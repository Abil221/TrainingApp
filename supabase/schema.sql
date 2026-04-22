create extension if not exists "pgcrypto";

create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  email text unique,
  display_name text not null default 'Атлет',
  fitness_level text not null default 'Средний',
  height integer not null default 175 check (height between 50 and 260),
  weight integer not null default 75 check (weight between 20 and 400),
  is_online boolean not null default false,
  last_seen timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.workouts (
  id uuid primary key default gen_random_uuid(),
  legacy_id text unique,
  title text not null,
  description text not null default '',
  duration_seconds integer not null default 0,
  image_url text,
  category text not null,
  difficulty text not null check (difficulty in ('easy', 'medium', 'hard')),
  calories_burned integer not null default 0,
  equipment text[] not null default '{}',
  instructions text not null default '',
  is_active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.workout_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  workout_id uuid not null references public.workouts (id) on delete restrict,
  completed_at timestamptz not null default timezone('utc', now()),
  duration_seconds integer not null default 0,
  calories_burned integer not null default 0,
  progress_value numeric(10, 2),
  progress_unit text not null default '',
  result_note text not null default '',
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.favorites (
  user_id uuid not null references public.profiles (id) on delete cascade,
  workout_id uuid not null references public.workouts (id) on delete cascade,
  created_at timestamptz not null default timezone('utc', now()),
  primary key (user_id, workout_id)
);

create table if not exists public.friendships (
  id uuid primary key default gen_random_uuid(),
  requester_id uuid not null references public.profiles (id) on delete cascade,
  addressee_id uuid not null references public.profiles (id) on delete cascade,
  status text not null default 'pending' check (status in ('pending', 'accepted', 'declined')),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint friendships_unique_pair unique (requester_id, addressee_id),
  constraint friendships_no_self check (requester_id <> addressee_id)
);

create index if not exists idx_workout_logs_user_completed_at
  on public.workout_logs (user_id, completed_at desc);

create index if not exists idx_workout_logs_workout_id
  on public.workout_logs (workout_id);

create index if not exists idx_friendships_requester
  on public.friendships (requester_id);

create index if not exists idx_friendships_addressee
  on public.friendships (addressee_id);

create unique index if not exists idx_friendships_unique_users
  on public.friendships (
    least(requester_id, addressee_id),
    greatest(requester_id, addressee_id)
  );

create table if not exists public.friend_messages (
  id uuid primary key default gen_random_uuid(),
  friendship_id uuid not null references public.friendships (id) on delete cascade,
  sender_id uuid not null references public.profiles (id) on delete cascade,
  recipient_id uuid not null references public.profiles (id) on delete cascade,
  content text not null,
  created_at timestamptz not null default timezone('utc', now()),
  read_at timestamptz
);

create table if not exists public.friend_typing_states (
  friendship_id uuid not null references public.friendships (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  is_typing boolean not null default false,
  updated_at timestamptz not null default timezone('utc', now()),
  primary key (friendship_id, user_id)
);

create index if not exists idx_friend_messages_friendship_created_at
  on public.friend_messages (friendship_id, created_at asc);

create index if not exists idx_friend_typing_states_friendship
  on public.friend_typing_states (friendship_id, updated_at desc);

create or replace function public.is_friendship_participant(
  friendship_id uuid,
  user_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.friendships
    where id = friendship_id
      and status = 'accepted'
      and (requester_id = user_id or addressee_id = user_id)
  );
$$;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email)
  values (new.id, new.email)
  on conflict (id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

create or replace function public.are_friends(user_a uuid, user_b uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.friendships
    where status = 'accepted'
      and (
        (requester_id = user_a and addressee_id = user_b) or
        (requester_id = user_b and addressee_id = user_a)
      )
  );
$$;

create or replace function public.search_profiles(search_term text default '')
returns table (
  id uuid,
  display_name text,
  email text,
  friendship_id uuid,
  friendship_status text,
  is_outgoing boolean
)
language sql
stable
security definer
set search_path = public
as $$
  select
    p.id,
    p.display_name,
    p.email,
    f.id as friendship_id,
    f.status as friendship_status,
    case when f.requester_id = auth.uid() then true else false end as is_outgoing
  from public.profiles p
  left join lateral (
    select fr.id, fr.status, fr.requester_id, fr.addressee_id
    from public.friendships fr
    where (
      (fr.requester_id = auth.uid() and fr.addressee_id = p.id) or
      (fr.requester_id = p.id and fr.addressee_id = auth.uid())
    )
    limit 1
  ) f on true
  where auth.uid() is not null
    and p.id <> auth.uid()
    and (
      coalesce(trim(search_term), '') = '' or
      p.display_name ilike '%' || trim(search_term) || '%' or
      coalesce(p.email, '') ilike '%' || trim(search_term) || '%'
    )
  order by p.display_name
  limit 20;
$$;

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute procedure public.set_updated_at();

drop trigger if exists workouts_set_updated_at on public.workouts;
create trigger workouts_set_updated_at
  before update on public.workouts
  for each row execute procedure public.set_updated_at();

drop trigger if exists friendships_set_updated_at on public.friendships;
create trigger friendships_set_updated_at
  before update on public.friendships
  for each row execute procedure public.set_updated_at();

alter table public.profiles enable row level security;
alter table public.workouts enable row level security;
alter table public.workout_logs enable row level security;
alter table public.favorites enable row level security;
alter table public.friendships enable row level security;
alter table public.friend_messages enable row level security;
alter table public.friend_typing_states enable row level security;

drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own"
  on public.profiles for select
  using (auth.uid() = id);

drop policy if exists "profiles_select_accepted_friends" on public.profiles;
create policy "profiles_select_accepted_friends"
  on public.profiles for select
  using (public.are_friends(auth.uid(), id));

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own"
  on public.profiles for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

drop policy if exists "workouts_select_authenticated" on public.workouts;
create policy "workouts_select_authenticated"
  on public.workouts for select
  using (auth.role() = 'authenticated');

drop policy if exists "workout_logs_select_own" on public.workout_logs;
create policy "workout_logs_select_own"
  on public.workout_logs for select
  using (auth.uid() = user_id);

drop policy if exists "workout_logs_select_accepted_friends" on public.workout_logs;
create policy "workout_logs_select_accepted_friends"
  on public.workout_logs for select
  using (public.are_friends(auth.uid(), user_id));

drop policy if exists "workout_logs_insert_own" on public.workout_logs;
create policy "workout_logs_insert_own"
  on public.workout_logs for insert
  with check (auth.uid() = user_id);

drop policy if exists "workout_logs_update_own" on public.workout_logs;
create policy "workout_logs_update_own"
  on public.workout_logs for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "workout_logs_delete_own" on public.workout_logs;
create policy "workout_logs_delete_own"
  on public.workout_logs for delete
  using (auth.uid() = user_id);

drop policy if exists "favorites_select_own" on public.favorites;
create policy "favorites_select_own"
  on public.favorites for select
  using (auth.uid() = user_id);

drop policy if exists "favorites_insert_own" on public.favorites;
create policy "favorites_insert_own"
  on public.favorites for insert
  with check (auth.uid() = user_id);

drop policy if exists "favorites_delete_own" on public.favorites;
create policy "favorites_delete_own"
  on public.favorites for delete
  using (auth.uid() = user_id);

drop policy if exists "friendships_select_participant" on public.friendships;
create policy "friendships_select_participant"
  on public.friendships for select
  using (auth.uid() = requester_id or auth.uid() = addressee_id);

drop policy if exists "friendships_insert_requester" on public.friendships;
create policy "friendships_insert_requester"
  on public.friendships for insert
  with check (auth.uid() = requester_id);

drop policy if exists "friendships_update_participant" on public.friendships;
create policy "friendships_update_participant"
  on public.friendships for update
  using (auth.uid() = requester_id or auth.uid() = addressee_id)
  with check (auth.uid() = requester_id or auth.uid() = addressee_id);

drop policy if exists "friendships_delete_participant" on public.friendships;
create policy "friendships_delete_participant"
  on public.friendships for delete
  using (auth.uid() = requester_id or auth.uid() = addressee_id);

drop policy if exists "friend_messages_select_participant" on public.friend_messages;
create policy "friend_messages_select_participant"
  on public.friend_messages for select
  using (public.is_friendship_participant(friendship_id, auth.uid()));

drop policy if exists "friend_messages_insert_participant" on public.friend_messages;
create policy "friend_messages_insert_participant"
  on public.friend_messages for insert
  with check (
    public.is_friendship_participant(friendship_id, auth.uid())
    and auth.uid() = sender_id
  );

drop policy if exists "friend_messages_update_none" on public.friend_messages;
create policy "friend_messages_update_recipient_read_at"
  on public.friend_messages for update
  using (
    auth.uid() = recipient_id
    and read_at is null
  )
  with check (
    auth.uid() = recipient_id
    and sender_id = sender_id
    and recipient_id = recipient_id
    and friendship_id = friendship_id
    and content = content
    and read_at is not null
  );

drop policy if exists "friend_messages_delete_none" on public.friend_messages;
create policy "friend_messages_delete_none"
  on public.friend_messages for delete
  using (false);

drop policy if exists "friend_typing_states_select_participant" on public.friend_typing_states;
create policy "friend_typing_states_select_participant"
  on public.friend_typing_states for select
  using (public.is_friendship_participant(friendship_id, auth.uid()));

drop policy if exists "friend_typing_states_insert_participant" on public.friend_typing_states;
create policy "friend_typing_states_insert_participant"
  on public.friend_typing_states for insert
  with check (
    public.is_friendship_participant(friendship_id, auth.uid())
    and auth.uid() = user_id
  );

drop policy if exists "friend_typing_states_update_participant" on public.friend_typing_states;
create policy "friend_typing_states_update_participant"
  on public.friend_typing_states for update
  using (
    public.is_friendship_participant(friendship_id, auth.uid())
    and auth.uid() = user_id
  )
  with check (
    public.is_friendship_participant(friendship_id, auth.uid())
    and auth.uid() = user_id
  );

drop policy if exists "friend_typing_states_delete_participant" on public.friend_typing_states;
create policy "friend_typing_states_delete_participant"
  on public.friend_typing_states for delete
  using (auth.uid() = user_id);

-- ============ ACHIEVEMENTS ============
create table if not exists public.achievements (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  description text,
  icon_name text not null,
  criteria_type text not null check (criteria_type in ('total_workouts', 'calories_burned', 'streak_days', 'specific_workout', 'level_reached')),
  criteria_value integer not null default 1,
  reward_xp integer not null default 50,
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.user_achievements (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  achievement_id uuid not null references public.achievements (id) on delete cascade,
  unlocked_at timestamptz not null default timezone('utc', now()),
  unique (user_id, achievement_id)
);

create index if not exists idx_user_achievements_user
  on public.user_achievements (user_id);

-- ============ USER LEVELS & XP ============
create table if not exists public.user_levels (
  user_id uuid primary key references public.profiles (id) on delete cascade,
  current_level integer not null default 1 check (current_level between 1 and 100),
  total_xp integer not null default 0,
  xp_for_next_level integer not null default 1000,
  updated_at timestamptz not null default timezone('utc', now())
);

-- ============ WORKOUT PLANS ============
create table if not exists public.workout_plans (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  name text not null,
  description text,
  duration_weeks integer not null default 4 check (duration_weeks between 1 and 52),
  is_active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.workout_plan_days (
  id uuid primary key default gen_random_uuid(),
  plan_id uuid not null references public.workout_plans (id) on delete cascade,
  day_of_week integer not null check (day_of_week between 0 and 6),
  workout_id uuid not null references public.workouts (id) on delete restrict,
  order_in_day integer not null default 1,
  created_at timestamptz not null default timezone('utc', now())
);

create index if not exists idx_workout_plan_days_plan
  on public.workout_plan_days (plan_id);

create index if not exists idx_workout_plan_days_workout
  on public.workout_plan_days (workout_id);

-- ============ USER GOALS ============
create table if not exists public.user_goals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  goal_type text not null check (goal_type in ('weight_loss', 'muscle_gain', 'endurance', 'strength', 'flexibility')),
  name text not null,
  description text,
  target_value numeric(10, 2) not null,
  current_value numeric(10, 2) not null,
  unit text not null,
  deadline date not null,
  is_completed boolean not null default false,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create index if not exists idx_user_goals_user
  on public.user_goals (user_id, is_completed);

-- ============ WEIGHT HISTORY ============
create table if not exists public.weight_history (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  weight integer not null check (weight between 20 and 400),
  recorded_at timestamptz not null default timezone('utc', now()),
  notes text
);

create index if not exists idx_weight_history_user_date
  on public.weight_history (user_id, recorded_at desc);

-- ============ ENABLE RLS & POLICIES ============
alter table public.achievements enable row level security;
alter table public.user_achievements enable row level security;
alter table public.user_levels enable row level security;
alter table public.workout_plans enable row level security;
alter table public.workout_plan_days enable row level security;
alter table public.user_goals enable row level security;
alter table public.weight_history enable row level security;

-- Achievements are public
drop policy if exists "achievements_select_authenticated" on public.achievements;
create policy "achievements_select_authenticated"
  on public.achievements for select
  using (auth.role() = 'authenticated');

-- User achievements
drop policy if exists "user_achievements_select_own" on public.user_achievements;
create policy "user_achievements_select_own"
  on public.user_achievements for select
  using (auth.uid() = user_id);

drop policy if exists "user_achievements_insert_own" on public.user_achievements;
create policy "user_achievements_insert_own"
  on public.user_achievements for insert
  with check (auth.uid() = user_id);

-- User levels
drop policy if exists "user_levels_select_own" on public.user_levels;
create policy "user_levels_select_own"
  on public.user_levels for select
  using (auth.uid() = user_id);

drop policy if exists "user_levels_select_friends" on public.user_levels;
create policy "user_levels_select_friends"
  on public.user_levels for select
  using (public.are_friends(auth.uid(), user_id));

drop policy if exists "user_levels_insert_own" on public.user_levels;
create policy "user_levels_insert_own"
  on public.user_levels for insert
  with check (auth.uid() = user_id);

drop policy if exists "user_levels_update_own" on public.user_levels;
create policy "user_levels_update_own"
  on public.user_levels for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Workout plans
drop policy if exists "workout_plans_select_own" on public.workout_plans;
create policy "workout_plans_select_own"
  on public.workout_plans for select
  using (auth.uid() = user_id);

drop policy if exists "workout_plans_insert_own" on public.workout_plans;
create policy "workout_plans_insert_own"
  on public.workout_plans for insert
  with check (auth.uid() = user_id);

drop policy if exists "workout_plans_update_own" on public.workout_plans;
create policy "workout_plans_update_own"
  on public.workout_plans for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "workout_plans_delete_own" on public.workout_plans;
create policy "workout_plans_delete_own"
  on public.workout_plans for delete
  using (auth.uid() = user_id);

-- Workout plan days
drop policy if exists "workout_plan_days_select_own" on public.workout_plan_days;
create policy "workout_plan_days_select_own"
  on public.workout_plan_days for select
  using (
    exists (
      select 1 from public.workout_plans wp
      where wp.id = plan_id and wp.user_id = auth.uid()
    )
  );

drop policy if exists "workout_plan_days_insert_own" on public.workout_plan_days;
create policy "workout_plan_days_insert_own"
  on public.workout_plan_days for insert
  with check (
    exists (
      select 1 from public.workout_plans wp
      where wp.id = plan_id and wp.user_id = auth.uid()
    )
  );

drop policy if exists "workout_plan_days_update_own" on public.workout_plan_days;
create policy "workout_plan_days_update_own"
  on public.workout_plan_days for update
  using (
    exists (
      select 1 from public.workout_plans wp
      where wp.id = plan_id and wp.user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.workout_plans wp
      where wp.id = plan_id and wp.user_id = auth.uid()
    )
  );

drop policy if exists "workout_plan_days_delete_own" on public.workout_plan_days;
create policy "workout_plan_days_delete_own"
  on public.workout_plan_days for delete
  using (
    exists (
      select 1 from public.workout_plans wp
      where wp.id = plan_id and wp.user_id = auth.uid()
    )
  );

-- User goals
drop policy if exists "user_goals_select_own" on public.user_goals;
create policy "user_goals_select_own"
  on public.user_goals for select
  using (auth.uid() = user_id);

drop policy if exists "user_goals_insert_own" on public.user_goals;
create policy "user_goals_insert_own"
  on public.user_goals for insert
  with check (auth.uid() = user_id);

drop policy if exists "user_goals_update_own" on public.user_goals;
create policy "user_goals_update_own"
  on public.user_goals for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "user_goals_delete_own" on public.user_goals;
create policy "user_goals_delete_own"
  on public.user_goals for delete
  using (auth.uid() = user_id);

-- Weight history
drop policy if exists "weight_history_select_own" on public.weight_history;
create policy "weight_history_select_own"
  on public.weight_history for select
  using (auth.uid() = user_id);

drop policy if exists "weight_history_insert_own" on public.weight_history;
create policy "weight_history_insert_own"
  on public.weight_history for insert
  with check (auth.uid() = user_id);

drop policy if exists "weight_history_delete_own" on public.weight_history;
create policy "weight_history_delete_own"
  on public.weight_history for delete
  using (auth.uid() = user_id);

-- ============ TRIGGERS FOR UPDATED_AT ============
drop trigger if exists workout_plans_set_updated_at on public.workout_plans;
create trigger workout_plans_set_updated_at
  before update on public.workout_plans
  for each row execute procedure public.set_updated_at();

drop trigger if exists user_goals_set_updated_at on public.user_goals;
create trigger user_goals_set_updated_at
  before update on public.user_goals
  for each row execute procedure public.set_updated_at();
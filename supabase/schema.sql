create extension if not exists "pgcrypto";

create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  email text unique,
  display_name text not null default 'Атлет',
  fitness_level text not null default 'Средний',
  height integer not null default 175 check (height between 50 and 260),
  weight integer not null default 75 check (weight between 20 and 400),
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
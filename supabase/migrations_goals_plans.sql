-- ============ GOALS MIGRATION ============
-- This migration creates tables for user goals, weight tracking, workout plans, and achievements

-- User Goals Table
CREATE TABLE IF NOT EXISTS public.user_goals (
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

CREATE INDEX IF NOT EXISTS idx_user_goals_user
  ON public.user_goals (user_id, is_completed);

-- Weight History Table
CREATE TABLE IF NOT EXISTS public.weight_history (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  weight integer not null check (weight between 20 and 400),
  recorded_at timestamptz not null default timezone('utc', now()),
  notes text
);

CREATE INDEX IF NOT EXISTS idx_weight_history_user_date
  ON public.weight_history (user_id, recorded_at desc);

-- User Levels & XP Table
CREATE TABLE IF NOT EXISTS public.user_levels (
  user_id uuid primary key references public.profiles (id) on delete cascade,
  current_level integer not null default 1 check (current_level between 1 and 100),
  total_xp integer not null default 0,
  xp_for_next_level integer not null default 1000,
  updated_at timestamptz not null default timezone('utc', now())
);

-- Achievements Table
CREATE TABLE IF NOT EXISTS public.achievements (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  description text,
  icon_name text not null,
  criteria_type text not null check (criteria_type in ('total_workouts', 'calories_burned', 'streak_days', 'specific_workout', 'level_reached')),
  criteria_value integer not null default 1,
  reward_xp integer not null default 50,
  created_at timestamptz not null default timezone('utc', now())
);

-- User Achievements Table
CREATE TABLE IF NOT EXISTS public.user_achievements (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  achievement_id uuid not null references public.achievements (id) on delete cascade,
  unlocked_at timestamptz not null default timezone('utc', now()),
  unique (user_id, achievement_id)
);

CREATE INDEX IF NOT EXISTS idx_user_achievements_user
  ON public.user_achievements (user_id);

-- Workout Plans Table
CREATE TABLE IF NOT EXISTS public.workout_plans (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  name text not null,
  description text,
  duration_weeks integer not null default 4 check (duration_weeks between 1 and 52),
  is_active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

-- Workout Plan Days Table
CREATE TABLE IF NOT EXISTS public.workout_plan_days (
  id uuid primary key default gen_random_uuid(),
  plan_id uuid not null references public.workout_plans (id) on delete cascade,
  day_of_week integer not null check (day_of_week between 0 and 6),
  workout_id uuid not null references public.workouts (id) on delete restrict,
  order_in_day integer not null default 1,
  created_at timestamptz not null default timezone('utc', now())
);

CREATE INDEX IF NOT EXISTS idx_workout_plan_days_plan
  ON public.workout_plan_days (plan_id);

CREATE INDEX IF NOT EXISTS idx_workout_plan_days_workout
  ON public.workout_plan_days (workout_id);

-- ============ ENABLE RLS ============
ALTER TABLE public.user_goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.weight_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_levels ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workout_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workout_plan_days ENABLE ROW LEVEL SECURITY;

-- ============ CREATE RLS POLICIES ============

-- User Goals Policies
DROP POLICY IF EXISTS "user_goals_select_own" ON public.user_goals;
CREATE POLICY "user_goals_select_own"
  ON public.user_goals FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "user_goals_insert_own" ON public.user_goals;
CREATE POLICY "user_goals_insert_own"
  ON public.user_goals FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "user_goals_update_own" ON public.user_goals;
CREATE POLICY "user_goals_update_own"
  ON public.user_goals FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "user_goals_delete_own" ON public.user_goals;
CREATE POLICY "user_goals_delete_own"
  ON public.user_goals FOR DELETE
  USING (auth.uid() = user_id);

-- Weight History Policies
DROP POLICY IF EXISTS "weight_history_select_own" ON public.weight_history;
CREATE POLICY "weight_history_select_own"
  ON public.weight_history FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "weight_history_insert_own" ON public.weight_history;
CREATE POLICY "weight_history_insert_own"
  ON public.weight_history FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "weight_history_delete_own" ON public.weight_history;
CREATE POLICY "weight_history_delete_own"
  ON public.weight_history FOR DELETE
  USING (auth.uid() = user_id);

-- User Levels Policies
DROP POLICY IF EXISTS "user_levels_select_own" ON public.user_levels;
CREATE POLICY "user_levels_select_own"
  ON public.user_levels FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "user_levels_insert_own" ON public.user_levels;
CREATE POLICY "user_levels_insert_own"
  ON public.user_levels FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "user_levels_update_own" ON public.user_levels;
CREATE POLICY "user_levels_update_own"
  ON public.user_levels FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Achievements (Public - read only)
DROP POLICY IF EXISTS "achievements_select_authenticated" ON public.achievements;
CREATE POLICY "achievements_select_authenticated"
  ON public.achievements FOR SELECT
  USING (auth.role() = 'authenticated');

-- User Achievements Policies
DROP POLICY IF EXISTS "user_achievements_select_own" ON public.user_achievements;
CREATE POLICY "user_achievements_select_own"
  ON public.user_achievements FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "user_achievements_insert_own" ON public.user_achievements;
CREATE POLICY "user_achievements_insert_own"
  ON public.user_achievements FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Workout Plans Policies
DROP POLICY IF EXISTS "workout_plans_select_own" ON public.workout_plans;
CREATE POLICY "workout_plans_select_own"
  ON public.workout_plans FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "workout_plans_insert_own" ON public.workout_plans;
CREATE POLICY "workout_plans_insert_own"
  ON public.workout_plans FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "workout_plans_update_own" ON public.workout_plans;
CREATE POLICY "workout_plans_update_own"
  ON public.workout_plans FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "workout_plans_delete_own" ON public.workout_plans;
CREATE POLICY "workout_plans_delete_own"
  ON public.workout_plans FOR DELETE
  USING (auth.uid() = user_id);

-- Workout Plan Days Policies
DROP POLICY IF EXISTS "workout_plan_days_select_own" ON public.workout_plan_days;
CREATE POLICY "workout_plan_days_select_own"
  ON public.workout_plan_days FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.workout_plans wp
      WHERE wp.id = plan_id AND wp.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "workout_plan_days_insert_own" ON public.workout_plan_days;
CREATE POLICY "workout_plan_days_insert_own"
  ON public.workout_plan_days FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.workout_plans wp
      WHERE wp.id = plan_id AND wp.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "workout_plan_days_update_own" ON public.workout_plan_days;
CREATE POLICY "workout_plan_days_update_own"
  ON public.workout_plan_days FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.workout_plans wp
      WHERE wp.id = plan_id AND wp.user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.workout_plans wp
      WHERE wp.id = plan_id AND wp.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "workout_plan_days_delete_own" ON public.workout_plan_days;
CREATE POLICY "workout_plan_days_delete_own"
  ON public.workout_plan_days FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM public.workout_plans wp
      WHERE wp.id = plan_id AND wp.user_id = auth.uid()
    )
  );

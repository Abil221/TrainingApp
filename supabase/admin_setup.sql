-- ============================================================
-- ADMIN SETUP FOR TRAININGAPP (Supabase SQL Editor)
-- Вставить и выполнить в Supabase > SQL Editor
-- После выполнения вставить user_id администратора:
--   INSERT INTO public.admin_roles (user_id) VALUES ('<ВАШ_USER_ID>');
-- ============================================================

-- ============================================================
-- 1. ADMIN ROLES TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS public.admin_roles (
  user_id     uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  granted_at  timestamptz NOT NULL DEFAULT now(),
  granted_by  uuid REFERENCES auth.users(id) ON DELETE SET NULL
);

COMMENT ON TABLE public.admin_roles IS 'Администраторы приложения';

-- ============================================================
-- 2. ADMIN AUDIT LOG TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS public.admin_audit_log (
  id           uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_id     uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  action       text        NOT NULL,
  target_table text,
  target_id    text,
  details      jsonb,
  created_at   timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_admin_audit_log_admin
  ON public.admin_audit_log (admin_id, created_at DESC);

COMMENT ON TABLE public.admin_audit_log IS 'Журнал действий администраторов';

-- ============================================================
-- 3. HELPER FUNCTION: is_admin()
-- Drop ALL overloads to avoid "function name is not unique" error
-- ============================================================
DO $$
DECLARE
  r record;
BEGIN
  FOR r IN
    SELECT oid::regprocedure AS sig
    FROM pg_proc
    WHERE proname = 'is_admin'
      AND pronamespace = 'public'::regnamespace
  LOOP
    EXECUTE 'DROP FUNCTION IF EXISTS ' || r.sig || ' CASCADE';
  END LOOP;
END;
$$;

CREATE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.admin_roles WHERE user_id = auth.uid()
  );
$$;

COMMENT ON FUNCTION public.is_admin() IS 'Проверяет, является ли текущий пользователь администратором';

-- ============================================================
-- 4. AGGREGATE STATS FUNCTION (for admin dashboard)
-- ============================================================
DROP FUNCTION IF EXISTS public.get_admin_stats() CASCADE;

CREATE FUNCTION public.get_admin_stats()
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT jsonb_build_object(
    'total_users',        (SELECT COUNT(*)  FROM public.profiles),
    'total_workouts',     (SELECT COUNT(*)  FROM public.workouts),
    'total_logs',         (SELECT COUNT(*)  FROM public.workout_logs),
    'online_users',       (SELECT COUNT(*)  FROM public.profiles    WHERE is_online = true),
    'logs_today',         (SELECT COUNT(*)  FROM public.workout_logs WHERE completed_at >= now() - interval '24 hours'),
    'logs_week',          (SELECT COUNT(*)  FROM public.workout_logs WHERE completed_at >= now() - interval '7 days'),
    'new_users_week',     (SELECT COUNT(*)  FROM public.profiles     WHERE created_at  >= now() - interval '7 days'),
    'new_users_month',    (SELECT COUNT(*)  FROM public.profiles     WHERE created_at  >= now() - interval '30 days'),
    'active_workouts',    (SELECT COUNT(*)  FROM public.workouts     WHERE is_active   = true),
    'total_achievements', (SELECT COUNT(*)  FROM public.achievements),
    'total_friends',      (SELECT COUNT(*)  FROM public.friendships  WHERE status = 'accepted'),
    'total_messages',     (SELECT COUNT(*)  FROM public.friend_messages),
    'calories_today',     (SELECT COALESCE(SUM(calories_burned), 0) FROM public.workout_logs WHERE completed_at >= now() - interval '24 hours'),
    'calories_week',      (SELECT COALESCE(SUM(calories_burned), 0) FROM public.workout_logs WHERE completed_at >= now() - interval '7 days')
  );
$$;

-- ============================================================
-- 5. DAILY ACTIVITY FUNCTION
-- ============================================================
DROP FUNCTION IF EXISTS public.get_admin_daily_activity(integer) CASCADE;

CREATE FUNCTION public.get_admin_daily_activity(days_back integer DEFAULT 14)
RETURNS TABLE (
  activity_date  date,
  logs_count     bigint,
  unique_users   bigint,
  total_calories bigint
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    completed_at::date          AS activity_date,
    COUNT(*)                    AS logs_count,
    COUNT(DISTINCT user_id)     AS unique_users,
    COALESCE(SUM(calories_burned), 0) AS total_calories
  FROM public.workout_logs
  WHERE completed_at >= now() - (days_back || ' days')::interval
  GROUP BY completed_at::date
  ORDER BY activity_date ASC;
$$;

-- ============================================================
-- 6. VIEWS  (drop first to avoid column-order conflicts)
-- ============================================================
DROP VIEW IF EXISTS public.admin_user_stats    CASCADE;
DROP VIEW IF EXISTS public.admin_workout_stats CASCADE;

CREATE VIEW public.admin_user_stats
  WITH (security_invoker = false)
AS
SELECT
  p.id,
  p.display_name,
  p.email,
  p.fitness_level,
  p.height,
  p.weight,
  p.is_online,
  p.last_seen,
  p.created_at,
  COALESCE(ul.current_level, 1)  AS current_level,
  COALESCE(ul.total_xp, 0)       AS total_xp,
  COALESCE(wl.workout_count, 0)  AS total_workouts,
  COALESCE(wl.total_calories, 0) AS total_calories,
  wl.last_workout_at,
  EXISTS (SELECT 1 FROM public.admin_roles ar WHERE ar.user_id = p.id) AS is_admin
FROM public.profiles p
LEFT JOIN public.user_levels ul ON ul.user_id = p.id
LEFT JOIN (
  SELECT
    user_id,
    COUNT(*)             AS workout_count,
    SUM(calories_burned) AS total_calories,
    MAX(completed_at)    AS last_workout_at
  FROM public.workout_logs
  GROUP BY user_id
) wl ON wl.user_id = p.id
ORDER BY p.created_at DESC;

COMMENT ON VIEW public.admin_user_stats IS 'Расширенная статистика пользователей для админа';

CREATE VIEW public.admin_workout_stats
  WITH (security_invoker = false)
AS
SELECT
  w.id,
  w.title,
  w.category,
  w.difficulty,
  w.duration_seconds,
  w.calories_burned,
  w.equipment,
  w.is_active,
  w.created_at,
  w.description,
  w.instructions,
  COALESCE(ls.log_count, 0)        AS total_completions,
  COALESCE(ls.unique_users, 0)     AS unique_users,
  COALESCE(ls.avg_calories, 0)     AS avg_calories_actual,
  ls.last_completed_at
FROM public.workouts w
LEFT JOIN (
  SELECT
    workout_id,
    COUNT(*)                AS log_count,
    COUNT(DISTINCT user_id) AS unique_users,
    AVG(calories_burned)    AS avg_calories,
    MAX(completed_at)       AS last_completed_at
  FROM public.workout_logs
  GROUP BY workout_id
) ls ON ls.workout_id = w.id
ORDER BY ls.log_count DESC NULLS LAST;

COMMENT ON VIEW public.admin_workout_stats IS 'Статистика тренировок для админа';

GRANT SELECT ON public.admin_user_stats    TO authenticated;
GRANT SELECT ON public.admin_workout_stats TO authenticated;

-- ============================================================
-- 7. RLS FOR ADMIN TABLES
-- ============================================================
ALTER TABLE public.admin_roles     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_audit_log ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "admin_roles_select_admin" ON public.admin_roles;
CREATE POLICY "admin_roles_select_admin"
  ON public.admin_roles FOR SELECT USING (public.is_admin());

DROP POLICY IF EXISTS "admin_roles_insert_admin" ON public.admin_roles;
CREATE POLICY "admin_roles_insert_admin"
  ON public.admin_roles FOR INSERT WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "admin_roles_delete_admin" ON public.admin_roles;
CREATE POLICY "admin_roles_delete_admin"
  ON public.admin_roles FOR DELETE USING (public.is_admin());

DROP POLICY IF EXISTS "audit_log_select_admin" ON public.admin_audit_log;
CREATE POLICY "audit_log_select_admin"
  ON public.admin_audit_log FOR SELECT USING (public.is_admin());

DROP POLICY IF EXISTS "audit_log_insert_admin" ON public.admin_audit_log;
CREATE POLICY "audit_log_insert_admin"
  ON public.admin_audit_log FOR INSERT
  WITH CHECK (public.is_admin() AND auth.uid() = admin_id);

-- ============================================================
-- 8. ADMIN BYPASS POLICIES FOR EXISTING TABLES
-- ============================================================

-- PROFILES
DROP POLICY IF EXISTS "profiles_select_admin" ON public.profiles;
CREATE POLICY "profiles_select_admin"
  ON public.profiles FOR SELECT USING (public.is_admin());

DROP POLICY IF EXISTS "profiles_update_admin" ON public.profiles;
CREATE POLICY "profiles_update_admin"
  ON public.profiles FOR UPDATE
  USING (public.is_admin()) WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "profiles_delete_admin" ON public.profiles;
CREATE POLICY "profiles_delete_admin"
  ON public.profiles FOR DELETE USING (public.is_admin());

-- WORKOUTS
DROP POLICY IF EXISTS "workouts_insert_admin" ON public.workouts;
CREATE POLICY "workouts_insert_admin"
  ON public.workouts FOR INSERT WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "workouts_update_admin" ON public.workouts;
CREATE POLICY "workouts_update_admin"
  ON public.workouts FOR UPDATE
  USING (public.is_admin()) WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "workouts_delete_admin" ON public.workouts;
CREATE POLICY "workouts_delete_admin"
  ON public.workouts FOR DELETE USING (public.is_admin());

-- WORKOUT LOGS
DROP POLICY IF EXISTS "workout_logs_select_admin" ON public.workout_logs;
CREATE POLICY "workout_logs_select_admin"
  ON public.workout_logs FOR SELECT USING (public.is_admin());

DROP POLICY IF EXISTS "workout_logs_delete_admin" ON public.workout_logs;
CREATE POLICY "workout_logs_delete_admin"
  ON public.workout_logs FOR DELETE USING (public.is_admin());

-- ACHIEVEMENTS
DROP POLICY IF EXISTS "achievements_insert_admin" ON public.achievements;
CREATE POLICY "achievements_insert_admin"
  ON public.achievements FOR INSERT WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "achievements_update_admin" ON public.achievements;
CREATE POLICY "achievements_update_admin"
  ON public.achievements FOR UPDATE
  USING (public.is_admin()) WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "achievements_delete_admin" ON public.achievements;
CREATE POLICY "achievements_delete_admin"
  ON public.achievements FOR DELETE USING (public.is_admin());

-- USER ACHIEVEMENTS
DROP POLICY IF EXISTS "user_achievements_select_admin" ON public.user_achievements;
CREATE POLICY "user_achievements_select_admin"
  ON public.user_achievements FOR SELECT USING (public.is_admin());

-- USER LEVELS
DROP POLICY IF EXISTS "user_levels_select_admin" ON public.user_levels;
CREATE POLICY "user_levels_select_admin"
  ON public.user_levels FOR SELECT USING (public.is_admin());

-- USER GOALS
DROP POLICY IF EXISTS "user_goals_select_admin" ON public.user_goals;
CREATE POLICY "user_goals_select_admin"
  ON public.user_goals FOR SELECT USING (public.is_admin());

-- FRIENDSHIPS
DROP POLICY IF EXISTS "friendships_select_admin" ON public.friendships;
CREATE POLICY "friendships_select_admin"
  ON public.friendships FOR SELECT USING (public.is_admin());

-- FRIEND MESSAGES
DROP POLICY IF EXISTS "friend_messages_select_admin" ON public.friend_messages;
CREATE POLICY "friend_messages_select_admin"
  ON public.friend_messages FOR SELECT USING (public.is_admin());

-- WEIGHT HISTORY
DROP POLICY IF EXISTS "weight_history_select_admin" ON public.weight_history;
CREATE POLICY "weight_history_select_admin"
  ON public.weight_history FOR SELECT USING (public.is_admin());

-- WORKOUT PLANS
DROP POLICY IF EXISTS "workout_plans_select_admin" ON public.workout_plans;
CREATE POLICY "workout_plans_select_admin"
  ON public.workout_plans FOR SELECT USING (public.is_admin());

-- ============================================================
-- DONE! Теперь добавьте первого администратора:
--
--   INSERT INTO public.admin_roles (user_id)
--   VALUES ('<ВАШ_UUID_ИЗ_auth.users>');
--
-- UUID можно найти в Supabase > Authentication > Users
-- ============================================================

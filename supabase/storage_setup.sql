-- ============================================================
-- STORAGE SETUP FOR TRAININGAPP
-- Запустить в Supabase > SQL Editor ПОСЛЕ admin_setup.sql
-- ============================================================

-- 1. Создаём публичный bucket для изображений тренировок
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'workout-images',
  'workout-images',
  true,
  5242880,  -- 5 MB лимит
  ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO UPDATE
  SET public            = true,
      file_size_limit   = 5242880,
      allowed_mime_types = ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/webp'];

-- 2. Политики доступа к файлам

-- Публичное чтение (все могут видеть картинки)
DROP POLICY IF EXISTS "workout_images_public_read" ON storage.objects;
CREATE POLICY "workout_images_public_read"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'workout-images');

-- Загрузка только для аутентифицированных (только админы загружают)
DROP POLICY IF EXISTS "workout_images_auth_insert" ON storage.objects;
CREATE POLICY "workout_images_auth_insert"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'workout-images'
    AND auth.role() = 'authenticated'
  );

-- Обновление файлов только для аутентифицированных
DROP POLICY IF EXISTS "workout_images_auth_update" ON storage.objects;
CREATE POLICY "workout_images_auth_update"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'workout-images'
    AND auth.role() = 'authenticated'
  );

-- Удаление файлов только для аутентифицированных
DROP POLICY IF EXISTS "workout_images_auth_delete" ON storage.objects;
CREATE POLICY "workout_images_auth_delete"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'workout-images'
    AND auth.role() = 'authenticated'
  );

-- 3. Обновляем вьюху admin_workout_stats — добавляем image_url
--    (если admin_setup.sql уже был запущен, DROP CASCADE безопасно пересоздаст вьюху)
DROP VIEW IF EXISTS public.admin_workout_stats CASCADE;

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
  w.image_url,
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

GRANT SELECT ON public.admin_workout_stats TO authenticated;

-- ============================================================
-- ГОТОВО!
-- Bucket 'workout-images' создан и открыт для публичного чтения.
-- Загружать изображения могут только авторизованные пользователи.
-- ============================================================

-- Достижения для TrainingApp
-- Выполните этот SQL в Supabase SQL Editor (Dashboard → SQL Editor → New query)

insert into public.achievements (name, description, icon_name, criteria_type, criteria_value, reward_xp)
values
  -- По количеству тренировок
  ('Первый шаг',          'Завершите вашу первую тренировку',          'beginner',  'total_workouts',  1,    50),
  ('Новичок',             'Завершите 5 тренировок',                    'beginner',  'total_workouts',  5,    100),
  ('Регулярный',          'Завершите 10 тренировок',                   'runner',    'total_workouts',  10,   200),
  ('Активный атлет',      'Завершите 25 тренировок',                   'trophy',    'total_workouts',  25,   500),
  ('Профессионал',        'Завершите 50 тренировок',                   'star',      'total_workouts',  50,   1000),
  ('Легенда зала',        'Завершите 100 тренировок',                  'trophy',    'total_workouts',  100,  2000),
  ('Элита',               'Завершите 250 тренировок',                  'lightning', 'total_workouts',  250,  5000),

  -- По сожжённым калориям
  ('Первые калории',      'Сожгите 1 000 калорий',                     'fire',      'calories_burned', 1000,  100),
  ('Разжигатель',         'Сожгите 5 000 калорий',                     'fire',      'calories_burned', 5000,  300),
  ('Пламя',               'Сожгите 10 000 калорий',                    'fire',      'calories_burned', 10000, 600),
  ('Инфerno',             'Сожгите 50 000 калорий',                    'lightning', 'calories_burned', 50000, 1500),
  ('Вулкан',              'Сожгите 100 000 калорий',                   'lightning', 'calories_burned', 100000,3000),

  -- По полосе (streak)
  ('Три дня подряд',      'Тренируйтесь 3 дня подряд',                 'runner',    'streak_days',     3,    150),
  ('Неделя силы',         'Тренируйтесь 7 дней подряд',                'star',      'streak_days',     7,    350),
  ('Двухнедельный марафон','Тренируйтесь 14 дней подряд',              'trophy',    'streak_days',     14,   750),
  ('Месяц без пропусков', 'Тренируйтесь 30 дней подряд',               'lightning', 'streak_days',     30,   1500),
  ('Железная воля',       'Тренируйтесь 60 дней подряд',               'lightning', 'streak_days',     60,   3000),

  -- По уровню
  ('Уровень 5',           'Достигните 5-го уровня',                    'star',      'level_reached',   5,    200),
  ('Уровень 10',          'Достигните 10-го уровня',                   'trophy',    'level_reached',   10,   500),
  ('Уровень 25',          'Достигните 25-го уровня',                   'trophy',    'level_reached',   25,   1000),
  ('Уровень 50',          'Достигните 50-го уровня',                   'lightning', 'level_reached',   50,   2500),
  ('Максимальный уровень','Достигните 100-го уровня',                  'lightning', 'level_reached',   100,  10000)

on conflict (name) do update
  set
    description    = excluded.description,
    icon_name      = excluded.icon_name,
    criteria_type  = excluded.criteria_type,
    criteria_value = excluded.criteria_value,
    reward_xp      = excluded.reward_xp;

-- Test queries to check your database data
-- Run these in Supabase SQL Editor to see what's happening

-- 1. Check if you have any users
SELECT id, email, created_at FROM auth.users ORDER BY created_at DESC;

-- 2. Check if profiles exist
SELECT * FROM public.profiles ORDER BY created_at DESC;

-- 3. Check if you have any habits
SELECT id, user_id, title, is_active, created_at 
FROM public.habits 
ORDER BY created_at DESC;

-- 4. Check if you have any habit completions
SELECT hc.id, h.title, hc.completion_date, hc.completed_at
FROM public.habit_completions hc
JOIN public.habits h ON h.id = hc.habit_id
ORDER BY hc.completion_date DESC, hc.completed_at DESC;

-- 5. Check completions for TODAY
SELECT h.title, hc.completion_date
FROM public.habit_completions hc
JOIN public.habits h ON h.id = hc.habit_id
WHERE hc.completion_date = CURRENT_DATE
ORDER BY h.title;

-- 6. Count habits vs completions for today (should both be 5)
SELECT 
  (SELECT COUNT(*) FROM public.habits WHERE is_active = TRUE) as total_habits,
  (SELECT COUNT(DISTINCT habit_id) FROM public.habit_completions WHERE completion_date = CURRENT_DATE) as completed_today;

-- 7. Get your user ID and test the streak function:
SELECT 
  id as user_id,
  email,
  get_user_current_streak(id) as current_streak
FROM auth.users 
ORDER BY created_at DESC
LIMIT 1;

-- 8. DETAILED DEBUG - Check what's actually in the database:
WITH user_info AS (
  SELECT id FROM auth.users ORDER BY created_at DESC LIMIT 1
)
SELECT 
  'Total Active Habits' as check_type,
  COUNT(*)::text as result
FROM public.habits h, user_info u
WHERE h.user_id = u.id AND h.is_active = TRUE

UNION ALL

SELECT 
  'Completions Today' as check_type,
  COUNT(*)::text as result
FROM public.habit_completions hc, user_info u
WHERE hc.user_id = u.id AND hc.completion_date = CURRENT_DATE

UNION ALL

SELECT 
  'Distinct Habits Completed Today' as check_type,
  COUNT(DISTINCT habit_id)::text as result
FROM public.habit_completions hc, user_info u
WHERE hc.user_id = u.id AND hc.completion_date = CURRENT_DATE

UNION ALL

SELECT 
  'Current Date in DB' as check_type,
  CURRENT_DATE::text as result

UNION ALL

SELECT 
  'Latest Completion Date' as check_type,
  COALESCE(MAX(completion_date)::text, 'No completions') as result
FROM public.habit_completions hc, user_info u
WHERE hc.user_id = u.id;

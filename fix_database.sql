-- Fix: Manually create profile and habits for your user
-- Run this in Supabase SQL Editor

-- Step 1: Get your user ID
DO $$
DECLARE
  v_user_id UUID;
BEGIN
  -- Get the most recent user
  SELECT id INTO v_user_id FROM auth.users ORDER BY created_at DESC LIMIT 1;
  
  -- Create profile if it doesn't exist
  INSERT INTO public.profiles (id, username)
  VALUES (v_user_id, 'GasGuard User')
  ON CONFLICT (id) DO NOTHING;
  
  RAISE NOTICE 'Profile created/verified for user: %', v_user_id;
  
  -- Manually create the 5 default habits
  INSERT INTO public.habits (user_id, title, description, icon, category, target_frequency) VALUES
    (v_user_id, 'Check Gas Detector Status', 'Verify your gas detector is powered on and functioning', '🔍', 'safety', 'daily'),
    (v_user_id, 'Inspect Sensor Readings', 'Review current gas levels and sensor data', '📊', 'safety', 'daily'),
    (v_user_id, 'Test Ventilation System', 'Ensure ventilation systems are working properly', '💨', 'safety', 'daily'),
    (v_user_id, 'Visual Safety Check', 'Look for visible gas leaks or damaged equipment', '👁️', 'safety', 'daily'),
    (v_user_id, 'Emergency Plan Review', 'Review and remember your gas emergency procedures', '🚨', 'safety', 'daily')
  ON CONFLICT DO NOTHING;
  
  RAISE NOTICE '5 default habits created!';
  
  -- Verify what was created
  RAISE NOTICE 'Total habits now: %', (SELECT COUNT(*) FROM public.habits WHERE user_id = v_user_id);
END $$;

-- Verify the results
(SELECT 
  'User' as item,
  email as name,
  id::text as id
FROM auth.users 
ORDER BY created_at DESC LIMIT 1)

UNION ALL

(SELECT 
  'Profile' as item,
  username as name,
  id::text as id
FROM public.profiles
ORDER BY created_at DESC LIMIT 1)

UNION ALL

(SELECT 
  'Habit' as item,
  title as name,
  id::text as id
FROM public.habits
ORDER BY created_at DESC
LIMIT 5);

-- GasGuard Complete Database Schema for Supabase
-- This schema tracks sensor data, safety events, user behavior, and daily safety habits
-- Run this entire file in Supabase SQL Editor

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- SECTION 1: USER PROFILES
-- ============================================

-- Users table (extends Supabase auth.users)
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  username TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Profiles policies
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
CREATE POLICY "Users can view own profile" 
  ON public.profiles FOR SELECT 
  USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile" 
  ON public.profiles FOR UPDATE 
  USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
CREATE POLICY "Users can insert own profile" 
  ON public.profiles FOR INSERT 
  WITH CHECK (auth.uid() = id);

-- ============================================
-- SECTION 2: HABITS SYSTEM
-- ============================================

-- Habits table
CREATE TABLE IF NOT EXISTS public.habits (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  icon TEXT,
  category TEXT,
  target_frequency TEXT DEFAULT 'daily',
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE public.habits ENABLE ROW LEVEL SECURITY;

-- Habits policies
DROP POLICY IF EXISTS "Users can view own habits" ON public.habits;
CREATE POLICY "Users can view own habits" 
  ON public.habits FOR SELECT 
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own habits" ON public.habits;
CREATE POLICY "Users can insert own habits" 
  ON public.habits FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own habits" ON public.habits;
CREATE POLICY "Users can update own habits" 
  ON public.habits FOR UPDATE 
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own habits" ON public.habits;
CREATE POLICY "Users can delete own habits" 
  ON public.habits FOR DELETE 
  USING (auth.uid() = user_id);

-- Habit completions table
CREATE TABLE IF NOT EXISTS public.habit_completions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  habit_id UUID REFERENCES public.habits(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  completed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  completion_date DATE DEFAULT CURRENT_DATE,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for habit completions
CREATE INDEX IF NOT EXISTS idx_habit_completions_user_id ON public.habit_completions(user_id);
CREATE INDEX IF NOT EXISTS idx_habit_completions_habit_id ON public.habit_completions(habit_id);
CREATE INDEX IF NOT EXISTS idx_habit_completions_date ON public.habit_completions(completion_date);
CREATE INDEX IF NOT EXISTS idx_habit_completions_user_date ON public.habit_completions(user_id, completion_date);

-- Enable Row Level Security
ALTER TABLE public.habit_completions ENABLE ROW LEVEL SECURITY;

-- Habit completions policies
DROP POLICY IF EXISTS "Users can view own completions" ON public.habit_completions;
CREATE POLICY "Users can view own completions" 
  ON public.habit_completions FOR SELECT 
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own completions" ON public.habit_completions;
CREATE POLICY "Users can insert own completions" 
  ON public.habit_completions FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own completions" ON public.habit_completions;
CREATE POLICY "Users can update own completions" 
  ON public.habit_completions FOR UPDATE 
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own completions" ON public.habit_completions;
CREATE POLICY "Users can delete own completions" 
  ON public.habit_completions FOR DELETE 
  USING (auth.uid() = user_id);

-- ============================================
-- SECTION 3: APP SESSIONS
-- ============================================

-- App sessions table
CREATE TABLE IF NOT EXISTS public.app_sessions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  session_date DATE DEFAULT CURRENT_DATE,
  session_start TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  session_end TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_app_sessions_user_id ON public.app_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_app_sessions_date ON public.app_sessions(session_date);

-- Enable Row Level Security
ALTER TABLE public.app_sessions ENABLE ROW LEVEL SECURITY;

-- App sessions policies
DROP POLICY IF EXISTS "Users can view own sessions" ON public.app_sessions;
CREATE POLICY "Users can view own sessions" 
  ON public.app_sessions FOR SELECT 
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own sessions" ON public.app_sessions;
CREATE POLICY "Users can insert own sessions" 
  ON public.app_sessions FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own sessions" ON public.app_sessions;
CREATE POLICY "Users can update own sessions" 
  ON public.app_sessions FOR UPDATE 
  USING (auth.uid() = user_id);

-- ============================================
-- SECTION 4: SENSOR DATA
-- ============================================

-- Sensor Data table
CREATE TABLE IF NOT EXISTS public.sensor_data (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  sensor_id TEXT NOT NULL,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  raw_value INTEGER NOT NULL,
  ppm_value NUMERIC(10, 2) NOT NULL,
  temperature NUMERIC(5, 2),
  humidity NUMERIC(5, 2),
  location TEXT,
  timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_sensor_data_user_id ON public.sensor_data(user_id);
CREATE INDEX IF NOT EXISTS idx_sensor_data_sensor_id ON public.sensor_data(sensor_id);
CREATE INDEX IF NOT EXISTS idx_sensor_data_timestamp ON public.sensor_data(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_sensor_data_ppm ON public.sensor_data(ppm_value);

-- Enable Row Level Security
ALTER TABLE public.sensor_data ENABLE ROW LEVEL SECURITY;

-- Sensor data policies
DROP POLICY IF EXISTS "Users can view own sensor data" ON public.sensor_data;
CREATE POLICY "Users can view own sensor data" 
  ON public.sensor_data FOR SELECT 
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own sensor data" ON public.sensor_data;
CREATE POLICY "Users can insert own sensor data" 
  ON public.sensor_data FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

-- ============================================
-- SECTION 5: SAFETY EVENTS
-- ============================================

-- Safety Event Log table
CREATE TABLE IF NOT EXISTS public.safety_events (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  sensor_id TEXT NOT NULL,
  event_type TEXT NOT NULL,
  severity TEXT NOT NULL,
  alert_type TEXT,
  peak_gas_level NUMERIC(10, 2),
  current_ppm NUMERIC(10, 2),
  auto_action_taken TEXT,
  power_cutoff_triggered BOOLEAN DEFAULT FALSE,
  window_opened BOOLEAN DEFAULT FALSE,
  alarm_activated BOOLEAN DEFAULT FALSE,
  message TEXT,
  location TEXT,
  resolved BOOLEAN DEFAULT FALSE,
  resolved_at TIMESTAMP WITH TIME ZONE,
  event_timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_safety_events_user_id ON public.safety_events(user_id);
CREATE INDEX IF NOT EXISTS idx_safety_events_sensor_id ON public.safety_events(sensor_id);
CREATE INDEX IF NOT EXISTS idx_safety_events_timestamp ON public.safety_events(event_timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_safety_events_type ON public.safety_events(event_type);
CREATE INDEX IF NOT EXISTS idx_safety_events_severity ON public.safety_events(severity);
CREATE INDEX IF NOT EXISTS idx_safety_events_resolved ON public.safety_events(resolved);

-- Enable Row Level Security
ALTER TABLE public.safety_events ENABLE ROW LEVEL SECURITY;

-- Safety events policies
DROP POLICY IF EXISTS "Users can view own safety events" ON public.safety_events;
CREATE POLICY "Users can view own safety events" 
  ON public.safety_events FOR SELECT 
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own safety events" ON public.safety_events;
CREATE POLICY "Users can insert own safety events" 
  ON public.safety_events FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own safety events" ON public.safety_events;
CREATE POLICY "Users can update own safety events" 
  ON public.safety_events FOR UPDATE 
  USING (auth.uid() = user_id);

-- ============================================
-- SECTION 6: USER BEHAVIOR LOG
-- ============================================

-- User Behavior Data table
CREATE TABLE IF NOT EXISTS public.user_behavior_log (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  activity_type TEXT NOT NULL,
  habit_id UUID REFERENCES public.habits(id) ON DELETE CASCADE,
  activity_date DATE DEFAULT CURRENT_DATE,
  activity_timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  details JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_user_behavior_user_id ON public.user_behavior_log(user_id);
CREATE INDEX IF NOT EXISTS idx_user_behavior_date ON public.user_behavior_log(activity_date);
CREATE INDEX IF NOT EXISTS idx_user_behavior_type ON public.user_behavior_log(activity_type);
CREATE INDEX IF NOT EXISTS idx_user_behavior_habit ON public.user_behavior_log(habit_id);

-- Enable Row Level Security
ALTER TABLE public.user_behavior_log ENABLE ROW LEVEL SECURITY;

-- User behavior policies
DROP POLICY IF EXISTS "Users can view own behavior log" ON public.user_behavior_log;
CREATE POLICY "Users can view own behavior log" 
  ON public.user_behavior_log FOR SELECT 
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own behavior log" ON public.user_behavior_log;
CREATE POLICY "Users can insert own behavior log" 
  ON public.user_behavior_log FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

-- ============================================
-- SECTION 7: STREAK ACHIEVEMENTS
-- ============================================

-- Streak Achievements table
CREATE TABLE IF NOT EXISTS public.streak_achievements (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  streak_count INTEGER NOT NULL,
  achievement_type TEXT NOT NULL,
  achieved_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  celebrated BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_streak_achievements_user_id ON public.streak_achievements(user_id);
CREATE INDEX IF NOT EXISTS idx_streak_achievements_count ON public.streak_achievements(streak_count DESC);

-- Enable Row Level Security
ALTER TABLE public.streak_achievements ENABLE ROW LEVEL SECURITY;

-- Streak achievements policies
DROP POLICY IF EXISTS "Users can view own achievements" ON public.streak_achievements;
CREATE POLICY "Users can view own achievements" 
  ON public.streak_achievements FOR SELECT 
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own achievements" ON public.streak_achievements;
CREATE POLICY "Users can insert own achievements" 
  ON public.streak_achievements FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own achievements" ON public.streak_achievements;
CREATE POLICY "Users can update own achievements" 
  ON public.streak_achievements FOR UPDATE 
  USING (auth.uid() = user_id);

-- ============================================
-- SECTION 8: FUNCTIONS
-- ============================================

-- Function: Get user's current overall streak
CREATE OR REPLACE FUNCTION get_user_current_streak(p_user_id UUID)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  streak_count INTEGER := 0;
  check_date DATE := CURRENT_DATE;
  total_habits INTEGER;
  completed_habits INTEGER;
BEGIN
  SELECT COUNT(*) INTO total_habits
  FROM public.habits
  WHERE user_id = p_user_id AND is_active = TRUE;
  
  IF total_habits = 0 THEN
    RETURN 0;
  END IF;
  
  LOOP
    SELECT COUNT(DISTINCT habit_id) INTO completed_habits
    FROM public.habit_completions
    WHERE user_id = p_user_id 
      AND completion_date = check_date;
    
    IF completed_habits < total_habits THEN
      EXIT;
    END IF;
    
    streak_count := streak_count + 1;
    check_date := check_date - INTERVAL '1 day';
  END LOOP;
  
  RETURN streak_count;
END;
$$;

-- Function: Get individual habit streak
CREATE OR REPLACE FUNCTION get_habit_streak(p_habit_id UUID, p_user_id UUID)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  streak_count INTEGER := 0;
  check_date DATE := CURRENT_DATE;
  has_completion BOOLEAN;
BEGIN
  LOOP
    SELECT EXISTS(
      SELECT 1 
      FROM public.habit_completions 
      WHERE habit_id = p_habit_id 
        AND user_id = p_user_id 
        AND completion_date = check_date
    ) INTO has_completion;
    
    IF NOT has_completion THEN
      EXIT;
    END IF;
    
    streak_count := streak_count + 1;
    check_date := check_date - INTERVAL '1 day';
  END LOOP;
  
  RETURN streak_count;
END;
$$;

-- Function: Check and record streak achievement
CREATE OR REPLACE FUNCTION check_and_record_streak(p_user_id UUID)
RETURNS TABLE(
  new_streak INTEGER,
  is_milestone BOOLEAN,
  milestone_type TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  current_streak INTEGER;
  v_is_milestone BOOLEAN := FALSE;
  v_milestone_type TEXT := NULL;
BEGIN
  current_streak := get_user_current_streak(p_user_id);
  
  IF current_streak IN (3, 7, 14, 30, 60, 90, 180, 365) THEN
    v_is_milestone := TRUE;
    
    v_milestone_type := CASE current_streak
      WHEN 3 THEN '🔥 3-Day Streak!'
      WHEN 7 THEN '⭐ Week Warrior!'
      WHEN 14 THEN '💪 2-Week Champion!'
      WHEN 30 THEN '🏆 Month Master!'
      WHEN 60 THEN '🌟 2-Month Legend!'
      WHEN 90 THEN '👑 Quarter King!'
      WHEN 180 THEN '💎 Half-Year Hero!'
      WHEN 365 THEN '🎖️ YEAR ACHIEVED!'
    END;
    
    INSERT INTO public.streak_achievements (user_id, streak_count, achievement_type, celebrated)
    VALUES (p_user_id, current_streak, v_milestone_type, FALSE)
    ON CONFLICT DO NOTHING;
  END IF;
  
  RETURN QUERY SELECT current_streak, v_is_milestone, v_milestone_type;
END;
$$;

-- Function: Record sensor reading with auto-alert
CREATE OR REPLACE FUNCTION record_sensor_reading(
  p_sensor_id TEXT,
  p_user_id UUID,
  p_raw_value INTEGER,
  p_ppm_value NUMERIC,
  p_temperature NUMERIC DEFAULT NULL,
  p_humidity NUMERIC DEFAULT NULL,
  p_location TEXT DEFAULT NULL,
  p_alert_threshold NUMERIC DEFAULT 100.0
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  reading_id UUID;
  alert_severity TEXT;
BEGIN
  INSERT INTO public.sensor_data (sensor_id, user_id, raw_value, ppm_value, temperature, humidity, location)
  VALUES (p_sensor_id, p_user_id, p_raw_value, p_ppm_value, p_temperature, p_humidity, p_location)
  RETURNING id INTO reading_id;
  
  IF p_ppm_value >= p_alert_threshold THEN
    IF p_ppm_value >= 1000 THEN
      alert_severity := 'critical';
    ELSIF p_ppm_value >= 500 THEN
      alert_severity := 'high';
    ELSIF p_ppm_value >= 200 THEN
      alert_severity := 'medium';
    ELSE
      alert_severity := 'low';
    END IF;
    
    INSERT INTO public.safety_events (
      user_id, 
      sensor_id, 
      event_type, 
      severity, 
      alert_type,
      peak_gas_level,
      current_ppm,
      auto_action_taken,
      power_cutoff_triggered,
      window_opened,
      alarm_activated,
      message,
      location
    ) VALUES (
      p_user_id,
      p_sensor_id,
      'alert',
      alert_severity,
      'threshold_exceeded',
      p_ppm_value,
      p_ppm_value,
      CASE 
        WHEN p_ppm_value >= 1000 THEN 'power_cutoff,window_open,alarm_triggered'
        WHEN p_ppm_value >= 500 THEN 'window_open,alarm_triggered'
        ELSE 'alarm_triggered'
      END,
      p_ppm_value >= 1000,
      p_ppm_value >= 500,
      TRUE,
      format('Gas level detected: %s PPM - %s severity', p_ppm_value, alert_severity),
      p_location
    );
  END IF;
  
  RETURN reading_id;
END;
$$;

-- Function: Get habit completion rate
CREATE OR REPLACE FUNCTION get_habit_completion_rate(
  p_user_id UUID,
  p_start_date DATE,
  p_end_date DATE
)
RETURNS TABLE(
  habit_id UUID,
  habit_title TEXT,
  total_days INTEGER,
  completed_days INTEGER,
  completion_rate NUMERIC
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  WITH date_range AS (
    SELECT generate_series(p_start_date, p_end_date, '1 day'::INTERVAL)::DATE AS date
  ),
  habit_dates AS (
    SELECT 
      h.id AS habit_id,
      h.title AS habit_title,
      dr.date,
      CASE 
        WHEN EXISTS(
          SELECT 1 
          FROM public.habit_completions hc 
          WHERE hc.habit_id = h.id 
            AND hc.completion_date = dr.date
        ) THEN 1 
        ELSE 0 
      END AS is_completed
    FROM public.habits h
    CROSS JOIN date_range dr
    WHERE h.user_id = p_user_id AND h.is_active = TRUE
  )
  SELECT 
    hd.habit_id,
    hd.habit_title,
    COUNT(*)::INTEGER AS total_days,
    SUM(hd.is_completed)::INTEGER AS completed_days,
    ROUND((SUM(hd.is_completed)::NUMERIC / COUNT(*)::NUMERIC) * 100, 2) AS completion_rate
  FROM habit_dates hd
  GROUP BY hd.habit_id, hd.habit_title
  ORDER BY completion_rate DESC;
END;
$$;

-- Function: Record app session
CREATE OR REPLACE FUNCTION record_app_session(p_user_id UUID)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  session_id UUID;
BEGIN
  INSERT INTO public.app_sessions (user_id, session_date, session_start)
  VALUES (p_user_id, CURRENT_DATE, NOW())
  RETURNING id INTO session_id;
  
  RETURN session_id;
END;
$$;

-- Function: End app session
CREATE OR REPLACE FUNCTION end_app_session(p_session_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.app_sessions
  SET session_end = NOW()
  WHERE id = p_session_id;
END;
$$;

-- ============================================
-- SECTION 9: TRIGGERS
-- ============================================

-- Trigger function: Update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

-- Apply triggers
DROP TRIGGER IF EXISTS update_profiles_updated_at ON public.profiles;
CREATE TRIGGER update_profiles_updated_at 
  BEFORE UPDATE ON public.profiles 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_habits_updated_at ON public.habits;
CREATE TRIGGER update_habits_updated_at 
  BEFORE UPDATE ON public.habits 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger function: Create default 5 habits for new users
CREATE OR REPLACE FUNCTION create_default_habits()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO public.habits (user_id, title, description, icon, category, target_frequency) VALUES
    (NEW.id, 'Check Gas Detector Status', 'Verify your gas detector is powered on and functioning', '🔍', 'safety', 'daily'),
    (NEW.id, 'Inspect Sensor Readings', 'Review current gas levels and sensor data', '📊', 'safety', 'daily'),
    (NEW.id, 'Test Ventilation System', 'Ensure ventilation systems are working properly', '💨', 'safety', 'daily'),
    (NEW.id, 'Visual Safety Check', 'Look for visible gas leaks or damaged equipment', '👁️', 'safety', 'daily'),
    (NEW.id, 'Emergency Plan Review', 'Review and remember your gas emergency procedures', '🚨', 'safety', 'daily');
  RETURN NEW;
END;
$$;

-- Apply trigger
DROP TRIGGER IF EXISTS create_user_default_habits ON public.profiles;
CREATE TRIGGER create_user_default_habits
  AFTER INSERT ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION create_default_habits();

-- ============================================
-- SECTION 10: VIEWS
-- ============================================

-- View: Today's habit status for user
CREATE OR REPLACE VIEW user_daily_habits AS
SELECT 
  h.id AS habit_id,
  h.user_id,
  h.title,
  h.description,
  h.icon,
  h.category,
  CASE 
    WHEN EXISTS(
      SELECT 1 
      FROM public.habit_completions hc 
      WHERE hc.habit_id = h.id 
        AND hc.completion_date = CURRENT_DATE
    ) THEN TRUE 
    ELSE FALSE 
  END AS completed_today,
  (
    SELECT COUNT(*) 
    FROM public.habit_completions hc 
    WHERE hc.habit_id = h.id
  ) AS total_completions
FROM public.habits h
WHERE h.is_active = TRUE;

-- ============================================
-- SECTION 11: PERMISSIONS
-- ============================================

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated;

-- ============================================
-- SETUP COMPLETE
-- ============================================
-- Database schema created successfully!
-- Next steps:
-- 1. Create a user account in your app
-- 2. The trigger will automatically create 5 default safety habits
-- 3. Start tracking habits and building your streak!

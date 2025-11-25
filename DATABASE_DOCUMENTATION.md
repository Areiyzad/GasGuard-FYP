# GasGuard Database Documentation

## Database Overview
Complete Supabase database schema for GasGuard app with sensor monitoring, safety events, and daily safety habits tracking.

---

## 📊 Database Tables

### 1. **sensor_data** - Raw Gas Readings
Stores all sensor readings with raw values and calculated PPM.

**Columns:**
- `id` (UUID) - Primary key
- `sensor_id` (TEXT) - Physical sensor identifier
- `user_id` (UUID) - Foreign key to profiles
- `raw_value` (INTEGER) - Raw ADC value from sensor
- `ppm_value` (NUMERIC) - Calculated Parts Per Million
- `temperature` (NUMERIC) - Temperature in Celsius
- `humidity` (NUMERIC) - Humidity percentage
- `location` (TEXT) - Sensor location (Kitchen, Garage, etc.)
- `timestamp` (TIMESTAMP) - When reading was taken
- `created_at` (TIMESTAMP) - Record creation time

**Usage:**
```dart
// Record sensor reading with auto-alert
await supabase.rpc('record_sensor_reading', params: {
  'p_sensor_id': 'SENSOR_001',
  'p_user_id': userId,
  'p_raw_value': 512,
  'p_ppm_value': 150.5,
  'p_temperature': 25.3,
  'p_humidity': 65.0,
  'p_location': 'Kitchen',
  'p_alert_threshold': 100.0,
});
```

---

### 2. **safety_events** - Alert & Action Log
Tracks all safety alerts and automated actions taken.

**Columns:**
- `id` (UUID) - Primary key
- `user_id` (UUID) - Foreign key to profiles
- `sensor_id` (TEXT) - Which sensor triggered event
- `event_type` (TEXT) - 'alert', 'warning', 'critical', 'auto_action'
- `severity` (TEXT) - 'low', 'medium', 'high', 'critical'
- `alert_type` (TEXT) - 'gas_detected', 'threshold_exceeded', 'sensor_malfunction'
- `peak_gas_level` (NUMERIC) - Peak PPM during event
- `current_ppm` (NUMERIC) - Current PPM when triggered
- `auto_action_taken` (TEXT) - Actions: 'power_cutoff', 'window_open', 'alarm_triggered'
- `power_cutoff_triggered` (BOOLEAN) - Was power cut off?
- `window_opened` (BOOLEAN) - Was window opened?
- `alarm_activated` (BOOLEAN) - Was alarm triggered?
- `message` (TEXT) - Event description
- `location` (TEXT) - Where event occurred
- `resolved` (BOOLEAN) - Has event been resolved?
- `resolved_at` (TIMESTAMP) - When resolved
- `event_timestamp` (TIMESTAMP) - When event occurred

**Automated Actions:**
- **PPM ≥ 1000**: Power cutoff + Window open + Alarm
- **PPM ≥ 500**: Window open + Alarm
- **PPM ≥ 100**: Alarm only

**Usage:**
```dart
// Get unresolved safety events
final events = await supabase
  .from('safety_events')
  .select()
  .eq('user_id', userId)
  .eq('resolved', false)
  .order('event_timestamp', ascending: false);

// Mark event as resolved
await supabase
  .from('safety_events')
  .update({'resolved': true, 'resolved_at': DateTime.now().toIso8601String()})
  .eq('id', eventId);
```

---

### 3. **habits** - Daily Safety Habits
5 daily safety habits that users must complete.

**Default Habits:**
1. 🔍 Check Gas Detector Status
2. 📊 Inspect Sensor Readings
3. 💨 Test Ventilation System
4. 👁️ Visual Safety Check
5. 🚨 Emergency Plan Review

**Columns:**
- `id` (UUID) - Primary key
- `user_id` (UUID) - Foreign key to profiles
- `title` (TEXT) - Habit name
- `description` (TEXT) - What to do
- `icon` (TEXT) - Emoji icon
- `category` (TEXT) - 'safety'
- `target_frequency` (TEXT) - 'daily'
- `is_active` (BOOLEAN) - Is habit enabled
- `created_at` (TIMESTAMP)
- `updated_at` (TIMESTAMP)

---

### 4. **habit_completions** - Daily Completion Records
Tracks when each habit is completed.

**Columns:**
- `id` (UUID) - Primary key
- `habit_id` (UUID) - Foreign key to habits
- `user_id` (UUID) - Foreign key to profiles
- `completed_at` (TIMESTAMP) - Exact completion time
- `completion_date` (DATE) - Date only for tracking
- `notes` (TEXT) - Optional notes
- `created_at` (TIMESTAMP)

**Usage:**
```dart
// Mark habit complete
await supabase.from('habit_completions').insert({
  'habit_id': habitId,
  'user_id': userId,
  'completion_date': DateTime.now().toIso8601String().split('T')[0],
});

// Check if completed today
final isCompleted = await supabase
  .from('habit_completions')
  .select('id')
  .eq('habit_id', habitId)
  .eq('user_id', userId)
  .eq('completion_date', DateTime.now().toIso8601String().split('T')[0])
  .maybeSingle();
```

---

### 5. **user_behavior_log** - Activity Tracking
Logs all user activities for analytics.

**Columns:**
- `id` (UUID) - Primary key
- `user_id` (UUID) - Foreign key to profiles
- `activity_type` (TEXT) - 'habit_completed', 'app_opened', 'sensor_checked', 'alert_acknowledged'
- `habit_id` (UUID) - Related habit (if applicable)
- `activity_date` (DATE) - Date of activity
- `activity_timestamp` (TIMESTAMP) - Exact time
- `details` (JSONB) - Additional metadata
- `created_at` (TIMESTAMP)

**Usage:**
```dart
// Log activity
await supabase.from('user_behavior_log').insert({
  'user_id': userId,
  'activity_type': 'habit_completed',
  'habit_id': habitId,
  'details': {'completion_time': DateTime.now().toIso8601String()},
});
```

---

### 6. **streak_achievements** - Milestone Tracking
Records streak milestones for celebration popups.

**Milestones:**
- 🔥 3 days - "3-Day Streak!"
- ⭐ 7 days - "Week Warrior!"
- 💪 14 days - "2-Week Champion!"
- 🏆 30 days - "Month Master!"
- 🌟 60 days - "2-Month Legend!"
- 👑 90 days - "Quarter King!"
- 💎 180 days - "Half-Year Hero!"
- 🎖️ 365 days - "YEAR ACHIEVED!"

**Columns:**
- `id` (UUID) - Primary key
- `user_id` (UUID) - Foreign key to profiles
- `streak_count` (INTEGER) - Number of consecutive days
- `achievement_type` (TEXT) - Milestone name
- `achieved_at` (TIMESTAMP) - When milestone reached
- `celebrated` (BOOLEAN) - Has popup been shown?
- `created_at` (TIMESTAMP)

---

## 🔥 Streak System

### How It Works
1. User completes **all 5 daily safety habits**
2. System checks if it's a consecutive day
3. If milestone reached (3, 7, 14, 30, etc.), show TikTok-style popup
4. Record achievement in database
5. Continue counting streak

### Get Current Streak
```dart
final streak = await supabase.rpc('get_user_current_streak', params: {
  'p_user_id': userId,
});
```

### Check for Milestone
```dart
final result = await supabase.rpc('check_and_record_streak', params: {
  'p_user_id': userId,
});

// Returns:
// {
//   'new_streak': 7,
//   'is_milestone': true,
//   'milestone_type': '⭐ Week Warrior!'
// }
```

---

## 🚨 Safety Alert System

### Automatic Alert Triggers

**Function: `record_sensor_reading()`**

Automatically creates safety events when PPM thresholds are exceeded:

| PPM Level | Severity | Auto Actions |
|-----------|----------|--------------|
| ≥ 1000 | Critical | Power cutoff + Window + Alarm |
| ≥ 500 | High | Window + Alarm |
| ≥ 200 | Medium | Alarm only |
| ≥ 100 | Low | Alarm only |

**Usage:**
```dart
// Record reading - alerts created automatically if needed
final readingId = await supabase.rpc('record_sensor_reading', params: {
  'p_sensor_id': 'SENSOR_001',
  'p_user_id': userId,
  'p_raw_value': 850,
  'p_ppm_value': 1200.0, // CRITICAL LEVEL!
  'p_location': 'Kitchen',
  'p_alert_threshold': 100.0,
});
```

---

## 📱 Flutter Integration

### Initialize User
```dart
// Ensure profile exists (creates default 5 habits)
await habitService.ensureUserProfile();

// Record app session
await habitService.recordAppSession();
```

### Complete Habit & Check Streak
```dart
// Mark habit complete
await habitService.completeHabit(habitId);

// Log activity
await habitService.logUserActivity(
  'habit_completed',
  habitId: habitId,
  details: {'habit_title': habit.title},
);

// Check if all 5 habits completed
if (allHabitsCompleted) {
  final streakInfo = await habitService.checkAndRecordStreak();
  
  if (streakInfo != null && streakInfo['is_milestone']) {
    // Show TikTok-style celebration popup!
    showStreakPopup(
      streakInfo['new_streak'],
      streakInfo['milestone_type'],
    );
  }
}
```

### Get Dashboard Summary
```dart
final summary = await supabase.rpc('get_safety_dashboard_summary', params: {
  'user_id': userId,
});

// Returns:
// {
//   'active_alerts': 2,
//   'avg_ppm_24h': 45.3,
//   'current_streak': 7,
//   'habits_completed_today': 5
// }
```

---

## 🔒 Row Level Security (RLS)

All tables have RLS enabled. Users can only:
- View their own data
- Insert their own data
- Update their own data
- Delete their own data

**Policy Example:**
```sql
CREATE POLICY "Users can view own sensor data" 
  ON public.sensor_data FOR SELECT 
  USING (auth.uid() = user_id);
```

---

## 📈 Analytics Queries

### Sensor Trends
```sql
-- Average PPM over last 7 days
SELECT DATE(timestamp) as date, AVG(ppm_value) as avg_ppm
FROM sensor_data
WHERE user_id = 'USER_UUID'
  AND timestamp >= NOW() - INTERVAL '7 days'
GROUP BY DATE(timestamp)
ORDER BY date;
```

### Safety Events Report
```sql
-- Count events by severity
SELECT severity, COUNT(*) as count
FROM safety_events
WHERE user_id = 'USER_UUID'
GROUP BY severity
ORDER BY count DESC;
```

### Habit Completion Rate
```sql
-- Completion rate for last 30 days
SELECT * FROM get_habit_completion_rate(
  'USER_UUID',
  CURRENT_DATE - INTERVAL '30 days',
  CURRENT_DATE
);
```

---

## 🎯 Key Features

✅ **Real-time sensor monitoring** with automatic PPM calculation  
✅ **Automated safety responses** (power cutoff, window control, alarms)  
✅ **5 daily safety habits** with streak tracking  
✅ **TikTok-style milestone celebrations** (3, 7, 14, 30+ days)  
✅ **Complete activity logging** for user behavior analysis  
✅ **Row-level security** for data privacy  
✅ **Comprehensive analytics** with built-in SQL functions

---

## 📝 Setup Instructions

1. **Run SQL Schema**
   ```bash
   # Copy supabase_schema.sql to Supabase SQL Editor
   # Execute to create all tables, functions, and triggers
   ```

2. **Test Connection**
   ```dart
   // In your Flutter app
   print('🚀 Initializing Supabase...');
   await Supabase.initialize(url: 'YOUR_URL', anonKey: 'YOUR_KEY');
   print('✅ Connected!');
   ```

3. **Create First User**
   ```dart
   await habitService.ensureUserProfile();
   // This automatically creates 5 default safety habits
   ```

4. **Start Tracking**
   ```dart
   // Record sensor data
   await supabase.rpc('record_sensor_reading', ...);
   
   // Complete habits
   await habitService.completeHabit(habitId);
   
   // Check streak
   final streak = await habitService.getCurrentStreak();
   ```

---

## 🎨 UI Components

- **Sensor Dashboard**: Real-time PPM display with color-coded alerts
- **Safety Events Panel**: List of unresolved alerts with action buttons
- **Habit Tracker**: 5 daily habits with checkboxes and streak counter
- **Streak Popup**: TikTok-style fullscreen celebration with confetti
- **Analytics Charts**: Historical sensor data and completion trends

---

**Last Updated:** November 25, 2025  
**Database Version:** 2.0  
**Schema File:** `supabase_schema.sql`

# Supabase Database Setup for GasGuard Habit Tracking

## Quick Start

1. **Copy the SQL file**: Open `supabase_schema.sql`
2. **Run in Supabase**:
   - Go to your Supabase project dashboard
   - Navigate to SQL Editor
   - Paste the entire SQL schema
   - Click "Run" to execute

## Database Structure

### Tables

#### 1. `profiles`
Extends Supabase auth.users with additional user data
- `id` (UUID): User ID from auth.users
- `username` (TEXT): Optional username
- `created_at`, `updated_at`: Timestamps

#### 2. `habits`
Stores user's gas safety habits
- `id` (UUID): Habit unique ID
- `user_id` (UUID): Owner
- `title` (TEXT): Habit name
- `description` (TEXT): Details
- `icon` (TEXT): Emoji or icon name
- `category` (TEXT): 'safety', 'maintenance', 'awareness'
- `target_frequency` (TEXT): 'daily', 'weekly', 'monthly'
- `is_active` (BOOLEAN): Active status

#### 3. `habit_completions`
Tracks each habit completion
- `id` (UUID): Completion ID
- `habit_id` (UUID): Reference to habit
- `user_id` (UUID): User who completed
- `completed_at` (TIMESTAMP): Exact completion time
- `completion_date` (DATE): Date for daily tracking
- `notes` (TEXT): Optional notes

#### 4. `app_sessions`
Tracks when users open the app
- `id` (UUID): Session ID
- `user_id` (UUID): User
- `session_date` (DATE): Date of session
- `session_start` (TIMESTAMP): When app opened
- `session_end` (TIMESTAMP): When app closed

## Functions

### `record_app_session(user_id)`
Call when user opens the app. Returns session ID.

```sql
SELECT record_app_session('user-uuid-here');
```

### `get_habit_streak(habit_id, user_id)`
Calculate current streak for a habit.

```sql
SELECT get_habit_streak('habit-uuid', 'user-uuid');
```

### `get_habit_completion_rate(user_id, start_date, end_date)`
Get completion statistics for date range.

```sql
SELECT * FROM get_habit_completion_rate(
  'user-uuid', 
  '2025-11-01', 
  '2025-11-24'
);
```

## Flutter Integration Examples

### 1. Initialize User Profile
```dart
final user = Supabase.instance.client.auth.currentUser;
if (user != null) {
  await Supabase.instance.client
    .from('profiles')
    .upsert({'id': user.id, 'username': 'User Name'});
}
```

### 2. Record App Session
```dart
final userId = Supabase.instance.client.auth.currentUser?.id;
final response = await Supabase.instance.client
  .rpc('record_app_session', params: {'p_user_id': userId});
final sessionId = response as String;
```

### 3. Fetch Today's Habits
```dart
final userId = Supabase.instance.client.auth.currentUser?.id;
final response = await Supabase.instance.client
  .from('user_daily_habits')
  .select()
  .eq('user_id', userId);
```

### 4. Mark Habit Complete
```dart
await Supabase.instance.client
  .from('habit_completions')
  .insert({
    'habit_id': habitId,
    'user_id': userId,
    'completion_date': DateTime.now().toIso8601String().split('T')[0],
  });
```

### 5. Get Habit Streak
```dart
final streak = await Supabase.instance.client
  .rpc('get_habit_streak', params: {
    'p_habit_id': habitId,
    'p_user_id': userId,
  });
```

### 6. Check if Habit Completed Today
```dart
final today = DateTime.now().toIso8601String().split('T')[0];
final response = await Supabase.instance.client
  .from('habit_completions')
  .select('id')
  .eq('habit_id', habitId)
  .eq('user_id', userId)
  .eq('completion_date', today)
  .maybeSingle();

final isCompleted = response != null;
```

## Features Included

✅ **Row Level Security (RLS)**: Users can only access their own data
✅ **Default Habits**: 5 gas safety habits created automatically for new users
✅ **Streak Tracking**: Calculate consecutive completion days
✅ **Completion Statistics**: Analyze habit performance over time
✅ **App Session Tracking**: Know when users engage with the app
✅ **Efficient Indexing**: Fast queries for date-based lookups
✅ **Automatic Timestamps**: created_at and updated_at maintained automatically

## Security

All tables use Row Level Security policies ensuring:
- Users can only view/modify their own data
- Auth is required for all operations
- Function execution is secure with SECURITY DEFINER

## Next Steps

1. Run the SQL schema in Supabase
2. Update your Flutter app's Supabase credentials in `main.dart`
3. Create models for habits and completions in Flutter
4. Implement habit tracking UI using the queries above

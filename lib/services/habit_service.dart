import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/habit_model.dart';

class HabitService {
  final SupabaseClient _client = Supabase.instance.client;

  // Get current user ID
  String? get _userId => _client.auth.currentUser?.id;

  // Record app session when user opens the app
  Future<String?> recordAppSession() async {
    try {
      if (_userId == null) return null;
      
      final response = await _client.rpc('record_app_session', params: {
        'p_user_id': _userId,
      });
      
      return response as String?;
    } catch (e) {
      print('Error recording app session: $e');
      return null;
    }
  }

  // Get all habits for current user
  Future<List<Habit>> getUserHabits() async {
    try {
      if (_userId == null) {
        print('❌ getUserHabits: No user ID!');
        return [];
      }

      print('🔍 Fetching habits for user: $_userId');

      final response = await _client
          .from('habits')
          .select()
          .eq('user_id', _userId!)
          .eq('is_active', true)
          .order('created_at');

      print('📦 Habits response: $response');
      print('📊 Total habits found: ${(response as List).length}');

      final habits = (response as List)
          .map((json) => Habit.fromJson(json))
          .toList();

      // Get streaks for each habit
      for (var habit in habits) {
        habit.streak = await getHabitStreak(habit.id);
        habit.completed = await isHabitCompletedToday(habit.id);
      }

      print('✅ Loaded ${habits.length} habits with completion status');
      return habits;
    } catch (e) {
      print('❌ Error fetching habits: $e');
      return [];
    }
  }

  // Add new habit
  Future<Habit?> addHabit({
    required String title,
    String? description,
    String? icon,
    String category = 'daily',
    String targetFrequency = 'daily',
    bool completeToday = false, // Option to mark complete immediately
  }) async {
    try {
      if (_userId == null) return null;

      final habit = Habit(
        id: '',
        userId: _userId!,
        title: title,
        description: description,
        icon: icon,
        category: category,
        targetFrequency: targetFrequency,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final response = await _client
          .from('habits')
          .insert(habit.toInsert())
          .select()
          .single();

      final newHabit = Habit.fromJson(response);

      // Optionally mark as completed for today
      if (completeToday) {
        await completeHabit(newHabit.id);
        newHabit.completed = true;
      }

      return newHabit;
    } catch (e) {
      print('Error adding habit: $e');
      return null;
    }
  }

  // Mark habit as completed for today
  Future<bool> completeHabit(String habitId, {String? notes}) async {
    try {
      if (_userId == null) return false;

      // Check if already completed today
      final isCompleted = await isHabitCompletedToday(habitId);
      if (isCompleted) {
        print('✅ Habit $habitId already completed today');
        return true;
      }

      final today = DateTime.now().toIso8601String().split('T')[0];

      print('📝 Inserting habit completion: habit=$habitId, user=$_userId, date=$today');
      
      await _client.from('habit_completions').insert({
        'habit_id': habitId,
        'user_id': _userId!,
        'completion_date': today,
        'notes': notes,
      });

      print('✅ Habit completed successfully!');
      return true;
    } catch (e) {
      print('❌ Error completing habit: $e');
      return false;
    }
  }

  // Uncomplete habit for today (remove completion)
  Future<bool> uncompleteHabit(String habitId) async {
    try {
      if (_userId == null) return false;

      final today = DateTime.now().toIso8601String().split('T')[0];

      await _client
          .from('habit_completions')
          .delete()
          .eq('habit_id', habitId)
          .eq('user_id', _userId!)
          .eq('completion_date', today);

      return true;
    } catch (e) {
      print('Error uncompleting habit: $e');
      return false;
    }
  }

  // Check if habit is completed today
  Future<bool> isHabitCompletedToday(String habitId) async {
    try {
      if (_userId == null) return false;

      final today = DateTime.now().toIso8601String().split('T')[0];

      final response = await _client
          .from('habit_completions')
          .select('id')
          .eq('habit_id', habitId)
          .eq('user_id', _userId!)
          .eq('completion_date', today)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Error checking habit completion: $e');
      return false;
    }
  }

  // Get habit streak (consecutive days)
  Future<int> getHabitStreak(String habitId) async {
    try {
      if (_userId == null) return 0;

      final response = await _client.rpc('get_habit_streak', params: {
        'p_habit_id': habitId,
        'p_user_id': _userId!,
      });

      return response as int? ?? 0;
    } catch (e) {
      print('Error getting habit streak: $e');
      return 0;
    }
  }

  // Get all completions for a specific date
  Future<List<HabitCompletion>> getCompletionsForDate(DateTime date) async {
    try {
      if (_userId == null) return [];

      final dateStr = date.toIso8601String().split('T')[0];

      final response = await _client
          .from('habit_completions')
          .select()
          .eq('user_id', _userId!)
          .eq('completion_date', dateStr)
          .order('completed_at', ascending: false);

      return (response as List)
          .map((json) => HabitCompletion.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching completions: $e');
      return [];
    }
  }

  // Get habit completions for a specific date and habit
  Future<List<HabitCompletion>> getHabitCompletionsForDate(String habitId, DateTime date) async {
    try {
      if (_userId == null) return [];

      final dateStr = date.toIso8601String().split('T')[0];

      final response = await _client
          .from('habit_completions')
          .select()
          .eq('user_id', _userId!)
          .eq('habit_id', habitId)
          .eq('completion_date', dateStr)
          .order('completed_at', ascending: false);

      return (response as List)
          .map((json) => HabitCompletion.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching habit completions for date: $e');
      return [];
    }
  }

  // Get completion rate for date range
  Future<Map<String, dynamic>> getCompletionRate({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      if (_userId == null) return {};

      final response = await _client.rpc('get_habit_completion_rate', params: {
        'p_user_id': _userId!,
        'p_start_date': startDate.toIso8601String().split('T')[0],
        'p_end_date': endDate.toIso8601String().split('T')[0],
      });

      return response as Map<String, dynamic>? ?? {};
    } catch (e) {
      print('Error getting completion rate: $e');
      return {};
    }
  }

  // Update habit
  Future<bool> updateHabit(String habitId, Map<String, dynamic> updates) async {
    try {
      if (_userId == null) return false;

      await _client
          .from('habits')
          .update(updates)
          .eq('id', habitId)
          .eq('user_id', _userId!);

      return true;
    } catch (e) {
      print('Error updating habit: $e');
      return false;
    }
  }

  // Delete habit (soft delete - set is_active to false)
  Future<bool> deleteHabit(String habitId) async {
    try {
      if (_userId == null) return false;

      await _client
          .from('habits')
          .update({'is_active': false})
          .eq('id', habitId)
          .eq('user_id', _userId!);

      return true;
    } catch (e) {
      print('Error deleting habit: $e');
      return false;
    }
  }

  // Ensure user profile exists
  Future<void> ensureUserProfile() async {
    try {
      if (_userId == null) {
        print('❌ ensureUserProfile: No user logged in!');
        print('🔐 Current user: ${_client.auth.currentUser}');
        return;
      }

      print('👤 Checking profile for user: $_userId');

      // Check if profile exists
      final existing = await _client
          .from('profiles')
          .select('id')
          .eq('id', _userId!)
          .maybeSingle();

      if (existing == null) {
        print('📝 Creating new profile for user: $_userId');
        // Create profile - this should trigger the default habits creation
        await _client.from('profiles').insert({
          'id': _userId!,
        });
        print('✅ Profile created! Default habits should be auto-created by trigger.');
      } else {
        print('✅ Profile already exists');
      }
    } catch (e) {
      print('❌ Error ensuring user profile: $e');
    }
  }

  // Get current user's overall streak (all 5 habits completed daily)
  Future<int> getCurrentStreak() async {
    try {
      if (_userId == null) {
        print('❌ getCurrentStreak: No user ID');
        return 0;
      }

      print('🔍 Calling get_user_current_streak for user: $_userId');
      final response = await _client.rpc('get_user_current_streak', params: {
        'p_user_id': _userId!,
      });

      print('✅ Streak response: $response (type: ${response.runtimeType})');
      return response as int? ?? 0;
    } catch (e) {
      print('❌ Error getting current streak: $e');
      return 0;
    }
  }

  // Check and record streak achievement (returns milestone info)
  Future<Map<String, dynamic>?> checkAndRecordStreak() async {
    try {
      if (_userId == null) {
        print('❌ checkAndRecordStreak: No user ID');
        return null;
      }

      print('🔍 Calling check_and_record_streak for user: $_userId');
      final response = await _client.rpc('check_and_record_streak', params: {
        'p_user_id': _userId!,
      });

      print('📦 Raw response from check_and_record_streak: $response (type: ${response.runtimeType})');

      if (response is List && response.isNotEmpty) {
        final result = response.first as Map<String, dynamic>;
        print('✅ Parsed result: $result');
        return {
          'new_streak': result['new_streak'] ?? 0,
          'is_milestone': result['is_milestone'] ?? false,
          'milestone_type': result['milestone_type'],
        };
      }

      print('⚠️ Response is not a list or is empty');
      return null;
    } catch (e) {
      print('❌ Error checking streak: $e');
      return null;
    }
  }

  // Get uncelebrated achievements
  Future<List<Map<String, dynamic>>> getUncelebratedAchievements() async {
    try {
      if (_userId == null) return [];

      final response = await _client
          .from('streak_achievements')
          .select()
          .eq('user_id', _userId!)
          .eq('celebrated', false)
          .order('achieved_at', ascending: false);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error fetching achievements: $e');
      return [];
    }
  }

  // Mark achievement as celebrated
  Future<bool> markAchievementCelebrated(String achievementId) async {
    try {
      await _client
          .from('streak_achievements')
          .update({'celebrated': true})
          .eq('id', achievementId);

      return true;
    } catch (e) {
      print('Error marking achievement celebrated: $e');
      return false;
    }
  }

  // Log user behavior activity
  Future<void> logUserActivity(String activityType, {String? habitId, Map<String, dynamic>? details}) async {
    try {
      if (_userId == null) return;

      await _client.from('user_behavior_log').insert({
        'user_id': _userId!,
        'activity_type': activityType,
        'habit_id': habitId,
        'details': details,
      });
    } catch (e) {
      print('Error logging user activity: $e');
    }
  }
}

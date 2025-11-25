import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:confetti/confetti.dart';
import 'widgets/glassy.dart';
import 'models/habit_model.dart';
import 'services/habit_service.dart';

class HabitTrackerPage extends StatefulWidget {
  const HabitTrackerPage({super.key});

  @override
  State<HabitTrackerPage> createState() => _HabitTrackerPageState();
}

class _HabitTrackerPageState extends State<HabitTrackerPage>
    with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _streakAnimationController;
  final HabitService _habitService = HabitService();

  int currentStreak = 0;
  List<Habit> _habits = [];
  bool _isLoading = true;
  int daysCompletedThisMonth = 0;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _streakAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _initializeHabits();
  }

  Future<void> _initializeHabits() async {
    setState(() => _isLoading = true);
    
    print('🚀 Initializing habits...');
    
    // Ensure user profile exists
    print('👤 Ensuring user profile...');
    await _habitService.ensureUserProfile();
    
    // Record app session
    print('📱 Recording app session...');
    await _habitService.recordAppSession();
    
    // Load habits
    print('📋 Loading habits...');
    await _loadHabits();
    
    print('✅ Initialization complete. Total habits: ${_habits.length}');
    
    setState(() => _isLoading = false);
  }

  Future<void> _loadHabits() async {
    final habits = await _habitService.getUserHabits();
    final overallStreak = await _habitService.getCurrentStreak();
    print('📊 Loaded habits - Streak: $overallStreak');
    setState(() {
      _habits = habits;
      currentStreak = overallStreak;
      daysCompletedThisMonth = overallStreak; // Monthly progress = current streak
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _streakAnimationController.dispose();
    super.dispose();
  }

  Future<void> _checkHabit(int index) async {
    final habit = _habits[index];
    final wasCompleted = habit.completed;

    // Optimistic UI update
    setState(() {
      _habits[index].completed = !wasCompleted;
    });

    bool success;
    if (wasCompleted) {
      success = await _habitService.uncompleteHabit(habit.id);
      // Log uncomplete activity
      await _habitService.logUserActivity('habit_uncompleted', habitId: habit.id);
    } else {
      success = await _habitService.completeHabit(habit.id);
      // Log complete activity
      await _habitService.logUserActivity('habit_completed', habitId: habit.id, details: {
        'habit_title': habit.title,
        'completion_time': DateTime.now().toIso8601String(),
      });
    }

    if (success) {
      // Check if all 5 habits are now completed
      final allCompleted = _habits.every((h) => h.completed);
      
      if (allCompleted && !wasCompleted) {
        // All habits completed! Check for streak milestone
        print('🎉 All 5 habits completed! Checking streak...');
        final streakInfo = await _habitService.checkAndRecordStreak();
        
        print('Streak info: $streakInfo');
        
        if (streakInfo != null) {
          final currentStreak = streakInfo['new_streak'] as int;
          final isMilestone = streakInfo['is_milestone'] as bool;
          final milestoneType = streakInfo['milestone_type'] as String?;
          
          print('Current streak: $currentStreak, Is milestone: $isMilestone');
          
          // Reload monthly progress (same as current streak)
          final monthlyCompletion = currentStreak;
          
          setState(() {
            this.currentStreak = currentStreak;
            daysCompletedThisMonth = monthlyCompletion;
          });
          
          print('Updated UI - Streak: $currentStreak, Monthly: $monthlyCompletion');
          
          // Always show TikTok-style celebration when all 5 habits completed
          _showTikTokStreakCelebration(currentStreak, isMilestone, milestoneType);
        } else {
          print('❌ Streak info is null!');
        }
      } else {
        // Refresh individual streak and monthly progress
        final newStreak = await _habitService.getHabitStreak(habit.id);
        final overallStreak = await _habitService.getCurrentStreak();
        final monthlyCompletion = overallStreak; // Same as streak
        setState(() {
          _habits[index].streak = newStreak;
          currentStreak = overallStreak;
          daysCompletedThisMonth = monthlyCompletion;
        });
        print('Updated single habit - Overall streak: $overallStreak, Monthly: $monthlyCompletion');
      }
    } else {
      // Revert on failure
      setState(() {
        _habits[index].completed = wasCompleted;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update habit. Please try again.')),
        );
      }
    }
  }

  void _showAddHabitDialog() {
    // Define 5 default safety habit options
    final List<Map<String, String>> habitOptions = [
      {
        'title': 'Check Gas Detector Status',
        'description': 'Verify your gas detector is powered on and functioning',
        'icon': '🔍',
      },
      {
        'title': 'Inspect Sensor Readings',
        'description': 'Review current gas levels and sensor data',
        'icon': '📊',
      },
      {
        'title': 'Test Ventilation System',
        'description': 'Ensure ventilation systems are working properly',
        'icon': '💨',
      },
      {
        'title': 'Visual Safety Check',
        'description': 'Look for visible gas leaks or damaged equipment',
        'icon': '👁️',
      },
      {
        'title': 'Emergency Plan Review',
        'description': 'Review and remember your gas emergency procedures',
        'icon': '🚨',
      },
    ];

    // Track which options are selected
    Set<int> selectedOptions = {};

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: GlassyContainer(
          borderRadius: BorderRadius.circular(20),
          padding: const EdgeInsets.all(24),
          child: StatefulBuilder(
            builder: (context, setDialogState) => SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Complete Daily Safety Habits',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Complete all 5 to build your streak! 🔥',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Progress indicator
                  GlassyContainer(
                    borderRadius: BorderRadius.circular(12),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Progress',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${selectedOptions.length}/5',
                              style: TextStyle(
                                color: selectedOptions.length == 5 
                                  ? const Color(0xFF10B981) 
                                  : Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: selectedOptions.length / 5,
                            minHeight: 8,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              selectedOptions.length == 5 
                                ? const Color(0xFF10B981) 
                                : const Color(0xFF3B82F6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // 5 Habit Options
                  ...List.generate(5, (index) {
                    final option = habitOptions[index];
                    final isSelected = selectedOptions.contains(index);
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: GlassyContainer(
                        borderRadius: BorderRadius.circular(12),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              setDialogState(() {
                                if (isSelected) {
                                  selectedOptions.remove(index);
                                } else {
                                  selectedOptions.add(index);
                                }
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: isSelected 
                                        ? const Color(0xFF10B981).withOpacity(0.2) 
                                        : Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      option['icon']!,
                                      style: const TextStyle(fontSize: 24),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          option['title']!,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: isSelected 
                                              ? Colors.white 
                                              : Colors.white.withOpacity(0.9),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          option['description']!,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.white.withOpacity(0.6),
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (isSelected)
                                    const Icon(
                                      Icons.check_circle,
                                      color: Color(0xFF10B981),
                                      size: 24,
                                    )
                                  else
                                    Icon(
                                      Icons.circle_outlined,
                                      color: Colors.white.withOpacity(0.3),
                                      size: 24,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: selectedOptions.length == 5 ? () async {
                            Navigator.pop(context);
                            
                            // Mark all habits as complete
                            for (int i = 0; i < _habits.length && i < 5; i++) {
                              if (!_habits[i].completed) {
                                await _habitService.completeHabit(_habits[i].id);
                                await _habitService.logUserActivity(
                                  'habit_completed',
                                  habitId: _habits[i].id,
                                  details: {
                                    'habit_title': _habits[i].title,
                                    'completion_time': DateTime.now().toIso8601String(),
                                    'from_dialog': true,
                                  },
                                );
                              }
                            }
                            
                            // Reload habits to update UI
                            await _loadHabits();
                            
                            // Check for streak and show celebration
                            final streakInfo = await _habitService.checkAndRecordStreak();
                            
                            if (streakInfo != null) {
                              final currentStreak = streakInfo['new_streak'] as int;
                              final isMilestone = streakInfo['is_milestone'] as bool;
                              final milestoneType = streakInfo['milestone_type'] as String?;
                              
                              print('Dialog completion - Streak: $currentStreak');
                              
                              // Monthly progress is same as current streak
                              final monthlyCompletion = currentStreak;
                              
                              setState(() {
                                this.currentStreak = currentStreak;
                                daysCompletedThisMonth = monthlyCompletion;
                              });
                              
                              print('Updated UI from dialog - Streak: $currentStreak, Monthly: $monthlyCompletion');
                              
                              // Always show TikTok-style celebration
                              _showTikTokStreakCelebration(currentStreak, isMilestone, milestoneType);
                            }
                            
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('🎉 All 5 habits completed!'),
                                  backgroundColor: Color(0xFF10B981),
                                ),
                              );
                            }
                          } : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: selectedOptions.length == 5 
                              ? const Color(0xFF10B981) 
                              : Colors.grey,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            selectedOptions.length == 5 
                              ? 'Complete All ✓' 
                              : 'Select All (${selectedOptions.length}/5)',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showTikTokStreakCelebration(int streak, bool isMilestone, String? milestoneType) {
    _confettiController.play();
    _streakAnimationController.forward(from: 0);

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.95),
      builder: (context) => _buildTikTokStreakPopup(streak, isMilestone, milestoneType),
    );
  }

  Widget _buildTikTokStreakPopup(int streak, bool isMilestone, String? milestoneType) {
    return Stack(
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: math.pi / 2,
            maxBlastForce: 5,
            minBlastForce: 2,
            emissionFrequency: 0.05,
            numberOfParticles: 50,
            gravity: 0.3,
            colors: const [
              Color(0xFF10B981),
              Color(0xFF3B82F6),
              Color(0xFFF59E0B),
              Color(0xFFEF4444),
              Color(0xFF8B5CF6),
            ],
          ),
        ),
        Center(
          child: ScaleTransition(
            scale: CurvedAnimation(
              parent: _streakAnimationController,
              curve: Curves.elasticOut,
            ),
            child: GlassyContainer(
              borderRadius: BorderRadius.circular(30),
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                      // Fire emoji with animation
                      AnimatedBuilder(
                        animation: _streakAnimationController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: 1 + (math.sin(_streakAnimationController.value * math.pi * 4) * 0.1),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.orange.withOpacity(0.5),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: const Text(
                                '🔥',
                                style: TextStyle(fontSize: 80),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      // Streak number
                      // Milestone badge (if applicable)
                      if (isMilestone && milestoneType != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withOpacity(0.6),
                                blurRadius: 15,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                          child: Text(
                            milestoneType,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      // Streak count with gradient
                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: isMilestone 
                            ? [const Color(0xFFFFD700), const Color(0xFFFFA500)]
                            : [Colors.white, const Color(0xFF10B981)],
                        ).createShader(bounds),
                        child: Text(
                          '$streak',
                          style: const TextStyle(
                            fontSize: 80,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        streak == 1 ? 'DAY STREAK!' : 'DAYS STREAK!',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '✨ All 5 Safety Habits Completed! ✨',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isMilestone 
                          ? 'You\'ve reached a milestone! Keep up the amazing work! 🎉'
                          : 'Great job staying safe! Keep it going! 🔥',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Continue button (TikTok style)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isMilestone 
                              ? const Color(0xFFFFD700)
                              : const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 5,
                          ),
                          child: const Text(
                            'Continue',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      ],
    );
  }



  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    int completedHabits = _habits.where((h) => h.completed).length;
    double progress = _habits.isEmpty ? 0 : completedHabits / _habits.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildStreakCard(),
          const SizedBox(height: 24),
          _buildProgressCard(completedHabits, progress),
          const SizedBox(height: 24),
          _buildHabitsList(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Safety Habits',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                'Build consistent gas safety practices',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white70,
                    ),
              ),
            ],
          ),
        ),
        FloatingActionButton(
          onPressed: _showAddHabitDialog,
          backgroundColor: const Color(0xFF3B82F6),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildStreakCard() {
    return GlassyContainer(
      borderRadius: BorderRadius.circular(20),
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Text(
              '🔥',
              style: TextStyle(fontSize: 40),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current Streak',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$currentStreak ${currentStreak == 1 ? 'Day' : 'Days'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  currentStreak == 0 ? 'Complete 5 habits to start!' : 'Keep going! 💪',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(int completed, double progress) {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final monthlyProgress = daysCompletedThisMonth / daysInMonth;
    
    return GlassyContainer(
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Today\'s Progress',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                '$daysCompletedThisMonth/$daysInMonth days',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Completed days this month',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: monthlyProgress,
              minHeight: 12,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation<Color>(
                monthlyProgress >= 0.8 ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white24),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Today',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Text(
                '$completed/${_habits.length} habits',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress == 1.0 ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            progress == 1.0 ? '🎉 All done for today!' : 'Keep it up!',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Habits',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        if (_habits.isEmpty)
          GlassyContainer(
            borderRadius: BorderRadius.circular(16),
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.task_alt,
                    size: 64,
                    color: Colors.white.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No habits yet',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to add your first habit',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...List.generate(_habits.length, (index) {
            return _buildHabitCard(index);
          }),
      ],
    );
  }

  Widget _buildHabitCard(int index) {
    final habit = _habits[index];
    final isDone = habit.completed;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 100)),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: GlassyContainer(
          borderRadius: BorderRadius.circular(16),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _checkHabit(index),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDone 
                          ? const Color(0xFF10B981).withOpacity(0.2) 
                          : Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        habit.displayIcon,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            habit.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              decoration: isDone ? TextDecoration.lineThrough : null,
                              color: isDone ? Colors.white60 : Colors.white,
                            ),
                          ),
                          if (habit.streak > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '🔥 ${habit.streak} day streak',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange.withOpacity(0.9),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (isDone)
                      const Text(
                        '✓',
                        style: TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
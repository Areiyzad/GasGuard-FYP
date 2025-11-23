import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:confetti/confetti.dart';
import 'widgets/glassy.dart';

class HabitTrackerPage extends StatefulWidget {
  const HabitTrackerPage({super.key});

  @override
  State<HabitTrackerPage> createState() => _HabitTrackerPageState();
}

class _HabitTrackerPageState extends State<HabitTrackerPage>
    with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _streakAnimationController;

  int currentStreak = 7;
  final List<Habit> _habits = [
    Habit(id: 1, title: 'Check gas detector', streak: 7, completed: false, category: 'daily'),
    Habit(id: 2, title: 'Inspect gas valves', streak: 3, completed: false, category: 'daily'),
    Habit(id: 3, title: 'Clean detector sensors', streak: 2, completed: false, category: 'weekly'),
    Habit(id: 4, title: 'Test alarm sound', streak: 15, completed: false, category: 'weekly'),
    Habit(id: 5, title: 'Replace batteries', streak: 1, completed: false, category: 'monthly'),
  ];

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _streakAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _streakAnimationController.dispose();
    super.dispose();
  }

  void _checkHabit(int index) {
    setState(() {
      _habits[index].completed = !_habits[index].completed;
    });

    // Check if all habits are completed
    if (_habits.every((habit) => habit.completed)) {
      _showStreakCelebration();
    }
  }

  void _showStreakCelebration() {
    _confettiController.play();
    _streakAnimationController.forward(from: 0);

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (context) => _buildStreakPopup(),
    );
  }

  Widget _buildStreakPopup() {
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
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Colors.white, Colors.yellow],
                        ).createShader(bounds),
                        child: Text(
                          '$currentStreak Day Streak!',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Amazing! Keep it up!',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'All habits completed today 🎉',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Stats row
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStreakStat('Current', '$currentStreak'),
                            Container(
                              width: 1,
                              height: 40,
                              color: Colors.white.withOpacity(0.3),
                            ),
                            _buildStreakStat('Best', '${currentStreak + 3}'),
                            Container(
                              width: 1,
                              height: 40,
                              color: Colors.white.withOpacity(0.3),
                            ),
                            _buildStreakStat('Total', '${currentStreak * 4}'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Close button
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          setState(() {
                            currentStreak++;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF10B981),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 5,
                        ),
                        child: const Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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

  Widget _buildStreakStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    int completedHabits = _habits.where((h) => h.completed).length;
    double progress = completedHabits / _habits.length;

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
    return Column(
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
                  '$currentStreak Days',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Keep going! 💪',
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
                '$completed/${_habits.length}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress == 1.0 ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            progress == 1.0 ? '🎉 All done!' : 'Keep it up!',
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
          'Daily Habits',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
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
                      color: isDone ? const Color(0xFF10B981).withOpacity(0.2) : Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isDone ? Icons.check : habit.icon,
                      color: isDone ? Colors.white : Colors.white70,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      habit.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        decoration: isDone ? TextDecoration.lineThrough : null,
                        color: isDone ? Colors.white60 : Colors.white,
                      ),
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

class Habit {
  final int id;
  final String title;
  int streak;
  bool completed;
  final String category;

  Habit({
    required this.id,
    required this.title,
    required this.streak,
    required this.completed,
    required this.category,
  });
  
  IconData get icon {
    switch (category) {
      case 'daily':
        return Icons.check_circle_outline;
      case 'weekly':
        return Icons.calendar_view_week;
      case 'monthly':
        return Icons.calendar_month;
      default:
        return Icons.task_alt;
    }
  }
}
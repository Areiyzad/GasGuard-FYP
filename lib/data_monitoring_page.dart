import 'package:flutter/material.dart';
import 'dart:async';
import 'widgets/glassy.dart';
import 'dart:math' as math;
import 'services/gas_data_service.dart';
import 'models/gas_reading_model.dart';

class DataMonitoringPage extends StatefulWidget {
  const DataMonitoringPage({super.key});

  @override
  State<DataMonitoringPage> createState() => _DataMonitoringPageState();
}

class _DataMonitoringPageState extends State<DataMonitoringPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  final GasDataService _gasDataService = GasDataService();
  String selectedTimeRange = '24h';
  GasReading? _currentReading;
  List<GasReading> _historicalReadings = [];
  Map<String, dynamic> _statistics = {};
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    _loadGasData();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startAutoRefresh() {
    _updateTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _loadGasData();
    });
  }

  Future<void> _loadGasData() async {
    final reading = await _gasDataService.getCurrentReading('SENSOR_001');
    final duration = _getDurationFromRange(selectedTimeRange);
    final readings = await _gasDataService.getReadingsByTimeRange(duration);
    final stats = await _gasDataService.getStatistics();
    
    if (mounted) {
      setState(() {
        _currentReading = reading;
        _historicalReadings = readings;
        _statistics = stats;
      });
    }
  }

  Duration _getDurationFromRange(String range) {
    switch (range) {
      case '1h':
        return const Duration(hours: 1);
      case '6h':
        return const Duration(hours: 6);
      case '24h':
        return const Duration(hours: 24);
      case '7d':
        return const Duration(days: 7);
      default:
        return const Duration(hours: 24);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildLiveMonitor(),
          const SizedBox(height: 24),
          _buildTimeRangeSelector(),
          const SizedBox(height: 16),
          _buildChartCard(),
          const SizedBox(height: 24),
          _buildSensorReadings(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gas Monitoring',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        Text(
          'Real-time sensor data and analytics',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white70,
              ),
        ),
      ],
    );
  }

  Widget _buildLiveMonitor() {
    return GlassyContainer(
      borderRadius: BorderRadius.circular(20),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(
                        0.2 + (_pulseController.value * 0.1),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.sensors,
                      color: Colors.white,
                      size: 28,
                    ),
                  );
                },
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.greenAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Live Monitoring',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'All sensors active',
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
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLiveMetric(
                _currentReading?.gasLevel.toStringAsFixed(1) ?? '0',
                _currentReading?.unit ?? 'ppm',
                'Current',
              ),
              _buildLiveMetric(
                _statistics['avg_level'] != null 
                    ? (_statistics['avg_level'] as double).toStringAsFixed(1)
                    : '0',
                'ppm',
                'Average',
              ),
              _buildLiveMetric(
                _statistics['peak_level'] != null 
                    ? (_statistics['peak_level'] as double).toStringAsFixed(1)
                    : '0',
                'ppm',
                'Peak',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLiveMetric(String value, String unit, String label) {
    return Column(
      children: [
        RichText(
          text: TextSpan(
            text: value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            children: [
              TextSpan(
                text: ' $unit',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeRangeSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: ['1h', '6h', '24h', '7d', '30d'].map((range) {
          final isSelected = selectedTimeRange == range;
          return GestureDetector(
            onTap: () => setState(() => selectedTimeRange = range),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                      )
                    : null,
                color: isSelected ? null : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF10B981).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                range,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChartCard() {
    final currentLevel = _currentReading?.gasLevel ?? 0.0;
    final status = _getStatusForLevel(currentLevel);
    final statusColor = _getColorForStatus(status);
    
    return GlassyContainer(
      borderRadius: BorderRadius.circular(20),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'Gas Level Monitor',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          // Circular speedometer
          SizedBox(
            width: 280,
            height: 280,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Animated circular progress
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: currentLevel / 100),
                  duration: const Duration(milliseconds: 1500),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return CustomPaint(
                      size: const Size(280, 280),
                      painter: SpeedometerPainter(
                        progress: value,
                        color: statusColor,
                      ),
                    );
                  },
                ),
                // Center content
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: currentLevel),
                      duration: const Duration(milliseconds: 1500),
                      builder: (context, value, _) {
                        return Text(
                          value.toStringAsFixed(0),
                          style: TextStyle(
                            fontSize: 64,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                            shadows: [
                              Shadow(
                                color: statusColor.withOpacity(0.5),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    Text(
                      'PPM',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Status indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: statusColor.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Text(
              status.toUpperCase(),
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(
                Icons.download,
                _statistics['avg_level'] != null 
                    ? (_statistics['avg_level'] as double).toStringAsFixed(1)
                    : '0',
                'Average',
                const Color(0xFF10B981),
              ),
              _buildStatItem(
                Icons.upload,
                _statistics['peak_level'] != null 
                    ? (_statistics['peak_level'] as double).toStringAsFixed(1)
                    : '0',
                'Peak',
                const Color(0xFFF59E0B),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Network quality style bottom stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildBottomStat(
                _historicalReadings.length.toString(),
                'Readings',
                Icons.access_time,
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withOpacity(0.2),
              ),
              _buildBottomStat(
                status,
                'Air Quality',
                Icons.speed,
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withOpacity(0.2),
              ),
              _buildBottomStat(
                '${((1 - currentLevel / 100) * 100).toInt()}%',
                'Safety',
                Icons.security,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getStatusForLevel(double level) {
    if (level < 30) return 'Safe';
    if (level < 50) return 'Warning';
    return 'Danger';
  }

  Color _getColorForStatus(String status) {
    switch (status.toLowerCase()) {
      case 'safe':
        return const Color(0xFF10B981); // green
      case 'warning':
        return const Color(0xFFF59E0B); // yellow
      case 'danger':
        return const Color(0xFFEF4444); // red
      default:
        return const Color(0xFF10B981);
    }
  }

  Widget _buildStatItem(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              ' PPM',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomStat(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.7), size: 18),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 10,
          ),
        ),
      ],
    );
  }



  Widget _buildSensorReadings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sensor Readings',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        _buildSensorCard('Kitchen Sensor', 0, 'SAFE', const Color(0xFF10B981), 0),
        _buildSensorCard('Living Room', 3, 'SAFE', const Color(0xFF10B981), 100),
        _buildSensorCard('Bedroom', 1, 'SAFE', const Color(0xFF10B981), 200),
      ],
    );
  }

  Widget _buildSensorCard(
    String name,
    int value,
    String status,
    Color statusColor,
    int delay,
  ) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + delay),
      builder: (context, animValue, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - animValue)),
          child: Opacity(opacity: animValue, child: child),
        );
      },
      child: GlassyContainer(
        borderRadius: BorderRadius.circular(16),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.sensors, color: statusColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$value ppm',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Speedometer circular painter
class SpeedometerPainter extends CustomPainter {
  final double progress;
  final Color color;

  SpeedometerPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    
    // Background circle (track)
    final trackPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;
    
    canvas.drawCircle(center, radius - 10, trackPaint);
    
    // Progress arc with glow effect
    final progressPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          color.withOpacity(0.6),
          color,
          color.withOpacity(0.9),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;
    
    // Draw main progress arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 10),
      -math.pi / 2,  // Start from top
      2 * math.pi * progress,
      false,
      progressPaint,
    );
    
    // Add glow effect
    final glowPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 30
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 10),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      glowPaint,
    );
    
    // Inner glow circle
    final innerGlowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withOpacity(0.4),
          color.withOpacity(0.1),
          Colors.transparent,
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 0.7));
    
    canvas.drawCircle(center, radius * 0.7, innerGlowPaint);
  }

  @override
  bool shouldRepaint(covariant SpeedometerPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
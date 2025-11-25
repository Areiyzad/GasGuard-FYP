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
    return GlassyContainer(
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gas Levels Over Time',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: CustomPaint(
              size: const Size(double.infinity, 200),
              painter: ChartPainter(readings: _historicalReadings),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildChartLegend('Safe', const Color(0xFF10B981)),
              _buildChartLegend('Warning', const Color(0xFFF59E0B)),
              _buildChartLegend('Danger', const Color(0xFFEF4444)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
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

class ChartPainter extends CustomPainter {
  final List<GasReading> readings;

  ChartPainter({required this.readings});

  @override
  void paint(Canvas canvas, Size size) {
    if (readings.isEmpty) {
      return;
    }

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final gradient = LinearGradient(
      colors: [
        const Color(0xFF10B981),
        const Color(0xFF3B82F6),
      ],
    );

    paint.shader = gradient.createShader(
      Rect.fromLTWH(0, 0, size.width, size.height),
    );

    final path = Path();

    final minLevel = readings.map((r) => r.gasLevel).reduce(math.min);
    final maxLevel = readings.map((r) => r.gasLevel).reduce(math.max);
    final range = (maxLevel - minLevel) == 0 ? 1 : (maxLevel - minLevel);

    for (int i = 0; i < readings.length; i++) {
      final x = (size.width / (readings.length - 1)) * i;
      final normalized = (readings[i].gasLevel - minLevel) / range;
      final y = size.height - (normalized * size.height * 0.9); // padding top

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is ChartPainter) {
      return oldDelegate.readings != readings;
    }
    return true;
  }
}
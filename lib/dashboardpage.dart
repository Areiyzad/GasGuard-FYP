import 'package:flutter/material.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'widgets/glassy.dart';
import 'services/settings_service.dart';
import 'services/gas_data_service.dart';
import 'services/sensor_service.dart';
import 'services/habit_service.dart';
import 'models/gas_reading_model.dart';
import 'models/sensor_model.dart';
import 'sensor_management_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _glowController;
  final SettingsService _settingsService = SettingsService();
  final GasDataService _gasDataService = GasDataService();
  final SensorService _sensorService = SensorService();
  final HabitService _habitService = HabitService();
  
  GasReading? _currentReading;
  List<Sensor> _sensors = [];
  Map<String, double> _sensorReadings = {}; // sensor_id -> ppm value
  bool _windowVentilationActive = false;
  Timer? _dataUpdateTimer;
  List<Map<String, dynamic>> _recentActivities = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..forward();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _loadSensors();
    _initializeGasData();
    _startRealTimeMonitoring();
    _loadRecentActivities();
  }

  @override
  void dispose() {
    _dataUpdateTimer?.cancel();
    _glowController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Your build method implementation goes here.
    // For example, you can return a Scaffold or any widget tree.
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSupabaseDebugBanner(),
          const SizedBox(height: 12),
          _buildWelcomeSection(),
          const SizedBox(height: 24),
          _buildStatusCard(),
          const SizedBox(height: 24),
          if (_sensors.isNotEmpty) _buildSensorsSection(),
          if (_sensors.isNotEmpty) const SizedBox(height: 24),
          _buildQuickStats(),
          const SizedBox(height: 24),
          _buildRecentActivity(),
        ],
      ),
    );
  }

  Future<void> _loadSensors() async {
    final sensors = await _sensorService.getAllSensors();
    if (!mounted) return;
    setState(() {
      _sensors = sensors;
    });
  }

  Future<void> _loadRecentActivities() async {
    try {
      final activities = <Map<String, dynamic>>[];
      
      // Get today's habit completions
      final today = DateTime.now();
      final completions = await _habitService.getCompletionsForDate(today);
      
      // Check if all 5 daily habits were completed
      final habits = await _habitService.getUserHabits();
      final dailyHabits = habits.where((h) => h.category == 'daily').toList();
      final completedToday = completions.length;
      
      if (completedToday == dailyHabits.length && dailyHabits.length == 5) {
        activities.add({
          'title': 'Daily Safety Habits Completed',
          'time': _getTimeAgo(completions.first.completedAt),
          'icon': Icons.check_circle,
          'color': const Color(0xFF10B981),
        });
      } else if (completedToday > 0) {
        activities.add({
          'title': '$completedToday/${dailyHabits.length} Habits Completed',
          'time': _getTimeAgo(completions.first.completedAt),
          'icon': Icons.task_alt,
          'color': const Color(0xFF3B82F6),
        });
      }
      
      // Add sensor activities
      if (_currentReading != null) {
        activities.add({
          'title': 'System Check Completed',
          'time': _getTimeAgo(_currentReading!.timestamp),
          'icon': Icons.sensors,
          'color': const Color(0xFF8B5CF6),
        });
      }
      
      // Add sensor calibration (mock - last hour)
      activities.add({
        'title': 'Sensor Calibrated',
        'time': '1 hour ago',
        'icon': Icons.settings,
        'color': const Color(0xFF3B82F6),
      });
      
      if (!mounted) return;
      setState(() {
        _recentActivities = activities;
      });
    } catch (e) {
      print('Error loading recent activities: $e');
    }
  }

  Future<void> _initializeGasData() async {
    // Generate sample historical data on first run
    final readings = await _gasDataService.getAllReadings();
    if (readings.isEmpty) {
      await _gasDataService.generateSampleData(100);
    }
    await _updateGasData();
  }

  void _startRealTimeMonitoring() {
    // Update gas data every 5 seconds
    _dataUpdateTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _updateGasData();
    });
  }

  Future<void> _updateGasData() async {
    // Update all sensor readings
    for (var sensor in _sensors) {
      final reading = await _gasDataService.getCurrentReading(sensor.deviceId);
      _sensorReadings[sensor.id] = reading.gasLevel;
    }
    
    // Get default sensor reading
    final reading = await _gasDataService.getCurrentReading('SENSOR_001');
    if (!mounted) return;
    setState(() {
      _currentReading = reading;
    });
    _checkGasLevels();
  }
  void _checkGasLevels() async {
    if (_currentReading == null) return;
    
    final settings = await _settingsService.getSettings();
    
    // Check if gas level exceeds maximum threshold
    if (_currentReading!.gasLevel >= settings.maxThreshold && 
        settings.autoWindowVentilation && 
        !_windowVentilationActive) {
      _triggerWindowVentilation();
    }
  }

  String _getTimeAgo(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    
    if (diff.inSeconds < 60) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} min ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} hr ago';
    } else {
      return '${diff.inDays} day ago';
    }
  }

  void _triggerWindowVentilation() {
    setState(() {
      _windowVentilationActive = true;
    });
    
    _showWindowVentilationAlert();
  }

  void _showWindowVentilationAlert() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: GlassyContainer(
          borderRadius: BorderRadius.circular(20),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.white,
                  size: 64,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'DANGER ALERT',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Dangerous gas levels detected!',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              GlassyContainer(
                borderRadius: BorderRadius.circular(12),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.air, color: Colors.white, size: 48),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Window Ventilation',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Windows are now opening automatically for ventilation',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Active',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.withOpacity(0.5)),
                ),
                child: const Column(
                  children: [
                    Text(
                      '⚠️ IMMEDIATE ACTION REQUIRED',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Evacuate the area immediately\n'
                      '• Do not use electrical switches\n'
                      '• Call emergency services: 999\n'
                      '• Move to fresh air location',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        // Call emergency services
                      },
                      icon: const Icon(Icons.phone),
                      label: const Text('Call 999'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _windowVentilationActive = false;
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Safe Now'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSupabaseDebugBanner() {
    final supabase = Supabase.instance.client;
    final isConnected = supabase.auth.currentSession != null;
    
    return GlassyContainer(
      borderRadius: BorderRadius.circular(12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      tintColor: isConnected ? Colors.green : Colors.blue,
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: isConnected ? Colors.green : Colors.blue,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (isConnected ? Colors.green : Colors.blue).withOpacity(0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🗄️ Supabase Database',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isConnected ? 'Connected & Authenticated' : 'Connected (Anonymous)',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            isConnected ? Icons.check_circle : Icons.cloud_done,
            color: isConnected ? Colors.green : Colors.blue,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome Back! 👋',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        Text(
          'Monitor your gas safety in real-time',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white.withOpacity(0.75),
              ),
        ),
      ],
    );
  }

  Widget _buildStatusCard() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _glowController,
              builder: (context, _) {
                final t = _glowController.value;
                final pulseOpacity = 0.30 + (0.15 * (0.5 - (t - 0.5).abs()));
                final innerOpacity = 0.55 + (0.10 * (0.5 - (t - 0.5).abs()));
                final radius = 1.1 + (0.08 * (0.5 - (t - 0.5).abs()));
                return IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFFFFB300).withOpacity(innerOpacity),
                          const Color(0xFFFFB300).withOpacity(pulseOpacity),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.55, 1.0],
                        radius: radius,
                        center: const Alignment(-0.8, -0.8),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          GlassyContainer(
            borderRadius: BorderRadius.circular(20),
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _windowVentilationActive ? Icons.air : Icons.check_circle,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _windowVentilationActive 
                                ? 'Ventilation Active' 
                                : _currentReading != null && _currentReading!.status != 'normal'
                                    ? '${_currentReading!.getStatusLabel()} Level Detected'
                                    : 'All Systems Normal',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _windowVentilationActive 
                                ? 'Windows open for safety' 
                                : _currentReading != null
                                    ? 'Current: ${_currentReading!.gasLevel.toStringAsFixed(1)} ${_currentReading!.unit}'
                                    : 'No gas detected',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!_windowVentilationActive)
                      IconButton(
                        onPressed: _showWindowVentilationAlert,
                        icon: const Icon(Icons.warning_amber_rounded),
                        color: Colors.orange,
                        tooltip: 'Test ventilation alert',
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatusMetric('Air Quality', '95%', Icons.air),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    Expanded(
                      child: _buildStatusMetric(
                        'Sensors', 
                        '${_sensors.where((s) => s.isActive).length}/${_sensors.length}',
                        Icons.sensors,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusMetric(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.9), size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
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

  Widget _buildSensorsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'My Sensors',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SensorManagementPage(),
                  ),
                ).then((_) => _loadSensors());
              },
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _sensors.length,
          itemBuilder: (context, index) {
            final sensor = _sensors[index];
            final ppmValue = _sensorReadings[sensor.id] ?? 0.0;
            final status = _getStatusForPPM(ppmValue);
            final statusColor = _getColorForStatus(status);
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: GlassyContainer(
                borderRadius: BorderRadius.circular(16),
                padding: const EdgeInsets.all(16),
                tintColor: statusColor,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        sensor.isActive ? Icons.sensors : Icons.sensors_off,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sensor.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            sensor.deviceId,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${ppmValue.toStringAsFixed(1)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'PPM',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  String _getStatusForPPM(double ppm) {
    if (ppm < 30) return 'safe';
    if (ppm < 50) return 'warning';
    return 'danger';
  }

  Color _getColorForStatus(String status) {
    switch (status) {
      case 'safe':
        return const Color(0xFF10B981);
      case 'warning':
        return const Color(0xFFF59E0B);
      case 'danger':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF3B82F6);
    }
  }

  Widget _buildQuickStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Stats',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard(
              'Gas Level',
              _currentReading != null 
                  ? '${_currentReading!.gasLevel.toStringAsFixed(1)} ${_currentReading!.unit}'
                  : '0 ppm',
              Icons.speed,
              [const Color(0xFF3B82F6), const Color(0xFF2563EB)],
              0,
            ),
            _buildStatCard(
              'Last Check',
              _currentReading != null 
                  ? _getTimeAgo(_currentReading!.timestamp)
                  : '2 min ago',
              Icons.access_time,
              [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)],
              100,
            ),
            _buildStatCard(
              'Active Alerts',
              '0',
              Icons.notifications_active,
              [const Color(0xFFF59E0B), const Color(0xFFD97706)],
              200,
            ),
            _buildStatCard(
              'Uptime',
              '24 days',
              Icons.trending_up,
              [const Color(0xFFEC4899), const Color(0xFFDB2777)],
              300,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    List<Color> colors,
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
      child: InkWell(
        onTap: () => _showStatDetails(title, value, icon, colors),
        borderRadius: BorderRadius.circular(16),
        child: GlassyContainer(
          borderRadius: BorderRadius.circular(16),
          padding: const EdgeInsets.all(12),
          tintColor: const Color(0xFF2E6DF9),
          subtleBorder: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 16),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 10.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStatDetails(String title, String value, IconData icon, List<Color> colors) {
    Map<String, Map<String, dynamic>> detailsMap = {
      'Gas Level': {
        'description': 'Current gas concentration detected by sensors',
        'details': [
          {'label': 'Current Level', 'value': '0 ppm'},
          {'label': 'Threshold', 'value': '50 ppm'},
          {'label': 'Status', 'value': 'Safe'},
          {'label': 'Last Updated', 'value': 'Just now'},
        ],
        'info': 'Gas levels are monitored continuously. Alert will trigger if levels exceed 50 ppm.'
      },
      'Last Check': {
        'description': 'Time since last system check',
        'details': [
          {'label': 'Last Check', 'value': '2 minutes ago'},
          {'label': 'Next Check', 'value': 'In 58 minutes'},
          {'label': 'Check Interval', 'value': '60 minutes'},
          {'label': 'Total Checks Today', 'value': '24'},
        ],
        'info': 'Automatic system checks ensure all sensors are functioning properly.'
      },
      'Active Alerts': {
        'description': 'Number of active system alerts',
        'details': [
          {'label': 'Active', 'value': '0'},
          {'label': 'Total Today', 'value': '0'},
          {'label': 'This Week', 'value': '0'},
          {'label': 'Last Alert', 'value': 'None'},
        ],
        'info': 'Alerts notify you of potential gas leaks or system issues requiring attention.'
      },
      'Uptime': {
        'description': 'System continuous operation time',
        'details': [
          {'label': 'Current Uptime', 'value': '24 days'},
          {'label': 'Total Uptime', 'value': '99.8%'},
          {'label': 'Last Restart', 'value': 'Oct 24, 2025'},
          {'label': 'Restarts This Year', 'value': '3'},
        ],
        'info': 'High uptime ensures continuous monitoring and protection of your home.'
      },
    };

    final details = detailsMap[title];
    if (details == null) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: GlassyContainer(
          borderRadius: BorderRadius.circular(20),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: colors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: Colors.white, size: 48),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                details['description'],
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.75),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              GlassyContainer(
                borderRadius: BorderRadius.circular(12),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    for (var detail in details['details'])
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              detail['label'],
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.85),
                              ),
                            ),
                            Text(
                              detail['value'],
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.first.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: colors.first,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        details['info'],
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.first,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: _loadRecentActivities,
              tooltip: 'Refresh activities',
              color: Colors.white70,
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (_recentActivities.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Icon(Icons.history, size: 48, color: Colors.white.withOpacity(0.3)),
                  const SizedBox(height: 12),
                  Text(
                    'No recent activities',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...(_recentActivities.map((activity) => _buildActivityItem(
            activity['title'] as String,
            activity['time'] as String,
            activity['icon'] as IconData,
            activity['color'] as Color,
          )).toList()),
      ],
    );
  }

  Widget _buildActivityItem(
    String title,
    String time,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassyContainer(
        borderRadius: BorderRadius.circular(12),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    time,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
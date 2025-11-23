import 'package:flutter/material.dart';
import 'dart:async';
import 'widgets/glassy.dart';
import 'services/settings_service.dart';
import 'services/gas_data_service.dart';
import 'models/gas_reading_model.dart';

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
  
  GasReading? _currentReading;
  bool _windowVentilationActive = false;
  Timer? _dataUpdateTimer;

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
    _initializeGasData();
    _startRealTimeMonitoring();
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
          _buildWelcomeSection(),
          const SizedBox(height: 24),
          _buildStatusCard(),
          const SizedBox(height: 24),
          _buildQuickStats(),
          const SizedBox(height: 24),
          _buildRecentActivity(),
        ],
      ),
    );
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
                      child: _buildStatusMetric('Sensors', '3/3', Icons.sensors),
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
        Text(
          'Recent Activity',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 20),
        _buildActivityItem(
          'System Check Completed',
          '2 minutes ago',
          Icons.check_circle,
          const Color(0xFF10B981),
        ),
        _buildActivityItem(
          'Sensor Calibrated',
          '1 hour ago',
          Icons.settings,
          const Color(0xFF3B82F6),
        ),
        _buildActivityItem(
          'Weekly Report Generated',
          '1 day ago',
          Icons.description,
          const Color(0xFF8B5CF6),
        ),
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
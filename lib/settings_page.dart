import 'package:flutter/material.dart';
import 'models/settings_model.dart';
import 'models/sensor_model.dart';
import 'services/settings_service.dart';
import 'services/sensor_service.dart';
import 'widgets/glassy.dart';
import 'theme_mode.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with SingleTickerProviderStateMixin {
  final SettingsService _settingsService = SettingsService();
  final SensorService _sensorService = SensorService();
  late Future<GasDetectionSettings> _settingsFuture;
  late Future<List<Sensor>> _sensorsFuture;
  late GasDetectionSettings _currentSettings;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _settingsFuture = _settingsService.getSettings();
    _sensorsFuture = _sensorService.getAllSensors();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    final success = await _settingsService.saveSettings(_currentSettings);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Settings saved successfully!' : 'Failed to save settings'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _resetSettings() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: GlassyContainer(
          borderRadius: BorderRadius.circular(16),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Reset Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Are you sure you want to reset all settings to default?',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                    style: TextButton.styleFrom(foregroundColor: Colors.white70),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Reset'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm == true) {
      await _settingsService.resetSettings();
      setState(() {
        _settingsFuture = _settingsService.getSettings();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings reset to default')),
        );
      }
    }
  }

  void _showAddSensorDialog() {
    final nameController = TextEditingController();
    final deviceIdController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: GlassyContainer(
          borderRadius: BorderRadius.circular(16),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Add New Sensor', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Sensor Name',
                  hintText: 'e.g., Kitchen Sensor',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: deviceIdController,
                decoration: const InputDecoration(
                  labelText: 'Device ID',
                  hintText: 'e.g., SENSOR_001',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      if (nameController.text.isNotEmpty &&
                          deviceIdController.text.isNotEmpty) {
                        await _sensorService.addSensor(
                          nameController.text,
                          deviceIdController.text,
                        );
                        setState(() {
                          _sensorsFuture = _sensorService.getAllSensors();
                        });
                        Navigator.pop(context);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Sensor added successfully!')),
                          );
                        }
                      }
                    },
                    child: const Text('Add'),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Settings & Sensors',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
              ),
              IconButton(
                icon: const Icon(Icons.restore),
                onPressed: _resetSettings,
                tooltip: 'Reset to defaults',
                color: Colors.white70,
              ),
            ],
          ),
        ),
        GlassyContainer(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          padding: EdgeInsets.zero,
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: const Color(0xFF1E3A8A),
            tabs: const [
              Tab(icon: Icon(Icons.tune), text: 'Detection'),
              Tab(icon: Icon(Icons.sensors), text: 'Sensors'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildSettingsTab(),
              _buildSensorsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTab() {
    return FutureBuilder<GasDetectionSettings>(
      future: _settingsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        _currentSettings = snapshot.data ?? GasDetectionSettings();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Detection Thresholds'),
              _buildThresholdCard(),
              const SizedBox(height: 24),
              _buildSectionHeader('Unit Settings'),
              _buildUnitCard(),
              const SizedBox(height: 24),
              _buildSectionHeader('Alert Settings'),
              _buildAlertCard(),
              const SizedBox(height: 24),
              _buildSectionHeader('Appearance'),
              _buildAppearanceCard(),
              const SizedBox(height: 24),
              _buildInfoCard(),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Save Settings',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSensorsTab() {
    return FutureBuilder<List<Sensor>>(
      future: _sensorsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final sensors = snapshot.data ?? [];

        if (sensors.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.sensors, size: 48, color: Colors.white60),
                const SizedBox(height: 16),
                Text(
                  'No sensors added yet',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _showAddSensorDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Your First Sensor'),
                ),
              ],
            ),
          );
        }

        return Stack(
          children: [
            ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sensors.length,
              itemBuilder: (context, index) {
                final sensor = sensors[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: GlassyContainer(
                    borderRadius: BorderRadius.circular(12),
                    child: ListTile(
                      title: Text(sensor.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      subtitle: Text('Device ID: ${sensor.deviceId}', style: const TextStyle(color: Colors.white70)),
                      trailing: PopupMenuButton(
                        icon: const Icon(Icons.more_vert, color: Colors.white70),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            child: const Text('Delete'),
                            onTap: () async {
                              await _sensorService.deleteSensor(sensor.id);
                              setState(() {
                                _sensorsFuture = _sensorService.getAllSensors();
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            Positioned(
              right: 16,
              bottom: 16,
              child: FloatingActionButton(
                onPressed: _showAddSensorDialog,
                backgroundColor: const Color(0xFF1E3A8A),
                child: const Icon(Icons.add),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
      ),
    );
  }

  Widget _buildThresholdCard() {
    return GlassyContainer(
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(20.0),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Minimum Threshold',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showManualThresholdDialog(isMinimum: true),
                  icon: const Icon(Icons.edit, size: 16, color: Colors.orangeAccent),
                  label: const Text(
                    'Adjust',
                    style: TextStyle(color: Colors.orangeAccent, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Alert when gas level reaches: ${_currentSettings.minThreshold.toInt()} ${_currentSettings.unit}',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            Slider(
              value: _currentSettings.minThreshold,
              min: 10,
              max: 200,
              divisions: 38,
              label: '${_currentSettings.minThreshold.toInt()} ${_currentSettings.unit}',
              activeColor: Colors.orange[600],
              onChanged: (value) {
                setState(() {
                  _currentSettings = _currentSettings.copyWith(
                    minThreshold: value,
                  );
                });
              },
            ),
            const Divider(height: 32),
            Row(
              children: [
                Icon(Icons.dangerous, color: Colors.red[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Maximum Threshold',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showManualThresholdDialog(isMinimum: false),
                  icon: const Icon(Icons.edit, size: 16, color: Colors.redAccent),
                  label: const Text(
                    'Adjust',
                    style: TextStyle(color: Colors.redAccent, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Critical alert when gas level reaches: ${_currentSettings.maxThreshold.toInt()} ${_currentSettings.unit}',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            Slider(
              value: _currentSettings.maxThreshold.clamp(200, 500),
              min: 200,
              max: 500,
              divisions: 60,
              label: '${_currentSettings.maxThreshold.toInt()} ${_currentSettings.unit}',
              activeColor: Colors.red[600],
              onChanged: (value) {
                setState(() {
                  _currentSettings = _currentSettings.copyWith(
                    maxThreshold: value,
                  );
                });
              },
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.red[300], size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Maximum threshold limited to 500+ PPM for safety',
                      style: TextStyle(
                        color: Colors.red[200],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
    );
  }

  void _showManualThresholdDialog({required bool isMinimum}) {
    final controller = TextEditingController(
      text: isMinimum 
          ? _currentSettings.minThreshold.toInt().toString()
          : _currentSettings.maxThreshold.toInt().toString(),
    );

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: GlassyContainer(
          borderRadius: BorderRadius.circular(20),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isMinimum ? Icons.warning_amber_rounded : Icons.dangerous,
                    color: isMinimum ? Colors.orange : Colors.red,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isMinimum ? 'Set Minimum Threshold' : 'Set Maximum Threshold',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                isMinimum
                    ? 'Enter warning threshold (10-500 PPM)'
                    : 'Enter critical threshold (must be ≤500 PPM)',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: 'Enter value',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                  suffixText: _currentSettings.unit.toUpperCase(),
                  suffixStyle: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 16),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isMinimum ? Colors.orange : Colors.red,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (isMinimum ? Colors.orange : Colors.red).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: (isMinimum ? Colors.orange : Colors.red).withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: isMinimum ? Colors.orange[300] : Colors.red[300],
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Safety Guidelines',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isMinimum
                          ? '• Recommended range: 30-100 PPM\n• Standard warning: 50 PPM\n• Must be less than maximum threshold'
                          : '• Maximum allowed: 500 PPM\n• Recommended: 200-400 PPM\n• Standard critical: 200 PPM\n• Must be greater than minimum threshold',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
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
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white70,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        final value = double.tryParse(controller.text);
                        if (value == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter a valid number'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        if (isMinimum) {
                          if (value < 10 || value > 500) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Minimum threshold must be between 10-500 PPM'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          if (value >= _currentSettings.maxThreshold) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Minimum must be less than maximum threshold'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          setState(() {
                            _currentSettings = _currentSettings.copyWith(minThreshold: value);
                          });
                        } else {
                          if (value > 500) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Maximum threshold cannot exceed 500 PPM'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          if (value <= _currentSettings.minThreshold) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Maximum must be greater than minimum threshold'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          setState(() {
                            _currentSettings = _currentSettings.copyWith(maxThreshold: value);
                          });
                        }

                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${isMinimum ? "Minimum" : "Maximum"} threshold set to ${value.toInt()} PPM',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isMinimum ? Colors.orange : Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Set Threshold',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
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

  Widget _buildUnitCard() {
    return GlassyContainer(
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(20.0),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Measurement Unit',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            RadioListTile<String>(
              title: const Text('PPM (Parts Per Million)'),
              subtitle: const Text('Standard measurement for gas concentration'),
              value: 'ppm',
              groupValue: _currentSettings.unit,
              activeColor: Colors.green[600],
              onChanged: (value) {
                setState(() {
                  _currentSettings = _currentSettings.copyWith(unit: value);
                });
              },
            ),
            RadioListTile<String>(
              title: const Text('Percentage (%)'),
              subtitle: const Text('Percentage of gas in air'),
              value: 'percentage',
              groupValue: _currentSettings.unit,
              activeColor: Colors.green[600],
              onChanged: (value) {
                setState(() {
                  _currentSettings = _currentSettings.copyWith(unit: value);
                });
              },
            ),
          ],
        ),
    );
  }

  Widget _buildAlertCard() {
    return GlassyContainer(
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(20.0),
      child: Column(
          children: [
            SwitchListTile(
              title: const Text('Enable Notifications'),
              subtitle: const Text('Receive alerts when thresholds are exceeded'),
              value: _currentSettings.enableNotifications,
              activeColor: Colors.green[600],
              onChanged: (value) {
                setState(() {
                  _currentSettings = _currentSettings.copyWith(
                    enableNotifications: value,
                  );
                });
              },
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Enable Sound Alerts'),
              subtitle: const Text('Play alarm sound when gas is detected'),
              value: _currentSettings.enableSound,
              activeColor: Colors.green[600],
              onChanged: (value) {
                setState(() {
                  _currentSettings = _currentSettings.copyWith(
                    enableSound: value,
                  );
                });
              },
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Auto Window Ventilation'),
              subtitle: const Text('Automatically open windows when dangerous gas levels detected'),
              value: _currentSettings.autoWindowVentilation,
              activeColor: Colors.green[600],
              onChanged: (value) {
                setState(() {
                  _currentSettings = _currentSettings.copyWith(
                    autoWindowVentilation: value,
                  );
                });
              },
            ),
          ],
        ),
    );
  }

  Widget _buildAppearanceCard() {
    final isDark = themeModeNotifier.value == ThemeMode.dark;
    return GlassyContainer(
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.dark_mode, color: isDark ? Colors.cyanAccent : Colors.blueAccent),
              const SizedBox(width: 8),
              Text(
                'Display Mode',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: Text(isDark ? 'Dark Mode' : 'Light Mode'),
            subtitle: Text(isDark ? 'Using deep midnight theme' : 'Using vivid cobalt theme'),
            value: isDark,
            activeColor: Colors.cyanAccent,
            onChanged: (value) {
              themeModeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return GlassyContainer(
      borderRadius: BorderRadius.circular(12),
      padding: const EdgeInsets.all(16.0),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Safety Guidelines',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '• Normal levels: 0-50 ppm\n'
              '• Warning levels: 50-200 ppm\n'
              '• Danger levels: 200+ ppm\n'
              '• Critical levels: 500+ ppm (evacuate immediately)',
              style: const TextStyle(color: Colors.white70, height: 1.5),
            ),
          ],
        ),
    );
  }
}

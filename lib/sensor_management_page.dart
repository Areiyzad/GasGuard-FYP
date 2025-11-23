import 'package:flutter/material.dart';
import 'models/sensor_model.dart';
import 'services/sensor_service.dart';
import 'widgets/glassy.dart';

class SensorManagementPage extends StatefulWidget {
  const SensorManagementPage({super.key});

  @override
  State<SensorManagementPage> createState() => _SensorManagementPageState();
}

class _SensorManagementPageState extends State<SensorManagementPage> {
  final SensorService _sensorService = SensorService();
  late Future<List<Sensor>> _sensorsFuture;

  @override
  void initState() {
    super.initState();
    _sensorsFuture = _sensorService.getAllSensors();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Sensors'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FutureBuilder<List<Sensor>>(
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
                  Icon(Icons.sensors, size: 48, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No sensors added yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _showAddSensorDialog,
                    child: const Text('Add Your First Sensor'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
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
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSensorDialog,
        backgroundColor: const Color(0xFF10B981),
        child: const Icon(Icons.add),
      ),
    );
  }
}

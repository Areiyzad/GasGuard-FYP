class GasReading {
  final String id;
  final String sensorId;
  final double gasLevel;
  final String unit;
  final DateTime timestamp;
  final String status; // 'normal', 'warning', 'danger', 'critical'

  GasReading({
    required this.id,
    required this.sensorId,
    required this.gasLevel,
    required this.unit,
    required this.timestamp,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sensor_id': sensorId,
      'gas_level': gasLevel,
      'unit': unit,
      'timestamp': timestamp.toIso8601String(),
      'status': status,
    };
  }

  factory GasReading.fromMap(Map<String, dynamic> map) {
    return GasReading(
      id: map['id'] ?? '',
      sensorId: map['sensor_id'] ?? '',
      gasLevel: (map['gas_level'] ?? 0.0).toDouble(),
      unit: map['unit'] ?? 'ppm',
      timestamp: map['timestamp'] != null 
          ? DateTime.parse(map['timestamp']) 
          : DateTime.now(),
      status: map['status'] ?? 'normal',
    );
  }

  String getStatusColor() {
    switch (status) {
      case 'normal':
        return '0xFF10B981'; // green
      case 'warning':
        return '0xFFF59E0B'; // amber
      case 'danger':
        return '0xFFEF4444'; // red
      case 'critical':
        return '0xFF991B1B'; // dark red
      default:
        return '0xFF6B7280'; // gray
    }
  }

  String getStatusLabel() {
    switch (status) {
      case 'normal':
        return 'Normal';
      case 'warning':
        return 'Warning';
      case 'danger':
        return 'Danger';
      case 'critical':
        return 'Critical';
      default:
        return 'Unknown';
    }
  }
}

class GasDataSummary {
  final double currentLevel;
  final double avgLevel;
  final double maxLevel;
  final double minLevel;
  final int totalReadings;
  final String status;
  final DateTime lastUpdate;

  GasDataSummary({
    required this.currentLevel,
    required this.avgLevel,
    required this.maxLevel,
    required this.minLevel,
    required this.totalReadings,
    required this.status,
    required this.lastUpdate,
  });

  factory GasDataSummary.fromReadings(List<GasReading> readings) {
    if (readings.isEmpty) {
      return GasDataSummary(
        currentLevel: 0.0,
        avgLevel: 0.0,
        maxLevel: 0.0,
        minLevel: 0.0,
        totalReadings: 0,
        status: 'normal',
        lastUpdate: DateTime.now(),
      );
    }

    final current = readings.first.gasLevel;
    final levels = readings.map((r) => r.gasLevel).toList();
    final avg = levels.reduce((a, b) => a + b) / levels.length;
    final max = levels.reduce((a, b) => a > b ? a : b);
    final min = levels.reduce((a, b) => a < b ? a : b);

    return GasDataSummary(
      currentLevel: current,
      avgLevel: avg,
      maxLevel: max,
      minLevel: min,
      totalReadings: readings.length,
      status: readings.first.status,
      lastUpdate: readings.first.timestamp,
    );
  }
}

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';
import '../models/gas_reading_model.dart';

class GasDataService {
  static const String _readingsKey = 'gas_readings';
  static const int _maxReadings = 1000; // Keep last 1000 readings
  
  // Simulate real-time gas readings
  Future<GasReading> getCurrentReading(String sensorId) async {
    final random = Random();
    
    // Simulate different gas levels (mostly safe with occasional spikes)
    double gasLevel;
    String status;
    
    final chance = random.nextInt(100);
    if (chance < 85) {
      // 85% of the time: normal levels (0-40 ppm)
      gasLevel = random.nextDouble() * 40;
      status = 'normal';
    } else if (chance < 95) {
      // 10% of the time: warning levels (40-200 ppm)
      gasLevel = 40 + (random.nextDouble() * 160);
      status = 'warning';
    } else if (chance < 99) {
      // 4% of the time: danger levels (200-500 ppm)
      gasLevel = 200 + (random.nextDouble() * 300);
      status = 'danger';
    } else {
      // 1% of the time: critical levels (500+ ppm)
      gasLevel = 500 + (random.nextDouble() * 500);
      status = 'critical';
    }
    
    final reading = GasReading(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sensorId: sensorId,
      gasLevel: double.parse(gasLevel.toStringAsFixed(2)),
      unit: 'ppm',
      timestamp: DateTime.now(),
      status: status,
    );
    
    // Save reading
    await _saveReading(reading);
    
    return reading;
  }
  
  Future<void> _saveReading(GasReading reading) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final readings = await getAllReadings();
      
      readings.insert(0, reading);
      
      // Keep only recent readings
      if (readings.length > _maxReadings) {
        readings.removeRange(_maxReadings, readings.length);
      }
      
      final readingsJson = json.encode(
        readings.map((r) => r.toMap()).toList(),
      );
      await prefs.setString(_readingsKey, readingsJson);
    } catch (e) {
      print('Error saving reading: $e');
    }
  }
  
  Future<List<GasReading>> getAllReadings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final readingsJson = prefs.getString(_readingsKey);
      
      if (readingsJson != null) {
        final List<dynamic> decodedList = json.decode(readingsJson);
        return decodedList.map((item) => GasReading.fromMap(item)).toList();
      }
      return [];
    } catch (e) {
      print('Error loading readings: $e');
      return [];
    }
  }
  
  Future<List<GasReading>> getReadingsByTimeRange(Duration duration) async {
    final allReadings = await getAllReadings();
    final cutoffTime = DateTime.now().subtract(duration);
    
    return allReadings.where((reading) => 
      reading.timestamp.isAfter(cutoffTime)
    ).toList();
  }
  
  Future<List<GasReading>> getReadingsBySensor(String sensorId) async {
    final allReadings = await getAllReadings();
    return allReadings.where((r) => r.sensorId == sensorId).toList();
  }
  
  Future<GasDataSummary> getSummary({Duration? duration}) async {
    List<GasReading> readings;
    
    if (duration != null) {
      readings = await getReadingsByTimeRange(duration);
    } else {
      readings = await getAllReadings();
    }
    
    return GasDataSummary.fromReadings(readings);
  }
  
  Future<Map<String, dynamic>> getStatistics() async {
    final readings = await getReadingsByTimeRange(const Duration(hours: 24));
    
    if (readings.isEmpty) {
      return {
        'total_readings': 0,
        'normal_count': 0,
        'warning_count': 0,
        'danger_count': 0,
        'critical_count': 0,
        'avg_level': 0.0,
        'peak_level': 0.0,
      };
    }
    
    final normalCount = readings.where((r) => r.status == 'normal').length;
    final warningCount = readings.where((r) => r.status == 'warning').length;
    final dangerCount = readings.where((r) => r.status == 'danger').length;
    final criticalCount = readings.where((r) => r.status == 'critical').length;
    
    final levels = readings.map((r) => r.gasLevel).toList();
    final avgLevel = levels.reduce((a, b) => a + b) / levels.length;
    final peakLevel = levels.reduce((a, b) => a > b ? a : b);
    
    return {
      'total_readings': readings.length,
      'normal_count': normalCount,
      'warning_count': warningCount,
      'danger_count': dangerCount,
      'critical_count': criticalCount,
      'avg_level': avgLevel,
      'peak_level': peakLevel,
    };
  }
  
  Future<bool> clearAllReadings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_readingsKey);
    } catch (e) {
      print('Error clearing readings: $e');
      return false;
    }
  }
  
  // Generate sample historical data for testing
  Future<void> generateSampleData(int count) async {
    final random = Random();
    final readings = <GasReading>[];
    
    for (int i = 0; i < count; i++) {
      final timestamp = DateTime.now().subtract(Duration(minutes: i * 5));
      double gasLevel;
      String status;
      
      final chance = random.nextInt(100);
      if (chance < 90) {
        gasLevel = random.nextDouble() * 40;
        status = 'normal';
      } else if (chance < 97) {
        gasLevel = 40 + (random.nextDouble() * 160);
        status = 'warning';
      } else {
        gasLevel = 200 + (random.nextDouble() * 300);
        status = 'danger';
      }
      
      readings.add(GasReading(
        id: timestamp.millisecondsSinceEpoch.toString(),
        sensorId: 'SENSOR_001',
        gasLevel: double.parse(gasLevel.toStringAsFixed(2)),
        unit: 'ppm',
        timestamp: timestamp,
        status: status,
      ));
    }
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final readingsJson = json.encode(
        readings.map((r) => r.toMap()).toList(),
      );
      await prefs.setString(_readingsKey, readingsJson);
    } catch (e) {
      print('Error generating sample data: $e');
    }
  }
}

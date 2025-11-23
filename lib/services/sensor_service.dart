import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/sensor_model.dart';

class SensorService {
  final supabase = Supabase.instance.client;

  Future<List<Sensor>> getAllSensors() async {
    try {
      final response = await supabase
          .from('sensors')
          .select()
          .order('created_at', ascending: false);
      return (response as List).map((e) => Sensor.fromMap(e)).toList();
    } catch (e) {
      print('Error fetching sensors: $e');
      return [];
    }
  }

  Future<Sensor?> addSensor(String name, String deviceId) async {
    try {
      final response = await supabase
          .from('sensors')
          .insert({
            'name': name,
            'device_id': deviceId,
            'created_at': DateTime.now().toIso8601String(),
            'is_active': true,
          })
          .select()
          .single();
      return Sensor.fromMap(response);
    } catch (e) {
      print('Error adding sensor: $e');
      return null;
    }
  }

  Future<bool> deleteSensor(String sensorId) async {
    try {
      await supabase.from('sensors').delete().eq('id', sensorId);
      return true;
    } catch (e) {
      print('Error deleting sensor: $e');
      return false;
    }
  }

  Future<bool> updateSensorStatus(String sensorId, bool isActive) async {
    try {
      await supabase
          .from('sensors')
          .update({'is_active': isActive})
          .eq('id', sensorId);
      return true;
    } catch (e) {
      print('Error updating sensor: $e');
      return false;
    }
  }
}

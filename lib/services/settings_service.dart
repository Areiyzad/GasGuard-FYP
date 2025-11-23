import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/settings_model.dart';

class SettingsService {
  static const String _settingsKey = 'gas_detection_settings';

  Future<GasDetectionSettings> getSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_settingsKey);
      
      if (settingsJson != null) {
        final map = json.decode(settingsJson) as Map<String, dynamic>;
        return GasDetectionSettings.fromMap(map);
      }
      return GasDetectionSettings();
    } catch (e) {
      print('Error loading settings: $e');
      return GasDetectionSettings();
    }
  }

  Future<bool> saveSettings(GasDetectionSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = json.encode(settings.toMap());
      return await prefs.setString(_settingsKey, settingsJson);
    } catch (e) {
      print('Error saving settings: $e');
      return false;
    }
  }

  Future<bool> resetSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_settingsKey);
    } catch (e) {
      print('Error resetting settings: $e');
      return false;
    }
  }
}

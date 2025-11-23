class GasDetectionSettings {
  final double minThreshold;
  final double maxThreshold;
  final bool enableNotifications;
  final bool enableSound;
  final bool autoWindowVentilation;
  final String unit; // 'ppm' or 'percentage'

  GasDetectionSettings({
    this.minThreshold = 50.0,
    this.maxThreshold = 500.0,
    this.enableNotifications = true,
    this.enableSound = true,
    this.autoWindowVentilation = true,
    this.unit = 'ppm',
  });

  Map<String, dynamic> toMap() {
    return {
      'min_threshold': minThreshold,
      'max_threshold': maxThreshold,
      'enable_notifications': enableNotifications,
      'enable_sound': enableSound,
      'auto_window_ventilation': autoWindowVentilation,
      'unit': unit,
    };
  }

  factory GasDetectionSettings.fromMap(Map<String, dynamic> map) {
    return GasDetectionSettings(
      minThreshold: map['min_threshold'] ?? 50.0,
      maxThreshold: map['max_threshold'] ?? 500.0,
      enableNotifications: map['enable_notifications'] ?? true,
      enableSound: map['enable_sound'] ?? true,
      autoWindowVentilation: map['auto_window_ventilation'] ?? true,
      unit: map['unit'] ?? 'ppm',
    );
  }

  GasDetectionSettings copyWith({
    double? minThreshold,
    double? maxThreshold,
    bool? enableNotifications,
    bool? enableSound,
    bool? autoWindowVentilation,
    String? unit,
  }) {
    return GasDetectionSettings(
      minThreshold: minThreshold ?? this.minThreshold,
      maxThreshold: maxThreshold ?? this.maxThreshold,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      enableSound: enableSound ?? this.enableSound,
      autoWindowVentilation: autoWindowVentilation ?? this.autoWindowVentilation,
      unit: unit ?? this.unit,
    );
  }
}

class Sensor {
  final String id;
  final String name;
  final String deviceId;
  final DateTime createdAt;
  bool isActive;

  Sensor({
    required this.id,
    required this.name,
    required this.deviceId,
    required this.createdAt,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'device_id': deviceId,
      'created_at': createdAt.toIso8601String(),
      'is_active': isActive,
    };
  }

  factory Sensor.fromMap(Map<String, dynamic> map) {
    return Sensor(
      id: map['id'],
      name: map['name'],
      deviceId: map['device_id'],
      createdAt: DateTime.parse(map['created_at']),
      isActive: map['is_active'] ?? true,
    );
  }
}

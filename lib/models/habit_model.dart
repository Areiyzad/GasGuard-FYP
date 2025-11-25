class Habit {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final String? icon;
  final String category;
  final String targetFrequency;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Runtime properties
  bool completed;
  int streak;

  Habit({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.icon,
    this.category = 'daily',
    this.targetFrequency = 'daily',
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.completed = false,
    this.streak = 0,
  });

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      icon: json['icon'] as String?,
      category: json['category'] as String? ?? 'daily',
      targetFrequency: json['target_frequency'] as String? ?? 'daily',
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'icon': icon,
      'category': category,
      'target_frequency': targetFrequency,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsert() {
    return {
      'user_id': userId,
      'title': title,
      'description': description,
      'icon': icon,
      'category': category,
      'target_frequency': targetFrequency,
      'is_active': isActive,
    };
  }

  Habit copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? icon,
    String? category,
    String? targetFrequency,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? completed,
    int? streak,
  }) {
    return Habit(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      category: category ?? this.category,
      targetFrequency: targetFrequency ?? this.targetFrequency,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completed: completed ?? this.completed,
      streak: streak ?? this.streak,
    );
  }

  // Helper to get display icon (emoji or default)
  String get displayIcon => icon ?? '✓';
}

class HabitCompletion {
  final String id;
  final String habitId;
  final String userId;
  final DateTime completedAt;
  final DateTime completionDate;
  final String? notes;
  final DateTime createdAt;

  HabitCompletion({
    required this.id,
    required this.habitId,
    required this.userId,
    required this.completedAt,
    required this.completionDate,
    this.notes,
    required this.createdAt,
  });

  factory HabitCompletion.fromJson(Map<String, dynamic> json) {
    return HabitCompletion(
      id: json['id'] as String,
      habitId: json['habit_id'] as String,
      userId: json['user_id'] as String,
      completedAt: DateTime.parse(json['completed_at'] as String),
      completionDate: DateTime.parse(json['completion_date'] as String),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'habit_id': habitId,
      'user_id': userId,
      'completed_at': completedAt.toIso8601String(),
      'completion_date': completionDate.toIso8601String().split('T')[0],
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsert() {
    return {
      'habit_id': habitId,
      'user_id': userId,
      'completion_date': completionDate.toIso8601String().split('T')[0],
      'notes': notes,
    };
  }
}

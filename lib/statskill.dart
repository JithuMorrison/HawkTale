import 'package:intl/intl.dart';

class Stat {
  final int? id;
  final String name;
  final String description;
  final int currentValue;
  final int maxValue;
  final DateTime createdAt;

  Stat({
    this.id,
    required this.name,
    this.description = '',
    this.currentValue = 0,
    this.maxValue = 100,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'current_value': currentValue,
      'max_value': maxValue,
      'created_at': DateFormat('yyyy-MM-dd').format(createdAt),
    };
  }

  factory Stat.fromMap(Map<String, dynamic> map) {
    return Stat(
      id: map['id'],
      name: map['name'],
      description: map['description'] ?? '',
      currentValue: map['current_value'] ?? 0,
      maxValue: map['max_value'] ?? 100,
      createdAt: map['created_at'] != null
          ? DateFormat('yyyy-MM-dd').parse(map['created_at'])
          : DateTime.now(),
    );
  }

  Stat copyWith({
    int? id,
    String? name,
    String? description,
    int? currentValue,
    int? maxValue,
    DateTime? createdAt,
  }) {
    return Stat(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      currentValue: currentValue ?? this.currentValue,
      maxValue: maxValue ?? this.maxValue,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class Skill {
  final int? id;
  final String name;
  final String description;
  final int currentXP;
  final int level;
  final bool isPassive;
  final DateTime createdAt;
  final DateTime? lastPassiveClick;

  Skill({
    this.id,
    required this.name,
    this.description = '',
    this.currentXP = 0,
    this.level = 1,
    this.isPassive = false,
    DateTime? createdAt,
    this.lastPassiveClick,
  }) : createdAt = createdAt ?? DateTime.now();

  int get xpForNextLevel => level * 500;

  double get progressToNextLevel => currentXP / xpForNextLevel;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'current_xp': currentXP,
      'level': level,
      'is_passive': isPassive ? 1 : 0,
      'created_at': DateFormat('yyyy-MM-dd').format(createdAt),
      'last_passive_click': lastPassiveClick != null
          ? DateFormat('yyyy-MM-dd').format(lastPassiveClick!)
          : null,
    };
  }

  factory Skill.fromMap(Map<String, dynamic> map) {
    return Skill(
      id: map['id'],
      name: map['name'],
      description: map['description'] ?? '',
      currentXP: map['current_xp'] ?? 0,
      level: map['level'] ?? 1,
      isPassive: map['is_passive'] == 1,
      createdAt: map['created_at'] != null
          ? DateFormat('yyyy-MM-dd').parse(map['created_at'])
          : DateTime.now(),
      lastPassiveClick: map['last_passive_click'] != null
          ? DateFormat('yyyy-MM-dd').parse(map['last_passive_click'])
          : null,
    );
  }

  Skill copyWith({
    int? id,
    String? name,
    String? description,
    int? currentXP,
    int? level,
    bool? isPassive,
    DateTime? createdAt,
    DateTime? lastPassiveClick,
  }) {
    return Skill(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      currentXP: currentXP ?? this.currentXP,
      level: level ?? this.level,
      isPassive: isPassive ?? this.isPassive,
      createdAt: createdAt ?? this.createdAt,
      lastPassiveClick: lastPassiveClick ?? this.lastPassiveClick,
    );
  }
}
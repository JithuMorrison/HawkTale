import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Habit {
  final int? id;
  final String name;
  final String description;
  final String type; // 'task', 'amount', 'time'
  final int targetValue;
  final String unit;
  final String frequency; // 'daily', 'weekly', 'monthly'
  final List<String> days;
  final TimeOfDay? reminderTime;
  final DateTime createdAt;

  Habit({
    this.id,
    required this.name,
    this.description = '',
    this.type = 'task',
    this.targetValue = 1,
    this.unit = 'times',
    this.frequency = 'daily',
    this.days = const [],
    this.reminderTime,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type,
      'target_value': targetValue,
      'unit': unit,
      'frequency': frequency,
      'days': days.join(','),
      'reminder_time': reminderTime != null
          ? '${reminderTime!.hour}:${reminderTime!.minute}'
          : null,
      'created_at': DateFormat('yyyy-MM-dd').format(createdAt),
    };
  }

  factory Habit.fromMap(Map<String, dynamic> map) {
    final timeParts = map['reminder_time']?.toString().split(':');
    return Habit(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      type: map['type'],
      targetValue: map['target_value'] ?? 1,
      unit: map['unit'] ?? 'times',
      frequency: map['frequency'] ?? 'daily',
      days: (map['days']?.toString().split(',') ?? []).where((d) => d.isNotEmpty).toList(),
      reminderTime: timeParts != null && timeParts.length == 2
          ? TimeOfDay(hour: int.parse(timeParts[0]), minute: int.parse(timeParts[1]))
          : null,
      createdAt: map['created_at'] != null
          ? DateFormat('yyyy-MM-dd').parse(map['created_at'])
          : DateTime.now(),
    );
  }

  Habit copyWith({
    int? id,
    String? name,
    String? description,
    String? type,
    int? targetValue,
    String? unit,
    String? frequency,
    List<String>? days,
    TimeOfDay? reminderTime,
    DateTime? createdAt,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      targetValue: targetValue ?? this.targetValue,
      unit: unit ?? this.unit,
      frequency: frequency ?? this.frequency,
      days: days ?? this.days,
      reminderTime: reminderTime ?? this.reminderTime,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
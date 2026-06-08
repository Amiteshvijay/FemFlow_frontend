import 'package:flutter/material.dart';

class NutritionReminder {
  final String key;
  final int id;
  final String label;
  final String title;
  final String body;
  final int hour;
  final int minute;
  final int iconCodePoint;
  final bool isCustom;

  NutritionReminder({
    required this.key,
    required this.id,
    required this.label,
    required this.title,
    required this.body,
    required this.hour,
    required this.minute,
    required this.iconCodePoint,
    this.isCustom = false,
  });

  TimeOfDay get time => TimeOfDay(hour: hour, minute: minute);

  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'id': id,
      'label': label,
      'title': title,
      'body': body,
      'hour': hour,
      'minute': minute,
      'iconCodePoint': iconCodePoint,
      'isCustom': isCustom,
    };
  }

  factory NutritionReminder.fromJson(Map<String, dynamic> json) {
    return NutritionReminder(
      key: json['key'],
      id: json['id'],
      label: json['label'],
      title: json['title'],
      body: json['body'],
      hour: json['hour'],
      minute: json['minute'],
      iconCodePoint: json['iconCodePoint'],
      isCustom: json['isCustom'] ?? false,
    );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/notification_service.dart';
import '../models/nutrition_reminder.dart';

class NutritionReminderHelper {
  static const String _remindersEnabledKey = 'reminders_enabled';
  static const String _customRemindersKey = 'custom_nutrition_reminders';

  static final List<Map<String, dynamic>> defaultRemindersDef = [
    {
      'key': 'breakfast',
      'id': 101,
      'label': 'Breakfast Alert',
      'title': 'Time for Breakfast!',
      'body': 'Fuel your body with a professional, nourishing meal.',
      'defaultTime': '08:00',
      'iconCodePoint': Icons.wb_sunny_outlined.codePoint,
    },
    {
      'key': 'water1',
      'id': 102,
      'label': 'Water Alert 1',
      'title': 'Hydration Check!',
      'body': 'Drink a fresh glass of water to support metabolism.',
      'defaultTime': '10:30',
      'iconCodePoint': Icons.opacity.codePoint,
    },
    {
      'key': 'lunch',
      'id': 103,
      'label': 'Lunch Alert',
      'title': 'Time for Lunch!',
      'body': 'Enjoy your custom balanced meal to support your goal.',
      'defaultTime': '13:00',
      'iconCodePoint': Icons.light_mode.codePoint,
    },
    {
      'key': 'water2',
      'id': 104,
      'label': 'Water Alert 2',
      'title': 'Hydration Check!',
      'body': 'Keep going! Drink some water to stay energized.',
      'defaultTime': '15:30',
      'iconCodePoint': Icons.opacity.codePoint,
    },
    {
      'key': 'snack',
      'id': 105,
      'label': 'Snack Alert',
      'title': 'Snack Alert!',
      'body': 'Time for a light healthy snack to keep energy steady.',
      'defaultTime': '17:00',
      'iconCodePoint': Icons.apple.codePoint,
    },
    {
      'key': 'dinner',
      'id': 106,
      'label': 'Dinner Alert',
      'title': 'Time for Dinner!',
      'body': 'Wrap up your day with a light, protein-rich dinner.',
      'defaultTime': '20:00',
      'iconCodePoint': Icons.dark_mode_outlined.codePoint,
    },
    {
      'key': 'water3',
      'id': 107,
      'label': 'Water Alert 3',
      'title': 'Hydration Check!',
      'body': 'A glass of water before bed to support muscle recovery.',
      'defaultTime': '21:30',
      'iconCodePoint': Icons.opacity.codePoint,
    },
  ];

  static Future<List<NutritionReminder>> loadReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final List<NutritionReminder> list = [];

    // Load Default Reminders
    for (var def in defaultRemindersDef) {
      final key = def['key'] as String;
      final id = def['id'] as int;
      final label = def['label'] as String;
      final title = def['title'] as String;
      final body = def['body'] as String;
      final iconCodePoint = def['iconCodePoint'] as int;
      final defaultTimeStr = def['defaultTime'] as String;

      final timeStr = prefs.getString('reminder_${key}_time') ?? defaultTimeStr;
      final timeParts = timeStr.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      list.add(NutritionReminder(
        key: key,
        id: id,
        label: label,
        title: title,
        body: body,
        hour: hour,
        minute: minute,
        iconCodePoint: iconCodePoint,
        isCustom: false,
      ));
    }

    // Load Custom Reminders
    final customJson = prefs.getString(_customRemindersKey);
    if (customJson != null) {
      try {
        final List<dynamic> decodedList = jsonDecode(customJson);
        for (var item in decodedList) {
          list.add(NutritionReminder.fromJson(item));
        }
      } catch (e) {
        debugPrint('Error parsing custom nutrition reminders: $e');
      }
    }

    // Sort by time
    list.sort((a, b) {
      final aMinutes = a.hour * 60 + a.minute;
      final bMinutes = b.hour * 60 + b.minute;
      return aMinutes.compareTo(bMinutes);
    });

    return list;
  }

  static Future<bool> areRemindersEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_remindersEnabledKey) ?? false;
  }

  static Future<void> setRemindersEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_remindersEnabledKey, enabled);
  }

  static Future<void> saveCustomReminder(NutritionReminder reminder) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await loadReminders();
    
    // Check if key already exists, if so update it
    final customList = list.where((item) => item.isCustom).toList();
    final index = customList.indexWhere((item) => item.key == reminder.key);
    
    if (index >= 0) {
      customList[index] = reminder;
    } else {
      customList.add(reminder);
    }

    final jsonList = customList.map((item) => item.toJson()).toList();
    await prefs.setString(_customRemindersKey, jsonEncode(jsonList));
  }

  static Future<void> deleteCustomReminder(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await loadReminders();
    
    final customList = list.where((item) => item.isCustom).toList();
    final targetIndex = customList.indexWhere((item) => item.key == key);

    if (targetIndex >= 0) {
      final target = customList[targetIndex];
      // Cancel local notification
      final notificationService = NotificationService();
      await notificationService.cancelNotification(target.id);
      
      customList.removeAt(targetIndex);
      final jsonList = customList.map((item) => item.toJson()).toList();
      await prefs.setString(_customRemindersKey, jsonEncode(jsonList));
    }
  }

  static Future<void> updateDefaultReminderTime(String key, TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    final timeStr = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    await prefs.setString('reminder_${key}_time', timeStr);
  }

  static Future<void> scheduleAll(List<NutritionReminder> reminders) async {
    final notificationService = NotificationService();
    await notificationService.requestPermissions();
    await notificationService.requestExactAlarmPermission();

    for (var reminder in reminders) {
      final now = DateTime.now();
      final scheduledDate = DateTime(
        now.year,
        now.month,
        now.day,
        reminder.hour,
        reminder.minute,
      );

      // Cancel first to prevent duplicates
      await notificationService.cancelNotification(reminder.id);

      await notificationService.scheduleNotification(
        id: reminder.id,
        title: reminder.title,
        body: reminder.body,
        scheduledDate: scheduledDate,
        repeatDaily: true,
        payload: 'diet:${reminder.key}',
      );
    }
  }

  static Future<void> cancelAll(List<NutritionReminder> reminders) async {
    final notificationService = NotificationService();
    for (var reminder in reminders) {
      await notificationService.cancelNotification(reminder.id);
    }
  }
}

import '../../../core/network/api_client.dart';
import '../../../core/services/notification_service.dart';
import '../../cycles/data/cycle_service.dart';

class Reminder {
  final int? id;
  final String title;
  final String reminderType;
  final String repeatType;
  final String scheduleText;
  final String time;
  final DateTime? specificDate;
  final String weekdays;
  final bool isActive;

  Reminder({
    this.id,
    required this.title,
    required this.reminderType,
    required this.repeatType,
    required this.scheduleText,
    required this.time,
    this.specificDate,
    required this.weekdays,
    required this.isActive,
  });

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'],
      title: json['title'],
      reminderType: json['reminder_type'],
      repeatType: json['repeat_type'] ?? 'daily',
      scheduleText: json['schedule_text'] ?? '',
      time: json['time'],
      specificDate: json['specific_date'] != null ? DateTime.parse(json['specific_date']) : null,
      weekdays: json['weekdays'] ?? '',
      isActive: json['is_active'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'reminder_type': reminderType,
      'repeat_type': repeatType,
      'schedule_text': scheduleText,
      'time': time,
      'specific_date': specificDate?.toIso8601String().split('T')[0],
      'weekdays': weekdays,
      'is_active': isActive,
    };
  }
}

class ReminderService {
  final ApiClient _apiClient = ApiClient();
  final NotificationService _notificationService = NotificationService();
  final CycleService _cycleService = CycleService();

  Future<List<Reminder>> getReminders() async {
    final response = await _apiClient.get('/reminders/');
    if (response is List) {
      return response.map((json) => Reminder.fromJson(json)).toList();
    }
    return [];
  }

  Future<Reminder> createReminder(Reminder reminder) async {
    final response = await _apiClient.post('/reminders/', body: reminder.toJson());
    final savedReminder = Reminder.fromJson(response);
    if (savedReminder.isActive) {
      await scheduleReminderNotification(savedReminder);
    }
    return savedReminder;
  }

  Future<Reminder> updateReminder(int id, Map<String, dynamic> data) async {
    final response = await _apiClient.patch('/reminders/$id/', body: data);
    final updatedReminder = Reminder.fromJson(response);
    
    // Always cancel old and re-schedule if active
    await _notificationService.cancelNotification(id);
    if (updatedReminder.isActive) {
      await scheduleReminderNotification(updatedReminder);
    }
    
    return updatedReminder;
  }

  Future<void> deleteReminder(int id) async {
    await _notificationService.cancelNotification(id);
    await _apiClient.delete('/reminders/$id/');
  }

  Future<void> scheduleReminderNotification(Reminder reminder) async {
    if (!reminder.isActive) return;

    String body = _getNotificationBody(reminder);
    DateTime? scheduledTime = _parseTime(reminder.time);
    if (scheduledTime == null) return;

    final bool isMedication = reminder.reminderType == 'pill';

    if (reminder.repeatType == 'daily') {
      await _notificationService.scheduleNotification(
        id: reminder.id!,
        title: 'FemFlow Reminder',
        body: body,
        scheduledDate: scheduledTime,
        repeatDaily: true,
        payload: 'reminder:${reminder.id}:${reminder.reminderType}',
        isMedication: isMedication,
      );
    } else if (reminder.repeatType == 'weekly' && reminder.weekdays.isNotEmpty) {
      final List<int> days = reminder.weekdays.split(',').map((e) => int.parse(e)).toList();
      await _notificationService.scheduleNotification(
        id: reminder.id!,
        title: 'FemFlow Reminder',
        body: body,
        scheduledDate: scheduledTime,
        weekdays: days,
        payload: 'reminder:${reminder.id}:${reminder.reminderType}',
        isMedication: isMedication,
      );
    } else if (reminder.repeatType == 'once' && reminder.specificDate != null) {
      final combinedDate = DateTime(
        reminder.specificDate!.year,
        reminder.specificDate!.month,
        reminder.specificDate!.day,
        scheduledTime.hour,
        scheduledTime.minute,
      );
      if (combinedDate.isAfter(DateTime.now())) {
        await _notificationService.scheduleNotification(
          id: reminder.id!,
          title: 'FemFlow Reminder',
          body: body,
          scheduledDate: combinedDate,
          payload: 'reminder:${reminder.id}:${reminder.reminderType}',
          isMedication: isMedication,
        );
      }
    } else if (reminder.repeatType == 'period_relative') {
      // Fetch predicted period
      final dashboard = await _cycleService.getDashboard();
      final nextPeriodStr = dashboard['next_period'];
      if (nextPeriodStr != null) {
        DateTime nextPeriod = DateTime.parse(nextPeriodStr);
        // Logic for "Day before", etc.
        int offset = _parseOffset(reminder.scheduleText);
        DateTime targetDate = nextPeriod.add(Duration(days: offset));
        final combinedDate = DateTime(
          targetDate.year,
          targetDate.month,
          targetDate.day,
          scheduledTime.hour,
          scheduledTime.minute,
        );
        if (combinedDate.isAfter(DateTime.now())) {
          await _notificationService.scheduleNotification(
            id: reminder.id!,
            title: 'FemFlow Reminder',
            body: body,
            scheduledDate: combinedDate,
            payload: 'reminder:${reminder.id}:${reminder.reminderType}',
            isMedication: isMedication,
          );
        }
      }
    }
  }

  String _getNotificationBody(Reminder reminder) {
    switch (reminder.reminderType) {
      case 'pill': return 'Time to take your medicine';
      case 'log_data': return 'Don\'t forget to log your health data';
      case 'period': return 'Your period is coming up soon';
      case 'ovulation': return 'Your fertile window is here';
      default: return 'Your reminder: ${reminder.title}';
    }
  }

  DateTime? _parseTime(String timeStr) {
    try {
      final parts = timeStr.split(':');
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
    } catch (e) {
      return null;
    }
  }

  int _parseOffset(String text) {
    if (text.toLowerCase().contains('day before')) return -1;
    if (text.toLowerCase().contains('2 days before')) return -2;
    if (text.toLowerCase().contains('day of')) return 0;
    return 0;
  }

  Future<void> scheduleAllActiveReminders() async {
    final reminders = await getReminders();
    for (var r in reminders) {
      if (r.isActive) {
        await scheduleReminderNotification(r);
      }
    }
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

// Action constants for medication reminders
const String actionTake = 'MED_TAKE';
const String actionSkip = 'MED_SKIP';
const String categoryMedication = 'MEDICATION_REMINDER';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  // This function handles notification actions when the app is in the background or terminated.
  // In a full implementation, this would use a background-safe service to call the API.
  debugPrint('Notification Action: ${notificationResponse.actionId} with payload: ${notificationResponse.payload}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Initialize TimeZone
    tz.initializeTimeZones();
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    final List<DarwinNotificationCategory> darwinNotificationCategories = [
      DarwinNotificationCategory(
        categoryMedication,
        actions: <DarwinNotificationAction>[
          DarwinNotificationAction.plain(actionTake, 'Take', options: {DarwinNotificationActionOption.foreground}),
          DarwinNotificationAction.plain(actionSkip, 'Skip'),
        ],
      ),
    ];

    final DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      notificationCategories: darwinNotificationCategories,
    );

    final InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap in foreground
        notificationTapBackground(response);
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
  }

  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;
    
    if (defaultTargetPlatform == TargetPlatform.android) {
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
          _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      // Request standard notification permission
      final bool? granted = await androidPlugin?.requestNotificationsPermission();
      
      return granted ?? false;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      final bool? granted = await _notificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return granted ?? false;
    }
    return false;
  }

  Future<void> requestExactAlarmPermission() async {
    if (kIsWeb) return;

    if (defaultTargetPlatform == TargetPlatform.android) {
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
          _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      final bool? canSchedule = await androidPlugin?.canScheduleExactNotifications();
      if (canSchedule == false) {
        // This will typically open the system settings page for exact alarms
        await androidPlugin?.requestExactAlarmsPermission();
      }
    }
  }

  Future<AndroidScheduleMode> _getScheduleMode() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
          _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      final bool? canSchedule = await androidPlugin?.canScheduleExactNotifications();
      if (canSchedule == true) {
        return AndroidScheduleMode.exactAllowWhileIdle;
      }
    }
    // Fallback to inexact to avoid PlatformException crash
    return AndroidScheduleMode.inexactAllowWhileIdle;
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
    bool repeatDaily = false,
    List<int>? weekdays, // 1-7 (Mon-Sun)
    bool isMedication = false,
  }) async {
    if (kIsWeb) return;

    final tz.TZDateTime tzDate = tz.TZDateTime.from(scheduledDate, tz.local);
    final AndroidScheduleMode scheduleMode = await _getScheduleMode();

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'femflow_reminders',
      'FemFlow Reminders',
      channelDescription: 'Notifications for period, pills, and wellness reminders',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      actions: isMedication ? <AndroidNotificationAction>[
        const AndroidNotificationAction(actionTake, 'Take', showsUserInterface: true),
        const AndroidNotificationAction(actionSkip, 'Skip'),
      ] : null,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        categoryIdentifier: isMedication ? categoryMedication : null,
      ),
    );

    if (repeatDaily) {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        _nextInstanceOfTime(scheduledDate),
        details,
        androidScheduleMode: scheduleMode,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payload,
      );
    } else if (weekdays != null && weekdays.isNotEmpty) {
      for (var day in weekdays) {
        // flutter_local_notifications uses 1 for Monday, 7 for Sunday
        // We create a unique ID for each day of the week to avoid collisions
        // e.g. id * 10 + day
        await _notificationsPlugin.zonedSchedule(
          id * 10 + day,
          title,
          body,
          _nextInstanceOfWeekday(scheduledDate, day),
          details,
          androidScheduleMode: scheduleMode,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          payload: payload,
        );
      }
    } else {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzDate,
        details,
        androidScheduleMode: scheduleMode,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
    }
  }

  tz.TZDateTime _nextInstanceOfWeekday(DateTime time, int day) {
    tz.TZDateTime scheduledDate = _nextInstanceOfTime(time);
    while (scheduledDate.weekday != day) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  tz.TZDateTime _nextInstanceOfTime(DateTime time) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
    // Also cancel weekly sub-IDs
    for (int day = 1; day <= 7; day++) {
      await _notificationsPlugin.cancel(id * 10 + day);
    }
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }
}

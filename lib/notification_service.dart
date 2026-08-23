import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final NotificationService instance =
      NotificationService._();

  final FlutterLocalNotificationsPlugin notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const settings = InitializationSettings(
      android: androidSettings,
    );

    await notifications.initialize(settings);

    final androidPlugin =
        notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.requestNotificationsPermission();
  }

  // ============================================================
  // SCHEDULE ONE DAILY REMINDER
  // ============================================================

  Future<void> scheduleDailyReminder({
    required int id,
    required String medicineName,
    required String dosage,
    required String time,
  }) async {
    final parsedTime = _parseTime(time);

    if (parsedTime == null) {
      return;
    }

    final now = tz.TZDateTime.now(tz.local);

    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      parsedTime.hour,
      parsedTime.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(
        const Duration(days: 1),
      );
    }

    await notifications.zonedSchedule(
      id,
      'Time for your medicine 💊',
      '$medicineName • $dosage',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'dosemate_medications',
          'Medication Reminders',
          channelDescription:
              'Reminders to take scheduled medications.',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode:
          AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents:
          DateTimeComponents.time,
    );
  }

  // ============================================================
  // CANCEL ONE REMINDER
  // ============================================================

  Future<void> cancelReminder(int id) async {
    await notifications.cancel(id);
  }

  // ============================================================
  // CANCEL ALL REMINDERS
  // ============================================================

  Future<void> cancelAll() async {
    await notifications.cancelAll();
  }

  // ============================================================
  // PARSE TIME
  // ============================================================

  TimeOfDayData? _parseTime(String value) {
    try {
      final parts = value.trim().split(' ');

      if (parts.length != 2) {
        return null;
      }

      final timeParts = parts[0].split(':');

      if (timeParts.length != 2) {
        return null;
      }

      int hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      final period = parts[1].toUpperCase();

      if (period == 'PM' && hour != 12) {
        hour += 12;
      }

      if (period == 'AM' && hour == 12) {
        hour = 0;
      }

      return TimeOfDayData(
        hour: hour,
        minute: minute,
      );
    } catch (_) {
      return null;
    }
  }
}

class TimeOfDayData {
  final int hour;
  final int minute;

  const TimeOfDayData({
    required this.hour,
    required this.minute,
  });
}
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final NotificationService instance =
      NotificationService._();

  final FlutterLocalNotificationsPlugin notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    try {
      // Initialize timezone database.
      tz.initializeTimeZones();

      // ----------------------------------------------------------
      // Get device timezone
      // ----------------------------------------------------------

      final timezoneInfo =
          await FlutterTimezone.getLocalTimezone();

      String timezoneName = timezoneInfo.identifier;

      print('DEVICE TIMEZONE: $timezoneName');

      // ----------------------------------------------------------
      // Android can return the old alias:
      //
      // Asia/Calcutta
      //
      // timezone package uses:
      //
      // Asia/Kolkata
      // ----------------------------------------------------------

      if (timezoneName == 'Asia/Calcutta') {
        timezoneName = 'Asia/Kolkata';
      }

      // More common aliases can be handled here too.
      if (timezoneName == 'US/Eastern') {
        timezoneName = 'America/New_York';
      }

      if (timezoneName == 'US/Central') {
        timezoneName = 'America/Chicago';
      }

      if (timezoneName == 'US/Mountain') {
        timezoneName = 'America/Denver';
      }

      if (timezoneName == 'US/Pacific') {
        timezoneName = 'America/Los_Angeles';
      }

      // ----------------------------------------------------------
      // Set timezone
      // ----------------------------------------------------------

      try {
        tz.setLocalLocation(
          tz.getLocation(timezoneName),
        );

        print(
          'TIMEZONE SET SUCCESSFULLY: $timezoneName',
        );
      } catch (e) {
        print(
          'TIMEZONE NOT FOUND: $timezoneName',
        );

        print(
          'Falling back to UTC.',
        );

        tz.setLocalLocation(
          tz.getLocation('UTC'),
        );
      }

      // ----------------------------------------------------------
      // Android initialization
      // ----------------------------------------------------------

      const androidSettings =
          AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );

      const settings =
          InitializationSettings(
        android: androidSettings,
      );

      await notifications.initialize(
        settings,
      );

      // ----------------------------------------------------------
      // Android permissions
      // ----------------------------------------------------------

      final androidPlugin =
          notifications
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>();

      // Android 13+
      await androidPlugin
          ?.requestNotificationsPermission();

      // Android 12+
      await androidPlugin
          ?.requestExactAlarmsPermission();

      // ----------------------------------------------------------
      // Notification channel
      // ----------------------------------------------------------

      const channel =
          AndroidNotificationChannel(
        'dosemate_medications',
        'Medication Reminders',
        description:
            'Reminders to take scheduled medications.',
        importance: Importance.high,
      );

      await androidPlugin
          ?.createNotificationChannel(channel);

      _initialized = true;

      print(
        'NOTIFICATION SERVICE INITIALIZED SUCCESSFULLY',
      );
    } catch (e, stackTrace) {
      print(
        'NOTIFICATION INITIALIZATION ERROR: $e',
      );

      print(stackTrace);

      // IMPORTANT:
      // Don't crash the whole app because notifications failed.
      _initialized = false;
    }
  }

  // ============================================================
  // SCHEDULE DAILY REMINDER
  // ============================================================

  Future<bool> scheduleDailyReminder({
    required int id,
    required String medicineName,
    required String dosage,
    required String time,
  }) async {
    try {
      if (!_initialized) {
        await initialize();
      }

      // If initialization still failed, stop here.
      if (!_initialized) {
        print(
          'NOTIFICATION ERROR: Service was not initialized.',
        );

        return false;
      }

      final parsedTime = _parseTime(time);

      if (parsedTime == null) {
        print(
          'NOTIFICATION ERROR: Invalid time: $time',
        );

        return false;
      }

      // ----------------------------------------------------------
      // Current local time
      // ----------------------------------------------------------

      final now =
          tz.TZDateTime.now(tz.local);

      // ----------------------------------------------------------
      // Today's scheduled time
      // ----------------------------------------------------------

      var scheduledDate =
          tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        parsedTime.hour,
        parsedTime.minute,
      );

      // ----------------------------------------------------------
      // If time already passed today,
      // schedule first reminder tomorrow.
      // ----------------------------------------------------------

      if (scheduledDate.isBefore(now)) {
        scheduledDate =
            scheduledDate.add(
          const Duration(days: 1),
        );
      }

      print('--------------------------------');
      print('SCHEDULING MEDICATION');
      print('ID: $id');
      print('MEDICINE: $medicineName');
      print('DOSAGE: $dosage');
      print('TIME: $time');
      print('SCHEDULED: $scheduledDate');
      print('TIMEZONE: ${tz.local.name}');
      print('--------------------------------');

      // ----------------------------------------------------------
      // Notification details
      // ----------------------------------------------------------

      const androidDetails =
          AndroidNotificationDetails(
        'dosemate_medications',
        'Medication Reminders',
        channelDescription:
            'Reminders to take scheduled medications.',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      );

      const notificationDetails =
          NotificationDetails(
        android: androidDetails,
      );

      // ----------------------------------------------------------
      // Schedule notification
      // ----------------------------------------------------------

      await notifications.zonedSchedule(
        id,
        'Time for your medicine 💊',
        '$medicineName • $dosage',
        scheduledDate,
        notificationDetails,
        androidScheduleMode:
            AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents:
            DateTimeComponents.time,
      );

      print(
        'NOTIFICATION SCHEDULED SUCCESSFULLY',
      );

      return true;
    } catch (e, stackTrace) {
      print(
        'NOTIFICATION SCHEDULING ERROR: $e',
      );

      print(stackTrace);

      return false;
    }
  }

  // ============================================================
  // CANCEL ONE
  // ============================================================

  Future<void> cancelReminder(int id) async {
    try {
      await notifications.cancel(id);

      print(
        'NOTIFICATION CANCELLED: $id',
      );
    } catch (e) {
      print(
        'NOTIFICATION CANCEL ERROR: $e',
      );
    }
  }

  // ============================================================
  // CANCEL ALL
  // ============================================================

  Future<void> cancelAll() async {
    try {
      await notifications.cancelAll();

      print(
        'ALL NOTIFICATIONS CANCELLED',
      );
    } catch (e) {
      print(
        'NOTIFICATION CANCEL ALL ERROR: $e',
      );
    }
  }

  // ============================================================
  // PENDING NOTIFICATIONS
  // ============================================================

  Future<void> printPendingNotifications() async {
    try {
      final pending =
          await notifications
              .pendingNotificationRequests();

      print(
        'PENDING NOTIFICATIONS: ${pending.length}',
      );

      for (final notification in pending) {
        print(
          'ID: ${notification.id} '
          '| TITLE: ${notification.title} '
          '| BODY: ${notification.body}',
        );
      }
    } catch (e) {
      print(
        'PENDING NOTIFICATIONS ERROR: $e',
      );
    }
  }

  // ============================================================
  // PARSE TIME
  // ============================================================

  TimeOfDayData? _parseTime(String value) {
    try {
      final cleaned =
          value.trim().replaceAll(
                RegExp(r'\s+'),
                ' ',
              );

      final parts =
          cleaned.split(' ');

      if (parts.length != 2) {
        return null;
      }

      final timeParts =
          parts[0].split(':');

      if (timeParts.length != 2) {
        return null;
      }

      int hour =
          int.parse(timeParts[0]);

      final minute =
          int.parse(timeParts[1]);

      final period =
          parts[1].toUpperCase();

      // ----------------------------------------------------------
      // Validate
      // ----------------------------------------------------------

      if (hour < 1 || hour > 12) {
        return null;
      }

      if (minute < 0 || minute > 59) {
        return null;
      }

      if (period != 'AM' &&
          period != 'PM') {
        return null;
      }

      // ----------------------------------------------------------
      // Convert to 24-hour time
      // ----------------------------------------------------------

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
    } catch (e) {
      print(
        'TIME PARSE ERROR: $e',
      );

      return null;
    }
  }
}

// ============================================================
// TIME DATA
// ============================================================

class TimeOfDayData {
  final int hour;
  final int minute;

  const TimeOfDayData({
    required this.hour,
    required this.minute,
  });
}
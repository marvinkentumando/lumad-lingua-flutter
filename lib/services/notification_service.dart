import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const int streakNotificationId = 100;
  static const int wotdNotificationId = 101;

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    try {
      tz.initializeTimeZones();

      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(settings: settings);
      _initialized = true;

      await requestPermissions();
    } catch (e) {
      debugPrint("Error initializing NotificationService: $e");
    }
  }

  Future<void> requestPermissions() async {
    try {
      final androidImplementation =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
      }
    } catch (e) {
      debugPrint("Error requesting notification permissions: $e");
    }
  }

  /// Schedules or updates the daily repeating streak reminder at [hour]:[minute].
  /// Uses [matchDateTimeComponents: DateTimeComponents.time] to repeat every day.
  Future<void> scheduleDailyStreakReminder({
    int hour = 20,
    int minute = 0,
    String? title,
    String? body,
  }) async {
    await init();

    try {
      // Cancel previous scheduled streak notification first
      await cancelDailyStreakReminder();

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'streak_reminder_channel',
        'Daily Streak Reminders',
        channelDescription: 'Daily reminders to complete lessons and protect your streak',
        importance: Importance.high,
        priority: Priority.high,
        styleInformation: BigTextStyleInformation(''),
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      // If scheduled time has already passed today, schedule for tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      final reminderTitle = title ?? '🔥 Keep Your Flame Burning!';
      final reminderBody = body ??
          "Don't let your daily streak slip away into the mist. Complete today's tribal lesson!";

      await _notifications.zonedSchedule(
        id: streakNotificationId,
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        title: reminderTitle,
        body: reminderBody,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      debugPrint("Scheduled daily streak reminder for $scheduledDate");
    } catch (e) {
      debugPrint("Error scheduling streak reminder: $e");
    }
  }

  /// Cancels the daily streak reminder notification.
  Future<void> cancelDailyStreakReminder() async {
    try {
      await _notifications.cancel(id: streakNotificationId);
      debugPrint("Cancelled daily streak reminder");
    } catch (e) {
      debugPrint("Error cancelling streak reminder: $e");
    }
  }

  /// Shows an instant preview streak notification for testing/debugging.
  Future<void> showInstantStreakWarning({
    String? title,
    String? body,
  }) async {
    await init();

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'streak_reminder_channel',
      'Daily Streak Reminders',
      channelDescription: 'Notifications for streak preservation',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _notifications.show(
      id: 0,
      title: title ?? '🔥 Streak in Danger!',
      body: body ?? 'Keep your daily rhythm alive. Complete a challenge now before midnight!',
      notificationDetails: details,
    );
  }

  /// Updates streak reminder schedule based on preferences and today's activity status.
  Future<void> updateStreakReminderSchedule({
    required bool enabled,
    int hour = 20,
    int minute = 0,
    bool isCompletedToday = false,
  }) async {
    if (!enabled) {
      await cancelDailyStreakReminder();
      return;
    }

    if (isCompletedToday) {
      // User has finished today's streak!
      // Schedule reminder for tomorrow at specified time
      await cancelDailyStreakReminder();
      await scheduleDailyStreakReminder(
        hour: hour,
        minute: minute,
        title: '☀️ Flame Maintained!',
        body: 'Great job today! Tomorrow brings a new step on your ancestral path.',
      );
    } else {
      // User hasn't finished today's streak yet: schedule for today at hour:minute
      await scheduleDailyStreakReminder(
        hour: hour,
        minute: minute,
      );
    }
  }

  Future<void> scheduleWordOfTheDay(String word, String meaning) async {
    await init();

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'wotd_channel',
      'Word of the Day',
      importance: Importance.low,
      priority: Priority.low,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      9,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      id: wotdNotificationId,
      scheduledDate: scheduledDate,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      title: '📖 Word of the Day: $word',
      body: 'Learn what "$word" means in our ancestral tongue.',
    );
  }
}

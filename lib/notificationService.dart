import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'notificationConfig.dart';

import 'package:timezone/timezone.dart' as tz;

const int notificationsPerDay = 15;
const int notificationDays = 4;
const int maxPendingNotifications =
    64; // iOS per-app cap on pending local notifications

class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  final tz.TZDateTime Function() _now;

  NotificationService({
    FlutterLocalNotificationsPlugin? plugin,
    tz.TZDateTime Function()? now,
  }) : flutterLocalNotificationsPlugin =
           plugin ?? FlutterLocalNotificationsPlugin(),
       _now = now ?? (() => tz.TZDateTime.now(tz.local));

  Future<void> initialize() async {
    var initializationSettingsAndroid = AndroidInitializationSettings(
      'ic_notifications_white_18dp',
    );
    // permission is asked for in requestPermissions, not at launch
    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        );

    final InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );
    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
    );
  }

  /// Asks for permission to show notifications, when the user turns them on.
  /// Completes once the user answers (or the request fails); errors are
  /// logged, not thrown.
  Future<void> requestPermissions() async {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission()
        .onError<PlatformException>((e, _) {
          debugPrint('notification permission request failed: $e');
          return null;
        });
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true)
        .onError<PlatformException>((e, _) {
          debugPrint('notification permission request failed: $e');
          return null;
        });
  }

  /// Whether the OS lets the app show notifications (iOS provisional
  /// authorization counts). True if it can't tell, so a failed check never
  /// turns notifications off.
  Future<bool> hasPermission() async {
    try {
      final android = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android != null) {
        return await android.areNotificationsEnabled() ?? true;
      }
      final ios = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (ios != null) {
        final options = await ios.checkPermissions();
        return options == null ||
            options.isEnabled ||
            options.isProvisionalEnabled;
      }
    } on PlatformException catch (e) {
      debugPrint('notification permission check failed: $e');
    }
    return true;
  }

  void onDidReceiveNotificationResponse(NotificationResponse? response) {
    // Handle notification tapped
    debugPrint('notification tapped: ${response?.payload}');
  }

  /// Schedules one-shot notifications hourly from 7 a.m. to 9 p.m. for
  /// today and the next [notificationDays] - 1 days, skipping times that have
  /// already passed. IDs are `day * notificationsPerDay + slot`. With
  /// [skipToday], nothing is scheduled for today.
  Future<void> scheduleNotifications({bool skipToday = false}) async {
    final tz.TZDateTime now = _now();
    debugPrint('scheduling notifications (now: $now, skipToday: $skipToday)');

    for (int day = 0; day < notificationDays; day++) {
      if (day == 0 && skipToday) {
        continue;
      }
      for (int slot = 0; slot < notificationsPerDay; slot++) {
        final tz.TZDateTime scheduledTime = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day + day,
          7 + slot,
        );
        if (!scheduledTime.isAfter(now)) {
          continue;
        }
        final int id = day * notificationsPerDay + slot;
        await flutterLocalNotificationsPlugin.zonedSchedule(
          id: id,
          title: notificationTitle,
          body: notificationBody,
          scheduledDate: scheduledTime,
          notificationDetails: platformChannelSpecifics,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
        debugPrint('scheduled notification $id for $scheduledTime');
      }
    }
  }

  /// Brings scheduled notifications in line with the stored preferences:
  /// cancels everything, then (if enabled) schedules the rolling window of
  /// notifications, skipping today when today's 15 prayers are complete.
  Future<void> syncNotifications() async {
    await cancelAllNotifications();

    final prefs = await SharedPreferences.getInstance();
    final bool notificationsEnabled =
        prefs.getBool('notifications_enabled') ?? false;
    if (!notificationsEnabled) {
      debugPrint('notifications disabled, nothing scheduled');
      return;
    }

    await scheduleNotifications(skipToday: _prayersCompleteToday(prefs));
  }

  bool _prayersCompleteToday(SharedPreferences prefs) {
    final int counter = prefs.getInt('counter') ?? 0;
    final String? lastUpdatedStr = prefs.getString('last_updated');
    if (counter < 15 || lastUpdatedStr == null) {
      return false;
    }
    final DateTime lastUpdated = DateTime.parse(lastUpdatedStr);
    final tz.TZDateTime now = _now();
    return lastUpdated.year == now.year &&
        lastUpdated.month == now.month &&
        lastUpdated.day == now.day;
  }

  Future<void> cancelAllNotifications() async {
    debugPrint('cancelling all notifications');
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}

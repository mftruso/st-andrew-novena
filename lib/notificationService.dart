import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'notificationConfig.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  NotificationService({FlutterLocalNotificationsPlugin? plugin})
      : flutterLocalNotificationsPlugin =
            plugin ?? FlutterLocalNotificationsPlugin();

  Future<void> scheduleNotificationsFor(DateTime day) async {
    debugPrint('scheduling notifications for ${day.toIso8601String()}');
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, day.year, day.month, day.day, 7);

    for (int i = 0; i < 15; i++) {
      final tz.TZDateTime scheduledTime = scheduledDate.add(Duration(hours: i));
      if (scheduledTime.isAfter(now)) {
        flutterLocalNotificationsPlugin.zonedSchedule(
          i, // unique id from 0 to 14
          notificationTitle,
          notificationBody,
          scheduledTime,
          platformChannelSpecifics,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
        debugPrint('scheduled notification $i for $scheduledTime');
      }
    }
  }

  Future<void> cancelAllNotifications() async {
    debugPrint('cancelling all notifications');
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}

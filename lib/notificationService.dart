import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'notificationConfig.dart';
import 'package:timezone/timezone.dart' as tz;


class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future scheduleNotifications() async {
    // Show a notification every minute with the first appearance happening a minute after invoking the method
    await flutterLocalNotificationsPlugin.periodicallyShow(
        0,
        notificationTitle,
        notificationBody,
       // RepeatInterval.everyMinute, // DEBUG
        RepeatInterval.hourly,
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle);
    debugPrint('notifications scheduled');
  }

  Future<void> cancelNotification() async {
    debugPrint('cancelling notifications');
    await flutterLocalNotificationsPlugin.cancel(0);
  }

  Future<void> rescheduleForTomorrow() async {
    debugPrint('cancelling current notifications');
    await flutterLocalNotificationsPlugin.cancelAll();

    debugPrint('rescheduling notifications');
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, 7);
       // tz.TZDateTime(tz.local, now.year, now.month, now.day, now.hour, now.minute + 1); // DEBUG in a minute

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    debugPrint("reschedule time: " + scheduledDate.toIso8601String());
    flutterLocalNotificationsPlugin.zonedSchedule(
        0,
        notificationTitle,
        notificationBody,
        scheduledDate,
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: "RESET");
  }
}

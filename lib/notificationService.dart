import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'notificationConfig.dart';


class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future scheduleNotifications() async {
    // Show a notification every minute with the first appearance happening a minute after invoking the method
    await flutterLocalNotificationsPlugin.periodicallyShow(
        0,
        notificationTitle,
        notificationBody,
        RepeatInterval.everyMinute,
        platformChannelSpecifics);
    debugPrint('notifications scheduled');
  }

  Future<void> cancelNotification() async {
    debugPrint('cancelling notifications');
    await flutterLocalNotificationsPlugin.cancel(0);
  }
}
import 'dart:typed_data';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

var androidPlatformChannelSpecifics = AndroidNotificationDetails(
    'st-andrew-novena-notifications', // channel id
    'St. Andrew Novena Notifications', // channel name
    enableVibration: true,
    vibrationPattern: Int64List.fromList([0, 250, 250]),
    playSound: true);
var iOSPlatformChannelSpecifics = DarwinNotificationDetails();
var platformChannelSpecifics = NotificationDetails(
    android: androidPlatformChannelSpecifics, iOS: iOSPlatformChannelSpecifics);

const notificationTitle = 'Oremus';
const notificationBody = 'Pray the St. Andrew Novena';

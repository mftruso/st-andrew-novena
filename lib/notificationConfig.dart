import 'dart:typed_data';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

var androidPlatformChannelSpecifics = AndroidNotificationDetails(
    'st-andrew-novena-notifications', // channel id
    'St. Andrew Novena Notifications', // channel name
    'repeating prayer notifications', // channel description
    enableVibration: true,
    vibrationPattern: Int64List.fromList([0, 250, 250]),
    playSound: true
);
var iOSPlatformChannelSpecifics = IOSNotificationDetails();
var platformChannelSpecifics = NotificationDetails(
    androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);

const notificationTitle = 'Oremus';
const notificationBody = 'Pray the St. Andrew Novena';

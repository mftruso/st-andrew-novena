import 'dart:typed_data';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// TODO icon https://github.com/MaikuB/flutter_local_notifications/tree/master/flutter_local_notifications#custom-notification-icons-and-sounds
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
    android: androidPlatformChannelSpecifics,
    iOS: iOSPlatformChannelSpecifics);

const notificationTitle = 'Oremus';
const notificationBody = 'Pray the St. Andrew Novena';

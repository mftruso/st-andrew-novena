import 'dart:typed_data';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

var androidPlatformChannelSpecifics = AndroidNotificationDetails(
  'st-andrew-novena-notifications', // channel id
  'St. Andrew Novena Notifications', // channel name
  enableVibration: true,
  vibrationPattern: Int64List.fromList([0, 250, 250]),
  playSound: true,
  // dismiss each hourly reminder just before the next one arrives so
  // missed reminders don't pile up in the notification shade
  timeoutAfter: 59 * 60 * 1000,
);
// iOS has no timeout, so group missed reminders into a single stack instead
var iOSPlatformChannelSpecifics = DarwinNotificationDetails(
  threadIdentifier: 'st-andrew-novena',
);
var platformChannelSpecifics = NotificationDetails(
  android: androidPlatformChannelSpecifics,
  iOS: iOSPlatformChannelSpecifics,
);

const notificationTitle = 'Oremus';
const notificationBody = 'Pray the St. Andrew Novena';

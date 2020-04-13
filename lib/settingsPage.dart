import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'notificationConfig.dart';

class SettingsPage extends StatefulWidget {
  SettingsPage({Key key}) : super(key: key);

  @override
  _SettingPagesState createState() => _SettingPagesState();
}

class _SettingPagesState extends State<SettingsPage> {
  bool _notificationsEnabled = false;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future _initializeSettings() async {
    final prefs = await SharedPreferences.getInstance();
    bool notificationsEnabled = prefs.getBool('notifications_enabled');
    setState(() {
      _notificationsEnabled = notificationsEnabled ?? false;
    });
  }

  Future _storeNotificationPreferences(value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('notifications_enabled', value);
    if (value) {
      _scheduleNotifications();
    } else {
      _cancelNotification();
    }
  }

  Future _scheduleNotifications() async {
    // Show a notification every minute with the first appearance happening a minute after invoking the method
    await flutterLocalNotificationsPlugin.periodicallyShow(
        0,
        notificationTitle,
        notificationBody,
        RepeatInterval.EveryMinute,
        platformChannelSpecifics);
    debugPrint('notifications scheduled');
  }

  Future<void> _cancelNotification() async {
    debugPrint('cancelling notifications');
    await flutterLocalNotificationsPlugin.cancel(0);
  }

  @override
  void initState() {
    super.initState();
    _initializeSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Settings'),
          automaticallyImplyLeading: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, false),
          ),
        ),
        body: Center(
            child: Padding(
                padding: const EdgeInsets.all(10.0),

                // We use [Builder] here to use a [context] that is a descendant of [Scaffold] for showToast to work
                child: Builder(
                    builder: (context) => Column(
                          children: <Widget>[
                            ListTile(
                              title: Text('Notifications'),
                              trailing: Switch(
                                value: _notificationsEnabled,
                                onChanged: (value) {
                                  setState(() {
                                    _notificationsEnabled = value;
                                    _storeNotificationPreferences(value);
                                    _showToast(context, value);
                                  });
                                },
                              ),
                            )
                          ],
                        )))));
  }

  void _showToast(BuildContext context, bool notificationsEnabled) {
    debugPrint(
        'notification setting set to: ' + notificationsEnabled.toString());
    final scaffold = Scaffold.of(context);
    scaffold.showSnackBar(
      SnackBar(
        content: notificationsEnabled
            ? Text('Notifications Enabled')
            : Text('Notifications Disabled'),
      ),
    );
  }
}

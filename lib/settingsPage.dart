import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:st_andrew_novena/notificationService.dart';

import 'main.dart'; // need for getIt

class SettingsPage extends StatefulWidget {
  SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingPagesState createState() => _SettingPagesState();
}

class _SettingPagesState extends State<SettingsPage> {
  bool _notificationsEnabled = false;

  Future _initializeSettings() async {
    final prefs = await SharedPreferences.getInstance();
    bool? notificationsEnabled = prefs.getBool('notifications_enabled');
    setState(() {
      _notificationsEnabled = notificationsEnabled ?? false;
    });
  }

  Future _storeNotificationPreferences(value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('notifications_enabled', value);
    if (value) {
      getIt<NotificationService>().scheduleNotifications();
    } else {
      getIt<NotificationService>().cancelNotification();
    }
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
          backgroundColor: Theme.of(context).colorScheme.background,
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
                            ),
                            ListTile(
                              dense: true,
                              title: Text(
                                'Enables hourly notifications until the prayer is completed 15 times daily. Notifications resume at 7 a.m. each day.',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            )
                          ],
                        )))));
  }

  void _showToast(BuildContext context, bool notificationsEnabled) {
    debugPrint(
        'notification setting set to: ' + notificationsEnabled.toString());
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
      SnackBar(
        content: notificationsEnabled
            ? Text('Notifications Enabled')
            : Text('Notifications Disabled'),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  SettingsPage({Key key}) : super(key: key);

  @override
  _SettingPagesState createState() => _SettingPagesState();
}

class _SettingPagesState extends State<SettingsPage> {
  bool _notificationsEnabled = false;

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
                child: Column(
                  children: <Widget>[
                    ListTile(
                      title: Text('Notifications'),
                      trailing: Switch(
                        value: _notificationsEnabled,
                        onChanged: (value) {
                          setState(() {
                            _notificationsEnabled = value;
                            _storeNotificationPreferences(value);
                          });
                        },
                      ),
                    )
                  ],
                ))));
  }
}

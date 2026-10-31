import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:st_andrew_novena/appTheme.dart';
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
    await _turnOffIfNotPermitted();
  }

  Future _storeNotificationPreferences(value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
    if (value) {
      // Not awaited: the dialog can stay up. iOS drops notifications
      // scheduled before permission is granted, so resync once it's answered.
      getIt<NotificationService>().requestPermissions().then((_) async {
        if (await _turnOffIfNotPermitted()) {
          return;
        }
        await getIt<NotificationService>().syncNotifications();
        // unless it was switched back off while the dialog was up
        if (mounted && _notificationsEnabled) {
          _showToast(context, true);
        }
      });
    }
    await getIt<NotificationService>().syncNotifications();
  }

  /// Turns notifications off (and resyncs) if they're on but the OS doesn't
  /// allow them: the prompt was denied, or permission was revoked in system
  /// settings. Returns whether it turned them off.
  Future<bool> _turnOffIfNotPermitted() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool('notifications_enabled') ?? false) ||
        await getIt<NotificationService>().hasPermission()) {
      return false;
    }
    await prefs.setBool('notifications_enabled', false);
    await getIt<NotificationService>().syncNotifications();
    if (!mounted) {
      return true;
    }
    setState(() {
      _notificationsEnabled = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Notifications are turned off for this app in system settings',
        ),
      ),
    );
    return true;
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
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxContentWidth),
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
                      onChanged: (value) async {
                        setState(() {
                          _notificationsEnabled = value;
                        });
                        // enabling is confirmed once permission is answered
                        if (!value) {
                          _showToast(context, value);
                        }
                        await _storeNotificationPreferences(value);
                      },
                    ),
                  ),
                  ListTile(
                    dense: true,
                    title: Text(
                      'Enables hourly notifications until the prayer is completed 15 times daily. Notifications resume at 7 a.m. each day.',
                      style: Theme.of(context).textTheme.bodyLarge
                          ?.copyWith(fontSize: 18, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showToast(BuildContext context, bool notificationsEnabled) {
    debugPrint(
      'notification setting set to: ' + notificationsEnabled.toString(),
    );
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

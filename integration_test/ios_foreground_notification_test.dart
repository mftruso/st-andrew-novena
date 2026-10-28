// Checks that, under the UIScene lifecycle, iOS hands foreground
// notifications to the plugin. AppDelegate sets itself as the
// UNUserNotificationCenter delegate in didFinishLaunching, but plugins are
// only registered later, in didInitializeImplicitFlutterEngine. If willPresent
// didn't reach the plugin, its completion handler would never be called and
// the notification would not be delivered.
//
// Run with: flutter test integration_test/ios_foreground_notification_test.dart -d <ios simulator>
// It asks for provisional authorization, which iOS grants without a prompt.

import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'a notification shown in the foreground is delivered',
    (WidgetTester tester) async {
      final plugin = FlutterLocalNotificationsPlugin();
      await plugin.initialize(
        settings: InitializationSettings(
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
            requestProvisionalPermission: true,
          ),
        ),
      );
      await plugin.cancelAll();

      await plugin.show(
        id: 99,
        title: 'foreground test',
        body: 'foreground test',
      );

      List<ActiveNotification> active = [];
      for (int i = 0; i < 50 && active.isEmpty; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        active = await plugin.getActiveNotifications();
      }
      expect(active.map((n) => n.id), contains(99));
      await plugin.cancelAll();
    },
    skip: !Platform.isIOS,
  );
}

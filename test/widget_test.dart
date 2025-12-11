// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:st_andrew_novena/notificationService.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:st_andrew_novena/main.dart';

import 'notification_service_test.mocks.dart';

void main() {
  late MockNotificationService mockNotificationService;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/New_York'));

    mockNotificationService = MockNotificationService();
    when(mockNotificationService.initialize()).thenAnswer((_) async => {});
    when(mockNotificationService.scheduleNotificationsFor(any))
        .thenAnswer((_) async => {});
    when(mockNotificationService.cancelAllNotifications())
        .thenAnswer((_) async => {});

    final getIt = GetIt.instance;
    if (getIt.isRegistered<NotificationService>()) {
      getIt.unregister<NotificationService>();
    }
    getIt.registerSingleton<NotificationService>(mockNotificationService);
  });

  tearDown(() {
    GetIt.instance.reset();
  });

  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp());
    await tester.pumpAndSettle();

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the 'Amen' button and trigger a frame.
    await tester.tap(find.text('Amen'));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}

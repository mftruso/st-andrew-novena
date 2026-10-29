// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:st_andrew_novena/notificationService.dart';
import 'package:st_andrew_novena/prayerBeads.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:st_andrew_novena/main.dart';

import 'notification_service_test.mocks.dart';

List<bool> beadsFilled(WidgetTester tester) => [
  for (var i = 0; i < 15; i++)
    tester.widget<PrayerBead>(find.byKey(ValueKey('bead-$i'))).filled,
];

void main() {
  late MockNotificationService mockNotificationService;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/New_York'));

    mockNotificationService = MockNotificationService();
    when(mockNotificationService.initialize()).thenAnswer((_) async => {});
    when(
      mockNotificationService.scheduleNotifications(
        skipToday: anyNamed('skipToday'),
      ),
    ).thenAnswer((_) async => {});
    when(mockNotificationService.cancelAllNotifications())
        .thenAnswer((_) async => {});
    when(mockNotificationService.syncNotifications())
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

  testWidgets('launch initializes then syncs notifications', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MyApp());
    await tester.pumpAndSettle();

    verifyInOrder([
      mockNotificationService.initialize(),
      mockNotificationService.syncNotifications(),
    ]);
  });

  testWidgets('15th prayer with notifications enabled resyncs notifications', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'notifications_enabled': true,
      'counter': 14,
      'last_updated': DateTime.now().toString(),
    });
    await tester.pumpWidget(MyApp());
    await tester.pumpAndSettle();
    expect(find.text('14'), findsOneWidget);
    verify(mockNotificationService.syncNotifications()).called(1); // startup

    await tester.tap(find.text('Amen'));
    await tester.pumpAndSettle();

    expect(find.text('15'), findsOneWidget);
    verify(mockNotificationService.syncNotifications()).called(1);
    verifyNever(mockNotificationService.cancelAllNotifications());
    verifyNever(
      mockNotificationService.scheduleNotifications(
        skipToday: anyNamed('skipToday'),
      ),
    );
    expect(
      find.text('Prayers complete! Notifications will resume tomorrow.'),
      findsOneWidget,
    );
  });

  testWidgets('15th prayer with notifications disabled schedules nothing', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'notifications_enabled': false,
      'counter': 14,
      'last_updated': DateTime.now().toString(),
    });
    await tester.pumpWidget(MyApp());
    await tester.pumpAndSettle();
    verify(mockNotificationService.syncNotifications()).called(1); // startup

    await tester.tap(find.text('Amen'));
    await tester.pumpAndSettle();

    expect(find.text('15'), findsOneWidget);
    verifyNever(mockNotificationService.syncNotifications());
    verifyNever(mockNotificationService.cancelAllNotifications());
    verifyNever(
      mockNotificationService.scheduleNotifications(
        skipToday: anyNamed('skipToday'),
      ),
    );
  });

  testWidgets('resuming on a new day resets the counter and resyncs', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'notifications_enabled': true,
      'counter': 7,
      'last_updated': DateTime.now().toString(),
    });
    await tester.pumpWidget(MyApp());
    await tester.pumpAndSettle();
    expect(find.text('7'), findsOneWidget);
    verify(mockNotificationService.syncNotifications()).called(1);

    // the app sat in the background overnight
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'last_updated',
      DateTime.now().subtract(const Duration(days: 1)).toString(),
    );
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(find.text('0'), findsOneWidget);
    verify(mockNotificationService.syncNotifications()).called(1);
  });

  testWidgets('reset menu item zeroes the counter and resyncs', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'notifications_enabled': true,
      'counter': 15,
      'last_updated': DateTime.now().toString(),
    });
    await tester.pumpWidget(MyApp());
    await tester.pumpAndSettle();
    expect(find.text('15'), findsOneWidget);
    verify(mockNotificationService.syncNotifications()).called(1); // startup

    await tester.tap(find.byType(PopupMenuButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();

    expect(find.text('0'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('counter'), 0);
    verify(mockNotificationService.syncNotifications()).called(1);
  });

  testWidgets('toggling the notifications setting resyncs', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MyApp());
    await tester.pumpAndSettle();
    clearInteractions(mockNotificationService);

    await tester.tap(find.byType(PopupMenuButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    verify(mockNotificationService.syncNotifications()).called(1);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('notifications_enabled'), isTrue);
  });

  testWidgets('each Amen fills one more bead', (WidgetTester tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(MyApp());
    await tester.pumpAndSettle();
    expect(beadsFilled(tester), everyElement(isFalse));

    for (var i = 0; i < 7; i++) {
      await tester.tap(find.text('Amen'));
      await tester.pumpAndSettle();
    }

    expect(find.text('7'), findsOneWidget);
    expect(beadsFilled(tester), [
      ...List.filled(7, true),
      ...List.filled(8, false),
    ]);
    expect(find.bySemanticsLabel('7 of 15 prayers'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('the count keeps going past 15 with every bead filled', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'counter': 15,
      'last_updated': DateTime.now().toString(),
    });
    await tester.pumpWidget(MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Amen'));
    await tester.pumpAndSettle();

    expect(find.text('16'), findsOneWidget);
    expect(beadsFilled(tester), everyElement(isTrue));
  });

  testWidgets('15th prayer shows completed for today, 14th does not', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'notifications_enabled': false,
      'counter': 13,
      'last_updated': DateTime.now().toString(),
    });
    await tester.pumpWidget(MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Amen'));
    await tester.pumpAndSettle();
    expect(find.text('14'), findsOneWidget);
    expect(find.text('Completed for today'), findsNothing);

    await tester.tap(find.text('Amen'));
    await tester.pumpAndSettle();
    expect(find.text('15'), findsOneWidget);
    expect(find.text('Completed for today'), findsOneWidget);
  });

  testWidgets('follows the system dark theme', (WidgetTester tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await tester.pumpWidget(MyApp());
    await tester.pumpAndSettle();

    expect(
      Theme.of(tester.element(find.text('Amen'))).brightness,
      Brightness.dark,
    );
    await tester.tap(find.text('Amen'));
    await tester.pumpAndSettle();
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('lays out without overflow at 200% text size', (
    WidgetTester tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    SharedPreferences.setMockInitialValues({
      'counter': 15,
      'last_updated': DateTime.now().toString(),
    });
    await tester.pumpWidget(MyApp());
    await tester.pumpAndSettle();

    // a RenderFlex overflow would fail the test with an exception
    expect(tester.takeException(), isNull);
    expect(find.text('15'), findsOneWidget);
    expect(find.text('Completed for today'), findsOneWidget);
  });
}

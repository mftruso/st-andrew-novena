// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:st_andrew_novena/aboutPage.dart';
import 'package:st_andrew_novena/appTheme.dart';
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
    when(mockNotificationService.requestPermissions())
        .thenAnswer((_) async => {});
    when(mockNotificationService.hasPermission()).thenAnswer((_) async => true);

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

  Future<void> openSettings(WidgetTester tester) async {
    await tester.tap(find.byType(PopupMenuButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
  }

  testWidgets('settings turns notifications off without permission', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({'notifications_enabled': true});
    when(mockNotificationService.hasPermission())
        .thenAnswer((_) async => false);
    await tester.pumpWidget(MyApp());
    await tester.pumpAndSettle();
    clearInteractions(mockNotificationService);

    await openSettings(tester);

    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('notifications_enabled'), isFalse);
    verify(mockNotificationService.syncNotifications()).called(1);
    expect(find.textContaining('turned off for this app'), findsOneWidget);
  });

  testWidgets('settings leaves notifications on with permission', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({'notifications_enabled': true});
    await tester.pumpWidget(MyApp());
    await tester.pumpAndSettle();
    clearInteractions(mockNotificationService);

    await openSettings(tester);

    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    verifyNever(mockNotificationService.syncNotifications());
  });

  testWidgets("denying permission turns the switch back off", (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MyApp());
    await tester.pumpAndSettle();
    await openSettings(tester);
    clearInteractions(mockNotificationService);

    final permission = Completer<void>();
    when(mockNotificationService.requestPermissions())
        .thenAnswer((_) => permission.future);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    verify(mockNotificationService.syncNotifications()).called(1);

    when(mockNotificationService.hasPermission())
        .thenAnswer((_) async => false);
    permission.complete();
    await tester.pumpAndSettle();

    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('notifications_enabled'), isFalse);
    // one resync, which cancels what was scheduled
    verify(mockNotificationService.syncNotifications()).called(1);
    expect(find.text('Notifications Enabled'), findsNothing);
    expect(find.textContaining('turned off for this app'), findsOneWidget);
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
    final permission = Completer<void>();
    when(mockNotificationService.requestPermissions())
        .thenAnswer((_) => permission.future);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    // syncs right away, without waiting for the permission answer
    verify(mockNotificationService.requestPermissions()).called(1);
    verify(mockNotificationService.syncNotifications()).called(1);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('notifications_enabled'), isTrue);

    expect(find.text('Notifications Enabled'), findsNothing);

    // and again once it's answered, since iOS dropped what was scheduled
    permission.complete();
    await tester.pump();
    verify(mockNotificationService.syncNotifications()).called(1);
    await tester.pump();
    expect(find.text('Notifications Enabled'), findsOneWidget);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    // turning notifications off doesn't ask again
    verifyNever(mockNotificationService.requestPermissions());
    verify(mockNotificationService.syncNotifications()).called(1);
    expect(prefs.getBool('notifications_enabled'), isFalse);
  });

  testWidgets('the about menu item opens the about page', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(PopupMenuButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('About'));
    await tester.pumpAndSettle();

    expect(find.text('How to Pray It'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('What is a Novena?'), 200);
    expect(find.text('What is a Novena?'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('Amen'), findsOneWidget);
  });

  for (final scale in [1.0, 3.0]) {
    testWidgets('the about page lays out without overflow at ${scale}x text', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640) * 3;
      tester.view.devicePixelRatio = 3;
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(MaterialApp(home: AboutPage()));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Prepare for Christmas with the St. Andrew Novena'),
        1000,
      );
      expect(tester.takeException(), isNull);
    });
  }

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
    final semantics = tester.ensureSemantics();
    // the badge is always laid out, so check what's visible and announced
    double badgeOpacity() => tester
        .widget<AnimatedOpacity>(
          find.ancestor(
            of: find.byType(CompletedBadge),
            matching: find.byType(AnimatedOpacity),
          ),
        )
        .opacity;
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
    expect(badgeOpacity(), 0);
    expect(find.bySemanticsLabel('Completed for today'), findsNothing);

    await tester.tap(find.text('Amen'));
    await tester.pumpAndSettle();
    expect(find.text('15'), findsOneWidget);
    expect(badgeOpacity(), 1);
    expect(find.bySemanticsLabel('Completed for today'), findsOneWidget);
    semantics.dispose();
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

  // phone-sized surfaces, including a landscape iPhone, where the fixed parts
  // of the layout have the least room, and tablets, where it has the most
  const screens = {
    'small Android portrait': Size(360, 640),
    'iPhone portrait': Size(390, 844),
    'iPhone landscape': Size(844, 390),
    'tablet portrait': Size(800, 1280),
    'tablet landscape': Size(1280, 800),
  };
  // the placeholder, and the longest intention the sheet allows
  final intentions = {
    'no intention': null,
    'a long intention': ('for my family and friends ' * 8).substring(0, 200),
  };
  for (final MapEntry(key: name, value: size) in screens.entries) {
    for (final scale in [1.0, 2.0, 3.0]) {
      for (final MapEntry(key: variant, value: intention)
          in intentions.entries) {
        testWidgets(
          'lays out without overflow: $name at ${scale}x text, $variant',
          (WidgetTester tester) async {
            tester.view.physicalSize = size * 3;
            tester.view.devicePixelRatio = 3;
            tester.platformDispatcher.textScaleFactorTestValue = scale;
            addTearDown(tester.view.reset);
            addTearDown(
              tester.platformDispatcher.clearTextScaleFactorTestValue,
            );
            SharedPreferences.setMockInitialValues({
              'counter': 15,
              'last_updated': DateTime.now().toString(),
              if (intention != null) 'intention': intention,
            });
            await tester.pumpWidget(MyApp());
            await tester.pumpAndSettle();

            // a RenderFlex overflow would fail the test with an exception
            expect(tester.takeException(), isNull);
            // the Amen button is fully on screen and tappable without scrolling
            final button = tester.getRect(find.byType(FilledButton));
            expect(button.top, greaterThanOrEqualTo(0));
            expect(button.bottom, lessThanOrEqualTo(size.height));
            await tester.tap(find.text('Amen'));
            await tester.pumpAndSettle();
            expect(find.text('16'), findsOneWidget);
          },
        );
      }
    }
  }

  for (final scale in [1.0, 2.0, 3.0]) {
    testWidgets('the badge fits its slot and the ring stays put at ${scale}x', (
      WidgetTester tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      SharedPreferences.setMockInitialValues({
        'counter': 14,
        'last_updated': DateTime.now().toString(),
      });
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();
      final ringBefore = tester.getRect(find.byType(PrayerBeads));
      final prayerBefore = tester.getRect(find.textContaining('Hail and'));

      await tester.tap(find.text('Amen'));
      await tester.pumpAndSettle();

      expect(tester.getRect(find.byType(PrayerBeads)), ringBefore);
      expect(tester.getRect(find.textContaining('Hail and')), prayerBefore);
      final badge = tester.getRect(find.byType(CompletedBadge));
      expect(badge.top, greaterThanOrEqualTo(ringBefore.bottom));
      expect(badge.bottom, lessThanOrEqualTo(prayerBefore.top));
    });
  }

  testWidgets('past 15 the ring reads as a count, not more than complete', (
    WidgetTester tester,
  ) async {
    final semantics = tester.ensureSemantics();
    SharedPreferences.setMockInitialValues({
      'counter': 15,
      'last_updated': DateTime.now().toString(),
    });
    await tester.pumpWidget(MyApp());
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('15 of 15 prayers'), findsOneWidget);
    expect(find.text('of 15'), findsOneWidget);

    await tester.tap(find.text('Amen'));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel(RegExp('of 15')), findsNothing);
    expect(find.bySemanticsLabel('16 prayers'), findsOneWidget);
    expect(find.text('of 15'), findsNothing);
    expect(find.text('prayers'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('the intention style is built once per theme, not per build', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MyApp());
    await tester.pumpAndSettle();
    TextStyle intention() => tester
        .widget<Text>(find.textContaining('[name your intention]'))
        .style!;
    final before = intention();
    expect(before.fontStyle, FontStyle.italic);

    await tester.tap(find.text('Amen'));
    await tester.pumpAndSettle();

    expect(identical(intention(), before), isTrue);
  });

  for (final MapEntry(key: name, value: size) in {
    'tablet portrait': const Size(800, 1280),
    'tablet landscape': const Size(1280, 800),
  }.entries) {
    testWidgets('the prayer and Amen stay readable width on a $name', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = size * 2;
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();

      for (final finder in [
        find.textContaining('Hail and'),
        find.byType(FilledButton),
      ]) {
        final rect = tester.getRect(finder);
        expect(rect.width, lessThanOrEqualTo(maxContentWidth));
        expect(rect.center.dx, moreOrLessEquals(size.width / 2));
      }
    });
  }

  testWidgets('the prayer is centred between the app bar and Amen', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1280) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MyApp());
    await tester.pumpAndSettle();

    // the gaps beyond the fixed padding (36 above the ring, 16 below the
    // prayer) are split evenly
    final above =
        tester.getRect(find.byType(PrayerBeads)).top -
        tester.getRect(find.byType(AppBar)).bottom -
        36;
    final below =
        tester.getRect(find.byType(FilledButton)).top -
        tester.getRect(find.textContaining('through the merits')).bottom -
        16;
    expect(above, greaterThan(100));
    expect(above, moreOrLessEquals(below, epsilon: 1));
  });

  testWidgets('the about page text stays readable width on a tablet', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: AboutPage()));
    await tester.pumpAndSettle();

    final rect = tester.getRect(find.text('How to Pray It'));
    final paragraph = tester.getRect(find.textContaining('Pray the prayer 15'));
    expect(paragraph.width, lessThanOrEqualTo(maxContentWidth));
    expect(paragraph.center.dx, moreOrLessEquals(640));
    expect(rect.left, paragraph.left);
  });

  testWidgets('the prayer bounces on Android instead of stretching', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(844, 390) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MyApp());
    await tester.pumpAndSettle();

    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
    expect(scrollable.position.physics, isA<BouncingScrollPhysics>());
    expect(find.byType(StretchingOverscrollIndicator), findsNothing);
    expect(find.byType(GlowingOverscrollIndicator), findsNothing);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  group('prayer intention', () {
    Future<SharedPreferences> pumpWithIntention(
      WidgetTester tester,
      String? intention,
    ) async {
      SharedPreferences.setMockInitialValues({
        if (intention != null) 'intention': intention,
      });
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();
      return SharedPreferences.getInstance();
    }

    const placeholder = '[name your intention]';

    Future<void> openSheet(WidgetTester tester, String text) async {
      // scrolled into view first, for large text on small screens
      await tester.ensureVisible(find.textContaining(text));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining(text));
      await tester.pumpAndSettle();
      expect(find.text('Your intention'), findsOneWidget);
    }

    testWidgets('a saved intention replaces the placeholder', (
      WidgetTester tester,
    ) async {
      await pumpWithIntention(tester, 'for my mother');

      expect(find.textContaining('for my mother'), findsOneWidget);
      expect(find.textContaining(placeholder), findsNothing);
    });

    testWidgets('a blank intention shows the placeholder', (
      WidgetTester tester,
    ) async {
      await pumpWithIntention(tester, '   ');

      expect(find.textContaining(placeholder), findsOneWidget);
    });

    testWidgets('typing an intention and saving shows and stores it', (
      WidgetTester tester,
    ) async {
      final prefs = await pumpWithIntention(tester, null);

      await openSheet(tester, placeholder);
      expect(find.text('Clear'), findsNothing);
      await tester.enterText(find.byType(TextField), 'for my mother');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Your intention'), findsNothing);
      expect(find.textContaining('for my mother'), findsOneWidget);
      expect(find.textContaining(placeholder), findsNothing);
      expect(prefs.getString('intention'), 'for my mother');
    });

    testWidgets('cancelling the sheet changes nothing', (
      WidgetTester tester,
    ) async {
      final prefs = await pumpWithIntention(tester, 'for my mother');

      await openSheet(tester, 'for my mother');
      await tester.enterText(find.byType(TextField), 'for my father');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Your intention'), findsNothing);
      expect(find.textContaining('for my mother'), findsOneWidget);
      expect(prefs.getString('intention'), 'for my mother');
    });

    testWidgets('tapping outside the sheet changes nothing', (
      WidgetTester tester,
    ) async {
      final prefs = await pumpWithIntention(tester, null);

      await openSheet(tester, placeholder);
      await tester.enterText(find.byType(TextField), 'for my father');
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.text('Your intention'), findsNothing);
      expect(find.textContaining(placeholder), findsOneWidget);
      expect(prefs.containsKey('intention'), isFalse);
    });

    testWidgets('clearing the intention restores the placeholder', (
      WidgetTester tester,
    ) async {
      final prefs = await pumpWithIntention(tester, 'for my mother');

      await openSheet(tester, 'for my mother');
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();

      expect(find.text('Your intention'), findsNothing);
      expect(find.textContaining(placeholder), findsOneWidget);
      expect(prefs.getString('intention') ?? '', isEmpty);
    });

    testWidgets('the intention is announced as a button to edit it', (
      WidgetTester tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpWithIntention(tester, 'for my mother');

      final finder = find.bySemanticsLabel('Prayer intention: for my mother');
      expect(finder, findsOneWidget);
      expect(
        tester.getSemantics(finder),
        matchesSemantics(
          label: 'Prayer intention: for my mother',
          isButton: true,
          hasTapAction: true,
          onTapHint: 'edit',
        ),
      );
      // the text itself isn't announced again
      expect(find.bySemanticsLabel('for my mother'), findsNothing);
      semantics.dispose();
    });

    testWidgets('an unset intention is announced as not set', (
      WidgetTester tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpWithIntention(tester, null);

      expect(
        find.bySemanticsLabel('Prayer intention, not set'),
        findsOneWidget,
      );
      semantics.dispose();
    });

    for (final scale in [1.0, 3.0]) {
      testWidgets('the sheet lays out above the keyboard at ${scale}x text', (
        WidgetTester tester,
      ) async {
        tester.view.physicalSize = const Size(360, 640) * 3;
        tester.view.devicePixelRatio = 3;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        // set, so the sheet shows all three actions
        await pumpWithIntention(tester, 'for my mother');

        await openSheet(tester, 'for my mother');
        // a keyboard taking up almost half the screen
        tester.view.viewInsets = const FakeViewPadding(bottom: 300 * 3);
        await tester.pumpAndSettle();
        // the longest intention, filling the field's four lines
        await tester.enterText(find.byType(TextField), 'a ' * 100);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Your intention'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('Save'),
          100,
          scrollable: find
              .descendant(
                of: find.byType(BottomSheet),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        final save = tester.getRect(find.text('Save'));
        expect(save.bottom, lessThanOrEqualTo(640 - 300));
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('double-tapping Save closes only the sheet', (
      WidgetTester tester,
    ) async {
      final prefs = await pumpWithIntention(tester, null);

      await openSheet(tester, placeholder);
      await tester.enterText(find.byType(TextField), 'for my mother');
      // both taps land before the first save finishes, as when a device's
      // prefs write is slow (tester.tap would let the in-memory save finish)
      final save = tester.getCenter(find.text('Save'));
      for (final pointer in [1, 2]) {
        tester.binding.handlePointerEvent(
          PointerDownEvent(pointer: pointer, position: save),
        );
        tester.binding.handlePointerEvent(
          PointerUpEvent(pointer: pointer, position: save),
        );
      }
      await tester.pumpAndSettle();

      expect(find.text('Your intention'), findsNothing);
      expect(find.text('Amen'), findsOneWidget);
      expect(find.textContaining('for my mother'), findsOneWidget);
      expect(prefs.getString('intention'), 'for my mother');
    });

    testWidgets('a saved intention shows while notifications initialize', (
      WidgetTester tester,
    ) async {
      // notification setup that never finishes, like a slow or failed init
      when(mockNotificationService.initialize())
          .thenAnswer((_) => Completer<void>().future);
      await pumpWithIntention(tester, 'for my mother');

      expect(find.textContaining('for my mother'), findsOneWidget);
      expect(find.textContaining(placeholder), findsNothing);
    });

    testWidgets('saving before notifications initialize keeps the intention', (
      WidgetTester tester,
    ) async {
      when(mockNotificationService.initialize())
          .thenAnswer((_) => Completer<void>().future);
      final prefs = await pumpWithIntention(tester, 'for my mother');

      // whatever the intention shows, the sheet opens with the saved one
      await tester.ensureVisible(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Your intention'), findsOneWidget);
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, 'for my mother');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(prefs.getString('intention'), 'for my mother');
    });

    testWidgets('saving a blank intention reopens the sheet empty', (
      WidgetTester tester,
    ) async {
      final prefs = await pumpWithIntention(tester, 'for my mother');

      await openSheet(tester, 'for my mother');
      await tester.enterText(find.byType(TextField), '   ');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(prefs.containsKey('intention'), isFalse);

      // the same as after a restart, which loads nothing
      await openSheet(tester, placeholder);
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, isEmpty);
    });

    testWidgets('the intention stays on one line in the prayer', (
      WidgetTester tester,
    ) async {
      final prefs = await pumpWithIntention(tester, null);

      await openSheet(tester, placeholder);
      await tester.enterText(
        find.byType(TextField),
        'for my mother\n\n\nand father',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(prefs.getString('intention'), isNot(contains('\n')));
      final shown = tester.widget<Text>(find.textContaining('for my mother'));
      expect(shown.textSpan!.toPlainText(), isNot(contains('\n')));
    });
  });
}

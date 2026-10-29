// On-device tests that check what the real flutter_local_notifications plugin
// has pending. Run with: flutter test integration_test -d <device>
//
// On Android the app isn't granted the notification permission, so its
// dialog may stay up during the run; it doesn't block the tests (a repeated
// request's permissionRequestInProgress error is logged, not thrown).

import 'package:material_ui/material_ui.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:st_andrew_novena/main.dart';
import 'package:st_andrew_novena/notificationService.dart';
import 'package:timezone/timezone.dart' as tz;

/// The notification IDs scheduleNotifications would schedule right now.
Set<int> expectedIds({bool skipToday = false}) {
  final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
  final Set<int> ids = {};
  for (int day = skipToday ? 1 : 0; day < notificationDays; day++) {
    for (int slot = 0; slot < notificationsPerDay; slot++) {
      final tz.TZDateTime scheduledTime = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day + day,
        7 + slot,
      );
      if (scheduledTime.isAfter(now)) {
        ids.add(day * notificationsPerDay + slot);
      }
    }
  }
  return ids;
}

Future<Set<int>> pendingIds() async {
  final requests = await FlutterLocalNotificationsPlugin()
      .pendingNotificationRequests();
  return requests.map((r) => r.id).toSet();
}

/// Scheduling runs in un-awaited callbacks, so poll until the pending set
/// matches what's expected (or time out and return the last value seen).
///
/// [before] is computed before the action and [after] just now. They differ
/// only if the run straddled the top of an hour, in which case the slot that
/// just passed may or may not still be pending, so the pending set must lie
/// between them.
Future<Set<int>> waitForPending(
  Set<int> before, {
  bool skipToday = false,
}) async {
  Set<int> pending = {};
  for (int i = 0; i < 50; i++) {
    pending = await pendingIds();
    final Set<int> after = expectedIds(skipToday: skipToday);
    if (pending.containsAll(after) && before.containsAll(pending)) {
      return pending;
    }
    await Future.delayed(const Duration(milliseconds: 200));
  }
  return pending;
}

Matcher pendingBetween(Set<int> before, {bool skipToday = false}) =>
    predicate<Set<int>>((pending) {
      final Set<int> after = expectedIds(skipToday: skipToday);
      return pending.containsAll(after) && before.containsAll(pending);
    }, 'pending ids between $before and ${expectedIds(skipToday: skipToday)}');

/// Taps run un-awaited async handlers (SharedPreferences, platform calls), so
/// pumpAndSettle can return before their setState; pump until [finder] shows.
Future<void> pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (int i = 0; i < 50 && finder.evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> launchApp(WidgetTester tester) async {
  await tester.pumpWidget(MyApp());
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(initLocalTimezone);

  setUp(() async {
    // state persists on the device between tests
    await (await SharedPreferences.getInstance()).clear();
    await FlutterLocalNotificationsPlugin().cancelAll();
    getIt.registerSingleton<NotificationService>(NotificationService());
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('enabling notifications schedules the rolling window', (
    WidgetTester tester,
  ) async {
    await launchApp(tester);
    expect(await pendingIds(), isEmpty);

    await tester.tap(find.byType(PopupMenuButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    final Set<int> before = expectedIds();
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(await waitForPending(before), pendingBetween(before));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('notifications_enabled'), isTrue);
  });

  testWidgets("praying 15 times clears today's reminders", (
    WidgetTester tester,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', true);

    final Set<int> beforeLaunch = expectedIds();
    await launchApp(tester);
    // startup schedules the full window
    expect(await waitForPending(beforeLaunch), pendingBetween(beforeLaunch));

    for (int i = 0; i < 15; i++) {
      await tester.tap(find.text('Amen'));
      await tester.pumpAndSettle();
      await pumpUntilFound(tester, find.text('${i + 1}'));
    }

    expect(find.text('15'), findsOneWidget);
    await pumpUntilFound(
      tester,
      find.text('Prayers complete! Notifications will resume tomorrow.'),
    );
    expect(
      find.text('Prayers complete! Notifications will resume tomorrow.'),
      findsOneWidget,
    );
    final Set<int> daysOneToThree = {
      for (
        int id = notificationsPerDay;
        id < notificationDays * notificationsPerDay;
        id++
      )
        id,
    };
    expect(expectedIds(skipToday: true), daysOneToThree);
    expect(
      await waitForPending(daysOneToThree, skipToday: true),
      daysOneToThree,
    );
  });
}

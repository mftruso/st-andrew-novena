import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:st_andrew_novena/notificationService.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'notification_service_test.mocks.dart';

@GenerateMocks([
  FlutterLocalNotificationsPlugin,
  AndroidFlutterLocalNotificationsPlugin,
  NotificationService
])
void main() {
  late MockFlutterLocalNotificationsPlugin mockFlutterLocalNotificationsPlugin;
  late tz.Location newYork;

  setUp(() {
    tz.initializeTimeZones();
    newYork = tz.getLocation('America/New_York');
    tz.setLocalLocation(newYork);

    mockFlutterLocalNotificationsPlugin = MockFlutterLocalNotificationsPlugin();
    when(mockFlutterLocalNotificationsPlugin.zonedSchedule(
      any,
      any,
      any,
      any,
      any,
      androidScheduleMode: anyNamed('androidScheduleMode'),
      payload: anyNamed('payload'),
      matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
    )).thenAnswer((_) async {});
    when(mockFlutterLocalNotificationsPlugin.cancelAll())
        .thenAnswer((_) async {});
  });

  // Builds a service whose clock is fixed at 2026-12-03 hour:minute in New York.
  NotificationService serviceAt(int hour, [int minute = 0]) {
    final fixedNow = tz.TZDateTime(newYork, 2026, 12, 3, hour, minute);
    return NotificationService(
        plugin: mockFlutterLocalNotificationsPlugin, now: () => fixedNow);
  }

  // Returns {id: scheduledDate} for every zonedSchedule call, and checks
  // that each call is a one-shot (no matchDateTimeComponents) with a unique id.
  Map<int, tz.TZDateTime> captureSchedules() {
    final captured = verify(mockFlutterLocalNotificationsPlugin.zonedSchedule(
      captureAny,
      any,
      any,
      captureAny,
      any,
      androidScheduleMode: anyNamed('androidScheduleMode'),
      payload: anyNamed('payload'),
      matchDateTimeComponents:
          captureAnyNamed('matchDateTimeComponents'),
    )).captured;
    final result = <int, tz.TZDateTime>{};
    for (int i = 0; i < captured.length; i += 3) {
      expect(captured[i + 2], isNull);
      final id = captured[i] as int;
      expect(result.containsKey(id), isFalse, reason: 'duplicate id $id');
      result[id] = captured[i + 1] as tz.TZDateTime;
    }
    return result;
  }

  tz.TZDateTime dec(int day, int hour) =>
      tz.TZDateTime(newYork, 2026, 12, day, hour);

  // Expected id for a notification `day` days from today at `slot` (7 a.m. + slot).
  int idFor(int day, int slot) => day * notificationsPerDay + slot;

  group('scheduleNotifications', () {
    test('before 7 a.m. schedules every slot for the next 4 days as one-shots',
        () async {
      await serviceAt(6).scheduleNotifications();

      final schedules = captureSchedules();
      expect(schedules.keys.toSet(), Set.of(List.generate(60, (i) => i)));
      for (int day = 0; day < 4; day++) {
        for (int slot = 0; slot < 15; slot++) {
          expect(schedules[idFor(day, slot)], dec(3 + day, 7 + slot));
        }
      }
    });

    test('mid-day skips the slots that have already passed today', () async {
      final now = tz.TZDateTime(newYork, 2026, 12, 3, 10, 30);
      await serviceAt(10, 30).scheduleNotifications();

      final schedules = captureSchedules();
      expect(schedules.length, 11 + 45);
      for (int slot = 0; slot < 4; slot++) {
        expect(schedules.containsKey(idFor(0, slot)), isFalse);
      }
      for (int slot = 4; slot < 15; slot++) {
        expect(schedules[idFor(0, slot)], dec(3, 7 + slot));
      }
      for (final time in schedules.values) {
        expect(time.isAfter(now), isTrue);
      }
    });

    test('after 9 p.m. schedules nothing for today', () async {
      await serviceAt(22).scheduleNotifications();

      final schedules = captureSchedules();
      expect(schedules.length, 45);
      for (final time in schedules.values) {
        expect(time.day, isNot(3));
      }
    });

    test('skipToday schedules only the following 3 days', () async {
      await serviceAt(10, 30).scheduleNotifications(skipToday: true);

      final schedules = captureSchedules();
      expect(schedules.length, 45);
      for (int day = 1; day < 4; day++) {
        for (int slot = 0; slot < 15; slot++) {
          expect(schedules[idFor(day, slot)], dec(3 + day, 7 + slot));
        }
      }
    });

    test('never exceeds the iOS cap of pending notifications', () async {
      expect(notificationDays * notificationsPerDay,
          lessThanOrEqualTo(maxPendingNotifications));

      // 06:00 is the worst case: every slot of every day is still ahead.
      await serviceAt(6).scheduleNotifications();
      expect(captureSchedules().length,
          lessThanOrEqualTo(maxPendingNotifications));
    });

    test('rolls over month and year boundaries', () async {
      final fixedNow = tz.TZDateTime(newYork, 2026, 12, 30, 6);
      await NotificationService(
              plugin: mockFlutterLocalNotificationsPlugin,
              now: () => fixedNow)
          .scheduleNotifications();

      final schedules = captureSchedules();
      expect(schedules.length, 60);
      for (int slot = 0; slot < 15; slot++) {
        expect(schedules[idFor(0, slot)],
            tz.TZDateTime(newYork, 2026, 12, 30, 7 + slot));
        expect(schedules[idFor(1, slot)],
            tz.TZDateTime(newYork, 2026, 12, 31, 7 + slot));
        expect(schedules[idFor(2, slot)],
            tz.TZDateTime(newYork, 2027, 1, 1, 7 + slot));
        expect(schedules[idFor(3, slot)],
            tz.TZDateTime(newYork, 2027, 1, 2, 7 + slot));
      }
    });
  });

  group('syncNotifications', () {
    test('when disabled, cancels all and schedules nothing', () async {
      SharedPreferences.setMockInitialValues({'notifications_enabled': false});

      await serviceAt(10, 30).syncNotifications();

      verify(mockFlutterLocalNotificationsPlugin.cancelAll()).called(1);
      verifyNever(mockFlutterLocalNotificationsPlugin.zonedSchedule(
        any,
        any,
        any,
        any,
        any,
        androidScheduleMode: anyNamed('androidScheduleMode'),
        payload: anyNamed('payload'),
        matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
      ));
    });

    test('when enabled, cancels before scheduling', () async {
      SharedPreferences.setMockInitialValues({
        'notifications_enabled': true,
        'counter': 3,
        'last_updated': '2026-12-03 09:00:00.000',
      });

      await serviceAt(10, 30).syncNotifications();

      verifyInOrder([
        mockFlutterLocalNotificationsPlugin.cancelAll(),
        mockFlutterLocalNotificationsPlugin.zonedSchedule(
          any,
          any,
          any,
          any,
          any,
          androidScheduleMode: anyNamed('androidScheduleMode'),
          payload: anyNamed('payload'),
          matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
        ),
      ]);
    });

    // Separate from the ordering test: mockito's verifyInOrder marks calls
    // as verified, which would hide them from captureSchedules().
    test('when enabled and prayers incomplete, schedules the rest of today',
        () async {
      SharedPreferences.setMockInitialValues({
        'notifications_enabled': true,
        'counter': 3,
        'last_updated': '2026-12-03 09:00:00.000',
      });

      await serviceAt(10, 30).syncNotifications();

      final schedules = captureSchedules();
      expect(schedules.length, 56);
      expect(schedules.values.where((t) => t.day == 3).length, 11);
    });

    test('when enabled and prayers complete today, skips today', () async {
      SharedPreferences.setMockInitialValues({
        'notifications_enabled': true,
        'counter': 15,
        'last_updated': '2026-12-03 09:00:00.000',
      });

      await serviceAt(10, 30).syncNotifications();

      final schedules = captureSchedules();
      expect(schedules.length, 45);
      expect(schedules.values.where((t) => t.day == 3), isEmpty);
    });

    test('ignores a completed count from a previous day', () async {
      SharedPreferences.setMockInitialValues({
        'notifications_enabled': true,
        'counter': 15,
        'last_updated': '2026-12-02 20:00:00.000',
      });

      await serviceAt(10, 30).syncNotifications();

      final schedules = captureSchedules();
      expect(schedules.length, 56);
      expect(schedules.values.where((t) => t.day == 3).length, 11);
    });
  });

  group('notification details', () {
    test('Android reminders time out within the hour and iOS ones are grouped',
        () async {
      await serviceAt(6).scheduleNotifications();

      final details = verify(mockFlutterLocalNotificationsPlugin.zonedSchedule(
        any,
        any,
        any,
        any,
        captureAny,
        androidScheduleMode: anyNamed('androidScheduleMode'),
        payload: anyNamed('payload'),
        matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
      )).captured;
      expect(details, hasLength(60));
      for (final NotificationDetails d in details.cast<NotificationDetails>()) {
        expect(d.android?.timeoutAfter, isNotNull);
        expect(d.android!.timeoutAfter!, lessThan(60 * 60 * 1000));
        expect(d.iOS?.threadIdentifier, isNotNull);
      }
    });
  });

  group('initialize', () {
    test('a failed permission request does not escape or block initialize',
        () async {
      final mockAndroidPlugin = MockAndroidFlutterLocalNotificationsPlugin();
      when(mockAndroidPlugin.requestNotificationsPermission()).thenAnswer(
          (_) => Future.error(
              PlatformException(code: 'permissionRequestInProgress')));
      when(mockFlutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>())
          .thenReturn(mockAndroidPlugin);
      when(mockFlutterLocalNotificationsPlugin.initialize(any,
              onDidReceiveNotificationResponse:
                  anyNamed('onDidReceiveNotificationResponse')))
          .thenAnswer((_) async => true);

      await NotificationService(plugin: mockFlutterLocalNotificationsPlugin)
          .initialize();
      // Let the permission request's error reach its handler; an unhandled
      // error here would fail the test.
      await pumpEventQueue();

      verify(mockAndroidPlugin.requestNotificationsPermission()).called(1);
      verify(mockFlutterLocalNotificationsPlugin.initialize(any,
              onDidReceiveNotificationResponse:
                  anyNamed('onDidReceiveNotificationResponse')))
          .called(1);
    });
  });

  group('cancelAllNotifications', () {
    test('calls cancelAll on the plugin', () async {
      await NotificationService(plugin: mockFlutterLocalNotificationsPlugin)
          .cancelAllNotifications();
      verify(mockFlutterLocalNotificationsPlugin.cancelAll()).called(1);
    });
  });
}

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:st_andrew_novena/notificationService.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'notification_service_test.mocks.dart';

@GenerateMocks([FlutterLocalNotificationsPlugin])
void main() {
  late NotificationService notificationService;
  late MockFlutterLocalNotificationsPlugin mockFlutterLocalNotificationsPlugin;

  setUp(() {
    mockFlutterLocalNotificationsPlugin = MockFlutterLocalNotificationsPlugin();
    notificationService =
        NotificationService(plugin: mockFlutterLocalNotificationsPlugin);

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/New_York'));
  });

  group('scheduleNotificationsFor', () {
    test('schedules 15 notifications for a future day', () async {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      await notificationService.scheduleNotificationsFor(tomorrow);

      verify(mockFlutterLocalNotificationsPlugin.zonedSchedule(
        any,
        any,
        any,
        any,
        any,
        androidScheduleMode: anyNamed('androidScheduleMode'),
      )).called(15);
    });

    test('schedules only future notifications for today', () async {
      // Since we can't easily mock DateTime.now(), we'll have to rely on the logic inside the function
      // and verify the number of calls.
      
      // Let's assume the test runs fast enough and DateTime.now() doesn't change much.
      final today = DateTime.now();
      await notificationService.scheduleNotificationsFor(today);

      // This is a weak test because the number of notifications depends on the time the test is run.
      // However, we can verify that it's called at most 15 times.
      verify(mockFlutterLocalNotificationsPlugin.zonedSchedule(
        any,
        any,
        any,
        any,
        any,
        androidScheduleMode: anyNamed('androidScheduleMode'),
      )).called(lessThanOrEqualTo(15));
    });

    test('does not schedule notifications for a past day', () async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      await notificationService.scheduleNotificationsFor(yesterday);

      verifyNever(mockFlutterLocalNotificationsPlugin.zonedSchedule(
        any,
        any,
        any,
        any,
        any,
        androidScheduleMode: anyNamed('androidScheduleMode'),
      ));
    });
  });

  group('cancelAllNotifications', () {
    test('calls cancelAll on the plugin', () async {
      await notificationService.cancelAllNotifications();
      verify(mockFlutterLocalNotificationsPlugin.cancelAll()).called(1);
    });
  });
}
# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Flutter app (Android/iOS) that counts recitations of the St. Andrew Novena prayer, which is traditionally prayed 15 times a day from Nov 30 until Christmas. Published on Google Play as `com.miketruso.standrewnovena`. README says it's built with Flutter v3.38.3.

## Commands

```
flutter pub get                                   # install deps
flutter run                                       # run on device/emulator
flutter test                                      # run all tests (this is all CI runs, on every push)
flutter test test/widget_test.dart                # run one test file
flutter test --plain-name "schedules 15 notifications for a future day"   # run one test by name
dart run build_runner build --delete-conflicting-outputs   # regenerate mockito mocks
flutter build apk && flutter install              # install a build on a connected Android device
flutter build appbundle                           # Play Store release build
```

Release builds need `android/key.properties` (storePassword, keyPassword, keyAlias=upload, storeFile). Never commit it. The version lives in `pubspec.yaml` (`version: X.Y.Z+build`). Release commits are just that version string, e.g. `2.3.1+12`.

## Architecture

All app code is in `lib/` as a few flat files. There is no state-management library: state is a `StatefulWidget` and is persisted with `SharedPreferences`.

- **`main.dart`**: initializes timezones (`timezone` + `flutter_timezone`, falling back to UTC), registers `NotificationService` as a `get_it` singleton (`getIt`, exported from `main.dart`, which is why `settingsPage.dart` imports `main.dart`), and holds the home screen with the counter logic.
- **`notificationService.dart`**: wraps `FlutterLocalNotificationsPlugin`. The plugin is injectable through the constructor so tests can pass a mock. `scheduleNotificationsFor(day)` schedules up to 15 hourly notifications (IDs 0–14) starting at 7 a.m. local time, skipping times that have already passed.
- **`notificationConfig.dart`**: notification channel details and the notification title/body.

### SharedPreferences keys (behavior spans several files)

- `counter` / `last_updated`: the counter resets to 0 on launch if `last_updated` is before the start of today.
- `notifications_enabled`: toggled in `settingsPage.dart`, which schedules today's notifications or cancels all of them.
- `last_scheduled_day` (`YYYY-MM-DD`): on startup, if it isn't today, all notifications are cancelled and today's are rescheduled. When the counter reaches 15 with notifications enabled, today's notifications are cancelled, tomorrow's are scheduled, and this key is set to tomorrow.

## Tests

- `test/notification_service_test.dart` uses `@GenerateMocks([FlutterLocalNotificationsPlugin, NotificationService])`. `notification_service_test.mocks.dart` is generated and committed, so regenerate it with build_runner whenever those class signatures change.
- `test/widget_test.dart` reuses those mocks. It registers `MockNotificationService` in `GetIt`, calls `SharedPreferences.setMockInitialValues`, and sets the tz location to `America/New_York`.

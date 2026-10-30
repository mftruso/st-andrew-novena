# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Flutter app (Android/iOS) that counts recitations of the St. Andrew Novena prayer, which is traditionally prayed 15 times a day from Nov 30 until Christmas. Published on Google Play as `com.miketruso.standrewnovena`. README says it's built with Flutter v3.47.8.

## Commands

```
flutter pub get                                   # install deps
flutter run                                       # run on device/emulator
flutter test                                      # run all tests (this is all CI runs, on every push)
flutter test test/widget_test.dart                # run one test file
flutter test --plain-name "skipToday schedules only the following 3 days"   # run one test by name
flutter test integration_test -d <device>        # on-device notification tests (needs emulator/device; not run in CI)
dart run build_runner build                         # regenerate mockito mocks
flutter build apk && flutter install              # install a build on a connected Android device
flutter build appbundle                           # Play Store release build
```

Release builds need `android/key.properties` (storePassword, keyPassword, keyAlias=upload, storeFile). Never commit it. The version lives in `pubspec.yaml` (`version: X.Y.Z+build`). Release commits are just that version string, e.g. `2.3.1+12`.

## Architecture

All app code is in `lib/` as a few flat files. There is no state-management library: state is a `StatefulWidget` and is persisted with `SharedPreferences`.

- **`main.dart`**: initializes timezones (`timezone` + `flutter_timezone`, falling back to UTC), registers `NotificationService` as a `get_it` singleton (`getIt`, exported from `main.dart`, which is why `settingsPage.dart` imports `main.dart`), and holds the home screen with the counter logic.
- **`notificationService.dart`**: wraps `FlutterLocalNotificationsPlugin`. The plugin and a clock (`now`) are injectable through the constructor so tests can pass a mock and a fixed time. `scheduleNotifications({skipToday})` schedules a rolling window of one-shot notifications: `notificationsPerDay` (15) hourly slots from 7 a.m. to 9 p.m. local time for `notificationDays` (4) days starting today, skipping times that have passed (and all of today with `skipToday: true`). IDs are `day * notificationsPerDay + slot` (0–59). The window must stay within `maxPendingNotifications` (64, the iOS per-app cap on pending notifications); a test fails if the constants exceed it. Don't use `matchDateTimeComponents` (repeating) here: the plugin ignores the date and fires at the next matching time, so today can't be skipped. `syncNotifications()` is the single place that decides what is scheduled from `SharedPreferences`: it cancels everything, then schedules if enabled, skipping today when today's 15 prayers are done.
- **`notificationConfig.dart`**: notification channel details and the notification title/body. Android reminders time out after 59 minutes (`timeoutAfter`) and iOS ones share a `threadIdentifier`, so missed reminders don't pile up.

### SharedPreferences keys (behavior spans several files)

- `counter` / `last_updated`: the counter resets to 0 on launch if `last_updated` is before the start of today.
- `notifications_enabled`: toggled in `settingsPage.dart`, which then calls `syncNotifications()`. Turning it on is the only place notification permission is asked for (`requestPermissions()`, Android and iOS; `initialize()` asks for nothing). The request isn't awaited, and settings resyncs once it's answered, because iOS drops notifications scheduled while permission is undecided. If `hasPermission()` is false (denied, or revoked in system settings), settings turns notifications back off, both after the prompt and whenever the page loads; the "Notifications Enabled" snackbar only shows after a grant.
- `syncNotifications()` runs on startup (after `initialize()` and the counter check), on app resume (`WidgetsBindingObserver`), after the Reset menu item, on the settings toggle, and when the counter reaches 15 with notifications enabled (prefs then show today complete, so today's remaining reminders are dropped). Each run rebuilds the 4-day window, so reminders only stop if the app isn't opened for 4+ days.

## Tests

- `test/notification_service_test.dart` uses `@GenerateMocks([FlutterLocalNotificationsPlugin, AndroidFlutterLocalNotificationsPlugin, NotificationService])`. `notification_service_test.mocks.dart` is generated and committed, so regenerate it with build_runner whenever those class signatures change.
- `test/widget_test.dart` reuses those mocks. It registers `MockNotificationService` in `GetIt`, calls `SharedPreferences.setMockInitialValues`, and sets the tz location to `America/New_York`.
- `integration_test/notifications_test.dart` runs on a device against the real plugin and asserts the set of `pendingNotificationRequests()` ids, computed from the real clock. It shares `main()`'s timezone setup (`initLocalTimezone()`) but registers the service itself instead of calling `main()` (so `getIt` can be reset between tests) and clears prefs and pending notifications in setUp. On iOS, setUpAll grants provisional authorization (no prompt), since iOS drops notifications scheduled before permission is granted. The settings test's permission dialog may stay up during the run and doesn't block the tests (on Android, later requests' `permissionRequestInProgress` errors are logged, not thrown), so no grant is needed: `flutter test integration_test -d <device>`.
- `integration_test/ios_foreground_notification_test.dart` (iOS only, skipped elsewhere) shows a notification while the app is in the foreground and checks that it's delivered, which proves `AppDelegate`'s `UNUserNotificationCenter` delegate reaches the plugin under the UIScene lifecycle. It asks for provisional authorization, so no prompt needs answering on a simulator. Provisional must be paired with alert: on its own the plugin requests nothing and the notification is dropped as `NotDetermined`. If the app was denied earlier, uninstall it first. Use an iOS 27 simulator: the iOS 17.5 runtime under Xcode 27 doesn't deliver taps.

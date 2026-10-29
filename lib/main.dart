import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:st_andrew_novena/appTheme.dart';
import 'package:st_andrew_novena/notificationService.dart';
import 'package:st_andrew_novena/settingsPage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzData;
import 'package:flutter_timezone/flutter_timezone.dart';

// +JMJ+
// AMDG
// Sanctus Andrea, ora pro nobis!

final getIt = GetIt.instance;

/// Sets tz.local to the device's timezone, falling back to UTC.
Future<void> initLocalTimezone() async {
  tzData.initializeTimeZones();
  try {
    final String timezone =
        (await FlutterTimezone.getLocalTimezone()).identifier;
    debugPrint('Local Timezone: ' + timezone);
    tz.setLocalLocation(tz.getLocation(timezone));
  } on Exception {
    debugPrint('Could not load local timezone, defaults to UTC');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // fonts are bundled in assets/google_fonts (release builds have no INTERNET)
  GoogleFonts.config.allowRuntimeFetching = false;
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('assets/google_fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(['google_fonts'], license);
  });

  await initLocalTimezone();

  // register the singleton service
  getIt.registerSingleton<NotificationService>(NotificationService());

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'St. Andrew Novena',
      theme: lightTheme(),
      home: MyHomePage(title: 'St. Andrew Novena'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, this.title = ''}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

enum Screens { settings }

class ScreenNavigator {
  static Widget getScreenWidget(String screenString) {
    final Screens screen = Screens.values.firstWhere(
      (s) => s.toString().split('.').last == screenString,
      orElse: () => Screens.settings,
    );

    switch (screen) {
      case Screens.settings:
        return SettingsPage();
    }
  }
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  int _counter = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startup();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _onResumed();
    }
  }

  Future<void> _startup() async {
    await getIt<NotificationService>().initialize();
    await _initializeCounter();
    await getIt<NotificationService>().syncNotifications();
  }

  Future<void> _onResumed() async {
    debugPrint('app resumed');
    await _initializeCounter();
    await getIt<NotificationService>().syncNotifications();
  }

  Future<void> _initializeCounter() async {
    debugPrint('initializeCounter');
    final prefs = await SharedPreferences.getInstance();
    int counter = prefs.getInt('counter') ?? 0;

    String? lastUpdatedStr = prefs.getString('last_updated');
    if (lastUpdatedStr != null) {
      DateTime lastUpdated = DateTime.parse(lastUpdatedStr);
      DateTime now = DateTime.now();
      DateTime startOfToday = DateTime(now.year, now.month, now.day);
      if (lastUpdated.isBefore(startOfToday)) {
        await _resetCounter();
      } else {
        setState(() {
          _counter = counter;
        });
      }
    } else {
      setState(() {
        _counter = counter;
      });
    }
  }

  Future<void> _incrementCounter() async {
    final prefs = await SharedPreferences.getInstance();
    int counter = (prefs.getInt('counter') ?? 0) + 1;
    await prefs.setInt('counter', counter);
    setState(() {
      _counter = counter;
    });
    await prefs.setString('last_updated', DateTime.now().toString());

    bool notificationsEnabled = prefs.getBool('notifications_enabled') ?? false;
    if (counter >= 15 && notificationsEnabled) {
      _showToast(context);
      // prefs now show today's prayers complete, so this skips today
      await getIt<NotificationService>().syncNotifications();
    }
  }

  void _showToast(BuildContext context) {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
      SnackBar(
        content: const Text(
          'Prayers complete! Notifications will resume tomorrow.',
        ),
      ),
    );
  }

  Future<void> _resetCounter() async {
    debugPrint('reset counter');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('counter', 0);
    setState(() {
      _counter = 0;
    });
  }

  Future<void> _resetCounterAndResync() async {
    await _resetCounter();
    // prayers are no longer complete, so reminders resume today
    await getIt<NotificationService>().syncNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget>[
          PopupMenuButton(
            onSelected: (result) {
              if (result == 'reset') {
                _resetCounterAndResync();
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ScreenNavigator.getScreenWidget(result as String),
                  ),
                );
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry>[
              const PopupMenuItem(child: Text('Reset'), value: 'reset'),
              const PopupMenuItem(child: Text('Settings'), value: 'settings'),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            children: <Widget>[
              Text('$_counter', style: textTheme.headlineSmall),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      children: [
                        Text(
                          'Hail and blessed be the hour and moment in which the Son of God was born of the most pure Virgin Mary, at midnight, in Bethlehem, in the piercing cold.\n\nIn that hour, vouchsafe, O my God! to hear my prayer and grant my desire',
                          style: textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          '[name your intention]',
                          style: intentionStyle(textTheme),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          'through the merits of Our Saviour Jesus Christ, and of His Blessed Mother.',
                          style: textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              FilledButton(
                onPressed: _incrementCounter,
                child: const Text('Amen'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

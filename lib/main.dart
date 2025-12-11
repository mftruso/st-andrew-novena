import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:st_andrew_novena/notificationService.dart';
import 'package:st_andrew_novena/settingsPage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzData;
import 'package:flutter_timezone/flutter_timezone.dart';

// +JMJ+
// AMDG
// Sanctus Andrea, ora pro nobis!

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = 
    FlutterLocalNotificationsPlugin();
final getIt = GetIt.instance;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  tzData.initializeTimeZones();
  try {
    final String timezone = await FlutterTimezone.getLocalTimezone();
    debugPrint('Local Timezone: ' + timezone);
    tz.setLocalLocation(tz.getLocation(timezone));
  } on Exception {
    debugPrint('Could not load local timezone, defaults to UTC');
  }

  // register the singleton service
  getIt.registerSingleton<NotificationService>(NotificationService());

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return MaterialApp(
      title: 'St. Andrew Novena',
      theme: ThemeData(
          colorScheme: ColorScheme(
            brightness: Brightness.light,
            primary: Color(0xFF9f382b),
            onPrimary: Colors.red,
            primaryContainer: Colors.grey,
            secondary: Colors.red,
            secondaryContainer: Colors.grey,
            onSecondary: Colors.red,
            surface: Color(0xFFe6cb9e),
            onSurface: Colors.black,
            error: Colors.redAccent,
            onError: Colors.white,
          ),
          appBarTheme: AppBarTheme(color: Colors.amber),
          useMaterial3: true,
          textTheme: GoogleFonts.montserratTextTheme(textTheme)
              .copyWith(bodySmall: TextStyle(fontSize: 20))),
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

enum Screens {
  settings,
}

class ScreenNavigator {
  static Widget getScreenWidget(String screenString) {
    final Screens screen = Screens.values.firstWhere(
      (s) => s.toString().split('.').last == screenString,
      orElse: () => Screens.settings,
    );

    switch (screen) {
      case Screens.settings:
        return SettingsPage();
      default:
        return Container();
    }
  }
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  @override
  void initState() {
    super.initState();
    _initializeCounter();
    _initializeNotifications();
    _scheduleDailyNotificationsIfNeeded();
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
        _resetCounter();
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

  Future<void> _scheduleDailyNotificationsIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final String? lastScheduledDayStr = prefs.getString('last_scheduled_day');
    final String todayStr = DateTime.now().toIso8601String().substring(0, 10);

    if (lastScheduledDayStr != todayStr) {
      debugPrint('scheduling notifications for today: $todayStr');
      await getIt<NotificationService>().cancelAllNotifications();
      await getIt<NotificationService>().scheduleNotificationsFor(DateTime.now());
      await prefs.setString('last_scheduled_day', todayStr);
    } else {
      debugPrint('notifications already scheduled for today: $todayStr');
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
      await getIt<NotificationService>().cancelAllNotifications();
      final tomorrow = DateTime.now().add(Duration(days: 1));
      await getIt<NotificationService>().scheduleNotificationsFor(tomorrow);
      await prefs.setString('last_scheduled_day', tomorrow.toIso8601String().substring(0, 10));
      // TODO: show toast "Prayers complete! Notifications will resume tomorrow."
    }
  }

  Future<void> _resetCounter() async {
    debugPrint('reset counter');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('counter', 0);
    setState(() {
      _counter = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text(widget.title, style: GoogleFonts.montserrat()),
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: <Widget>[
          PopupMenuButton(
              onSelected: (result) {
                if (result == 'reset') {
                  _resetCounter();
                } else {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              ScreenNavigator.getScreenWidget(result as String)));
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry>[
                    const PopupMenuItem(child: Text('Reset'), value: 'reset'),
                    const PopupMenuItem(
                        child: Text('Settings'), value: 'settings'),
                  ])
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              Text('$_counter',
                  style: Theme.of(context).textTheme.headlineSmall),
              Container(
                child: Column(
                  children: [
                    Text(
                        'Hail and blessed be the hour and moment in which the Son of God was born of the most pure Virgin Mary, at midnight, in Bethlehem, in the piercing cold.\n\nIn that hour, vouchsafe, O my God! to hear my prayer and grant my desire',
                        style: Theme.of(context).textTheme.bodySmall),
                    Text('[name your intention]',
                        style: TextStyle(
                            fontStyle: FontStyle.italic, fontSize: 18)),
                    Text(
                        'through the merits of Our Saviour Jesus Christ, and of His Blessed Mother.',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _incrementCounter,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade100),
                  child: Text('Amen',
                      style: TextStyle(
                          fontSize:
                              Theme.of(context).textTheme.bodySmall?.fontSize,
                          color: Theme.of(context).colorScheme.primary)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _initializeNotifications() async {
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation< 
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    var initializationSettingsAndroid = 
        AndroidInitializationSettings('ic_notifications_white_18dp');
    final DarwinInitializationSettings initializationSettingsDarwin = 
        DarwinInitializationSettings();

    final InitializationSettings initializationSettings = 
        InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsDarwin);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }
}
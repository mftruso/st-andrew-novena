import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:st_andrew_novena/aboutPage.dart';
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
final List<ReceivedNotification> didReceiveLocalNotificationSubject =
    List<ReceivedNotification>.empty();
final List<String> selectNotificationSubject = List<String>.empty();
const appName = 'St. Andrew Novena';
final getIt = GetIt.instance;

class ReceivedNotification {
  final int id;
  final String title;
  final String body;
  final String payload;

  ReceivedNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.payload,
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  var timezone;
  tzData.initializeTimeZones();
  try {
    timezone =
        await FlutterTimezone.getLocalTimezone(); //e.g. America/Chicago
    debugPrint('Local Timezone: ' + timezone);
    var location = tz.getLocation(timezone);
    tz.setLocalLocation(location);
  } on Exception {
    debugPrint('Could not load local timezone, defaults to UTC');
  }

  // register the singleton service
  getIt.registerSingleton<NotificationService>(NotificationService());

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return MaterialApp(
      title: appName,
      theme: ThemeData(
          colorScheme: ColorScheme(
            brightness: Brightness.light,
            primary: Color(0xFF9f382b),
            onPrimary: Colors.red,
            // Colors that are not relevant to AppBar in LIGHT mode:
            primaryContainer: Colors.grey,
            secondary: Colors.red,
            secondaryContainer: Colors.grey,
            onSecondary: Colors.red,
            background: Color(0xFFe6cb9e),
            onBackground: Colors.black,
            surface: Colors.grey.shade100,
            onSurface: Colors.black,
            error: Colors.redAccent,
            onError: Colors.white,
          ),
          appBarTheme: AppBarTheme(color: Colors.amber),
          useMaterial3: true,
          textTheme: GoogleFonts.montserratTextTheme(textTheme)
              .copyWith(bodySmall: TextStyle(fontSize: 20))),
      home: MyHomePage(title: appName),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, this.title = ''}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

enum Screens {
  settings,
  // about,
}

class ScreenNavigator {
  static Screens getScreenFromString(String screenString) {
    return Screens.values.firstWhere(
      (screen) => screen.toString().split('.').last == screenString,
      orElse: () => Screens.settings,
    );
  }

  static Widget getScreenWidget(String screenString) {
    final Screens screen = getScreenFromString(screenString);

    switch (screen) {
      case Screens.settings:
        return SettingsPage();
      // Add cases for other screens
      default:
        return Container();
    }
  }
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  Future _initializeCounter() async {
    debugPrint('initializeCounter');
    final prefs = await SharedPreferences.getInstance();
    int counter = prefs.getInt('counter') ?? 0;

    // check last updated
    String? lastUpdatedStr = prefs.getString('last_updated');

    if (lastUpdatedStr != null) {
      debugPrint('Counter last updated: ' + lastUpdatedStr);
      DateTime lastUpdated = DateTime.parse(lastUpdatedStr);
      DateTime now = DateTime.now();
      DateTime startOfToday = DateTime(now.year, now.month, now.day);
      if (lastUpdated.isBefore(startOfToday)) {
        debugPrint('last updated yesterday or before');
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

  Future _incrementCounter() async {
    final prefs = await SharedPreferences.getInstance();
    int counter = prefs.getInt('counter') ?? 0;
    counter++;
    prefs.setInt('counter', counter);
    setState(() {
      _counter = counter;
    });
    DateTime now = DateTime.now();
    prefs.setString('last_updated', now.toString());
    bool notificationsEnabled = prefs.getBool('notifications_enabled') ?? false;
    if (counter == 15 && notificationsEnabled) {
      getIt<NotificationService>().rescheduleForTomorrow();
      // TODO show toast "Prayers complete! Notifications will resume tomorrow at 7am"
//      _showToast(context);
    }
  }

  Future _resetCounter() async {
    debugPrint('reset counter');
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('counter', 0);
    setState(() {
      _counter = 0;
    });
  }

  @override
  void initState() {
    super.initState();
    _initializeCounter();
    _initializeNotifications();
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: Text(widget.title, style: GoogleFonts.montserrat()),
          backgroundColor: Theme.of(context).colorScheme.primary,
          actions: <Widget>[
            PopupMenuButton(
                onSelected: (result) {
                  switch (result) {
                    case 'reset':
                      _resetCounter();
                      break;
                    default:
                      final Widget screen =
                          ScreenNavigator.getScreenWidget(result);

                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) => screen));
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry>[
                      const PopupMenuItem(
                        child: Text('Reset'),
                        value: 'reset',
                      ),
                      const PopupMenuItem(
                        child: Text('Settings'),
                        value: 'settings',
                      ),
                      // const PopupMenuItem(
                      //   child: Text('About'),
                      //   value: 'about',
                      // ),
                    ])
          ]),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            // Column is also a layout widget. It takes a list of children and
            // arranges them vertically. By default, it sizes itself to fit its
            // children horizontally, and tries to be as tall as its parent.
            //
            // Invoke "debug painting" (press "p" in the console, choose the
            // "Toggle Debug Paint" action from the Flutter Inspector in Android
            // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
            // to see the wireframe for each widget.
            //
            // Column has various properties to control how it sizes itself and
            // how it positions its children. Here we use mainAxisAlignment to
            // center the children vertically; the main axis here is the vertical
            // axis because Columns are vertical (the cross axis would be
            // horizontal).
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              Text(
                '$_counter',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Container(
                child: Column(
                  children: [
                    Text(
                        'Hail and blessed be the hour and moment in which the Son of God was born of the most pure Virgin Mary, at midnight, in Bethlehem, in the piercing cold.\n\nIn that hour, vouchsafe, O my God! to hear my prayer and grant my desire',
                        style: Theme.of(context).textTheme.bodySmall),
                    Text(
                      '[name your intention]',
                      style:
                          TextStyle(fontStyle: FontStyle.italic, fontSize: 18),
                    ),
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
                      child: Text('Amen',
                          style: TextStyle(
                              fontSize: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.fontSize,
                              color: Theme.of(context).colorScheme.primary))))
            ],
          ),
        ),
      ),
    );
  }

  Future<void> onDidReceiveLocalNotification(
      int id, String title, String body, String payload) async {
    // display a dialog with the notification details, tap ok to go to another page
    await showDialog(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: Text('Ok'),
            onPressed: () async {
              Navigator.of(context, rootNavigator: true).pop();
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MyApp(),
                ),
              );
            },
          )
        ],
      ),
    );
  }

  // initialize within the first page so that _selectNotification() has access to the Navigator
  Future _initializeNotifications() async {
    // notification config
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestPermission();
    var initializationSettingsAndroid =
        AndroidInitializationSettings('ic_notifications_white_18dp');
    var initializationSettingsIOS = DarwinInitializationSettings(
        onDidReceiveLocalNotification:
            (int id, String? title, String? body, String? payload) async {
      didReceiveLocalNotificationSubject.add(ReceivedNotification(
          id: id,
          title: title ?? '',
          body: body ?? '',
          payload: payload ?? ''));
    });
    final InitializationSettings initializationSettings =
        InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse: onDidReceiveNotificationResponse);
  }

  void onDidReceiveNotificationResponse(NotificationResponse? response) async {
    String? payload = response?.payload;

    if (payload != null) {
      debugPrint('notification payload: ' + payload);

      if (payload == 'RESET') {
        await _resetCounter();
        getIt<NotificationService>().scheduleNotifications();
      }
    }
  }

//  void _showToast(BuildContext context) {
//    debugPrint('prayer complete toast');
//    final scaffold = Scaffold.of(context);
//    scaffold.showSnackBar(
//      SnackBar(
//        content: Text('Prayer complete! Notifications will resume tomorrow at 7:00 a.m.')
//      ),
//    );
//  }
}

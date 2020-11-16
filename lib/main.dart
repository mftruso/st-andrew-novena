import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:st_andrew_novena_flutter/notificationConfig.dart';
import 'package:st_andrew_novena_flutter/notificationService.dart';
import 'package:st_andrew_novena_flutter/settingsPage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzData;
import 'package:flutter_native_timezone/flutter_native_timezone.dart';


// +JMJ+
// AMDG

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
final List<ReceivedNotification> didReceiveLocalNotificationSubject =
    List<ReceivedNotification>();
final List<String> selectNotificationSubject = List<String>();
const appName = 'St. Andrew Novena';
final getIt = GetIt.instance;

class ReceivedNotification {
  final int id;
  final String title;
  final String body;
  final String payload;

  ReceivedNotification({
    @required this.id,
    @required this.title,
    @required this.body,
    @required this.payload,
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  var timezone;
  tzData.initializeTimeZones();
  try {
    timezone = await FlutterNativeTimezone.getLocalTimezone();
    debugPrint('Local Timezone: ' + timezone);
    var location = tz.getLocation(timezone);
    tz.setLocalLocation(location);
  } on Exception {
    debugPrint('Could not load local timezone, defaults to UTC');
  }

  // register the singleton service
  getIt.registerSingleton<NotificationService>(NotificationService());


  // notification config
  flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  var initializationSettingsAndroid =
      AndroidInitializationSettings('ic_notifications_white_18dp');
  var initializationSettingsIOS = IOSInitializationSettings(
      onDidReceiveLocalNotification:
          (int id, String title, String body, String payload) async {
    didReceiveLocalNotificationSubject.add(ReceivedNotification(
        id: id, title: title, body: body, payload: payload));
  });
  final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings,
      onSelectNotification: (String payload) async {
    if (payload != null) {
      debugPrint('notification payload: ' + payload);
    }
    selectNotificationSubject.add(payload);
  });

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
          primarySwatch: Colors.red,
          accentColor: Colors.red,
          textTheme: GoogleFonts.montserratTextTheme(textTheme)
              .copyWith(body1: TextStyle(fontSize: 20))),
      home: MyHomePage(title: appName),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

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

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  Future _initializeCounter() async {
    final prefs = await SharedPreferences.getInstance();
    int counter = prefs.getInt('counter') ?? 0;
    setState(() {
      _counter = counter;
    });
  }

  Future _incrementCounter() async {
    final prefs = await SharedPreferences.getInstance();
    int counter = prefs.getInt('counter') ?? 0;
    counter++;
    prefs.setInt('counter', counter);
    setState(() {
      _counter = counter;
    });
    bool notificationsEnabled = prefs.getBool('notifications_enabled');
    if (counter == 15 && notificationsEnabled) {
      _rescheduleForTomorrow();
    }
  }

  Future _resetCounter() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('counter', 0);
    setState(() {
      _counter = 0;
    });
  }

  Future<void> _rescheduleForTomorrow() async {
    debugPrint('cancelling current notifications');
    await flutterLocalNotificationsPlugin.cancelAll();

    debugPrint('rescheduling notifications');
    final now = DateTime.now();
    final tomorrow =
        tz.TZDateTime(tz.local, now.year, now.month, now.day + 1, 7); // 7am tomorrow
    debugPrint("reschedule time: " + tomorrow.toIso8601String());
    flutterLocalNotificationsPlugin.zonedSchedule(
        0,
        notificationTitle,
        notificationBody,
        tomorrow,
        platformChannelSpecifics,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: "RESET");
  }

  @override
  void initState() {
    super.initState();
    _initializeCounter();
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
      appBar: AppBar(
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: Text(widget.title, style: GoogleFonts.montserrat()),
          actions: <Widget>[
            PopupMenuButton(
                onSelected: (result) {
                  if (result == 'reset') {
                    _resetCounter();
                  } else if (result == 'settings') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SettingsPage()),
                    );
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
                style: Theme.of(context).textTheme.display1,
              ),
              Text(
                  'Hail and blessed be the hour and moment in which the Son of God was born of the most pure Virgin Mary, at midnight, in Bethlehem, in the piercing cold.\n\nIn that hour, vouchsafe, O my God! to hear my prayer and grant my desire [name your intention], through the merits of Our Saviour Jesus Christ, and of His Blessed Mother.',
                  style: Theme.of(context).textTheme.body1),
              SizedBox(
                  width: double.infinity,
                  child: RaisedButton(
                      onPressed: _incrementCounter,
                      child: Text('Amen',
                          style: TextStyle(
                              fontSize:
                                  Theme.of(context).textTheme.body1.fontSize,
                              color: Theme.of(context).accentColor))))
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
        title: title != null ? Text(title) : null,
        content: body != null ? Text(body) : null,
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

  Future<void> onSelectNotification(String payload) async {
    if (payload != null) {
      debugPrint('notification payload: ' + payload);

      if (payload == 'RESET') {
        _resetCounter();
        getIt<NotificationService>().scheduleNotifications();
      }
    }

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MyApp()),
    );
  }
}

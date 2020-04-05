import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:st_andrew_novena_flutter/settingsPage.dart';

// +JMJ+
// AMDG

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

void main() async {
  flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'St. Andrew Novena',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'St. Andrew Novena'),
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
  }

  Future _resetCounter() async {
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
    var initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');
    var initializationSettingsIOS = IOSInitializationSettings(
        onDidReceiveLocalNotification: onDidReceiveLocalNotification);
    var initializationSettings = InitializationSettings(
        initializationSettingsAndroid, initializationSettingsIOS);
    flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: onSelectNotification);
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
          title: Text(widget.title),
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                '$_counter',
                style: Theme.of(context).textTheme.display1,
              ),
              Text(
                  'Hail and blessed be the hour and moment in which the Son of God was born of the most pure Virgin Mary, at midnight, in Bethlehem, in the piercing cold.\n\nIn that hour, vouchsafe, O my God! to hear my prayer and grant my desire [name your intention], through the merits of Our Saviour Jesus Christ, and of His Blessed Mother.',
                  style: TextStyle(fontSize: 20)),
              RaisedButton(
                  onPressed: _incrementCounter,
                  child: const Text('Amen', style: TextStyle(fontSize: 20)))
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
    }

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MyApp()),
    );
  }
}

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:st_andrew_novena/aboutPage.dart';
import 'package:st_andrew_novena/appTheme.dart';
import 'package:st_andrew_novena/intentionSheet.dart';
import 'package:st_andrew_novena/notificationService.dart';
import 'package:st_andrew_novena/prayerBeads.dart';
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
  try {
    await preloadFonts();
  } catch (e) {
    // the fallback font is better than not starting
    debugPrint('Could not load fonts: $e');
  }

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
      darkTheme: darkTheme(),
      themeMode: ThemeMode.system,
      scrollBehavior: BouncingScrollBehavior(),
      home: MyHomePage(title: 'St. Andrew Novena'),
    );
  }
}

/// iOS-style bounce on every platform, instead of Android's overscroll stretch.
class BouncingScrollBehavior extends MaterialScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, this.title = ''}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

enum Screens { settings, about }

class ScreenNavigator {
  static Widget getScreenWidget(String screenString) {
    final Screens screen = Screens.values.firstWhere(
      (s) => s.toString().split('.').last == screenString,
      orElse: () => Screens.settings,
    );

    switch (screen) {
      case Screens.settings:
        return SettingsPage();
      case Screens.about:
        return AboutPage();
    }
  }
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  int _counter = 0;
  String _intention = '';

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
    // first, so a slow or failed notification setup can't hide it
    await _initializeIntention();
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

  Future<void> _initializeIntention() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _intention = prefs.getString('intention') ?? '';
    });
  }

  Future<void> _editIntention() async {
    final intention = await showIntentionSheet(context, _intention);
    // null when the sheet was dismissed without saving
    if (intention != null && mounted) {
      setState(() {
        _intention = intention;
      });
    }
  }

  Future<void> _incrementCounter() async {
    HapticFeedback.lightImpact();
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

  /// The intention in the prayer, tapped to edit it: underlined like a link
  /// rather than drawn as a button, so it reads as part of the prayer.
  Widget _buildIntention(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.extension<NovenaText>()!.intention;
    final muted = theme.extension<NovenaColors>()!.gold.withValues(alpha: 0.6);
    final intention = _intention.trim();
    final iconSize = MediaQuery.textScalerOf(context).scale(style.fontSize!);

    return Semantics(
      button: true,
      label: intention.isEmpty
          ? 'Prayer intention, not set'
          : 'Prayer intention: $intention',
      onTap: _editIntention,
      onTapHint: 'edit',
      excludeSemantics: true,
      // the gradient behind the prayer would hide ripples on the Scaffold
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: _editIntention,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: intention.isEmpty
                        ? '[name your intention]'
                        : intention,
                    style: TextStyle(
                      decoration: TextDecoration.underline,
                      decorationStyle: TextDecorationStyle.dotted,
                      decorationColor: muted,
                    ),
                  ),
                  // in the text, so it wraps with the last word
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Icon(
                        Icons.edit_outlined,
                        size: iconSize * 0.8,
                        color: muted,
                      ),
                    ),
                  ),
                ],
              ),
              // the theme's style itself, not a copy built on every build
              style: style,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colors = theme.extension<NovenaColors>()!;
    final complete = _counter >= 15;

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
              const PopupMenuItem(child: Text('About'), value: 'about'),
            ],
          ),
        ],
      ),
      body: DecoratedBox(
        // candlelight: brightest around the ring, falling off to the edges
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.6),
            radius: 1.2,
            colors: [colors.halo, theme.colorScheme.surface, colors.vignette],
            stops: const [0, 0.55, 1],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              children: <Widget>[
                // everything but the Amen button scrolls, so the layout fits
                // short screens (landscape, large text)
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(top: 36, bottom: 16),
                    child: Column(
                      children: [
                        PrayerBeads(count: _counter),
                        // always laid out, so the prayer doesn't move when
                        // the badge appears
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: AnimatedOpacity(
                            opacity: complete ? 1 : 0,
                            duration: const Duration(milliseconds: 400),
                            child: ExcludeSemantics(
                              excluding: !complete,
                              child: const CompletedBadge(),
                            ),
                          ),
                        ),
                        Text(
                          'Hail and blessed be the hour and moment in which the Son of God was born of the most pure Virgin Mary, at midnight, in Bethlehem, in the piercing cold.\n\nIn that hour, vouchsafe, O my God! to hear my prayer and grant my desire',
                          style: textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                        _buildIntention(context),
                        Text(
                          'through the merits of Our Saviour Jesus Christ, and of His Blessed Mother.',
                          style: textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                      ],
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
      ),
    );
  }
}

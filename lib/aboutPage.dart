import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatelessWidget {
  AboutPage({Key? key}) : super(key: key);

  static const links = {
    'What is a Novena?': 'https://en.wikipedia.org/wiki/Novena',
    'Prepare for Christmas with the St. Andrew Novena': 'https://aleteia.org/2016/11/30/prepare-for-christmas-with-the-saint-andrew-novena/',
  };
  static const sourceUrl = 'https://github.com/mftruso/st-andrew-novena';

  Future<void> _openLink(BuildContext context, String url) async {
    final messenger = ScaffoldMessenger.of(context);
    if (!await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    )) {
      messenger.showSnackBar(SnackBar(content: Text('Could not open $url')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final body = textTheme.bodyLarge?.copyWith(fontSize: 18, height: 1.4);

    Widget heading(String text) => Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(text, style: textTheme.titleLarge),
    );
    Widget paragraph(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(text, style: body),
    );
    Widget link(String title, String url) => ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: body),
      trailing: Icon(Icons.open_in_new),
      onTap: () => _openLink(context, url),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('About'),
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          children: <Widget>[
            heading('The Prayer'),
            paragraph(
              'The St. Andrew Novena, also called the Christmas Anticipation Prayer, is a Catholic tradition of preparing for the birth of Christ during Advent. It takes its name from its start date, the feast of St. Andrew the Apostle on November 30, rather than being a prayer to St. Andrew: it asks God, recalling the hour of Christ\'s birth in Bethlehem, to grant a particular intention.',
            ),
            paragraph(
              'Though it isn\'t a novena in the strict sense (nine days of prayer), it is called one because it is prayed daily for a set time in petition for a grace.',
            ),
            heading('How to Pray It'),
            paragraph(
              'Pray the prayer 15 times each day, from November 30 until Christmas. Where the prayer says "[name your intention]", ask for the grace you are seeking. In this app, you can tap it to type your intention, which is saved only on this device.',
            ),
            paragraph(
              'The 15 prayers don\'t have to be said all at once: many people spread them throughout the day. If you miss a day, simply pick up again the next day.',
            ),
            heading('Using This App'),
            paragraph(
              'Tap Amen each time you finish the prayer. A bead fills for each prayer, and the ring is complete at 15. The count starts over each day, and Reset in the menu sets it back to 0.',
            ),
            paragraph(
              'Turn on notifications in Settings to be reminded each hour from 7 a.m. Reminders stop for the day once you\'ve prayed 15 times.',
            ),
            heading('Learn More'),
            for (final MapEntry(key: title, value: url) in links.entries)
              link(title, url),
            heading('Open Source'),
            paragraph(
              'This app is open source. Its code and the licenses of the software it uses are on GitHub.',
            ),
            link('St. Andrew Novena on GitHub', sourceUrl),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:st_andrew_novena/appTheme.dart';

// Its own file so google_fonts' cache of loaded fonts starts empty. All
// GoogleFonts calls live in appTheme.dart, so this covers every font the app
// requests.
void main() {
  testWidgets('every font the theme uses loads from bundled assets', (
    WidgetTester tester,
  ) async {
    GoogleFonts.config.allowRuntimeFetching = false;

    // In the real zone: asset reads don't complete under fake async.
    // pendingFonts throws if a requested variant isn't in assets/google_fonts.
    await tester.runAsync(preloadFonts);
  });
}

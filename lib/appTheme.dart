import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

const novenaRed = Color(0xFF9f382b);
const parchment = Color(0xFFe6cb9e);

/// Colors the ColorScheme has no slot for.
class NovenaColors extends ThemeExtension<NovenaColors> {
  const NovenaColors({required this.bead});

  final Color bead;

  @override
  NovenaColors copyWith({Color? bead}) {
    return NovenaColors(bead: bead ?? this.bead);
  }

  @override
  NovenaColors lerp(NovenaColors? other, double t) {
    if (other == null) return this;
    return NovenaColors(bead: Color.lerp(bead, other.bead, t)!);
  }
}

ThemeData lightTheme() {
  return _theme(
    ColorScheme.fromSeed(
      seedColor: novenaRed,
      primary: novenaRed,
      surface: parchment,
    ),
    const NovenaColors(bead: novenaRed),
  );
}

ThemeData _theme(ColorScheme scheme, NovenaColors novenaColors) {
  final base = ThemeData(colorScheme: scheme, useMaterial3: true);
  // base.textTheme carries only colors; weights and sizes come from the
  // geometry, which must be merged in before google_fonts picks variants.
  final baseText = base.typography.englishLike.merge(base.textTheme);
  final textTheme = GoogleFonts.ebGaramondTextTheme(
    baseText.copyWith(
      bodyLarge: baseText.bodyLarge?.copyWith(fontSize: 21, height: 1.5),
    ),
  );

  return base.copyWith(
    textTheme: textTheme,
    extensions: [novenaColors],
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(60),
        shape: const StadiumBorder(),
        textStyle: GoogleFonts.ebGaramond(
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

/// The prayer's body style in italic, for `[name your intention]`.
TextStyle intentionStyle(TextTheme textTheme) {
  return GoogleFonts.ebGaramond(
    textStyle: textTheme.bodyLarge,
    fontStyle: FontStyle.italic,
  );
}

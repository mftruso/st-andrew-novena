import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

const novenaRed = Color(0xFF9f382b);
const parchment = Color(0xFFe6cb9e);

/// Colors the ColorScheme has no slot for.
class NovenaColors extends ThemeExtension<NovenaColors> {
  const NovenaColors({
    required this.bead,
    required this.gold,
    required this.glow,
  });

  final Color bead;

  /// Beads and star once today's prayers are complete, with their [glow].
  final Color gold;
  final Color glow;

  @override
  NovenaColors copyWith({Color? bead, Color? gold, Color? glow}) {
    return NovenaColors(
      bead: bead ?? this.bead,
      gold: gold ?? this.gold,
      glow: glow ?? this.glow,
    );
  }

  @override
  NovenaColors lerp(NovenaColors? other, double t) {
    if (other == null) return this;
    return NovenaColors(
      bead: Color.lerp(bead, other.bead, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
      glow: Color.lerp(glow, other.glow, t)!,
    );
  }
}

ThemeData lightTheme() {
  return _theme(
    ColorScheme.fromSeed(
      seedColor: novenaRed,
      primary: novenaRed,
      surface: parchment,
    ),
    const NovenaColors(
      bead: novenaRed,
      gold: Color(0xFF8A6508),
      glow: Color(0xFFFFC94A),
    ),
  );
}

const _midnight = Color(0xFF0E1628);
const _warmGold = Color(0xFFE9D3A0);

ThemeData darkTheme() {
  return _theme(
    ColorScheme.fromSeed(
      seedColor: novenaRed,
      brightness: Brightness.dark,
      // a touch lighter than novenaRed so it holds up against the navy
      primary: const Color(0xFFB5443A),
      onPrimary: Colors.white,
      surface: _midnight,
      onSurface: _warmGold,
      onSurfaceVariant: const Color(0xFFC2AE80),
      surfaceContainerLowest: const Color(0xFF0A1120),
      surfaceContainerLow: const Color(0xFF131C30),
      surfaceContainer: const Color(0xFF172238),
      surfaceContainerHigh: const Color(0xFF1C2840),
      surfaceContainerHighest: const Color(0xFF22304A),
    ),
    const NovenaColors(
      bead: Color(0xFFD9B45A),
      gold: Color(0xFFFFD86B),
      glow: Color(0xFFFFD86B),
    ),
  );
}

ThemeData _theme(ColorScheme scheme, NovenaColors novenaColors) {
  final base = ThemeData(colorScheme: scheme, useMaterial3: true);
  // base.textTheme carries only colors; weights and sizes come from the
  // geometry, which must be merged in before google_fonts picks variants.
  final baseText = base.typography.englishLike
      .merge(base.textTheme)
      .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);
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

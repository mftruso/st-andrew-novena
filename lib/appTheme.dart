import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

const _midnight = Color(0xFF0E1628);
// app bar and light-mode button: a touch lighter than the midnight background
const _navy = Color(0xFF1F2B47);
const _warmGold = Color(0xFFE9D3A0);
const _ivory = Color(0xFFF5F1E8);

/// Colors the ColorScheme has no slot for.
class NovenaColors extends ThemeExtension<NovenaColors> {
  const NovenaColors({
    required this.bead,
    required this.gold,
    required this.glow,
    required this.halo,
    required this.vignette,
  });

  final Color bead;

  /// Beads and star once today's prayers are complete, with their [glow].
  final Color gold;
  final Color glow;

  /// Background gradient: [halo] around the beads, [vignette] at the edges.
  final Color halo;
  final Color vignette;

  @override
  NovenaColors copyWith({
    Color? bead,
    Color? gold,
    Color? glow,
    Color? halo,
    Color? vignette,
  }) {
    return NovenaColors(
      bead: bead ?? this.bead,
      gold: gold ?? this.gold,
      glow: glow ?? this.glow,
      halo: halo ?? this.halo,
      vignette: vignette ?? this.vignette,
    );
  }

  @override
  NovenaColors lerp(NovenaColors? other, double t) {
    if (other == null) return this;
    return NovenaColors(
      bead: Color.lerp(bead, other.bead, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
      glow: Color.lerp(glow, other.glow, t)!,
      halo: Color.lerp(halo, other.halo, t)!,
      vignette: Color.lerp(vignette, other.vignette, t)!,
    );
  }
}

ThemeData lightTheme() {
  // "winter dawn": the midnight palette on ivory
  return _theme(
    ColorScheme.fromSeed(
      seedColor: _midnight,
      primary: _navy,
      onPrimary: _warmGold,
      surface: _ivory,
      onSurface: _midnight,
      onSurfaceVariant: const Color(0xFF5B6478),
    ),
    const NovenaColors(
      bead: Color(0xFF9A731F),
      gold: Color(0xFF8F6A1C),
      glow: Color(0xFFF2C760),
      halo: Color(0xFFFBF8F2),
      vignette: Color(0xFFE6E3DC),
    ),
    appBarBackground: _navy,
    appBarForeground: _warmGold,
  );
}

ThemeData darkTheme() {
  return _theme(
    ColorScheme.fromSeed(
      seedColor: _midnight,
      brightness: Brightness.dark,
      primary: const Color(0xFFD9B45A),
      onPrimary: _midnight,
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
      halo: Color(0xFF2A3044),
      vignette: Color(0xFF070B16),
    ),
    appBarBackground: const Color(0xFF172238),
    appBarForeground: _warmGold,
  );
}

ThemeData _theme(
  ColorScheme scheme,
  NovenaColors novenaColors, {
  Color? appBarBackground,
  Color? appBarForeground,
}) {
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
      backgroundColor: appBarBackground ?? scheme.primary,
      foregroundColor: appBarForeground ?? scheme.onPrimary,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(60),
        shape: const StadiumBorder(),
        elevation: 3,
        shadowColor: Colors.black,
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

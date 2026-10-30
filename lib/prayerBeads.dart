import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'appTheme.dart';

const _beadSize = 18.0;
const _ringSize = 184.0;

double textScale(BuildContext context) =>
    MediaQuery.textScalerOf(context).scale(16) / 16;

/// The count fits inside the ring up to 2x text, so it only grows past that
/// (iOS accessibility sizes).
double ringScale(BuildContext context) =>
    (textScale(context) / 2).clamp(1.0, 1.5);

/// A ring of [total] beads, one filled per prayer, with the count inside.
class PrayerBeads extends StatelessWidget {
  const PrayerBeads({super.key, required this.count, this.total = 15});

  final int count;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<NovenaColors>()!;
    final ringSize = _ringSize * ringScale(context);
    final radius = (ringSize - _beadSize) / 2;
    final complete = count >= total;
    // past the total, "16 of 15" would read as more than complete
    final over = count > total;

    return Semantics(
      label: over ? '$count prayers' : '$count of $total prayers',
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: ringSize,
        child: Stack(
          children: [
            for (var i = 0; i < total; i++)
              Positioned(
                // bead 0 at the top, then clockwise
                left: radius + radius * math.cos(_angle(i)),
                top: radius + radius * math.sin(_angle(i)),
                child: PrayerBead(
                  key: ValueKey('bead-$i'),
                  filled: i < count,
                  color: complete ? colors.gold : colors.bead,
                  outline: theme.colorScheme.onSurfaceVariant,
                  glow: complete ? colors.glow : null,
                ),
              ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$count',
                    style: theme.textTheme.displayMedium?.copyWith(height: 1),
                  ),
                  Text(
                    over ? 'prayers' : 'of $total',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _angle(int i) => -math.pi / 2 + 2 * math.pi * i / total;
}

class PrayerBead extends StatelessWidget {
  const PrayerBead({
    super.key,
    required this.filled,
    required this.color,
    required this.outline,
    this.glow,
  });

  final bool filled;
  final Color color;

  /// Border of an empty bead, strong enough to see against the background.
  final Color outline;
  final Color? glow;

  @override
  Widget build(BuildContext context) {
    final scale = filled ? 1.0 : 0.6;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      width: _beadSize,
      height: _beadSize,
      transformAlignment: Alignment.center,
      transform: Matrix4.diagonal3Values(scale, scale, 1),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // lit from the top left, so a filled bead reads as round
        gradient: filled
            ? RadialGradient(
                center: const Alignment(-0.35, -0.45),
                radius: 0.9,
                colors: [
                  Color.lerp(color, Colors.white, 0.45)!,
                  color,
                  Color.lerp(color, Colors.black, 0.3)!,
                ],
                stops: const [0, 0.5, 1],
              )
            : null,
        border: Border.all(
          color: filled ? Color.lerp(color, Colors.black, 0.3)! : outline,
          width: filled ? 0.5 : 1.25,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: filled ? 0.3 : 0),
            offset: const Offset(0, 1.5),
            blurRadius: 2.5,
          ),
          BoxShadow(
            color: (glow ?? color).withValues(alpha: glow == null ? 0 : 0.7),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}

/// Shown under the beads once today's 15 prayers are done.
class CompletedBadge extends StatelessWidget {
  const CompletedBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, color: theme.extension<NovenaColors>()!.gold),
        const SizedBox(width: 6),
        // wraps at large text sizes instead of overflowing the screen
        Flexible(
          child: Text(
            'Completed for today',
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'appTheme.dart';

const _beadSize = 18.0;
const _ringSize = 184.0;

/// A ring of [total] beads, one filled per prayer, with the count inside.
class PrayerBeads extends StatelessWidget {
  const PrayerBeads({super.key, required this.count, this.total = 15});

  final int count;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<NovenaColors>()!;
    const radius = (_ringSize - _beadSize) / 2;
    final complete = count >= total;

    return Semantics(
      label: '$count of $total prayers',
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: _ringSize,
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
                    'of $total',
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
    this.glow,
  });

  final bool filled;
  final Color color;
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
        color: filled ? color : color.withValues(alpha: 0),
        border: Border.all(
          color: color.withValues(alpha: filled ? 1 : 0.5),
          width: 1.5,
        ),
        boxShadow: [
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
        Text('Completed for today', style: theme.textTheme.titleMedium),
      ],
    );
  }
}

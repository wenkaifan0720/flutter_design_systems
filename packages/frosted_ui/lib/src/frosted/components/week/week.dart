import 'package:flutter/widgets.dart';

import '../../glyphs.dart';

import '../../chrome_metrics.dart';
import '../../format.dart';
import '../../internal/face.dart';
import '../../internal/cap.dart';
import '../../internal/hit_slop.dart';
import '../../theme.dart';
import '../pressable/pressable.dart';

/// Where one day of a [FrostedWeekStrip] stands: [complete] done and lit,
/// [missed] gone by undone, [current] the day under way and not yet done,
/// [upcoming] still to come.
enum FrostedDayStatus {
  /// Done, and lit.
  complete,

  /// Gone by undone.
  missed,

  /// Under way and not yet done.
  current,

  /// Still to come.
  upcoming,
}

/// A week as seven days in a row: a bead 36 across with the weekday's
/// letters under it, so the state never rests on colour alone. A kept day
/// is a round of the hue's light wearing a check in the hue's deep ink; a
/// missed one prints its date on the wash in a hairline; today prints its
/// date on white in the strip's ring of the hue; a day to come prints its
/// date on the wash, faint. With [onDayTap] the days that have happened are
/// controls (kept ones toggled); the days to come never are, since a day
/// that has not happened cannot be kept. [start] is the first day (a
/// Monday, as a rule), [days] the seven states from it and [hue] the light
/// the kept days wear (the prism's own by default). DERIVED: the source's
/// strip of days (`.strip-day`) is a row of dots; the beads take the dot's
/// light and today's ring.
///
/// ```dart
/// FrostedWeekStrip(start: DateTime(2026, 10, 26), days: const [FrostedDayStatus.complete, FrostedDayStatus.complete, FrostedDayStatus.missed, FrostedDayStatus.current, FrostedDayStatus.upcoming, FrostedDayStatus.upcoming, FrostedDayStatus.upcoming], onChanged: toggle)
/// ```
class FrostedWeekStrip extends StatelessWidget {
  /// Creates a [FrostedWeekStrip].
  const FrostedWeekStrip({
    required this.start,
    required this.days,
    this.onChanged,
    this.hue,
    super.key,
  }) : assert(days.length == 7, 'A week is seven days.');

  /// The first day of the strip.
  final DateTime start;

  /// Where each of the seven days stands, from [start].
  final List<FrostedDayStatus> days;

  /// What a press on a day that has happened does with its date; null makes
  /// the strip a report.
  final ValueChanged<DateTime>? onChanged;

  /// The light the kept days and today's ring wear; null takes the prism's.
  final FrostedHue? hue;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final light = hue ?? t.hues.iris;
    Widget day(int i) {
      final date = DateTime(start.year, start.month, start.day + i);
      final state = days[i];
      final Widget bead;
      switch (state) {
        case FrostedDayStatus.complete:
          bead = FrostedFace(
            material: FrostedMaterial.paint,
            radius: BorderRadius.circular(FrostedChromeMetrics.weekBead / 2),
            gradients: [light.dot],
            child: Center(
              child: Icon(
                FrostedGlyphs.check,
                size: FrostedChromeMetrics.checkGlyph,
                color: light.inkDeep,
              ),
            ),
          );
        case FrostedDayStatus.current:
          bead = DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: t.glass.plane,
              border: Border.all(
                color: light.b,
                width: FrostedChromeMetrics.stripDotRing,
              ),
            ),
            child: Center(
              child: _date(
                date,
                t.textTheme.labelSmall.c(t.colorScheme.textPrimary),
              ),
            ),
          );
        case FrostedDayStatus.missed:
          bead = FrostedFace(
            material: FrostedMaterial.paint,
            radius: BorderRadius.circular(FrostedChromeMetrics.weekBead / 2),
            color: t.glass.wash,
            ring: t.colorScheme.border,
            child: Center(
              child: _date(
                date,
                t.textTheme.labelSmall.c(t.colorScheme.textSecondary),
              ),
            ),
          );
        case FrostedDayStatus.upcoming:
          bead = FrostedFace(
            material: FrostedMaterial.paint,
            radius: BorderRadius.circular(FrostedChromeMetrics.weekBead / 2),
            color: t.glass.wash.withValues(alpha: t.glass.wash.a * 0.5),
            child: Center(
              child: _date(
                date,
                t.textTheme.labelSmall.c(t.colorScheme.textTertiary),
              ),
            ),
          );
      }
      final column = Column(
        mainAxisSize: MainAxisSize.min,
        spacing: FrostedSpacing.s6,
        children: [
          SizedBox.square(
            dimension: FrostedChromeMetrics.weekBead,
            child: bead,
          ),
          Text(
            FrostedFormat.weekday(date).toUpperCase(),
            maxLines: 1,
            textScaler: TextScaler.noScaling,
            // .strip-x span { 500 12/1; ink-3 }; .now { ink; 600 }
            style: state == FrostedDayStatus.current
                ? t.textTheme.tab.semibold.c(t.colorScheme.textPrimary)
                : t.textTheme.tab.c(t.colorScheme.textTertiary),
          ),
        ],
      );
      final said = switch (state) {
        FrostedDayStatus.complete => 'kept',
        FrostedDayStatus.missed => 'missed',
        FrostedDayStatus.current => 'today',
        FrostedDayStatus.upcoming => 'to come',
      };
      final spoken =
          '${FrostedFormat.weekday(date, short: false)} '
          '${FrostedFormat.date(date)}, $said';
      final tappable = onChanged != null && state != FrostedDayStatus.upcoming;
      if (!tappable) {
        return Semantics(label: spoken, excludeSemantics: true, child: column);
      }
      return FrostedHitSlop(
        child: FrostedPressable(
          onPressed: () => onChanged!(date),
          label: spoken,
          toggled: state == FrostedDayStatus.complete,
          radius: FrostedChromeMetrics.weekBead / 2,
          child: column,
        ),
      );
    }

    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [for (var i = 0; i < 7; i++) day(i)],
      ),
    );
  }

  /// The date printed on a bead, never scaled: the bead is a fixed box.
  static Widget _date(DateTime date, TextStyle style) => frostedCapCentred(
    Text(
      '${date.day}',
      maxLines: 1,
      textScaler: TextScaler.noScaling,
      style: style.tabular,
    ),
  );
}

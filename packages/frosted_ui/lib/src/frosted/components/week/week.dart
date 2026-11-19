import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../glyphs.dart';

import '../../chrome_metrics.dart';
import '../../format.dart';
import '../../internal/face.dart';
import '../../internal/cap.dart';
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
/// date on the wash, faint. With [onChanged] the days that have happened are
/// controls (kept ones toggled); the days to come never are, since a day
/// that has not happened cannot be kept. [start] is the first day (a
/// Monday, as a rule), [days] the seven states from it and [hue] the light
/// the kept days wear. At large text sizes the dates and weekday labels grow
/// together and the week can span multiple rows.
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
    final scaler = MediaQuery.textScalerOf(context);
    final beadSize =
        FrostedChromeMetrics.weekBead +
        scaler.scale(t.textTheme.labelSmall.fontSize!) -
        t.textTheme.labelSmall.fontSize!;
    var cellWidth = FrostedBreakpoints.hitTargetOf(context);
    for (var i = 0; i < 7; i++) {
      final day = DateTime(start.year, start.month, start.day + i);
      final p = TextPainter(
        text: TextSpan(
          text: FrostedFormat.weekday(day).toUpperCase(),
          style: t.textTheme.tab.semibold,
        ),
        textDirection: Directionality.of(context),
        textScaler: scaler,
      )..layout();
      if (p.width.ceilToDouble() > cellWidth) {
        cellWidth = p.width.ceilToDouble();
      }
      p.dispose();
    }
    if (beadSize > cellWidth) cellWidth = beadSize;
    Widget day(int i) {
      final date = DateTime(start.year, start.month, start.day + i);
      final state = days[i];
      final Widget bead;
      switch (state) {
        case FrostedDayStatus.complete:
          bead = FrostedFace(
            material: FrostedMaterial.paint,
            radius: BorderRadius.circular(beadSize / 2),
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
            radius: BorderRadius.circular(beadSize / 2),
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
            radius: BorderRadius.circular(beadSize / 2),
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
          SizedBox.square(dimension: beadSize, child: bead),
          Text(
            FrostedFormat.weekday(date).toUpperCase(),
            maxLines: 1,
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
      return FrostedPressable(
        onPressed: () => onChanged!(date),
        label: spoken,
        toggled: state == FrostedDayStatus.complete,
        radius: FrostedChromeMetrics.weekBead / 2,
        child: column,
      );
    }

    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: LayoutBuilder(
        builder: (context, box) {
          if (!box.hasBoundedWidth || box.maxWidth >= 7 * cellWidth) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [for (var i = 0; i < 7; i++) day(i)],
            );
          }
          final count = (box.maxWidth / cellWidth).floor().clamp(1, 7);
          return Wrap(
            runSpacing: FrostedSpacing.s8,
            children: [
              for (var i = 0; i < 7; i++)
                SizedBox(width: box.maxWidth / count, child: day(i)),
            ],
          );
        },
      ),
    );
  }

  /// The day number on a bead, at the reader’s text size, in the reader's
  /// digits.
  static Widget _date(DateTime date, TextStyle style) => Builder(
    builder: (context) => frostedCapCentred(
      Text(
        DesignLocalizations.of(context).formatDecimal(date.day),
        maxLines: 1,
        style: style.tabular,
      ),
    ),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<DateTime>('start', start))
      ..add(IterableProperty<FrostedDayStatus>('days', days))
      ..add(
        ObjectFlagProperty<ValueChanged<DateTime>>.has('onChanged', onChanged),
      )
      ..add(DiagnosticsProperty<FrostedHue>('hue', hue, defaultValue: null));
  }
}

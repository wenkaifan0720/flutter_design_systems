import 'package:flutter/widgets.dart';

import '../../theme.dart';
import '../icon_tile/icon_tile.dart';
import '../pressable/pressable.dart';

/// One week as a row of days to pick from, the strip a phone's calendar
/// heads its agenda with: seven equal cells, each the short
/// weekday in caption1 (the third ink) over the day's number in a 32
/// circle and a 4 dot under it when [hasEvents] says the day holds
/// something. The [value] day is the brand's fill with its number in the
/// on-brand ink, strong; [today] (when not picked) has its number in the
/// brand's ink, strong. The week shown is the one holding [value],
/// starting on [firstDayOfWeek] (Monday by default). A press picks a day
/// through [onChanged]; with none it is inert. Derived: Fluent has no week
/// strip; it is composed from its calendar's day button. Each day reads
/// as a button, "Monday, November 3", selected when picked.
///
/// ```dart
/// Fluent2WeekStrip(value: DateTime(2026, 11, 3), today: DateTime(2026, 11, 3), onChanged: (day) {})
/// ```
class Fluent2WeekStrip extends StatelessWidget {
  /// A week strip holding [value].
  const Fluent2WeekStrip({
    required this.value,
    this.onChanged,
    this.today,
    this.hasEvents,
    this.firstDayOfWeek = DateTime.monday,
    super.key,
  });

  /// The day picked; its week is the one shown.
  final DateTime value;

  /// Told the day pressed; null makes the strip inert.
  final ValueChanged<DateTime>? onChanged;

  /// The day marked as today; null marks none.
  final DateTime? today;

  /// Whether a day holds something (a meeting, a deadline); null marks
  /// none.
  final bool Function(DateTime day)? hasEvents;

  /// The weekday the week starts on, [DateTime.monday] to
  /// [DateTime.sunday].
  final int firstDayOfWeek;

  /// The seven days of the week holding [value], from [firstDayOfWeek].
  static List<DateTime> weekOf(
    DateTime value, {
    int firstDayOfWeek = DateTime.monday,
  }) {
    final day = DateTime(value.year, value.month, value.day);
    final back = (day.weekday - firstDayOfWeek) % 7;
    final start = DateTime(day.year, day.month, day.day - back);
    return [
      for (var i = 0; i < 7; i++)
        DateTime(start.year, start.month, start.day + i),
    ];
  }

  static bool _same(DateTime a, DateTime? b) =>
      b != null && a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final pick = onChanged;
    // Seven days share the row, so the strip's words grow with the
    // reader's text size up to half again, and the day's disc with them:
    // the numeral stays inside its disc and the weekdays apart.
    final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final grow = scale < _most ? scale : _most;
    final disc = 32 * grow;
    Widget cell(DateTime day) {
      final picked = _same(day, value);
      final isToday = _same(day, today);
      final events = hasEvents?.call(day) ?? false;
      final spoken = Fluent2DateBlock.spoken(day);
      return Fluent2Pressable(
        onPressed: pick == null ? null : () => pick(day),
        label: isToday ? '$spoken, today' : spoken,
        value: events ? 'Has events' : null,
        selected: picked,
        radius: Fluent2Radius.medium,
        builder: (context, states) {
          final press = states.press;
          final fill = picked
              ? press.pick(
                  t.colors.brandBackground,
                  t.colors.brandBackgroundHover,
                  t.colors.brandBackgroundPressed,
                )
              : press.pick(
                  t.colors.subtleBackground,
                  t.colors.subtleBackgroundHover,
                  t.colors.subtleBackgroundPressed,
                );
          final number = picked
              ? t.body1Strong.tabular.c(t.colors.neutralForegroundOnBrand)
              : isToday
              ? t.body1Strong.tabular.c(t.accentText)
              : t.body1.tabular.c(t.textPrimary);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: Fluent2Spacing.xs),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  Fluent2DateBlock.weekdayOf(day).substring(0, 3),
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  style: t.caption1.c(t.textTertiary),
                ),
                const SizedBox(height: Fluent2Spacing.xs),
                Container(
                  width: disc,
                  height: disc,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: fill,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${day.day}',
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                    softWrap: false,
                    style: number,
                  ),
                ),
                const SizedBox(height: Fluent2Spacing.xs),
                SizedBox(
                  width: 4,
                  height: 4,
                  child: events
                      ? DecoratedBox(
                          decoration: BoxDecoration(
                            color: t.textTertiary,
                            shape: BoxShape.circle,
                          ),
                        )
                      : null,
                ),
              ],
            ),
          );
        },
      );
    }

    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: _most,
        child: Row(
          children: [
            for (final day in weekOf(value, firstDayOfWeek: firstDayOfWeek))
              Expanded(child: cell(day)),
          ],
        ),
      ),
    );
  }

  // The most the strip's words grow with the reader's text size.
  static const double _most = 1.5;
}

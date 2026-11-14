import 'package:flutter/widgets.dart';

import '../../theme.dart';
import '../check/check.dart';

/// How one day of a [LedgerWeekStrip] stands.
enum LedgerDayMark {
  /// Done: the green check pressed on it.
  kept,

  /// Passed without being done: its ring voided with a stroke through it.
  missed,

  /// Today, still to do: ringed in the ink with its centre dotted.
  today,

  /// Not yet come: a single faint dot, as the leader sets one.
  upcoming,
}

/// A week at a glance, seven days in a row: each a mark over its letter in the
/// mono capitals, [LedgerDayMark.kept] a green check, [LedgerDayMark.missed] a
/// voided ring, [LedgerDayMark.today] a ring in the ink with its letter firm,
/// [LedgerDayMark.upcoming] a dot. Read only (a day is changed on the page it
/// summarises). One node for a screen reader: its [label] and each day's name
/// with how it stands. [letters] and [names] start where the week does (Monday
/// by default).
///
/// ```dart
/// LedgerWeekStrip(days: const [LedgerDayMark.kept, LedgerDayMark.kept, LedgerDayMark.missed, LedgerDayMark.today, LedgerDayMark.upcoming, LedgerDayMark.upcoming, LedgerDayMark.upcoming], label: 'Morning pages this week')
/// ```
class LedgerWeekStrip extends StatelessWidget {
  /// A week of [days].
  const LedgerWeekStrip({
    required this.days,
    this.letters = _letters,
    this.names = _names,
    this.label = 'This week',
    super.key,
  });

  /// Each day's mark, Monday first.
  final List<LedgerDayMark> days;

  /// The capital under each day.
  final List<String> letters;

  /// Each day's name, spoken.
  final List<String> names;

  /// What the week is of, spoken first.
  final String label;

  static const List<String> _letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const List<String> _names = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static String _how(LedgerDayMark mark) => switch (mark) {
    LedgerDayMark.kept => 'kept',
    LedgerDayMark.missed => 'missed',
    LedgerDayMark.today => 'today, still to do',
    LedgerDayMark.upcoming => 'to come',
  };

  @override
  Widget build(BuildContext context) {
    assert(days.length == 7, 'a week has seven days');
    assert(letters.length == 7 && names.length == 7, 'seven of each');
    final t = context.ledgerTheme;
    return Semantics(
      label: label,
      value: [for (var i = 0; i < 7; i++) '${names[i]} ${_how(days[i])}']
          .join(', '),
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: _gap,
        children: [
          for (var i = 0; i < 7; i++)
            SizedBox(
              width: _column,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: _lift,
                children: [
                  SizedBox.square(
                    dimension: _mark,
                    child: days[i] == LedgerDayMark.kept
                        ? const LedgerCheck(value: true, size: _mark)
                        : CustomPaint(
                            painter: _MarkPainter(
                              days[i],
                              ring: t.borderStrong,
                              ink: t.textPrimary,
                              faint: t.textTertiary,
                            ),
                          ),
                  ),
                  Text(
                    letters[i],
                    textScaler: TextScaler.noScaling,
                    style: t.tag.colored(
                      days[i] == LedgerDayMark.today
                          ? t.textPrimary
                          : t.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // DERIVED (the source's habits are a heatmap): each day a column as wide
  // as its 20 mark, its letter centred 6 under, 34 apart (14 between), so
  // the first mark stands on the strip's start, not 5 in.
  static const double _column = _mark;
  static const double _mark = 20;
  static const double _lift = 6;
  static const double _gap = 14;
}

class _MarkPainter extends CustomPainter {
  _MarkPainter(
    this.mark, {
    required this.ring,
    required this.ink,
    required this.faint,
  });

  final LedgerDayMark mark;
  final Color ring;
  final Color ink;
  final Color faint;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    switch (mark) {
      case LedgerDayMark.kept:
        break;
      case LedgerDayMark.missed:
        canvas
          ..drawCircle(c, r - .75, line..color = ring)
          ..drawLine(
            c + Offset(-r * .45, r * .45),
            c + Offset(r * .45, -r * .45),
            line
              ..color = faint
              ..strokeWidth = 1.25
              ..strokeCap = StrokeCap.round,
          );
      case LedgerDayMark.today:
        canvas
          ..drawCircle(c, r - .75, line..color = ink)
          ..drawCircle(c, 2, Paint()..color = ink);
      case LedgerDayMark.upcoming:
        canvas.drawCircle(c, 1.75, Paint()..color = faint);
    }
  }

  @override
  bool shouldRepaint(_MarkPainter old) =>
      old.mark != mark ||
      old.ring != ring ||
      old.ink != ink ||
      old.faint != faint;
}

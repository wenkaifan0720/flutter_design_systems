import 'dart:ui' show SemanticsRole;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../internal/paint.dart';
import '../../theme.dart';

/// One event in a [CivicTimeline]: what happened ([title]), when ([date]),
/// and anything more ([child]: a sentence, a document's link, an action).
@immutable
class CivicTimelineEntry {
  /// An event.
  const CivicTimelineEntry({
    required this.title,
    required this.date,
    this.child,
  });

  /// What happened: Application received, Permit approved.
  final String title;

  /// When, in words: 3 November 2026, 10:42am.
  final String date;

  /// What more there is to say or do.
  final Widget? child;
}

/// A record's history, newest first: each event's title in bold, its date
/// under it, then what it means, down an ink rule at the start edge with a
/// solid square mark at each event (each has happened); where things stand
/// now is the first.
///
/// A screen reader reads it as a list, each event one item: its title, its
/// date, then its words.
///
/// Reads [CivicStyle]'s edge (the rule), fill (the marks) and textStyle
/// (the titles): its `style:`, then [CivicThemeData.timelineStyle].
///
/// ```dart
/// CivicTimeline(
///   entries: [
///     CivicTimelineEntry(
///       title: 'Proof of address checked',
///       date: '5 November 2026',
///     ),
///     CivicTimelineEntry(
///       title: 'Application received',
///       date: '3 November 2026',
///       child: Text('We will check it within 10 working days.'),
///     ),
///   ],
/// )
/// ```
class CivicTimeline extends StatelessWidget {
  /// A history of [entries], newest first.
  const CivicTimeline({super.key, required this.entries, this.style});

  /// The events, newest first.
  final List<CivicTimelineEntry> entries;

  /// Overrides for this timeline's look.
  final CivicStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final text = context.civicText;
    final direction = Directionality.of(context);
    final so = RawStyleOf([style, t.timelineStyle], const {});
    final titles = text.label.merge(so.textStyle);
    return Semantics(
      role: SemanticsRole.list,
      explicitChildNodes: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (i, entry) in entries.indexed)
            Semantics(
              role: SemanticsRole.listItem,
              container: true,
              child: CustomPaint(
                painter: _Gutter(
                  last: i == entries.length - 1,
                  rule: so.edge ?? t.rule,
                  mark: so.fill ?? t.action,
                  direction: direction,
                  // The mark sits on the title's first line.
                  markCentre: MediaQuery.textScalerOf(context)
                      .scale((titles.fontSize ?? 0) * (titles.height ?? 1) / 2),
                ),
                child: Padding(
                  padding: EdgeInsetsDirectional.only(
                    start: _gutter,
                    bottom: i == entries.length - 1 ? 0 : CivicSpacing.s32,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(entry.title, style: titles),
                      const SizedBox(height: CivicSpacing.s4),
                      Text(entry.date, style: text.caption),
                      if (entry.child case final child?) ...[
                        const SizedBox(height: CivicSpacing.s8),
                        DefaultTextStyle.merge(style: text.body, child: child),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// The room at the start for the rule and the marks.
  static const double _gutter = CivicSpacing.s40;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('entries', entries.length))
      ..add(
        DiagnosticsProperty<CivicStyle>('style', style, defaultValue: null),
      );
  }
}

class _Gutter extends CustomPainter {
  _Gutter({
    required this.last,
    required this.rule,
    required this.mark,
    required this.direction,
    required this.markCentre,
  });

  final bool last;
  final Color rule;
  final Color mark;
  final TextDirection direction;
  final double markCentre;

  static const double _mark = CivicSpacing.s16;

  @override
  void paint(Canvas canvas, Size size) {
    const half = _mark / 2;
    final x = direction == TextDirection.ltr ? half : size.width - half;
    // The rule joins this event's mark to the next one's, under the words.
    if (!last) {
      canvas.drawRect(
        Rect.fromLTRB(
          x - CivicMetrics.edge / 2,
          markCentre,
          x + CivicMetrics.edge / 2,
          size.height + markCentre,
        ),
        Paint()..color = rule,
      );
    }
    final box = Rect.fromCenter(
      center: Offset(x, markCentre),
      width: _mark,
      height: _mark,
    );
    canvas.drawOval(box, Paint()..color = mark);
  }

  @override
  bool shouldRepaint(_Gutter old) =>
      old.last != last ||
      old.rule != rule ||
      old.mark != mark ||
      old.direction != direction ||
      old.markCentre != markCentre;
}

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../chrome_metrics.dart';
import '../format.dart';
import '../internal/controls.dart';
import '../internal/field.dart';
import '../localizations.dart';
import '../theme.dart';
import 'pressable.dart';
import 'tag.dart';

/// The audit log's measure: the time column (scaled with the text so a
/// stamp never wraps), the air after it, and a row's vertical padding.
abstract final class _ActivityMetrics {
  static const double timeColumn = 92;
  static const double gap = 10;
  static const double pad = 7;
  static const double dot = 6;
}

/// Minimal's audit trail — what happened to a record and when, newest
/// first: one [MinimalActivity] per row, a mono time column on the left, the
/// event in the ink, hairlines between (the last entry draws none, as a
/// list's last row). It holds the page's measure (it is not full-bleed).
/// When any entry has a [MinimalActivity.tone], every entry keeps the dot's
/// slot, so the events start on one keyline. An empty log prints
/// [emptyLabel] in the faint ink.
///
/// ```dart
/// MinimalTimeline(entries: [MinimalActivity(at: DateTime(2026, 8, 28, 7, 12), text: 'Marked done')])
/// ```
class MinimalTimeline extends StatelessWidget {
  /// A log of [entries], newest first as given.
  const MinimalTimeline({super.key, required this.entries, this.emptyLabel});

  /// The entries, in the order they print.
  final List<MinimalActivity> entries;

  /// What an empty log says, in the faint ink.
  final String? emptyLabel;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    if (entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: _ActivityMetrics.pad),
        child: Text(
          emptyLabel ?? MinimalLocalizations.of(context).noActivity,
          style: t.bodySmall.c(t.mutedForeground),
        ),
      );
    }
    return _DotSlot(
      kept: entries.any((entry) => entry.tone != null),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...entries.take(entries.length - 1),
          _LastEntry(child: entries.last),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<MinimalActivity>('entries', entries))
      ..add(StringProperty('emptyLabel', emptyLabel, defaultValue: null));
  }
}

/// Marks a log's last entry, which draws no rule under it.
class _LastEntry extends InheritedWidget {
  const _LastEntry({required super.child});

  static bool marks(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_LastEntry>() != null;

  @override
  bool updateShouldNotify(_LastEntry oldWidget) => false;
}

/// Whether the entries of a log keep a dot's slot before their words.
class _DotSlot extends InheritedWidget {
  const _DotSlot({required this.kept, required super.child});

  final bool kept;

  static bool keptIn(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_DotSlot>()?.kept ?? false;

  @override
  bool updateShouldNotify(_DotSlot oldWidget) => kept != oldWidget.kept;
}

/// One event in a [MinimalTimeline]: when it happened (printed as a mono
/// stamp, `28 Aug 07:12`), what happened, and optionally who did it and
/// a quiet [detail] (`· note added`). [tone] marks an event with a status
/// dot (a failure, a completion). [onPressed] opens the event.
///
/// An event that sets a figure (a date, an amount, an id) passes the words
/// as [text] and the figure as [figure], which prints after them in the
/// mono face at the event's size: `set it due` `25 Sep`. Never type a
/// figure into [text], where it would print in the body face.
///
/// The time is data, never read off a clock: pass the moment the event
/// was recorded. [stamp] overrides the printed stamp (`Today`, `2026`).
///
/// ```dart
/// MinimalActivity(at: DateTime(2026, 8, 27, 7, 40), text: 'Marked done', detail: 'note added')
/// ```
class MinimalActivity extends StatelessWidget {
  /// An entry of a [MinimalTimeline].
  const MinimalActivity({
    super.key,
    required this.at,
    required this.text,
    this.figure,
    this.actor,
    this.detail,
    this.tone,
    this.stamp,
    this.onPressed,
    this.focusNode,
    this.autofocus = false,
  });

  /// When it happened.
  final DateTime at;

  /// What happened.
  final String text;

  /// A figure the event set, printed after [text] in the mono face with
  /// tabular figures: the `25 Sep` of `set it due 25 Sep`.
  final String? figure;

  /// Who did it, printed first at medium weight: `Ana marked done`.
  final String? actor;

  /// A quiet tail after the event: `note added`.
  final String? detail;

  /// A status dot before the event. In a [MinimalTimeline] where any entry
  /// has one, an entry without keeps its slot empty.
  final MinimalTone? tone;

  /// The printed time; null prints [MinimalFormat.stamp] of [at].
  final String? stamp;

  /// Opens the entry; null leaves it a plain row.
  final VoidCallback? onPressed;

  /// {@macro minimal.focusNode}
  final FocusNode? focusNode;

  /// {@macro minimal.autofocus}
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final scaler = MediaQuery.textScalerOf(context);
    final when = stamp ?? MinimalFormat.stamp(at);
    final actor = this.actor;
    final detail = this.detail;
    final figure = this.figure;
    final tone = this.tone;
    final slot = tone != null || _DotSlot.keptIn(context);
    final event = t.bodySmall;
    // Data, written left to right whatever the line's direction
    // (`28 Aug 09:06` keeps its order in Arabic), at its column's start.
    final stampText = Text(
      when,
      style: t.mono.c(t.mutedForeground),
      textDirection: TextDirection.ltr,
      textAlign: Directionality.of(context) == TextDirection.rtl
          ? TextAlign.right
          : TextAlign.left,
      maxLines: 1,
      overflow: TextOverflow.clip,
      softWrap: false,
    );
    final eventText = Text.rich(
      TextSpan(
        children: [
          // The dot rides the first line, centred on it; in a log
          // with dots, an entry without one keeps its slot empty.
          if (slot)
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(
                  end: MinimalSpacing.s8,
                ),
                child: tone == null
                    ? const SizedBox.square(dimension: _ActivityMetrics.dot)
                    : Container(
                        width: _ActivityMetrics.dot,
                        height: _ActivityMetrics.dot,
                        decoration: BoxDecoration(
                          color: t.tone(tone).indicator,
                          shape: BoxShape.circle,
                        ),
                      ),
              ),
            ),
          if (actor != null)
            TextSpan(text: '$actor ', style: t.bodySmall.medium),
          TextSpan(text: text, style: event),
          if (figure != null) ...[
            TextSpan(text: ' ', style: event),
            TextSpan(
              text: figure,
              style: t.mono.copyWith(
                fontSize: event.fontSize,
                height: event.height,
                color: event.color,
              ),
            ),
          ],
          // The dot holds to the word before it, so a wrapped
          // detail never starts its line with the dot.
          if (detail != null)
            TextSpan(
              text: ' · $detail',
              style: t.bodySmall.c(t.mutedForeground),
            ),
        ],
      ),
    );
    // From 160% text the stamp stands over its event rather than
    // squeeze it into what the grown time column leaves.
    final stacked = scaler.scale(10) / 10 >= MinimalChromeMetrics.rowStackScale;
    final row = Container(
      // An entry that opens stands at least the tap floor (40 at a finger),
      // its lines centred in it.
      constraints: onPressed == null
          ? null
          : BoxConstraints(minHeight: minimalTapFloor(context)),
      alignment: onPressed == null ? null : AlignmentDirectional.centerStart,
      padding: const EdgeInsets.symmetric(vertical: _ActivityMetrics.pad),
      decoration: _LastEntry.marks(context)
          ? null
          : BoxDecoration(border: Border(bottom: t.rule)),
      // The 12 px stamp and the 13 px event share the first line's
      // baseline, whatever the type scale.
      child: stacked
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [stampText, eventText],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                SizedBox(
                  width: scaler.scale(_ActivityMetrics.timeColumn),
                  child: stampText,
                ),
                const MinimalGap(_ActivityMetrics.gap),
                Expanded(child: eventText),
              ],
            ),
    );
    final what = figure == null ? text : '$text $figure';
    final announced = [when, ?actor, what, ?detail].join(', ');
    if (onPressed == null) {
      return Semantics(
        container: true,
        label: announced,
        child: ExcludeSemantics(child: row),
      );
    }
    return MinimalPressable(
      focusNode: focusNode,
      autofocus: autofocus,
      onPressed: onPressed,
      shape: t.shapes.mark,
      // Reaching past the words, the ring stays inside the reach, clear of
      // a card's edge.
      outset: MinimalFieldMetrics.rowReach,
      focusInside: true,
      semanticLabel: announced,
      child: ExcludeSemantics(child: row),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<DateTime>('at', at))
      ..add(StringProperty('text', text))
      ..add(StringProperty('figure', figure, defaultValue: null))
      ..add(StringProperty('actor', actor, defaultValue: null))
      ..add(StringProperty('detail', detail, defaultValue: null))
      ..add(EnumProperty<MinimalTone>('tone', tone, defaultValue: null))
      ..add(StringProperty('stamp', stamp, defaultValue: null))
      ..add(ObjectFlagProperty<VoidCallback>.has('onPressed', onPressed))
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'));
  }
}

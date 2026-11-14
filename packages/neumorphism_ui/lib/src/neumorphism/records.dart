// Records a page reads rather than works: a timeline of stops on an engraved line, a list of terms and their details,
// a meter in a groove, and a page's whole status (loading, failed, done) in one widget.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'controls.dart';
import 'frames.dart';
import 'internal/geometry.dart';
import 'knobs.dart';
import 'layout.dart';
import 'localizations.dart';
import 'ornaments.dart';
import 'rows.dart';
import 'tell.dart';
import 'chrome.dart';
import 'theme.dart';

/// One stop of a [NeumorphicTimeline]: when, what, a line more, and whether it is behind, current or ahead.
///
/// ```dart
/// NeumorphicTimelineStop(time: '19:45', title: 'Doors open', state: NeumorphicStepStatus.live)
/// ```
@immutable
class NeumorphicTimelineStop {
  /// A stop named [title].
  const NeumorphicTimelineStop({
    required this.title,
    this.time,
    this.body,
    this.state = NeumorphicStepStatus.past,
  });

  /// What happened, or happens.
  final String title;

  /// When, as the caller words it.
  final String? time;

  /// A line more under the title.
  final String? body;

  /// Behind, current or ahead.
  final NeumorphicStepStatus state;
}

/// What happened in order: each stop a dot on one engraved line, the current one in the pigment, those ahead an
/// open ring. A screen reader hears each stop's state with its words.
///
/// ```dart
/// NeumorphicTimeline(stops: [NeumorphicTimelineStop(time: '18:00', title: 'Booked'), NeumorphicTimelineStop(time: '19:45', title: 'Seated', state: NeumorphicStepStatus.live)])
/// ```
class NeumorphicTimeline extends StatelessWidget {
  /// A timeline of [stops], first to last.
  const NeumorphicTimeline({super.key, required this.stops, this.label});

  /// The stops, in order.
  final List<NeumorphicTimelineStop> stops;

  /// What a screen reader calls the whole.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final c = t.colors;
    final words = NeumorphicLocalizations.of(context);
    final flat = NeumorphicFlatScope.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: label,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < stops.length; i++)
            Builder(
              builder: (context) {
                final stop = stops[i];
                final live = stop.state == NeumorphicStepStatus.live;
                // The dot stands on the middle of the stop's first line at the reader's size, and grows with it as
                // the kit's glyphs do (to 1.5): at 17 it sat over a time set at twice the size.
                final first = stop.time != null
                    ? t.textTheme.micro
                    : t.textTheme.body;
                final scaler = MediaQuery.textScalerOf(context);
                final fontSize = first.fontSize ?? 14;
                final grown = scaler.scale(fontSize);
                final spoken = switch (stop.state) {
                  NeumorphicStepStatus.past => words.done,
                  NeumorphicStepStatus.live => words.current,
                  NeumorphicStepStatus.next => words.upcoming,
                };
                return MergeSemantics(
                  child: Semantics(
                    value: spoken,
                    child: CustomPaint(
                      painter: _TimelineRail(
                        colors: c,
                        state: stop.state,
                        first: i == 0,
                        last: i == stops.length - 1,
                        flat: flat,
                        rtl: rtl,
                        dotY: 8 + grown * (first.height ?? 1.2) / 2,
                        k: (grown / fontSize).clamp(1.0, 1.5),
                      ),
                      child: Padding(
                        padding: EdgeInsetsDirectional.only(
                          start: _TimelineRail.gutter,
                          top: 8,
                          bottom: i == stops.length - 1 ? 0 : 16,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (stop.time != null)
                              Text(
                                stop.time!,
                                style: t.textTheme.micro.tabular.copyWith(
                                  color: live ? c.pigmentInk : c.inkTertiary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            Text(
                              stop.title,
                              style: t.textTheme.body.copyWith(
                                color: switch (stop.state) {
                                  NeumorphicStepStatus.live => c.pigmentInk,
                                  NeumorphicStepStatus.past => c.ink,
                                  NeumorphicStepStatus.next => c.inkSecondary,
                                },
                                fontWeight: live
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                              ),
                            ),
                            if (stop.body != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                stop.body!,
                                style: t.textTheme.caption.copyWith(
                                  color: c.inkSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _TimelineRail extends CustomPainter {
  const _TimelineRail({
    required this.colors,
    required this.state,
    required this.first,
    required this.last,
    required this.flat,
    required this.rtl,
    required this.dotY,
    required this.k,
  });

  /// The words start this far in: the line and its dots stand in the gap.
  static const gutter = 32.0;
  static const _x = 11.0;

  final NeumorphicColors colors;
  final NeumorphicStepStatus state;
  final bool first, last, flat, rtl;

  /// Where the dot stands, down the stop: the middle of its first line.
  final double dotY;

  /// How much the dot has grown with the words.
  final double k;

  @override
  void paint(Canvas canvas, Size size) {
    final x = rtl ? size.width - _x : _x;
    final c = colors;
    // The engraved line: a crease and its lit edge, as the look's rules are, stood on end.
    void line(double from, double to) {
      if (to <= from) return;
      canvas.drawRect(
        Rect.fromLTWH(x - 1, from, 1, to - from),
        neumorphicFillPaint(flat ? c.quiet : c.crease),
      );
      if (!flat) {
        canvas.drawRect(
          Rect.fromLTWH(x, from, 1, to - from),
          neumorphicFillPaint(c.rim),
        );
      }
    }

    if (!first) line(0, dotY - 8 * k);
    if (!last) line(dotY + 8 * k, size.height);
    final mid = Offset(x, dotY);
    switch (state) {
      case NeumorphicStepStatus.past:
        canvas.drawCircle(mid, 5 * k, neumorphicFillPaint(c.inkTertiary));
      case NeumorphicStepStatus.live:
        canvas.drawCircle(mid, 7 * k, neumorphicFillPaint(c.pigment));
        canvas.drawCircle(mid, 2.5 * k, neumorphicFillPaint(c.onPigment));
      case NeumorphicStepStatus.next:
        canvas.drawCircle(
          mid,
          4.5 * k,
          neumorphicStrokePaint(c.inkTertiary, 2),
        );
    }
  }

  @override
  bool shouldRepaint(_TimelineRail old) =>
      old.colors != colors ||
      old.state != state ||
      old.first != first ||
      old.last != last ||
      old.flat != flat ||
      old.rtl != rtl ||
      old.dotY != dotY ||
      old.k != k;
}

/// One term and its details in a [NeumorphicDescriptionList].
@immutable
class NeumorphicDescription {
  /// [term] described by [details].
  const NeumorphicDescription(this.term, this.details, {this.live = false});

  /// What is described.
  final String term;

  /// What it is.
  final String details;

  /// Whether the details are live: pigment words.
  final bool live;
}

/// Terms and their details, a ruled row each, the details bold at the end; when the two can't share a line the
/// details drop under the term. For a record's facts: an order, a booking, a device.
///
/// ```dart
/// NeumorphicDescriptionList([NeumorphicDescription('Table', '12'), NeumorphicDescription('Guests', '4')])
/// ```
class NeumorphicDescriptionList extends StatelessWidget {
  /// A list of [items].
  const NeumorphicDescriptionList(this.items, {super.key, this.label});

  /// The terms and their details, in order.
  final List<NeumorphicDescription> items;

  /// What a screen reader calls the whole.
  final String? label;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    explicitChildNodes: true,
    label: label,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < items.length; i++)
          MergeSemantics(
            child: NeumorphicKvRow(
              items[i].term,
              items[i].details,
              isFirst: i == 0,
              live: items[i].live,
            ),
          ),
      ],
    ),
  );
}

/// A measure inside a known range (a battery, a quota, a reading): a groove filled to the value, notches at [low]
/// and [high], the fill in the pigment while the value sits on [optimum]'s side of them and in the ink past them,
/// with the reading said in words as well. For a task's progress, use [NeumorphicLinearProgressIndicator].
///
/// ```dart
/// NeumorphicMeter(label: 'Storage', value: 42, max: 50, high: 45, valueLabel: '42 of 50 GB')
/// ```
class NeumorphicMeter extends StatelessWidget {
  /// A meter named [label] at [value] between [min] and [max].
  const NeumorphicMeter({
    super.key,
    required this.label,
    required this.value,
    this.min = 0,
    this.max = 1,
    this.low,
    this.high,
    this.optimum,
    this.valueLabel,
  }) : assert(max > min);

  /// What it measures.
  final String label;

  /// The reading.
  final double value;

  /// The range's ends.
  final double min, max;

  /// Below this the reading is low; null: no low end.
  final double? low;

  /// Above this the reading is high; null: no high end.
  final double? high;

  /// Where the reading is best; null: between [low] and [high].
  final double? optimum;

  /// The reading in words; null: a percentage of the range.
  final String? valueLabel;

  /// Whether the reading is outside the good range, per [low], [high] and [optimum].
  bool get outOfRange {
    final lo = low ?? min, hi = high ?? max;
    final best = optimum ?? (lo + hi) / 2;
    final region = best < lo ? -1 : (best > hi ? 1 : 0);
    final at = value < lo ? -1 : (value > hi ? 1 : 0);
    return at != region;
  }

  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final c = t.colors;
    final words = NeumorphicLocalizations.of(context);
    double at(double v) => ((v - min) / (max - min)).clamp(0.0, 1.0);
    final reading = valueLabel ?? words.formatPercent(at(value));
    final off = outOfRange;
    return Semantics(
      container: true,
      label: label,
      value: reading,
      hint: off ? words.outOfRange : null,
      child: ExcludeSemantics(
        child: NeumorphicColumn(
          gap: 8,
          children: [
            NeumorphicSplit(
              start: Text(label, style: t.textTheme.body),
              end: Text(
                reading,
                style: t.textTheme.caption.tabular.copyWith(
                  color: off ? c.ink : c.inkSecondary,
                  fontWeight: off ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            SizedBox(
              height: 10,
              width: double.infinity,
              child: CustomPaint(
                painter: _MeterPainter(
                  colors: c,
                  elevation: t.elevation,
                  border: t.shapes.capsule,
                  value: at(value),
                  marks: [
                    if (low != null) at(low!),
                    if (high != null) at(high!),
                  ],
                  off: off,
                  flat: NeumorphicFlatScope.of(context),
                  rtl: Directionality.of(context) == TextDirection.rtl,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MeterPainter extends CustomPainter {
  const _MeterPainter({
    required this.colors,
    required this.elevation,
    required this.border,
    required this.value,
    required this.marks,
    required this.off,
    required this.flat,
    required this.rtl,
  });
  final NeumorphicColors colors;
  final NeumorphicElevation elevation;
  final OutlinedBorder border;
  final double value;
  final List<double> marks;
  final bool off, flat, rtl;

  @override
  void paint(Canvas canvas, Size size) {
    final box = Offset.zero & size;
    final shape = border.getOuterPath(box.deflate(.75));
    neumorphicPaintPressed(
      canvas,
      shape,
      colors,
      light: (const Offset(-1, -1), 2),
      dark: (const Offset(1, 1), 2),
      flat: flat,
      elevation: elevation,
    );
    // The fill ends round, as the groove it lies in does: a square end read as a cut stick. It is the groove's floor
    // where it reaches, under the groove's own shade in its colour's tones: laid over the groove, it stood fuller than
    // the groove beside it. Painted before the mirror, so its light stays top-left.
    final reach = value * size.width;
    if (reach > 0) {
      final colour = off ? colors.ink : colors.pigment;
      final span = Rect.fromLTWH(
        rtl ? size.width - reach : 0,
        0,
        reach,
        size.height,
      );
      canvas.save();
      canvas.clipRRect(
        RRect.fromRectAndRadius(
          span,
          Radius.circular(math.min(size.height, reach) / 2),
        ),
      );
      neumorphicPaintPressed(
        canvas,
        shape,
        colors,
        light: (const Offset(-1, -1), 2),
        dark: (const Offset(1, 1), 2),
        tone: colour,
        face: cssLinear(span, 90, [colour, colour]),
        flat: flat,
        elevation: elevation,
      );
      canvas.restore();
    }
    canvas.save();
    canvas.clipPath(shape);
    if (rtl) {
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
    }
    // The notches: a crease across the groove, the lit edge after it.
    for (final m in marks) {
      final x = (m * size.width).roundToDouble();
      canvas.drawRect(
        Rect.fromLTWH(x - 1, 0, 1.5, size.height),
        neumorphicFillPaint(colors.ground),
      );
      canvas.drawRect(
        Rect.fromLTWH(x + .5, 0, 1, size.height),
        neumorphicFillPaint(flat ? colors.quiet : colors.crease),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MeterPainter old) =>
      old.colors != colors ||
      old.elevation != elevation ||
      old.border != border ||
      old.value != value ||
      old.off != off ||
      old.flat != flat ||
      old.rtl != rtl ||
      old.marks.length != marks.length ||
      [for (var i = 0; i < marks.length; i++) old.marks[i] != marks[i]]
          .any((d) => d);
}

/// Which status a [NeumorphicStatusView] shows.
enum NeumorphicStatusKind {
  /// The page's data is on its way.
  loading,

  /// It could not load.
  error,

  /// The task is done.
  success,
}

/// A page's whole status in one place: loading (the look's mark), failed (what happened, a way to try again) or done
/// (a pressed check, what next). The three states compose [NeumorphicLoadingState], [NeumorphicErrorState] and
/// [NeumorphicSuccessState]; use those directly when a page only ever shows one.
///
/// ```dart
/// NeumorphicStatusView.error(title: 'Could not load', message: 'Check your connection.', onAction: retry)
/// ```
class NeumorphicStatusView extends StatelessWidget {
  /// A status view showing [status].
  const NeumorphicStatusView({
    super.key,
    required this.status,
    this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  /// The loading status: the mark, and [title] and [message] when given.
  const NeumorphicStatusView.loading({super.key, this.title, this.message})
    : status = NeumorphicStatusKind.loading,
      actionLabel = null,
      onAction = null;

  /// The failed status: [title], [message], and Try again (or [actionLabel]) calling [onAction].
  const NeumorphicStatusView.error({
    super.key,
    required String this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  }) : status = NeumorphicStatusKind.error;

  /// The done status: [title], [message], and [actionLabel] calling [onAction].
  const NeumorphicStatusView.success({
    super.key,
    this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  }) : status = NeumorphicStatusKind.success;

  /// Which status it shows.
  final NeumorphicStatusKind status;

  /// Its heading.
  final String? title;

  /// A line more.
  final String? message;

  /// The action's words.
  final String? actionLabel;

  /// The action: retry, or go on.
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final words = NeumorphicLocalizations.of(context);
    switch (status) {
      case NeumorphicStatusKind.loading:
        if (title == null && message == null) {
          return const NeumorphicLoadingState();
        }
        return Semantics(
          liveRegion: true,
          label: title ?? words.loading,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const ExcludeSemantics(child: NeumorphicMark()),
                  if (title != null) ...[
                    const SizedBox(height: 16),
                    ExcludeSemantics(
                      child: Text(
                        title!,
                        textAlign: TextAlign.center,
                        style: t.textTheme.value,
                      ),
                    ),
                  ],
                  if (message != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      message!,
                      textAlign: TextAlign.center,
                      style: t.textTheme.caption,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      case NeumorphicStatusKind.error:
        return NeumorphicErrorState(
          title: title ?? words.error,
          message: message,
          onRetry: onAction,
          retryLabel: actionLabel,
        );
      case NeumorphicStatusKind.success:
        return NeumorphicSuccessState(
          title: title ?? words.done,
          message: message,
          action: actionLabel == null || onAction == null
              ? null
              : Center(
                  widthFactor: 1,
                  child: NeumorphicButton(actionLabel!, onPressed: onAction),
                ),
        );
    }
  }
}

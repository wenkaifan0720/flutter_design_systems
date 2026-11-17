/// A span along a ruled track, in Ledger's hand, over ui_core's
/// [DesignRangeSlider].
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../chrome_metrics.dart';
import '../../internal/face.dart';
import '../../theme.dart';

/// A span's two values, low and high: ui_core's [DesignRangeValues].
typedef LedgerRangeValues = DesignRangeValues;

/// A span between two values (an amount from and to, a range of dates by
/// day) set along the slider's ruled track: the ink rule between the two
/// knobs, the dot leader outside them, each knob a ring of the ink holding
/// the paper, flat on the rule. Over it the [label] in the small capitals
/// and the span in the mono, its [unit] after it. Drag a knob, or tap the
/// track to bring the nearer one; the arrow keys step the focused knob,
/// which takes the accountant's double rule under it; a knob a pointer is
/// over darkens its paper, a held one sinks a pixel. The knobs keep
/// [minGap] apart; [divisions] snaps them and ticks the track. Each knob's
/// target is the tap floor; a screen reader hears each knob by its own
/// label and value. A null [onChanged] dims it.
///
/// ```dart
/// LedgerRangeSlider(label: 'Amount', values: const LedgerRangeValues(20, 180), max: 500, format: (v) => '\$${v.round()}', onChanged: (v) {})
/// ```
class LedgerRangeSlider extends StatelessWidget {
  /// A span at [values] between [min] and [max].
  const LedgerRangeSlider({
    required this.label,
    required this.values,
    required this.onChanged,
    this.onChangeEnd,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.minGap = 0,
    this.format,
    this.unit,
    this.startLabel,
    this.endLabel,
    super.key,
  }) : assert(min < max),
       assert(divisions == null || divisions > 0),
       assert(minGap >= 0);

  /// What it sets: printed over the track and spoken.
  final String label;

  /// The span chosen.
  final LedgerRangeValues values;

  /// Called as a knob moves; null dims the slider.
  final ValueChanged<LedgerRangeValues>? onChanged;

  /// Called when a drag or a key press settles.
  final ValueChanged<LedgerRangeValues>? onChangeEnd;

  /// The lowest value.
  final double min;

  /// The highest value.
  final double max;

  /// How many steps the range is cut into; null is continuous.
  final int? divisions;

  /// The least the two knobs keep apart.
  final double minGap;

  /// How a value's figure prints, in the line and to a screen reader.
  final String Function(double value)? format;

  /// The word after the span ("days").
  final String? unit;

  /// What a screen reader calls the lower knob; null: ui_core's word.
  final String? startLabel;

  /// What a screen reader calls the upper knob; null: ui_core's word.
  final String? endLabel;

  String _figure(double v) =>
      format?.call(v) ??
      (v == v.roundToDouble() || max - min >= 10
          ? '${v.round()}'
          : v.toStringAsFixed(1));

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ObjectFlagProperty<Object?>.has('format', format));
    properties
      ..add(StringProperty('label', label))
      ..add(DiagnosticsProperty<LedgerRangeValues>('values', values))
      ..add(
        ObjectFlagProperty<ValueChanged<LedgerRangeValues>>.has(
          'onChanged',
          onChanged,
        ),
      )
      ..add(
        ObjectFlagProperty<ValueChanged<LedgerRangeValues>>.has(
          'onChangeEnd',
          onChangeEnd,
        ),
      )
      ..add(DoubleProperty('min', min))
      ..add(DoubleProperty('max', max))
      ..add(IntProperty('divisions', divisions, defaultValue: null))
      ..add(DoubleProperty('minGap', minGap))
      ..add(StringProperty('unit', unit, defaultValue: null))
      ..add(StringProperty('startLabel', startLabel, defaultValue: null))
      ..add(StringProperty('endLabel', endLabel, defaultValue: null));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final live = onChanged != null;
    final floor = DesignTapTargets.of(context).floorOn();
    final side = floor.height < _strip ? _strip : floor.height;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Opacity(
      opacity: live ? 1 : _off,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: ExcludeSemantics(
                  child: Text(
                    label.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.label.colored(t.textSecondary),
                  ),
                ),
              ),
              ExcludeSemantics(
                child: Text.rich(
                  TextSpan(
                    // The span reads low to high in either direction.
                    text:
                        '${_figure(values.start)} – '
                        '${_figure(values.end)}',
                    style: t.amount.colored(t.textPrimary),
                    children: [
                      if (unit != null)
                        TextSpan(
                          text: ' $unit',
                          style: t.bodySmall.colored(t.textSecondary),
                        ),
                    ],
                  ),
                  maxLines: 1,
                ),
              ),
            ],
          ),
          Semantics(
            label: label,
            container: true,
            child: DesignRangeSlider(
              values: values,
              onChanged: onChanged,
              onChangeEnd: onChangeEnd,
              min: min,
              max: max,
              divisions: divisions,
              minGap: minGap,
              startLabel: startLabel,
              endLabel: endLabel,
              semanticFormatterCallback: (v) =>
                  unit == null ? _figure(v) : '${_figure(v)} $unit',
              thumbSize: Size(side, side),
              trackBuilder: (context, track) => SizedBox(
                height: side,
                child: CustomPaint(
                  painter: _Span(
                    start: track.start,
                    end: track.end,
                    rtl: rtl,
                    divisions: divisions,
                    rule: t.textPrimary,
                    dots: t.textTertiary,
                    tick: t.borderStrong,
                  ),
                ),
              ),
              thumbBuilder: (context, index, states) => _Knob(states: states),
            ),
          ),
        ],
      ),
    );
  }

  static const double _strip = LedgerLayout.minHitTarget;
  static const double _off = .45;
}

/// A knob: the paper in a ring of the ink, 22 across; darker paper under a
/// pointer, a pixel down while held, the double rule under it with focus.
class _Knob extends StatelessWidget {
  const _Knob({required this.states});

  final Set<WidgetState> states;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final hovered = states.contains(WidgetState.hovered);
    final pressed =
        states.contains(WidgetState.pressed) ||
        states.contains(WidgetState.dragged);
    final focused = states.contains(WidgetState.focused);
    return Center(
      child: LedgerEase(
        value: pressed ? LedgerChromeMetrics.pressSink : 0,
        builder: (context, sink, child) =>
            Transform.translate(offset: Offset(0, sink), child: child),
        child: LedgerFace(
          style: LedgerFaceStyle(
            ink: t.textPrimary,
            ground: BoxDecoration(
              color: hovered || pressed ? t.selectedFill : t.surface,
              shape: BoxShape.circle,
              border: Border.all(color: t.textPrimary, width: 1.5),
            ),
          ),
          builder: (context, s, _) => SizedBox(
            width: _knob,
            height: _knob + 2 * _ruleRoom,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                SizedBox(
                  width: _knob,
                  height: _knob,
                  child: DecoratedBox(decoration: s.ground),
                ),
                // The accountant's double rule under the knob with focus.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: LedgerEase(
                    value: focused ? 1 : 0,
                    builder: (context, shown, _) => Opacity(
                      opacity: shown.clamp(0.0, 1.0),
                      child: Column(
                        spacing: LedgerChromeMetrics.focusGap,
                        children: [
                          for (var i = 0; i < 2; i++)
                            SizedBox(
                              height: LedgerChromeMetrics.focusRing,
                              width: _knob,
                              child: ColoredBox(color: t.textPrimary),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static const double _knob = 22;
  static const double _ruleRoom =
      2 * LedgerChromeMetrics.focusGap + 2 * LedgerChromeMetrics.focusRing + 2;
}

/// The track: the ink rule between the knobs, the leader outside them and
/// the ticks of a stepped one.
class _Span extends CustomPainter {
  _Span({
    required this.start,
    required this.end,
    required this.rtl,
    required this.divisions,
    required this.rule,
    required this.dots,
    required this.tick,
  });

  final double start;
  final double end;
  final bool rtl;
  final int? divisions;
  final Color rule;
  final Color dots;
  final Color tick;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    double at(double f) => (rtl ? 1 - f : f) * size.width;
    final a = at(start);
    final b = at(end);
    canvas.drawLine(
      Offset(a, y),
      Offset(b, y),
      Paint()
        ..color = rule
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
    final dot = Paint()..color = dots;
    const pitch = LedgerChromeMetrics.leaderPitch;
    final lo = a < b ? a : b;
    final hi = a < b ? b : a;
    for (var d = lo - _clear; d >= -_knob; d -= pitch) {
      canvas.drawCircle(Offset(d, y), .9, dot);
    }
    for (var d = hi + _clear; d <= size.width + _knob; d += pitch) {
      canvas.drawCircle(Offset(d, y), .9, dot);
    }
    final n = divisions;
    if (n != null && n <= 20) {
      final ticks = Paint()
        ..color = tick
        ..strokeWidth = 1;
      for (var i = 0; i <= n; i++) {
        final tx = at(i / n);
        canvas.drawLine(Offset(tx, y + 15), Offset(tx, y + 19), ticks);
      }
    }
  }

  // The leader starts clear of a knob's ring, and runs under the track's
  // ends to where a knob at the end would stand.
  static const double _clear = 16;
  static const double _knob = 11;

  @override
  bool shouldRepaint(_Span old) =>
      old.start != start ||
      old.end != end ||
      old.rtl != rtl ||
      old.divisions != divisions ||
      old.rule != rule ||
      old.dots != dots ||
      old.tick != tick;
}

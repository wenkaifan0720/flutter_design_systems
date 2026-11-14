import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../chrome_metrics.dart';
import '../../theme.dart';

/// A value along a ruled track: the ink rule up to the knob, the dot leader
/// beyond it, the knob a ring of the ink holding the raised paper, flat on
/// the rule (no shadow: only a slip of paper rises). Over it the [label] in
/// the small capitals and the value in the mono, its [unit] after it. Tap the track or drag the knob; the arrow keys step it (one
/// division, or a tenth of the range), Home and End jump to the ends, and a
/// screen reader steps it by its increase and decrease. [divisions] snaps the
/// value and ticks the track like a ruler. [format] prints a value's figure
/// (`20`, `70%`), for the line and for a screen reader alike; without it a
/// range of 0 to 1 prints as a percent and any other as the value, rounded
/// to a whole number (a tenth on a span under 10). A null [onChanged] dims it.
/// The touch strip is 44 tall.
///
/// ```dart
/// LedgerSlider(label: 'Monthly budget', value: budget, min: 100, max: 2000, divisions: 19, format: (v) => '\$${v.round()}', onChanged: (v) => setState(() => budget = v))
/// ```
class LedgerSlider extends StatefulWidget {
  /// A slider at [value] between [min] and [max].
  const LedgerSlider({
    required this.label,
    required this.value,
    this.onChanged,
    this.onChangeEnd,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.format,
    this.unit,
    this.showLabel = true,
    this.focusNode,
    this.autofocus = false,
    super.key,
  }) : assert(max > min, 'a slider has a range'),
       assert(divisions == null || divisions > 0, 'divisions are at least one');

  /// What it sets: printed over the track unless [showLabel] is false, and
  /// always spoken.
  final String label;

  /// Whether [label] is printed (a slider beside its own words says it
  /// only to a screen reader).
  final bool showLabel;

  /// The value chosen.
  final double value;

  /// Called as the value moves; null dims the slider.
  final ValueChanged<double>? onChanged;

  /// Called with the value when a drag or a key press settles.
  final ValueChanged<double>? onChangeEnd;

  /// The lowest value.
  final double min;

  /// The highest value.
  final double max;

  /// How many steps the range is cut into; null is continuous.
  final int? divisions;

  /// How a value's figure prints, in the line and to a screen reader.
  final String Function(double value)? format;

  /// The word after the figure ("pages"), spoken with every value.
  final String? unit;

  /// The control's focus; null keeps one of its own. The caller disposes
  /// the node it gives.
  final FocusNode? focusNode;

  /// Whether it takes focus when it first appears.
  final bool autofocus;

  @override
  State<LedgerSlider> createState() => _LedgerSliderState();
}

class _LedgerSliderState extends State<LedgerSlider> {
  FocusNode? _ownFocus;
  FocusNode get _focus =>
      widget.focusNode ?? (_ownFocus ??= FocusNode(debugLabel: 'LedgerSlider'));

  /// The value while a finger holds the knob.
  double? _held;
  bool _keyboard = false;

  bool get _live => widget.onChanged != null;
  double get _value =>
      (_held ?? widget.value).clamp(widget.min, widget.max).toDouble();
  double get _range => widget.max - widget.min;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
  }

  @override
  void didUpdateWidget(LedgerSlider old) {
    super.didUpdateWidget(old);
    if (old.focusNode != widget.focusNode) {
      (old.focusNode ?? _ownFocus)?.removeListener(_onFocus);
      _focus.addListener(_onFocus);
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    _ownFocus?.dispose();
    super.dispose();
  }

  void _onFocus() => setState(
    () => _keyboard =
        _focus.hasFocus &&
        FocusManager.instance.highlightMode == FocusHighlightMode.traditional,
  );

  double _snap(double v) {
    final n = widget.divisions;
    final clamped = v.clamp(widget.min, widget.max).toDouble();
    if (n == null) return clamped;
    final step = _range / n;
    return widget.min + (((clamped - widget.min) / step).round() * step);
  }

  void _move(double v) {
    final next = _snap(v);
    if (next == _value && _held != null) return;
    setState(() => _held = next);
    widget.onChanged?.call(next);
  }

  void _settle() {
    final v = _value;
    setState(() => _held = null);
    widget.onChangeEnd?.call(v);
  }

  /// A key press or a screen reader's step: it moves and settles at once.
  void _nudge(double steps, {bool tenths = false}) {
    if (!_live) return;
    final each = tenths || widget.divisions == null
        ? _range / 10
        : _range / widget.divisions!;
    final v = _snap(_value + steps * each);
    widget.onChanged?.call(v);
    widget.onChangeEnd?.call(v);
  }

  void _jump(double v) {
    if (!_live) return;
    widget.onChanged?.call(v);
    widget.onChangeEnd?.call(v);
  }

  double _valueAt(double dx, double width, bool rtl) {
    final span = width - 2 * _Track.knob;
    var f = ((dx - _Track.knob) / span).clamp(0.0, 1.0);
    if (rtl) f = 1 - f;
    return widget.min + f * _range;
  }

  /// A value's figure, as a screen reader hears it and the line prints it.
  String _figure(double v) {
    final format = widget.format;
    if (format != null) return format(v);
    if (widget.min == 0 && widget.max == 1) return '${(v * 100).round()}%';
    return v == v.roundToDouble() || _range >= 10
        ? '${v.round()}'
        : v.toStringAsFixed(1);
  }

  String _spoken(double v) =>
      widget.unit == null ? _figure(v) : '${_figure(v)} ${widget.unit}';

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final value = _value;
    final fraction = (value - widget.min) / _range;
    // A pointer over the track or the knob shows the click cursor while the
    // slider is live; an off one defers to what it stands on.
    final strip = LayoutBuilder(
      builder: (context, box) => MouseRegion(
        cursor: _live ? SystemMouseCursors.click : MouseCursor.defer,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: _live
              ? (d) {
                  _focus.requestFocus();
                  _move(_valueAt(d.localPosition.dx, box.maxWidth, rtl));
                }
              : null,
          onTapUp: _live ? (_) => _settle() : null,
          onTapCancel: _live ? _settle : null,
          onHorizontalDragStart: _live
              ? (d) => _move(_valueAt(d.localPosition.dx, box.maxWidth, rtl))
              : null,
          onHorizontalDragUpdate: _live
              ? (d) => _move(_valueAt(d.localPosition.dx, box.maxWidth, rtl))
              : null,
          onHorizontalDragEnd: _live ? (_) => _settle() : null,
          child: SizedBox(
            height: _Track.strip,
            width: double.infinity,
            child: CustomPaint(
              painter: _Track(
                fraction: fraction,
                rtl: rtl,
                divisions: widget.divisions,
                rule: t.textPrimary,
                dots: t.textTertiary,
                tick: t.borderStrong,
                paper: t.surface,
                focus: _keyboard ? t.textPrimary : null,
              ),
            ),
          ),
        ),
      ),
    );
    final keys = <LogicalKeyboardKey, VoidCallback>{
      LogicalKeyboardKey.arrowRight: () => _nudge(rtl ? -1 : 1),
      LogicalKeyboardKey.arrowUp: () => _nudge(1),
      LogicalKeyboardKey.arrowLeft: () => _nudge(rtl ? 1 : -1),
      LogicalKeyboardKey.arrowDown: () => _nudge(-1),
      LogicalKeyboardKey.pageUp: () => _nudge(1, tenths: true),
      LogicalKeyboardKey.pageDown: () => _nudge(-1, tenths: true),
      LogicalKeyboardKey.home: () => _jump(widget.min),
      LogicalKeyboardKey.end: () => _jump(widget.max),
    };
    return Opacity(
      opacity: _live ? 1 : _off,
      child: Semantics(
        slider: true,
        enabled: _live,
        label: widget.label,
        value: _spoken(value),
        increasedValue: _spoken(_snap(value + _stepOf())),
        decreasedValue: _spoken(_snap(value - _stepOf())),
        onIncrease: _live ? () => _nudge(1) : null,
        onDecrease: _live ? () => _nudge(-1) : null,
        child: ExcludeSemantics(
          child: Focus(
            focusNode: _focus,
            autofocus: widget.autofocus,
            includeSemantics: false,
            canRequestFocus: _live,
            skipTraversal: !_live,
            onKeyEvent: (node, event) {
              if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
                return KeyEventResult.ignored;
              }
              final act = keys[event.logicalKey];
              if (!_live || act == null) return KeyEventResult.ignored;
              act();
              return KeyEventResult.handled;
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.showLabel)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Expanded(
                        child: Text(
                          widget.label.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.label.colored(t.textSecondary),
                        ),
                      ),
                      Text.rich(
                        TextSpan(
                          text: _figure(value),
                          style: t.amount.colored(t.textPrimary),
                          children: [
                            if (widget.unit != null)
                              TextSpan(
                                text: ' ${widget.unit}',
                                style: t.bodySmall.colored(t.textSecondary),
                              ),
                          ],
                        ),
                        maxLines: 1,
                      ),
                    ],
                  ),
                strip,
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// What one step of the screen reader's increase moves.
  double _stepOf() =>
      widget.divisions == null ? _range / 10 : _range / widget.divisions!;

  static const double _off = .45;
}

/// The track, its dot leader, the ticks of a stepped one and the knob, in
/// one pass. DERIVED (the source draws no slider): the ink rule 2 thick, the
/// leader's dots 5 apart as the leader tiles them, the knob 22 across.
class _Track extends CustomPainter {
  _Track({
    required this.fraction,
    required this.rtl,
    required this.divisions,
    required this.rule,
    required this.dots,
    required this.tick,
    required this.paper,
    required this.focus,
  });

  /// How far along the range the knob stands.
  final double fraction;
  final bool rtl;
  final int? divisions;
  final Color rule;
  final Color dots;
  final Color tick;
  final Color paper;

  /// The double rule under the knob while the keyboard holds focus.
  final Color? focus;

  /// The touch strip's height and the knob's radius.
  static const double strip = LedgerLayout.minHitTarget;
  static const double knob = 11;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    final span = size.width - 2 * knob;
    double at(double f) => knob + (rtl ? 1 - f : f) * span;
    final x = at(fraction);
    final rulePaint = Paint()
      ..color = rule
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    // The ink rule from the track's start up to the knob, the leader beyond.
    final from = rtl ? size.width : 0.0;
    canvas.drawLine(Offset(from, y), Offset(x, y), rulePaint);
    final dot = Paint()..color = dots;
    const pitch = LedgerChromeMetrics.leaderPitch;
    final reach = rtl ? 0.0 : size.width;
    final step = rtl ? -pitch : pitch;
    for (
      var d = x + (rtl ? -1 : 1) * (knob + 5);
      rtl ? d >= reach : d <= reach;
      d += step
    ) {
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
    // The knob: the paper in a ring of the ink, flat on the rule (only a slip
    // of paper rises in Ledger, never a control).
    canvas
      ..drawCircle(Offset(x, y), knob, Paint()..color = paper)
      ..drawCircle(
        Offset(x, y),
        knob - .75,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = rule,
      );
    if (focus != null) {
      // The accountant's double rule under the knob, as under any focused
      // Ledger control.
      const line = LedgerChromeMetrics.focusRing;
      const gap = LedgerChromeMetrics.focusGap;
      final ink = Paint()..color = focus!;
      final top = y + knob + 2 * gap;
      for (final at in [top, top + line + gap]) {
        canvas.drawRect(Rect.fromLTWH(x - knob, at, 2 * knob, line), ink);
      }
    }
  }

  @override
  bool shouldRepaint(_Track old) =>
      old.fraction != fraction ||
      old.rtl != rtl ||
      old.divisions != divisions ||
      old.rule != rule ||
      old.dots != dots ||
      old.tick != tick ||
      old.paper != paper ||
      old.focus != focus;
}

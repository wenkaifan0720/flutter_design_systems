import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../internal/bidi.dart';
import '../../internal/field_frame.dart';
import '../../internal/slider_parts.dart';
import '../../theme.dart';

// A range slider's caller holds its two values.
export 'package:ui_core/ui_core.dart' show RawRangeValues;

// A value in the reader's figures: whole, or to one place.
String _figure(BuildContext context, double v) =>
    RawWidgetsLocalizations.of(context)
        .formatDecimal(v, fractionDigits: v == v.roundToDouble() ? 0 : 1);

/// A value set along a scale where the exact figure matters less than
/// where it falls: a well-edged track filled in the action colour up to a
/// thumb in the button's material, the value always written over it in
/// words ([valueLabel]: "40 minutes"), so no one has to judge it by eye.
/// Where the exact figure matters, ask for it in a [CivicNumberField].
///
/// A press on the track moves the thumb there; a drag moves it along. The
/// arrow keys step it ([divisions], else a hundredth of the range), Page Up
/// and Page Down by a tenth, Home and End to the ends; a screen reader
/// hears its label and the value in [valueLabel]'s words.
///
/// Reads [CivicStyle]'s fill (the thumb) and edge (the thumb's solid edge)
/// by state: its `style:`, then [CivicThemeData.sliderStyle]. The track and
/// the focus are the look's.
///
/// ```dart
/// CivicSlider(
///   labelText: 'Text size',
///   value: size,
///   min: 100,
///   max: 200,
///   divisions: 4,
///   valueLabel: (v) => '${v.round()}%',
///   onChanged: (v) => setState(() => size = v),
/// )
/// ```
class CivicSlider extends StatefulWidget {
  /// A slider.
  const CivicSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.labelText,
    this.helperText,
    this.errorText,
    this.isQuestion = false,
    this.valueLabel,
    this.showLimits = true,
    this.onChangeStart,
    this.onChangeEnd,
    this.focusNode,
    this.autofocus = false,
    this.style,
  }) : assert(min < max, 'a slider has a range'),
       assert(divisions == null || divisions > 0);

  /// The value.
  final double value;

  /// Called with each new value; null disables the slider.
  final ValueChanged<double>? onChanged;

  /// The least value.
  final double min;

  /// The greatest value.
  final double max;

  /// How many steps the range snaps to; null: none.
  final int? divisions;

  /// What it sets; a screen reader hears it.
  final String? labelText;

  /// How to use it.
  final String? helperText;

  /// What to fix; null while the value is fine.
  final String? errorText;

  /// Whether the label is a question of its own on a page that asks a few
  /// (How much do you read a week?): it stands at a fieldset's legend size, as a
  /// question's does; else in the body's weight, as every field's label.
  final bool isQuestion;

  /// The value in words, shown and said; null: the figure, in the reader's
  /// figures.
  final String Function(double value)? valueLabel;

  /// Whether the least and greatest values stand under the track's ends.
  final bool showLimits;

  /// Called as a change begins (a press, a drag, a key).
  final ValueChanged<double>? onChangeStart;

  /// Called as a change ends.
  final ValueChanged<double>? onChangeEnd;

  /// {@macro civic.focusNode}
  final FocusNode? focusNode;

  /// {@macro civic.autofocus}
  final bool autofocus;

  /// Overrides for the thumb's look.
  final CivicStyle? style;

  @override
  State<CivicSlider> createState() => _CivicSliderState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DoubleProperty('value', value))
      ..add(
        ObjectFlagProperty<ValueChanged<double>>.has('onChanged', onChanged),
      )
      ..add(DoubleProperty('min', min))
      ..add(DoubleProperty('max', max))
      ..add(IntProperty('divisions', divisions, defaultValue: null))
      ..add(StringProperty('labelText', labelText, defaultValue: null))
      ..add(
        DiagnosticsProperty<CivicStyle>('style', style, defaultValue: null),
      );
  }
}

class _CivicSliderState extends State<CivicSlider> {
  FocusNode? _own;
  FocusNode get _focus => widget.focusNode ?? (_own ??= FocusNode());
  bool _dragging = false;

  // Where the press or drag last moved it: its end is told this, though the
  // page has not yet rebuilt with it.
  double? _moved;

  @override
  void dispose() {
    _own?.dispose();
    super.dispose();
  }

  String _say(double v) => widget.valueLabel?.call(v) ?? _figure(context, v);

  double _snap(double v) {
    final n = widget.divisions;
    final c = v.clamp(widget.min, widget.max).toDouble();
    if (n == null) return c;
    final step = (widget.max - widget.min) / n;
    return widget.min + ((c - widget.min) / step).round() * step;
  }

  double _at(double dx, double width, bool rtl) {
    final inset = CivicSliderMetrics.thumb.width / 2;
    var f = ((dx - inset) / (width - 2 * inset)).clamp(0.0, 1.0);
    if (rtl) f = 1 - f;
    return _snap(widget.min + f * (widget.max - widget.min));
  }

  void _move(double v) {
    _moved = v;
    if (v != widget.value) widget.onChanged?.call(v);
  }

  void _start(double value) {
    _moved = null;
    widget.onChangeStart?.call(value);
  }

  void _end([double? _]) {
    final end = _moved ?? widget.value;
    _moved = null;
    widget.onChangeEnd?.call(end);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final text = context.civicText;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final live = widget.onChanged != null;
    final value = widget.value.clamp(widget.min, widget.max).toDouble();
    final f = (value - widget.min) / (widget.max - widget.min);
    final hasError = widget.errorText != null;
    final strip = LayoutBuilder(
      builder: (context, box) {
        final width = box.maxWidth;
        final inset = CivicSliderMetrics.thumb.width / 2;
        final x = inset + (rtl ? 1 - f : f) * (width - 2 * inset);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          excludeFromSemantics: true,
          onTapDown: live
              ? (d) {
                  _focus.requestFocus();
                  _start(value);
                  _move(_at(d.localPosition.dx, width, rtl));
                }
              : null,
          onTapUp: live ? (_) => _end() : null,
          onHorizontalDragStart: live
              ? (d) {
                  _focus.requestFocus();
                  setState(() => _dragging = true);
                  _start(value);
                  _move(_at(d.localPosition.dx, width, rtl));
                }
              : null,
          onHorizontalDragUpdate: live
              ? (d) => _move(_at(d.localPosition.dx, width, rtl))
              : null,
          onHorizontalDragEnd: live
              ? (_) {
                  setState(() => _dragging = false);
                  _end();
                }
              : null,
          child: MouseRegion(
            cursor: live ? SystemMouseCursors.click : MouseCursor.defer,
            child: SizedBox(
              height: CivicSliderMetrics.strip,
              width: width,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: CivicTrackPainter(
                        from: 0,
                        to: f,
                        inset: inset,
                        rtl: rtl,
                        well: live ? t.background : t.disabledFill,
                        edge: hasError
                            ? t.danger
                            : live
                            ? t.border
                            : t.textDisabled,
                        fill: live ? t.action : t.textDisabled,
                        ticks: widget.divisions ?? 0,
                        tick: live ? t.textSecondary : t.textDisabled,
                      ),
                    ),
                  ),
                  Positioned(
                    // The thumb's target is a finger's 48, its face in the
                    // middle of it.
                    left: x - CivicSliderMetrics.strip / 2,
                    top: 0,
                    width: CivicSliderMetrics.strip,
                    height: CivicSliderMetrics.strip,
                    child: RawValueHandle(
                      value: value,
                      onChanged: live ? (v) => _move(_snap(v)) : null,
                      min: widget.min,
                      max: widget.max,
                      divisions: widget.divisions,
                      onChangeStart: _start,
                      onChangeEnd: _end,
                      dragging: _dragging,
                      semanticLabel: widget.labelText,
                      semanticFormatterCallback: _say,
                      focusNode: _focus,
                      autofocus: widget.autofocus,
                      minimumSize: const Size.square(CivicSliderMetrics.strip),
                      builder: (context, states) => Center(
                        child: CivicSliderThumb(
                          states: states,
                          styles: [widget.style, t.sliderStyle],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    final reading = ExcludeSemantics(
      child: Text(
        _say(value),
        style: text.headingS.copyWith(
          color: live ? t.textPrimary : t.textDisabled,
        ),
      ),
    );
    final limits = widget.showLimits
        ? ExcludeSemantics(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _say(widget.min),
                    style: text.bodySmall.copyWith(color: t.textSecondary),
                  ),
                ),
                Expanded(
                  child: Text(
                    _say(widget.max),
                    textAlign: TextAlign.end,
                    style: text.bodySmall.copyWith(color: t.textSecondary),
                  ),
                ),
              ],
            ),
          )
        : null;
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [reading, strip, ?limits],
    );
    if (widget.labelText == null &&
        widget.helperText == null &&
        widget.errorText == null) {
      return body;
    }
    return RawInputDecorator(
      labelText: widget.labelText,
      helperText: widget.helperText,
      errorText: widget.errorText,
      enabled: live,
      builder: (context, parts) =>
          CivicFieldFrame(parts: parts, isLegend: widget.isQuestion),
      child: body,
    );
  }
}

/// A range set along a scale: the slider's track filled between two
/// thumbs, the range written over it in words ([valueLabel] at each end:
/// "From £20 to £60"). The thumbs keep at least [minGap] apart.
///
/// Each thumb takes the keys as a slider's does; a screen reader hears
/// each by its own name ([startLabel], [endLabel]) and its value.
///
/// Reads [CivicStyle]'s fill and edge (the thumbs) by state: its `style:`,
/// then [CivicThemeData.sliderStyle].
///
/// ```dart
/// CivicRangeSlider(
///   labelText: 'Monthly cost',
///   values: cost,
///   max: 100,
///   valueLabel: (v) => '£${v.round()}',
///   onChanged: (range) => setState(() => cost = range),
/// )
/// ```
class CivicRangeSlider extends StatelessWidget {
  /// A range slider.
  const CivicRangeSlider({
    super.key,
    required this.values,
    required this.onChanged,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.minGap = 0,
    this.labelText,
    this.helperText,
    this.errorText,
    this.isQuestion = false,
    this.valueLabel,
    this.rangeLabel,
    this.startLabel,
    this.endLabel,
    this.showLimits = true,
    this.onChangeStart,
    this.onChangeEnd,
    this.style,
  }) : assert(min < max, 'a slider has a range');

  /// The range.
  final RawRangeValues values;

  /// Called with each new range; null disables the slider.
  final ValueChanged<RawRangeValues>? onChanged;

  /// The least value.
  final double min;

  /// The greatest value.
  final double max;

  /// How many steps the range snaps to; null: none.
  final int? divisions;

  /// The least distance between the ends.
  final double minGap;

  /// What it sets.
  final String? labelText;

  /// How to use it.
  final String? helperText;

  /// What to fix; null while the range is fine.
  final String? errorText;

  /// Whether the label is a question of its own on a page that asks a few
  /// (How much do you read a week?): it stands at a fieldset's legend size, as a
  /// question's does; else in the body's weight, as every field's label.
  final bool isQuestion;

  /// A value in words, shown and said; null: the figure.
  final String Function(double value)? valueLabel;

  /// The range in words over the track, from each end's words; null: the
  /// reader's "`start` to `end`", each end set apart from the sentence.
  final String Function(String start, String end)? rangeLabel;

  /// What a screen reader calls the lower thumb; null: ui_core's words.
  final String? startLabel;

  /// What a screen reader calls the upper thumb.
  final String? endLabel;

  /// Whether the least and greatest values stand under the track's ends.
  final bool showLimits;

  /// Called as a drag begins.
  final ValueChanged<RawRangeValues>? onChangeStart;

  /// Called as a drag ends.
  final ValueChanged<RawRangeValues>? onChangeEnd;

  /// Overrides for the thumbs' look.
  final CivicStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final text = context.civicText;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final live = onChanged != null;
    String say(double v) => valueLabel?.call(v) ?? _figure(context, v);
    final hasError = errorText != null;
    final slider = RawRangeSlider(
      values: values,
      onChanged: onChanged,
      min: min,
      max: max,
      divisions: divisions,
      minGap: minGap,
      onChangeStart: onChangeStart,
      onChangeEnd: onChangeEnd,
      semanticFormatterCallback: say,
      startLabel: startLabel,
      endLabel: endLabel,
      thumbSize: const Size(48, CivicSliderMetrics.strip),
      trackBuilder: (context, track) => SizedBox(
        height: CivicSliderMetrics.strip,
        child: CustomPaint(
          painter: CivicTrackPainter(
            // The box spans the thumbs' centres; the well runs on under
            // the thumbs to the row's ends.
            from: track.start,
            to: track.end,
            inset: 0,
            overhang: 24,
            rtl: rtl,
            well: live ? t.background : t.disabledFill,
            edge: hasError
                ? t.danger
                : live
                ? t.border
                : t.textDisabled,
            fill: live ? t.action : t.textDisabled,
            ticks: divisions ?? 0,
            tick: live ? t.textSecondary : t.textDisabled,
          ),
        ),
      ),
      thumbBuilder: (context, index, states) => Center(
        child: CivicSliderThumb(states: states, styles: [style, t.sliderStyle]),
      ),
    );
    final start = say(values.start);
    final end = say(values.end);
    // Each end set apart, so an amount keeps its order in a sentence that
    // reads right to left.
    final words =
        rangeLabel?.call(start, end) ??
        RawWidgetsLocalizations.of(context)
            .chartRangeLabel(civicIsolate(start), civicIsolate(end));
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(
          child: Text(
            words,
            style: text.headingS.copyWith(
              color: live ? t.textPrimary : t.textDisabled,
            ),
          ),
        ),
        slider,
        if (showLimits)
          ExcludeSemantics(
            child: Row(
              textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
              children: [
                Expanded(
                  child: Text(
                    say(min),
                    style: text.bodySmall.copyWith(color: t.textSecondary),
                  ),
                ),
                Expanded(
                  child: Text(
                    say(max),
                    textAlign: TextAlign.end,
                    style: text.bodySmall.copyWith(color: t.textSecondary),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
    if (labelText == null && helperText == null && errorText == null) {
      return body;
    }
    return RawInputDecorator(
      labelText: labelText,
      helperText: helperText,
      errorText: errorText,
      enabled: live,
      builder: (context, parts) =>
          CivicFieldFrame(parts: parts, isLegend: isQuestion),
      child: body,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<RawRangeValues>('values', values))
      ..add(
        ObjectFlagProperty<ValueChanged<RawRangeValues>>.has(
          'onChanged',
          onChanged,
        ),
      )
      ..add(DoubleProperty('min', min))
      ..add(DoubleProperty('max', max))
      ..add(StringProperty('labelText', labelText, defaultValue: null))
      ..add(
        DiagnosticsProperty<CivicStyle>('style', style, defaultValue: null),
      );
  }
}

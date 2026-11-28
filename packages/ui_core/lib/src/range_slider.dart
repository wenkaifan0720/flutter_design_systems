/// A range slider, headless: two [RawValueHandle]s on one track that
/// cannot cross. A drag or a press on the track moves the nearer thumb.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'localizations.dart';
import 'value_handle.dart';

/// A range's two ends.
@immutable
class RawRangeValues {
  /// The range from [start] to [end].
  const RawRangeValues(this.start, this.end)
    : assert(start <= end, 'start $start is at most end $end');

  /// Its lower end.
  final double start;

  /// Its upper end.
  final double end;

  @override
  bool operator ==(Object other) =>
      other is RawRangeValues && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'RawRangeValues($start, $end)';
}

/// The track's state, for the look to paint its rail and the filled part.
@immutable
class RawRangeSliderTrackDetails {
  /// The track's state; the slider makes it.
  const RawRangeSliderTrackDetails({
    required this.start,
    required this.end,
    required this.enabled,
  });

  /// Where the lower thumb sits, 0 to 1 from the track's start edge (the
  /// left, or the right in right to left).
  final double start;

  /// Where the upper thumb sits.
  final double end;

  /// Whether the slider takes input.
  final bool enabled;
}

/// A slider of [values] between [min] and [max].
///
/// ```dart
/// RawRangeSlider(values: const RawRangeValues(20, 80), max: 100, onChanged: (values) {}, trackBuilder: (context, track) => const SizedBox(height: 4), thumbBuilder: (context, index, states) => const SizedBox(width: 20, height: 20))
/// ```
class RawRangeSlider extends StatefulWidget {
  /// A range slider at [values].
  const RawRangeSlider({
    super.key,
    required this.values,
    required this.onChanged,
    required this.trackBuilder,
    required this.thumbBuilder,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.minGap = 0,
    this.step,
    this.pageStep,
    this.onChangeStart,
    this.onChangeEnd,
    this.semanticFormatterCallback,
    this.startLabel,
    this.endLabel,
    this.thumbSize = const Size(40, 40),
  }) : assert(min <= max, 'min is at most max'),
       assert(divisions == null || divisions > 0),
       assert(minGap >= 0),
       assert(step == null || step > 0),
       assert(pageStep == null || pageStep > 0);

  /// The range.
  final RawRangeValues values;

  /// A drag's, a key's or a screen reader's new range.
  ///
  /// {@macro design.nullDisables}
  final ValueChanged<RawRangeValues>? onChanged;

  /// Paints the track (full width, centred under the thumbs).
  final Widget Function(BuildContext context, RawRangeSliderTrackDetails track)
  trackBuilder;

  /// Paints thumb `index` (0 the lower, 1 the upper).
  final Widget Function(
    BuildContext context,
    int index,
    Set<WidgetState> states,
  )
  thumbBuilder;

  /// The least value.
  final double min;

  /// The greatest value.
  final double max;

  /// How many steps the range snaps to; null: none.
  final int? divisions;

  /// The least distance between the ends.
  final double minGap;

  /// An arrow's change.
  final double? step;

  /// A page key's change.
  final double? pageStep;

  /// Called when a drag starts.
  final ValueChanged<RawRangeValues>? onChangeStart;

  /// Called when a drag ends.
  final ValueChanged<RawRangeValues>? onChangeEnd;

  /// What a screen reader hears for a value, as
  /// `RangeSlider.semanticFormatterCallback`.
  final String Function(double value)? semanticFormatterCallback;

  /// What a screen reader calls the lower thumb; null:
  /// [RawWidgetsLocalizations.rangeSliderStartLabel].
  final String? startLabel;

  /// What a screen reader calls the upper thumb; null:
  /// [RawWidgetsLocalizations.rangeSliderEndLabel].
  final String? endLabel;

  /// Each thumb's target (its face is centred in it).
  final Size thumbSize;

  @override
  State<RawRangeSlider> createState() => _RawRangeSliderState();

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
      ..add(
        ObjectFlagProperty<
          Widget Function(
            BuildContext context,
            RawRangeSliderTrackDetails track,
          )
        >.has('trackBuilder', trackBuilder),
      )
      ..add(
        ObjectFlagProperty<
          Widget Function(
            BuildContext context,
            int index,
            Set<WidgetState> states,
          )
        >.has('thumbBuilder', thumbBuilder),
      )
      ..add(DoubleProperty('min', min, defaultValue: 0))
      ..add(DoubleProperty('max', max, defaultValue: 1))
      ..add(IntProperty('divisions', divisions, defaultValue: null))
      ..add(DoubleProperty('minGap', minGap, defaultValue: 0))
      ..add(DoubleProperty('step', step, defaultValue: null))
      ..add(DoubleProperty('pageStep', pageStep, defaultValue: null))
      ..add(
        ObjectFlagProperty<ValueChanged<RawRangeValues>>.has(
          'onChangeStart',
          onChangeStart,
        ),
      )
      ..add(
        ObjectFlagProperty<ValueChanged<RawRangeValues>>.has(
          'onChangeEnd',
          onChangeEnd,
        ),
      )
      ..add(
        ObjectFlagProperty<String Function(double value)>.has(
          'semanticFormatterCallback',
          semanticFormatterCallback,
        ),
      )
      ..add(StringProperty('startLabel', startLabel, defaultValue: null))
      ..add(StringProperty('endLabel', endLabel, defaultValue: null))
      ..add(
        DiagnosticsProperty<Size>(
          'thumbSize',
          thumbSize,
          defaultValue: const Size(40, 40),
        ),
      );
  }
}

class _RawRangeSliderState extends State<RawRangeSlider> {
  // Each thumb's node: a press on the track focuses the thumb it moves, so
  // the arrows after it move that thumb.
  final _thumbNodes = [
    FocusNode(debugLabel: 'RawRangeSlider start'),
    FocusNode(debugLabel: 'RawRangeSlider end'),
  ];

  @override
  void dispose() {
    for (final node in _thumbNodes) {
      node.dispose();
    }
    super.dispose();
  }

  int? _dragging;

  // The thumb painted on top where the two meet: the one moved last.
  int _onTop = 1;

  @override
  void didUpdateWidget(RawRangeSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Turned off mid-drag, the slider drops its drag recognizer, which then
    // tells it nothing more: the drag ends here.
    if (widget.onChanged == null) _dragging = null;
  }

  // The drag ends, lifted or cancelled.
  void _endDrag() {
    setState(() => _dragging = null);
    widget.onChangeEnd?.call(widget.values);
  }

  void _moving(int index) {
    if (_onTop != index) setState(() => _onTop = index);
  }

  double get _range => widget.max - widget.min;

  double _fraction(double v) => _range == 0 ? 0 : (v - widget.min) / _range;

  double _snap(double v) {
    final c = v.clamp(widget.min, widget.max);
    final d = widget.divisions;
    if (d == null || d <= 0 || _range == 0) return c;
    final unit = _range / d;
    return widget.min + ((c - widget.min) / unit).round() * unit;
  }

  double _clampThumb(int index, double snapped) {
    final r = widget.values;
    if (index == 0) {
      final hi = (r.end - widget.minGap).clamp(widget.min, widget.max);
      return snapped.clamp(widget.min, hi);
    }
    final lo = (r.start + widget.minGap).clamp(widget.min, widget.max);
    return snapped.clamp(lo, widget.max);
  }

  void _set(int index, double value) {
    final r = widget.values;
    final next = index == 0
        ? RawRangeValues(value, r.end)
        : RawRangeValues(r.start, value);
    if (next != r) widget.onChanged?.call(next);
  }

  void _setFromTrack(int index, double value) =>
      _set(index, _clampThumb(index, _snap(value)));

  // The value under a pointer at [dx] on a track [width] wide.
  double _valueAt(double dx, double width) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final usable = width - widget.thumbSize.width;
    var f = usable <= 0 ? 0.0 : (dx - widget.thumbSize.width / 2) / usable;
    if (rtl) f = 1 - f;
    return widget.min + f.clamp(0.0, 1.0) * _range;
  }

  int _nearer(double v) {
    final r = widget.values;
    final ds = (v - r.start).abs();
    final de = (v - r.end).abs();
    if (ds != de) return ds < de ? 0 : 1;
    return v < r.start ? 0 : 1;
  }

  @override
  Widget build(BuildContext context) {
    assert(
      widget.values.start >= widget.min && widget.values.end <= widget.max,
      'values ${widget.values} are between min ${widget.min} and max '
      '${widget.max}',
    );
    final enabled = widget.onChanged != null;
    final r = widget.values;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final thumb = widget.thumbSize;
    return LayoutBuilder(
      builder: (context, box) {
        final width = box.maxWidth;
        final usable = width - thumb.width;
        double left(double v) {
          final f = _fraction(v);
          return (rtl ? 1 - f : f) * usable;
        }

        Widget handle(int index) => Positioned(
          // Keyed, so a thumb keeps its focus as the order changes.
          key: ValueKey(index),
          left: left(index == 0 ? r.start : r.end),
          top: 0,
          width: thumb.width,
          height: thumb.height,
          child: RawValueHandle(
            focusNode: _thumbNodes[index],
            value: index == 0 ? r.start : r.end,
            min: widget.min,
            max: widget.max,
            divisions: widget.divisions,
            clampValue: (value) => _clampThumb(index, value),
            step: widget.step,
            pageStep: widget.pageStep,
            dragging: _dragging == index,
            // While the other thumb is dragged, the pointer holds it here too.
            mouseCursor: _dragging != null && _dragging != index
                ? SystemMouseCursors.grabbing
                : null,
            minimumSize: thumb,
            semanticLabel: index == 0
                ? widget.startLabel ??
                      RawWidgetsLocalizations.of(context).rangeSliderStartLabel
                : widget.endLabel ??
                      RawWidgetsLocalizations.of(context).rangeSliderEndLabel,
            semanticFormatterCallback: widget.semanticFormatterCallback,
            onChanged: enabled
                ? (v) {
                    _moving(index);
                    _set(index, v);
                  }
                : null,
            builder: (context, states) =>
                widget.thumbBuilder(context, index, states),
          ),
        );

        // The track's press and drag are the pointer's: a screen reader
        // reaches the two thumbs, each a labelled slider, so the track
        // adds no unlabelled node of its own. A press on it moves a thumb
        // (the click cursor), the thumbs grab, and a drag holds (grabbing)
        // wherever the pointer goes over the slider.
        final track = !enabled
            ? SystemMouseCursors.basic
            : _dragging != null
            ? SystemMouseCursors.grabbing
            : SystemMouseCursors.click;
        return MouseRegion(
          cursor: track,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            excludeFromSemantics: true,
            onHorizontalDragStart: !enabled
                ? null
                : (d) {
                    final v = _valueAt(d.localPosition.dx, width);
                    final i = _nearer(v);
                    setState(() {
                      _dragging = i;
                      _onTop = i;
                    });
                    widget.onChangeStart?.call(widget.values);
                    _setFromTrack(i, v);
                  },
            onHorizontalDragUpdate: !enabled
                ? null
                : (d) {
                    final i = _dragging;
                    if (i != null) {
                      _setFromTrack(i, _valueAt(d.localPosition.dx, width));
                    }
                  },
            onHorizontalDragEnd: !enabled ? null : (_) => _endDrag(),
            onHorizontalDragCancel: !enabled ? null : _endDrag,
            onTapUp: !enabled
                ? null
                : (d) {
                    final v = _valueAt(d.localPosition.dx, width);
                    final i = _nearer(v);
                    _moving(i);
                    _thumbNodes[i].requestFocus();
                    _setFromTrack(i, v);
                  },
            child: SizedBox(
              height: thumb.height,
              width: width,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: thumb.width / 2,
                    right: thumb.width / 2,
                    top: 0,
                    bottom: 0,
                    // The track spans the row; its own height, centred.
                    child: Center(
                      child: SizedBox(
                        width: double.infinity,
                        child: ExcludeSemantics(
                          child: widget.trackBuilder(
                            context,
                            RawRangeSliderTrackDetails(
                              start: _fraction(r.start),
                              end: _fraction(r.end),
                              enabled: enabled,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // The one moved last on top, so a thumb dragged over the
                  // other stays in front of it.
                  handle(1 - _onTop),
                  handle(_onTop),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

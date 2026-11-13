/// A range slider, headless: two [DesignValueHandle]s on one track that
/// cannot cross. A drag or a press on the track moves the nearer thumb.
library;

import 'package:flutter/widgets.dart';

import 'localizations.dart';
import 'value_handle.dart';

/// A range's two ends.
@immutable
class DesignRangeValues {
  /// The range from [start] to [end].
  const DesignRangeValues(this.start, this.end);

  /// Its lower end.
  final double start;

  /// Its upper end.
  final double end;

  @override
  bool operator ==(Object other) =>
      other is DesignRangeValues && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'DesignRangeValues($start, $end)';
}

/// The track's state, for the look to paint its rail and the filled part.
@immutable
class DesignRangeTrack {
  /// The track's state; the slider makes it.
  const DesignRangeTrack({
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
/// DesignRangeSlider(values: const DesignRangeValues(20, 80), max: 100, onChanged: (values) {}, trackBuilder: (context, track) => const SizedBox(height: 4), thumbBuilder: (context, index, states) => const SizedBox(width: 20, height: 20))
/// ```
class DesignRangeSlider extends StatefulWidget {
  /// A range slider at [values].
  const DesignRangeSlider({
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
    this.thumbSize = const Size(44, 44),
  });

  /// The range.
  final DesignRangeValues values;

  /// A drag's, a key's or a screen reader's new range; null disables it.
  final ValueChanged<DesignRangeValues>? onChanged;

  /// Paints the track (full width, centred under the thumbs).
  final Widget Function(BuildContext context, DesignRangeTrack track)
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
  final ValueChanged<DesignRangeValues>? onChangeStart;

  /// Called when a drag ends.
  final ValueChanged<DesignRangeValues>? onChangeEnd;

  /// What a screen reader hears for a value, as
  /// `RangeSlider.semanticFormatterCallback`.
  final String Function(double value)? semanticFormatterCallback;

  /// What a screen reader calls the lower thumb; null:
  /// [DesignLocalizations.rangeSliderStartLabel].
  final String? startLabel;

  /// What a screen reader calls the upper thumb; null:
  /// [DesignLocalizations.rangeSliderEndLabel].
  final String? endLabel;

  /// Each thumb's target (its face is centred in it).
  final Size thumbSize;

  @override
  State<DesignRangeSlider> createState() => _DesignRangeSliderState();
}

class _DesignRangeSliderState extends State<DesignRangeSlider> {
  int? _dragging;

  // The thumb painted on top where the two meet: the one moved last.
  int _onTop = 1;

  void _moving(int index) {
    if (_onTop != index) setState(() => _onTop = index);
  }

  double get _range => widget.max - widget.min;

  double _fraction(double v) => _range == 0 ? 0 : (v - widget.min) / _range;

  double _snap(double v) {
    final c = v.clamp(widget.min, widget.max);
    final d = widget.divisions;
    if (d == null || d <= 0) return c;
    final unit = _range / d;
    return widget.min + ((c - widget.min) / unit).round() * unit;
  }

  void _set(int index, double v) {
    final change = widget.onChanged;
    if (change == null) return;
    final r = widget.values;
    final lo = r.start + widget.minGap;
    final hi = r.end - widget.minGap;
    final next = index == 0
        ? DesignRangeValues(
            _snap(v).clamp(widget.min, hi < widget.min ? widget.min : hi),
            r.end,
          )
        : DesignRangeValues(
            r.start,
            _snap(v).clamp(lo > widget.max ? widget.max : lo, widget.max),
          );
    if (next != r) change(next);
  }

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
          child: DesignValueHandle(
            value: index == 0 ? r.start : r.end,
            min: widget.min,
            max: widget.max,
            divisions: widget.divisions,
            step: widget.step,
            pageStep: widget.pageStep,
            dragging: _dragging == index,
            minimumSize: thumb,
            semanticLabel: index == 0
                ? widget.startLabel ??
                      DesignLocalizations.of(context).rangeSliderStartLabel
                : widget.endLabel ??
                      DesignLocalizations.of(context).rangeSliderEndLabel,
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
        // adds no unlabelled node of its own.
        return GestureDetector(
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
                  _set(_dragging!, v);
                },
          onHorizontalDragUpdate: !enabled
              ? null
              : (d) {
                  final i = _dragging;
                  if (i != null) _set(i, _valueAt(d.localPosition.dx, width));
                },
          onHorizontalDragEnd: !enabled
              ? null
              : (_) {
                  setState(() => _dragging = null);
                  widget.onChangeEnd?.call(widget.values);
                },
          onTapUp: !enabled
              ? null
              : (d) {
                  final v = _valueAt(d.localPosition.dx, width);
                  final i = _nearer(v);
                  _moving(i);
                  _set(i, v);
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
                          DesignRangeTrack(
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
        );
      },
    );
  }
}

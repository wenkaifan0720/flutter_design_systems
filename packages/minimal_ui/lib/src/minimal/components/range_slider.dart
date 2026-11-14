/// A range on one track, between two thumbs that cannot cross, painted on
/// ui_core's range slider.
library;

import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../component_themes.dart';
import '../internal/field.dart';
import '../internal/kit_paint.dart';
import '../internal/styled.dart';
import '../localizations.dart';
import '../theme.dart';

// The two ends of a range are ui_core's, exported with the slider so a
// screen names them without a Material import.
export 'package:ui_core/ui_core.dart' show DesignRangeValues;

const double _thumb = 16;
const double _track = 4;
const Size _target = Size(44, 44);

/// A range between two ends: a price band, a time window, an age range. A
/// [MinimalSlider]'s track and thumbs, twice: the 4 px track in the
/// hairline ink, the accent between the two 16 px ringed thumbs, under a
/// label line that prints both ends in mono.
///
/// A drag or a tap on the track moves the nearer thumb; the thumbs never
/// cross (and keep [minGap] apart). Each thumb is its own focus stop and
/// slider for a screen reader (Minimum and Maximum, after [label]); the
/// arrows step it, Page Up and Down take bigger steps, Home and End go to
/// the ends. [divisions] snaps the values and ticks the track. The
/// behaviour is ui_core's ([DesignRangeSlider]); Minimal paints it.
///
/// [style] dresses one slider over `components.slider`, as a slider's does:
/// fill (between the thumbs, and their rings), edge (the rest of the
/// track), foreground (the thumbs' faces), overlay (a held thumb's halo)
/// and shape (the track's outline; a capsule unset).
///
/// ```dart
/// MinimalRangeSlider(label: 'Price', values: const DesignRangeValues(20, 80), min: 0, max: 200, format: (v) => '\$${v.round()}', onChanged: setPrice)
/// ```
class MinimalRangeSlider extends StatelessWidget {
  /// A range slider at [values].
  const MinimalRangeSlider({
    super.key,
    required this.label,
    required this.values,
    this.min = 0,
    this.max = 1,
    this.onChanged,
    this.onChangeEnd,
    this.divisions,
    this.minGap = 0,
    this.format,
    this.unit,
    this.showLabel = true,
    this.style,
  });

  /// What the range sets: printed over the track unless [showLabel] is
  /// false, and the thumbs' names for a screen reader.
  final String label;

  /// The range: ui_core's [DesignRangeValues], its two ends.
  final DesignRangeValues values;

  /// The least value.
  final double min;

  /// The greatest value.
  final double max;

  /// A drag's, a key's or a screen reader's new range; null disables it.
  final ValueChanged<DesignRangeValues>? onChanged;

  /// Called when a drag ends, with the range it left.
  final ValueChanged<DesignRangeValues>? onChangeEnd;

  /// How many steps the range snaps to; null: none.
  final int? divisions;

  /// The least distance between the ends.
  final double minGap;

  /// A value's figure (`$20`, `70%`); unstated, the value rounded to the
  /// span's grain: whole numbers over a span of 10 or more, one decimal
  /// over a span of 1 or more (`0.2–0.6` on the unit range), else two.
  final String Function(double value)? format;

  /// The word after a figure (`km`), in Geist beside the mono figure.
  final String? unit;

  /// Whether the label line prints over the track.
  final bool showLabel;

  /// This slider's style, over `components.slider`.
  final MinimalStyle? style;

  String _figure(double v) {
    final own = format;
    if (own != null) return own(v);
    final span = (max - min).abs();
    if (span >= 10) return '${v.round()}';
    return v.toStringAsFixed(span >= 1 ? 1 : 2);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final words = MinimalLocalizations.of(context);
    final enabled = onChanged != null;
    final layers = <MinimalStyle?>[style, t.components.slider];
    final so = MinimalStyleOf(layers, minimalStates(enabled: enabled));
    final fill = so.fill ?? t.primary;
    final unitWords = unit;

    final slider = DesignRangeSlider(
      values: values,
      min: min,
      max: max,
      divisions: divisions,
      minGap: minGap,
      thumbSize: _target,
      startLabel: '$label, ${words.minimum}',
      endLabel: '$label, ${words.maximum}',
      semanticFormatterCallback: (v) =>
          unitWords == null ? _figure(v) : '${_figure(v)} $unitWords',
      onChanged: onChanged,
      onChangeEnd: onChangeEnd,
      trackBuilder: (context, track) => CustomPaint(
        size: const Size(double.infinity, _track),
        painter: _RangeTrackPainter(
          start: track.start,
          end: track.end,
          rtl: Directionality.of(context) == TextDirection.rtl,
          divisions: divisions,
          rail: so.edge ?? t.border,
          fill: fill,
          tick: t.textTertiary,
          slot: so.shape ?? t.shapes.pill,
          // The thumbs' travel stops half a thumb from the part's edges
          // (_bleed); the rail runs on to the edges, as a slider's does.
          overhang: _thumb / 2,
        ),
      ),
      thumbBuilder: (context, index, states) {
        final ts = MinimalStyleOf(layers, states);
        final ring = t.focusWidth;
        return SizedBox.square(
          dimension: _thumb + 4 + 2 * ring,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (states.down)
                Container(
                  width: _thumb + 8,
                  height: _thumb + 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ts.overlay ?? fill.withValues(alpha: 0.16),
                  ),
                ),
              if (states.ring)
                Container(
                  width: _thumb + 4 + 2 * ring,
                  height: _thumb + 4 + 2 * ring,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: t.ring, width: ring),
                  ),
                ),
              Container(
                width: _thumb,
                height: _thumb,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ts.foreground ?? t.card,
                  border: Border.all(color: fill, width: 1.5),
                ),
              ),
            ],
          ),
        );
      },
    );

    final body = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showLabel)
          ExcludeSemantics(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: t.body,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const MinimalGap(MinimalSpacing.s8),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        // An en dash, unspaced, as every range in the
                        // look prints (12:00–18:00).
                        text:
                            '${_figure(values.start)}–'
                            '${_figure(values.end)}',
                        style: t.monoValue.c(t.mutedForeground),
                      ),
                      if (unitWords != null)
                        TextSpan(
                          text: ' $unitWords',
                          style: t.body.c(t.mutedForeground),
                        ),
                    ],
                  ),
                  maxLines: 1,
                ),
              ],
            ),
          ),
        _bleed(slider),
      ],
    );
    return enabled ? body : Opacity(opacity: 0.45, child: body);
  }
}

/// [slider], ui_core's, whose thumbs' 44 px targets stand inside its box,
/// widened past its column on both sides so a thumb's centre travels from
/// half a thumb inside one edge to half a thumb inside the other, as a
/// [MinimalSlider]'s does: the tracks and the thumbs of every slider in a
/// column then line up. What stands past the column paints but takes no
/// hits (the column's box ends where it ends).
Widget _bleed(Widget slider) {
  final reach = _target.width / 2 - _thumb / 2;
  return SizedBox(
    height: _target.height,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: -reach,
          right: -reach,
          top: 0,
          bottom: 0,
          child: slider,
        ),
      ],
    ),
  );
}

/// The rail, the fill between the thumbs and the division ticks, in one
/// pass; the rail reaches [overhang] past both ends.
class _RangeTrackPainter extends CustomPainter {
  const _RangeTrackPainter({
    required this.start,
    required this.end,
    required this.rtl,
    required this.divisions,
    required this.rail,
    required this.fill,
    required this.tick,
    required this.slot,
    required this.overhang,
  });

  final double start;
  final double end;
  final bool rtl;
  final int? divisions;
  final Color rail;
  final Color fill;
  final Color tick;
  final OutlinedBorder slot;
  final double overhang;

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2;
    double x(double f) => (rtl ? 1 - f : f) * size.width;
    void bar(double a, double b, Color colour) {
      final rect = Rect.fromLTRB(
        a < b ? a : b,
        cy - _track / 2,
        a < b ? b : a,
        cy + _track / 2,
      );
      canvas.drawPath(
        slot.getOuterPath(rect, textDirection: TextDirection.ltr),
        Paint()..color = colour,
      );
    }

    bar(-overhang, size.width + overhang, rail);
    bar(x(start), x(end), fill);
    final steps = divisions;
    if (steps != null && steps > 0 && steps <= 20) {
      for (var i = 0; i <= steps; i++) {
        final f = i / steps;
        // The fill says the range: ticks mark the rail outside it alone,
        // never speckling the accent.
        if (f >= start && f <= end) continue;
        canvas.drawCircle(Offset(x(f), cy), 1, Paint()..color = tick);
      }
    }
  }

  @override
  bool shouldRepaint(_RangeTrackPainter old) =>
      old.start != start ||
      old.end != end ||
      old.rtl != rtl ||
      old.divisions != divisions ||
      old.rail != rail ||
      old.fill != fill ||
      old.slot != slot ||
      old.overhang != overhang;
}

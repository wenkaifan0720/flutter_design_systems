import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../chrome_metrics.dart';
import '../../internal/face.dart';
import '../../internal/key_focus.dart';
import '../../internal/styled.dart';
import '../../theme.dart';
import '../../internal/dim.dart';

/// A slider: a value along a glass tube 6 tall (the prism bar's track in its
/// hairline), filled to the value in accent ink, under a
/// white knob 22 across in the toggle's shadow. Drag it or press where it
/// should stand; the arrow keys move it a step. With [divisions] it stands
/// only on the beads along the tube. Read aloud as an adjustable value named
/// [label], saying [semanticFormatterCallback]'s words for it (the share of the way by
/// default). [onChangeStart] and [onChangeEnd] bracket a drag, a press or
/// a key step, for work that should wait for the hand to lift (saving the
/// value). A null [onChanged] disables the slider.
///
/// ```dart
/// FrostedSlider(value: alertAt, min: 0, max: 100, divisions: 20, label: 'Alert at', semanticFormatterCallback: (v) => '\${v.round()}% of budget', onChanged: setAlertAt, onChangeEnd: saveAlertAt)
/// ```
class FrostedSlider extends StatelessWidget {
  /// Creates a [FrostedSlider].
  const FrostedSlider({
    required this.value,
    required this.onChanged,
    required this.label,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.semanticFormatterCallback,
    this.onChangeStart,
    this.onChangeEnd,
    this.style,
    this.focusNode,
    this.autofocus = false,
    super.key,
  }) : assert(max > min, 'A slider spans some range.'),
       assert(
         divisions == null || divisions > 0,
         'A stepped slider has steps.',
       ),
       assert(
         value >= min && value <= max,
         'A slider\'s value lies between its min and max.',
       );

  /// Where the knob stands, from [min] to [max].
  final double value;

  /// What the slider reports as it moves; null makes it inert.
  final ValueChanged<double>? onChanged;

  /// {@macro frosted.focusNode}
  final FocusNode? focusNode;

  /// {@macro frosted.autofocus}
  final bool autofocus;

  /// The value as a drag, press or key step begins.
  final ValueChanged<double>? onChangeStart;

  /// The value the drag, press or key step ended on: the one to keep.
  final ValueChanged<double>? onChangeEnd;

  /// What a screen reader calls it.
  final String label;

  /// The least value.
  final double min;

  /// The greatest value.
  final double max;

  /// How many equal steps the range is cut into; null for a continuous
  /// one.
  final int? divisions;

  /// The words for a value, as a screen reader reads it; null says the
  /// share of the way. Flutter's `Slider` takes it under this name.
  final String Function(double value)? semanticFormatterCallback;

  /// This slider's own style, over `FrostedThemeData.components.slider`:
  /// the filled run of the track (fill, a flat colour in place of the
  /// signature band), the thumb's colour (foreground), its edge or side and
  /// its shape, each per state (disabled while inert).
  ///
  /// ```dart
  /// FrostedSlider(
  ///   value: volume,
  ///   onChanged: setVolume,
  ///   label: 'Volume',
  ///   style: const FrostedStyle(
  ///     fill: WidgetStatePropertyAll(Color(0xFF5B5BD6)),
  ///   ),
  /// )
  /// ```
  final FrostedStyle? style;

  double get _fraction => ((value - min) / (max - min)).clamp(0.0, 1.0);

  double _at(double fraction) {
    final f = fraction.clamp(0.0, 1.0);
    final steps = divisions;
    final snapped = steps == null ? f : (f * steps).round() / steps;
    return min + (max - min) * snapped;
  }

  String _spoken(double v) =>
      semanticFormatterCallback?.call(v) ??
      '${(((v - min) / (max - min)) * 100).round()}%';

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final live = onChanged != null;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final s = FrostedStyleLayers(style, t.components.slider, {
      if (!live) WidgetState.disabled,
    });
    final active = s.fill ?? t.colorScheme.accentText;
    final thumb = s.shape;
    final cut = thumb is CircleBorder ? null : s.cut(FrostedCorners.full);
    const knob = FrostedChromeMetrics.sliderThumb;
    // The knob is bounded by its shadow and a white reflection on its rim,
    // never a dark traced edge.
    final (thumbEdge, thumbEdges) = s.edgeOf(
      t.glass.rim,
      FrostedStrokes.regular,
    );
    final step = (max - min) / (divisions ?? 20);
    void stepTo(double next) {
      onChangeStart?.call(value);
      onChanged!(next);
      onChangeEnd?.call(next);
    }

    final up = !live || value >= max
        ? null
        : () => stepTo(_at(_fraction + step / (max - min)));
    final down = !live || value <= min
        ? null
        : () => stepTo(_at(_fraction - step / (max - min)));
    final toward = rtl ? down : up;
    final away = rtl ? up : down;
    const trackTop =
        (FrostedChromeMetrics.sliderHeight - FrostedChromeMetrics.sliderTrack) /
        2;
    Widget slider = SizedBox(
      height: FrostedChromeMetrics.sliderHeight,
      child: LayoutBuilder(
        builder: (context, box) {
          final width = box.maxWidth;
          final room = math.max(1.0, width - FrostedChromeMetrics.sliderThumb);
          double fractionAt(double dx) {
            final f = (dx - FrostedChromeMetrics.sliderThumb / 2) / room;
            return rtl ? 1 - f : f;
          }

          final reach = FrostedChromeMetrics.sliderThumb / 2 + room * _fraction;
          final centre = rtl ? width - reach : reach;
          const end = Radius.circular(FrostedChromeMetrics.sliderTrack / 2);
          // The last value reported, for onChangeEnd: the widget's own
          // value is a frame behind while the page rebuilds it.
          var last = value;
          void report(double dx) => onChanged!(last = _at(fractionAt(dx)));
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: live
                ? (d) {
                    onChangeStart?.call(value);
                    report(d.localPosition.dx);
                  }
                : null,
            onTapUp: live ? (_) => onChangeEnd?.call(last) : null,
            onHorizontalDragStart: live
                ? (d) {
                    onChangeStart?.call(value);
                    report(d.localPosition.dx);
                  }
                : null,
            onHorizontalDragUpdate: live
                ? (d) => report(d.localPosition.dx)
                : null,
            onHorizontalDragEnd: live ? (_) => onChangeEnd?.call(last) : null,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // The tracks are paint, which no clearing reaches, and the
                // keyboard's light falls on the knob alone.
                Positioned.fill(
                  top: trackTop,
                  bottom: trackTop,
                  child: FrostedClearing(
                    level: 0,
                    child: FrostedFace(
                      material: FrostedMaterial.paint,
                      radius: const BorderRadius.all(end),
                      color: t.glass.track,
                      ring: t.glass.trackEdge,
                    ),
                  ),
                ),
                PositionedDirectional(
                  start: 0,
                  width: reach,
                  top: trackTop,
                  height: FrostedChromeMetrics.sliderTrack,
                  child: FrostedClearing(
                    level: 0,
                    child: FrostedFace(
                      material: FrostedMaterial.paint,
                      radius: const BorderRadius.all(end),
                      color: active,
                    ),
                  ),
                ),
                if (divisions case final steps?)
                  for (var i = 0; i <= steps; i++)
                    Positioned(
                      left:
                          (rtl ? 1 - i / steps : i / steps) * room +
                          FrostedChromeMetrics.sliderThumb / 2 -
                          FrostedChromeMetrics.sliderBead / 2,
                      top:
                          (FrostedChromeMetrics.sliderHeight -
                              FrostedChromeMetrics.sliderBead) /
                          2,
                      child: SizedBox.square(
                        dimension: FrostedChromeMetrics.sliderBead,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: (i / steps <= _fraction)
                                ? t.glass.plane.withValues(alpha: 0.7)
                                : t.colorScheme.textTertiary.withValues(
                                    alpha: 0.35,
                                  ),
                          ),
                        ),
                      ),
                    ),
                Positioned(
                  left: centre - FrostedChromeMetrics.sliderThumb / 2,
                  top:
                      (FrostedChromeMetrics.sliderHeight -
                          FrostedChromeMetrics.sliderThumb) /
                      2,
                  child: SizedBox.square(
                    dimension: FrostedChromeMetrics.sliderThumb,
                    child: FrostedFace(
                      material: FrostedMaterial.paint,
                      radius: BorderRadius.circular(
                        FrostedStyleLayers.radiusOf(cut, knob, knob / 2),
                      ),
                      shape: cut,
                      // A token theme's dark knob by night (made for a
                      // switch's light ink) takes the ink on the track.
                      color:
                          s.foreground ??
                          (t.colorScheme.toggleKnob.computeLuminance() > .5
                              ? t.colorScheme.toggleKnob
                              : t.colorScheme.textPrimary),
                      edge: thumbEdge,
                      edges: thumbEdges,
                      shadows: t.shadows.toggleKnob,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
    // The pointer's click cursor over the whole slider, track and knob, as
    // a press anywhere on it moves the value; inert, the cursor of what is
    // under it.
    slider = MouseRegion(
      cursor: live ? SystemMouseCursors.click : MouseCursor.defer,
      child: slider,
    );
    slider = FrostedKeyFocus(
      focusNode: focusNode,
      autofocus: autofocus,
      enabled: live,
      radius: FrostedStyleLayers.radiusOf(cut, knob, knob / 2),
      ringInsets: const EdgeInsets.symmetric(
        vertical:
            (FrostedChromeMetrics.sliderHeight -
                FrostedChromeMetrics.sliderThumb) /
            2,
      ),
      keys: {
        if (toward != null) ...{
          LogicalKeyboardKey.arrowRight: toward,
          LogicalKeyboardKey.arrowUp: toward,
        },
        if (away != null) ...{
          LogicalKeyboardKey.arrowLeft: away,
          LogicalKeyboardKey.arrowDown: away,
        },
      },
      child: slider,
    );
    slider = FrostedDim(off: !live, child: slider);
    return Semantics(
      slider: true,
      label: label,
      value: _spoken(value),
      increasedValue: up == null
          ? null
          : _spoken(_at(_fraction + step / (max - min))),
      decreasedValue: down == null
          ? null
          : _spoken(_at(_fraction - step / (max - min))),
      onIncrease: up,
      onDecrease: down,
      enabled: live,
      excludeSemantics: true,
      child: slider,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DoubleProperty('value', value))
      ..add(
        ObjectFlagProperty<ValueChanged<double>>.has('onChanged', onChanged),
      )
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'))
      ..add(
        ObjectFlagProperty<ValueChanged<double>>.has(
          'onChangeStart',
          onChangeStart,
        ),
      )
      ..add(
        ObjectFlagProperty<ValueChanged<double>>.has(
          'onChangeEnd',
          onChangeEnd,
        ),
      )
      ..add(StringProperty('label', label))
      ..add(DoubleProperty('min', min, defaultValue: 0))
      ..add(DoubleProperty('max', max, defaultValue: 1))
      ..add(IntProperty('divisions', divisions, defaultValue: null))
      ..add(
        ObjectFlagProperty<String Function(double value)>.has(
          'semanticFormatterCallback',
          semanticFormatterCallback,
        ),
      )
      ..add(
        DiagnosticsProperty<FrostedStyle>('style', style, defaultValue: null),
      );
  }
}

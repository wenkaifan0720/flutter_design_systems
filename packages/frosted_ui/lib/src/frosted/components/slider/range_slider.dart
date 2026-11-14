import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../chrome_metrics.dart';
import '../../internal/face.dart';
import '../../internal/panel.dart';
import '../../theme.dart';
import '../../internal/dim.dart';

export 'package:ui_core/ui_core.dart' show DesignRangeValues;

/// A range on a track with two knobs (Material's RangeSlider): the
/// [FrostedSlider]'s track and white knobs, the stretch between the knobs
/// in the signature band. Each knob is a Tab stop of its own (named
/// [startLabel] and [endLabel]); the arrows step it, Page Up and Down take
/// big steps, Home and End go to the ends; a press on the track moves the
/// nearer knob, and the knobs never cross. ui_core's [DesignRangeSlider]
/// is the behaviour.
///
/// ```dart
/// FrostedRangeSlider(values: const DesignRangeValues(20, 80), max: 100, onChanged: (v) => setState(() => price = v), startLabel: 'Lowest price', endLabel: 'Highest price')
/// ```
class FrostedRangeSlider extends StatelessWidget {
  /// A range slider at [values].
  const FrostedRangeSlider({
    required this.values,
    required this.onChanged,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.minGap = 0,
    this.semanticFormatterCallback,
    this.onChangeStart,
    this.onChangeEnd,
    this.startLabel,
    this.endLabel,
    super.key,
  });

  /// The range.
  final DesignRangeValues values;

  /// Called as a knob moves; null leaves it inert.
  final ValueChanged<DesignRangeValues>? onChanged;

  /// The track's low end.
  final double min;

  /// The track's high end.
  final double max;

  /// How many steps the track has; null moves freely.
  final int? divisions;

  /// The least the range may span.
  final double minGap;

  /// A value as a screen reader says it. Flutter's `RangeSlider` takes it
  /// under this name.
  final String Function(double value)? semanticFormatterCallback;

  /// Called as a drag starts.
  final ValueChanged<DesignRangeValues>? onChangeStart;

  /// Called as a drag ends.
  final ValueChanged<DesignRangeValues>? onChangeEnd;

  /// What a screen reader calls the low knob; null says
  /// `DesignLocalizations.rangeSliderStartLabel` ("Minimum" in English).
  final String? startLabel;

  /// What a screen reader calls the high knob; null says
  /// `DesignLocalizations.rangeSliderEndLabel` ("Maximum" in English).
  final String? endLabel;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    const knob = FrostedChromeMetrics.sliderThumb;
    const track = FrostedChromeMetrics.sliderTrack;
    const end = Radius.circular(track / 2);
    return SizedBox(
      height: FrostedChromeMetrics.sliderHeight,
      child: DesignRangeSlider(
        values: values,
        onChanged: onChanged,
        min: min,
        max: max,
        divisions: divisions,
        minGap: minGap,
        semanticFormatterCallback: semanticFormatterCallback,
        onChangeStart: onChangeStart,
        onChangeEnd: onChangeEnd,
        startLabel: startLabel,
        endLabel: endLabel,
        thumbSize: const Size.square(FrostedChromeMetrics.sliderHeight),
        trackBuilder: (context, range) {
          final rtl = Directionality.of(context) == TextDirection.rtl;
          final bar = Center(
            child: SizedBox(
              height: track,
              child: LayoutBuilder(
                builder: (context, box) {
                  final w = box.maxWidth;
                  final from = (rtl ? 1 - range.end : range.start) * w;
                  final to = (rtl ? 1 - range.start : range.end) * w;
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: FrostedFace(
                          material: FrostedMaterial.paint,
                          radius: const BorderRadius.all(end),
                          color: t.glass.track,
                          ring: t.glass.trackEdge,
                        ),
                      ),
                      Positioned(
                        left: from,
                        width: (to - from).clamp(0, w),
                        top: 0,
                        bottom: 0,
                        child: FrostedFace(
                          material: FrostedMaterial.paint,
                          radius: const BorderRadius.all(end),
                          gradients: [t.hues.iris.band],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          );
          return FrostedDim(off: !range.enabled, child: bar);
        },
        thumbBuilder: (context, index, states) {
          final face = SizedBox.square(
            dimension: knob,
            child: FrostedFace(
              material: FrostedMaterial.paint,
              radius: BorderRadius.circular(knob / 2),
              // A token theme's dark knob by night (made for a switch's
              // light ink) takes the ink on the track.
              color: t.colorScheme.toggleKnob.computeLuminance() > .5
                  ? t.colorScheme.toggleKnob
                  : t.colorScheme.textPrimary,
              edge: t.glass.edge,
              edges: EdgeInsets.all(FrostedStrokes.regular),
              shadows: t.shadows.toggleKnob,
            ),
          );
          return Center(child: frostedRingFor(states, face, radius: knob / 2));
        },
      ),
    );
  }
}

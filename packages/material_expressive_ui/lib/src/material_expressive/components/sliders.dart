/// Sliders — standard, centred, range and vertical, in five track sizes,
/// with stops, an inset icon and a value indicator — and the quantity
/// stepper (CONTRACT §4.1 `slider`, `quantity-stepper`). Owner: w3-sliders.
///
/// A port of Compose material3 1.5.0-alpha29's `Slider.kt`: `Slider`,
/// `VerticalSlider` and `RangeSlider` with `SliderDefaults.Thumb`, `Track`
/// and `CenteredTrack`. Geometry and colours come from the generated
/// `SliderTokens` and `SliderBehavior`; the layout follows `SliderImpl` and
/// `RangeSliderImpl`'s measure policy (the handle spans the track's ends,
/// a stepped value's handle is inset by the track's corner), the track is
/// `drawTrack` line for line (segments that leave a gap around the handle,
/// 2dp inside corners, the stop indicator at each open end, ticks in the
/// opposite colour), and input is Compose's: a tap moves the value on
/// release, a drag moves it from where the finger went down, arrows, Home,
/// End and Page keys step it. The handle narrows to half its width while
/// pressed, dragged or focused, at once, as Compose does (no spring).
///
/// Beyond the component code (deviations, recorded for the oracle): the
/// five track sizes, the inset icon and the value indicator are the
/// Material 3 Expressive spec's, which Compose reaches only by sizing
/// `Track` and `Thumb` and drawing labels in samples. The sizes are the
/// token scale's own steps: track XS 16 (`SliderTokens`) · S 24 · M 40 ·
/// L 56 · XL 96, the handle the track plus `activeHandlePadding` above and
/// below (never under `SliderTokens.handleHeight`), the corners the shape
/// scale's small · small · medium · large · extra-large (XS keeps the
/// default: half the track, no corner shrinking); the value indicator uses
/// the `SliderTokens` value-indicator roles.
///
/// The quantity stepper has no Compose counterpart: two tonal icon buttons
/// (`FilledTonalIconButtonTokens` on `SmallIconButtonTokens`' geometry, on
/// the shared pressable) around the value; holding one repeats.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../component_themes.dart';
import '../elevation.dart';
import '../internal/reach.dart';
import '../internal/focus_ring.dart';
import '../internal/styled_content.dart';
import '../icons.dart';
import '../internal/tokens/behavior.g.dart';
import '../internal/tokens/filled_tonal_icon_button_tokens.g.dart';
import '../internal/tokens/keys.g.dart';
import '../internal/tokens/slider_tokens.g.dart';
import '../internal/tokens/small_icon_button_tokens.g.dart';
import '../motion.dart';
import '../shape.dart';
import '../spacing.dart';
import '../states.dart';
import '../strings.dart';
import '../theme.dart';

// ---------------------------------------------------------------------------
// Sizes and colours
// ---------------------------------------------------------------------------

/// The five track sizes of the Material 3 Expressive slider.
enum ExpressiveSliderSize {
  /// 16dp track, 44dp handle: Compose's default slider.
  extraSmall,

  /// 24dp track, 44dp handle.
  small,

  /// 40dp track, 52dp handle; takes an inset icon.
  medium,

  /// 56dp track, 68dp handle; takes an inset icon.
  large,

  /// 96dp track, 108dp handle; takes a larger inset icon.
  extraLarge;

  /// The track's thickness.
  double get trackHeight => switch (this) {
    extraSmall => SliderTokens.inactiveTrackHeight,
    small => ExpressiveSpacing.s24,
    medium => ExpressiveSpacing.s40,
    large => ExpressiveSpacing.s56,
    extraLarge => ExpressiveSpacing.s48 * 2,
  };

  /// The handle's length across the track: the track plus the handle's
  /// padding above and below, never under the token handle.
  double get handleHeight => math.max(
    SliderTokens.handleHeight,
    trackHeight + SliderTokens.activeHandlePadding * 2,
  );

  /// The track's outer corner; null keeps Compose's default (half the
  /// track, `Dp.Unspecified`).
  ExpressiveCorner? get corner => switch (this) {
    extraSmall => null,
    small => ExpressiveCorner.small,
    medium => ExpressiveCorner.medium,
    large => ExpressiveCorner.large,
    extraLarge => ExpressiveCorner.extraLarge,
  };

  /// The inset icon's size; null where the track is too thin for one.
  double? get iconSize => switch (this) {
    extraSmall || small => null,
    medium || large => ExpressiveSpacing.s24,
    extraLarge => ExpressiveSpacing.s32,
  };
}

/// Compose's `SliderDefaults.defaultSliderColors`, resolved.
@immutable
class _SliderColors {
  const _SliderColors._({
    required this.thumb,
    required this.activeTrack,
    required this.activeTick,
    required this.inactiveTrack,
    required this.inactiveTick,
    required this.disabledThumb,
    required this.disabledActiveTrack,
    required this.disabledActiveTick,
    required this.disabledInactiveTrack,
    required this.disabledInactiveTick,
  });

  factory _SliderColors.of(
    ExpressiveThemeData t,
    ExpressiveComponentThemeData style,
    Set<WidgetState> states,
  ) {
    Color role(ExpressiveColorRole r) => t.colors.role(r);
    Color faded(ExpressiveColorRole r, double opacity) =>
        role(r).withValues(alpha: opacity);
    final base = _SliderColors._(
      thumb: role(SliderTokens.handleColor),
      activeTrack: role(SliderTokens.activeTrackColor),
      activeTick: role(SliderTokens.inactiveTrackColor),
      inactiveTrack: role(SliderTokens.inactiveTrackColor),
      inactiveTick: role(SliderTokens.activeTrackColor),
      disabledThumb: Color.alphaBlend(
        faded(
          SliderTokens.disabledHandleColor,
          SliderTokens.disabledHandleOpacity,
        ),
        t.colors.surface,
      ),
      disabledActiveTrack: faded(
        SliderTokens.disabledActiveTrackColor,
        SliderTokens.disabledActiveTrackOpacity,
      ),
      disabledActiveTick: faded(
        SliderTokens.disabledInactiveTrackColor,
        SliderTokens.disabledInactiveTrackOpacity,
      ),
      disabledInactiveTrack: faded(
        SliderTokens.disabledInactiveTrackColor,
        SliderTokens.disabledInactiveTrackOpacity,
      ),
      disabledInactiveTick: faded(
        SliderTokens.disabledActiveTrackColor,
        SliderTokens.disabledActiveTrackOpacity,
      ),
    );
    Color fill(Color fallback) => Color.alphaBlend(
      style.overlayColor?.resolve(states) ?? expressiveTransparent,
      style.backgroundColor?.resolve(states) ?? fallback,
    );
    Color ink(Color fallback) =>
        style.foregroundColor?.resolve(states) ?? fallback;
    Color rest(Color fallback) => style.outline?.resolve(states) ?? fallback;
    return _SliderColors._(
      thumb: ink(base.thumb),
      activeTrack: fill(base.activeTrack),
      activeTick: ink(base.activeTick),
      inactiveTrack: rest(base.inactiveTrack),
      inactiveTick: ink(base.inactiveTick),
      disabledThumb: ink(base.disabledThumb),
      disabledActiveTrack: fill(base.disabledActiveTrack),
      disabledActiveTick: ink(base.disabledActiveTick),
      disabledInactiveTrack: rest(base.disabledInactiveTrack),
      disabledInactiveTick: ink(base.disabledInactiveTick),
    );
  }

  final Color thumb;
  final Color activeTrack;
  final Color activeTick;
  final Color inactiveTrack;
  final Color inactiveTick;
  final Color disabledThumb;
  final Color disabledActiveTrack;
  final Color disabledActiveTick;
  final Color disabledInactiveTrack;
  final Color disabledInactiveTick;

  Color thumbColor(bool enabled) => enabled ? thumb : disabledThumb;

  Color trackColor(bool enabled, {required bool active}) => enabled
      ? (active ? activeTrack : inactiveTrack)
      : (active ? disabledActiveTrack : disabledInactiveTrack);

  Color tickColor(bool enabled, {required bool active}) => enabled
      ? (active ? activeTick : inactiveTick)
      : (active ? disabledActiveTick : disabledInactiveTick);
}

// ---------------------------------------------------------------------------
// Shared arithmetic (Slider.kt's private helpers)
// ---------------------------------------------------------------------------

/// `stepsToTickFractions`: none for a continuous slider.
List<double> _tickFractions(int steps) => steps == 0
    ? const <double>[]
    : List<double>.generate(steps + 2, (i) => i / (steps + 1));

double _lerp(double a, double b, double t) => a + (b - a) * t;

/// `calcFraction`, clamped to 0…1.
double _fraction(double a, double b, double pos) =>
    b - a == 0 ? 0 : ((pos - a) / (b - a)).clamp(0.0, 1.0);

/// `snapValueToTick`: the tick nearest [current], else [current].
double _snap(double current, List<double> ticks, double minPx, double maxPx) {
  if (ticks.isEmpty) return current;
  var best = _lerp(minPx, maxPx, ticks.first);
  for (final tick in ticks) {
    final at = _lerp(minPx, maxPx, tick);
    if ((at - current).abs() < (best - current).abs()) best = at;
  }
  return best;
}

bool _onFirstOrLast(double fraction, List<double> ticks) =>
    ticks.isNotEmpty && (fraction == ticks.first || fraction == ticks.last);

/// Where a handle sits along a track of [length] (`SliderImpl`'s
/// `fractionOffset`): a stepped value that is not an end is inset by the
/// track's corner.
double _handleOffset(
  double length,
  double fraction,
  double corner,
  List<double> ticks,
) => ticks.isNotEmpty && !_onFirstOrLast(fraction, ticks)
    ? (length - corner * 2) * fraction + corner
    : length * fraction;

/// Compose's `formatForSemantics`: two decimals.
String _semanticValue(double value) => ((value * 100).round() / 100).toString();

/// One arrow-key step over [min]…[max] (`slideOnKeyEvents`).
double _keyDelta(double min, double max, int steps) =>
    (max - min).abs() /
    (steps > 0 ? steps + 1 : SliderBehavior.keyboardContinuousSteps);

/// How many key steps a Page key moves.
int _pageSteps(int steps) {
  final actual = steps > 0
      ? steps + 1
      : SliderBehavior.keyboardContinuousSteps.toInt();
  return (actual ~/ SliderBehavior.keyboardPageDivisor).clamp(
    1,
    SliderBehavior.keyboardMaxPageSteps.toInt(),
  );
}

/// A key's effect on a slider (`slideOnKeyEvents`): a signed number of key
/// steps, or a jump to the start or the end.
typedef _KeyAction = ({int steps, bool? toEnd});

_KeyAction? _keyAction(
  LogicalKeyboardKey key, {
  required bool vertical,
  required bool reverse,
  required int stepsCount,
}) {
  final sign = reverse ? -1 : 1;
  final page = _pageSteps(stepsCount);
  if (key == LogicalKeyboardKey.home) return (steps: 0, toEnd: false);
  if (key == LogicalKeyboardKey.end) return (steps: 0, toEnd: true);
  if (vertical) {
    if (key == LogicalKeyboardKey.arrowUp) return (steps: -sign, toEnd: null);
    if (key == LogicalKeyboardKey.arrowDown) return (steps: sign, toEnd: null);
    if (key == LogicalKeyboardKey.pageUp) {
      return (steps: -page * sign, toEnd: null);
    }
    if (key == LogicalKeyboardKey.pageDown) {
      return (steps: page * sign, toEnd: null);
    }
  } else {
    if (key == LogicalKeyboardKey.arrowRight) {
      return (steps: sign, toEnd: null);
    }
    if (key == LogicalKeyboardKey.arrowLeft) {
      return (steps: -sign, toEnd: null);
    }
    if (key == LogicalKeyboardKey.pageUp) return (steps: page, toEnd: null);
    if (key == LogicalKeyboardKey.pageDown) return (steps: -page, toEnd: null);
  }
  return null;
}

// ---------------------------------------------------------------------------
// The track (SliderDefaults.drawTrack)
// ---------------------------------------------------------------------------

/// Paints one track exactly as Compose's `drawTrack` does, in the track's
/// own box (the handle's half-length in from each end of the slider).
class _TrackPainter extends CustomPainter {
  const _TrackPainter({
    required this.ticks,
    required this.activeStart,
    required this.activeEnd,
    required this.inactiveTrackColor,
    required this.activeTrackColor,
    required this.inactiveTickColor,
    required this.activeTickColor,
    required this.startThumb,
    required this.endThumb,
    required this.startGap,
    required this.endGap,
    required this.corner,
    required this.isRange,
    required this.cornerShrinking,
    required this.vertical,
    required this.flipVertical,
    required this.rtl,
    required this.centered,
  });

  final List<double> ticks;
  final double activeStart;
  final double activeEnd;
  final Color inactiveTrackColor;
  final Color activeTrackColor;
  final Color inactiveTickColor;
  final Color activeTickColor;

  /// The handles' length along the track (0: no handle on that side).
  final double startThumb;
  final double endThumb;

  /// The space between a handle and the track (0: none on that side).
  final double startGap;
  final double endGap;

  /// The outer corner radius; null: half the track's thickness.
  final double? corner;
  final bool isRange;
  final bool cornerShrinking;
  final bool vertical;

  /// A bottom-to-top vertical slider: drawn flipped (Compose's
  /// `scale(1f, -1f)`).
  final bool flipVertical;
  final bool rtl;
  final bool centered;

  @override
  void paint(Canvas canvas, Size size) {
    if (flipVertical) {
      canvas
        ..save()
        ..translate(0, size.height)
        ..scale(1, -1);
    }
    _drawTrack(canvas, size);
    if (flipVertical) canvas.restore();
  }

  /// `drawTrackPath`: a segment with [startRadius] corners at its start and
  /// [endRadius] at its end.
  void _path(
    Canvas canvas,
    Offset offset,
    Size size,
    Color color,
    double startRadius,
    double endRadius,
  ) {
    final start = Radius.circular(startRadius);
    final end = Radius.circular(endRadius);
    final rect = offset & size;
    final track = vertical
        ? RRect.fromRectAndCorners(
            rect,
            topLeft: start,
            topRight: start,
            bottomRight: end,
            bottomLeft: end,
          )
        : RRect.fromRectAndCorners(
            rect,
            topLeft: start,
            topRight: end,
            bottomRight: end,
            bottomLeft: start,
          );
    canvas.drawRRect(track, Paint()..color = color);
  }

  /// `drawStopIndicator`: a dot of the stop indicator's size.
  void _dot(Canvas canvas, Offset center, Color color) => canvas.drawCircle(
    center,
    SliderTokens.stopIndicatorSize / 2,
    Paint()..color = color,
  );

  void _drawTrack(Canvas canvas, Size size) {
    final isRtlHorizontal = rtl && !vertical;
    final cornerSize = corner ?? (vertical ? size.width : size.height) / 2;
    const sliderStart = 0.0;
    final sliderEnd = vertical ? size.height : size.width;
    final center = size.center(Offset.zero);

    final sliderValueEnd = ticks.isNotEmpty && !_onFirstOrLast(activeEnd, ticks)
        ? sliderStart +
              (sliderEnd - sliderStart - cornerSize * 2) * activeEnd +
              cornerSize
        : sliderStart + (sliderEnd - sliderStart) * activeEnd;
    final sliderValueStart =
        ticks.isNotEmpty && !_onFirstOrLast(activeStart, ticks)
        ? sliderStart +
              (sliderEnd - sliderStart - cornerSize * 2) * activeStart +
              cornerSize
        : sliderStart + (sliderEnd - sliderStart) * activeStart;

    final insideCornerSize = SliderBehavior.trackInsideCornerSize;
    final startGapPx = startGap > 0 ? startThumb / 2 + startGap : 0.0;
    final endGapPx = endGap > 0 ? endThumb / 2 + endGap : 0.0;
    final centerAxis = vertical ? center.dy : center.dx;
    // The stop indicator is the active track's colour (the default
    // drawStopIndicator lambda).
    final stopColor = activeTrackColor;

    // The inactive track before the active one (centred or range).
    var rangeInactiveTrackThreshold = sliderStart + startGapPx;
    if (!cornerShrinking || ticks.isNotEmpty) {
      rangeInactiveTrackThreshold += cornerSize;
    }
    final adjustedSliderValueEnd = centered
        ? math.min(sliderValueEnd, centerAxis)
        : sliderValueStart;
    if ((centered || isRange) &&
        adjustedSliderValueEnd > rangeInactiveTrackThreshold) {
      final startRadius = isRtlHorizontal ? insideCornerSize : cornerSize;
      final endRadius = isRtlHorizontal ? cornerSize : insideCornerSize;
      const start = sliderStart;
      final end = adjustedSliderValueEnd - startGapPx;
      final offset = isRtlHorizontal
          ? Offset(size.width - end, 0)
          : Offset.zero;
      final trackSize = vertical
          ? Size(size.width, end - start)
          : Size(end - start, size.height);
      _path(
        canvas,
        offset,
        trackSize,
        inactiveTrackColor,
        startRadius,
        endRadius,
      );
      final stop = vertical
          ? Offset(center.dx, start + cornerSize)
          : rtl
          ? Offset(size.width - start - cornerSize, center.dy)
          : Offset(start + cornerSize, center.dy);
      _dot(canvas, stop, stopColor);
    }

    // The inactive track after the active one.
    var inactiveTrackThreshold = sliderEnd - endGapPx;
    if (!cornerShrinking || ticks.isNotEmpty) {
      inactiveTrackThreshold -= cornerSize;
    }
    final adjustedSliderValueStart = centered
        ? math.max(sliderValueEnd, centerAxis)
        : sliderValueEnd;
    if (adjustedSliderValueStart < inactiveTrackThreshold) {
      final startRadius = isRtlHorizontal ? cornerSize : insideCornerSize;
      final endRadius = isRtlHorizontal ? insideCornerSize : cornerSize;
      final start = adjustedSliderValueStart + endGapPx;
      final end = sliderEnd;
      final inactiveTrackWidth = end - start;
      final offset = vertical
          ? Offset(0, start)
          : rtl
          ? Offset.zero
          : Offset(start, 0);
      final trackSize = vertical
          ? Size(size.width, inactiveTrackWidth)
          : rtl && !isRange
          ? Size(size.width - start, size.height)
          : Size(inactiveTrackWidth, size.height);
      _path(
        canvas,
        offset,
        trackSize,
        inactiveTrackColor,
        startRadius,
        endRadius,
      );
      final stop = vertical
          ? Offset(center.dx, end - cornerSize)
          : rtl
          ? Offset(cornerSize, center.dy)
          : Offset(end - cornerSize, center.dy);
      _dot(canvas, stop, stopColor);
    }

    // The active track.
    final activeTrackStart = centered
        ? adjustedSliderValueEnd +
              (adjustedSliderValueEnd < centerAxis ? startGapPx : 0)
        : isRange
        ? sliderValueStart + startGapPx
        : 0.0;
    final activeTrackEnd = centered
        ? adjustedSliderValueStart -
              (adjustedSliderValueStart > centerAxis ? endGapPx : 0)
        : sliderValueEnd - endGapPx;
    final activeStartRadius = isRtlHorizontal || centered || isRange
        ? insideCornerSize
        : cornerSize;
    final activeEndRadius = isRtlHorizontal && !centered && !isRange
        ? cornerSize
        : insideCornerSize;
    final activeTrackWidth = isRtlHorizontal && !centered && !isRange
        ? activeTrackEnd
        : activeTrackEnd - activeTrackStart;
    final activeTrackThreshold = !cornerShrinking || ticks.isNotEmpty
        ? activeStartRadius
        : 0.0;
    if (activeTrackWidth > activeTrackThreshold) {
      final offset = vertical
          ? Offset(0, activeTrackStart)
          : rtl
          ? Offset(size.width - activeTrackEnd, 0)
          : Offset(activeTrackStart, 0);
      final trackSize = vertical
          ? Size(size.width, activeTrackWidth)
          : rtl && !centered && !isRange
          ? Size(activeTrackEnd, size.height)
          : Size(activeTrackWidth, size.height);
      _path(
        canvas,
        offset,
        trackSize,
        activeTrackColor,
        activeStartRadius,
        activeEndRadius,
      );
    }

    // Ticks, skipping the ones on a stop indicator or in a gap.
    final start = sliderStart + cornerSize;
    final end = sliderEnd - cornerSize;
    bool within(double x, double from, double to) => x >= from && x <= to;
    final centerGap = sliderValueEnd > centerAxis ? startGapPx : endGapPx;
    final tickEndGap = centered
        ? (sliderValueEnd > centerAxis ? endGapPx : startGapPx)
        : endGapPx;
    for (var index = 0; index < ticks.length; index++) {
      final atStartStop = (centered || isRange) && index == 0;
      if (atStartStop || index == ticks.length - 1) continue;
      final tick = _lerp(start, end, ticks[index]);
      if ((centered &&
              within(tick, centerAxis - centerGap, centerAxis + centerGap)) ||
          (isRange &&
              within(
                tick,
                sliderValueStart - startGapPx,
                sliderValueStart + startGapPx,
              )) ||
          within(
            tick,
            sliderValueEnd - tickEndGap,
            sliderValueEnd + tickEndGap,
          )) {
        continue;
      }
      final offset = vertical
          ? Offset(center.dx, tick)
          : rtl
          ? Offset(size.width - tick, center.dy)
          : Offset(tick, center.dy);
      _dot(
        canvas,
        offset,
        within(tick, activeTrackStart, activeTrackEnd)
            ? activeTickColor
            : inactiveTickColor,
      );
    }
  }

  @override
  bool shouldRepaint(_TrackPainter old) =>
      !listEquals(old.ticks, ticks) ||
      old.activeStart != activeStart ||
      old.activeEnd != activeEnd ||
      old.inactiveTrackColor != inactiveTrackColor ||
      old.activeTrackColor != activeTrackColor ||
      old.inactiveTickColor != inactiveTickColor ||
      old.activeTickColor != activeTickColor ||
      old.startThumb != startThumb ||
      old.endThumb != endThumb ||
      old.startGap != startGap ||
      old.endGap != endGap ||
      old.corner != corner ||
      old.isRange != isRange ||
      old.cornerShrinking != cornerShrinking ||
      old.vertical != vertical ||
      old.flipVertical != flipVertical ||
      old.rtl != rtl ||
      old.centered != centered;
}

// ---------------------------------------------------------------------------
// The handle and the value indicator
// ---------------------------------------------------------------------------

/// `ThumbContent`: a [box]-sized slot whose pill narrows to half its
/// length along the track while [narrowed] (pressed, dragged, focused).
/// Under keyboard focus it also draws the focus ring round the pill, as
/// every focusable part does (Material's web slider rings its handle;
/// Compose shows only the narrowing).
class _Handle extends StatefulWidget {
  const _Handle({
    required this.box,
    required this.vertical,
    required this.narrowed,
    required this.color,
    required this.enabled,
    this.focused = false,
  });

  final Size box;
  final bool vertical;
  final bool narrowed;
  final Color color;
  final bool enabled;
  final bool focused;

  @override
  State<_Handle> createState() => _HandleState();
}

class _HandleState extends State<_Handle> {
  /// Read when built, never kept: a mouse connecting to a phone turns the
  /// default highlight mode traditional without telling any listener (as
  /// ExpressivePressable reads it).
  bool get _keyboard =>
      FocusManager.instance.highlightMode == FocusHighlightMode.traditional;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addHighlightModeListener(_modeChanged);
  }

  @override
  void dispose() {
    FocusManager.instance.removeHighlightModeListener(_modeChanged);
    super.dispose();
  }

  void _modeChanged(FocusHighlightMode mode) {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final scope = ExpressiveStyleScope.maybeOf(context)!;
    final theme = context.expressiveTheme;
    final side =
        scope.style.side?.resolve(scope.states) ??
        BorderSide.none.copyWith(
          color: scope.style.outline?.resolve(scope.states),
        );
    final shape =
        (scope.style.shape?.resolve(scope.states) ??
                theme.shapes.of(SliderTokens.handleShape))
            .copyWith(side: side);
    final divisor = widget.narrowed ? SliderBehavior.interactedThumbDivisor : 1;
    final box = widget.box;
    final size = widget.vertical
        ? Size(box.width, box.height / divisor)
        : Size(box.width / divisor, box.height);
    final ring = widget.focused && _keyboard && widget.enabled;
    return MouseRegion(
      cursor: widget.enabled ? SystemMouseCursors.click : MouseCursor.defer,
      child: SizedBox.fromSize(
        size: box,
        child: Center(
          child: CustomPaint(
            foregroundPainter: ring
                ? _HandleRing(
                    shape: shape,
                    color: theme.colors.secondary,
                    thickness: ExpressiveFocusRing.thickness,
                    textDirection: Directionality.maybeOf(context),
                  )
                : null,
            child: SizedBox.fromSize(
              size: size,
              child: DecoratedBox(
                decoration: ShapeDecoration(color: widget.color, shape: shape),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The focus ring round the handle's pill.
class _HandleRing extends CustomPainter {
  const _HandleRing({
    required this.shape,
    required this.color,
    required this.thickness,
    required this.textDirection,
  });

  final OutlinedBorder shape;
  final Color color;
  final double thickness;
  final TextDirection? textDirection;

  @override
  void paint(Canvas canvas, Size size) => expressivePaintFocusRing(
    canvas,
    Offset.zero & size,
    shape,
    color: color,
    thickness: thickness,
    offset: ExpressiveFocusRing.offset,
    textDirection: textDirection,
  );

  @override
  bool shouldRepaint(_HandleRing old) =>
      old.shape != shape ||
      old.color != color ||
      old.thickness != thickness ||
      old.textDirection != textDirection;
}

/// The value indicator: [text] in a full-round inverse-surface bubble that
/// fades in above the handle while [visible].
class _ValueIndicator extends StatelessWidget {
  const _ValueIndicator({required this.text, required this.visible});

  final String text;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final scope = ExpressiveStyleScope.maybeOf(context)!;
    return IgnorePointer(
      child: ExpressiveSpringValue(
        value: visible ? 1 : 0,
        motion: ExpressiveMotionKey.fastEffects,
        builder: (context, shown, child) => shown <= 0
            ? const SizedBox.shrink()
            : Opacity(opacity: shown.clamp(0.0, 1.0), child: child),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: ExpressiveSpacing.s48),
          child: ExpressiveSurface(
            states: scope.states,
            style: ExpressiveComponentThemeData(
              side: scope.style.side,
              overlayColor: scope.style.overlayColor,
              textStyle: scope.style.textStyle,
              foregroundColor: scope.style.foregroundColor,
            ),
            color: t.colors.role(SliderTokens.valueIndicatorContainerColor),
            contentColor: t.colors.role(
              SliderTokens.valueIndicatorLabelTextColor,
            ),
            shape: t.shapes.full,
            padding: const EdgeInsets.symmetric(
              horizontal: ExpressiveSpacing.s16,
              vertical: ExpressiveSpacing.s12,
            ),
            child: DefaultTextStyle.merge(
              style: t.type
                  .of(SliderTokens.valueIndicatorLabelTextFont)
                  .merge(scope.style.textStyle?.resolve(scope.states)),
              child: Text(text, textAlign: TextAlign.center, maxLines: 1),
            ),
          ),
        ),
      ),
    );
  }
}

/// The value indicator above [handle]: [SliderTokens
/// .valueIndicatorActiveBottomSpace] over the handle's top, centred on it.
Widget _indicatorAbove(Rect handle, String text, bool visible) => Positioned(
  left: handle.center.dx,
  top: handle.top - SliderTokens.valueIndicatorActiveBottomSpace,
  child: FractionalTranslation(
    translation: const Offset(-0.5, -1),
    child: _ValueIndicator(text: text, visible: visible),
  ),
);

// ---------------------------------------------------------------------------
// Slider and vertical slider
// ---------------------------------------------------------------------------

/// A slider: one value on a thick track, the handle a slim pill that
/// narrows while held, stops at the open ends (Compose's `Slider`).
///
/// [steps] is Compose's: the number of discrete values *between* [min] and
/// [max] (0 = continuous); each is a tick on the track. [centered] draws
/// the active track from the middle (Compose's `CenteredTrack`) — for a
/// value around a neutral point such as a balance or an offset. [size]
/// picks one of the five track sizes; M, L and XL take an inset [icon].
/// [valueLabel], when given, shows the value in a bubble above the handle
/// while it is held or focused, and is what a screen reader hears.
///
/// Disabled when [onChanged] is null. [onChangeEnd]
/// reports the value a drag, tap or key press settled on.
///
/// ```dart
/// ExpressiveSlider(value: volume, onChanged: (v) => setState(() => volume = v))
/// ```
class ExpressiveSlider extends StatelessWidget {
  /// A slider at [value] between [min] and [max], reporting a change through [onChanged].
  const ExpressiveSlider({
    required this.value,
    required this.onChanged,
    this.onChangeStart,
    this.onChangeEnd,
    this.style,
    this.min = 0,
    this.max = 1,
    this.steps = 0,
    this.size = ExpressiveSliderSize.extraSmall,
    this.centered = false,
    this.icon,
    this.valueLabel,
    this.semanticLabel,
    this.focusNode,
    this.autofocus = false,
    super.key,
  }) : assert(steps >= 0, 'steps should be >= 0'),
       assert(min <= max, 'min must not exceed max');

  /// The current value, in [min]…[max].
  final double value;

  /// Called with each new value while the user moves the slider.
  final ValueChanged<double>? onChanged;

  /// Called with the value when a drag or tap begins.
  final ValueChanged<double>? onChangeStart;

  /// Called with the settled value when a drag, tap or key press ends.
  final ValueChanged<double>? onChangeEnd;

  /// The value at the track's start.
  final double min;

  /// The value at the track's end.
  final double max;

  /// Discrete values between [min] and [max]; 0 = continuous.
  final int steps;

  /// The track size.
  final ExpressiveSliderSize size;

  /// Whether the active track grows from the middle.
  final bool centered;

  /// An icon inside the track's start (sizes M, L and XL; not centred).
  final IconData? icon;

  /// The value as the indicator and a screen reader show it; no indicator
  /// when null.
  final String Function(double value)? valueLabel;

  /// Whether it takes input: false when onChanged is null, as in Flutter.
  bool get enabled => onChanged != null;

  /// What a screen reader calls the slider.
  final String? semanticLabel;

  /// The slider's focus node.
  final FocusNode? focusNode;

  /// Whether the slider takes focus when first built.
  final bool autofocus;

  /// Stateful track colours, handle outline and content/layout overrides.
  /// Track segments retain the geometry that encodes their values.
  final ExpressiveComponentThemeData? style;

  // The inactive track is faint on the page (its end would read at the stop
  // dot): marked, the checks take the slider as one item, edge to edge.
  @override
  Widget build(BuildContext context) => DesignKeylineFace(
    child: _SingleSlider(
      style: style,
      value: value,
      onChanged: onChanged,
      onChangeStart: onChangeStart,
      onChangeEnd: onChangeEnd,
      min: min,
      max: max,
      steps: steps,
      size: size,
      centered: centered,
      icon: icon,
      valueLabel: valueLabel,
      enabled: enabled,
      semanticLabel: semanticLabel,
      focusNode: focusNode,
      autofocus: autofocus,
      vertical: false,
      topToBottom: true,
    ),
  );
}

/// A vertical slider (Compose's `VerticalSlider`): the same slider stood
/// on end, in a box of bounded height. By default [min] is at the top, as
/// in Compose; set [topToBottom] false for a level, a volume or a
/// brightness, whose minimum sits at the bottom.
///
/// ```dart
/// SizedBox(height: 240, child: ExpressiveVerticalSlider(value: level, topToBottom: false, onChanged: (v) => setState(() => level = v)))
/// ```
class ExpressiveVerticalSlider extends StatelessWidget {
  /// A vertical slider at [value] between [min] and [max], reporting a change through [onChanged].
  const ExpressiveVerticalSlider({
    required this.value,
    required this.onChanged,
    this.onChangeStart,
    this.onChangeEnd,
    this.style,
    this.min = 0,
    this.max = 1,
    this.steps = 0,
    this.size = ExpressiveSliderSize.extraSmall,
    this.centered = false,
    this.topToBottom = true,
    this.semanticLabel,
    this.valueLabel,
    this.focusNode,
    this.autofocus = false,
    super.key,
  }) : assert(steps >= 0, 'steps should be >= 0'),
       assert(min <= max, 'min must not exceed max');

  /// As [ExpressiveSlider.value].
  final double value;

  /// As [ExpressiveSlider.onChanged].
  final ValueChanged<double>? onChanged;

  /// As [ExpressiveSlider.onChangeStart].
  final ValueChanged<double>? onChangeStart;

  /// As [ExpressiveSlider.onChangeEnd].
  final ValueChanged<double>? onChangeEnd;

  /// As [ExpressiveSlider.min].
  final double min;

  /// As [ExpressiveSlider.max].
  final double max;

  /// As [ExpressiveSlider.steps].
  final int steps;

  /// As [ExpressiveSlider.size]: the track's thickness.
  final ExpressiveSliderSize size;

  /// As [ExpressiveSlider.centered].
  final bool centered;

  /// Whether [min] is at the top (Compose's `topToBottom`).
  final bool topToBottom;

  /// Whether it takes input: false when onChanged is null, as in Flutter.
  bool get enabled => onChanged != null;

  /// As [ExpressiveSlider.semanticLabel].
  final String? semanticLabel;

  /// The value as a screen reader hears it (a vertical slider draws no
  /// indicator).
  final String Function(double value)? valueLabel;

  /// As [ExpressiveSlider.focusNode].
  final FocusNode? focusNode;

  /// As [ExpressiveSlider.autofocus].
  final bool autofocus;

  /// Stateful track colours, handle outline and content/layout overrides.
  /// Track segments retain the geometry that encodes their values.
  final ExpressiveComponentThemeData? style;

  @override
  Widget build(BuildContext context) => _SingleSlider(
    style: style,
    value: value,
    onChanged: onChanged,
    onChangeStart: onChangeStart,
    onChangeEnd: onChangeEnd,
    min: min,
    max: max,
    steps: steps,
    size: size,
    centered: centered,
    icon: null,
    valueLabel: valueLabel,
    enabled: enabled,
    semanticLabel: semanticLabel,
    focusNode: focusNode,
    autofocus: autofocus,
    vertical: true,
    topToBottom: topToBottom,
  );
}

class _SingleSlider extends StatefulWidget {
  const _SingleSlider({
    required this.style,
    required this.value,
    required this.onChanged,
    required this.onChangeStart,
    required this.onChangeEnd,
    required this.min,
    required this.max,
    required this.steps,
    required this.size,
    required this.centered,
    required this.icon,
    required this.valueLabel,
    required this.enabled,
    required this.semanticLabel,
    required this.focusNode,
    required this.autofocus,
    required this.vertical,
    required this.topToBottom,
  });

  final ExpressiveComponentThemeData? style;
  final double value;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeStart;
  final ValueChanged<double>? onChangeEnd;
  final double min;
  final double max;
  final int steps;
  final ExpressiveSliderSize size;
  final bool centered;
  final IconData? icon;
  final String Function(double value)? valueLabel;
  final bool enabled;
  final String? semanticLabel;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool vertical;
  final bool topToBottom;

  @override
  State<_SingleSlider> createState() => _SingleSliderState();
}

class _SingleSliderState extends State<_SingleSlider> {
  bool _pressed = false;
  bool _hovered = false;
  bool _dragging = false;
  bool _focused = false;

  /// Compose's `rawOffset`: where input has pushed the value, in pixels
  /// along the slider's forward axis, unclamped.
  double _raw = 0;

  /// Where the current press went down, forward axis.
  double _pressAt = 0;

  /// The slider's length along its axis (`updateDimensions`).
  double _extent = 0;

  /// The value last reported, for [_SingleSlider.onChangeEnd].
  double? _reported;

  bool get _enabled => widget.enabled && widget.onChanged != null;

  bool get _rtl =>
      !widget.vertical && Directionality.of(context) == TextDirection.rtl;

  /// Whether the forward axis runs against the layout's (RTL, or a
  /// bottom-to-top vertical slider).
  bool get _reverse => widget.vertical ? !widget.topToBottom : _rtl;

  List<double> get _ticks => _tickFractions(widget.steps);

  /// The pointer's position along the forward axis. The slider is centred
  /// across its touch target, never offset along its axis.
  double _forward(Offset local) {
    final along = widget.vertical ? local.dy : local.dx;
    return _reverse ? _extent - along : along;
  }

  /// `dispatchRawDeltaInternal`: move the raw offset by [delta] and report
  /// the snapped value it lands on.
  void _dispatch(double delta) {
    const thumb = SliderTokens.handleWidth;
    final maxPx = math.max(_extent - thumb / 2, 0.0);
    final minPx = math.min(thumb / 2, maxPx);
    _raw += delta;
    final snapped = _snap(_raw, _ticks, minPx, maxPx);
    _report(_lerp(widget.min, widget.max, _fraction(minPx, maxPx, snapped)));
  }

  void _report(double value) {
    _reported = value;
    if (value != widget.value) widget.onChanged?.call(value);
  }

  void _finish() => widget.onChangeEnd?.call(_reported ?? widget.value);

  void _down(PointerDownEvent event) {
    if (!_enabled) return;
    setState(() => _pressed = true);
    _pressAt = _forward(event.localPosition);
    _reported = widget.value;
  }

  void _up() {
    if (_pressed) setState(() => _pressed = false);
  }

  void _tap() {
    widget.onChangeStart?.call(widget.value);
    _raw = _pressAt;
    _dispatch(0);
    if (!_dragging) _finish();
  }

  void _dragStart(DragStartDetails details) {
    setState(() => _dragging = true);
    widget.onChangeStart?.call(widget.value);
    _raw = _forward(details.localPosition);
    _dispatch(0);
  }

  void _dragUpdate(DragUpdateDetails details) {
    final delta = widget.vertical ? details.delta.dy : details.delta.dx;
    _dispatch(_reverse ? -delta : delta);
  }

  void _dragEnd() {
    if (!_dragging) return;
    setState(() => _dragging = false);
    _finish();
  }

  double _keyTarget(_KeyAction action) {
    if (action.toEnd != null) return action.toEnd! ? widget.max : widget.min;
    final delta = _keyDelta(widget.min, widget.max, widget.steps);
    return (widget.value + action.steps * delta).clamp(widget.min, widget.max);
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (!_enabled) return KeyEventResult.ignored;
    final action = _keyAction(
      event.logicalKey,
      vertical: widget.vertical,
      reverse: _reverse,
      stepsCount: widget.steps,
    );
    if (action == null) return KeyEventResult.ignored;
    if (event is KeyUpEvent) {
      _finish();
    } else {
      _report(_keyTarget(action));
    }
    return KeyEventResult.handled;
  }

  void _semanticStep(int direction) {
    _report(_keyTarget((steps: direction, toEnd: null)));
    _finish();
  }

  String _describe(double value) =>
      widget.valueLabel?.call(value) ?? _semanticValue(value);

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final enabled = _enabled;
    final states = <WidgetState>{
      if (!enabled) WidgetState.disabled,
      if (_pressed) WidgetState.pressed,
      if (_dragging) WidgetState.dragged,
      if (_hovered) WidgetState.hovered,
      if (_focused) WidgetState.focused,
    };
    final resolved = t.sliderTheme.merge(widget.style);
    final colors = _SliderColors.of(t, resolved, states);
    final vertical = widget.vertical;
    final size = widget.size;
    final thickness = t.density.height(size.trackHeight, floor: 8);
    final corner = size.corner == null
        ? null
        : t.shapes.corner(size.corner!).topStart.dp;
    // The handle's box: SliderTokens' width along the track, the size's
    // handle across it (Compose's ThumbSize / VerticalThumbSize).
    const thumbAlong = SliderTokens.handleWidth;
    final thumbAcross = math.max(
      SliderTokens.handleHeight,
      thickness + SliderTokens.activeHandlePadding * 2,
    );
    final thumbBox = vertical
        ? Size(thumbAcross, thumbAlong)
        : Size(thumbAlong, thumbAcross);
    final narrowed = _pressed || _dragging || _focused;
    final fraction = _fraction(
      widget.min,
      widget.max,
      widget.value.clamp(widget.min, widget.max),
    );
    final ticks = _ticks;
    final delta = _keyDelta(widget.min, widget.max, widget.steps);
    final up = (widget.value + delta).clamp(widget.min, widget.max);
    final down = (widget.value - delta).clamp(widget.min, widget.max);
    final label = widget.valueLabel;

    final slider = LayoutBuilder(
      builder: (context, constraints) {
        final extent = vertical ? constraints.maxHeight : constraints.maxWidth;
        assert(
          extent.isFinite,
          'An Expressive slider needs a bounded '
          '${vertical ? 'height' : 'width'}.',
        );
        _extent = extent;
        final trackLength = math.max(extent - thumbAlong, 0.0);
        final across = math.max(
          vertical ? constraints.minWidth : constraints.minHeight,
          math.max(thickness, thumbAcross),
        );
        final along = _handleOffset(
          trackLength,
          fraction,
          corner ?? thickness / 2,
          ticks,
        );
        // The handle's leading edge along the layout axis.
        final handleStart = _reverse ? extent - along - thumbAlong : along;
        // The track starts half a handle in; track and handle are centred
        // across the slider.
        final trackInset = thumbAlong / 2;
        final trackAcross = (across - thickness) / 2;
        final handleAcross = (across - thumbAcross) / 2;
        final trackRect = vertical
            ? Rect.fromLTWH(trackAcross, trackInset, thickness, trackLength)
            : Rect.fromLTWH(trackInset, trackAcross, trackLength, thickness);
        final handleRect = vertical
            ? Rect.fromLTWH(handleAcross, handleStart, thumbAcross, thumbAlong)
            : Rect.fromLTWH(handleStart, handleAcross, thumbAlong, thumbAcross);
        final painter = _TrackPainter(
          ticks: ticks,
          activeStart: 0,
          activeEnd: fraction,
          inactiveTrackColor: colors.trackColor(enabled, active: false),
          activeTrackColor: colors.trackColor(enabled, active: true),
          inactiveTickColor: colors.tickColor(enabled, active: false),
          activeTickColor: colors.tickColor(enabled, active: true),
          startThumb: widget.centered && fraction <= 0.5 ? thumbAlong : 0,
          endThumb: !widget.centered || fraction >= 0.5 ? thumbAlong : 0,
          startGap: widget.centered ? SliderTokens.activeHandleLeadingSpace : 0,
          endGap: SliderTokens.activeHandleLeadingSpace,
          corner: corner,
          isRange: false,
          // Compose's default horizontal Track does not shrink corners;
          // the sized, vertical and centred tracks do.
          cornerShrinking: vertical || widget.centered || corner != null,
          vertical: vertical,
          flipVertical: vertical && !widget.topToBottom,
          rtl: _rtl,
          centered: widget.centered,
        );
        final icon = _insetIcon(
          colors,
          enabled,
          trackRect,
          trackLength,
          along,
          thumbAlong,
          resolved.iconSize?.resolve(states),
        );
        return SizedBox(
          width: vertical ? across : extent,
          height: vertical ? extent : across,
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Positioned.fromRect(
                rect: trackRect,
                child: CustomPaint(painter: painter),
              ),
              ?icon,
              Positioned.fromRect(
                rect: handleRect,
                child: _Handle(
                  box: thumbBox,
                  vertical: vertical,
                  narrowed: narrowed,
                  color: colors.thumbColor(enabled),
                  enabled: enabled,
                  focused: _focused,
                ),
              ),
              if (label != null && !vertical)
                _indicatorAbove(
                  handleRect,
                  label(widget.value),
                  narrowed && enabled,
                ),
            ],
          ),
        );
      },
    );

    return _SliderFrame(
      style: resolved,
      states: states,
      onHoverChanged: (hovered) => setState(() => _hovered = hovered),
      child: Semantics(
        slider: true,
        label: widget.semanticLabel,
        value: _describe(widget.value),
        increasedValue: _describe(up),
        decreasedValue: _describe(down),
        enabled: enabled,
        onIncrease: enabled && up != widget.value
            ? () => _semanticStep(1)
            : null,
        onDecrease: enabled && down != widget.value
            ? () => _semanticStep(-1)
            : null,
        child: Focus(
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
          canRequestFocus: enabled,
          onKeyEvent: _key,
          onFocusChange: (focused) => setState(() => _focused = focused),
          // The slider is told to step through its own semantics (as
          // Compose's `setProgress`): the pointer's tap and drag are not
          // actions of their own, and a disabled slider has none.
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            excludeFromSemantics: true,
            dragStartBehavior: DragStartBehavior.down,
            onTap: enabled ? _tap : null,
            onTapCancel: enabled ? _up : null,
            onHorizontalDragStart: enabled && !vertical ? _dragStart : null,
            onHorizontalDragUpdate: enabled && !vertical ? _dragUpdate : null,
            onHorizontalDragEnd: enabled && !vertical
                ? (_) => _dragEnd()
                : null,
            onHorizontalDragCancel: enabled && !vertical ? _dragEnd : null,
            onVerticalDragStart: enabled && vertical ? _dragStart : null,
            onVerticalDragUpdate: enabled && vertical ? _dragUpdate : null,
            onVerticalDragEnd: enabled && vertical ? (_) => _dragEnd() : null,
            onVerticalDragCancel: enabled && vertical ? _dragEnd : null,
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: _down,
              onPointerUp: (_) => _up(),
              onPointerCancel: (_) => _up(),
              child: ExpressiveMinimumInteractiveSize(child: slider),
            ),
          ),
        ),
      ),
    );
  }

  /// The inset icon: inside the active track's start while it fits there,
  /// else just past the handle on the inactive track, in the tick colour of
  /// the track it sits on (the active tick colour on the active track).
  Widget? _insetIcon(
    _SliderColors colors,
    bool enabled,
    Rect trackRect,
    double trackLength,
    double along,
    double thumbAlong,
    double? customIconSize,
  ) {
    final glyph = widget.icon;
    final iconSize = customIconSize ?? widget.size.iconSize;
    if (glyph == null || iconSize == null) return null;
    if (widget.vertical || widget.centered) return null;
    const padding = ExpressiveSpacing.s10;
    final gap = thumbAlong / 2 + SliderTokens.activeHandleLeadingSpace;
    final double forward;
    final bool onActive;
    if (iconSize + padding * 2 <= along - gap) {
      forward = padding;
      onActive = true;
    } else if (along + gap + padding + iconSize <= trackLength) {
      forward = along + gap + padding;
      onActive = false;
    } else {
      return null;
    }
    return Positioned(
      left: _rtl
          ? trackRect.right - forward - iconSize
          : trackRect.left + forward,
      top: trackRect.center.dy - iconSize / 2,
      child: IgnorePointer(
        child: Icon(
          glyph,
          size: iconSize,
          color: colors.tickColor(enabled, active: onActive),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Range slider
// ---------------------------------------------------------------------------

/// Two values on one track (Compose's `RangeSlider`): [start] and [end],
/// each with its own handle; the active track runs between them. A press
/// takes the nearer handle; a handle never passes the other.
///
/// ```dart
/// ExpressiveRangeSlider(start: low, end: high, min: 0, max: 500, onChanged: (s, e) => setState(() { low = s; high = e; }))
/// ```
class ExpressiveRangeSlider extends StatefulWidget {
  /// A range slider from [start] to [end], reporting a change through [onChanged].
  const ExpressiveRangeSlider({
    required this.start,
    required this.end,
    required this.onChanged,
    this.onChangeEnd,
    this.style,
    this.min = 0,
    this.max = 1,
    this.steps = 0,
    this.size = ExpressiveSliderSize.extraSmall,
    this.valueLabel,
    this.startSemanticLabel,
    this.endSemanticLabel,
    super.key,
  }) : assert(steps >= 0, 'steps should be >= 0'),
       assert(min <= max, 'min must not exceed max');

  /// The lower value.
  final double start;

  /// The upper value.
  final double end;

  /// Called with both values while the user moves a handle.
  final void Function(double start, double end)? onChanged;

  /// Called with both values when a drag, tap or key press ends.
  final void Function(double start, double end)? onChangeEnd;

  /// The value at the track's start.
  final double min;

  /// The value at the track's end.
  final double max;

  /// Discrete values between [min] and [max]; 0 = continuous.
  final int steps;

  /// The track size.
  final ExpressiveSliderSize size;

  /// Each value as its indicator and a screen reader show it; no
  /// indicator when null.
  final String Function(double value)? valueLabel;

  /// Whether it takes input: false when onChanged is null, as in Flutter.
  bool get enabled => onChanged != null;

  /// What a screen reader calls the start handle (Compose's
  /// `Strings.SliderRangeStart`).
  final String? startSemanticLabel;

  /// What a screen reader calls the end handle.
  final String? endSemanticLabel;

  /// Stateful track colours, handle outline and content/layout overrides.
  /// Track segments retain the geometry that encodes their values.
  final ExpressiveComponentThemeData? style;

  @override
  State<ExpressiveRangeSlider> createState() => _RangeSliderState();
}

class _RangeSliderState extends State<ExpressiveRangeSlider> {
  bool _pressed = false;
  bool _hovered = false;
  bool _dragging = false;
  bool _startFocused = false;
  bool _endFocused = false;

  /// Which handle the gesture holds.
  bool _draggingStart = false;
  double _rawStart = 0;
  double _rawEnd = 0;
  double _pressAt = 0;
  double _width = 0;
  ({double start, double end})? _reported;

  bool get _enabled => widget.enabled && widget.onChanged != null;

  bool get _rtl => Directionality.of(context) == TextDirection.rtl;

  List<double> get _ticks => _tickFractions(widget.steps);

  double get _startValue => widget.start.clamp(widget.min, widget.max);

  double get _endValue => widget.end.clamp(_startValue, widget.max);

  double get _maxPx => math.max(_width - SliderTokens.handleWidth / 2, 0.0);

  double get _minPx => math.min(SliderTokens.handleWidth / 2, _maxPx);

  double _toPx(double value) =>
      _lerp(_minPx, _maxPx, _fraction(widget.min, widget.max, value));

  double _toValue(double px) =>
      _lerp(widget.min, widget.max, _fraction(_minPx, _maxPx, px));

  /// `updateMinMaxPx`: between gestures the raw offsets follow the values.
  void _sync() {
    _rawStart = _toPx(_startValue);
    _rawEnd = _toPx(_endValue);
  }

  /// `RangeSliderState.onDrag`.
  void _onDrag(bool isStart, double offset) {
    final double s;
    final double e;
    if (isStart) {
      _rawStart += offset;
      _rawEnd = _toPx(_endValue);
      final offsetStart = _snap(
        _rawStart.clamp(_minPx, _rawEnd),
        _ticks,
        _minPx,
        _maxPx,
      );
      s = math.min(offsetStart, _rawEnd);
      e = _rawEnd;
    } else {
      _rawEnd += offset;
      _rawStart = _toPx(_startValue);
      final offsetEnd = _snap(
        _rawEnd.clamp(_rawStart, _maxPx),
        _ticks,
        _minPx,
        _maxPx,
      );
      s = _rawStart;
      e = math.max(offsetEnd, _rawStart);
    }
    _report(_toValue(s), _toValue(e));
  }

  void _report(double start, double end) {
    _reported = (start: start, end: end);
    if (start != widget.start || end != widget.end) {
      widget.onChanged?.call(start, end);
    }
  }

  void _finish() {
    final r = _reported ?? (start: widget.start, end: widget.end);
    widget.onChangeEnd?.call(r.start, r.end);
  }

  double _forward(Offset local) => _rtl ? _width - local.dx : local.dx;

  /// A press takes the nearer handle; on a tie, the start handle when the
  /// press is before it (`compareOffsets`).
  void _down(PointerDownEvent event) {
    if (!_enabled) return;
    _sync();
    final pos = _forward(event.localPosition);
    final diffStart = (_rawStart - pos).abs();
    final diffEnd = (_rawEnd - pos).abs();
    _draggingStart = diffStart != diffEnd
        ? diffStart < diffEnd
        : _rawStart > pos;
    _pressAt = pos;
    _reported = null;
    setState(() => _pressed = true);
  }

  void _up() {
    if (_pressed) setState(() => _pressed = false);
  }

  void _tap() {
    _onDrag(_draggingStart, _pressAt - (_draggingStart ? _rawStart : _rawEnd));
    _finish();
  }

  void _dragStart(DragStartDetails details) {
    setState(() => _dragging = true);
    final pos = _forward(details.localPosition);
    _onDrag(_draggingStart, pos - (_draggingStart ? _rawStart : _rawEnd));
  }

  void _dragUpdate(DragUpdateDetails details) {
    final dx = details.delta.dx;
    _onDrag(_draggingStart, _rtl ? -dx : dx);
  }

  void _dragEnd() {
    if (!_dragging) return;
    setState(() => _dragging = false);
    _finish();
  }

  KeyEventResult _key(bool isStart, KeyEvent event) {
    if (!_enabled) return KeyEventResult.ignored;
    final action = _keyAction(
      event.logicalKey,
      vertical: false,
      reverse: _rtl,
      stepsCount: widget.steps,
    );
    if (action == null) return KeyEventResult.ignored;
    if (event is KeyUpEvent) {
      _finish();
    } else {
      _step(isStart, action);
    }
    return KeyEventResult.handled;
  }

  /// A key step of one handle, kept on its side of the other.
  void _step(bool isStart, _KeyAction action) {
    final delta = _keyDelta(widget.min, widget.max, widget.steps);
    if (isStart) {
      final next = action.toEnd != null
          ? (action.toEnd! ? _endValue : widget.min)
          : (_startValue + action.steps * delta).clamp(widget.min, _endValue);
      _report(next, _endValue);
    } else {
      final next = action.toEnd != null
          ? (action.toEnd! ? widget.max : _startValue)
          : (_endValue + action.steps * delta).clamp(_startValue, widget.max);
      _report(_startValue, next);
    }
  }

  String _describe(double value) =>
      widget.valueLabel?.call(value) ?? _semanticValue(value);

  /// One handle with its own focus, keys and slider semantics.
  Widget _handleNode({
    required bool isStart,
    required Rect rect,
    required bool narrowed,
    required Color color,
  }) {
    final value = isStart ? _startValue : _endValue;
    final delta = _keyDelta(widget.min, widget.max, widget.steps);
    final lower = isStart ? widget.min : _startValue;
    final upper = isStart ? _endValue : widget.max;
    final up = (value + delta).clamp(lower, upper);
    final down = (value - delta).clamp(lower, upper);
    final enabled = _enabled;
    void semanticStep(int direction) {
      _step(isStart, (steps: direction, toEnd: null));
      _finish();
    }

    return Positioned.fromRect(
      rect: rect,
      child: Semantics(
        slider: true,
        label: isStart
            ? widget.startSemanticLabel ??
                  ExpressiveLocalizations.of(context).rangeStart
            : widget.endSemanticLabel ??
                  ExpressiveLocalizations.of(context).rangeEnd,
        value: _describe(value),
        increasedValue: _describe(up),
        decreasedValue: _describe(down),
        enabled: enabled,
        onIncrease: enabled && up != value ? () => semanticStep(1) : null,
        onDecrease: enabled && down != value ? () => semanticStep(-1) : null,
        child: Focus(
          canRequestFocus: enabled,
          onKeyEvent: (_, event) => _key(isStart, event),
          onFocusChange: (focused) => setState(() {
            if (isStart) {
              _startFocused = focused;
            } else {
              _endFocused = focused;
            }
          }),
          child: _Handle(
            box: rect.size,
            vertical: false,
            narrowed: narrowed,
            color: color,
            enabled: enabled,
            focused: isStart ? _startFocused : _endFocused,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final enabled = _enabled;
    final states = <WidgetState>{
      if (!enabled) WidgetState.disabled,
      if (_pressed) WidgetState.pressed,
      if (_dragging) WidgetState.dragged,
      if (_hovered) WidgetState.hovered,
      if (_startFocused || _endFocused) WidgetState.focused,
    };
    final resolved = t.sliderTheme.merge(widget.style);
    final colors = _SliderColors.of(t, resolved, states);
    final size = widget.size;
    final thickness = t.density.height(size.trackHeight, floor: 8);
    final corner = size.corner == null
        ? null
        : t.shapes.corner(size.corner!).topStart.dp;
    final box = Size(
      SliderTokens.handleWidth,
      math.max(
        SliderTokens.handleHeight,
        thickness + SliderTokens.activeHandlePadding * 2,
      ),
    );
    final ticks = _ticks;
    final startFraction = _fraction(widget.min, widget.max, _startValue);
    final endFraction = _fraction(widget.min, widget.max, _endValue);
    final held = _pressed || _dragging;
    final startNarrowed = (held && _draggingStart) || _startFocused;
    final endNarrowed = (held && !_draggingStart) || _endFocused;
    final label = widget.valueLabel;

    final slider = LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        assert(width.isFinite, 'An Expressive slider needs a bounded width.');
        _width = width;
        if (!_dragging) _sync();
        final trackLength = math.max(width - box.width, 0.0);
        final height = math.max(
          constraints.minHeight,
          math.max(thickness, box.height),
        );
        // RangeSliderImpl places the handles by half the track's thickness
        // (its CornerSizeAlignmentLine), whatever corner the track draws.
        final layoutCorner = thickness / 2;
        double left(double fraction) {
          final along = _handleOffset(
            trackLength,
            fraction,
            layoutCorner,
            ticks,
          );
          return _rtl ? width - along - box.width : along;
        }

        final top = (height - box.height) / 2;
        final startRect = Offset(left(startFraction), top) & box;
        final endRect = Offset(left(endFraction), top) & box;
        final trackInset = box.width / 2;
        final trackTop = (height - thickness) / 2;
        final trackRect = Rect.fromLTWH(
          trackInset,
          trackTop,
          trackLength,
          thickness,
        );
        return SizedBox(
          width: width,
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Positioned.fromRect(
                rect: trackRect,
                child: CustomPaint(
                  painter: _TrackPainter(
                    ticks: ticks,
                    activeStart: startFraction,
                    activeEnd: endFraction,
                    inactiveTrackColor: colors.trackColor(
                      enabled,
                      active: false,
                    ),
                    activeTrackColor: colors.trackColor(enabled, active: true),
                    inactiveTickColor: colors.tickColor(enabled, active: false),
                    activeTickColor: colors.tickColor(enabled, active: true),
                    startThumb: box.width,
                    endThumb: box.width,
                    startGap: SliderTokens.activeHandleLeadingSpace,
                    endGap: SliderTokens.activeHandleLeadingSpace,
                    corner: corner,
                    isRange: true,
                    cornerShrinking: false,
                    vertical: false,
                    flipVertical: false,
                    rtl: _rtl,
                    centered: false,
                  ),
                ),
              ),
              _handleNode(
                isStart: true,
                rect: startRect,
                narrowed: startNarrowed,
                color: colors.thumbColor(enabled),
              ),
              _handleNode(
                isStart: false,
                rect: endRect,
                narrowed: endNarrowed,
                color: colors.thumbColor(enabled),
              ),
              if (label != null) ...<Widget>[
                _indicatorAbove(
                  startRect,
                  label(_startValue),
                  startNarrowed && enabled,
                ),
                _indicatorAbove(
                  endRect,
                  label(_endValue),
                  endNarrowed && enabled,
                ),
              ],
            ],
          ),
        );
      },
    );

    // Each thumb is its own node, stepped through its semantics: the
    // track's tap and drag are not actions of their own.
    return _SliderFrame(
      style: resolved,
      states: states,
      onHoverChanged: (hovered) => setState(() => _hovered = hovered),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        dragStartBehavior: DragStartBehavior.down,
        onTap: enabled ? _tap : null,
        onTapCancel: enabled ? _up : null,
        onHorizontalDragStart: enabled ? _dragStart : null,
        onHorizontalDragUpdate: enabled ? _dragUpdate : null,
        onHorizontalDragEnd: enabled ? (_) => _dragEnd() : null,
        onHorizontalDragCancel: enabled ? _dragEnd : null,
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: _down,
          onPointerUp: (_) => _up(),
          onPointerCancel: (_) => _up(),
          child: ExpressiveMinimumInteractiveSize(child: slider),
        ),
      ),
    );
  }
}

class _SliderFrame extends StatelessWidget {
  const _SliderFrame({
    required this.style,
    required this.states,
    required this.onHoverChanged,
    required this.child,
  });
  final ExpressiveComponentThemeData style;
  final Set<WidgetState> states;
  final ValueChanged<bool> onHoverChanged;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final minimum = style.minimumSize?.resolve(states) ?? Size.zero;
    return MouseRegion(
      // The click cursor over the whole slider, track and handles, as
      // Material's Slider shows it; a disabled slider defers to what is
      // around it.
      cursor: states.contains(WidgetState.disabled)
          ? MouseCursor.defer
          : SystemMouseCursors.click,
      onEnter: (_) => onHoverChanged(true),
      onExit: (_) => onHoverChanged(false),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: minimum.width,
          minHeight: minimum.height,
        ),
        child: Padding(
          padding: style.padding?.resolve(states) ?? EdgeInsets.zero,
          child: ExpressiveStyleScope(
            style: style,
            states: states,
            inset: EdgeInsets.zero,
            child: child,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quantity stepper
// ---------------------------------------------------------------------------

/// A whole-number quantity between two tonal icon buttons, − and +: a
/// cart line, guests, servings. Holding a button repeats; each button
/// disables at its bound. [format] shows the value (a unit, a price);
/// [label] names the quantity to a screen reader ("Increase Guests").
///
/// ```dart
/// ExpressiveNumberField(value: guests, min: 1, max: 8, label: 'Guests', onChanged: (v) => setState(() => guests = v))
/// ```
class ExpressiveNumberField extends StatefulWidget {
  /// A quantity stepper at [value] between [min] and [max], reporting a change through [onChanged].
  const ExpressiveNumberField({
    required this.value,
    required this.onChanged,
    this.style,
    this.min = 0,
    this.max = 99,
    this.step = 1,
    this.label,
    this.format,
    super.key,
  }) : assert(min <= max, 'min must not exceed max'),
       assert(step > 0, 'step must be positive');

  /// The current quantity.
  final int value;

  /// Stateful visual overrides for the buttons and value.
  final ExpressiveComponentThemeData? style;

  /// Called with each new quantity; null disables the stepper.
  final ValueChanged<int>? onChanged;

  /// The smallest quantity.
  final int min;

  /// The largest quantity.
  final int max;

  /// How far one press moves.
  final int step;

  /// What the quantity is, for a screen reader (the strings' `quantity`
  /// when null).
  final String? label;

  /// How the value reads; its decimal digits when null.
  final String Function(int value)? format;

  /// Whether it takes input: false when onChanged is null, as in Flutter.
  bool get enabled => onChanged != null;

  @override
  State<ExpressiveNumberField> createState() => _QuantityStepperState();
}

class _QuantityStepperState extends State<ExpressiveNumberField> {
  /// A hold repeats a fifth as often as the long-press timeout: the first
  /// repeat after the long-press timeout, then one per this interval.
  static final Duration _repeat = kLongPressTimeout ~/ 5;

  Timer? _timer;

  /// The value the current hold has reached (the parent may not have
  /// rebuilt between repeats).
  int? _held;

  /// A pointer press already stepped; the tap that ends it must not.
  bool _pointerStepped = false;

  bool get _enabled => widget.enabled && widget.onChanged != null;

  @override
  void didUpdateWidget(ExpressiveNumberField old) {
    super.didUpdateWidget(old);
    if (!_enabled || widget.min != old.min || widget.max != old.max) _stop();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
    _held = null;
  }

  /// Steps once in [direction]; false at the bound.
  bool _change(int direction) {
    if (!_enabled) return false;
    final from = _held ?? widget.value;
    final next = (from + direction * widget.step).clamp(widget.min, widget.max);
    if (next == from) return false;
    _held = next;
    HapticFeedback.selectionClick();
    widget.onChanged!(next);
    return true;
  }

  /// A finger down: step now, then repeat while it is held.
  void _start(int direction) {
    _stop();
    _pointerStepped = true;
    if (!_change(direction)) return;
    _timer = Timer(kLongPressTimeout, () {
      if (!_change(direction)) return _stop();
      _timer = Timer.periodic(_repeat, (_) {
        if (!_change(direction)) _stop();
      });
    });
  }

  void _release() {
    _stop();
    // The tap that ends this press runs after the pointer event; forget
    // the press once it has.
    scheduleMicrotask(() => _pointerStepped = false);
  }

  /// The button's activation: a key or a screen reader (a pointer press
  /// has already stepped).
  void _activate(int direction) {
    if (_pointerStepped) {
      _pointerStepped = false;
      return;
    }
    _stop();
    _change(direction);
    _held = null;
  }

  Widget _button(BuildContext context, int direction) {
    final t = context.expressiveTheme;
    final canStep =
        _enabled &&
        (direction < 0 ? widget.value > widget.min : widget.value < widget.max);
    final container = canStep
        ? t.colors.role(FilledTonalIconButtonTokens.containerColor)
        : t.colors
              .role(FilledTonalIconButtonTokens.disabledContainerColor)
              .withValues(
                alpha: FilledTonalIconButtonTokens.disabledContainerOpacity,
              );
    final content = canStep
        ? t.colors.role(FilledTonalIconButtonTokens.color)
        : t.colors
              .role(FilledTonalIconButtonTokens.disabledColor)
              .withValues(alpha: FilledTonalIconButtonTokens.disabledOpacity);
    return Listener(
      onPointerDown: canStep ? (_) => _start(direction) : null,
      onPointerUp: (_) => _release(),
      onPointerCancel: (_) => _release(),
      child: ExpressivePressable(
        style: widget.style,
        componentStyle: t.numberFieldTheme,
        shapes: ExpressivePressShapes(
          shape: t.shapes.of(SmallIconButtonTokens.containerShapeRound),
          pressed: t.shapes.of(SmallIconButtonTokens.pressedContainerShape),
        ),
        motion: IconButtonBehavior.pressMotion,
        color: container,
        contentColor: content,
        onPressed: canStep ? () => _activate(direction) : null,
        semanticLabel: (direction < 0
            ? ExpressiveLocalizations.of(context).decrease
            : ExpressiveLocalizations.of(context).increase)(_label(context)),
        // A tonal circle the checks may not tell from the page: marked, it
        // is read by its face, not by its glyph (a 2 px minus beside a
        // 14 px plus).
        child: DesignKeylineFace(
          child: ExpressiveStyledContent(
            minimumSize: const Size.square(
              SmallIconButtonTokens.containerHeight,
            ),
            iconSize: SmallIconButtonTokens.iconSize,
            child: Icon(
              direction < 0 ? ExpressiveSymbols.remove : ExpressiveSymbols.add,
            ),
          ),
        ),
      ),
    );
  }

  String _label(BuildContext context) =>
      widget.label ?? ExpressiveLocalizations.of(context).quantity;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final text = widget.format?.call(widget.value) ?? '${widget.value}';
    final resolved = t.numberFieldTheme.merge(widget.style);
    final states = expressiveComponentStates(enabled: _enabled);
    final onSurface = t.colors.onSurface;
    // The value is set in the labels' type (a button's labelLarge): one
    // size on the line, so it shares their baseline and their middle.
    final valueStyle = t.type.labelLarge
        .copyWith(
          color: _enabled
              ? onSurface
              : onSurface.withValues(
                  alpha: FilledTonalIconButtonTokens.disabledOpacity,
                ),
          fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
        )
        .merge(resolved.textStyle?.resolve(states))
        .copyWith(color: resolved.foregroundColor?.resolve(states));
    final value = ExcludeSemantics(
      child: Padding(
        padding: t.density.padding(
          const EdgeInsets.symmetric(horizontal: ExpressiveSpacing.s8),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: valueStyle,
        ),
      ),
    );
    return Semantics(
      container: true,
      label: _label(context),
      value: text,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final decrease = _button(context, -1);
          final increase = _button(context, 1);
          if (constraints.maxWidth < ExpressiveSpacing.s48 * 3) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                value,
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [decrease, increase],
                ),
              ],
            );
          }
          // The end circles stand on the stepper's own edges (a row's
          // keyline), their 48dp targets reaching past them.
          final drawn = t.density.width(
            SmallIconButtonTokens.containerHeight,
            floor: 0,
          );
          final reach = ExpressiveMinimumInteractiveSize.enforcedAt(context)
              ? math.max(
                      0.0,
                      HostBehavior.minimumInteractiveComponentSize - drawn,
                    ) /
                    2
              : 0.0;
          return ExpressiveReach(
            start: reach,
            end: reach,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                decrease,
                Flexible(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: ExpressiveSpacing.s48,
                    ),
                    child: value,
                  ),
                ),
                increase,
              ],
            ),
          );
        },
      ),
    );
  }
}

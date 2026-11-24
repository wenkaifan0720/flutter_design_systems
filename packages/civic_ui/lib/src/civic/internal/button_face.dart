import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../theme.dart';
import 'paint.dart';
import 'spinner_arc.dart';
import 'spring.dart';

/// A solid button's face by night, from [colour] (the action's or the
/// error's): its hue at the lightest tone that carries white words at
/// 4.5:1 (they are large and bold), on an edge of the same hue darker. The
/// light tone those colours take by night for words on the page (7:1) is
/// too pale for a face: a button in it read washed out. This one keeps the
/// button's weight on the slate (about 3.8:1 against the night page).
(Color, Color, Color) civicNightFace(Color colour) {
  const white = Color(0xFFFFFFFF);
  final hsl = HSLColor.fromColor(colour);
  final hue = hsl.withSaturation(math.min(hsl.saturation, 0.85));
  var near = hue.lightness;
  var far = 0.0;
  for (var i = 0; i < 24; i++) {
    final mid = (near + far) / 2;
    if (CivicThemeData.contrastRatio(hue.withLightness(mid).toColor(), white) >=
        4.5) {
      far = mid;
    } else {
      near = mid;
    }
  }
  var face = hue.withLightness(far).toColor();
  // The channels round to 8 bits: a step on where that fell just short.
  while (CivicThemeData.contrastRatio(face, white) < 4.5 && far > 0) {
    far = math.max(0, far - 0.004);
    face = hue.withLightness(far).toColor();
  }
  return (face, white, hue.withLightness(far * 0.68).toColor());
}

/// Which of Civic's buttons a [CivicButtonFace] paints.
enum CivicButtonKind {
  /// The page's one action, solid in the action colour.
  primary,

  /// An action beside it, the action's tint.
  secondary,

  /// The start of a service, larger, with its arrow.
  start,
}

/// A Civic button's face in [states]: its fill on the solid edge a press
/// sinks onto, deeper under a pointer, the yellow flood over the ink bar
/// for the keyboard, every change on Civic's springs. [CivicButton] and
/// each half of [CivicSplitButton] paint with it. Plumbing; pages never
/// place one.
class CivicButtonFace extends StatelessWidget {
  /// A face of [kind] round [child].
  const CivicButtonFace({
    super.key,
    required this.states,
    required this.kind,
    required this.child,
    this.destructive = false,
    this.icon,
    this.style,
    this.contentPadding,
    this.busy = false,
    this.busyLabel,
  });

  /// The pressable's states.
  final Set<WidgetState> states;

  /// Which button it is.
  final CivicButtonKind kind;

  /// The words (or a glyph, which takes their colour).
  final Widget child;

  /// Whether it confirms a loss: the error colour.
  final bool destructive;

  /// A glyph after the words.
  final IconData? icon;

  /// The part's own style, over its kind's theme.
  final CivicStyle? style;

  /// The room round [child] where the style gives none; null: the kind's.
  final EdgeInsets? contentPadding;

  /// Whether its press is being sent: the words cross to a turning arc and
  /// [busyLabel], said to a screen reader, and a pointer neither deepens
  /// nor sinks it.
  final bool busy;

  /// The words while [busy]; null: "Loading". Given, the face holds the
  /// width of the wider of its two words, busy or not.
  final String? busyLabel;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final text = context.civicText;
    final start = kind == CivicButtonKind.start;
    final height = start ? 56.0 : CivicMetrics.controlHeight;
    final kindStyle = destructive
        ? t.destructiveButtonStyle
        : switch (kind) {
            CivicButtonKind.primary => t.primaryButtonStyle,
            CivicButtonKind.secondary => t.secondaryButtonStyle,
            CivicButtonKind.start => t.startButtonStyle,
          };
    final so = RawStyleOf([style, kindStyle], states);
    final disabled = states.contains(WidgetState.disabled);
    final secondary = kind == CivicButtonKind.secondary;
    // A secondary button is a tint of its words' colour (the
    // action's, or the error's when it destroys) on a deeper tint's
    // edge, with no stroke round it.
    Color tint(Color c, double a) =>
        Color.alphaBlend(c.withValues(alpha: a), t.background);
    final (fill, ink, edge) = disabled
        ? (t.disabledFill, t.textDisabled, t.rule)
        : secondary && destructive
        ? (
            tint(t.danger, t.isDark ? 0.2 : 0.12),
            t.danger,
            tint(t.danger, t.isDark ? 0.45 : 0.4),
          )
        : destructive
        ? (t.isDark
              ? civicNightFace(t.danger)
              : (t.danger, t.onDanger, t.dangerEdge))
        : secondary
        ? (t.secondaryFill, t.onSecondary, t.secondaryEdge)
        : t.isDark
        ? civicNightFace(t.action)
        : (t.action, t.onAction, t.actionEdge);
    final pressed = !busy && states.contains(WidgetState.pressed) ? 1.0 : 0.0;
    final focused = states.contains(WidgetState.focused) ? 1.0 : 0.0;
    final hovered = !busy && states.contains(WidgetState.hovered) ? 1.0 : 0.0;
    final scaler = MediaQuery.textScalerOf(context);
    final busyWords =
        busyLabel ?? RawWidgetsLocalizations.of(context).loadingLabel;
    final words = (start ? text.headingM : text.button).merge(so.textStyle);
    final padding =
        so.padding(Directionality.of(context)) ??
        contentPadding ??
        EdgeInsets.symmetric(
          horizontal: start ? CivicSpacing.s24 : CivicSpacing.s20,
        );
    // The face's room over and under the words grows with them, so
    // large words never run edge to edge.
    final room = CivicSpacing.s8 * scaler.scale(1).clamp(1.0, 1.75);
    final asked = so.minimumSize;
    final min = Size(asked?.width ?? 0, math.max(asked?.height ?? 0, height));
    return CivicSpringValue(
      value: hovered,
      spring: CivicMotion.press,
      effects: true,
      builder: (context, hover, _) => CivicSpringValue(
        value: pressed,
        spring: CivicMotion.press,
        builder: (context, press, _) => CivicSpringValue(
          value: focused,
          spring: CivicMotion.focus,
          effects: true,
          builder: (context, focus, _) {
            // A pointer over it deepens its face (by night, lifts it):
            // a solid face a clear step darker, a tinted one a step
            // toward its edge.
            final rest = so.fill ?? fill;
            // A face under light words deepens; one under dark words (a
            // light face an app chose) lifts, so the words keep their
            // contrast either way.
            final deepens = (so.foreground ?? ink).computeLuminance() > 0.5;
            final over = secondary
                ? Color.lerp(rest, so.edge ?? edge, 0.45)!
                : deepens
                ? Color.lerp(
                    rest,
                    const Color(0xFF000000),
                    t.isDark ? 0.25 : 0.35,
                  )!
                : Color.lerp(rest, const Color(0xFFFFFFFF), 0.25)!;
            final face = disabled ? rest : Color.lerp(rest, over, hover)!;
            // A deepening face's edge deepens with it, so the deeper face
            // still stands on a darker edge.
            final base = so.edge ?? edge;
            final under = disabled || secondary || !deepens
                ? base
                : Color.lerp(base, const Color(0xFF000000), 0.5 * hover)!;
            final fg = Color.lerp(so.foreground ?? ink, t.onFocus, focus)!;
            final label = Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: CivicSpacing.s8,
              children: [
                Flexible(
                  child: RawCapCenter(
                    capHeightFactor: context.civicText.capHeight,
                    child: DefaultTextStyle(
                      style: words.copyWith(color: fg),
                      textAlign: TextAlign.center,
                      // A glyph for words (a split button's chevron) takes
                      // the words' colour.
                      child: IconTheme.merge(
                        data: IconThemeData(color: fg, size: so.iconSize ?? 22),
                        child: child,
                      ),
                    ),
                  ),
                ),
                if (icon != null)
                  // The start's arrow points the way the words read.
                  Transform.flip(
                    flipX:
                        start &&
                        Directionality.of(context) == TextDirection.rtl,
                    child: Icon(
                      icon,
                      size: so.iconSize ?? (start ? 28 : 22),
                      color: fg,
                      applyTextScaling: true,
                    ),
                  ),
              ],
            );
            final content = busy || busyLabel != null
                ? CivicSpringValue(
                    value: busy ? 1 : 0,
                    spring: CivicMotion.state,
                    effects: true,
                    builder: (context, b, _) {
                      final arc = scaler.scale(18);
                      final shown = b.clamp(0.0, 1.0);
                      // Both words stand in one place, so the face holds
                      // its width as they cross.
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          ExcludeSemantics(
                            excluding: busy,
                            child: Opacity(opacity: 1 - shown, child: label),
                          ),
                          ExcludeSemantics(
                            excluding: !busy,
                            child: Semantics(
                              liveRegion: busy,
                              label: busyWords,
                              child: ExcludeSemantics(
                                child: Opacity(
                                  opacity: shown,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    spacing: CivicSpacing.s8,
                                    children: [
                                      // Turning only while it shows.
                                      if (shown > 0.001)
                                        CivicSpinnerArc(
                                          size: arc,
                                          color: fg,
                                          ring: fg.withValues(alpha: 0.35),
                                        )
                                      else
                                        SizedBox.square(dimension: arc),
                                      Flexible(
                                        child: RawCapCenter(
                                          capHeightFactor:
                                              context.civicText.capHeight,
                                          child: Text(
                                            busyWords,
                                            textAlign: TextAlign.center,
                                            style: words.copyWith(color: fg),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  )
                : label;
            return CustomPaint(
              painter: CivicFacePainter(
                fill: face,
                edgeColor: under,
                edgeHeight: CivicMetrics.bar,
                press: press,
                focus: focus,
                focusColor: t.focus,
                barColor: t.focusBar,
                side: disabled ? null : so.side,
                radius: CivicMetrics.corner,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: min.width,
                  minHeight: min.height,
                ),
                child: Padding(
                  // The words stand on the face, above the edge, and
                  // sink with it.
                  padding: EdgeInsets.only(
                    top: CivicMetrics.bar * press,
                    bottom: CivicMetrics.bar * (1 - press),
                  ),
                  child: Padding(
                    padding: padding.add(EdgeInsets.symmetric(vertical: room)),
                    child: Center(
                      widthFactor: 1,
                      heightFactor: 1,
                      child: content,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

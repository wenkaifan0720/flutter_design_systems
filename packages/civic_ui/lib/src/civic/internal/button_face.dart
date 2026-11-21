import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../theme.dart';
import 'paint.dart';
import 'spinner_arc.dart';
import 'spring.dart';

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
    final so = DesignStyleOf([style, kindStyle], states);
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
        ? (t.danger, t.onDanger, t.dangerEdge)
        : secondary
        ? (t.secondaryFill, t.onSecondary, t.secondaryEdge)
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
            final over = secondary
                ? Color.lerp(rest, so.edge ?? edge, 0.45)!
                : t.isDark
                ? Color.lerp(rest, const Color(0xFFFFFFFF), 0.25)!
                : Color.lerp(rest, const Color(0xFF000000), 0.35)!;
            final face = disabled ? rest : Color.lerp(rest, over, hover)!;
            // By day a solid face's edge deepens with it, so the
            // deeper face still stands on a darker edge.
            final base = so.edge ?? edge;
            final under = disabled || secondary || t.isDark
                ? base
                : Color.lerp(base, const Color(0xFF000000), 0.5 * hover)!;
            final fg = Color.lerp(so.foreground ?? ink, t.onFocus, focus)!;
            final label = Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: CivicSpacing.s8,
              children: [
                Flexible(
                  child: DesignCapCenter(
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
                                        child: DesignCapCenter(
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

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../internal/paint.dart';
import '../../internal/spring.dart';
import '../../theme.dart';

/// A glyph that acts, on a squared face only the press and the focus show:
/// a press sinks it into the page's band, a keyboard focus floods it yellow
/// over the ink bar. Its [semanticLabel] is required: a glyph alone says
/// nothing to someone who cannot see it.
///
/// Reads [CivicStyle]'s fill, foreground, minimumSize (never under 48
/// points a side) and iconSize, by state: its `style:`, then
/// [CivicThemeData.iconButtonStyle]. With no foreground, the glyph takes
/// the surrounding [IconTheme]'s colour.
///
/// ```dart
/// CivicIconButton(
///   icon: LucideIcons.x,
///   semanticLabel: 'Close',
///   onPressed: () => Navigator.of(context).pop(),
/// )
/// ```
class CivicIconButton extends StatelessWidget {
  /// A glyph that acts.
  const CivicIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.style,
    this.focusNode,
    this.autofocus = false,
    this.statesController,
  });

  /// The glyph.
  final IconData icon;

  /// What it does, in words a screen reader says.
  final String semanticLabel;

  /// Called on a press; null disables it.
  final VoidCallback? onPressed;

  /// Overrides for this button's look.
  final CivicStyle? style;

  /// {@macro civic.focusNode}
  final FocusNode? focusNode;

  /// {@macro civic.autofocus}
  final bool autofocus;

  /// {@macro civic.statesController}
  final WidgetStatesController? statesController;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    return DesignTapTarget(
      child: DesignPressable(
        onPressed: onPressed,
        focusNode: focusNode,
        autofocus: autofocus,
        statesController: statesController,
        semanticLabel: semanticLabel,
        mouseCursor: onPressed == null
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
        builder: (context, states, _) {
          final so = DesignStyleOf([style, t.iconButtonStyle], states);
          final disabled = states.contains(WidgetState.disabled);
          // On a band of its own (the top bar's ink) it takes the band's glyph
          // colour.
          final ink = disabled
              ? t.textDisabled
              : so.foreground ?? IconTheme.of(context).color ?? t.textPrimary;
          final asked =
              so.minimumSize ?? const Size.square(CivicMetrics.controlHeight);
          final size = Size(
            math.max(asked.width, CivicMetrics.controlHeight),
            math.max(asked.height, CivicMetrics.controlHeight),
          );
          return CivicSpringValue(
            value: states.contains(WidgetState.pressed) ? 1 : 0,
            spring: CivicMotion.press,
            effects: true,
            builder: (context, press, _) => CivicSpringValue(
              value: states.contains(WidgetState.focused) ? 1 : 0,
              spring: CivicMotion.focus,
              effects: true,
              builder: (context, focus, _) => CustomPaint(
                painter: CivicFacePainter(
                  // A press veils the face in its glyph's colour, so it shows
                  // on the page and on the top bar's band alike.
                  fill: Color.lerp(
                    so.fill ?? ink.withValues(alpha: 0),
                    ink.withValues(alpha: 0.16),
                    press,
                  )!,
                  edgeColor: t.onFocus,
                  edgeHeight: 0,
                  press: 0,
                  focus: focus,
                  focusColor: t.focus,
                  barColor: t.focusBar,
                  radius: CivicMetrics.corner,
                ),
                child: SizedBox.fromSize(
                  size: size,
                  child: Center(
                    child: Icon(
                      icon,
                      size: so.iconSize ?? 24,
                      color: Color.lerp(ink, t.onFocus, focus),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<IconData>('icon', icon))
      ..add(StringProperty('semanticLabel', semanticLabel))
      ..add(ObjectFlagProperty<VoidCallback>.has('onPressed', onPressed))
      ..add(DiagnosticsProperty<CivicStyle>('style', style, defaultValue: null))
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'))
      ..add(
        DiagnosticsProperty<WidgetStatesController>(
          'statesController',
          statesController,
          defaultValue: null,
        ),
      );
  }
}

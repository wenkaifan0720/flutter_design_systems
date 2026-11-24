import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../internal/paint.dart';
import '../../internal/spring.dart';
import '../../theme.dart';
import '../tooltip/tooltip.dart';

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
/// With a [tooltip] a pointer resting on it, the keyboard reaching it and a
/// long press show those words beside it ([CivicTooltip]).
///
/// A glyph that is on or off (Reminders, Saved) takes [isSelected]: on, it
/// stands solid in the action colour with the glyph in its ink, as a chosen
/// [CivicChip] does, and a screen reader hears it as a toggle. What it holds
/// (a count drawn over it) is its [semanticValue], read after its name.
///
/// ```dart
/// CivicIconButton(
///   icon: LucideIcons.x,
///   semanticLabel: 'Close',
///   tooltip: 'Close',
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
    this.tooltip,
    this.isSelected,
    this.semanticValue,
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

  /// Words shown beside it on a pointer's rest, the keyboard's focus and a
  /// long press; null shows none. A screen reader hears [semanticLabel],
  /// and this too where it says more.
  final String? tooltip;

  /// Whether it is on, for a glyph that turns something on and off; null
  /// for one that acts once.
  final bool? isSelected;

  /// What it holds, read after [semanticLabel] ("3 new" for a count drawn
  /// over it); null reads nothing more.
  final String? semanticValue;

  @override
  Widget build(BuildContext context) {
    final words = tooltip;
    if (words == null || words.isEmpty) return _button(context);
    return CivicTooltip(
      message: words,
      excludeFromSemantics: words == semanticLabel,
      child: _button(context),
    );
  }

  Widget _button(BuildContext context) {
    final t = context.civicTheme;
    return TapTargetPadding(
      child: RawButton(
        onPressed: onPressed,
        focusNode: focusNode,
        autofocus: autofocus,
        statesController: statesController,
        semanticLabel: semanticLabel,
        semanticValue: semanticValue,
        selected: isSelected ?? false,
        // A toggle button: a button that is selected, as
        // IconButton(isSelected:) is.
        semanticSelected: isSelected,
        mouseCursor: onPressed == null
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
        builder: (context, states, _) {
          final so = RawStyleOf([style, t.iconButtonStyle], states);
          final disabled = states.contains(WidgetState.disabled);
          final on = isSelected ?? false;
          // On a band of its own (the top bar's ink) it takes the band's glyph
          // colour.
          final ink = disabled
              ? t.textDisabled
              : so.foreground ??
                    (on ? t.onAction : null) ??
                    IconTheme.of(context).color ??
                    t.textPrimary;
          final asked =
              so.minimumSize ?? const Size.square(CivicMetrics.controlHeight);
          final size = Size(
            math.max(asked.width, CivicMetrics.controlHeight),
            math.max(asked.height, CivicMetrics.controlHeight),
          );
          // A pointer over it veils the face lightly, a press deeper.
          final veil = disabled
              ? 0.0
              : states.contains(WidgetState.pressed)
              ? 1.0
              : states.contains(WidgetState.hovered)
              ? 0.5
              : 0.0;
          return CivicSpringValue(
            value: veil,
            spring: CivicMotion.press,
            effects: true,
            builder: (context, press, _) => CivicSpringValue(
              value: states.contains(WidgetState.focused) ? 1 : 0,
              spring: CivicMotion.focus,
              effects: true,
              builder: (context, focus, _) => CustomPaint(
                painter: CivicFacePainter(
                  // The veil is the glyph's colour, so it shows on the page
                  // and on the top bar's band alike.
                  fill: Color.lerp(
                    so.fill ??
                        (on && !disabled ? t.action : ink.withValues(alpha: 0)),
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
      )
      ..add(StringProperty('tooltip', tooltip, defaultValue: null))
      ..add(
        DiagnosticsProperty<bool>('isSelected', isSelected, defaultValue: null),
      )
      ..add(StringProperty('semanticValue', semanticValue, defaultValue: null));
  }
}

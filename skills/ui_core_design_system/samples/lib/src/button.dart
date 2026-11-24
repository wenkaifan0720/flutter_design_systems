import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'face.dart';
import 'theme.dart';

/// A [LookButton]'s kind.
enum LookButtonVariant {
  /// The accent plate: the one thing to act on.
  filled,

  /// A plate in the rule: everything beside it.
  outlined,
}

/// The face a button of [variant] shows for [states]: what [LookButton]
/// draws and what a dialog's actions draw. [style] is read first, then the
/// theme's [LookThemeData.buttonStyle], then the look's own default.
LookFace lookButtonFace(
  LookThemeData theme,
  Set<WidgetState> states, {
  LookButtonVariant variant = LookButtonVariant.filled,
  bool destructive = false,
  LookStyle? style,
}) {
  final c = theme.colors;
  final look = RawStyleOf([style, theme.buttonStyle], states);
  final tone = destructive ? c.danger : c.accent;
  final onTone = destructive ? c.onDanger : c.onAccent;
  if (states.contains(WidgetState.disabled)) {
    return LookFace(
      fill: look.fill ?? c.ground,
      rule: look.edge ?? c.rule,
      foreground: look.foreground ?? c.mutedInk,
    );
  }
  final filled = variant == LookButtonVariant.filled;
  final rest = look.fill ?? (filled ? tone : c.surface);
  return LookFace(
    // A press darkens the plate a step (lightens it by night): ink over it.
    fill: states.contains(WidgetState.pressed)
        ? Color.alphaBlend(c.ink.withValues(alpha: .12), rest)
        : rest,
    // Keyboard focus is the look's own rule, darker and twice as heavy: no
    // ring is added round the part.
    rule: states.contains(WidgetState.focused)
        ? c.ink
        : look.edge ?? (filled ? tone : c.rule),
    ruleWidth: states.contains(WidgetState.focused) ? 2 : 1,
    foreground: look.foreground ?? (filled ? onTone : tone),
  );
}

/// The look's button: a label, an optional glyph before it, and an action.
///
/// A null [onPressed] disables it. Its face is [lookButtonFace]; its tap
/// target reaches the theme's floor whatever its face's size.
///
/// ```dart
/// LookButton('Save', onPressed: () {})
/// ```
class LookButton extends StatelessWidget {
  /// A button saying [label].
  const LookButton(
    this.label, {
    super.key,
    required this.onPressed,
    this.variant = LookButtonVariant.filled,
    this.destructive = false,
    this.icon,
    this.style,
    this.focusNode,
    this.autofocus = false,
  });

  /// What it says.
  final String label;

  /// What a press does; null disables it.
  final VoidCallback? onPressed;

  /// Filled or outlined.
  final LookButtonVariant variant;

  /// Whether the action deletes or cannot be undone.
  final bool destructive;

  /// A glyph before the label.
  final IconData? icon;

  /// This button's style, over the theme's.
  final LookStyle? style;

  /// {@macro design.focusNode}
  final FocusNode? focusNode;

  /// {@macro design.autofocus}
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final theme = LookTheme.of(context);
    return TapTargetPadding(
      child: RawButton(
        onPressed: onPressed,
        focusNode: focusNode,
        autofocus: autofocus,
        builder: (context, states, _) {
          final look = RawStyleOf([style, theme.buttonStyle], states);
          return AnimatedLookSurface(
            face: lookButtonFace(
              theme,
              states,
              variant: variant,
              destructive: destructive,
              style: style,
            ),
            shape:
                look.shape ??
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(theme.radius),
                ),
            child: Padding(
              padding:
                  look.padding(Directionality.of(context)) ??
                  theme.density.padding(
                    const EdgeInsets.symmetric(horizontal: 16),
                  ),
              child: RawControlBox(
                minHeight:
                    look.minimumSize?.height ??
                    theme.density.height(theme.controlHeight),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: look.iconSize ?? 18),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: RawCapCenter(
                        capHeightFactor: theme.capHeightFactor,
                        child: Text(
                          label,
                          style: theme.label.merge(look.textStyle),
                          maxLines: 2,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
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
      ..add(StringProperty('label', label))
      ..add(ObjectFlagProperty<VoidCallback>.has('onPressed', onPressed))
      ..add(EnumProperty<LookButtonVariant>('variant', variant))
      ..add(
        FlagProperty('destructive', value: destructive, ifTrue: 'destructive'),
      );
  }
}

/// A glyph that acts, or a toggle button when [isSelected] is not null (a
/// pin, a formatting bar's Bold): read as a button that is selected, as
/// Flutter's `IconButton(isSelected:)` is, never as a switch.
///
/// ```dart
/// LookIconButton(icon: const IconData(0xe5d2), semanticLabel: 'Menu', onPressed: () {})
/// ```
class LookIconButton extends StatelessWidget {
  /// A button showing [icon], named [semanticLabel].
  const LookIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.isSelected,
    this.focusNode,
  });

  /// The glyph.
  final IconData icon;

  /// What a screen reader calls it; the glyph says nothing in words.
  final String semanticLabel;

  /// What a press does; null disables it.
  final VoidCallback? onPressed;

  /// Whether a toggle button is on; null for a plain icon button.
  final bool? isSelected;

  /// {@macro design.focusNode}
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final theme = LookTheme.of(context);
    final c = theme.colors;
    return TapTargetPadding(
      child: RawButton(
        onPressed: onPressed,
        focusNode: focusNode,
        semanticLabel: semanticLabel,
        selected: isSelected ?? false,
        semanticSelected: isSelected,
        builder: (context, states, _) {
          final on = states.contains(WidgetState.selected);
          final focused = states.contains(WidgetState.focused);
          return AnimatedLookSurface(
            face: LookFace(
              fill: on ? c.ink : c.surface,
              rule: focused ? c.ink : (on ? c.ink : c.rule),
              ruleWidth: focused ? 2 : 1,
              foreground: states.contains(WidgetState.disabled)
                  ? c.mutedInk
                  : (on ? c.surface : c.ink),
            ),
            shape: const CircleBorder(),
            child: SizedBox.square(
              dimension: theme.density.height(theme.controlHeight),
              child: Icon(icon, size: 20),
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
      ..add(StringProperty('semanticLabel', semanticLabel))
      ..add(
        DiagnosticsProperty<bool>('isSelected', isSelected, defaultValue: null),
      );
  }
}

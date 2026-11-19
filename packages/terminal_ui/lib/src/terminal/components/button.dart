/// Buttons: a label in brackets, `[ Deploy ]`, pressed in inverse video and
/// focused under the cursor.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../primitives/box.dart';
import '../primitives/control.dart';
import '../style.dart';
import '../theme.dart';
import 'key_hint.dart';

/// A button, as a terminal program draws one: its [label] in brackets,
/// `[ Deploy ]`, one line tall and as many cells wide as the label and its
/// brackets take, with the key that works it written after it.
///
/// A press fills the cells between the brackets in inverse video; the
/// keyboard's focus is the cursor, a block of the accent over every cell
/// with the brackets cut out of it (on a filled button, hollow: the bracket
/// cells in the accent, the fill cleared); under the pointer nothing
/// changes but the mouse cursor. [onPressed] null disables it.
///
/// [TermButton.filled] is a screen's one primary action, filled in the
/// accent; [isDestructiveAction] draws either in the danger ink.
///
/// ```dart
/// TermButton(
///   label: 'Cancel',
///   shortcut: const SingleActivator(LogicalKeyboardKey.escape),
///   onPressed: () {},
/// )
/// ```
///
/// Reads [TermStyle]'s `fill` (between the brackets), `foreground` (the
/// label), `edge` (the brackets) and `textStyle`.
class TermButton extends StatelessWidget {
  /// A bracketed button.
  const TermButton({
    super.key,
    required this.label,
    this.onPressed,
    this.shortcut,
    this.isDestructiveAction = false,
    this.focusNode,
    this.autofocus = false,
    this.style,
  }) : filled = false;

  /// The screen's primary button: the cells between its brackets filled in
  /// the accent (or, destructive, the danger ink).
  const TermButton.filled({
    super.key,
    required this.label,
    this.onPressed,
    this.shortcut,
    this.isDestructiveAction = false,
    this.focusNode,
    this.autofocus = false,
    this.style,
  }) : filled = true;

  /// The words in the brackets.
  final String label;

  /// Called on a press, Return or Space; null disables the button.
  final VoidCallback? onPressed;

  /// The key that works this action, written after the button. The app
  /// binds it (with `Shortcuts` or `CallbackShortcuts`); the button shows
  /// it.
  final SingleActivator? shortcut;

  /// Whether the action destroys something: drawn in the danger ink.
  final bool isDestructiveAction;

  /// Whether the button is filled (the primary action).
  final bool filled;

  /// {@template term.focusNode}
  /// Its focus; one given is the caller's to dispose, and null makes and
  /// disposes its own.
  /// {@endtemplate}
  final FocusNode? focusNode;

  /// {@template term.autofocus}
  /// Whether it takes focus when first shown.
  /// {@endtemplate}
  final bool autofocus;

  /// Overrides for the fill, the label, the brackets and the words' style,
  /// by state.
  final TermStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final grid = context.termGrid;
    final stroke = termStroke(theme, grid);
    final keys = shortcut == null || !termKeysShown(context)
        ? null
        : termKeyLabel(shortcut!);
    final ink = isDestructiveAction ? theme.danger : theme.accent;
    return TermTapTarget(
      child: DesignPressable(
        onPressed: onPressed,
        focusNode: focusNode,
        autofocus: autofocus,
        semanticLabel: label,
        semanticHint: keys,
        excludeSemantics: true,
        mouseCursor: onPressed == null
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
        builder: (context, states, _) {
          final disabled = states.contains(WidgetState.disabled);
          final own = TermStyleOf([
            style,
            if (isDestructiveAction) theme.destructiveButtonStyle,
            filled ? theme.filledButtonStyle : theme.buttonStyle,
          ], states);
          return TermStateSprings(
            pressed: states.contains(WidgetState.pressed),
            focused: states.contains(WidgetState.focused),
            builder: (context, press, focus) {
              final Color words;
              final Color brackets;
              final Color? fill;
              final double fillAmount;
              if (disabled) {
                fill = filled ? theme.rule.withValues(alpha: 0.35) : null;
                words = filled
                    ? termReadable(
                        theme.dim,
                        on: Color.alphaBlend(own.fill ?? fill!, theme.surface),
                      )
                    : theme.rule;
                brackets = theme.rule.withValues(alpha: 0.6);
                fillAmount = 1;
              } else if (filled) {
                // The cursor on a filled button hollows it: its bracket
                // cells in the accent, its fill cleared, its words in the
                // accent on the ground.
                final base = ink;
                fill = Color.lerp(base, theme.foreground, press * 0.4);
                fillAmount = 1;
                words = termCursorInk(
                  theme,
                  theme.onAccent,
                  focus,
                  hollow: true,
                );
                brackets = base;
              } else {
                // The cursor over the rest: a block of the accent, the
                // brackets taken in and cut out of it.
                fill = isDestructiveAction ? theme.danger : theme.foreground;
                fillAmount = press;
                words = termCursorInk(
                  theme,
                  Color.lerp(
                    isDestructiveAction ? theme.danger : theme.foreground,
                    theme.background,
                    press,
                  )!,
                  focus,
                );
                brackets = theme.rule;
              }
              final face = CustomPaint(
                painter: TermBracketPainter(
                  grid: grid,
                  color: own.edge ?? brackets,
                  stroke: stroke,
                  fill: own.fill ?? fill,
                  fillAmount: fillAmount,
                  cursor: disabled ? 0 : focus,
                  cursorColor: theme.accent,
                  knockout: theme.onAccent,
                  hollow: filled,
                ),
                child: SizedBox(
                  height: grid.lineHeight,
                  child: Padding(
                    padding: EdgeInsetsDirectional.symmetric(
                      horizontal: grid.cols(2),
                    ),
                    child: Text(
                      label,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textStyle
                          .merge(own.textStyle)
                          .copyWith(color: own.foreground ?? words),
                    ),
                  ),
                ),
              );
              if (keys == null) return face;
              // Where the line is short, the label gives way (it ends in
              // an ellipsis) and the key stays.
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(child: face),
                  SizedBox(width: grid.cellWidth),
                  ExcludeSemantics(child: TermKey(keys)),
                ],
              );
            },
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
      ..add(
        FlagProperty('enabled', value: onPressed != null, ifFalse: 'disabled'),
      )
      ..add(FlagProperty('filled', value: filled, ifTrue: 'filled'))
      ..add(
        FlagProperty(
          'isDestructiveAction',
          value: isDestructiveAction,
          ifTrue: 'destructive',
        ),
      )
      ..add(
        DiagnosticsProperty<SingleActivator>(
          'shortcut',
          shortcut,
          defaultValue: null,
        ),
      )
      ..add(DiagnosticsProperty<TermStyle>('style', style, defaultValue: null));
  }
}

/// A one-glyph button: [glyph] in brackets, `[?]`, three cells wide,
/// read to a screen reader as [semanticLabel].
///
/// ```dart
/// TermIconButton(glyph: '?', semanticLabel: 'Help', onPressed: () {})
/// ```
///
/// Reads [TermStyle]'s `fill`, `foreground`, `edge` and `textStyle`, as
/// [TermButton] does.
class TermIconButton extends StatelessWidget {
  /// A bracketed glyph.
  const TermIconButton({
    super.key,
    required this.glyph,
    required this.semanticLabel,
    this.onPressed,
    this.selected,
    this.focusNode,
    this.autofocus = false,
    this.style,
  });

  /// The one character in the brackets (`?`, `≡`, `×`, `/`).
  final String glyph;

  /// What a screen reader says it does.
  final String semanticLabel;

  /// Called on a press; null disables it.
  final VoidCallback? onPressed;

  /// Whether it is a toggle that is on (drawn in inverse video); null for an
  /// ordinary button.
  final bool? selected;

  /// {@macro term.focusNode}
  final FocusNode? focusNode;

  /// {@macro term.autofocus}
  final bool autofocus;

  /// Overrides for the fill, the glyph, the brackets and the words' style.
  final TermStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final grid = context.termGrid;
    final stroke = termStroke(theme, grid);
    final on = selected ?? false;
    return TermTapTarget(
      child: DesignPressable(
        onPressed: onPressed,
        focusNode: focusNode,
        autofocus: autofocus,
        selected: on,
        toggled: selected,
        semanticLabel: semanticLabel,
        mouseCursor: onPressed == null
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
        builder: (context, states, _) {
          final disabled = states.contains(WidgetState.disabled);
          final own = TermStyleOf([style, theme.iconButtonStyle], states);
          return TermStateSprings(
            pressed: states.contains(WidgetState.pressed),
            focused: states.contains(WidgetState.focused),
            builder: (context, press, focus) {
              final amount = on ? 1.0 : press;
              final words = disabled
                  ? theme.rule
                  : termCursorInk(
                      theme,
                      Color.lerp(theme.foreground, theme.background, amount)!,
                      focus,
                      hollow: on,
                    );
              return CustomPaint(
                painter: TermBracketPainter(
                  grid: grid,
                  color:
                      own.edge ??
                      (disabled
                          ? theme.rule.withValues(alpha: 0.6)
                          : theme.rule),
                  stroke: stroke,
                  fill: own.fill ?? (disabled ? null : theme.foreground),
                  fillAmount: amount,
                  cursor: disabled ? 0 : focus,
                  cursorColor: theme.accent,
                  knockout: theme.onAccent,
                  hollow: on,
                ),
                child: SizedBox(
                  width: grid.cols(3),
                  height: grid.lineHeight,
                  child: Center(
                    child: ExcludeSemantics(
                      child: Text(
                        glyph,
                        // As given, never mirrored: a `>` prompt stays `>` in
                        // a right-to-left app; a glyph that points (a back
                        // arrow, a month's ‹ ›) is its caller's to pick.
                        textDirection: TextDirection.ltr,
                        maxLines: 1,
                        softWrap: false,
                        style: theme.textStyle
                            .merge(own.textStyle)
                            .copyWith(color: own.foreground ?? words),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('glyph', glyph))
      ..add(StringProperty('semanticLabel', semanticLabel))
      ..add(
        FlagProperty('enabled', value: onPressed != null, ifFalse: 'disabled'),
      )
      ..add(
        DiagnosticsProperty<bool>('selected', selected, defaultValue: null),
      );
  }
}

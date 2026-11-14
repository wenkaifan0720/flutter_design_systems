import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'component_themes.dart';
import 'internal/face.dart';
import 'press.dart';
import 'theme.dart';
import 'glyphs.dart';
import 'layout.dart'
    show retroDesktopButtonFill, retroDesktopHugs, retroDesktopOwnSize;
import 'internal/caps.dart';
import 'internal/parts.dart' show retroDesktopOutdent;

const _clear = Color(0x00000000);

/// The size of a button's visible face; padded hit targets keep their minimum.
enum RetroDesktopButtonSize {
  /// The compact visual size.
  small,

  /// The standard visual size.
  medium,

  /// The spacious visual size.
  large,
}

/// A button, in Cupertino's pattern. The plain one has a raised grey face. [isDefaultAction] is THE default button:
/// the highlight's face in a ringed frame, the one thing Return would press, one a window, on the action that matters.
/// [RetroDesktopButton.text] has no face at rest (its words stand on the column's edge) and shows its edge on keyboard
/// focus and while pressed. [isDestructiveAction] marks an action that destroys with an alert glyph; with
/// [isDefaultAction] too, the face is drawn in desktop ink.
///
/// It keeps to its words; [wide] fills its column below 600 wide (a phone's block button), and from 600 up a room at
/// most 320 wide. With [iconOnPhone] and an [icon], a raised button on a phone shows the icon alone.
///
/// ```dart
/// RetroDesktopButton('Save', isDefaultAction: true, onPressed: () {})
/// ```
class RetroDesktopButton extends StatelessWidget {
  /// Creates a button with a raised face.
  const RetroDesktopButton(
    this.label, {
    super.key,
    this.onPressed,
    this.isDefaultAction = false,
    this.isDestructiveAction = false,
    this.size = RetroDesktopButtonSize.medium,
    this.wide = false,
    this.busy = false,
    this.showBusy,
    this.focusNode,
    this.autofocus = false,
    this.icon,
    this.mark,
    this.iconOnPhone = false,
    this.style,
  }) : _text = false;

  /// Creates a button with no face at rest, as Material's `TextButton`. Its words stand on its box's start; held or
  /// focused, its face stands out past that start by its padding (16, 10 when small), so beside another button give it
  /// that much room before it.
  const RetroDesktopButton.text(
    this.label, {
    super.key,
    this.onPressed,
    this.isDestructiveAction = false,
    this.size = RetroDesktopButtonSize.medium,
    this.wide = false,
    this.busy = false,
    this.showBusy,
    this.focusNode,
    this.autofocus = false,
    this.icon,
    this.mark,
    this.style,
  }) : _text = true,
       isDefaultAction = false,
       iconOnPhone = false;

  /// The visible or accessible name of this part.
  final String label;

  /// Called when the action is activated; null makes the action unavailable.
  final VoidCallback? onPressed;

  /// Whether this is the window's default action, the one Return presses (CupertinoDialogAction's flag).
  final bool isDefaultAction;

  /// Whether the action destroys something (CupertinoDialogAction's flag).
  final bool isDestructiveAction;

  /// The size of the visible face; minimum interactive reach is retained.
  final RetroDesktopButtonSize size;

  /// Whether the face fills its available width below 600 wide (a phone's
  /// block button); from 600 up it keeps to its words, at the room's start.
  final bool wide;

  /// Whether the action is in progress and further activation is blocked.
  final bool busy;

  /// Overrides whether the busy indicator is drawn; busy behavior is unchanged.
  final bool? showBusy;

  /// An optional externally owned focus node; the caller disposes it.
  final FocusNode? focusNode;

  /// Whether this part takes the focus when it first appears and nothing else has it.
  final bool autofocus;

  /// The glyph shown with the content.
  final IconData? icon;

  /// An identifying glyph or caller-supplied widget.
  final Widget? mark;

  /// Whether a phone shows the [icon] alone, so the button can stand beside a search box.
  final bool iconOnPhone;

  /// Overrides this part's component theme ([RetroDesktopThemeData.buttonTheme],
  /// [RetroDesktopThemeData.defaultButtonTheme] or [RetroDesktopThemeData.textButtonTheme]); unresolved slots keep
  /// their themed values.
  final RetroDesktopStyle? style;

  final bool _text;

  @override
  Widget build(BuildContext context) {
    // A default destructive button is the default face with the caution mark before its words, as an alert's
    // default "Erase" stood: no black slab, which reads as held or chosen (the state law).
    if (_text) {
      return _ExtraButton(
        label,
        onPressed: onPressed,
        icon: icon,
        mark: mark,
        size: size,
        wide: wide,
        busy: busy,
        showBusy: showBusy,
        focusNode: focusNode,
        autofocus: autofocus,
        isDestructiveAction: isDestructiveAction,
        isDefaultAction: !_text,
        style: style,
      );
    }
    if (isDefaultAction) {
      return _DefaultButton(
        label,
        onPressed: onPressed,
        size: size,
        wide: wide,
        busy: busy,
        showBusy: showBusy,
        focusNode: focusNode,
        autofocus: autofocus,
        icon:
            icon ??
            (isDestructiveAction ? RetroDesktopGlyphs.triangleAlert : null),
        mark: mark,
        iconOnPhone: iconOnPhone,
        style: style,
      );
    }
    return _PlainButton(
      label,
      onPressed: onPressed,
      size: size,
      wide: wide,
      busy: busy,
      showBusy: showBusy,
      focusNode: focusNode,
      autofocus: autofocus,
      icon: icon,
      mark: mark,
      isDestructiveAction: isDestructiveAction,
      iconOnPhone: iconOnPhone,
      style: style,
    );
  }
}

// The default face: the highlight in a ringed frame.
class _DefaultButton extends StatelessWidget {
  const _DefaultButton(
    this.label, {
    this.onPressed,
    this.size = RetroDesktopButtonSize.medium,
    this.wide = false,
    this.busy = false,
    this.showBusy,
    this.focusNode,
    this.autofocus = false,
    this.icon,
    this.mark,
    this.iconOnPhone = false,
    this.style,
  });

  /// The visible or accessible name of this part.
  final String label;

  /// Called when the action is activated; null makes the action unavailable.
  final VoidCallback? onPressed;

  /// The size of the visible face; minimum interactive reach is retained.
  final RetroDesktopButtonSize size;

  /// Whether the face fills its available width below 600 wide (a phone's
  /// block button); from 600 up it keeps to its words, at the room's start.
  /// Whether the action is in progress and further activation is blocked.
  final bool wide, busy;

  /// Overrides whether the busy indicator is drawn; busy behavior is unchanged.
  final bool? showBusy;

  /// An optional externally owned focus node; the caller disposes it.
  final FocusNode? focusNode;

  /// Whether this part takes the focus when it first appears and nothing else has it.
  final bool autofocus;

  /// The glyph shown with the content.
  final IconData? icon;

  /// An identifying glyph or caller-supplied widget.
  final Widget? mark;

  /// Whether compact layouts show the glyph instead of the full label.
  final bool iconOnPhone;

  /// Overrides this part's component theme; unresolved slots keep their themed values.
  final RetroDesktopStyle? style;
  @override
  Widget build(BuildContext context) => wide
      ? retroDesktopButtonFill(child: _draw(context))
      : retroDesktopOwnSize(child: _draw(context));
  Widget _draw(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final c = t.colors;
    final compact = size == RetroDesktopButtonSize.small;
    final words = iconOnPhone && icon != null && !t.desk ? '' : label;
    final glyph = (showBusy ?? busy) ? RetroDesktopGlyphs.hourglass : icon;
    final leading = (showBusy ?? busy) ? null : mark;
    return RetroDesktopPressable(
      onPressed: onPressed,
      label: label,
      busy: busy,
      focusNode: focusNode,
      autofocus: autofocus,
      builder: (context, states) => ConstrainedBox(
        constraints: BoxConstraints(
          // One line up to 300 on a desk; on a phone up to half the screen (the
          // old 200 broke a two-word label beside one-word buttons onto two
          // lines; more would starve a title written beside it), never under
          // 160, which a glyph, a word and the padding need. The room is for
          // words, so it grows with the reader's text: at twice the size the
          // same cap broke "Delete document" onto two lines in an empty row.
          maxWidth: wide
              ? double.infinity
              : MediaQuery.textScalerOf(context).scale(
                  t.desk
                      ? 300
                      : math.min(
                          300,
                          math.max(160, MediaQuery.sizeOf(context).width / 2),
                        ),
                ),
        ),
        child: retroDesktopFace(
          states: states,
          style: style,
          scale: RetroDesktopFaceScale.button,
          defaultRing: true,
          // The ring is the button's outline: beside a plain button it shows
          // the same top and bottom.
          ringInBox: true,
          // The blue runs to the outline, which stands on the keyline: a grey
          // shade line inside it read as the face stopping short.
          // Lit at the top left, in shade at the bottom right, by day and by night (law 2), so a press turns the bevel in
          // and does not only darken the face: mixed with the greys, both edges stood paler than the blue, and by night
          // both darker.
          bevelTint: (
            light: Color.lerp(c.highlightFaceTop, const Color(0xFFFFFFFF), .5)!,
            shade: c.highlightDark,
          ),
          flat: c.highlight,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0, .6, 1],
            colors: states.contains(WidgetState.pressed)
                ? [
                    c.highlightFaceBottom,
                    c.highlightFaceBottom,
                    c.highlightFaceMiddle,
                  ]
                : [
                    c.highlightFaceTop,
                    c.highlightFaceMiddle,
                    c.highlightFaceBottom,
                  ],
          ),

          component: t.defaultButtonTheme.merge(
            RetroDesktopStyle(
              foreground: WidgetStatePropertyAll(c.onHighlight),
              textStyle: WidgetStatePropertyAll(t.type.chrome),
              iconSize: const WidgetStatePropertyAll(15),
            ),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 17,
            vertical: compact
                ? 3
                : size == RetroDesktopButtonSize.large
                ? 11
                : 7,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (leading != null)
                ExcludeSemantics(child: leading)
              else if (glyph != null)
                Icon(glyph),
              if ((leading != null || glyph != null) && words.isNotEmpty)
                const SizedBox(width: 6),
              if (words.isNotEmpty)
                Flexible(
                  child: RetroDesktopCaps(
                    Text(words, textAlign: TextAlign.center),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// The plain face: grey, raised.
class _PlainButton extends StatelessWidget {
  const _PlainButton(
    this.label, {
    this.onPressed,
    this.size = RetroDesktopButtonSize.medium,
    this.wide = false,
    this.busy = false,
    this.showBusy,
    this.focusNode,
    this.autofocus = false,
    this.icon,
    this.mark,
    this.iconOnPhone = false,
    this.isDestructiveAction = false,
    this.style,
  });

  /// The visible or accessible name of this part.
  final String label;

  /// Called when the action is activated; null makes the action unavailable.
  final VoidCallback? onPressed;

  /// The size of the visible face; minimum interactive reach is retained.
  final RetroDesktopButtonSize size;

  /// Whether the face fills its available width below 600 wide (a phone's
  /// block button); from 600 up it keeps to its words, at the room's start.
  /// Whether the action is in progress and further activation is blocked.
  final bool wide, busy;

  /// Overrides whether the busy indicator is drawn; busy behavior is unchanged.
  final bool? showBusy;

  /// An optional externally owned focus node; the caller disposes it.
  final FocusNode? focusNode;

  /// Whether this part takes the focus when it first appears and nothing else has it.
  final bool autofocus;

  /// The glyph shown with the content.
  final IconData? icon;

  /// An identifying glyph or caller-supplied widget.
  final Widget? mark;

  /// Whether the content identifies a destructive action.
  final bool isDestructiveAction;

  /// Whether compact layouts show the glyph instead of the full label.
  final bool iconOnPhone;

  /// Overrides this part's component theme; unresolved slots keep their themed values.
  final RetroDesktopStyle? style;
  @override
  Widget build(BuildContext context) => wide
      ? retroDesktopButtonFill(child: _draw(context))
      : retroDesktopOwnSize(child: _draw(context));
  Widget _draw(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final c = t.colors;
    final compact = size == RetroDesktopButtonSize.small;
    final words = iconOnPhone && icon != null && !t.desk ? '' : label;
    final glyph = (showBusy ?? busy)
        ? RetroDesktopGlyphs.hourglass
        : (icon ??
              (isDestructiveAction ? RetroDesktopGlyphs.triangleAlert : null));
    final leading = (showBusy ?? busy) ? null : mark;
    return RetroDesktopPressable(
      onPressed: onPressed,
      label: label,
      busy: busy,
      focusNode: focusNode,
      autofocus: autofocus,
      builder: (context, states) => ConstrainedBox(
        constraints: BoxConstraints(
          // A button keeps its words on one line up to 280 on a desk (at 600,
          // "Open the command palette" broke onto two lines at 168), and on a
          // phone up to half the screen ("Document commands" beside one-word
          // buttons fits; a title written beside a long one keeps its half).
          // The room grows with the reader's text, as a line button's does.
          maxWidth: wide
              ? double.infinity
              : MediaQuery.textScalerOf(context).scale(
                  t.desk || retroDesktopHugs(context)
                      ? 280
                      : math.min(
                          280,
                          math.max(160, MediaQuery.sizeOf(context).width / 2),
                        ),
                ),
        ),
        child: retroDesktopFace(
          states: states,
          style: style,
          scale: RetroDesktopFaceScale.button,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: states.contains(WidgetState.pressed)
                ? [c.platinum, c.platinumDark]
                : [c.platinumLight, c.platinum],
          ),

          component: t.buttonTheme.merge(
            RetroDesktopStyle(
              foreground: WidgetStatePropertyAll(c.text),
              textStyle: WidgetStatePropertyAll(t.type.chrome),
              iconSize: const WidgetStatePropertyAll(15),
            ),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 9 : 13,
            vertical: compact
                ? 3
                : size == RetroDesktopButtonSize.large
                ? 11
                : 7,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (leading != null)
                ExcludeSemantics(child: leading)
              else if (glyph != null)
                Icon(glyph),
              if ((leading != null || glyph != null) && words.isNotEmpty)
                const SizedBox(width: 6),
              if (words.isNotEmpty)
                Flexible(
                  child: RetroDesktopCaps(
                    Text(words, textAlign: TextAlign.center),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExtraButton extends StatelessWidget {
  const _ExtraButton(
    this.label, {
    this.onPressed,
    this.icon,
    this.mark,
    required this.size,
    required this.wide,
    required this.busy,
    this.showBusy,
    this.focusNode,
    this.autofocus = false,
    this.isDestructiveAction = false,
    this.isDefaultAction = false,
    this.style,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Widget? mark;
  final RetroDesktopButtonSize size;
  final bool wide, busy, isDestructiveAction, isDefaultAction;
  final bool? showBusy;
  final FocusNode? focusNode;

  /// Whether this part takes the focus when it first appears and nothing else has it.
  final bool autofocus;
  final RetroDesktopStyle? style;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final glyph =
        icon ??
        (isDestructiveAction && !isDefaultAction
            ? RetroDesktopGlyphs.triangleAlert
            : null);
    final face = RetroDesktopPressable(
      label: label,
      busy: busy,
      focusNode: focusNode,
      autofocus: autofocus,
      onPressed: onPressed,
      builder: (context, states) {
        final bevel =
            isDefaultAction ||
            states.contains(WidgetState.focused) ||
            states.contains(WidgetState.pressed);
        final inset = bevel ? 0.0 : t.strokes.hairline;
        return retroDesktopFace(
          states: states,
          bevel: bevel,
          scale: RetroDesktopFaceScale.button,
          flat: isDefaultAction ? t.colors.text : null,
          component: isDefaultAction
              ? t.defaultButtonTheme.merge(
                  RetroDesktopStyle(
                    fill: WidgetStatePropertyAll(t.colors.text),
                    foreground: WidgetStatePropertyAll(t.colors.paper),
                    textStyle: WidgetStatePropertyAll(t.type.chrome),
                    iconSize: const WidgetStatePropertyAll(15),
                  ),
                )
              // No surface at rest on any ground: a window-coloured fill stood as a grey slab on a lighter card. Held
              // or focused, the window's face.
              : t.textButtonTheme.merge(
                  RetroDesktopStyle(
                    fill: WidgetStateProperty.resolveWith(
                      (states) => bevel ? t.colors.platinum : _clear,
                    ),
                    textStyle: WidgetStatePropertyAll(t.type.chrome),
                    iconSize: const WidgetStatePropertyAll(15),
                    side: WidgetStateProperty.resolveWith(
                      (states) => BorderSide(
                        color: states.contains(WidgetState.focused)
                            ? t.colors.control
                            : bevel
                            ? t.colors.platinum
                            : _clear,
                      ),
                    ),
                  ),
                ),
          style: style,
          padding: EdgeInsets.symmetric(
            horizontal:
                (size == RetroDesktopButtonSize.small ? 10 : 16) +
                inset / t.density.horizontal,
            vertical:
                (size == RetroDesktopButtonSize.large
                    ? 11
                    : size == RetroDesktopButtonSize.small
                    ? 3
                    : 7) +
                inset / t.density.vertical,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (showBusy ?? busy)
                const Text('…')
              else if (mark != null)
                ExcludeSemantics(child: mark!)
              else if (glyph != null)
                Icon(glyph),
              if (glyph != null || mark != null || (showBusy ?? busy))
                const SizedBox(width: 6),
              Flexible(
                child: RetroDesktopCaps(
                  Text(label, textAlign: TextAlign.center),
                ),
              ),
            ],
          ),
        );
      },
    );
    // A quiet button shows no surface at rest: its glyph or words stand on its
    // column's edge, and the face it shows held or focused stands out past
    // the edge by its padding and rim.
    final placed = isDefaultAction || wide
        ? face
        : retroDesktopOutdent(
            start:
                (size == RetroDesktopButtonSize.small ? 10 : 16) *
                    t.density.horizontal +
                retroDesktopFaceRim(t),
            child: face,
          );
    // It keeps to its words in a column that stretches it, at every width: on
    // a phone, spanning the column floated its words in the middle of nothing
    // (self-review 3). A press anywhere in its row still reaches it.
    return retroDesktopButtonFill(child: placed, always: !wide);
  }
}

/// An underlined text action with link semantics and the shared padded target.
///
/// ```dart
/// RetroDesktopLink('Read more', onPressed: () {})
/// ```
class RetroDesktopLink extends StatelessWidget {
  /// Creates a [RetroDesktopLink].
  const RetroDesktopLink(
    this.label, {
    super.key,
    this.onPressed,
    this.style,
    this.focusNode,
    this.autofocus = false,
    this.inSentence = false,
    this.busy = false,
  });

  /// An optional externally owned focus node; the caller disposes it.
  final FocusNode? focusNode;

  /// Whether this part takes the focus when it first appears and nothing else has it.
  final bool autofocus;

  /// Whether the link follows surrounding text instead of standing alone.
  final bool inSentence;

  /// Whether the action is in progress and further activation is blocked.
  final bool busy;

  /// The visible or accessible name of this part.
  final String label;

  /// Called when the action is activated; null makes the action unavailable.
  final VoidCallback? onPressed;

  /// Overrides this part's component theme; unresolved slots keep their themed values.
  final RetroDesktopStyle? style;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    return RetroDesktopPressable(
      label: label,
      focusNode: focusNode,
      autofocus: autofocus,
      busy: busy,
      onPressed: onPressed,
      button: false,
      link: true,
      builder: (context, states) => Text(
        label,
        style:
            (RetroDesktopStyle.first(
                      [style, t.textButtonTheme],
                      (s) => s.textStyle,
                      states,
                    ) ??
                    (inSentence
                        ? DefaultTextStyle.of(context).style
                        : t.type.body))
                .copyWith(
                  color:
                      RetroDesktopStyle.first(
                        [style, t.textButtonTheme],
                        (s) => s.foreground,
                        states,
                      ) ??
                      // Held, a link takes the deeper ink a pressed link
                      // took on the period's desktops.
                      (states.contains(WidgetState.pressed)
                          ? t.colors.highlightDark
                          : t.colors.highlight),
                  decoration: TextDecoration.underline,
                ),
      ),
    );
  }
}

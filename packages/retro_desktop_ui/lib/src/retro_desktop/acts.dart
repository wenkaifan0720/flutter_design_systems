import 'package:flutter/foundation.dart';

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
import 'tokens.dart';
import 'internal/parts.dart' show retroDesktopOutdent;
import 'internal/modal.dart';
import 'internal/actions.dart' show retroDesktopInActionBar;
import 'internal/marks.dart' show retroDesktopAlertArt;
import 'tone.dart';
import 'frames.dart' show retroDesktopActiveHere;

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
/// focus and while pressed. [isDestructiveAction] marks an action that destroys with the stop sign before its words,
/// the period's own picture for a loss (its alerts' stop sign, small), on the face it would have anyway: the language
/// had no red button. An [icon] or [mark] given takes its place.
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

  /// {@template retro_desktop.onPressed}
  /// Called when the action is activated; null makes the action unavailable.
  /// {@endtemplate}
  final VoidCallback? onPressed;

  /// Whether this is the window's default action, the one Return presses (CupertinoDialogAction's flag).
  final bool isDefaultAction;

  /// Whether the action destroys something (CupertinoDialogAction's flag): the stop sign stands before its words.
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

  /// {@template retro_desktop.focusNode}
  /// An optional externally owned focus node; the caller disposes it.
  /// {@endtemplate}
  final FocusNode? focusNode;

  /// {@template retro_desktop.autofocus}
  /// Whether this part takes the focus when it first appears and nothing else has it.
  /// {@endtemplate}
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
    // A destructive button keeps the face it would have and carries the stop sign before its words; a default one is
    // the default face, as an alert's default "Erase" stood: no black slab, which reads as held or chosen (the state
    // law), and no red face, which the language never had.
    final mark =
        this.mark ??
        (isDestructiveAction && icon == null
            ? retroDesktopAlertArt(
                RetroDesktopTheme.of(context),
                RetroDesktopTone.danger,
                size: 16,
              )
            : null);
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
        isDefaultAction: !_text,
        style: style,
      );
    }
    if (isDefaultAction) {
      // Only the front window's default is Return's: in a window behind, or under an alert, it keeps its place and
      // its ring, quiet.
      return RetroDesktopModalWatch(
        builder: (context) => _DefaultButton(
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
          iconOnPhone: iconOnPhone,
          // Out of use it lays the highlight down, as it does in a window behind: a plain face in its grey ring,
          // its words half strength, the one look a button out of use has.
          quiet: !retroDesktopActiveHere(context) || onPressed == null,
          style: style,
        ),
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
      iconOnPhone: iconOnPhone,
      style: style,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label))
      ..add(ObjectFlagProperty<VoidCallback>.has('onPressed', onPressed))
      ..add(
        FlagProperty(
          'isDefaultAction',
          value: isDefaultAction,
          ifTrue: 'isDefaultAction',
        ),
      )
      ..add(
        FlagProperty(
          'isDestructiveAction',
          value: isDestructiveAction,
          ifTrue: 'isDestructiveAction',
        ),
      )
      ..add(
        EnumProperty<RetroDesktopButtonSize>(
          'size',
          size,
          defaultValue: RetroDesktopButtonSize.medium,
        ),
      )
      ..add(FlagProperty('wide', value: wide, ifTrue: 'wide'))
      ..add(FlagProperty('busy', value: busy, ifTrue: 'busy'))
      ..add(DiagnosticsProperty<bool>('showBusy', showBusy, defaultValue: null))
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'))
      ..add(DiagnosticsProperty<IconData>('icon', icon, defaultValue: null))
      ..add(
        FlagProperty('iconOnPhone', value: iconOnPhone, ifTrue: 'iconOnPhone'),
      )
      ..add(
        DiagnosticsProperty<RetroDesktopStyle>(
          'style',
          style,
          defaultValue: null,
        ),
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
    this.quiet = false,
    this.style,
  });

  /// The visible or accessible name of this part.
  final String label;

  /// {@macro retro_desktop.onPressed}
  final VoidCallback? onPressed;

  /// The size of the visible face; minimum interactive reach is retained.
  final RetroDesktopButtonSize size;

  /// Whether the face fills its available width below 600 wide (a phone's
  /// block button); from 600 up it keeps to its words, at the room's start.
  /// Whether the action is in progress and further activation is blocked.
  final bool wide, busy;

  /// In a window that isn't the front one: a plain grey face in a grey ring, in the same box.
  final bool quiet;

  /// Overrides whether the busy indicator is drawn; busy behavior is unchanged.
  final bool? showBusy;

  /// {@macro retro_desktop.focusNode}
  final FocusNode? focusNode;

  /// {@macro retro_desktop.autofocus}
  final bool autofocus;

  /// The glyph shown with the content.
  final IconData? icon;

  /// An identifying glyph or caller-supplied widget.
  final Widget? mark;

  /// Whether compact layouts show the glyph instead of the full label.
  final bool iconOnPhone;

  /// {@template retro_desktop.style}
  /// Overrides this part's component theme; unresolved slots keep their themed values.
  /// {@endtemplate}
  final RetroDesktopStyle? style;
  @override
  Widget build(BuildContext context) => wide
      ? retroDesktopButtonFill(child: _draw(context))
      // In a window's buttons the bar sizes the face: its own size in the row, the column's width when it stacks.
      : retroDesktopInActionBar(context)
      ? _draw(context)
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
          // In a window behind, the ring stands in the inactive grey round a plain face: the place and the size stay,
          // and the one default Return presses is the front window's.
          ringColor: quiet ? c.textTertiary : null,
          // The blue runs to the outline, which stands on the keyline: a grey
          // shade line inside it would read as the face stopping short.
          // Lit at the top start, in shade at the bottom end, by day and by night (the light law), so a press turns
          // the bevel in and does not only darken the face: mixed with the greys, both edges would stand paler than
          // the blue, and by night both darker.
          bevelTint: quiet
              ? null
              : (
                  light: Color.lerp(
                    c.highlightFaceTop,
                    const Color(0xFFFFFFFF),
                    .5,
                  )!,
                  shade: c.highlightDark,
                ),
          flat: quiet ? null : c.highlight,
          gradient: quiet
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: states.contains(WidgetState.pressed)
                      ? [c.platinum, c.platinumDark]
                      : [c.platinumLight, c.platinum],
                )
              : LinearGradient(
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

          component: quiet
              ? t.buttonTheme.over(
                  RetroDesktopStyle(
                    foreground: WidgetStatePropertyAll(c.text),
                    textStyle: WidgetStatePropertyAll(t.textTheme.chrome),
                    iconSize: const WidgetStatePropertyAll(15),
                  ),
                )
              : t.defaultButtonTheme.over(
                  RetroDesktopStyle(
                    foreground: WidgetStatePropertyAll(c.onHighlight),
                    textStyle: WidgetStatePropertyAll(t.textTheme.chrome),
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
                const SizedBox(width: RetroDesktopSpacing.s6),
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
    this.style,
  });

  /// The visible or accessible name of this part.
  final String label;

  /// {@macro retro_desktop.onPressed}
  final VoidCallback? onPressed;

  /// The size of the visible face; minimum interactive reach is retained.
  final RetroDesktopButtonSize size;

  /// Whether the face fills its available width below 600 wide (a phone's
  /// block button); from 600 up it keeps to its words, at the room's start.
  /// Whether the action is in progress and further activation is blocked.
  final bool wide, busy;

  /// Overrides whether the busy indicator is drawn; busy behavior is unchanged.
  final bool? showBusy;

  /// {@macro retro_desktop.focusNode}
  final FocusNode? focusNode;

  /// {@macro retro_desktop.autofocus}
  final bool autofocus;

  /// The glyph shown with the content.
  final IconData? icon;

  /// An identifying glyph or caller-supplied widget.
  final Widget? mark;

  /// Whether compact layouts show the glyph instead of the full label.
  final bool iconOnPhone;

  /// {@macro retro_desktop.style}
  final RetroDesktopStyle? style;
  @override
  Widget build(BuildContext context) => wide
      ? retroDesktopButtonFill(child: _draw(context))
      // In a window's buttons the bar sizes the face: its own size in the row, the column's width when it stacks.
      : retroDesktopInActionBar(context)
      ? _draw(context)
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

          component: t.buttonTheme.over(
            RetroDesktopStyle(
              foreground: WidgetStatePropertyAll(c.text),
              textStyle: WidgetStatePropertyAll(t.textTheme.chrome),
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
                const SizedBox(width: RetroDesktopSpacing.s6),
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
    this.isDefaultAction = false,
    this.style,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Widget? mark;
  final RetroDesktopButtonSize size;
  final bool wide, busy, isDefaultAction;
  final bool? showBusy;
  final FocusNode? focusNode;

  /// {@macro retro_desktop.autofocus}
  final bool autofocus;
  final RetroDesktopStyle? style;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final glyph = icon;
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
              ? t.defaultButtonTheme.over(
                  RetroDesktopStyle(
                    fill: WidgetStatePropertyAll(t.colors.text),
                    foreground: WidgetStatePropertyAll(t.colors.paper),
                    textStyle: WidgetStatePropertyAll(t.textTheme.chrome),
                    iconSize: const WidgetStatePropertyAll(15),
                  ),
                )
              // No surface at rest on any ground: a window-coloured fill stood as a grey slab on a lighter card. Held
              // or focused, the window's face.
              : t.textButtonTheme.over(
                  RetroDesktopStyle(
                    fill: WidgetStateProperty.resolveWith(
                      (states) => bevel ? t.colors.platinum : _clear,
                    ),
                    textStyle: WidgetStatePropertyAll(t.textTheme.chrome),
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
                const SizedBox(width: RetroDesktopSpacing.s6),
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
    // a phone, spanning the column floated its words in the middle of
    // nothing. A press anywhere in its row still reaches it.
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

  /// {@macro retro_desktop.focusNode}
  final FocusNode? focusNode;

  /// {@macro retro_desktop.autofocus}
  final bool autofocus;

  /// Whether the link follows surrounding text instead of standing alone.
  final bool inSentence;

  /// Whether the action is in progress and further activation is blocked.
  final bool busy;

  /// The visible or accessible name of this part.
  final String label;

  /// {@macro retro_desktop.onPressed}
  final VoidCallback? onPressed;

  /// {@macro retro_desktop.style}
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
                        : t.textTheme.body))
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'))
      ..add(FlagProperty('inSentence', value: inSentence, ifTrue: 'inSentence'))
      ..add(FlagProperty('busy', value: busy, ifTrue: 'busy'))
      ..add(StringProperty('label', label))
      ..add(ObjectFlagProperty<VoidCallback>.has('onPressed', onPressed))
      ..add(
        DiagnosticsProperty<RetroDesktopStyle>(
          'style',
          style,
          defaultValue: null,
        ),
      );
  }
}

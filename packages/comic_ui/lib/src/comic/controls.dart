// Routine controls share Comic's ink, lettering and conventional corner scale.
// Speech balloons belong to messages, not to actions or editing surfaces.
import 'package:ui_core/ui_core.dart';

import 'dart:math' as math;
import 'dart:ui' show SemanticsValidationResult;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import 'glyphs.dart';
import 'internal/track.dart';
import 'component_themes.dart';
import 'styled.dart';
import 'internal/lettering.dart';

import 'internal/field_icon.dart';
import 'internal/geometry.dart';
import 'internal/reach.dart';
import 'layout.dart';
import 'press.dart';
import 'theme.dart';
import 'localizations.dart';
import 'editing.dart';
import 'tell.dart';
import 'internal/cap_label.dart';

// Marks retain a four-pixel reading gutter within the caller's outline.
// Their hit target grows with the face.
double _markExtent(
  double base,
  double glyph,
  OutlinedBorder? shape,
  BorderSide rim,
  TextDirection direction, {
  bool vertical = false,
}) {
  final dimensions = shape?.dimensions.resolve(direction) ?? EdgeInsets.zero;
  const clearance = 4.0;
  final body = shape is CircleBorder || shape is StadiumBorder
      ? (glyph + 2 * clearance) * math.sqrt2
      : glyph + 2 * clearance + 2 * comicCornerInset(shape, direction);
  return math.max(
    base,
    body +
        (vertical ? dimensions.vertical : dimensions.horizontal) +
        2 * rim.width +
        .5,
  );
}

/// A button's visual scale. Its input target remains at least 48 on touch.
enum ComicButtonSize {
  /// Small type and compact padding.
  small,

  /// Standard reading size.
  medium,

  /// Larger type and generous padding.
  large,
}

/// A button: the plain outlined box by default, [ComicButton.filled] for the screen's primary action, [ComicButton.text]
/// for quiet words with no box. [isDestructiveAction] draws any of them in the danger tone, as Cupertino names it.
///
/// ```dart
/// ComicButton.filled('New plan', icon: ComicGlyphs.plus, onPressed: () {})
/// ```
class ComicButton extends StatelessWidget {
  /// Creates an outlined button: a square box in the lettering.
  const ComicButton(
    this.label, {
    super.key,
    this.onPressed,
    this.icon,
    this.leading,
    this.size = ComicButtonSize.medium,
    this.busy = false,
    this.showBusy,
    this.wide = false,
    this.focusNode,
    this.autofocus = false,
    this.style,
    this.isDestructiveAction = false,
  }) : _variant = _ButtonVariant.outlined;

  /// Creates the filled primary action, one a screen.
  const ComicButton.filled(
    this.label, {
    super.key,
    this.onPressed,
    this.icon,
    this.leading,
    this.size = ComicButtonSize.medium,
    this.busy = false,
    this.showBusy,
    this.wide = false,
    this.focusNode,
    this.autofocus = false,
    this.style,
    this.isDestructiveAction = false,
  }) : _variant = _ButtonVariant.filled;

  /// Creates a text button: the words alone, with no box at rest.
  const ComicButton.text(
    this.label, {
    super.key,
    this.onPressed,
    this.icon,
    this.leading,
    this.size = ComicButtonSize.medium,
    this.busy = false,
    this.showBusy,
    this.wide = false,
    this.focusNode,
    this.autofocus = false,
    this.style,
    this.isDestructiveAction = false,
  }) : _variant = _ButtonVariant.text;

  final _ButtonVariant _variant;

  /// The button's words, lettered in capitals; a screen reader reads them as written.
  final String label;

  /// Called when the button is pressed; null disables it.
  final VoidCallback? onPressed;

  /// An optional glyph before the words.
  final IconData? icon;

  /// An optional widget before the words, in the icon's place; it wins over [icon].
  final Widget? leading;

  /// The button's scale: its lettering and, for [ComicButtonSize.large], its height.
  final ComicButtonSize size;

  /// Takes no press while keeping its focus and face, and shows progress in the icon's place.
  final bool busy;

  /// Whether the progress shows; null follows [busy] (a host that delays the progress sets it).
  final bool? showBusy;

  /// Whether the button fills the width it is given.
  final bool wide;

  /// The caller's focus node.
  final FocusNode? focusNode;

  /// Whether the button asks for the focus when it first appears.
  final bool autofocus;

  /// Per-state appearance above the component theme.
  final ComicStyle? style;

  /// Whether the button deletes or loses something: drawn in the danger tone.
  final bool isDestructiveAction;

  @override
  Widget build(BuildContext context) => switch (_variant) {
    _ButtonVariant.filled => _Filled(
      label,
      style: style,
      icon: icon,
      leading: leading,
      onPressed: onPressed,
      busy: busy,
      size: size,
      wide: wide,
      showBusy: showBusy,
      focusNode: focusNode,
      autofocus: autofocus,
      destructive: isDestructiveAction,
    ),
    _ButtonVariant.outlined when !isDestructiveAction => _Outlined(
      label,
      style: style,
      icon: icon,
      leading: leading,
      onPressed: onPressed,
      busy: busy,
      size: size,
      wide: wide,
      showBusy: showBusy,
      focusNode: focusNode,
      autofocus: autofocus,
    ),
    _ButtonVariant.outlined || _ButtonVariant.text => _Action(
      label: label,
      onPressed: onPressed,
      icon: icon,
      style: style,
      leading: leading,
      busy: busy,
      showBusy: showBusy,
      wide: wide,
      focusNode: focusNode,
      autofocus: autofocus,
      size: size,
      danger: isDestructiveAction,
      boxed: _variant == _ButtonVariant.outlined,
    ),
  };
}

enum _ButtonVariant { outlined, filled, text }

// [ComicButton.filled]: the primary action, in the primary colour with Comic's inked outline (the danger tone when
// destructive). Its face and label align with the outlined and text buttons of the same size.
class _Filled extends StatelessWidget {
  const _Filled(
    this.label, {
    this.style,
    this.icon,
    this.leading,
    this.onPressed,
    required this.busy,
    required this.size,
    required this.wide,
    this.showBusy,
    this.focusNode,
    this.autofocus = false,
    required this.destructive,
  });

  /// Suppresses input while preserving focus and showing progress.
  final bool busy;

  /// Whether to fill the available width.
  final bool wide;

  /// Overrides the busy indicator, for hosts that delay progress.
  final bool? showBusy;

  /// Caller-owned focus.
  final FocusNode? focusNode;

  /// Whether the button asks for the focus when it first appears.
  final bool autofocus;

  final ComicButtonSize size;
  final String label;
  final IconData? icon;
  final Widget? leading;
  final VoidCallback? onPressed;
  final bool destructive;
  final ComicStyle? style;
  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context), c = t.colors;
    final small = size == ComicButtonSize.small;
    final layers = [style, t.filledButtonTheme];
    final look = ComicStyleOf(layers, const {});
    final drawn = ComicPressable(
      onPressed: onPressed,
      label: label,
      busy: busy,
      focusNode: focusNode,
      autofocus: autofocus,
      outline: look.shapes(t.shapes.small),
      overlay: look.overlay,
      builder: (context, states) {
        final look = ComicStyleOf(layers, states);
        final ink = look.foreground ?? (destructive ? c.card : c.onPrimary);
        final text = (small ? t.type.buttonSmall : t.type.button)
            .merge(look.textStyle)
            .copyWith(color: ink);
        final minimum = look.minimumSize;
        // A field's height at every density (ComicTrack.fieldHeight): a button beside a field or a select stands as
        // tall as it (compact had buttons at 40 beside fields at 44).
        final height = size == ComicButtonSize.large
            ? math.max(ComicTrack.fieldHeight(context), t.density.height(56))
            : ComicTrack.fieldHeight(context);
        final padding =
            look.padding(Directionality.of(context)) ??
            t.density.padding(
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            );
        final rim = comicRim(t, look, c.nightLine);
        return AnimatedComicShape(
          shape: look.shape ?? t.shapes.small,
          builder: (context, shape) {
            final content = ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: minimum?.width ?? 0,
                minHeight: minimum?.height ?? height,
              ),
              child: Padding(
                padding: padding.add(shape?.dimensions ?? EdgeInsets.zero),
                child: Center(
                  widthFactor: 1,
                  heightFactor: 1,
                  child: ComicFitRow(
                    fill: leading == null && icon == null && !(showBusy ?? busy)
                        ? 0
                        : 1,
                    gap: 8,
                    shrink: true,
                    children: [
                      if (showBusy ?? busy)
                        ComicCircularProgressIndicator(
                          size: look.iconSize ?? 20,
                          color: ink,
                        )
                      else if (leading != null)
                        ExcludeSemantics(child: leading!)
                      else if (icon != null)
                        Icon(
                          icon,
                          size: look.iconSize ?? (small ? 17 : 20),
                          color: ink,
                        ),
                      CapLabel(
                        child: Text(
                          label.toUpperCase(),
                          style: text,
                          textScaler: comicLetteringScaler(context, text),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
            return ComicStateDecoration(
              decoration: ShapeDecoration(
                color: look.fill ?? (destructive ? c.tones.danger : c.primary),
                shape: (shape ?? const RoundedRectangleBorder()).copyWith(
                  side: rim,
                ),
              ),
              child: content,
            );
          },
        );
      },
    );
    return ComicButtonRoom(
      child: wide ? SizedBox(width: double.infinity, child: drawn) : drawn,
    );
  }
}

// [ComicButton]: a plain button, a square box in the lettering. It hugs its word unless a stretching column widens it,
// and a long word wraps inside it.
class _Outlined extends StatelessWidget {
  const _Outlined(
    this.label, {
    this.style,
    this.onPressed,
    this.icon,
    this.leading,
    required this.busy,
    required this.size,
    required this.wide,
    this.showBusy,
    this.focusNode,
    this.autofocus = false,
  });

  /// Suppresses input while preserving focus and showing progress.
  final bool busy;

  /// Whether to fill the available width.
  final bool wide;

  /// Overrides the busy indicator, for hosts that delay progress.
  final bool? showBusy;

  /// Caller-owned focus.
  final FocusNode? focusNode;

  /// Whether the button asks for the focus when it first appears.
  final bool autofocus;

  final ComicButtonSize size;

  /// The visible or spoken name of the component.
  final String label;

  /// The optional glyph beside the words.
  final IconData? icon;

  final Widget? leading;

  /// Called when activated; null disables the action.
  final VoidCallback? onPressed;

  /// Per-state face style, above the component theme and the look.
  final ComicStyle? style;
  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context), c = t.colors;
    final small = size == ComicButtonSize.small;
    final layers = [style, t.buttonTheme];
    final look = ComicStyleOf(layers, const {});
    final drawn = ComicPressable(
      onPressed: onPressed,
      label: label,
      busy: busy,
      focusNode: focusNode,
      autofocus: autofocus,
      outline: look.shapes(t.shapes.small),
      overlay: look.overlay,
      builder: (context, states) {
        final look = ComicStyleOf(layers, states);
        final ink = look.foreground ?? (c.dark ? c.text : c.onPaper);
        final text = (small ? t.type.buttonSmall : t.type.button)
            .merge(look.textStyle)
            .copyWith(color: ink);
        final minimum = look.minimumSize;
        // A field's height at every density (ComicTrack.fieldHeight): a button beside a field or a select stands as
        // tall as it (compact had buttons at 40 beside fields at 44).
        final height = size == ComicButtonSize.large
            ? math.max(ComicTrack.fieldHeight(context), t.density.height(56))
            : ComicTrack.fieldHeight(context);
        final padding =
            look.padding(Directionality.of(context)) ??
            t.density.padding(
              EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            );
        final rim = comicRim(t, look, c.nightLine);
        return AnimatedComicShape(
          shape: look.shape ?? t.shapes.small,
          builder: (context, shape) {
            final content = ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: minimum?.width ?? 0,
                minHeight: minimum?.height ?? height,
                maxWidth: wide ? double.infinity : (t.desk ? 320 : 200),
              ),
              child: Padding(
                padding: padding.add(shape?.dimensions ?? EdgeInsets.zero),
                child: Center(
                  widthFactor: 1,
                  heightFactor: 1,
                  child: ComicFitRow(
                    fill:
                        (leading == null && icon == null && !(showBusy ?? busy))
                        ? 0
                        : 1,
                    gap: 8,
                    shrink: true,
                    children: [
                      if (showBusy ?? busy)
                        ComicCircularProgressIndicator(
                          size: look.iconSize ?? 20,
                          color: ink,
                        )
                      else if (leading != null)
                        ExcludeSemantics(child: leading!)
                      else if (icon != null)
                        Icon(
                          icon,
                          size: look.iconSize ?? (small ? 17 : 20),
                          color: ink,
                        ),
                      CapLabel(
                        child: Text(
                          label.toUpperCase(),
                          style: text,
                          textScaler: comicLetteringScaler(context, text),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
            return ComicStateDecoration(
              decoration: ShapeDecoration(
                color: look.fill ?? (c.dark ? c.card : c.control),
                shape: (shape ?? const RoundedRectangleBorder()).copyWith(
                  side: rim,
                ),
              ),
              child: content,
            );
          },
        );
      },
    );
    return ComicButtonRoom(
      child: wide ? SizedBox(width: double.infinity, child: drawn) : drawn,
    );
  }
}

/// A square button with one icon, for a bar or a row. It keeps its size at its column's start, and needs a [label] for a screen
/// reader.
///
/// ```dart
/// ComicIconButton(ComicGlyphs.bell, label: 'Alerts', onPressed: () {})
/// ```
class ComicIconButton extends StatelessWidget {
  /// Creates a [ComicIconButton].
  const ComicIconButton(
    this.icon, {
    super.key,
    this.style,
    required this.label,
    this.onPressed,
    this.size = 40,
    this.focusNode,
    this.selected = false,
    this.badge,
    this.badgeLabel,
    this.dot = false,
    this.autofocus = false,
  });

  /// The optional glyph beside the words.
  final IconData icon;

  /// The visible or spoken name of the component.
  final String label;

  /// Called when activated; null disables the action.
  final VoidCallback? onPressed;

  /// The visual size in logical pixels.
  final double size;

  /// Caller-owned focus.
  final FocusNode? focusNode;

  /// A toggled action and its optional badge.
  final bool selected, dot;

  /// An optional count or indicator beside the destination.
  final int? badge;

  /// The spoken description of the destination badge.
  final String? badgeLabel;

  /// Per-state face style, above the component theme and the look.
  final ComicStyle? style;

  /// Whether the part asks for the focus when it first appears.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context), c = t.colors;
    final layers = [style, t.iconButtonTheme];
    final base = ComicStyleOf(layers, const {});
    final target = math.max(size, ComicTapTarget.targetOf(context));
    return comicOwnSize(
      child: ComicPressable(
        autofocus: autofocus,
        onPressed: onPressed,
        label: label,
        focusNode: focusNode,
        selected: selected ? true : null,
        value: badgeLabel,
        outline: base.shapes(t.shapes.small),
        overlay: base.overlay,
        builder: (context, states) {
          final look = ComicStyleOf(layers, states);
          final rim = comicRim(t, look, c.nightLine);
          return AnimatedComicShape(
            shape: look.shape ?? t.shapes.small,
            builder: (context, shape) => comicOwnSize(
              width: math.max(
                target,
                _markExtent(
                  look.minimumSize?.width ?? t.density.height(size),
                  look.iconSize ?? 20,
                  shape,
                  rim,
                  Directionality.of(context),
                  vertical: false,
                ),
              ),
              height: math.max(
                target,
                _markExtent(
                  look.minimumSize?.height ?? t.density.height(size),
                  look.iconSize ?? 20,
                  shape,
                  rim,
                  Directionality.of(context),
                  vertical: true,
                ),
              ),
              child: Center(
                child: ComicPressFace(
                  child: comicOwnSize(
                    width: _markExtent(
                      look.minimumSize?.width ?? t.density.height(size),
                      look.iconSize ?? 20,
                      shape,
                      rim,
                      Directionality.of(context),
                      vertical: false,
                    ),
                    height: _markExtent(
                      look.minimumSize?.height ?? t.density.height(size),
                      look.iconSize ?? 20,
                      shape,
                      rim,
                      Directionality.of(context),
                      vertical: true,
                    ),
                    child: ComicStateDecoration(
                      decoration: ShapeDecoration(
                        color:
                            look.fill ??
                            (selected
                                ? c.caption
                                : c.dark
                                ? c.card
                                : c.control),
                        shape: (shape ?? const RoundedRectangleBorder())
                            .copyWith(side: rim),
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Center(
                            child: Padding(
                              padding: shape?.dimensions ?? EdgeInsets.zero,
                              child: Icon(
                                icon,
                                size: look.iconSize ?? 20,
                                color:
                                    look.foreground ??
                                    (selected
                                        ? c.onCaption
                                        : c.dark
                                        ? c.text
                                        : c.onPaper),
                              ),
                            ),
                          ),
                          if (badge != null || dot)
                            PositionedDirectional(
                              top: -6,
                              end: -6,
                              child: ExcludeSemantics(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 3,
                                    vertical: 1,
                                  ),
                                  decoration: ShapeDecoration(
                                    color: c.caption,
                                    shape:
                                        (badge == null
                                                ? t.shapes.full
                                                : t.shapes.capsule)
                                            .copyWith(
                                              side: BorderSide(
                                                color: c.nightLine,
                                              ),
                                            ),
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 8,
                                    minHeight: 8,
                                  ),
                                  child: badge == null
                                      ? null
                                      : Text(
                                          badge! > 99 ? '99+' : '$badge',
                                          style: ComicTheme.of(context)
                                              .type
                                              .label
                                              .copyWith(color: c.onCaption),
                                        ),
                                ),
                              ),
                            ),
                        ],
                      ),
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
}

/// A field on the control surface. [onPaper] uses the paper surface and conversational
/// lettering for a reply; its outline remains on the same corner scale.
/// [maxLines] above one makes a note box; [trailing] holds a send button or a unit.
///
/// ```dart
/// ComicTextField(hint: 'Your name', onChanged: (text) {})
/// ```
class ComicTextField extends StatelessWidget {
  /// Creates a [ComicTextField].
  const ComicTextField({
    super.key,
    this.style,
    this.controller,
    this.initialValue,
    this.hint,
    this.onChanged,
    this.onSubmitted,
    this.trailing,
    this.leading,
    this.maxLines = 1,
    this.minLines,
    this.prefix,
    this.keyboardType,
    this.textDirection,
    this.onPaper = false,
    this.obscureText = false,
    this.label,
    this.helper,
    this.error,
    this.enabled = true,
    this.focusNode,
    this.autofocus = false,
    this.textInputAction,
    this.autofillHints,
    this.inputFormatters,
    this.password = false,
    this.revealLabels,
    this.onEditingComplete,
    this.decorate,
    this.failureLine,
    this.nameOnly = false,
    this.showLabel = true,
  });

  /// The caller-owned editing controller.
  final TextEditingController? controller;

  /// [initialValue]: initial text when no editing controller is supplied. [hint]: placeholder text shown when the field is empty. [prefix]: text displayed before the editable value.
  final String? initialValue, hint, prefix;

  /// [onChanged]: reports a new value; null disables changes. [onSubmitted]: reports text submitted from the keyboard.
  final ValueChanged<String>? onChanged, onSubmitted;

  /// [trailing]: content after the main words. [leading]: content before the main words.
  final Widget? trailing, leading;

  /// The most lines the field shows before it scrolls; above one it is a note box.
  final int maxLines;

  /// The fewest lines the field shows; null shows [maxLines] from the start.
  final int? minLines;

  /// The keyboard requested for editing.
  final TextInputType? keyboardType;

  /// The direction of the entered text, as [TextField.textDirection]; null follows the ambient [Directionality]. A
  /// number or code in groups ("0042 1187") holds [TextDirection.ltr] in a right-to-left app, or its groups swap.
  final TextDirection? textDirection;

  /// [onPaper]: uses the paper surface for a reply. [obscureText]: hides entered text.
  final bool onPaper, obscureText;

  /// The label stays above the frame, even while focused.
  final String? label;

  /// Supporting text under the field; an error takes its place.
  final String? helper;

  /// The error message and invalid semantics, when present.
  final String? error;

  /// Whether input and selection are available.
  final bool enabled;

  /// An optional focus node owned by the caller.
  final FocusNode? focusNode;

  /// Whether the field requests initial focus.
  final bool autofocus;

  /// The action shown on the keyboard.
  final TextInputAction? textInputAction;

  /// Hints passed to the platform autofill service.
  final Iterable<String>? autofillHints;

  /// Input formatters applied by Flutter's text editor.
  final List<TextInputFormatter>? inputFormatters;

  /// A password editor with a reveal control, initially hidden.
  final bool password;

  /// Spoken reveal and conceal labels, in that order.
  final (String, String)? revealLabels;

  /// Replaces the editor's default focus traversal after submission.
  final VoidCallback? onEditingComplete;

  /// Decorates the editable input with application semantics.
  final Widget Function(Widget input)? decorate;

  /// Decorates the visible error line, for example as a live region.
  final Widget Function(Widget line)? failureLine;

  /// Keeps the placeholder out of the editor's accessible name.
  final bool nameOnly;

  /// False to retain the spoken label without drawing a separate line.
  final bool showLabel;

  /// Per-state field frame, text and metrics.
  final ComicStyle? style;

  @override
  Widget build(BuildContext context) => _FieldFocus(
    node: focusNode,
    builder: (context, node, hidden, toggle, hovered) =>
        _build(context, node, hidden, toggle, hovered),
  );
  Widget _build(
    BuildContext context,
    FocusNode effectiveFocus,
    bool hidden,
    VoidCallback toggle,
    bool hovered,
  ) {
    final t = ComicTheme.of(context);
    final c = t.colors;
    final wrong = error != null || comicFieldInError(context);
    final look = ComicStyleOf(
      [style, t.textFieldTheme],
      comicStates(
        enabled: enabled,
        focused: effectiveFocus.hasFocus,
        hovered: hovered,
        error: wrong,
      ),
    );
    final inputInk = onPaper
        ? c.onPaper
        : c.dark
        ? c.text
        : c.onPaper;
    final inputHint = onPaper
        ? c.hint
        : c.dark
        ? c.textSecondary
        : c.hint;
    // A talking field's rim is the night line too: by night the ink line vanished on the ground and the field read
    // 2.5 px shorter than the send button beside it (ui_core's DesignRowCheck); by day the two lines are one.
    final rim = comicRim(t, look, wrong ? c.tones.danger : c.nightLine);
    // Every field's words at one size: a reply's at 14 on a phone read as a different part beside a form's.
    final textStyle = t.type
        .text(
          16,
          maxLines > 1 ? 1.4 : 1.3,
          weight: FontWeight.w600,
          color: inputInk,
        )
        .merge(look.textStyle)
        .copyWith(color: look.foreground ?? inputInk);
    // The editor itself fills the target, including the room above and below
    // its words, so both pointer taps and its semantics use the whole height.
    final words =
        MediaQuery.textScalerOf(context).scale(textStyle.fontSize ?? 16) *
        (textStyle.height ?? 1.3);
    final reach = maxLines > 1
        ? 0.0
        : math.max(0.0, (ComicTapTarget.targetOf(context) - words) / 2);
    final editor = Material(
      type: MaterialType.transparency,
      child: Theme(
        data: Theme.of(context).copyWith(visualDensity: VisualDensity.standard),
        child: TextFormField(
          controller: controller,
          enabled: enabled,
          focusNode: effectiveFocus,
          autofocus: autofocus,
          textInputAction: textInputAction,
          autofillHints: autofillHints,
          inputFormatters: inputFormatters,
          contextMenuBuilder: ComicTextContextMenu.editable,
          selectionControls: ComicTextSelectionControls.of(
            Theme.of(context).platform,
          ),
          initialValue: controller == null ? initialValue : null,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          onEditingComplete: onEditingComplete,
          style: textStyle,
          keyboardType: keyboardType,
          textDirection: textDirection,
          obscureText: obscureText || (password && hidden),
          minLines: minLines ?? maxLines,
          maxLines: maxLines,
          cursorColor: look.foreground ?? inputInk,
          textAlignVertical: maxLines > 1
              ? TextAlignVertical.top
              : TextAlignVertical.center,
          decoration: InputDecoration(
            isCollapsed: true,
            border: InputBorder.none,
            hint: hint == null
                ? null
                : ExcludeSemantics(
                    child: Text(
                      hint!,
                      style: textStyle.copyWith(color: inputHint),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
            hintStyle: textStyle.copyWith(color: inputHint),
            hintMaxLines: 1,
            contentPadding: EdgeInsets.symmetric(vertical: reach),
          ),
        ),
      ),
    );
    // A one-line entry draws its capitals on the field's middle, as every face's label: the
    // caret, the hint and taps move with it.
    final line = maxLines > 1
        ? editor
        : CapLabel(display: false, child: editor);
    final input =
        decorate?.call(line) ??
        Semantics(
          label: label ?? hint,
          hint: error ?? helper ?? (label == null ? null : hint),
          child: line,
        );
    final trailing = password
        ? ComicIconButton(
            hidden ? ComicGlyphs.show : ComicGlyphs.hide,
            style: comicInFieldIcon,
            label: hidden
                ? (revealLabels?.$1 ??
                      DesignLocalizations.of(context).showPasswordLabel)
                : (revealLabels?.$2 ??
                      DesignLocalizations.of(context).hidePasswordLabel),
            onPressed: enabled ? toggle : null,
          )
        : this.trailing;
    final frame = AnimatedComicShape(
      shape: look.shape ?? (maxLines > 1 ? t.shapes.medium : t.shapes.small),
      // The keyboard's focus rings the field as it rings every part: the look's ring, concentric outside the frame
      // (the frame recoloured to the ring's ink was the same ink as its rim in light).
      builder: (context, shape) => ComicHighlight(
        states: {if (effectiveFocus.hasFocus) WidgetState.focused},
        shape: shape ?? const RoundedRectangleBorder(),
        wash: false,
        child: ComicStateDecoration(
          decoration: ShapeDecoration(
            color:
                look.fill ??
                (onPaper
                    ? c.paper
                    : c.dark
                    ? c.card
                    : c.control),
            shape: (shape ?? const RoundedRectangleBorder()).copyWith(
              side: rim,
            ),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: look.minimumSize?.width ?? 0,
              minHeight: math.max(
                ComicTapTarget.targetOf(context),
                look.minimumSize?.height ??
                    t.density.height(maxLines > 1 ? 92 : 48),
              ),
            ),
            child: Padding(
              padding:
                  (look.padding(Directionality.of(context)) ??
                          t.density.padding(
                            EdgeInsets.fromLTRB(
                              comicFieldWords,
                              maxLines > 1 ? 12 : 0,
                              comicFieldWords,
                              maxLines > 1 ? 12 : 0,
                            ),
                          ))
                      .add(shape?.dimensions ?? EdgeInsets.zero),
              child: IconTheme.merge(
                data: IconThemeData(
                  color: look.foreground ?? inputInk,
                  size: look.iconSize ?? 18,
                ),
                child: maxLines > 1
                    ? input
                    : Row(
                        children: [
                          if (leading != null) ...[
                            leading!,
                            const SizedBox(width: 8),
                          ],
                          if (prefix != null) ...[
                            Text(
                              prefix!,
                              style: textStyle.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(child: input),
                          if (trailing != null) ...[
                            const SizedBox(width: 10),
                            trailing,
                          ],
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
    return Semantics(
      validationResult: error == null
          ? SemanticsValidationResult.none
          : SemanticsValidationResult.invalid,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (label != null && showLabel) ...[
            ExcludeSemantics(child: Text(label!, style: t.type.title)),
            const SizedBox(height: 6),
          ],
          Opacity(opacity: enabled ? 1 : .55, child: frame),
          if (error != null || helper != null) ...[
            const SizedBox(height: 6),
            _fieldLine(
              Text(
                error ?? helper!,
                style: t.type.small.copyWith(
                  color: error == null ? c.textSecondary : c.tones.danger,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _fieldLine(Widget line) => error == null
      ? ExcludeSemantics(child: line)
      : failureLine?.call(line) ??
            Semantics(container: true, liveRegion: true, child: line);
}

class _FieldFocus extends StatefulWidget {
  const _FieldFocus({this.node, required this.builder});
  final FocusNode? node;
  final Widget Function(BuildContext, FocusNode, bool, VoidCallback, bool)
  builder;
  @override
  State<_FieldFocus> createState() => _FieldFocusState();
}

class _FieldFocusState extends State<_FieldFocus> {
  bool _hidden = true, _hovered = false;
  final _owned = FocusNode();
  FocusNode get _node => widget.node ?? _owned;
  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _node.addListener(_changed);
  }

  @override
  void didUpdateWidget(_FieldFocus old) {
    super.didUpdateWidget(old);
    if (old.node != widget.node) {
      (old.node ?? _owned).removeListener(_changed);
      _node.addListener(_changed);
    }
  }

  @override
  void dispose() {
    _node.removeListener(_changed);
    _owned.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hovered = true),
    onExit: (_) => setState(() => _hovered = false),
    child: widget.builder(
      context,
      _node,
      _hidden,
      () => setState(() => _hidden = !_hidden),
      _hovered,
    ),
  );
}

/// The small act at the end of a reply field.
///
/// ```dart
/// ComicSendButton(onPressed: () {})
/// ```
class ComicSendButton extends StatelessWidget {
  /// Creates a reply action using the icon-button theme.
  const ComicSendButton({
    super.key,
    this.onPressed,
    this.label,
    this.style,
    this.focusNode,
    this.autofocus = false,
  });

  /// Overrides the localized send label.
  final String? label;

  /// Null disables the action.
  final VoidCallback? onPressed;

  /// Per-state appearance above the icon theme.
  final ComicStyle? style;

  /// The caller's focus node, if any; the part makes its own when null.
  final FocusNode? focusNode;

  /// Whether the part asks for the focus when it first appears.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    return ComicIconButton(
      ComicGlyphs.sendHorizontal,
      focusNode: focusNode,
      autofocus: autofocus,
      label: label ?? ComicLocalizations.of(context).send,
      size: 46,
      onPressed: onPressed,
      style: ComicStyle.layered([
        style,
        t.iconButtonTheme,
        ComicStyle(
          fill: WidgetStatePropertyAll(t.colors.primary),
          foreground: WidgetStatePropertyAll(t.colors.onPrimary),
        ),
      ]),
    );
  }
}

/// A read-only picker: a value, a dim note and a arrow, in a field's box.
///
/// ```dart
/// ComicSelectField(value: 'Current ··3108', note: 'Change', onPressed: () {})
/// ```
class ComicSelectField extends StatelessWidget {
  /// Creates a [ComicSelectField].
  const ComicSelectField({
    super.key,
    this.style,
    required this.value,
    this.note,
    this.onPressed,
    this.focusNode,
    this.autofocus = false,
  });

  /// Per-state field appearance.
  final ComicStyle? style;

  /// The current value represented by the control or record.
  final String value;

  /// Secondary explanatory text.
  final String? note;

  /// Called when activated; null disables the action.
  final VoidCallback? onPressed;

  /// The caller's focus node, if any; the part makes its own when null.
  final FocusNode? focusNode;

  /// Whether the part asks for the focus when it first appears.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context), c = t.colors;
    final layers = [style, t.textFieldTheme],
        base = ComicStyleOf([style, t.textFieldTheme], const {});
    // A dropdown's face: its content's width, at most comicDropdownMost from 600 up.
    return comicDropdownWidth(
      context,
      ComicPressable(
        focusNode: focusNode,
        autofocus: autofocus,
        onPressed: onPressed,
        label: value,
        outline: base.shapes(t.shapes.small),
        overlay: base.overlay,
        builder: (context, states) {
          final look = ComicStyleOf(layers, states),
              rim = comicRim(
                t,
                ComicStyleOf(layers, states),
                comicFieldInError(context) ? c.tones.danger : c.nightLine,
              );
          final ink = look.foreground ?? (c.dark ? c.text : c.onPaper);
          final text = t.type
              .text(16, 1.3, weight: FontWeight.w600)
              .merge(look.textStyle)
              .copyWith(color: ink);
          return AnimatedComicShape(
            shape: look.shape ?? t.shapes.small,
            builder: (context, shape) => ComicStateDecoration.box(
              constraints: BoxConstraints(
                minWidth: look.minimumSize?.width ?? 0,
                // A select stands as tall as a text field beside it (and as a trough of choices).
                minHeight:
                    look.minimumSize?.height ?? ComicTrack.fieldHeight(context),
              ),
              decoration: ShapeDecoration(
                color: look.fill ?? (c.dark ? c.card : c.control),
                shape: (shape ?? const RoundedRectangleBorder()).copyWith(
                  side: rim,
                ),
              ),
              // The box adds its rim to the padding; the words stand on the field's keyline all the same.
              padding:
                  look.padding(Directionality.of(context)) ??
                  comicFieldInset(t) -
                      EdgeInsetsDirectional.only(
                        start: rim.strokeInset,
                        end: rim.strokeInset,
                      ),
              child: ComicFitRow(
                fill: 0,
                gap: 10,
                fillShare: .3,
                children: [
                  CapLabel(
                    child: Text(
                      value,
                      style: text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (note != null)
                    Text(
                      note!,
                      style: t.type.small.copyWith(
                        color:
                            look.foreground ??
                            (c.dark ? c.textSecondary : c.hint),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  Icon(
                    ComicGlyphs.chevronDown,
                    size: look.iconSize ?? 18,
                    color: ink,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A short filter or quick reply, as wide as its word, on the family's capsule step. It wears the lamp when [selected]; a choice is lit,
/// not acted on.
///
/// ```dart
/// ComicChip('Fish', selected: true, onPressed: () {})
/// ```
class ComicChip extends StatelessWidget {
  /// Creates a [ComicChip].
  const ComicChip(
    this.label, {
    super.key,
    this.style,
    this.onPressed,
    this.selected = false,
    this.onDeleted,
    this.deleteButtonTooltipMessage,
    this.icon,
    this.focusNode,
    this.autofocus = false,
  }) : onSelected = null;

  /// Creates a filter chip: a choice the reader turns on and off, lit when [selected]. [onSelected] reports the new
  /// state; null disables it.
  const ComicChip.filter(
    this.label, {
    super.key,
    this.style,
    required this.selected,
    required this.onSelected,
    this.icon,
    this.focusNode,
    this.autofocus = false,
  }) : onPressed = null,
       onDeleted = null,
       deleteButtonTooltipMessage = null;

  /// A filter chip's change: its new state. Null on a plain chip, which reports [onPressed].
  final ValueChanged<bool>? onSelected;

  VoidCallback? get _press =>
      onSelected == null ? onPressed : () => onSelected!(!selected);

  /// The visible or spoken name of the component.
  final String label;

  /// Called when activated; null disables the action.
  final VoidCallback? onPressed;

  /// Removes this chip through a separate control.
  final VoidCallback? onDeleted;

  /// Overrides the localized removal name; also shows a disabled remove control.
  final String? deleteButtonTooltipMessage;

  /// Optional mark before the label.
  final IconData? icon;

  /// The caller's focus node for the chip's press, if any.
  final FocusNode? focusNode;

  /// Whether the chip asks for the focus when it first appears.
  final bool autofocus;

  /// Whether this choice is selected.
  final bool selected;

  /// Per-state face style, above the component theme and the look.
  final ComicStyle? style;
  @override
  Widget build(BuildContext context) {
    if (onDeleted != null || deleteButtonTooltipMessage != null) {
      return _removable(context);
    }
    final t = ComicTheme.of(context), c = t.colors;
    final layers = [style, t.chipTheme],
        base = ComicStyleOf([style, t.chipTheme], const {});
    return ComicPressable(
      onPressed: _press,
      focusNode: focusNode,
      autofocus: autofocus,
      label: label,
      selected: selected,
      outline: base.shapes(t.shapes.capsule),
      overlay: base.overlay,
      builder: (context, states) {
        final look = ComicStyleOf(layers, states),
            rim = comicRim(t, ComicStyleOf(layers, states), c.nightLine);
        return AnimatedComicShape(
          shape: look.shape ?? t.shapes.capsule,
          builder: (context, shape) => ComicStateDecoration.box(
            constraints: BoxConstraints(
              minWidth: look.minimumSize?.width ?? 0,
              minHeight: look.minimumSize?.height ?? t.density.height(36),
            ),
            padding:
                (look.padding(Directionality.of(context)) ??
                        t.density.padding(
                          const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                        ))
                    .add(
                      shape == null ? EdgeInsets.zero : const EdgeInsets.all(6),
                    ),
            decoration: ShapeDecoration(
              color:
                  look.fill ??
                  (selected
                      ? c.caption
                      : c.dark
                      ? c.card
                      : c.control),
              shape: (shape ?? const RoundedRectangleBorder()).copyWith(
                side: rim,
              ),
            ),
            child: Center(
              widthFactor: 1,
              heightFactor: 1,
              child: icon == null
                  ? CapLabel(
                      child: Text(
                        label,
                        style: t.type
                            .text(14, 1.1, weight: FontWeight.w700)
                            .merge(look.textStyle)
                            .copyWith(
                              color:
                                  look.foreground ??
                                  (selected
                                      ? c.onCaption
                                      : c.dark
                                      ? c.text
                                      : c.onPaper),
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          size: look.iconSize ?? 18,
                          color:
                              look.foreground ??
                              (selected
                                  ? c.onCaption
                                  : c.dark
                                  ? c.text
                                  : c.onPaper),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: CapLabel(
                            child: Text(
                              label,
                              style: t.type
                                  .text(14, 1.1, weight: FontWeight.w700)
                                  .merge(look.textStyle)
                                  .copyWith(
                                    color:
                                        look.foreground ??
                                        (selected
                                            ? c.onCaption
                                            : c.dark
                                            ? c.text
                                            : c.onPaper),
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  /// The cross's place, and the room from it to the chip's end: it stands as far in as down from the top of a chip
  /// the plain one's height, concentric with the capsule's end.
  static const double _crossBox = 24, _crossEnd = 10;

  Widget _removable(BuildContext context) {
    final t = ComicTheme.of(context), c = t.colors;
    final layers = [style, t.chipTheme];
    final direction = Directionality.of(context);
    final disabled = onDeleted == null && _press == null;
    // The chip's face is the plain chip's (its room, its words, its least height), so a chip with its remove stands
    // the plain one's height in one row with it (11-12): the cross stands inside the face, the room at its end held
    // for it, as a password field's eye stands inside the field.
    Widget face(Set<WidgetState> states) {
      final look = ComicStyleOf(layers, states);
      // The words move to their new ink with the plate under them.
      return ComicStateLerp<Color?>(
        value:
            look.foreground ??
            (selected
                ? c.onCaption
                : c.dark
                ? c.text
                : c.onPaper),
        lerp: Color.lerp,
        builder: (context, ink, _) {
          final words = CapLabel(
            child: Text(
              label,
              style: t.type
                  .text(14, 1.1, weight: FontWeight.w700)
                  .merge(look.textStyle)
                  .copyWith(color: ink),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          );
          return AnimatedComicShape(
            shape: look.shape ?? t.shapes.capsule,
            builder: (context, shape) {
              final room =
                  (look.padding(direction) ??
                          t.density.padding(
                            const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                          ))
                      .add(
                        shape == null
                            ? EdgeInsets.zero
                            : const EdgeInsets.all(6),
                      )
                      .resolve(direction);
              return ComicStateDecoration.box(
                constraints: BoxConstraints(
                  minWidth: look.minimumSize?.width ?? 0,
                  minHeight: look.minimumSize?.height ?? t.density.height(36),
                ),
                padding: EdgeInsetsDirectional.fromSTEB(
                  direction == TextDirection.rtl ? room.right : room.left,
                  room.top,
                  _crossEnd,
                  room.bottom,
                ),
                decoration: ShapeDecoration(
                  color:
                      look.fill ??
                      (selected
                          ? c.caption
                          : c.dark
                          ? c.card
                          : c.control),
                  shape: (shape ?? const RoundedRectangleBorder()).copyWith(
                    side: comicRim(t, look, c.nightLine),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: look.iconSize ?? 18, color: ink),
                      const SizedBox(width: 8),
                    ],
                    Flexible(child: words),
                    const SizedBox(width: 6),
                    // The cross's place: it stands over it, the chip's whole height.
                    const SizedBox(width: _crossBox),
                  ],
                ),
              );
            },
          );
        },
      );
    }

    final base = ComicStyleOf(layers, const {});
    // A chip that takes nothing at all is disabled, and says so as the plain chip does: its press stays, with nothing
    // to run. A chip that only removes shows its words, its cross the one press.
    final Widget chip = _press == null && !disabled
        ? face({if (selected) WidgetState.selected})
        : ComicPressable(
            label: label,
            selected: selected,
            onPressed: _press,
            focusNode: focusNode,
            autofocus: autofocus,
            outline: base.shapes(t.shapes.capsule),
            overlay: base.overlay,
            builder: (context, states) => face(states),
          );
    final look = ComicStyleOf(layers, {
      if (disabled) WidgetState.disabled,
      if (selected) WidgetState.selected,
    });
    final ink =
        look.foreground ??
        (selected
            ? c.onCaption
            : c.dark
            ? c.text
            : c.onPaper);
    // The cross: its glyph in its place at the face's end, its press the platform's least target wide and tall,
    // centred on the face as the plain chip's target stands round its face (the face never grows for it); a pointer
    // or the keyboard lights a round mark round the glyph.
    final reach = math.max(
      ComicTapTarget.targetOf(context),
      2 * (_crossEnd + _crossBox / 2),
    );
    final cross = ComicPressable(
      label:
          deleteButtonTooltipMessage ??
          '${ComicLocalizations.of(context).delete} $label',
      onPressed: onDeleted,
      target: true,
      outline: WidgetStatePropertyAll(t.shapes.capsule),
      builder: (context, states) => SizedBox.square(
        dimension: _crossBox,
        child: Center(child: Icon(ComicGlyphs.x, size: 16, color: ink)),
      ),
    );
    // The face takes what its parent gives, as the plain chip's does: it hugs its words in a row or a wrap, and a
    // stretching column widens it, the cross at its end and the press on the cross. Only the press's room is the
    // target's height; the face keeps its own.
    return Stack(
      fit: StackFit.passthrough,
      alignment: AlignmentDirectional.centerStart,
      children: [
        chip,
        SizedBox(height: reach),
        PositionedDirectional(
          top: 0,
          bottom: 0,
          end: math.max(0.0, _crossEnd + _crossBox / 2 - reach / 2),
          width: reach,
          child: cross,
        ),
      ],
    );
  }
}

/// A square tick box, with its tap target around it.
///
/// ```dart
/// ComicCheckbox(label: 'Keep issue', value: true, onChanged: (v) {})
/// ```
class ComicCheckbox extends StatelessWidget {
  /// Creates a [ComicCheckbox].
  const ComicCheckbox({
    super.key,
    this.style,
    required this.value,
    this.onChanged,
    required this.label,
    this.isError = false,
    this.tristate = false,
    this.focusNode,
    this.autofocus = false,
  }) : assert(tristate || value != null);

  /// Whether null is a third state. The cycle is false, true, null.
  final bool tristate;

  /// The current value represented by the control or record.
  final bool? value;

  /// Reports a new value; null disables changes.
  final ValueChanged<bool?>? onChanged;

  /// The visible or spoken name of the component.
  final String label;

  /// Whether validation failed, announced and exposed as WidgetState.error.
  final bool isError;

  /// Per-state face style, above the component theme and the look.
  final ComicStyle? style;

  /// The caller's focus node, if any; the part makes its own when null.
  final FocusNode? focusNode;

  /// Whether the part asks for the focus when it first appears.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context), c = t.colors;
    final layers = [style, t.checkboxTheme];
    final base = ComicStyleOf(layers, const {});
    final target = ComicTapTarget.targetOf(context);
    return comicOwnSize(
      child: ComicPressable(
        focusNode: focusNode,
        autofocus: autofocus,
        onPressed: onChanged == null
            ? null
            : () => onChanged!(
                tristate
                    ? (value == false
                          ? true
                          : value == true
                          ? null
                          : false)
                    : value != true,
              ),
        label: label,
        error: isError,
        checked: value == true,
        mixed: value == null,
        button: false,
        // The marks are the box's own: drawn below, on the mark, not on its larger target.
        wash: false,
        ring: false,
        builder: (context, states) {
          final look = ComicStyleOf(layers, states);
          final box = comicCappedShape(t.shapes.small, 7);
          final rim = comicRim(
            t,
            look,
            isError || comicFieldInError(context)
                ? c.tones.danger
                : c.nightLine,
          );
          return AnimatedComicShape(
            shape: look.shape ?? box,
            builder: (context, shape) => comicOwnSize(
              width: math.max(
                target,
                _markExtent(
                  look.minimumSize?.width ?? 26,
                  18,
                  shape,
                  rim,
                  Directionality.of(context),
                  vertical: false,
                ),
              ),
              height: math.max(
                target,
                _markExtent(
                  look.minimumSize?.height ?? 26,
                  18,
                  shape,
                  rim,
                  Directionality.of(context),
                  vertical: true,
                ),
              ),
              child: Center(
                child: ComicPressFace(
                  child: comicOwnSize(
                    width: _markExtent(
                      look.minimumSize?.width ?? 26,
                      18,
                      shape,
                      rim,
                      Directionality.of(context),
                      vertical: false,
                    ),
                    height: _markExtent(
                      look.minimumSize?.height ?? 26,
                      18,
                      shape,
                      rim,
                      Directionality.of(context),
                      vertical: true,
                    ),
                    child: ComicHighlight(
                      states: states,
                      shape: shape ?? box,
                      wash: onChanged != null,
                      overlay: onChanged == null
                          ? null
                          : base.overlay?.resolve(states),
                      child: ComicStateDecoration(
                        decoration: ShapeDecoration(
                          color:
                              look.fill ??
                              (value != false
                                  ? c.caption
                                  : c.dark
                                  ? c.card
                                  : c.control),
                          shape: (shape ?? box).copyWith(side: rim),
                        ),
                        child: value != false
                            ? Center(
                                child: Padding(
                                  padding: shape?.dimensions ?? EdgeInsets.zero,
                                  child: Icon(
                                    value == null
                                        ? ComicGlyphs.minus
                                        : ComicGlyphs.check,
                                    size: 18,
                                    color: look.foreground ?? c.onCaption,
                                  ),
                                ),
                              )
                            : null,
                      ),
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
}

/// The box of every option: a contour on the control's fill; selected, it wears the lamp, and everything in it reads on that
/// by itself.
///
/// ```dart
/// ComicChoiceBox(selected: true, onPressed: () {}, child: Text('Mild'))
/// ```
class ComicChoiceBox extends StatelessWidget {
  /// Creates a [ComicChoiceBox].
  const ComicChoiceBox({
    super.key,
    this.style,
    required this.child,
    this.selected = false,
    this.padding = EdgeInsets.zero,
    this.wordsAt,
    this.onPressed,
    this.label,
    this.focusNode,
    this.onKeyEvent,
    this.hint,
    this.many = false,
    this.inGroup = false,
    this.autofocus = false,
  });

  /// Supporting accessibility information.
  final String? hint;

  /// Checkbox selection, or exclusive group membership.
  final bool many, inGroup;

  /// Content placed inside this widget.
  final Widget child;

  /// Whether this choice is selected.
  final bool selected;

  /// Space between the content and its boundary.
  final EdgeInsetsGeometry padding;

  /// Where the words start from the box's outer edges, on either side: a text field's in a stack of fields
  /// (ComicChoices sets it). Null keeps [padding] inside the rim.
  final double? wordsAt;

  /// Called when activated; null disables the action.
  final VoidCallback? onPressed;

  /// The visible or spoken name of the component.
  final String? label;

  /// Optional caller-owned focus node.
  final FocusNode? focusNode;

  /// Additional keys handled by a grouped choice.
  final KeyEventResult Function(FocusNode, KeyEvent)? onKeyEvent;

  /// Per-state face style, above the component theme and the look.
  final ComicStyle? style;
  // The room inside the box: [wordsAt] on either side when set, the vertical room as computed.
  EdgeInsets _inset(EdgeInsets room) =>
      wordsAt == null ? room : room.copyWith(left: wordsAt, right: wordsAt);

  /// Whether the part asks for the focus when it first appears.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context), c = t.colors;
    final layers = [style, t.optionTheme],
        look = ComicStyleOf([style, t.optionTheme], const {});
    return ComicPressable(
      autofocus: autofocus,
      onPressed: onPressed,
      label: label,
      selected: many || inGroup ? null : selected,
      checked: many || inGroup ? selected : null,
      inGroup: inGroup,
      hint: hint,
      button: !many && !inGroup,
      focusNode: focusNode,
      keys: onKeyEvent,
      outline: look.shapes(t.shapes.small),
      overlay: look.overlay,
      builder: (context, states) {
        final look = ComicStyleOf(layers, states),
            rim = comicRim(t, ComicStyleOf(layers, states), c.nightLine);
        return AnimatedComicShape(
          shape: look.shape ?? t.shapes.small,
          builder: (context, shape) => ComicStateDecoration(
            decoration: ShapeDecoration(
              color:
                  look.fill ??
                  (selected
                      ? c.caption
                      : c.dark
                      ? c.card
                      : c.control),
              shape: (shape ?? const RoundedRectangleBorder()).copyWith(
                side: rim,
              ),
            ),
            child: Padding(
              padding: _inset(
                (look.padding(Directionality.of(context)) ??
                        padding.resolve(Directionality.of(context))) +
                    EdgeInsets.all(rim.width + (shape == null ? 0 : 8)) +
                    (shape?.dimensions.resolve(Directionality.of(context)) ??
                        EdgeInsets.zero),
              ),
              child: ComicLetteringScope(
                look.foreground ??
                    (selected
                        ? c.onCaption
                        : c.dark
                        ? c.text
                        : c.onPaper),
                child: DefaultTextStyle.merge(
                  style: look.textStyle ?? const TextStyle(),
                  child: child,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// One choice in a [ComicChoices]: its words, an optional small line, and the value it stands for (its words if left out).
class ComicChoice {
  /// Creates a [ComicChoice].
  const ComicChoice(this.label, {this.note, String? value})
    : value = value ?? label;

  /// [label]: the visible or spoken name of the component. [value]: the current value represented by the control or record.
  final String label, value;

  /// Secondary explanatory text.
  final String? note;
}

/// One choice from a few, as tiles: a filter, a grade, a size, a kind. Give it the words: on a phone it puts as many on a row
/// as hold their longest word, and the rest on the next rows, so no tile crushes; from 600 up each tile keeps to its words
/// (its name over its note), side by side. Never write this as a `Row` of `Expanded` boxes. The selected tile wears the lamp.
///
/// ```dart
/// ComicChoices(options: const [ComicChoice('All'), ComicChoice('Mild', note: 'For everyone')], value: 'All', onChanged: (v) {})
/// ```
class ComicChoices extends StatelessWidget {
  /// Creates a [ComicChoices].
  const ComicChoices({
    super.key,
    this.style,
    required this.options,
    this.value,
    this.onChanged,
  });

  /// Choices available to the user.
  final List<ComicChoice> options;

  /// The value of the selected option; none, if null.
  final String? value;

  /// Reports a new value; null disables changes.
  final ValueChanged<String>? onChanged;

  /// Per-state appearance forwarded to the public control.
  final ComicStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    final words = t.type.title;
    final notes = options.any((o) => o.note != null);
    return LayoutBuilder(
      builder: (context, box) {
        // The words stand on a text field's inner keyline, so choices and fields stacked in a panel share it.
        final pad = comicFieldWordsAt(t);
        const gap = 6.0;
        // From 600 up a tile keeps to its words, side by side as chips are (no button or segmented control
        // stretches to its column), a tile with a note too, its name over its note (the design kit's checks holds a group
        // of choices to what its tiles take); on a phone they share the column in a grid.
        if (t.width >= 600) {
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final o in options)
                ComicChoiceBox(
                  style: style,
                  selected: o.value == value,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  wordsAt: pad,
                  label: o.label,
                  onPressed: onChanged == null
                      ? null
                      : () => onChanged!(o.value),
                  child: Builder(
                    builder: (context) {
                      final tt = ComicTheme.of(context);
                      final name = CapLabel(
                        child: Text(
                          o.label,
                          maxLines: 1,
                          softWrap: false,
                          style: tt.type.title,
                        ),
                      );
                      if (!notes) return name;
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          name,
                          if (o.note != null) ...[
                            const SizedBox(height: 2),
                            Text(o.note!, style: tt.type.meta),
                          ],
                        ],
                      );
                    },
                  ),
                ),
            ],
          );
        }
        var need = notes ? 104.0 : 56.0;
        final scaler = MediaQuery.textScalerOf(context);
        for (final o in options) {
          // A short label stays on one line; a long one may wrap, between its words.
          final holds = o.label.length <= 16
              ? _wholeWidth(o.label, words, scaler)
              : comicWidestWord(o.label, words, textScaler: scaler);
          need = math.max(need, holds + 2 * pad + 10);
          if (o.note != null) {
            // A note may wrap between its words, never inside one.
            need = math.max(
              need,
              comicWidestWord(o.note!, t.type.small, textScaler: scaler) +
                  2 * pad +
                  10,
            );
          }
        }
        final w = box.hasBoundedWidth ? box.maxWidth : 390.0;
        var columns = math.max(
          1,
          math.min(options.length, ((w + gap) / (need + gap)).floor()),
        );
        // One left alone on its row reads worse than a row one shorter.
        if (columns > 2 && options.length % columns == 1) columns -= 1;
        // Choices with a line of detail stand on one line when they fit, else one to a row at the full width, the name
        // at the start and the detail at the end: never a tile left alone under a pair.
        final rows =
            notes && columns < options.length && options.length % columns != 0;
        if (rows) columns = 1;
        return ComicGridOf(
          columns: columns,
          gap: gap,
          runGap: gap,
          children: [
            for (final o in options)
              ComicChoiceBox(
                style: style,
                selected: o.value == value,
                padding: const EdgeInsets.symmetric(vertical: 8),
                wordsAt: pad,
                label: o.label,
                onPressed: onChanged == null ? null : () => onChanged!(o.value),
                child: Builder(
                  builder: (context) {
                    final tt = ComicTheme.of(context);
                    if (rows) {
                      // The name and its detail each on the row's middle, as every label sits on its face's.
                      return Row(
                        children: [
                          Expanded(
                            child: CapLabel(
                              child: Text(o.label, style: tt.type.title),
                            ),
                          ),
                          if (o.note != null) ...[
                            const SizedBox(width: 12),
                            Flexible(
                              child: CapLabel(
                                child: Text(
                                  o.note!,
                                  style: tt.type.meta,
                                  textAlign: TextAlign.end,
                                ),
                              ),
                            ),
                          ],
                        ],
                      );
                    }
                    return SizedBox(
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: notes
                            ? CrossAxisAlignment.start
                            : CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CapLabel(
                            child: Text(
                              o.label,
                              style: tt.type.title,
                              textAlign: notes
                                  ? TextAlign.start
                                  : TextAlign.center,
                            ),
                          ),
                          if (o.note != null) ...[
                            const SizedBox(height: 2),
                            Text(o.note!, style: tt.type.meta),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

/// A number stepper: one trough at a field's height, less and more as square cells at its ends and the lettered
/// count with its unit between them; a note under it. A press marks its cell concentric with the trough.
///
/// ```dart
/// ComicNumberField(value: 6, unit: 'servings', onChanged: (_) {})
/// ```
class ComicNumberField extends StatelessWidget {
  /// Creates a [ComicNumberField].
  const ComicNumberField({
    super.key,
    this.style,
    required this.value,
    this.onChanged,
    this.min,
    this.max,
    this.step = 1,
    this.format,
    this.unit,
    this.note,
    this.lessLabel,
    this.moreLabel,
  });

  /// The count shown.
  final int value;

  /// Receives the count a step less or more; null disables both steps.
  final ValueChanged<int>? onChanged;

  /// The least and the most the count may be; a step past either is disabled. Null leaves that end open.
  final int? min, max;

  /// How far one press moves the count.
  final int step;

  /// Writes the count, `'$value'` when null.
  final String Function(int value)? format;

  /// The word under the number, when the row around it hasn't said.
  final String? unit;

  /// Secondary explanatory text.
  final String? note;

  /// Overrides the localized decrease label.
  final String? lessLabel;

  /// Overrides the localized increase label.
  final String? moreLabel;

  /// Appearance above the stepper component theme.
  final ComicStyle? style;

  VoidCallback? _step(int by) {
    final next = value + by, change = onChanged;
    if (change == null ||
        (min != null && next < min!) ||
        (max != null && next > max!)) {
      return null;
    }
    return () => change(next);
  }

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    final c = t.colors;
    final layers = [style, t.stepperTheme];
    final look = ComicStyleOf(layers, const {});
    // One trough at a field's height: less and more are square cells at its ends, the count between them. A press
    // marks a cell in the trough's outline moved in by the rim and 2 px, so the marks are concentric with it.
    final rim = comicRim(t, look, c.nightLine);
    final outer = look.shape ?? t.shapes.small;
    final inner = ComicTrack.cellShape(outer, rim);
    final ink = look.foreground ?? (c.dark ? c.text : c.onPaper);
    final side = ComicTrack.fieldHeight(context) - 2 * rim.width;
    Widget end(bool more) => ComicPressable(
      label: more
          ? moreLabel ?? ComicLocalizations.of(context).more
          : lessLabel ?? ComicLocalizations.of(context).less,
      wash: false,
      ring: false,
      sink: false,
      onPressed: more ? _step(step) : _step(-step),
      // The trough is the surface, so a cell's slot in it is its whole target wide (the trough has no room beside it
      // for a target to stand out into), the cell's mark centred in it.
      builder: (context, states) => SizedBox(
        width: math.max(side, ComicTapTarget.targetOf(context)),
        height: side,
        child: Center(
          child: SizedBox.square(
            dimension: side,
            child: ComicTrackFace(
              states: states,
              shape: inner,
              overlay: look.overlay?.resolve(states),
              padding: EdgeInsets.zero,
              child: Icon(
                more ? ComicGlyphs.plus : ComicGlyphs.minus,
                size: look.iconSize ?? 20,
                color: ink,
              ),
            ),
          ),
        ),
      ),
    );
    // The count's line holds its glyphs (the letter face stands about 1.29 of
    // its size, ascent to descent) and stands the rim and 2 px inside the
    // trough's outline: at 1.0 that is 45 of a field's 48, and at a larger
    // text size the trough grows with it instead of the count running under
    // the rim (cells span the trough's whole height, under its rim).
    final number = t.type
        .letter(28, lineHeight: 1.3)
        .merge(look.textStyle)
        .copyWith(color: ink);
    final Widget track = ComicTrack(
      shape: outer,
      rim: rim,
      fill: look.fill ?? (c.dark ? c.card : c.control),
      equal: false,
      grow: const {1},
      cells: [
        end(false),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 64, maxWidth: 140),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 8,
              vertical: rim.width + 2,
            ),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      format?.call(value) ?? '$value',
                      maxLines: 1,
                      style: number,
                    ),
                    if (unit != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        unit!.toUpperCase(),
                        maxLines: 1,
                        style: t.type.text(
                          11,
                          1.2,
                          weight: FontWeight.w800,
                          color: c.dark ? c.textSecondary : c.onPaperSecondary,
                          tracking: .06,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        end(true),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // From 600 up a stepper keeps to its count (no stepper stretches to its column); on a phone it
        // takes its column, as a field does.
        if (t.width >= 600) IntrinsicWidth(child: track) else track,
        if (note != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(note!, style: t.type.small),
          ),
      ],
    );
  }
}

class _SwitchPainter extends CustomPainter {
  _SwitchPainter(
    this.position,
    this.c, {
    this.fill,
    this.foreground,
    this.side,
    this.shape,
    this.rtl = false,
  });
  final Color? fill, foreground;
  final BorderSide? side;
  final OutlinedBorder? shape;
  final bool rtl;
  final double position;
  final ComicColors c;
  @override
  void paint(Canvas canvas, Size s) {
    final r = Offset.zero & s;
    final rim = side ?? BorderSide(color: c.nightLine, width: 2.5);
    final outline = shape?.copyWith(side: rim);
    if (outline == null) {
      canvas.drawRect(
        r,
        fillPaint(
          fill ?? Color.lerp(c.dark ? c.card : c.control, c.caption, position)!,
        ),
      );
      canvas.drawRect(
        r.deflate(rim.width / 2),
        strokePaint(rim.color, rim.width),
      );
    } else {
      canvas.drawPath(
        outline.getOuterPath(r),
        fillPaint(
          fill ?? Color.lerp(c.dark ? c.card : c.control, c.caption, position)!,
        ),
      );
      outline.paint(canvas, r);
    }
    final knob = Rect.fromLTWH(
      5 + (s.width - s.height) * (rtl ? 1 - position : position),
      5,
      s.height - 10,
      s.height - 10,
    );
    if (shape == null) {
      canvas.drawRect(
        knob,
        fillPaint(
          foreground ?? Color.lerp(c.nightLine, c.onCaption, position)!,
        ),
      );
    } else {
      canvas.drawPath(
        comicInsetShape(shape!, 5).getOuterPath(knob),
        fillPaint(
          foreground ?? Color.lerp(c.nightLine, c.onCaption, position)!,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(_SwitchPainter o) =>
      o.position != position ||
      o.c != c ||
      o.fill != fill ||
      o.foreground != foreground ||
      o.side != side ||
      o.shape != shape ||
      o.rtl != rtl;
}

/// An animated lever on an outlined track, lit by the caption ink while on.
///
/// ```dart
/// ComicSwitch(value: on, onChanged: (v) => setState(() => on = v))
/// ```
class ComicSwitch extends StatelessWidget {
  /// Creates a [ComicSwitch].
  const ComicSwitch({
    super.key,
    this.style,
    required this.value,
    this.onChanged,
    this.label,
    this.focusNode,
    this.autofocus = false,
  });

  /// Per-state track and lever appearance.
  final ComicStyle? style;

  /// The current value represented by the control or record.
  final bool value;

  /// Reports a new value; null disables changes.
  final ValueChanged<bool>? onChanged;

  /// The visible or spoken name of the component.
  final String? label;

  /// The caller's focus node, if any; the part makes its own when null.
  final FocusNode? focusNode;

  /// Whether the part asks for the focus when it first appears.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context), c = t.colors;
    final base = ComicStyleOf([style, t.switchTheme], const {});
    final target = ComicTapTarget.targetOf(context);
    return comicOwnSize(
      width: 48,
      height: target,
      child: ComicPressable(
        focusNode: focusNode,
        autofocus: autofocus,
        onPressed: onChanged == null ? null : () => onChanged!(!value),
        label: label,
        toggled: value,
        // The marks are the track's own: drawn below, on the track, not on its taller target.
        wash: false,
        ring: false,
        builder: (context, states) {
          final look = ComicStyleOf([style, t.switchTheme], states);
          return AnimatedComicShape(
            shape: look.shape ?? t.shapes.capsule,
            builder: (context, shape) => Center(
              child: comicOwnSize(
                width: 48,
                height: 26,
                child: ComicHighlight(
                  states: states,
                  shape: shape ?? t.shapes.capsule,
                  wash: onChanged != null,
                  overlay: onChanged == null
                      ? null
                      : base.overlay?.resolve(states),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: value ? 1 : 0),
                    duration: ComicMotion.of(context).state,
                    curve: ComicMotion.of(context).standard,
                    builder: (context, position, _) => CustomPaint(
                      painter: _SwitchPainter(
                        position,
                        c,
                        fill: look.fill,
                        foreground: look.foreground,
                        side: comicRim(t, look, c.nightLine),
                        shape: shape,
                        rtl: Directionality.of(context) == TextDirection.rtl,
                      ),
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
}

double _wholeWidth(String text, TextStyle style, TextScaler textScaler) {
  final tp = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    maxLines: 1,
    textScaler: textScaler,
  )..layout();
  final width = tp.width;
  tp.dispose();
  return width;
}

class _Action extends StatelessWidget {
  const _Action({
    required this.label,
    this.onPressed,
    this.icon,
    this.style,
    this.leading,
    required this.busy,
    this.showBusy,
    this.wide = false,
    this.focusNode,
    this.autofocus = false,
    required this.size,
    this.danger = false,
    bool? boxed,
  }) : boxed = boxed ?? danger;
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  /// Per-state face style above the component theme.
  final ComicStyle? style;

  final Widget? leading;
  final bool busy, danger, wide;

  // Boxed at a field's height in a rim, as the outlined button (the destructive outlined button); else quiet words.
  final bool boxed;
  final bool? showBusy;
  final FocusNode? focusNode;

  /// Whether the button asks for the focus when it first appears.
  final bool autofocus;
  final ComicButtonSize size;
  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    final layers = [style, boxed ? t.filledButtonTheme : t.textButtonTheme];
    final base = ComicStyleOf(layers, const {});
    final drawn = ComicPressable(
      onPressed: onPressed,
      label: label,
      busy: busy,
      focusNode: focusNode,
      autofocus: autofocus,
      // The danger button is boxed at a field's height, as the act and line buttons: it takes the width its row or
      // column gives it, as they do (a sheet's stacked actions, full width). Only the quiet words stand centred in a
      // least target of their own.
      target: !boxed,
      outline: base.shapes(t.shapes.small),
      overlay: base.overlay,
      builder: (context, states) {
        final look = ComicStyleOf(layers, states);
        final ink =
            look.foreground ??
            (danger ? t.colors.tones.danger : t.colors.shadeText);
        final rim = comicRim(t, look, ink);
        final letters =
            (size == ComicButtonSize.small ? t.type.buttonSmall : t.type.button)
                .merge(look.textStyle)
                .copyWith(color: ink);
        return AnimatedComicShape(
          shape: look.shape ?? t.shapes.small,
          builder: (context, shape) => ComicStateDecoration(
            decoration: ShapeDecoration(
              color:
                  look.fill ??
                  (boxed ? t.colors.card : const Color(0x00000000)),
              shape: (shape ?? const RoundedRectangleBorder()).copyWith(
                side: boxed ? rim : look.side ?? BorderSide.none,
              ),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: look.minimumSize?.width ?? 0,
                minHeight:
                    look.minimumSize?.height ??
                    // A field's height at every density, as the act and line buttons.
                    (size == ComicButtonSize.large
                        ? math.max(
                            ComicTrack.fieldHeight(context),
                            t.density.height(56),
                          )
                        : ComicTrack.fieldHeight(context)),
              ),
              child: Padding(
                padding:
                    (look.padding(Directionality.of(context)) ??
                            t.density.padding(
                              const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ))
                        .add(shape?.dimensions ?? EdgeInsets.zero),
                child: Center(
                  widthFactor: 1,
                  heightFactor: 1,
                  child: ComicFitRow(
                    fill:
                        (leading == null && icon == null && !(showBusy ?? busy))
                        ? 0
                        : 1,
                    gap: 8,
                    shrink: true,
                    children: [
                      if (showBusy ?? busy)
                        ComicCircularProgressIndicator(
                          size: look.iconSize ?? 20,
                          color: ink,
                        )
                      else if (leading != null)
                        ExcludeSemantics(child: leading!)
                      else if (icon != null)
                        Icon(icon, color: ink, size: look.iconSize ?? 20),
                      CapLabel(
                        child: Text(
                          label.toUpperCase(),
                          textAlign: TextAlign.center,
                          textScaler: comicLetteringScaler(context, letters),
                          style: letters,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
    // Quiet words with no surface at rest start on their column's edge: the room before them stands outward, the wash
    // round them still. Held at a set width (a phone's stacked actions) they stay centred in it.
    final dir = Directionality.of(context);
    final restShape = base.shape ?? t.shapes.small;
    final rest =
        !boxed &&
        (base.fill == null || base.fill!.a == 0) &&
        (base.side == null || base.side!.style == BorderStyle.none);
    final pad = rest
        ? (base.padding(dir) ??
                  t.density.padding(
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ))
              .add(restShape.dimensions)
              .resolve(dir)
        : EdgeInsets.zero;
    final rtl = dir == TextDirection.rtl;
    final lead = rtl ? pad.right : pad.left;
    final room = rtl
        ? EdgeInsets.only(right: lead)
        : EdgeInsets.only(left: lead);
    final placed = lead == 0
        ? drawn
        : ComicOutward(margin: room, inwardWhenHeld: true, child: drawn);
    return ComicButtonRoom(
      child: wide ? SizedBox(width: double.infinity, child: placed) : placed,
    );
  }
}

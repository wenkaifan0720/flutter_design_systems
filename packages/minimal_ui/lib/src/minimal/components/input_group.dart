/// A field and its add-ons as one control, a password field with its
/// show/hide toggle, and a one-time code in boxes, painted on ui_core's
/// input group, password reveal and code field.
library;

import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../chrome_metrics.dart';
import '../component_themes.dart';
import '../internal/cap_label.dart';
import '../internal/controls.dart';
import '../internal/field.dart';
import '../internal/give_way_row.dart';
import '../internal/kit_paint.dart';
import '../internal/styled.dart';
import '../internal/text_entry.dart';
import '../localizations.dart';
import '../shapes.dart';
import '../theme.dart';
import 'button.dart';
import 'icon_button.dart';
import 'input.dart';
import 'pressable.dart';

/// A field with add-ons inside one box: a fixed text before or after the
/// value (`https://`, `.com`, `kg`), a glyph, a button. The box is a
/// [MinimalTextField]'s, and so are its states: its rule turns to the focus
/// colour while anything in it has focus, the ring shows for the keyboard
/// only, the danger rule when [error] says. A text add-on stands on the
/// quiet fill behind a hairline, as one part of the box. A tap on the box
/// or a plain add-on puts the caret in the field.
///
/// The behaviour is ui_core's ([DesignInputGroup]); Minimal paints it.
/// [style] dresses the box over `components.textField`, as a text field's
/// `fieldStyle` does.
///
/// ```dart
/// MinimalInputGroup(label: 'Website', prefixText: 'https://', suffixText: '.com', controller: site)
/// ```
class MinimalInputGroup extends StatefulWidget {
  /// A group around one field.
  const MinimalInputGroup({
    super.key,
    this.label,
    this.hint,
    this.helper,
    this.error,
    this.controller,
    this.focusNode,
    this.prefixText,
    this.suffixText,
    this.leading,
    this.trailing,
    this.mono = false,
    this.enabled = true,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.style,
    this.autofocus = false,
  });

  /// The field's name, over the box.
  final String? label;

  /// What the empty field shows.
  final String? hint;

  /// A quiet line under the box; the [error] replaces it.
  final String? helper;

  /// The message under the box; also turns its rule to the destructive ink.
  final String? error;

  /// The field's text.
  final TextEditingController? controller;

  /// The field's focus.
  final FocusNode? focusNode;

  /// A fixed text at the box's start, before the value.
  final String? prefixText;

  /// A fixed text at the box's end, after the value.
  final String? suffixText;

  /// A widget at the start, after [prefixText]: a 16 px glyph.
  final Widget? leading;

  /// A widget at the end, before [suffixText]: a small ghost button.
  final Widget? trailing;

  /// Set the value in Geist Mono with tabular figures.
  final bool mono;

  /// Whether it takes input.
  final bool enabled;

  /// The keyboard the platform shows.
  final TextInputType? keyboardType;

  /// The keyboard's action key.
  final TextInputAction? textInputAction;

  /// What the field lets through as it is typed.
  final List<TextInputFormatter>? inputFormatters;

  /// Called with the text as it changes.
  final ValueChanged<String>? onChanged;

  /// Called when the keyboard's action submits the text.
  final ValueChanged<String>? onSubmitted;

  /// The box's style, over `components.textField`.
  final MinimalStyle? style;

  /// Whether it takes keyboard focus when it first appears.
  final bool autofocus;

  @override
  State<MinimalInputGroup> createState() => _MinimalInputGroupState();
}

class _MinimalInputGroupState extends State<MinimalInputGroup>
    with MinimalFieldOwner<MinimalInputGroup> {
  @override
  TextEditingController? get externalController => widget.controller;

  @override
  FocusNode? get externalFocusNode => widget.focusNode;

  @override
  void didUpdateWidget(MinimalInputGroup old) {
    super.didUpdateWidget(old);
    syncField(oldController: old.controller, oldFocusNode: old.focusNode);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final label = widget.label;
    final error = widget.error;
    final message = error ?? widget.helper;
    final valueStyle = widget.mono ? t.monoValue : t.body;
    final ink = widget.enabled ? t.foreground : t.mutedForeground;

    Widget field = TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: widget.autofocus,
      enabled: widget.enabled,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      inputFormatters: widget.inputFormatters,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      cursorColor: t.primary,
      cursorWidth: MinimalFieldMetrics.cursor,
      style: valueStyle.c(ink),
      decoration: minimalBareDecoration(
        hint: widget.hint,
        hintStyle: valueStyle.c(t.textTertiary),
      ),
    );
    // The line by its capitals: caret, hint and taps move with it.
    field = minimalCapLabel(field);
    if (label != null) field = Semantics(label: label, child: field);
    if (Material.maybeOf(context) == null) {
      field = Material(type: MaterialType.transparency, child: field);
    }

    Widget addOn(String text, {required bool start}) {
      final side = BorderSide(color: t.border, width: t.hairline);
      return Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(
          horizontal: MinimalFieldMetrics.inset,
        ),
        // The muted words behind a hairline say it is fixed; no grey well.
        decoration: BoxDecoration(
          border: BorderDirectional(
            end: start ? side : BorderSide.none,
            start: start ? BorderSide.none : side,
          ),
        ),
        // On the typed text's capitals, as the field beside it is.
        child: minimalCapLabel(
          Text(
            text,
            style: valueStyle.c(t.mutedForeground),
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }

    final prefix = widget.prefixText;
    final suffix = widget.suffixText;
    final lead = widget.leading;
    final end = widget.trailing;
    // The field takes the room its add-ons leave; in a narrow column (or
    // at large text) the add-ons' words give way before the field drops
    // under a touch target's width, so the group never overflows.
    final cells = <Widget>[];
    final fixed = <int>{};
    void hold(Widget cell) {
      fixed.add(cells.length);
      cells.add(cell);
    }

    if (prefix != null) {
      cells.add(ExcludeSemantics(child: addOn(prefix, start: true)));
    }
    hold(const MinimalGap(MinimalFieldMetrics.inset));
    if (lead != null) {
      hold(Center(child: lead));
      hold(const MinimalGap(MinimalSpacing.s8));
    }
    final grow = cells.length;
    cells.add(Center(child: MinimalFieldTarget(child: field)));
    if (end != null) {
      hold(const MinimalGap(MinimalSpacing.s4));
      hold(Center(child: end));
      hold(const MinimalGap(MinimalSpacing.s2));
    } else {
      hold(const MinimalGap(MinimalFieldMetrics.inset));
    }
    if (suffix != null) {
      cells.add(ExcludeSemantics(child: addOn(suffix, start: false)));
    }
    final row = IntrinsicHeight(
      child: MinimalGiveWayRow(
        stretch: true,
        fixed: fixed,
        grow: grow,
        growMin: MinimalLayout.minHitTarget,
        children: cells,
      ),
    );

    final group = DesignInputGroup(
      focusNode: focusNode,
      enabled: widget.enabled,
      isError: error != null || MinimalFieldErrorScope.of(context),
      child: row,
      builder: (context, states, child) {
        final so = MinimalStyleOf([
          widget.style,
          t.components.textField,
        ], states);
        final shape = so.shape ?? t.shapes.small;
        final within = states.contains(WidgetState.focused);
        final keyboard =
            within &&
            FocusManager.instance.highlightMode ==
                FocusHighlightMode.traditional;
        return Container(
          constraints: BoxConstraints(
            minHeight:
                so.minimumSize?.height ??
                minimalGrownHeight(
                  context,
                  t.density.height(MinimalChromeMetrics.control),
                ),
          ),
          decoration: minimalFrame(
            shape,
            fill: so.fill ?? (states.off ? t.sunken : t.card),
            side: so.rim(
              states.wrong
                  ? t.destructive
                  : within
                  ? t.ring
                  : t.border,
              t.rim,
            ),
          ),
          foregroundDecoration: minimalFieldRing(
            t,
            shown: keyboard,
            error: states.wrong,
            shape: shape,
          ),
          child: minimalClip(
            MinimalShapes.inset(shape, t.rim),
            child: Padding(padding: EdgeInsets.all(t.rim), child: child),
          ),
        );
      },
    );

    return _framed(
      t,
      label: label,
      message: message,
      error: error != null,
      enabled: widget.enabled,
      child: MinimalHitTarget(child: group),
    );
  }
}

/// A field's label over it and its message under it, as a
/// [MinimalTextField] sets them; dimmed whole when disabled.
Widget _framed(
  MinimalThemeData t, {
  required String? label,
  required String? message,
  required bool error,
  required bool enabled,
  required Widget child,
}) {
  final column = Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (label != null) ...[
        ExcludeSemantics(
          child: Text(label, style: t.caption.medium.c(t.foreground)),
        ),
        const MinimalGap(MinimalChromeMetrics.iconGap),
      ],
      child,
      if (message != null) ...[
        const MinimalGap(MinimalChromeMetrics.iconGap),
        Semantics(
          liveRegion: error,
          child: Text(
            message,
            style: t.caption.c(error ? t.destructiveInk : t.mutedForeground),
          ),
        ),
      ],
    ],
  );
  return enabled ? column : Opacity(opacity: 0.45, child: column);
}

/// A password field: a [MinimalTextField] that hides what is typed, and at
/// its end an eye that shows it (and hides it again), announced as Show
/// password or Hide password. The field keeps its focus and caret as it
/// flips; the keyboard never learns a shown password. With [hideOnBlur] a
/// shown password hides again when focus leaves the field.
///
/// The behaviour is ui_core's ([DesignPasswordReveal]); Minimal paints it.
/// [fieldStyle] dresses the box over `components.textField`.
///
/// ```dart
/// MinimalPasswordField(label: 'Password', controller: password, onSubmitted: (_) => signIn())
/// ```
class MinimalPasswordField extends StatefulWidget {
  /// A password field.
  const MinimalPasswordField({
    super.key,
    this.label,
    this.hint,
    this.helper,
    this.error,
    this.controller,
    this.focusNode,
    this.enabled = true,
    this.autofocus = false,
    this.hideOnBlur = false,
    this.newPassword = false,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.fieldStyle,
  });

  /// The field's name, over the box.
  final String? label;

  /// What the empty field shows.
  final String? hint;

  /// A quiet line under the box (the rules a new password keeps); the
  /// [error] replaces it.
  final String? helper;

  /// The message under the box.
  final String? error;

  /// The password.
  final TextEditingController? controller;

  /// The field's focus.
  final FocusNode? focusNode;

  /// Whether it takes input.
  final bool enabled;

  /// Whether it takes focus when it first appears.
  final bool autofocus;

  /// Whether a shown password hides when focus leaves the field.
  final bool hideOnBlur;

  /// A password being made (sign-up, a change): the platform offers a strong
  /// one rather than the saved one.
  final bool newPassword;

  /// The keyboard's action key.
  final TextInputAction? textInputAction;

  /// Called with the text as it changes.
  final ValueChanged<String>? onChanged;

  /// Called when the keyboard's action submits it.
  final ValueChanged<String>? onSubmitted;

  /// The box's style, over `components.textField`.
  final MinimalStyle? fieldStyle;

  @override
  State<MinimalPasswordField> createState() => _MinimalPasswordFieldState();
}

class _MinimalPasswordFieldState extends State<MinimalPasswordField> {
  FocusNode? _owned;

  FocusNode get _focus => widget.focusNode ?? (_owned ??= FocusNode());

  @override
  void dispose() {
    _owned?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final words = MinimalLocalizations.of(context);
    return DesignPasswordReveal(
      focusNode: _focus,
      hideOnBlur: widget.hideOnBlur,
      showLabel: words.showPassword,
      hideLabel: words.hidePassword,
      builder: (context, password) => MinimalTextField(
        label: widget.label,
        hint: widget.hint,
        helper: widget.helper,
        error: widget.error,
        controller: widget.controller,
        focusNode: _focus,
        enabled: widget.enabled,
        autofocus: widget.autofocus,
        obscureText: password.obscured,
        enableSuggestions: false,
        autocorrect: false,
        keyboardType: TextInputType.visiblePassword,
        textInputAction: widget.textInputAction,
        autofillHints: [
          widget.newPassword
              ? AutofillHints.newPassword
              : AutofillHints.password,
        ],
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        fieldStyle: widget.fieldStyle,
        trailing: MinimalIconButton(
          password.obscured ? LucideIcons.eye : LucideIcons.eyeOff,
          label: password.toggleLabel,
          size: MinimalButtonSize.small,
          onPressed: widget.enabled ? password.toggle : null,
        ),
      ),
    );
  }
}

/// A one-time code (a sign-in code, a PIN) as a row of boxes over one
/// input: paste, the platform's SMS autofill and Backspace work as in any
/// field. The boxes join edge to edge in groups of [groupSize] (three and
/// three for six), a short dash between groups: a group is one outline,
/// its boxes split by single hairlines. A box prints its figure in Geist Mono; the box the next
/// figure goes in wears the focus colour, with a caret while it is empty.
/// [error] turns every rim to the destructive ink and prints its message under
/// the boxes. A long press or a secondary click offers Paste, in Minimal's
/// menu, while the clipboard holds text.
///
/// The behaviour is ui_core's ([DesignOtpField]); Minimal paints it. The
/// boxes read `components.textField` (fill, edge or side, shape).
///
/// ```dart
/// MinimalInputOtp(length: 6, label: 'Code from your email', onCompleted: verify)
/// ```
class MinimalInputOtp extends StatelessWidget {
  /// A code of [length] boxes.
  const MinimalInputOtp({
    super.key,
    this.length = 6,
    this.groupSize,
    this.label,
    this.error,
    this.focusNode,
    this.onChanged,
    this.onCompleted,
    this.onSubmitted,
    this.inputFormatters = const [],
    this.autofillHints = const [AutofillHints.oneTimeCode],
    this.enabled = true,
    this.autofocus = false,
    this.obscureText = false,
    this.keyboardType = TextInputType.number,
    this.style,
  });

  /// How many boxes.
  final int length;

  /// How many boxes a group joins; null: halves for an even [length] of 6 or
  /// 8, one group otherwise.
  final int? groupSize;

  /// The code's name, over the boxes; also what a screen reader calls it.
  final String? label;

  /// The message under the boxes; also turns their rims to the destructive ink.
  final String? error;

  /// The input's focus.
  final FocusNode? focusNode;

  /// Called with the code as it changes.
  final ValueChanged<String>? onChanged;

  /// Called once each time the code becomes whole.
  final ValueChanged<String>? onCompleted;

  /// Called with the code when the keyboard's action key is pressed.
  final ValueChanged<String>? onSubmitted;

  /// The caller's formatters (upper-casing letters, say), run before the
  /// code's own filter and length, which have the last word.
  final List<TextInputFormatter> inputFormatters;

  /// What autofill may offer; a one-time code by default.
  final Iterable<String> autofillHints;

  /// Whether it takes input.
  final bool enabled;

  /// Whether it takes focus when it first appears.
  final bool autofocus;

  /// Whether the figures are hidden (a PIN).
  final bool obscureText;

  /// The keyboard the platform shows.
  final TextInputType keyboardType;

  /// The boxes' style, over `components.textField`.
  final MinimalStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final words = MinimalLocalizations.of(context);
    final group =
        groupSize ?? (length == 6 || length == 8 ? length ~/ 2 : length);
    const box = Size(36, 40);
    // Each group is one frame in the field's state; a box draws only the
    // hairline it shares with the box before it (one line, never two), and
    // the box the next figure goes in rings itself over the frame.
    final frame = MinimalStyleOf([
      style,
      t.components.textField,
    ], minimalStates(enabled: enabled, error: error != null));
    final whole = frame.shape ?? t.shapes.small;
    final edge = frame.rim(error != null ? t.destructive : t.border, t.rim);

    Widget slot(DesignOtpSlot s) {
      final so = MinimalStyleOf(
        [style, t.components.textField],
        minimalStates(
          enabled: s.enabled,
          focused: s.active && s.focused,
          error: s.isError,
        ),
      );
      final at = s.index % group;
      final cell = minimalCell(
        whole,
        index: at,
        count: s.index ~/ group == (length - 1) ~/ group
            ? length - (length - 1) ~/ group * group
            : group,
      );
      final active = s.active && s.focused;
      return Container(
        width: so.minimumSize?.width ?? box.width,
        height: so.minimumSize?.height ?? box.height,
        alignment: Alignment.center,
        decoration: at == 0
            ? null
            : BoxDecoration(border: BorderDirectional(start: edge)),
        foregroundDecoration: active
            ? minimalFrame(
                cell,
                side: so.rim(s.isError ? t.destructive : t.ring, t.focusWidth),
              )
            : null,
        // A figure by its capitals, on the cell's middle (a bullet, which has
        // none, by its line).
        child: s.filled
            ? s.obscured
                  ? Text(
                      '•',
                      style: t.monoValue.copyWith(fontSize: 16).c(t.foreground),
                    )
                  : minimalCapLabel(
                      Text(
                        s.character,
                        style: t.monoValue
                            .copyWith(fontSize: 16)
                            .c(t.foreground),
                      ),
                    )
            : active
            ? Container(
                width: MinimalFieldMetrics.cursor,
                height: 16,
                color: t.primary,
              )
            : null,
      );
    }

    final field = DesignOtpField(
      length: length,
      focusNode: focusNode,
      onChanged: onChanged,
      onCompleted: onCompleted,
      onSubmitted: onSubmitted,
      inputFormatters: inputFormatters,
      autofillHints: autofillHints,
      enabled: enabled,
      autofocus: autofocus,
      isError: error != null,
      obscureText: obscureText,
      keyboardType: keyboardType,
      semanticLabel: label ?? words.oneTimeCode,
      contextMenuBuilder: (context, anchors, items) =>
          _CodeMenu(anchors: anchors, items: items),
      slotBuilder: (context, s) => slot(s),
      layoutBuilder: (context, slots) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var g = 0; g < slots.length; g += group) ...[
            if (g > 0)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: MinimalSpacing.s8,
                ),
                child: Container(width: 8, height: 1.5, color: t.textTertiary),
              ),
            // A DecoratedBox, not a Container: the boxes lie on the frame's
            // rim, so a ringed box covers it rather than sitting inside it.
            DecoratedBox(
              decoration: minimalFrame(
                whole,
                fill: frame.fill ?? (enabled ? t.card : t.sunken),
                side: edge,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: slots.sublist(g, math.min(g + group, slots.length)),
              ),
            ),
          ],
        ],
      ),
    );
    return _framed(
      t,
      label: label,
      message: error,
      error: error != null,
      enabled: enabled,
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: MinimalHitTarget(child: field),
      ),
    );
  }
}

/// The code field's menu at the press: Minimal's card of 32 px items, kept
/// on screen. Paste is the one item ui_core offers; its word is the
/// framework's, in the app's language.
class _CodeMenu extends StatelessWidget {
  const _CodeMenu({required this.anchors, required this.items});

  final TextSelectionToolbarAnchors anchors;
  final List<ContextMenuButtonItem> items;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final paste = WidgetsLocalizations.of(context).pasteButtonLabel;
    final margin =
        MediaQuery.paddingOf(context) + const EdgeInsets.all(MinimalSpacing.s8);
    return Padding(
      padding: margin,
      child: CustomSingleChildLayout(
        delegate: DesktopTextSelectionToolbarLayoutDelegate(
          anchor: anchors.primaryAnchor - Offset(margin.left, margin.top),
        ),
        child: MinimalKitPanel(
          padding: const EdgeInsets.all(MinimalSpacing.s4),
          width: 160,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final item in items)
                MinimalPressable(
                  onPressed: item.onPressed,
                  shape: minimalKitRowShape(t),
                  child: MinimalKitRow(
                    states: const {},
                    label: item.label ?? paste,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

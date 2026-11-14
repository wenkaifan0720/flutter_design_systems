import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../icons.dart';
import '../../internal/hit_slop.dart';
import '../../internal/measure.dart';
import '../../localizations.dart';
import '../../theme.dart';
import '../button/button.dart';
import '../field/field.dart';
import '../pressable/pressable.dart';
import 'field_core.dart';

import 'package:ui_core/ui_core.dart';

/// An input's or a textarea's editor: the shared [Fluent2FieldEditor] in
/// the field's type and inks.
class _Editor extends StatelessWidget {
  const _Editor({
    required this.controller,
    required this.focusNode,
    required this.style,
    required this.enabled,
    this.label,
    this.placeholder,
    this.onChanged,
    this.onSubmitted,
    this.readOnly = false,
    this.obscureText = false,
    this.multiline = false,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.autofocus = false,
    this.appearance = Fluent2InputAppearance.outline,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final TextStyle style;
  final bool enabled;
  final String? label;
  final String? placeholder;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool readOnly;
  final bool obscureText;
  final bool multiline;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final bool autofocus;
  final Fluent2InputAppearance appearance;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final ink = enabled
        ? t.colors.neutralForeground1
        : t.colors.neutralForegroundDisabled;
    final hint = enabled
        ? fluent2PlaceholderInk(t, appearance)
        : t.colors.neutralForegroundDisabled;
    return Semantics(
      label: label,
      child: Fluent2FieldEditor(
        controller: controller,
        focusNode: focusNode,
        enabled: enabled,
        readOnly: readOnly,
        obscureText: obscureText,
        autofocus: autofocus,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        keyboardType:
            keyboardType ?? (multiline ? TextInputType.multiline : null),
        textInputAction: textInputAction,
        inputFormatters: inputFormatters,
        maxLines: multiline ? null : 1,
        style: style.c(ink),
        hint: placeholder,
        hintStyle: style.c(hint),
      ),
    );
  }
}

/// Fluent 2's Input: one line of text in a field 32 tall (24 small, 40
/// large) on the [appearance]'s face, the brand underline growing from
/// its middle while it holds focus; a [prefixIcon] glyph and a
/// [suffixIcon] glyph in the third ink, a [trailing] control at its
/// end; [password] hides the words and puts the reveal button at the end.
/// The page owns the text through [value] and [onChanged], or a
/// [controller]; with neither it is disabled. Inside a `Fluent2FormField` it
/// takes the field's label as its spoken name and its error stroke.
/// [obscureText] and [validationMessage] are the names a generated app writes: [obscureText]
/// is [password], and [validationMessage] is a
/// validation line under the field (as a `Fluent2FormField`'s) with the error
/// stroke.
///
/// ```dart
/// Fluent2TextField(label: 'Project name', hint: 'Northwind launch', value: name, onChanged: (v) => setState(() => name = v))
/// ```
class Fluent2TextField extends StatefulWidget {
  /// A text field, Fluent's Input.
  const Fluent2TextField({
    this.label,
    this.value,
    this.onChanged,
    this.onSubmitted,
    this.controller,
    this.focusNode,
    this.hint,
    this.appearance = Fluent2InputAppearance.outline,
    this.size = Fluent2InputSize.medium,
    this.prefixIcon,
    this.suffixIcon,
    this.trailing,
    this.password = false,
    this.invalid = false,
    this.readOnly = false,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.autofocus = false,
    this.obscureText = false,
    this.validationMessage,
    super.key,
  });

  /// The spoken name; null takes the enclosing field's label.
  final String? label;

  /// The text, when the page owns it.
  final String? value;

  /// Called with the new value when the user changes it; null puts it out of
  /// use.
  final ValueChanged<String>? onChanged;

  /// Called with the words when the user submits them (the keyboard's done or
  /// Enter).
  final ValueChanged<String>? onSubmitted;

  /// The controller that holds the words; null makes its own.
  final TextEditingController? controller;

  /// The focus node it takes focus with; null makes its own.
  final FocusNode? focusNode;

  /// What the empty field says, in the fourth ink.
  final String? hint;

  /// Fluent's `appearance`: which of its faces it wears.
  final Fluent2InputAppearance appearance;

  /// Fluent's `size`: how large it is drawn.
  final Fluent2InputSize size;

  /// A glyph before the words (a search, a mail, a person).
  final IconData? prefixIcon;

  /// A glyph after the words (a unit's mark, a lock).
  final IconData? suffixIcon;

  /// A control at the field's end (a transparent small button).
  final Widget? trailing;

  /// Hide the words, with the reveal button at the end.
  final bool password;

  /// Draw the error stroke (`paletteRedBorder2`) while not focused.
  final bool invalid;

  /// Whether its value can be read and selected but not changed.
  final bool readOnly;

  /// The keyboard the platform shows for it; null is the text keyboard.
  final TextInputType? keyboardType;

  /// The keyboard's action button; null is the platform's choice.
  final TextInputAction? textInputAction;

  /// Formatters that check and shape the words as they are typed.
  final List<TextInputFormatter>? inputFormatters;

  /// Whether it takes focus when it first appears.
  final bool autofocus;

  /// [password] by the generated app's name for it; with a [trailing]
  /// control of the caller's (its own reveal), no second button is added.
  final bool obscureText;

  /// A validation message under the field, which also draws the error
  /// stroke; inside a `Fluent2FormField` the field's own message stands instead.
  final String? validationMessage;

  @override
  State<Fluent2TextField> createState() => _Fluent2TextFieldState();
}

class _Fluent2TextFieldState extends State<Fluent2TextField>
    with Fluent2FieldOwner<Fluent2TextField> {
  bool _revealed = false;

  @override
  TextEditingController? controllerOf(Fluent2TextField w) => w.controller;

  @override
  String? valueOf(Fluent2TextField w) => w.value;

  @override
  FocusNode? focusNodeOf(Fluent2TextField w) => w.focusNode;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final scope = Fluent2FieldScope.maybeOf(context);
    final enabled = widget.onChanged != null || widget.controller != null;
    final m = Fluent2FieldMetrics.of(widget.size);
    final slot = enabled
        ? t.colors.neutralForeground3
        : t.colors.neutralForegroundDisabled;
    final before = widget.prefixIcon;
    // A hidden field brings its reveal button, unless the caller puts its
    // own control at the end (Fluent2PasswordField's reveal): two would
    // stand side by side.
    final hidden = widget.password || widget.obscureText;
    final password =
        widget.password || (widget.obscureText && widget.trailing == null);
    final after = <Widget>[
      if (widget.suffixIcon case final glyph?)
        Icon(glyph, size: m.glyph, color: slot),
      ?widget.trailing,
      if (password)
        Fluent2IconButton(
          _revealed ? Fluent2Icons.eyeOff : Fluent2Icons.eye,
          label: _revealed
              ? DesignLocalizations.of(context).hidePasswordLabel
              : DesignLocalizations.of(context).showPasswordLabel,
          appearance: Fluent2ButtonAppearance.transparent,
          size: widget.size == Fluent2InputSize.large
              ? Fluent2ButtonSize.medium
              : Fluent2ButtonSize.small,
          onPressed: enabled
              ? () => setState(() => _revealed = !_revealed)
              : null,
        ),
    ];
    final validationMessage = scope == null ? widget.validationMessage : null;
    final input = Fluent2HitSlop(
      child: Fluent2FieldFrame(
        appearance: widget.appearance,
        focused: fieldFocus.hasFocus,
        enabled: enabled,
        invalid:
            widget.invalid ||
            validationMessage != null ||
            (scope?.invalid ?? false),
        textNode: true,
        minHeight: m.height,
        padding: EdgeInsetsDirectional.only(
          start: before != null ? m.root : 0,
          end: after.isNotEmpty ? m.root : 0,
        ),
        child: Row(
          spacing: m.gap,
          children: [
            if (before != null) Icon(before, size: m.glyph, color: slot),
            Expanded(
              child: Padding(
                padding: EdgeInsetsDirectional.only(
                  start: before != null ? m.inner : m.combined,
                  end: after.isNotEmpty ? m.inner : m.combined,
                ),
                child: _Editor(
                  appearance: widget.appearance,
                  controller: fieldController,
                  focusNode: fieldFocus,
                  style: Fluent2FieldMetrics.typeOf(t, widget.size),
                  enabled: enabled,
                  label: widget.label ?? scope?.label,
                  placeholder: widget.hint,
                  onChanged: widget.onChanged,
                  onSubmitted: widget.onSubmitted,
                  readOnly: widget.readOnly,
                  obscureText: hidden && !(password && _revealed),
                  keyboardType: hidden
                      ? TextInputType.visiblePassword
                      : widget.keyboardType,
                  textInputAction: widget.textInputAction,
                  inputFormatters: widget.inputFormatters,
                  autofocus: widget.autofocus,
                ),
              ),
            ),
            ...after,
          ],
        ),
      ),
    );
    if (validationMessage == null) return input;
    return Fluent2FormField(validationMessage: validationMessage, child: input);
  }
}

/// Fluent 2's Textarea: several lines in a field at least 52 tall (40
/// small, 64 large), 6 over the words and 12 at the sides, growing with
/// its text up to 260 (200, 320) and scrolling past it, on the outline or
/// a filled face with the brand underline on focus (Fluent's Textarea has
/// no underline face). The page owns the text through [value] and
/// [onChanged], or a [controller]; with neither it is disabled.
///
/// ```dart
/// Fluent2TextArea(label: 'Notes', hint: 'What should the team know?', value: notes, onChanged: (v) => setState(() => notes = v))
/// ```
class Fluent2TextArea extends StatefulWidget {
  /// A text area for several lines, Fluent's Textarea.
  const Fluent2TextArea({
    this.label,
    this.value,
    this.onChanged,
    this.controller,
    this.focusNode,
    this.autofocus = false,
    this.hint,
    this.appearance = Fluent2InputAppearance.outline,
    this.size = Fluent2InputSize.medium,
    this.invalid = false,
    this.readOnly = false,
    super.key,
  }) : assert(
         appearance != Fluent2InputAppearance.underline,
         "Fluent's Textarea has no underline face",
       );

  /// What a screen reader calls the field; null reads the surrounding form
  /// field's label.
  final String? label;

  /// The words it starts with; null starts empty.
  final String? value;

  /// Called with the new value when the user changes it; null puts it out of
  /// use.
  final ValueChanged<String>? onChanged;

  /// The controller that holds the words; null makes its own.
  final TextEditingController? controller;

  /// The focus node it takes focus with; null makes its own.
  final FocusNode? focusNode;

  /// Whether it takes focus when it first builds.
  final bool autofocus;

  /// The words shown while it is empty.
  final String? hint;

  /// Fluent's `appearance`: which of its faces it wears.
  final Fluent2InputAppearance appearance;

  /// Fluent's `size`: how large it is drawn.
  final Fluent2InputSize size;

  /// Whether it shows Fluent's invalid state, its edge in the danger colour.
  final bool invalid;

  /// Whether its value can be read and selected but not changed.
  final bool readOnly;

  @override
  State<Fluent2TextArea> createState() => _Fluent2TextareaState();
}

class _Fluent2TextareaState extends State<Fluent2TextArea>
    with Fluent2FieldOwner<Fluent2TextArea> {
  @override
  TextEditingController? controllerOf(Fluent2TextArea w) => w.controller;

  @override
  String? valueOf(Fluent2TextArea w) => w.value;

  @override
  FocusNode? focusNodeOf(Fluent2TextArea w) => w.focusNode;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final scope = Fluent2FieldScope.maybeOf(context);
    final enabled = widget.onChanged != null || widget.controller != null;
    // Fluent's Textarea: small min 40 / max 200, 4 by 8; medium 52 / 260,
    // 6 by 12; large 64 / 320, 8 by 14; the root 2 under (the focus
    // underline's room).
    final (min, max, v, h) = switch (widget.size) {
      Fluent2InputSize.small => (40.0, 200.0, 4.0, 8.0),
      Fluent2InputSize.medium => (52.0, 260.0, 6.0, 12.0),
      Fluent2InputSize.large => (64.0, 320.0, 8.0, 14.0),
    };
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: max + 2 + Fluent2Stroke.thick),
      child: Fluent2FieldFrame(
        appearance: widget.appearance,
        focused: fieldFocus.hasFocus,
        enabled: enabled,
        invalid: widget.invalid || (scope?.invalid ?? false),
        textNode: true,
        minHeight: min + 2 + Fluent2Stroke.thick,
        padding: EdgeInsets.fromLTRB(h, v, h, v + Fluent2Stroke.thick),
        child: _Editor(
          appearance: widget.appearance,
          controller: fieldController,
          focusNode: fieldFocus,
          autofocus: widget.autofocus,
          style: Fluent2FieldMetrics.typeOf(t, widget.size),
          enabled: enabled,
          label: widget.label ?? scope?.label,
          placeholder: widget.hint,
          onChanged: widget.onChanged,
          readOnly: widget.readOnly,
          multiline: true,
        ),
      ),
    );
  }
}

/// Fluent 2's SearchBox: an Input with the search glyph before the words
/// and, once it holds a query, the dismiss glyph that clears it (calling
/// [onChanged] with the empty text and [onClear]); 8 at the sides, the
/// words 6 after the glyph, on the outline face by default. Read as a
/// search field named [label] (Search). With neither [onChanged] nor a
/// [controller] it is disabled.
///
/// ```dart
/// Fluent2SearchBox(hint: 'Search files', value: query, onChanged: (v) => setState(() => query = v))
/// ```
class Fluent2SearchBox extends StatefulWidget {
  /// A search box, Fluent's SearchBox.
  const Fluent2SearchBox({
    this.value,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.controller,
    this.focusNode,
    this.hint,
    this.label,
    this.appearance = Fluent2InputAppearance.outline,
    this.size = Fluent2InputSize.medium,
    this.autofocus = false,
    super.key,
  });

  /// The words it starts with; null starts empty.
  final String? value;

  /// Called with the new value when the user changes it; null puts it out of
  /// use.
  final ValueChanged<String>? onChanged;

  /// Called with the words when the user submits them (the keyboard's done or
  /// Enter).
  final ValueChanged<String>? onSubmitted;

  /// Called when the clear button empties it.
  final VoidCallback? onClear;

  /// The controller that holds the words; null makes its own.
  final TextEditingController? controller;

  /// The focus node it takes focus with; null makes its own.
  final FocusNode? focusNode;

  /// The empty words; null is "Search" in the app's language.
  final String? hint;

  /// The spoken name; null says [placeholder].
  final String? label;

  /// Fluent's `appearance`: which of its faces it wears.
  final Fluent2InputAppearance appearance;

  /// Fluent's `size`: how large it is drawn.
  final Fluent2InputSize size;

  /// Whether it takes focus when it first appears.
  final bool autofocus;

  @override
  State<Fluent2SearchBox> createState() => _Fluent2SearchBoxState();
}

class _Fluent2SearchBoxState extends State<Fluent2SearchBox>
    with Fluent2FieldOwner<Fluent2SearchBox> {
  @override
  TextEditingController? controllerOf(Fluent2SearchBox w) => w.controller;

  @override
  String? valueOf(Fluent2SearchBox w) => w.value;

  @override
  FocusNode? focusNodeOf(Fluent2SearchBox w) => w.focusNode;

  void _clear() {
    fieldController.clear();
    widget.onChanged?.call('');
    widget.onClear?.call();
    fieldFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final enabled = widget.onChanged != null || widget.controller != null;
    final m = Fluent2FieldMetrics.of(widget.size);
    // SearchBox: the root 6, 8, 10 at the sides; the words 6 after the
    // glyph; the dismiss 12 after the words.
    final side = switch (widget.size) {
      Fluent2InputSize.small => Fluent2Spacing.sNudge,
      Fluent2InputSize.medium => Fluent2Spacing.s,
      Fluent2InputSize.large => Fluent2Spacing.mNudge,
    };
    final slot = enabled
        ? t.colors.neutralForeground3
        : t.colors.neutralForegroundDisabled;
    final filled = fieldController.text.isNotEmpty;
    final hint =
        widget.hint ?? DesignLocalizations.of(context).searchFieldLabel;
    return Fluent2HitSlop(
      child: Fluent2FieldFrame(
        appearance: widget.appearance,
        focused: fieldFocus.hasFocus,
        enabled: enabled,
        textNode: true,
        minHeight: m.height,
        padding: EdgeInsets.symmetric(horizontal: side),
        child: Row(
          children: [
            Icon(Fluent2Icons.search, size: m.glyph, color: slot),
            Expanded(
              child: Padding(
                padding: EdgeInsetsDirectional.only(
                  start: Fluent2Spacing.sNudge,
                  end: filled ? 0 : side,
                ),
                child: _Editor(
                  appearance: widget.appearance,
                  controller: fieldController,
                  focusNode: fieldFocus,
                  style: Fluent2FieldMetrics.typeOf(t, widget.size),
                  enabled: enabled,
                  label: widget.label ?? hint,
                  placeholder: hint,
                  onChanged: widget.onChanged,
                  onSubmitted: widget.onSubmitted,
                  textInputAction: TextInputAction.search,
                  autofocus: widget.autofocus,
                ),
              ),
            ),
            if (filled)
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: Fluent2Spacing.m,
                ),
                child: Fluent2Pressable(
                  onPressed: enabled ? _clear : null,
                  label: DesignLocalizations.of(context).clearButtonTooltip,
                  radius: Fluent2Radius.small,
                  builder: (context, states) => Icon(
                    Fluent2Icons.dismiss,
                    size: m.glyph,
                    color: states.press.pick(
                      t.colors.neutralForeground3,
                      t.colors.neutralForeground3Hover,
                      t.colors.neutralForeground3Pressed,
                      t.colors.neutralForegroundDisabled,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A way into search drawn as Fluent's SearchBox: the same field face and
/// search glyph with its [placeholder] in the fourth ink, or the [query]
/// the page already holds in the first; the whole field is one button
/// that opens the search ([onTap]). [onFilter] stands a filter button
/// beside it. Null [onTap] draws it disabled.
///
/// ```dart
/// Fluent2SearchEntry(hint: 'Search Northwind', onPressed: () => Navigator.of(context).pushNamed('/search'))
/// ```
class Fluent2SearchEntry extends StatelessWidget {
  /// A search box's face that opens a search page when pressed.
  const Fluent2SearchEntry({
    required this.onPressed,
    this.hint,
    this.query,
    this.onFilter,
    this.appearance = Fluent2InputAppearance.outline,
    this.size = Fluent2InputSize.medium,
    super.key,
  });

  /// Called when it is pressed (to open the search).
  final VoidCallback? onPressed;

  /// The empty words; null is "Search" in the app's language.
  final String? hint;

  /// The query the page holds, drawn in place of the placeholder.
  final String? query;

  /// Opens the filters; null draws no filter button.
  final VoidCallback? onFilter;

  /// Fluent's `appearance`: which of its faces it wears.
  final Fluent2InputAppearance appearance;

  /// Fluent's `size`: how large it is drawn.
  final Fluent2InputSize size;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final m = Fluent2FieldMetrics.of(size);
    final enabled = onPressed != null;
    final side = switch (size) {
      Fluent2InputSize.small => Fluent2Spacing.sNudge,
      Fluent2InputSize.medium => Fluent2Spacing.s,
      Fluent2InputSize.large => Fluent2Spacing.mNudge,
    };
    final words = query;
    final own = Fluent2Localizations.of(context);
    final hint = this.hint ?? DesignLocalizations.of(context).searchFieldLabel;
    final entry = Fluent2HitSlop(
      child: Fluent2Pressable(
        onPressed: onPressed,
        label: words ?? hint,
        hint: own.opensSearch,
        radius: Fluent2Radius.medium,
        builder: (context, states) => Fluent2FieldFrame(
          appearance: appearance,
          focused: false,
          enabled: enabled,
          pressed: states.press == Fluent2Press.pressed,
          cursor: SystemMouseCursors.click,
          minHeight: m.height,
          padding: EdgeInsets.symmetric(horizontal: side),
          child: Row(
            spacing: Fluent2Spacing.sNudge,
            children: [
              Icon(
                Fluent2Icons.search,
                size: m.glyph,
                color: enabled
                    ? t.colors.neutralForeground3
                    : t.colors.neutralForegroundDisabled,
              ),
              Expanded(
                child: Text(
                  words ?? hint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Fluent2FieldMetrics.typeOf(t, size).c(
                    !enabled
                        ? t.colors.neutralForegroundDisabled
                        : words != null
                        ? t.colors.neutralForeground1
                        : fluent2PlaceholderInk(t, appearance),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    // From 600 it is a control at most 320 wide (design6 P (a)), its
    // filter beside it; on a phone it runs the column.
    final roomy = fluent2Roomy(context);
    final filter = onFilter;
    if (filter == null) {
      return roomy
          ? fluent2KeepsOwnWidth(
              context,
              content: fluent2ControlMax,
              child: entry,
            )
          : entry;
    }
    return Row(
      spacing: Fluent2Spacing.s,
      children: [
        if (roomy)
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: fluent2ControlMax),
              child: entry,
            ),
          )
        else
          Expanded(child: entry),
        Fluent2IconButton(
          Fluent2Icons.filter,
          label: own.filters,
          appearance: Fluent2ButtonAppearance.secondary,
          size: switch (size) {
            Fluent2InputSize.small => Fluent2ButtonSize.small,
            Fluent2InputSize.medium => Fluent2ButtonSize.medium,
            Fluent2InputSize.large => Fluent2ButtonSize.large,
          },
          onPressed: enabled ? filter : null,
        ),
      ],
    );
  }
}

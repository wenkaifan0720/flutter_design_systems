import 'package:material_ui/material_ui.dart'
    show
        InputBorder,
        InputDecoration,
        Material,
        MaterialType,
        TextField,
        Theme,
        VisualDensity;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../editing.dart';
import '../theme.dart';
import 'cap.dart';
import 'hit_slop.dart';

/// A line of text with no well of its own: the field's type (400 16 in the
/// ink, the hint in the tertiary ink), the look's selection handles and
/// menu. The parts that draw their own frame round a field (an input
/// group, a tag input) stand it inside. Plumbing of the components.
class FrostedBareField extends StatelessWidget {
  /// A bare field on [controller] and [focusNode].
  const FrostedBareField({
    required this.controller,
    required this.focusNode,
    this.hint,
    this.label,
    this.onChanged,
    this.onSubmitted,
    this.obscureText = false,
    this.enabled = true,
    this.autofocus = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.inputFormatters,
    this.textAlign = TextAlign.start,
    super.key,
  });

  /// The field's text.
  final TextEditingController controller;

  /// The field's focus.
  final FocusNode focusNode;

  /// The placeholder.
  final String? hint;

  /// What a screen reader calls the field.
  final String? label;

  /// Called as the text changes.
  final ValueChanged<String>? onChanged;

  /// Called on Return.
  final ValueChanged<String>? onSubmitted;

  /// Whether the text is hidden.
  final bool obscureText;

  /// Whether it takes input.
  final bool enabled;

  /// Whether it takes focus on its first frame.
  final bool autofocus;

  /// The keyboard to raise.
  final TextInputType? keyboardType;

  /// The keyboard's action key.
  final TextInputAction? textInputAction;

  /// What autofill may put in it.
  final Iterable<String>? autofillHints;

  /// Rules the text is held to.
  final List<TextInputFormatter>? inputFormatters;

  /// Where the text stands.
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final style = t.textTheme.bodyLarge.line(19.2).c(t.colorScheme.textPrimary);
    return FrostedFieldTarget(
      label: label,
      child: Material(
        type: MaterialType.transparency,
        child: frostedCapCentredEntry(
          style,
          TextField(
            contextMenuBuilder: FrostedTextContextMenu.editable,
            selectionControls: FrostedTextSelectionControls.of(
              Theme.of(context).platform,
            ),
            controller: controller,
            focusNode: focusNode,
            autofocus: autofocus,
            enabled: enabled,
            obscureText: obscureText,
            autofillHints: autofillHints,
            inputFormatters: inputFormatters,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            textAlign: textAlign,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            style: style,
            cursorColor: t.colorScheme.textPrimary,
            decoration: _bareDecoration(
              hint: hint,
              hintStyle: style.c(t.colorScheme.textTertiary),
            ),
          ),
        ),
      ),
    );
  }
}

// The decoration of every text entry in Frosted (kept the same in
// bare_field.dart, forms.dart and composer.dart): the hint only, and every
// field that could size or place the line set, so that no
// InputDecorationTheme above the field (its padding, isDense, its
// constraints, a fill or a border) and no platform's density moves it. The
// decorator stands exactly the line's height; the look's own well draws the
// box round it and centres the line by alignment.
// InputDecoration.collapsed alone leaves the constraints and density to the
// theme.
InputDecoration _bareDecoration({String? hint, TextStyle? hintStyle}) =>
    InputDecoration(
      hintText: hint,
      hintStyle: hintStyle,
      isCollapsed: true,
      isDense: false,
      contentPadding: EdgeInsets.zero,
      visualDensity: VisualDensity.standard,
      constraints: const BoxConstraints(),
      filled: false,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      disabledBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      focusedErrorBorder: InputBorder.none,
    );

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
    this.hintText,
    this.labelText,
    this.onChanged,
    this.onSubmitted,
    this.onEditingComplete,
    this.obscureText = false,
    this.enabled = true,
    this.autofocus = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.inputFormatters,
    this.textAlign = TextAlign.start,
    this.ownNode = true,
    super.key,
  });

  /// The field's text.
  final TextEditingController controller;

  /// The field's focus.
  final FocusNode focusNode;

  /// The placeholder.
  final String? hintText;

  /// What a screen reader calls the field.
  final String? labelText;

  /// Called as the text changes.
  final ValueChanged<String>? onChanged;

  /// Called on Return; the field then lets the focus go.
  final ValueChanged<String>? onSubmitted;

  /// Takes Return in place of [onSubmitted] and keeps the focus: a field
  /// that stays focused after Return (a tag input's, a palette's search)
  /// must not also have [onSubmitted], or in a browser typing after Return
  /// goes nowhere (Flutter restarts the text input of a submitted field that
  /// still holds the focus).
  final VoidCallback? onEditingComplete;

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

  /// Whether the field's line makes its node ([FrostedFieldTarget.ownNode]);
  /// false inside a field that names it.
  final bool ownNode;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final style = t.textTheme.bodyLarge.line(19.2).c(t.colorScheme.textPrimary);
    return FrostedFieldTarget(
      label: labelText,
      ownNode: ownNode,
      child: frostedOpenEntry(
        context,
        Material(
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
              onEditingComplete: onEditingComplete,
              style: style,
              cursorColor: t.colorScheme.textPrimary,
              decoration: _bareDecoration(
                hint: hintText,
                hintStyle: style.c(t.colorScheme.textTertiary),
              ),
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

/// Whether the list a text entry opens stands open, for the entry under it
/// to say on its own node (expanded, or collapsed): a combobox's or a tag
/// input's field builder sets it from its field's `isOpen`. Outside one an
/// entry says neither. Plumbing of the components.
class FrostedEntryOpen extends InheritedWidget {
  /// Marks the entry under [child] as opening a list that is [open].
  const FrostedEntryOpen({required this.open, required super.child, super.key});

  /// Whether the entry's list stands open.
  final bool open;

  /// Whether the list of the entry at [context] stands open; null where
  /// the entry opens none.
  static bool? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FrostedEntryOpen>()?.open;

  @override
  bool updateShouldNotify(FrostedEntryOpen oldWidget) => open != oldWidget.open;
}

/// Wraps [entry] so its node says whether its list stands open
/// ([FrostedEntryOpen]); [entry] as it is outside one. Plumbing of the
/// components.
Widget frostedOpenEntry(BuildContext context, Widget entry) {
  final open = FrostedEntryOpen.maybeOf(context);
  return open == null ? entry : Semantics(expanded: open, child: entry);
}

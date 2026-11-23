/// A password field in Ledger's hand: the field on its rule with the eye
/// that shows what was typed, over ui_core's [RawPasswordReveal].
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../icon-button/icon_button.dart';
import '../../style.dart';
import '../text-field/text_field.dart';

/// A password written on the rule, as [LedgerTextField] is, its letters
/// hidden as dots, with the eye at its end that shows them and hides them
/// again: the eye says "Show password" or "Hide password" and the field
/// keeps its focus and its caret as it flips. With [hideOnBlur] a shown
/// password hides when focus leaves the field. [autofillHints] default to
/// a password's, so a password manager offers to fill it.
///
/// The [controller] and [focusNode] are the caller's to dispose when given;
/// when not, the field makes its own and disposes them.
///
/// ```dart
/// LedgerPasswordField(labelText: 'Password', helperText: 'At least 12 characters', controller: password)
/// ```
class LedgerPasswordField extends StatefulWidget {
  /// A password field [labelText]led.
  const LedgerPasswordField({
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.controller,
    this.focusNode,
    this.isRequired = false,
    this.enabled = true,
    this.hideOnBlur = false,
    this.autofocus = false,
    this.textInputAction,
    this.autofillHints = const [AutofillHints.password],
    this.onChanged,
    this.onSubmitted,
    this.style,
    super.key,
  });

  /// The small capitals over the rule.
  final String? labelText;

  /// The third ink's words while it is empty.
  final String? hintText;

  /// The note under the rule.
  final String? helperText;

  /// What is wrong, under the rule in the vermilion; it replaces [helperText].
  final String? errorText;

  /// The words typed; null: the field's own.
  final TextEditingController? controller;

  /// The field's focus; null: the field's own.
  final FocusNode? focusNode;

  /// Whether the label carries the required mark.
  final bool isRequired;

  /// Whether it takes words; false holds it, and its eye, in the third ink.
  final bool enabled;

  /// Whether a shown password hides when focus leaves the field.
  final bool hideOnBlur;

  /// {@macro ledger.autofocus}
  final bool autofocus;

  /// The keyboard's act key.
  final TextInputAction? textInputAction;

  /// What a password manager fills it with.
  final Iterable<String>? autofillHints;

  /// Called as the words change.
  final ValueChanged<String>? onChanged;

  /// Called when the keyboard's act key is pressed.
  final ValueChanged<String>? onSubmitted;

  /// The field's look, over `components.textField`. It reads `edge` (the
  /// rule's ink), `fill` (a paper behind the written line), `padding` (round
  /// the line), `foreground` (the words' ink) and `textStyle` (the words');
  /// a field is `focused`, `error` or `disabled` as it stands.
  final LedgerStyle? style;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('labelText', labelText, defaultValue: null))
      ..add(StringProperty('hintText', hintText, defaultValue: null))
      ..add(StringProperty('helperText', helperText, defaultValue: null))
      ..add(StringProperty('errorText', errorText, defaultValue: null))
      ..add(
        DiagnosticsProperty<TextEditingController>(
          'controller',
          controller,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(FlagProperty('isRequired', value: isRequired, ifTrue: 'isRequired'))
      ..add(FlagProperty('enabled', value: enabled, ifTrue: 'enabled'))
      ..add(FlagProperty('hideOnBlur', value: hideOnBlur, ifTrue: 'hideOnBlur'))
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'))
      ..add(
        DiagnosticsProperty<TextInputAction>(
          'textInputAction',
          textInputAction,
          defaultValue: null,
        ),
      )
      ..add(
        IterableProperty<String>(
          'autofillHints',
          autofillHints,
          defaultValue: null,
        ),
      )
      ..add(
        ObjectFlagProperty<ValueChanged<String>>.has('onChanged', onChanged),
      )
      ..add(
        ObjectFlagProperty<ValueChanged<String>>.has(
          'onSubmitted',
          onSubmitted,
        ),
      )
      ..add(
        DiagnosticsProperty<LedgerStyle>('style', style, defaultValue: null),
      );
  }

  @override
  State<LedgerPasswordField> createState() => _LedgerPasswordFieldState();
}

class _LedgerPasswordFieldState extends State<LedgerPasswordField> {
  FocusNode? _ownFocus;

  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode());

  @override
  void dispose() {
    _ownFocus?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RawPasswordReveal(
    focusNode: _focus,
    hideOnBlur: widget.hideOnBlur,
    builder: (context, password) => LedgerTextField(
      labelText: widget.labelText,
      hintText: widget.hintText,
      helperText: widget.helperText,
      errorText: widget.errorText,
      controller: widget.controller,
      focusNode: _focus,
      isRequired: widget.isRequired,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      obscureText: password.obscured,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: widget.textInputAction,
      autofillHints: widget.autofillHints,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      style: widget.style,
      trailing: LedgerIconButton(
        password.obscured ? LucideIcons.eye : LucideIcons.eyeOff,
        semanticLabel: password.toggleLabel,
        onPressed: widget.enabled ? password.toggle : null,
      ),
    ),
  );
}

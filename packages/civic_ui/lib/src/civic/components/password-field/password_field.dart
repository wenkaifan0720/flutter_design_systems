import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../theme.dart';
import '../checkbox/checkbox.dart';
import '../text-field/text_field.dart';

/// A box for a password, its characters hidden, with a "Show password"
/// checkbox under it: ticked, the password shows, so a reader can check
/// what they typed (and a reader who types slowly or with a switch can see
/// a mistake before sending it). The words are the reader's language's.
///
/// The box reads [CivicStyle] as [CivicTextField] does: [style], then
/// [CivicThemeData.textFieldStyle]; the checkbox reads
/// [CivicThemeData.checkboxStyle].
///
/// ```dart
/// CivicPasswordField(
///   labelText: 'Password',
///   helperText: 'At least 10 characters',
///   errorText: passwordError,
///   onChanged: (value) => password = value,
/// )
/// ```
class CivicPasswordField extends StatefulWidget {
  /// A password box.
  const CivicPasswordField({
    super.key,
    this.controller,
    this.focusNode,
    this.labelText,
    this.helperText,
    this.errorText,
    this.isNewPassword = false,
    this.enabled = true,
    this.autofocus = false,
    this.onChanged,
    this.onSubmitted,
    this.style,
  });

  /// The password; the field's own when null, and never disposed when
  /// given.
  final TextEditingController? controller;

  /// {@macro civic.focusNode}
  final FocusNode? focusNode;

  /// What the field asks: Password, Create a password.
  final String? labelText;

  /// What a password takes.
  final String? helperText;

  /// What is wrong and how to put it right; null while it is fine.
  final String? errorText;

  /// Whether it makes a password rather than asks for one: the platform
  /// offers to make and keep one.
  final bool isNewPassword;

  /// Whether it takes input.
  final bool enabled;

  /// {@macro civic.autofocus}
  final bool autofocus;

  /// Called with the password as it is typed.
  final ValueChanged<String>? onChanged;

  /// Called with the password when the keyboard submits it.
  final ValueChanged<String>? onSubmitted;

  /// Overrides for the box's look.
  final CivicStyle? style;

  @override
  State<CivicPasswordField> createState() => _CivicPasswordFieldState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
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
      ..add(StringProperty('labelText', labelText, defaultValue: null))
      ..add(StringProperty('helperText', helperText, defaultValue: null))
      ..add(StringProperty('errorText', errorText, defaultValue: null))
      ..add(
        FlagProperty(
          'isNewPassword',
          value: isNewPassword,
          ifTrue: 'new password',
        ),
      )
      ..add(FlagProperty('enabled', value: enabled, ifFalse: 'disabled'))
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'))
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
        DiagnosticsProperty<CivicStyle>('style', style, defaultValue: null),
      );
  }
}

class _CivicPasswordFieldState extends State<CivicPasswordField> {
  FocusNode? _own;
  FocusNode get _focus => widget.focusNode ?? (_own ??= FocusNode());

  @override
  void dispose() {
    _own?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final words = DesignLocalizations.of(context);
    return DesignPasswordReveal(
      focusNode: _focus,
      builder: (context, password) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: CivicSpacing.s8,
        children: [
          CivicTextField(
            controller: widget.controller,
            focusNode: _focus,
            labelText: widget.labelText,
            helperText: widget.helperText,
            errorText: widget.errorText,
            enabled: widget.enabled,
            autofocus: widget.autofocus,
            obscureText: password.obscured,
            keyboardType: TextInputType.visiblePassword,
            autofillHints: [
              widget.isNewPassword
                  ? AutofillHints.newPassword
                  : AutofillHints.password,
            ],
            onChanged: widget.onChanged,
            onSubmitted: widget.onSubmitted,
            style: widget.style,
          ),
          CivicCheckbox(
            value: !password.obscured,
            labelText: words.showPasswordLabel,
            onChanged: widget.enabled ? (_) => password.toggle() : null,
          ),
        ],
      ),
    );
  }
}

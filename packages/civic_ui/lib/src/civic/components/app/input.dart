import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../text-field/text_field.dart';

/// A one-line answer, as generated code writes it: a [CivicTextField] with
/// its [labelText] over the box, a [hintText] under the label, an [errorText] above the
/// box. A field always has words over it: with no [labelText], the [hintText] is
/// the label.
///
/// ```dart
/// CivicInput(
///   labelText: 'Email address',
///   errorText: emailError,
///   onChanged: (value) => email = value,
/// )
/// ```
class CivicInput extends StatelessWidget {
  /// A one-line answer.
  const CivicInput({
    super.key,
    this.labelText,
    this.hintText,
    this.errorText,
    this.obscureText = false,
    this.controller,
    this.onChanged,
    this.onSubmitted,
  });

  /// What the field asks.
  final String? labelText;

  /// Help with the answer, under the label.
  final String? hintText;

  /// What is wrong with the answer; null when nothing is.
  final String? errorText;

  /// Whether the answer is hidden as it is typed (a password).
  final bool obscureText;

  /// The answer's controller; null keeps its own.
  final TextEditingController? controller;

  /// Called with the answer as it changes.
  final ValueChanged<String>? onChanged;

  /// Called with the answer when the reader submits it.
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) => CivicTextField(
    controller: controller,
    labelText: labelText ?? hintText,
    helperText: labelText == null ? null : hintText,
    errorText: errorText,
    obscureText: obscureText,
    onChanged: onChanged,
    onSubmitted: onSubmitted,
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('labelText', labelText, defaultValue: null))
      ..add(StringProperty('hintText', hintText, defaultValue: null))
      ..add(StringProperty('errorText', errorText, defaultValue: null))
      ..add(
        FlagProperty('obscureText', value: obscureText, ifTrue: 'obscured'),
      );
  }
}

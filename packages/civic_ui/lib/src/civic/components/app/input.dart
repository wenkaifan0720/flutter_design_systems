import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../text-field/text_field.dart';

/// A one-line answer, as generated code writes it: a [CivicTextField] with
/// its [label] over the box, a [hint] under the label, an [error] above the
/// box. A field always has words over it: with no [label], the [hint] is
/// the label.
///
/// ```dart
/// CivicInput(
///   label: 'Email address',
///   error: emailError,
///   onChanged: (value) => email = value,
/// )
/// ```
class CivicInput extends StatelessWidget {
  /// A one-line answer.
  const CivicInput({
    super.key,
    this.label,
    this.hint,
    this.error,
    this.obscure = false,
    this.controller,
    this.onChanged,
    this.onSubmitted,
  });

  /// What the field asks.
  final String? label;

  /// Help with the answer, under the label.
  final String? hint;

  /// What is wrong with the answer; null when nothing is.
  final String? error;

  /// Whether the answer is hidden as it is typed (a password).
  final bool obscure;

  /// The answer's controller; null keeps its own.
  final TextEditingController? controller;

  /// Called with the answer as it changes.
  final ValueChanged<String>? onChanged;

  /// Called with the answer when the reader submits it.
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) => CivicTextField(
    controller: controller,
    labelText: label ?? hint,
    helperText: label == null ? null : hint,
    errorText: error,
    obscureText: obscure,
    onChanged: onChanged,
    onSubmitted: onSubmitted,
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label, defaultValue: null))
      ..add(StringProperty('hint', hint, defaultValue: null))
      ..add(StringProperty('error', error, defaultValue: null))
      ..add(FlagProperty('obscure', value: obscure, ifTrue: 'obscured'));
  }
}

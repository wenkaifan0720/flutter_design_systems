/// A multi-line text field: notes, a description, a message.
library;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../component_themes.dart';
import 'input.dart';

/// A field for more than a line — a note, a description, a message: the
/// [MinimalTextField] box, label, helper and error, resting at [minLines]
/// and growing with what is typed up to [maxLines], then scrolling. Enter
/// starts a new line rather than submitting.
///
/// It reads `components.textField` and its [fieldStyle] exactly as the one-
/// line field does, so a form's boxes match: fill, edge or side, shape
/// (else `shapes.small`) and padding, focused and in error.
///
/// ```dart
/// MinimalTextArea(label: 'Notes', hint: 'Anything the team should know', controller: notes)
/// ```
class MinimalTextArea extends StatelessWidget {
  /// A text field of several lines.
  const MinimalTextArea({
    super.key,
    this.label,
    this.hint,
    this.helper,
    this.error,
    this.controller,
    this.onChanged,
    this.minLines = 3,
    this.maxLines = 8,
    this.enabled = true,
    this.readOnly = false,
    this.focusNode,
    this.fieldStyle,
    this.autofocus = false,
  }) : assert(minLines > 0 && maxLines >= minLines);

  /// What it holds, over the box.
  final String? label;

  /// What an empty field says.
  final String? hint;

  /// A quiet line under the box, when there is no [error].
  final String? helper;

  /// The message under the box; also turns its rule to the destructive ink.
  final String? error;

  /// The text; null keeps its own.
  final TextEditingController? controller;

  /// Reports each edit.
  final ValueChanged<String>? onChanged;

  /// The lines the box stands at when empty.
  final int minLines;

  /// The lines it grows to before it scrolls.
  final int maxLines;

  /// Whether it takes input.
  final bool enabled;

  /// Whether its text is shown but not edited.
  final bool readOnly;

  /// Its focus; null keeps its own.
  final FocusNode? focusNode;

  /// This box's style, over `components.textField`.
  final MinimalStyle? fieldStyle;

  /// Whether it takes keyboard focus when it first appears.
  final bool autofocus;

  @override
  Widget build(BuildContext context) => MinimalTextField(
    label: label,
    hint: hint,
    helper: helper,
    error: error,
    controller: controller,
    onChanged: onChanged,
    minLines: minLines,
    maxLines: maxLines,
    enabled: enabled,
    readOnly: readOnly,
    focusNode: focusNode,
    autofocus: autofocus,
    keyboardType: TextInputType.multiline,
    textInputAction: TextInputAction.newline,
    textCapitalization: TextCapitalization.sentences,
    fieldStyle: fieldStyle,
  );
}

import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../text_field.dart';

/// A Studio field's frame: its label stamped over [child], its help or its
/// error under it, all read on [child]'s node through ui_core's field, as
/// Material's TextField reads its words: a screen reader on the control
/// hears its label, then the error or the help. Plumbing of Studio's fields.
class StudioFieldFrame extends StatelessWidget {
  /// [child] framed as a field.
  const StudioFieldFrame({
    super.key,
    required this.child,
    this.labelText,
    this.helperText,
    this.errorText,
    this.enabled = true,
    this.focusNode,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
  });

  /// The control.
  final Widget child;

  /// The label stamped above it, and the control's name.
  final String? labelText;

  /// A note under it.
  final String? helperText;

  /// What is wrong, in the note's place; empty marks the control invalid
  /// with the lamp alone.
  final String? errorText;

  /// Whether the control takes input.
  final bool enabled;

  /// The control's focus.
  final FocusNode? focusNode;

  /// How the label, the control and the words line up.
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    final error = errorText;
    final said = error == null || error.isEmpty ? null : error;
    return RawInputDecorator(
      labelText: labelText,
      helperText: helperText,
      errorText: said,
      invalid: error != null,
      enabled: enabled,
      focusNode: focusNode,
      builder: (context, parts) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: crossAxisAlignment,
        children: [
          if (labelText != null)
            ExcludeSemantics(
              child: StudioFieldLabel(labelText!, enabled: enabled),
            ),
          parts.control,
          // The words are the control's hint. Where the platform makes no
          // announcement, the error's line is a live region beside it, as
          // ui_core draws it.
          ExcludeSemantics(
            excluding: said == null || MediaQuery.supportsAnnounceOf(context),
            child: StudioFieldMessage(helper: helperText, error: error),
          ),
        ],
      ),
      child: child,
    );
  }
}

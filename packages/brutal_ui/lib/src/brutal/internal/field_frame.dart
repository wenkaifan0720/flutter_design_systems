import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../text_field.dart';

/// A label over [child] and its help or error under it, as Brutal's fields
/// stand, through ui_core's [RawInputDecorator]: the label, the help and the
/// error are read with the control, so the drawn words stay out of the
/// semantics tree. An error is announced as it appears; where the platform
/// takes no announcements its line is a live region.
class BrutalFieldFrame extends StatelessWidget {
  /// [child] with its words.
  const BrutalFieldFrame({
    super.key,
    required this.child,
    this.labelText,
    this.helperText,
    this.errorText,
    this.enabled = true,
    this.failureLine,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
    this.semantics = true,
  });

  /// The control.
  final Widget child;

  /// The label over it.
  final String? labelText;

  /// Help under it.
  final String? helperText;

  /// What is wrong, under it; empty, the box alone is marked (its words
  /// stand elsewhere).
  final String? errorText;

  /// Whether the control is on; off, the label is grey.
  final bool enabled;

  /// Wraps the error line ([BrutalFieldMessage.failureLine]).
  final Widget Function(Widget line)? failureLine;

  /// How the label, the control and the message line up across.
  final CrossAxisAlignment crossAxisAlignment;

  /// Whether the words are read with the control, through ui_core's
  /// [RawInputDecorator]; false where the caller names the control itself
  /// (a field's `decorate`), the words only drawn.
  final bool semantics;

  @override
  Widget build(BuildContext context) {
    if (labelText == null && helperText == null && errorText == null) {
      // Laid out as a framed one is: as tall as the control.
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: crossAxisAlignment,
        children: [child],
      );
    }
    final error = errorText;
    if (!semantics) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: crossAxisAlignment,
        children: [
          if (labelText != null)
            ExcludeSemantics(
              child: BrutalFieldLabel(labelText!, enabled: enabled),
            ),
          child,
          BrutalFieldMessage(
            helperText: helperText,
            errorText: error,
            failureLine: failureLine,
          ),
        ],
      );
    }
    return RawInputDecorator(
      labelText: labelText,
      helperText: helperText,
      errorText: error == null || error.isEmpty ? null : error,
      invalid: error != null,
      enabled: enabled,
      builder: (context, parts) {
        final message = BrutalFieldMessage(
          helperText: helperText,
          errorText: error,
          failureLine: failureLine,
        );
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: crossAxisAlignment,
          children: [
            if (labelText != null)
              ExcludeSemantics(
                child: BrutalFieldLabel(labelText!, enabled: enabled),
              ),
            parts.control,
            if (parts.errorText != null &&
                !MediaQuery.supportsAnnounceOf(context))
              message
            else
              ExcludeSemantics(child: message),
          ],
        );
      },
      child: child,
    );
  }
}

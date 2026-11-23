import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../text_field.dart';

/// A label over [child] and its help or error under it, as Gloss's fields
/// stand, through ui_core's [RawInputDecorator]: the label, the help and the
/// error are read with the control, so the drawn words stay out of the
/// semantics tree. An error is announced as it appears; where the platform
/// takes no announcements its line is a live region.
class GlossFieldFrame extends StatelessWidget {
  /// [child] with its words.
  const GlossFieldFrame({
    super.key,
    required this.child,
    this.labelText,
    this.helperText,
    this.errorText,
    this.enabled = true,
  });

  /// The control.
  final Widget child;

  /// The label over it.
  final String? labelText;

  /// Help under it.
  final String? helperText;

  /// What is wrong, under it.
  final String? errorText;

  /// Whether the control is on; off, the label is clouded.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (labelText == null && helperText == null && errorText == null) {
      // Laid out as a framed one is: as tall as the control.
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [child],
      );
    }
    return RawInputDecorator(
      labelText: labelText,
      helperText: helperText,
      errorText: errorText,
      enabled: enabled,
      builder: (context, parts) {
        final message = GlossFieldMessage(
          helperText: helperText,
          errorText: errorText,
        );
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (labelText != null)
              ExcludeSemantics(
                child: GlossFieldLabel(labelText!, enabled: enabled),
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

/// A field's label over its control and its help or error under it, on
/// ui_core's [RawInputDecorator]: the label, the help and the error are read
/// on the control's own node, and the drawn words are left out of the tree.
library;

import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../text_field.dart';

/// [control] under its label, over its help or its error. The field's
/// name for a screen reader is [semanticLabel], else [labelText].
Widget applianceFieldFrame({
  required Widget control,
  String? labelText,
  String? semanticLabel,
  String? helperText,
  String? errorText,
  bool required = false,
  bool enabled = true,
  FocusNode? focusNode,
  bool? mergeSemantics,
}) => RawInputDecorator(
  labelText: semanticLabel ?? labelText,
  helperText: helperText,
  errorText: errorText,
  required: required,
  enabled: enabled,
  focusNode: focusNode,
  mergeSemantics: mergeSemantics,
  builder: (context, parts) {
    final label = labelText;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label != null)
          ExcludeSemantics(
            child: ApplianceFieldLabel(
              parts.required ? '$label *' : label,
              enabled: parts.enabled,
            ),
          ),
        parts.control,
        ApplianceFieldMessage(parts),
      ],
    );
  },
  child: control,
);

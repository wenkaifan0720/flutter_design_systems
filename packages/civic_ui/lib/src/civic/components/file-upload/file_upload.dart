import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../internal/field_frame.dart';
import '../../internal/paint.dart';
import '../../theme.dart';
import '../button/button.dart';
import '../link/link.dart';

/// A document the reader sends with their answers: the question, then a
/// secondary button that chooses the file ([onChoose]; the app opens the
/// platform's picker) and, once one is chosen, its name with a link to
/// remove it. The file's name is words, so it reads at any size and in
/// either direction. In error the control stands in the error's doubled
/// edge, as a field's box does; the button keeps its own look.
///
/// ```dart
/// CivicFileUpload(
///   labelText: 'Upload proof of address',
///   helperText: 'A council tax bill or a tenancy agreement, as a PDF or a photo.',
///   chooseLabel: 'Choose file',
///   emptyLabel: 'No file chosen',
///   removeLabel: 'Remove',
///   fileName: proof?.name,
///   onChoose: pickProof,
///   onRemoved: () => setState(() => proof = null),
/// )
/// ```
class CivicFileUpload extends StatelessWidget {
  /// A file to send.
  const CivicFileUpload({
    super.key,
    required this.chooseLabel,
    required this.emptyLabel,
    required this.onChoose,
    this.removeLabel,
    this.onRemoved,
    this.fileName,
    this.labelText,
    this.helperText,
    this.errorText,
    this.isError = false,
    this.focusNode,
  });

  /// The button's words: Choose file.
  final String chooseLabel;

  /// What stands while none is chosen: No file chosen.
  final String emptyLabel;

  /// Opens the picker; null disables it.
  final VoidCallback? onChoose;

  /// The remove link's words.
  final String? removeLabel;

  /// Called by the remove link; null shows none.
  final VoidCallback? onRemoved;

  /// The chosen file's name; null while none is.
  final String? fileName;

  /// The question.
  final String? labelText;

  /// What file is wanted.
  final String? helperText;

  /// What to fix; null while it is fine.
  final String? errorText;

  /// Whether it takes the error edge with no words of its own: an upload
  /// under a fieldset's question, which says what is wrong.
  final bool isError;

  /// The choose button's focus; an error summary's link focuses it.
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final text = context.civicText;
    final name = fileName;
    final remove = onRemoved;
    return DesignField(
      labelText: labelText,
      helperText: helperText,
      errorText: errorText,
      builder: (context, parts) => CivicFieldFrame(
        parts: parts,
        control: errorText == null && !isError
            ? parts.control
            : DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: t.danger,
                    width: CivicMetrics.edge * 2,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(CivicSpacing.s12),
                  child: parts.control,
                ),
              ),
      ),
      child: Wrap(
        spacing: CivicSpacing.s16,
        runSpacing: CivicSpacing.s12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          CivicButton.secondary(
            onPressed: onChoose,
            focusNode: focusNode,
            expand: false,
            icon: LucideIcons.upload,
            child: Text(chooseLabel),
          ),
          if (name == null)
            Text(emptyLabel, style: text.body.copyWith(color: t.textSecondary))
          else
            Wrap(
              spacing: CivicSpacing.s12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: CivicSpacing.s8,
                  children: [
                    Icon(LucideIcons.fileCheck, size: 22, color: t.success),
                    Flexible(child: Text(name, style: text.label)),
                  ],
                ),
                if (remove != null && removeLabel != null)
                  CivicLink(
                    onPressed: remove,
                    semanticLabel: '$removeLabel $name',
                    child: Text(removeLabel!),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('fileName', fileName, defaultValue: null))
      ..add(StringProperty('labelText', labelText, defaultValue: null))
      ..add(StringProperty('errorText', errorText, defaultValue: null))
      ..add(FlagProperty('isError', value: isError, ifTrue: 'error'))
      ..add(ObjectFlagProperty<VoidCallback>.has('onChoose', onChoose))
      ..add(ObjectFlagProperty<VoidCallback>.has('onRemoved', onRemoved));
  }
}

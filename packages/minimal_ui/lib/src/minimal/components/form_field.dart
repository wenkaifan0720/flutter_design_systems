/// Any control with its label, help and error, and a form that validates
/// its fields, painted on ui_core's field and form.
library;

import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../chrome_metrics.dart';
import '../internal/field.dart';
import '../localizations.dart';
import '../theme.dart';

/// A control with its words round it: a select, a switch, a group of radios,
/// a combobox, anything that brings no label of its own. The [label] over
/// it in the caption weight (a quiet asterisk after it when [required]),
/// the [help] under it in the secondary ink, and the [error] in its place,
/// in the destructive ink, when the value is wrong.
///
/// A screen reader hears the label as the control's name and the error and
/// help as its hint, the control marked invalid while [error] is set (a
/// [MinimalTextField] or [MinimalInputGroup] in it draws its rule in the
/// danger ink, as with an error of its own); a tap
/// on the label focuses the control ([focusNode]). A group of controls
/// (radios) sets `group: true`, and the label names the group instead. The
/// behaviour is ui_core's ([DesignField]); Minimal paints it. A
/// [MinimalTextField] carries its own label and needs none of this.
///
/// ```dart
/// MinimalFormField(label: 'Plan', help: 'You can change it later', group: true, child: MinimalRadioGroup<String>(value: plan, onChanged: setPlan, options: const [MinimalRadioOption(value: 'free', label: 'Free'), MinimalRadioOption(value: 'pro', label: 'Pro')]))
/// ```
class MinimalFormField extends StatelessWidget {
  /// A field around [child].
  const MinimalFormField({
    super.key,
    required this.child,
    this.label,
    this.help,
    this.error,
    this.required = false,
    this.enabled = true,
    this.focusNode,
    this.group = false,
  });

  /// The control.
  final Widget child;

  /// What the field is.
  final String? label;

  /// A quiet line under the control; the [error] replaces it.
  final String? help;

  /// What is wrong, or null.
  final String? error;

  /// Whether it must be filled: an asterisk, and "required" said after the
  /// name.
  final bool required;

  /// Whether the control takes input; the words dim with it.
  final bool enabled;

  /// The control's focus: a tap on the label requests it.
  final FocusNode? focusNode;

  /// A group of controls the label names (radios), rather than one control
  /// that takes the label as its own name.
  final bool group;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final words = MinimalLocalizations.of(context);
    final field = DesignField(
      labelText: label,
      helperText: help,
      errorText: error,
      required: required,
      enabled: enabled,
      focusNode: focusNode,
      mergeSemantics: !group,
      requiredHint: words.required,
      child: child,
      builder: (context, parts) {
        final name = parts.label;
        final help = parts.helper;
        final wrong = parts.error;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (name != null) ...[
              DefaultTextStyle(
                style: t.caption.medium.c(t.foreground),
                child: Row(
                  children: [
                    Flexible(child: name),
                    if (parts.required)
                      ExcludeSemantics(
                        child: Text(
                          ' *',
                          style: t.caption.medium.c(t.textTertiary),
                        ),
                      ),
                  ],
                ),
              ),
              const MinimalGap(MinimalChromeMetrics.iconGap),
            ],
            MinimalFieldErrorScope(wrong: wrong != null, child: parts.control),
            if (wrong != null || help != null) ...[
              const MinimalGap(MinimalChromeMetrics.iconGap),
              DefaultTextStyle(
                style: t.caption.c(
                  wrong != null ? t.destructiveInk : t.mutedForeground,
                ),
                child: (wrong ?? help)!,
              ),
            ],
          ],
        );
      },
    );
    return enabled ? field : Opacity(opacity: 0.45, child: field);
  }
}

/// The fields of a form, validated together: a submit that finds a wrong
/// field shows every error, moves focus to the first one (scrolling it into
/// view) and tells a screen reader how many need attention; after that,
/// the errors follow the edits. Fields take part through Flutter's
/// `FormField` (ui_core's `DesignFormField`, with the control's focus
/// node); [MinimalForm.submit] runs the check from a button.
///
/// The behaviour is ui_core's ([DesignForm]); it paints nothing.
///
/// ```dart
/// MinimalForm(onSubmit: save, child: Column(children: fields))
/// ```
class MinimalForm extends StatelessWidget {
  /// A form around [child].
  const MinimalForm({super.key, required this.child, this.onSubmit});

  /// The fields, laid out as the screen likes.
  final Widget child;

  /// Called by [submit] when every field is fine.
  final VoidCallback? onSubmit;

  /// Validates the form around [context]: true, and [onSubmit] called, when
  /// every field is fine.
  static bool submit(BuildContext context) => DesignForm.of(context).submit();

  /// Clears the form around [context] back to its first values.
  static void reset(BuildContext context) => DesignForm.of(context).reset();

  @override
  Widget build(BuildContext context) {
    final words = MinimalLocalizations.of(context);
    return DesignForm(
      onSubmit: onSubmit,
      problemsMessage: words.fieldsNeedAttention,
      child: child,
    );
  }
}

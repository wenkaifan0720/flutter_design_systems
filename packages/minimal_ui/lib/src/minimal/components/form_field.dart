/// Any control with its label, help and error, and a form that validates
/// its fields, painted on ui_core's field and form.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../chrome_metrics.dart';
import '../internal/field.dart';
import '../localizations.dart';
import '../theme.dart';
import '../internal/message_reveal.dart';
import 'input.dart';

/// A control with its words round it: a select, a switch, a group of radios,
/// a combobox, anything that brings no label of its own. The [labelText] over
/// it in the caption weight (a quiet asterisk after it when [required]),
/// the [helperText] under it in the secondary ink, and the [errorText] in its place,
/// in the destructive ink, when the value is wrong.
///
/// A screen reader hears the label as the control's name and the error and
/// help as its hint, the control marked invalid while [errorText] is set (a
/// [MinimalTextField] or [MinimalInputGroup] in it draws its rule in the
/// danger ink, as with an error of its own); a tap
/// on the label focuses the control ([focusNode]). The control inside takes
/// no `semanticLabel` of its own: the label names it, and a second name is
/// read twice. A group of controls
/// (radios) sets `group: true`, and the label names the group instead. The
/// behaviour is ui_core's ([RawInputDecorator]); Minimal paints it. A
/// [MinimalTextField] carries its own label and needs none of this.
///
/// ```dart
/// MinimalFormField(labelText: 'Plan', helperText: 'You can change it later', group: true, child: MinimalRadioGroup<String>(value: plan, onChanged: setPlan, options: const [MinimalRadioOption(value: 'free', label: 'Free'), MinimalRadioOption(value: 'pro', label: 'Pro')]))
/// ```
class MinimalFormField extends StatelessWidget {
  /// A field around [child].
  const MinimalFormField({
    super.key,
    required this.child,
    this.labelText,
    this.helperText,
    this.errorText,
    this.required = false,
    this.enabled = true,
    this.focusNode,
    this.group = false,
  });

  /// The control.
  final Widget child;

  /// What the field is.
  final String? labelText;

  /// A quiet line under the control; the [errorText] replaces it.
  final String? helperText;

  /// What is wrong, or null.
  final String? errorText;

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
    final field = RawInputDecorator(
      labelText: labelText,
      helperText: helperText,
      errorText: errorText,
      required: required,
      enabled: enabled,
      focusNode: focusNode,
      mergeSemantics: !group,
      requiredHint: words.required,
      child: child,
      builder: (context, parts) {
        final name = parts.label;
        final helperText = parts.helper;
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
            // The line grows open and fades in (and out), never jumps.
            MinimalMessageReveal(
              id: parts.errorText,
              child: !(wrong != null || helperText != null)
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.only(
                        top: MinimalChromeMetrics.iconGap,
                      ),
                      child: DefaultTextStyle(
                        style: t.caption.c(
                          wrong != null ? t.destructiveInk : t.mutedForeground,
                        ),
                        child: (wrong ?? helperText)!,
                      ),
                    ),
            ),
          ],
        );
      },
    );
    return enabled ? field : Opacity(opacity: 0.45, child: field);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('labelText', labelText, defaultValue: null))
      ..add(StringProperty('helperText', helperText, defaultValue: null))
      ..add(StringProperty('errorText', errorText, defaultValue: null))
      ..add(FlagProperty('required', value: required, ifTrue: 'required'))
      ..add(FlagProperty('enabled', value: enabled, ifFalse: 'enabled: false'))
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(FlagProperty('group', value: group, ifTrue: 'group'));
  }
}

/// The fields of a form, validated together: a submit that finds a wrong
/// field shows every error, moves focus to the first one (scrolling it into
/// view) and tells a screen reader how many need attention; after that,
/// the errors follow the edits. Fields take part through Flutter's
/// `FormField`: a [MinimalTextFormField] for text, and ui_core's
/// `RawFormField` round any other control (given the control's focus node,
/// its `errorText` passed to a [MinimalFormField] round the control);
/// [MinimalForm.submit] runs the check from a button.
///
/// Lay the fields in one column, each at the column's width, 16 px apart:
/// `Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing:
/// MinimalSpacing.s16, children: fields)`, the rhythm every Minimal form
/// keeps. Keep one field style: beside boxed text fields a date is boxed
/// too (`MinimalDatePickerPresentation.field`).
///
/// A form that is itself a place (an "Add" tab, a nav root) is the same
/// page as the form pushed to edit: its Save stays in the
/// [MinimalScaffold.footer], which docks above a phone's tab bar.
///
/// The behaviour is ui_core's ([RawForm]); it paints nothing.
///
/// ```dart
/// MinimalForm(onSubmit: save, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: MinimalSpacing.s16, children: [MinimalTextFormField(labelText: 'Title', required: true, validator: (value) => (value ?? '').trim().isEmpty ? 'Enter a title' : null)]))
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
  static bool submit(BuildContext context) => RawForm.of(context).submit();

  /// Clears the form around [context] back to its first values.
  static void reset(BuildContext context) => RawForm.of(context).reset();

  @override
  Widget build(BuildContext context) {
    final words = MinimalLocalizations.of(context);
    return RawForm(
      onSubmit: onSubmit,
      problemsMessage: words.fieldsNeedAttention,
      child: child,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ObjectFlagProperty<VoidCallback>.has('onSubmit', onSubmit));
  }
}

/// A [MinimalTextField] that takes part in a [MinimalForm], as Flutter's
/// `TextFormField` wraps its `TextField`: [validator] checks the text when
/// the form submits (and after a failed submit, as the text is edited), its
/// message shows as the field's error, and [onSaved] gets the text when every
/// field is fine. A failed submit moves focus to the first field that is
/// wrong; [MinimalForm.reset] puts the text back to its first value.
///
/// The text is [controller]'s when given, else the field keeps its own,
/// starting at [initialValue]. The rest is the text field's own.
///
/// ```dart
/// MinimalTextFormField(labelText: 'Title', required: true, validator: (value) => (value ?? '').trim().isEmpty ? 'Enter a title' : null, onSaved: (value) => title = value!)
/// ```
class MinimalTextFormField extends StatefulWidget {
  /// A text field that a [MinimalForm] validates.
  const MinimalTextFormField({
    super.key,
    this.controller,
    this.initialValue,
    this.focusNode,
    this.validator,
    this.onSaved,
    this.onChanged,
    this.onFieldSubmitted,
    this.autovalidateMode = AutovalidateMode.disabled,
    this.labelText,
    this.hintText,
    this.helperText,
    this.required = false,
    this.icon,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.obscureText = false,
    this.maxLines = 1,
    this.minLines,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
    this.inputFormatters,
    this.mono = false,
    this.suffix,
    this.clearable = false,
  }) : assert(
         initialValue == null || controller == null,
         'the text comes from initialValue or from controller, not both',
       );

  /// The text; null keeps its own, starting at [initialValue].
  final TextEditingController? controller;

  /// The first text of a field with no [controller].
  final String? initialValue;

  /// Its focus, which a failed submit moves here when this field is the
  /// first that is wrong; null keeps its own.
  final FocusNode? focusNode;

  /// Says what is wrong with the text, or null when it is fine.
  final FormFieldValidator<String>? validator;

  /// Gets the text when the form submits and every field is fine.
  final FormFieldSetter<String>? onSaved;

  /// Reports each edit.
  final ValueChanged<String>? onChanged;

  /// Reports the text when the keyboard's action is pressed.
  final ValueChanged<String>? onFieldSubmitted;

  /// When the field checks itself before a submit does; after a failed
  /// submit the form checks every field as it is edited whatever this says.
  final AutovalidateMode autovalidateMode;

  /// What it holds, over the box.
  final String? labelText;

  /// What an empty field says.
  final String? hintText;

  /// A quiet line under the field; the error replaces it.
  final String? helperText;

  /// Whether it must be filled: the asterisk and "required", as
  /// [MinimalTextField.required]. The check itself is [validator]'s.
  final bool required;

  /// A glyph at the field's start.
  final IconData? icon;

  /// Whether it takes input.
  final bool enabled;

  /// {@macro minimal.readOnly}
  final bool readOnly;

  /// Whether it takes focus when it first shows.
  final bool autofocus;

  /// Whether it hides what is typed.
  final bool obscureText;

  /// Above 1 the field becomes a notes box that grows to this many lines.
  final int maxLines;

  /// Where a notes box rests; unstated it is [maxLines].
  final int? minLines;

  /// The keyboard it asks for.
  final TextInputType? keyboardType;

  /// {@macro minimal.textInputAction}
  final TextInputAction? textInputAction;

  /// Which letters the keyboard capitalises.
  final TextCapitalization textCapitalization;

  /// What the platform may fill it with: an email, a password.
  final Iterable<String>? autofillHints;

  /// What the field lets through as it is typed.
  final List<TextInputFormatter>? inputFormatters;

  /// Set the value in Geist Mono with tabular figures.
  final bool mono;

  /// A unit printed at the field's end.
  final String? suffix;

  /// Show a clear glyph at the end while the field holds text.
  final bool clearable;

  @override
  State<MinimalTextFormField> createState() => _MinimalTextFormFieldState();

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
      ..add(StringProperty('initialValue', initialValue, defaultValue: null))
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(
        ObjectFlagProperty<FormFieldValidator<String>>.has(
          'validator',
          validator,
        ),
      )
      ..add(ObjectFlagProperty<FormFieldSetter<String>>.has('onSaved', onSaved))
      ..add(
        EnumProperty<AutovalidateMode>(
          'autovalidateMode',
          autovalidateMode,
          defaultValue: AutovalidateMode.disabled,
        ),
      )
      ..add(StringProperty('labelText', labelText, defaultValue: null))
      ..add(StringProperty('hintText', hintText, defaultValue: null))
      ..add(StringProperty('helperText', helperText, defaultValue: null))
      ..add(
        ObjectFlagProperty<ValueChanged<String>>.has('onChanged', onChanged),
      )
      ..add(
        ObjectFlagProperty<ValueChanged<String>>.has(
          'onFieldSubmitted',
          onFieldSubmitted,
        ),
      )
      ..add(FlagProperty('required', value: required, ifTrue: 'required'))
      ..add(IconDataProperty('icon', icon))
      ..add(FlagProperty('enabled', value: enabled, ifFalse: 'enabled: false'))
      ..add(FlagProperty('readOnly', value: readOnly, ifTrue: 'readOnly'))
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'))
      ..add(FlagProperty('obscureText', value: obscureText, ifTrue: 'obscured'))
      ..add(IntProperty('maxLines', maxLines, defaultValue: 1))
      ..add(IntProperty('minLines', minLines, defaultValue: null))
      ..add(
        DiagnosticsProperty<TextInputType>(
          'keyboardType',
          keyboardType,
          defaultValue: null,
        ),
      )
      ..add(
        EnumProperty<TextInputAction>(
          'textInputAction',
          textInputAction,
          defaultValue: null,
        ),
      )
      ..add(
        EnumProperty<TextCapitalization>(
          'textCapitalization',
          textCapitalization,
          defaultValue: TextCapitalization.none,
        ),
      )
      ..add(
        IterableProperty<String>(
          'autofillHints',
          autofillHints,
          defaultValue: null,
        ),
      )
      ..add(
        IterableProperty<TextInputFormatter>(
          'inputFormatters',
          inputFormatters,
          defaultValue: null,
        ),
      )
      ..add(FlagProperty('mono', value: mono, ifTrue: 'mono'))
      ..add(StringProperty('suffix', suffix, defaultValue: null))
      ..add(FlagProperty('clearable', value: clearable, ifTrue: 'clearable'));
  }
}

class _MinimalTextFormFieldState extends State<MinimalTextFormField> {
  TextEditingController? _ownedController;
  FocusNode? _ownedFocus;
  FormFieldState<String>? _field;

  TextEditingController get _controller =>
      widget.controller ??
      (_ownedController ??= TextEditingController(text: widget.initialValue));

  FocusNode get _focus =>
      widget.focusNode ??
      (_ownedFocus ??= FocusNode(debugLabel: 'MinimalTextFormField'));

  @override
  void initState() {
    super.initState();
    _controller.addListener(_textChanged);
  }

  @override
  void didUpdateWidget(MinimalTextFormField old) {
    super.didUpdateWidget(old);
    if (old.controller == widget.controller) return;
    (old.controller ?? _ownedController)?.removeListener(_textChanged);
    if (widget.controller != null) {
      _ownedController?.dispose();
      _ownedController = null;
    } else {
      _ownedController = TextEditingController.fromValue(old.controller?.value);
    }
    _controller.addListener(_textChanged);
    _field?.didChange(_controller.text);
  }

  @override
  void dispose() {
    _controller.removeListener(_textChanged);
    _ownedController?.dispose();
    _ownedFocus?.dispose();
    super.dispose();
  }

  // The field's value follows the text, however it changed (typing, the
  // clear glyph, the app setting the controller).
  void _textChanged() {
    final field = _field;
    if (field != null && field.value != _controller.text) {
      field.didChange(_controller.text);
    }
  }

  @override
  Widget build(BuildContext context) => RawFormField<String>(
    initialValue: widget.controller?.text ?? widget.initialValue ?? '',
    focusNode: _focus,
    validator: widget.validator,
    onSaved: widget.onSaved,
    autovalidateMode: widget.autovalidateMode,
    enabled: widget.enabled,
    builder: (field) {
      _field = field;
      // A reset puts the value back; the text follows it after the frame
      // (the text field can't change under its own build).
      final value = field.value ?? '';
      if (value != _controller.text) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && field.value == value) _controller.text = value;
        });
      }
      return MinimalTextField(
        controller: _controller,
        focusNode: _focus,
        labelText: widget.labelText,
        hintText: widget.hintText,
        helperText: widget.helperText,
        errorText: field.errorText,
        required: widget.required,
        icon: widget.icon,
        enabled: widget.enabled,
        readOnly: widget.readOnly,
        autofocus: widget.autofocus,
        obscureText: widget.obscureText,
        maxLines: widget.maxLines,
        minLines: widget.minLines,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        textCapitalization: widget.textCapitalization,
        autofillHints: widget.autofillHints,
        inputFormatters: widget.inputFormatters,
        mono: widget.mono,
        suffix: widget.suffix,
        clearable: widget.clearable,
        onChanged: widget.onChanged,
        onSubmitted: widget.onFieldSubmitted,
      );
    },
  );
}

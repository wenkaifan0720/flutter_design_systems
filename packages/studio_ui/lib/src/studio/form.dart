/// A form that checks its fields together, and a text field that takes part
/// in it, on ui_core's form.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'text_field.dart';

/// The fields of a form, checked together: a submit that finds a wrong field
/// shows every error, moves focus to the first one (scrolling it into view)
/// and tells a screen reader how many need attention; after that, the errors
/// follow the edits. Fields take part through Flutter's `FormField`: a
/// [StudioTextFormField] for text, and ui_core's `RawFormField` round any
/// other control (given the control's focus node, its `errorText` passed to
/// the control). [StudioForm.submit] runs the check from a key.
///
/// Lay the fields in one column, 16 apart, each the column's width:
/// `Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing:
/// StudioSpacing.regular, children: fields)`.
///
/// The behaviour is ui_core's (`RawForm`); it paints nothing.
///
/// ```dart
/// StudioForm(onSubmit: save, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: StudioSpacing.regular, children: [StudioTextFormField(labelText: 'Title', validator: (value) => (value ?? '').trim().isEmpty ? 'Enter a title' : null)]))
/// ```
class StudioForm extends StatelessWidget {
  /// A form round [child].
  const StudioForm({super.key, required this.child, this.onSubmit});

  /// The fields, laid out as the screen likes.
  final Widget child;

  /// Called by [submit] when every field is fine, after each field's
  /// `onSaved`.
  final VoidCallback? onSubmit;

  /// Checks the form round [context]: true, and [onSubmit] called, when
  /// every field is fine.
  static bool submit(BuildContext context) => RawForm.of(context).submit();

  /// Puts the form round [context] back to its first values.
  static void reset(BuildContext context) => RawForm.of(context).reset();

  @override
  Widget build(BuildContext context) =>
      RawForm(onSubmit: onSubmit, child: child);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ObjectFlagProperty<VoidCallback>.has('onSubmit', onSubmit));
  }
}

/// A [StudioTextField] that takes part in a [StudioForm], as Flutter's
/// `TextFormField` wraps its `TextField`: [validator] checks the text when
/// the form submits (and, after a failed submit, as the text is edited), its
/// message shows as the field's error (the red edge and the message under
/// it, read as the field's error), and [onSaved] gets the text when every
/// field is fine. A failed submit moves focus to the first field that is
/// wrong; [StudioForm.reset] puts the text back to its first value.
///
/// The text is [controller]'s when given, else the field keeps its own,
/// starting at [initialValue]. With a controller, the field's initial value
/// is the controller's text when it was last built; reset() restores it. To
/// empty a form, call reset() and then clear the controllers. The rest is
/// the text field's own.
///
/// ```dart
/// StudioTextFormField(labelText: 'Title', validator: (value) => (value ?? '').trim().isEmpty ? 'Enter a title' : null, onSaved: (value) => title = value!)
/// ```
class StudioTextFormField extends StatefulWidget {
  /// A text field that a [StudioForm] checks.
  const StudioTextFormField({
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
    this.prefixIcon,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.sentences,
    this.inputFormatters,
    this.autofillHints,
    this.maxLines = 1,
    this.minLines,
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

  /// What it holds, printed above the window.
  final String? labelText;

  /// What an empty field says.
  final String? hintText;

  /// A quiet line under the field.
  final String? helperText;

  /// A glyph at the window's start.
  final Widget? prefixIcon;

  /// Whether it takes text; off, it dims.
  final bool enabled;

  /// Whether the text can be selected and copied but not changed.
  final bool readOnly;

  /// Whether it takes focus when it first shows.
  final bool autofocus;

  /// Whether it hides what is typed.
  final bool obscureText;

  /// The keyboard it asks for.
  final TextInputType? keyboardType;

  /// The action the keyboard's enter key names.
  final TextInputAction? textInputAction;

  /// Which letters the keyboard capitalises.
  final TextCapitalization textCapitalization;

  /// What the field lets through as it is typed.
  final List<TextInputFormatter>? inputFormatters;

  /// What an autofill service may offer it.
  final Iterable<String>? autofillHints;

  /// The most lines it grows to.
  final int? maxLines;

  /// The fewest lines it stands.
  final int? minLines;

  @override
  State<StudioTextFormField> createState() => _StudioTextFormFieldState();

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
      ..add(FlagProperty('enabled', value: enabled, ifFalse: 'disabled'))
      ..add(FlagProperty('readOnly', value: readOnly, ifTrue: 'readOnly'))
      ..add(
        FlagProperty('obscureText', value: obscureText, ifTrue: 'obscured'),
      );
  }
}

class _StudioTextFormFieldState extends State<StudioTextFormField> {
  TextEditingController? _ownedController;
  FocusNode? _ownedFocus;
  FormFieldState<String>? _field;

  TextEditingController get _controller =>
      widget.controller ??
      (_ownedController ??= TextEditingController(text: widget.initialValue));

  FocusNode get _focus =>
      widget.focusNode ??
      (_ownedFocus ??= FocusNode(debugLabel: 'StudioTextFormField'));

  @override
  void initState() {
    super.initState();
    _controller.addListener(_textChanged);
  }

  @override
  void didUpdateWidget(StudioTextFormField old) {
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

  // The field's value follows the text, however it changed (typing, the app
  // setting the controller).
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
      return StudioTextField(
        controller: _controller,
        focusNode: _focus,
        labelText: widget.labelText,
        hintText: widget.hintText,
        helperText: widget.helperText,
        errorText: field.errorText,
        prefixIcon: widget.prefixIcon,
        onChanged: widget.onChanged,
        onSubmitted: widget.onFieldSubmitted,
        enabled: widget.enabled,
        readOnly: widget.readOnly,
        autofocus: widget.autofocus,
        obscureText: widget.obscureText,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        textCapitalization: widget.textCapitalization,
        inputFormatters: widget.inputFormatters,
        autofillHints: widget.autofillHints,
        maxLines: widget.maxLines,
        minLines: widget.minLines,
      );
    },
  );
}

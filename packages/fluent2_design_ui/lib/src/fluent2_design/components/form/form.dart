/// A form that validates its fields together, and a text field that takes
/// part in it, on ui_core's form.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../internal/measure.dart';
import '../field/field.dart';
import '../input/field_core.dart';
import '../input/input.dart';

/// The fields of a form, validated together: a submit that finds a wrong
/// field shows every error, moves focus to the first one (scrolling it into
/// view) and tells a screen reader how many need attention; after that, the
/// errors follow the edits. Fields take part through Flutter's `FormField`:
/// a [Fluent2TextFormField] for text, and ui_core's `RawFormField` round any
/// other control (given the control's focus node, its `errorText` passed to
/// a [Fluent2FormField] round the control as its `validationMessage`);
/// [Fluent2Form.submit] runs the check from a button.
///
/// In it a select, a combobox and a date field take the column's width, as
/// a text field does. Lay the fields in one column, 16 apart:
/// `Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing:
/// Fluent2Spacing.l, children: fields)`, the rhythm of Fluent's forms.
///
/// The behaviour is ui_core's (`RawForm`); it paints nothing.
///
/// ```dart
/// Fluent2Form(onSubmit: save, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: Fluent2Spacing.l, children: [Fluent2TextFormField(labelText: 'Title', required: true, validator: (value) => (value ?? '').trim().isEmpty ? 'Enter a title' : null)]))
/// ```
class Fluent2Form extends StatelessWidget {
  /// A form around [child].
  const Fluent2Form({super.key, required this.child, this.onSubmit});

  /// The fields, laid out as the screen likes.
  final Widget child;

  /// Called by [submit] when every field is fine, after each field's
  /// `onSaved`.
  final VoidCallback? onSubmit;

  /// Validates the form around [context]: true, and [onSubmit] called, when
  /// every field is fine.
  static bool submit(BuildContext context) => RawForm.of(context).submit();

  /// Puts the form around [context] back to its first values.
  static void reset(BuildContext context) => RawForm.of(context).reset();

  @override
  Widget build(BuildContext context) => RawForm(
    onSubmit: onSubmit,
    child: Fluent2FormColumn(child: child),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ObjectFlagProperty<VoidCallback>.has('onSubmit', onSubmit));
  }
}

/// A [Fluent2TextField] in its [Fluent2FormField] that takes part in a
/// [Fluent2Form], as Flutter's `TextFormField` wraps its `TextField`:
/// [validator] checks the text when the form submits (and after a failed
/// submit, as the text is edited), its message shows as the field's error
/// (the red stroke and the message under it, read as the field's hint), and
/// [onSaved] gets the text when every field is fine. A failed submit moves
/// focus to the first field that is wrong; [Fluent2Form.reset] puts the
/// text back to its first value.
///
/// The text is [controller]'s when given, else the field keeps its own,
/// starting at [initialValue]. With a controller, the field's initial value
/// is the controller's text when it was last built; reset() restores it. To
/// empty a form, call reset() and then clear the controllers.
/// [labelText], [required] and [helperText] are the field's words; the rest
/// is the text field's own.
///
/// ```dart
/// Fluent2TextFormField(labelText: 'Title', required: true, validator: (value) => (value ?? '').trim().isEmpty ? 'Enter a title' : null, onSaved: (value) => title = value!)
/// ```
class Fluent2TextFormField extends StatefulWidget {
  /// A text field that a [Fluent2Form] validates.
  const Fluent2TextFormField({
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
    this.prefixIcon,
    this.password = false,
    this.readOnly = false,
    this.autofocus = false,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.size = Fluent2InputSize.medium,
    this.appearance = Fluent2InputAppearance.outline,
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

  /// A quiet line under the field.
  final String? helperText;

  /// Whether it must be filled: the asterisk and "required" said after the
  /// name. The check itself is [validator]'s.
  final bool required;

  /// A glyph at the field's start.
  final IconData? prefixIcon;

  /// Whether it hides what is typed, with a button that shows it.
  final bool password;

  /// Whether the text can be selected and copied but not changed.
  final bool readOnly;

  /// Whether it takes focus when it first shows.
  final bool autofocus;

  /// The keyboard it asks for.
  final TextInputType? keyboardType;

  /// The action the keyboard's enter key names.
  final TextInputAction? textInputAction;

  /// What the field lets through as it is typed.
  final List<TextInputFormatter>? inputFormatters;

  /// Its height: small 24, medium 32, large 40.
  final Fluent2InputSize size;

  /// How its box is drawn.
  final Fluent2InputAppearance appearance;

  @override
  State<Fluent2TextFormField> createState() => _Fluent2TextFormFieldState();

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
        ObjectFlagProperty<ValueChanged<String>>.has('onChanged', onChanged),
      )
      ..add(
        ObjectFlagProperty<ValueChanged<String>>.has(
          'onFieldSubmitted',
          onFieldSubmitted,
        ),
      )
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
      ..add(FlagProperty('required', value: required, ifTrue: 'required'))
      ..add(IconDataProperty('prefixIcon', prefixIcon))
      ..add(FlagProperty('password', value: password, ifTrue: 'password'))
      ..add(FlagProperty('readOnly', value: readOnly, ifTrue: 'readOnly'))
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'))
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
        IterableProperty<TextInputFormatter>(
          'inputFormatters',
          inputFormatters,
          defaultValue: null,
        ),
      )
      ..add(
        EnumProperty<Fluent2InputSize>(
          'size',
          size,
          defaultValue: Fluent2InputSize.medium,
        ),
      )
      ..add(
        EnumProperty<Fluent2InputAppearance>(
          'appearance',
          appearance,
          defaultValue: Fluent2InputAppearance.outline,
        ),
      );
  }
}

class _Fluent2TextFormFieldState extends State<Fluent2TextFormField> {
  TextEditingController? _ownedController;
  FocusNode? _ownedFocus;
  FormFieldState<String>? _field;

  TextEditingController get _controller =>
      widget.controller ??
      (_ownedController ??= TextEditingController(text: widget.initialValue));

  FocusNode get _focus =>
      widget.focusNode ??
      (_ownedFocus ??= FocusNode(debugLabel: 'Fluent2TextFormField'));

  @override
  void initState() {
    super.initState();
    _controller.addListener(_textChanged);
  }

  @override
  void didUpdateWidget(Fluent2TextFormField old) {
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
  // app setting the controller).
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
      return Fluent2FormField(
        labelText: widget.labelText,
        required: widget.required,
        helperText: widget.helperText,
        validationMessage: field.errorText,
        size: widget.size,
        child: Fluent2TextField(
          controller: _controller,
          focusNode: _focus,
          hintText: widget.hintText,
          prefixIcon: widget.prefixIcon,
          password: widget.password,
          readOnly: widget.readOnly,
          autofocus: widget.autofocus,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          inputFormatters: widget.inputFormatters,
          size: widget.size,
          appearance: widget.appearance,
          onChanged: widget.onChanged,
          onSubmitted: widget.onFieldSubmitted,
        ),
      );
    },
  );
}

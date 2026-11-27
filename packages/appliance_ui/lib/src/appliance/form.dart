import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'text_field.dart';

/// The fields of a form, checked together, as Flutter's `Form` is: a
/// submit that finds a wrong field shows every error, moves focus to the
/// first one (scrolling it into view) and tells a screen reader how many
/// need attention; after that the errors follow the edits.
///
/// Fields take part through Flutter's `FormField`: an
/// [ApplianceTextFormField] for words, and ui_core's `RawFormField` round
/// any other control (a select, a date, a switch), its `errorText` on an
/// `ApplianceField` round the control and the control's focus node on
/// both. [ApplianceForm.submit] runs the check from a key.
///
/// Lay the fields in one column, each at the column's width, 16 apart:
/// `Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 16,
/// children: fields)`.
///
/// The behaviour is ui_core's (`RawForm`); it paints nothing.
///
/// ```dart
/// ApplianceForm(onSubmit: save, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 16, children: [ApplianceTextFormField(labelText: 'Name', validator: (value) => (value ?? '').trim().isEmpty ? 'Enter a name' : null)]))
/// ```
class ApplianceForm extends StatelessWidget {
  /// A form round [child].
  const ApplianceForm({super.key, required this.child, this.onSubmit});

  /// The fields, laid out as the page likes.
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

/// An [ApplianceTextField] that takes part in an [ApplianceForm], as
/// Flutter's `TextFormField` wraps its `TextField`: [validator] checks the
/// words when the form submits (and after a failed submit, as they are
/// edited), its message shows under the well beside the red lamp, and
/// [onSaved] gets the words when every field is fine. A failed submit moves
/// focus to the first field that is wrong; [ApplianceForm.reset] puts the
/// words back.
///
/// The words are [controller]'s when given, else the field keeps its own,
/// starting at [initialValue]. The rest is the text field's own.
///
/// ```dart
/// ApplianceTextFormField(labelText: 'Postcode', validator: (value) => (value ?? '').trim().isEmpty ? 'Enter a postcode' : null, onSaved: (value) => postcode = value!)
/// ```
class ApplianceTextFormField extends StatefulWidget {
  /// A text field that an [ApplianceForm] checks.
  const ApplianceTextFormField({
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
    this.leading,
    this.trailing,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.obscureText = false,
    this.autofillHints,
    this.inputFormatters,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.maxLines = 1,
    this.minLines,
  }) : assert(
         initialValue == null || controller == null,
         'the words come from initialValue or from controller, not both',
       );

  /// The words; null keeps its own, starting at [initialValue]. One you
  /// give is yours to dispose.
  final TextEditingController? controller;

  /// The first words of a field with no [controller].
  final String? initialValue;

  /// Its focus, which a failed submit moves here when this field is the
  /// first that is wrong; null keeps its own.
  final FocusNode? focusNode;

  /// Says what is wrong with the words, or null when they are fine.
  final FormFieldValidator<String>? validator;

  /// Gets the words when the form submits and every field is fine.
  final FormFieldSetter<String>? onSaved;

  /// Called as the words change.
  final ValueChanged<String>? onChanged;

  /// Called when the keyboard's action key submits the words.
  final ValueChanged<String>? onFieldSubmitted;

  /// When the field checks itself before a submit does; after a failed
  /// submit the form checks every field as it is edited, whatever this says.
  final AutovalidateMode autovalidateMode;

  /// The words over the well.
  final String? labelText;

  /// What the well says while it is empty: a format, never the label.
  final String? hintText;

  /// Help under the well; the error replaces it.
  final String? helperText;

  /// A glyph at the well's start.
  final Widget? leading;

  /// What stands at the well's end (a unit).
  final Widget? trailing;

  /// The keyboard to show.
  final TextInputType? keyboardType;

  /// The keyboard's action key.
  final TextInputAction? textInputAction;

  /// Whether the keyboard starts words or sentences in capitals.
  final TextCapitalization textCapitalization;

  /// Whether the words are hidden (a password).
  final bool obscureText;

  /// What the platform may fill in.
  final Iterable<String>? autofillHints;

  /// Formatters run on every change.
  final List<TextInputFormatter>? inputFormatters;

  /// Whether the field takes words.
  final bool enabled;

  /// Whether the words can be selected but not changed.
  final bool readOnly;

  /// Whether it takes focus when it first shows.
  final bool autofocus;

  /// The most lines; 1 centres one line in the well.
  final int? maxLines;

  /// The fewest lines the well shows.
  final int? minLines;

  @override
  State<ApplianceTextFormField> createState() => _ApplianceTextFormFieldState();

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
      ..add(DiagnosticsProperty<Widget>('leading', leading, defaultValue: null))
      ..add(
        DiagnosticsProperty<Widget>('trailing', trailing, defaultValue: null),
      )
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
      ..add(FlagProperty('obscureText', value: obscureText, ifTrue: 'obscured'))
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
      ..add(FlagProperty('enabled', value: enabled, ifFalse: 'disabled'))
      ..add(FlagProperty('readOnly', value: readOnly, ifTrue: 'readOnly'))
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'))
      ..add(IntProperty('maxLines', maxLines, defaultValue: 1))
      ..add(IntProperty('minLines', minLines, defaultValue: null));
  }
}

class _ApplianceTextFormFieldState extends State<ApplianceTextFormField> {
  TextEditingController? _ownedController;
  FocusNode? _ownedFocus;
  FormFieldState<String>? _field;

  TextEditingController get _controller =>
      widget.controller ??
      (_ownedController ??= TextEditingController(text: widget.initialValue));

  FocusNode get _focus =>
      widget.focusNode ??
      (_ownedFocus ??= FocusNode(debugLabel: 'ApplianceTextFormField'));

  @override
  void initState() {
    super.initState();
    _controller.addListener(_wordsChanged);
  }

  @override
  void didUpdateWidget(ApplianceTextFormField old) {
    super.didUpdateWidget(old);
    if (old.controller == widget.controller) return;
    (old.controller ?? _ownedController)?.removeListener(_wordsChanged);
    if (widget.controller != null) {
      _ownedController?.dispose();
      _ownedController = null;
    } else {
      _ownedController = TextEditingController.fromValue(old.controller?.value);
    }
    _controller.addListener(_wordsChanged);
    _field?.didChange(_controller.text);
  }

  @override
  void dispose() {
    _controller.removeListener(_wordsChanged);
    _ownedController?.dispose();
    _ownedFocus?.dispose();
    super.dispose();
  }

  // The field's value follows the words, however they changed (typing, the
  // app setting the controller).
  void _wordsChanged() {
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
      // A reset puts the value back; the words follow it after the frame
      // (the text field can't change under its own build).
      final value = field.value ?? '';
      if (value != _controller.text) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && field.value == value) _controller.text = value;
        });
      }
      return ApplianceTextField(
        controller: _controller,
        focusNode: _focus,
        labelText: widget.labelText,
        hintText: widget.hintText,
        helperText: widget.helperText,
        errorText: field.errorText,
        leading: widget.leading,
        trailing: widget.trailing,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        textCapitalization: widget.textCapitalization,
        obscureText: widget.obscureText,
        autofillHints: widget.autofillHints,
        inputFormatters: widget.inputFormatters,
        enabled: widget.enabled,
        readOnly: widget.readOnly,
        autofocus: widget.autofocus,
        maxLines: widget.maxLines,
        minLines: widget.minLines,
        onChanged: widget.onChanged,
        onSubmitted: widget.onFieldSubmitted,
      );
    },
  );
}

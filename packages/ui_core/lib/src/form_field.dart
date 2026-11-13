/// A form field and a form, headless.
///
/// [DesignField] wires a control to its label, help and error: a screen
/// reader hears the label as the control's name and the error and help as
/// its hint, with the control marked invalid; a tap on the label focuses
/// the control; the look gets whether anything in the field has focus.
///
/// [DesignFormField] and [DesignForm] add validation on the widgets layer's
/// [Form]: a submit that fails shows every error, moves focus to the first
/// field that is wrong, and tells a screen reader how many need attention.
library;

import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';

import 'internal/announce.dart';
import 'localizations.dart';

/// What a [DesignField]'s builder lays out.
@immutable
class DesignFieldParts {
  /// The parts of a field; [DesignField] makes these.
  const DesignFieldParts({
    required this.control,
    required this.labelText,
    required this.helperText,
    required this.errorText,
    required this.label,
    required this.helper,
    required this.error,
    required this.required,
    required this.enabled,
    required this.focused,
  });

  /// The control, carrying the field's name, hint and validity for a
  /// screen reader.
  final Widget control;

  /// The label's words.
  final String? labelText;

  /// The help's words.
  final String? helperText;

  /// The error's words, or null while the value is fine.
  final String? errorText;

  /// The label as text a screen reader skips (the control already says
  /// it), and a tap on it focuses the control. Style it with a
  /// [DefaultTextStyle]; a look that draws its own label from [labelText]
  /// wraps it in [ExcludeSemantics].
  final Widget? label;

  /// The help as text a screen reader skips.
  final Widget? helper;

  /// The error as text. The control's hint carries it; it is announced as
  /// it appears (a live region where the platform takes no announcements).
  /// Draw this one rather than your own from [errorText], or the
  /// announcement is lost.
  final Widget? error;

  /// Whether the field must be filled (draw its mark).
  final bool required;

  /// Whether the control takes input.
  final bool enabled;

  /// Whether anything in the field has focus.
  final bool focused;

  /// Whether the field shows an error.
  bool get hasError => errorText != null;
}

/// Lays out a field's parts.
typedef DesignFieldBuilder = Widget Function(
  BuildContext context,
  DesignFieldParts parts,
);

/// A control with its label, help and error.
///
/// With [mergeSemantics] (a single control: a text field, a select, a
/// switch) the control's node takes the label as its name and the error
/// and help as its hint; a group of controls (radios) sets it false and
/// the label names the group instead.
///
/// ```dart
/// DesignField(labelText: 'Email', builder: (context, parts) => Column(children: [?parts.label, parts.control]), child: const Text('field'))
/// ```
class DesignField extends StatefulWidget {
  /// A field around [child].
  const DesignField({
    super.key,
    required this.builder,
    required this.child,
    this.labelText,
    this.helperText,
    this.errorText,
    this.required = false,
    this.enabled = true,
    this.focusNode,
    this.mergeSemantics = true,
    this.requiredHint,
  });

  /// Lays out the parts.
  final DesignFieldBuilder builder;

  /// The control.
  final Widget child;

  /// What the field is: its label's words, and its control's name.
  final String? labelText;

  /// Help under it.
  final String? helperText;

  /// What is wrong, or null.
  final String? errorText;

  /// Whether it must be filled.
  final bool required;

  /// Whether the control takes input.
  final bool enabled;

  /// The control's focus: a tap on the label requests it. The caller's,
  /// who disposes it; the field only requests it.
  final FocusNode? focusNode;

  /// Whether the label, hint and validity join the control's own node.
  final bool mergeSemantics;

  /// Added to the name of a required field; null:
  /// [DesignLocalizations.requiredHint].
  final String? requiredHint;

  @override
  State<DesignField> createState() => _DesignFieldState();
}

class _DesignFieldState extends State<DesignField> {
  bool _focused = false;

  @override
  void didUpdateWidget(DesignField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // An error that appears or changes is announced (where the platform
    // takes announcements; elsewhere its line is a live region).
    final error = widget.errorText;
    if (error != null && error != oldWidget.errorText) {
      designAnnounce(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.labelText;
    final error = widget.errorText;
    final help = widget.helperText;
    final name = label == null
        ? null
        : widget.required
        ? '$label, ${widget.requiredHint ?? DesignLocalizations.of(context).requiredHint}'
        : label;
    final hint = [?error, ?help].join('. ');
    Widget control = Focus(
      canRequestFocus: false,
      skipTraversal: true,
      includeSemantics: false,
      onFocusChange: (focused) => setState(() => _focused = focused),
      child: widget.child,
    );
    if (widget.mergeSemantics) {
      control = MergeSemantics(
        child: Semantics(
          label: name,
          hint: hint.isEmpty ? null : hint,
          validationResult: error == null
              ? SemanticsValidationResult.none
              : SemanticsValidationResult.invalid,
          child: control,
        ),
      );
    }
    final node = widget.focusNode;
    final parts = DesignFieldParts(
      control: control,
      labelText: label,
      helperText: help,
      errorText: error,
      label: label == null
          ? null
          : ExcludeSemantics(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.enabled && node != null
                    ? node.requestFocus
                    : null,
                child: Text(label),
              ),
            ),
      helper: help == null ? null : ExcludeSemantics(child: Text(help)),
      // The control's hint carries the error. Where the platform takes
      // announcements the error is announced as it appears (didUpdateWidget)
      // and the line stays out of the tree, so it is not read twice; where
      // it takes none, the line is a live region (as Material's
      // InputDecorator's is).
      error: error == null
          ? null
          : MediaQuery.supportsAnnounceOf(context)
          ? ExcludeSemantics(child: Text(error))
          : Semantics(container: true, liveRegion: true, child: Text(error)),
      required: widget.required,
      enabled: widget.enabled,
      focused: _focused,
    );
    final field = widget.builder(context, parts);
    if (widget.mergeSemantics) return field;
    // A group: the label names the group, the error and help are its hint.
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: name,
      hint: hint.isEmpty ? null : hint,
      child: field,
    );
  }
}

/// A [FormField] whose control [DesignForm] can focus: give [focusNode]
/// to the control.
///
/// ```dart
/// DesignFormField<String>(validator: (value) => (value ?? '').isEmpty ? 'Required' : null, builder: (field) => Text(field.errorText ?? ''))
/// ```
class DesignFormField<T> extends FormField<T> {
  /// A form field validated by [validator], built by [builder].
  DesignFormField({
    super.key,
    required FormFieldBuilder<T> builder,
    this.focusNode,
    super.initialValue,
    super.validator,
    super.onSaved,
    super.autovalidateMode,
    super.enabled,
  }) : super(
         builder: (field) => _Registered(
           field: field,
           focusNode: focusNode,
           child: builder(field),
         ),
       );

  /// The control's focus, which a failed submit moves to the first field
  /// that is wrong. The caller's, who disposes it; the form only requests
  /// it.
  final FocusNode? focusNode;
}

class _Registered extends StatefulWidget {
  const _Registered({
    required this.field,
    required this.focusNode,
    required this.child,
  });

  final FormFieldState<Object?> field;
  final FocusNode? focusNode;
  final Widget child;

  @override
  State<_Registered> createState() => _RegisteredState();
}

class _RegisteredState extends State<_Registered> {
  DesignFormState? _form;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final form = DesignForm.maybeOf(context);
    if (form != _form) {
      _form?._fields.remove(this);
      _form = form;
      _form?._fields.add(this);
    }
  }

  @override
  void dispose() {
    _form?._fields.remove(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// A [Form] that, on a submit that fails, shows every error, moves focus to
/// the first field that is wrong (scrolling it into view) and tells a
/// screen reader how many fields need attention; after that, errors update
/// as the reader edits.
///
/// ```dart
/// DesignForm(onSubmit: () {}, child: const SizedBox())
/// ```
class DesignForm extends StatefulWidget {
  /// A form around [child].
  const DesignForm({
    super.key,
    required this.child,
    this.onSubmit,
    this.problemsMessage,
  });

  /// The fields, laid out by the look.
  final Widget child;

  /// Called by [DesignFormState.submit] when every field is fine, after
  /// each field's `onSaved`.
  final VoidCallback? onSubmit;

  /// What a screen reader hears when `count` fields are wrong; null:
  /// [DesignLocalizations.formProblemsMessage].
  final String Function(int count)? problemsMessage;

  /// The nearest form's state, or null.
  static DesignFormState? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_DesignFormScope>()?.state;

  /// The nearest form's state.
  static DesignFormState of(BuildContext context) {
    final state = maybeOf(context);
    assert(state != null, 'No DesignForm above this context.');
    return state!;
  }

  @override
  State<DesignForm> createState() => DesignFormState();
}

/// The state of a [DesignForm]: submit and reset it.
class DesignFormState extends State<DesignForm> {
  final _key = GlobalKey<FormState>();
  final List<_RegisteredState> _fields = [];
  AutovalidateMode _mode = AutovalidateMode.disabled;

  /// Validates every field; when all are fine saves them and calls
  /// [DesignForm.onSubmit] and returns true, else focuses the first that is
  /// wrong and returns false.
  bool submit() {
    final form = _key.currentState!;
    if (form.validate()) {
      form.save();
      widget.onSubmit?.call();
      return true;
    }
    setState(() => _mode = AutovalidateMode.onUserInteraction);
    final wrong = _fields.where((f) => f.widget.field.hasError).toList();
    if (wrong.isNotEmpty) {
      final first = wrong.first;
      first.widget.focusNode?.requestFocus();
      final target = first.context;
      if (Scrollable.maybeOf(target) != null) {
        Scrollable.ensureVisible(
          target,
          alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
        ).ignore();
      }
      designAnnounce(
        context,
        (widget.problemsMessage ??
            DesignLocalizations.of(context).formProblemsMessage)(wrong.length),
      );
    }
    return false;
  }

  /// Clears every field back to its initial value and hides the errors.
  void reset() {
    _key.currentState!.reset();
    setState(() => _mode = AutovalidateMode.disabled);
  }

  @override
  Widget build(BuildContext context) => _DesignFormScope(
    state: this,
    child: Form(key: _key, autovalidateMode: _mode, child: widget.child),
  );
}

class _DesignFormScope extends InheritedWidget {
  const _DesignFormScope({required this.state, required super.child});

  final DesignFormState state;

  @override
  bool updateShouldNotify(_DesignFormScope old) => state != old.state;
}

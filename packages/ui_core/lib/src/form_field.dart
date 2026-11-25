/// A form field and a form, headless.
///
/// [RawInputDecorator] wires a control to its label, help and error: a screen
/// reader hears the label as the control's name and the error and help as
/// its hint, with the control marked invalid; a tap on the label focuses
/// the control; the look gets whether anything in the field has focus.
///
/// [RawFormField] and [RawForm] add validation on the widgets layer's
/// [Form]: a submit that fails shows every error, moves focus to the first
/// field that is wrong, and tells a screen reader how many need attention.
///
/// Which one a control needs:
///
/// - [RawInputDecorator] alone, for a control whose label, help and error the app
///   sets itself (a settings switch, a search box): it carries the words and
///   their semantics, and validates nothing.
/// - A [RawFormField] round the [RawInputDecorator], for a value the form
///   checks: it registers with the [Form] above it, runs its validator and
///   hands its `errorText` to the [RawInputDecorator], whose control takes the
///   [RawFormField.focusNode].
/// - [RawForm] round the fields: it submits them, and on a submit that
///   fails focuses the first field that is wrong.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'internal/announce.dart';
import 'internal/field_words.dart';
import 'localizations.dart';
import 'semantics_proxy.dart';

/// What a [RawInputDecorator]'s builder lays out.
@immutable
class RawInputDecoratorDetails {
  /// The parts of a field; [RawInputDecorator] makes these.
  const RawInputDecoratorDetails({
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
    this.invalid = false,
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

  /// Whether the field's value is invalid: it has [errorText], or the
  /// decorator was told so with no words ([RawInputDecorator.invalid]).
  /// Paint the error state from this.
  final bool invalid;

  /// Whether the field shows an error.
  bool get hasError => errorText != null;
}

/// Lays out a field's parts.
typedef RawInputDecoratorBuilder = Widget Function(
  BuildContext context,
  RawInputDecoratorDetails parts,
);

/// A control with its label, help and error.
///
/// By default ([mergeSemantics] null) the field reads what its child brings
/// to the semantics tree. A child that holds one control (a text field, a
/// select, a switch, a slider) is one node, which takes the label as its
/// name and the error and help as its hint. A child that holds several (a
/// stepper's buttons and entry, segmented buttons, a wrap of chips, radios)
/// keeps each control's own node, so a tap through the semantics tree (a
/// screen reader's, or a click on the web with semantics on) reaches the
/// control under it; the label names them as a group. When the child
/// already says the label (a stepper named as its field, or a group that
/// names itself on its own node), the label is not added again, so it is
/// read once. ui_core's number field and tag input carry the label, error
/// and help on their text entry's own node, beside their step buttons and
/// tags, and the field's node says none of them.
///
/// A text entry keeps its node as controls come and go beside it (a clear
/// key that shows with the first letter): on the web that node is the
/// browser's input, and a new one loses the keys typed meanwhile. The entry
/// is the field's node, alone or beside controls with nodes of their own,
/// while nothing between them makes a node: a tap that focuses the entry
/// from anywhere on its line is left out of the semantics tree
/// (`GestureDetector.excludeFromSemantics`), as the gesture detector of
/// Flutter's own text field is. A press that stays in the tree gives the
/// entry a node of its own beside it. Alone, that entry is still merged
/// with the field's label and hint, so it is read as a named text field;
/// once a second control joins, it stands apart under the field's node,
/// and on the web it is then a new input.
///
/// ```dart
/// RawInputDecorator(labelText: 'Email', builder: (context, parts) => Column(children: [?parts.label, parts.control]), child: const Text('field'))
/// ```
class RawInputDecorator extends StatefulWidget {
  /// A field around [child].
  const RawInputDecorator({
    super.key,
    required this.builder,
    required this.child,
    this.labelText,
    this.helperText,
    this.errorText,
    this.required = false,
    this.enabled = true,
    this.focusNode,
    this.mergeSemantics,
    this.requiredHint,
    this.invalid = false,
  });

  /// Lays out the parts.
  final RawInputDecoratorBuilder builder;

  /// The control.
  final Widget child;

  /// What the field is: its label's words, and its control's name.
  final String? labelText;

  /// Help under it.
  final String? helperText;

  /// What is wrong, or null. A field with an error is invalid: a screen
  /// reader hears it so ([SemanticsValidationResult.invalid]), and the
  /// error's words are its hint.
  final String? errorText;

  /// Whether its value is invalid with no words to say why: a screen
  /// reader hears it invalid ([SemanticsValidationResult.invalid]), as it
  /// does a field with [errorText], and the builder's
  /// [RawInputDecoratorDetails.invalid] is true.
  final bool invalid;

  /// Whether it must be filled. Its node carries the required flag
  /// ([SemanticsProperties.isRequired]); where the platform says nothing
  /// of the flag, its name also ends with [requiredHint] (with no
  /// [labelText], its hint starts with them).
  final bool required;

  /// Whether the control takes input.
  final bool enabled;

  /// The control's focus: a tap on the label requests it. The caller's,
  /// who disposes it; the field only requests it.
  final FocusNode? focusNode;

  /// Whether the label, hint and validity join the control's own node:
  /// true always (one node for the whole child), false never (the label
  /// names the child as a group and each control keeps its node), null as
  /// the child's controls say (see [RawInputDecorator]).
  final bool? mergeSemantics;

  /// Added to the name of a required field where the platform says nothing
  /// of the required flag; null: [RawWidgetsLocalizations.requiredHint].
  /// A field with no [labelText] is named by what its control says (the
  /// words it draws, a semantic label): its hint starts with them, as it
  /// does where the control says the label itself.
  ///
  /// In Flutter 3.47 only the web reads the flag aloud (`aria-required`);
  /// Android, iOS, macOS, Windows and Linux carry it and say nothing. So
  /// the words go everywhere but the web, and on the web too unless the
  /// field's node is its text entry (one text field, alone or beside
  /// controls with nodes of their own), whose input the flag marks: a
  /// group, a select or a field that merges its whole child keeps them.
  final String? requiredHint;

  @override
  State<RawInputDecorator> createState() => _RawFieldState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        ObjectFlagProperty<RawInputDecoratorBuilder>.has('builder', builder),
      )
      ..add(StringProperty('labelText', labelText, defaultValue: null))
      ..add(StringProperty('helperText', helperText, defaultValue: null))
      ..add(StringProperty('errorText', errorText, defaultValue: null))
      ..add(
        FlagProperty(
          'required',
          value: required,
          ifTrue: 'required',
          defaultValue: false,
        ),
      )
      ..add(
        FlagProperty(
          'enabled',
          value: enabled,
          ifFalse: 'enabled: false',
          defaultValue: true,
        ),
      )
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<bool>(
          'mergeSemantics',
          mergeSemantics,
          defaultValue: null,
        ),
      )
      ..add(StringProperty('requiredHint', requiredHint, defaultValue: null))
      ..add(
        FlagProperty(
          'invalid',
          value: invalid,
          ifTrue: 'invalid',
          defaultValue: false,
        ),
      );
  }
}

class _RawFieldState extends State<RawInputDecorator> {
  bool _focused = false;

  @override
  void didUpdateWidget(RawInputDecorator oldWidget) {
    super.didUpdateWidget(oldWidget);
    // An error that appears or changes is announced (where the platform
    // takes announcements; elsewhere its line is a live region).
    final error = widget.errorText;
    if (error != null && error != oldWidget.errorText) {
      rawAnnounce(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.labelText;
    final error = widget.errorText;
    final help = widget.helperText;
    final needed = widget.required
        ? widget.requiredHint ??
              RawWidgetsLocalizations.of(context).requiredHint
        : null;
    final name = label == null
        ? null
        : needed == null
        ? label
        : '$label, $needed';
    final hint = [?error, ?help].join('. ');
    // A field with no label is named by what its control says (the words it
    // draws, a semantic label), which the field can't add to: a required
    // one says so first in its hint, as one whose control says its label
    // does.
    final told = [
      if (label == null) ?needed,
      if (hint.isNotEmpty) hint,
    ].join(', ');
    final invalid = error != null || widget.invalid;
    Widget control = Focus(
      canRequestFocus: false,
      skipTraversal: true,
      includeSemantics: false,
      onFocusChange: (focused) => setState(() => _focused = focused),
      child: widget.child,
    );
    final merge = widget.mergeSemantics;
    if (merge == null) {
      control = _FieldSemantics(
        label: name,
        words: label,
        needed: needed,
        hint: hint.isEmpty ? null : hint,
        invalid: invalid,
        textDirection: Directionality.maybeOf(context),
        child: RawFieldWords(
          name: name,
          hint: told.isEmpty ? null : told,
          invalid: invalid,
          required: widget.required,
          child: control,
        ),
      );
    } else if (merge) {
      control = MergeSemantics(
        child: Semantics(
          label: name,
          hint: told.isEmpty ? null : told,
          isRequired: widget.required ? true : null,
          validationResult: invalid
              ? SemanticsValidationResult.invalid
              : SemanticsValidationResult.none,
          child: control,
        ),
      );
    }
    final node = widget.focusNode;
    final parts = RawInputDecoratorDetails(
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
      invalid: invalid,
    );
    final field = widget.builder(context, parts);
    if (merge != false) return field;
    // A group: the label names the group, the error and help are its hint.
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: name,
      hint: told.isEmpty ? null : told,
      isRequired: widget.required ? true : null,
      child: field,
    );
  }
}

/// A [FormField] whose control [RawForm] can focus: give [focusNode]
/// to the control.
///
/// It validates and registers; it draws no label, help or error and adds
/// nothing to the semantics tree. Build a [RawInputDecorator] in [builder] and
/// pass it the field's `errorText`, so the error is shown and read as the
/// control's hint.
///
/// ```dart
/// RawFormField<String>(validator: (value) => (value ?? '').isEmpty ? 'Required' : null, builder: (field) => Text(field.errorText ?? ''))
/// ```
class RawFormField<T> extends FormField<T> {
  /// A form field validated by [validator], built by [builder].
  RawFormField({
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
  RawFormState? _form;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final form = RawForm.maybeOf(context);
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
/// RawForm(onSubmit: () {}, child: const SizedBox())
/// ```
class RawForm extends StatefulWidget {
  /// A form around [child].
  const RawForm({
    super.key,
    required this.child,
    this.onSubmit,
    this.problemsMessage,
  });

  /// The fields, laid out by the look.
  final Widget child;

  /// Called by [RawFormState.submit] when every field is fine, after
  /// each field's `onSaved`.
  final VoidCallback? onSubmit;

  /// What a screen reader hears when `count` fields are wrong; null:
  /// [RawWidgetsLocalizations.formProblemsMessage].
  final String Function(int count)? problemsMessage;

  /// The nearest form's state, or null.
  static RawFormState? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_RawFormScope>()?.state;

  /// The nearest form's state.
  static RawFormState of(BuildContext context) {
    final state = maybeOf(context);
    assert(state != null, 'No RawForm above this context.');
    return state!;
  }

  @override
  State<RawForm> createState() => RawFormState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(ObjectFlagProperty<VoidCallback>.has('onSubmit', onSubmit))
      ..add(
        ObjectFlagProperty<String Function(int count)>.has(
          'problemsMessage',
          problemsMessage,
        ),
      );
  }
}

/// The state of a [RawForm]: submit and reset it.
class RawFormState extends State<RawForm> {
  final _key = GlobalKey<FormState>();
  final List<_RegisteredState> _fields = [];
  AutovalidateMode _mode = AutovalidateMode.disabled;

  /// Validates every field; when all are fine saves them and calls
  /// [RawForm.onSubmit] and returns true, else focuses the first that is
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
      rawAnnounce(
        context,
        (widget.problemsMessage ??
            RawWidgetsLocalizations.of(context)
                .formProblemsMessage)(wrong.length),
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
  Widget build(BuildContext context) => _RawFormScope(
    state: this,
    child: Form(key: _key, autovalidateMode: _mode, child: widget.child),
  );
}

class _RawFormScope extends InheritedWidget {
  const _RawFormScope({required this.state, required super.child});

  final RawFormState state;

  @override
  bool updateShouldNotify(_RawFormScope old) => state != old.state;
}

// The field's own node, shaped by the controls under it: one control is
// merged with the label, hint and validity; several keep their own nodes
// under a node that names them, unless one of them is a text entry with no
// node of its own and the others each have theirs: then the entry's node
// is the field's (Material's text field with a suffix button), the others
// in it. A text entry that stands in a node of its own (a press round it
// besides its own, or a node between) is merged alone, as any lone
// control, so its node holds the label, the hint and the entry, as a text
// field's must for a screen reader to name it. Beside other controls it
// is never the field's node: it stands apart under a node that names the
// group, so a control that comes beside it (a clear key with the first
// letter) moves it to a node of its own, which on the web is a new input.
// A look keeps the entry's node by leaving its line's tap out of the
// semantics tree. A control of ui_core's that carries the field's words on its own
// node (a number field's entry, a tag input's) leaves the field's node
// saying nothing.
// The label is left out when a control already says it (a button's name
// aside); a required field then says it is required first in its hint,
// unless the control says that too, as one with no label does: what its
// control says names it.
class _FieldSemantics extends SingleChildRenderObjectWidget {
  const _FieldSemantics({
    required this.label,
    required this.words,
    required this.needed,
    required this.hint,
    required this.invalid,
    required this.textDirection,
    required super.child,
  });

  final String? label;
  final String? words;
  final String? needed;
  final String? hint;
  final bool invalid;
  final TextDirection? textDirection;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderFieldSemantics(label, words, needed, hint, invalid, textDirection);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderFieldSemantics renderObject,
  ) {
    renderObject
      ..label = label
      ..words = words
      ..needed = needed
      ..hint = hint
      ..invalid = invalid
      ..wordsDirection = textDirection
      // A rebuild may change what the child says (a control named as the
      // field, or no longer) and leave the field's size as it was: read the
      // child again in the layout that follows, once it is built.
      ..markNeedsLayout();
  }
}

class _RenderFieldSemantics extends RenderSemanticsProxy
    implements RawFieldSays {
  _RenderFieldSemantics(
    this._label,
    this._words,
    this._needed,
    this._hint,
    this._invalid,
    this._wordsDirection,
  );

  String? _label;
  set label(String? value) {
    if (value == _label) return;
    _label = value;
    markNeedsSemanticsUpdate();
  }

  String? _words;
  set words(String? value) {
    if (value == _words) return;
    _words = value;
    markNeedsSemanticsUpdate();
  }

  // The words a required field adds to its name; null when it is not
  // required.
  String? _needed;
  set needed(String? value) {
    if (value == _needed) return;
    _needed = value;
    markNeedsSemanticsUpdate();
  }

  String? _hint;
  set hint(String? value) {
    if (value == _hint) return;
    _hint = value;
    markNeedsSemanticsUpdate();
  }

  bool _invalid;
  set invalid(bool value) {
    if (value == _invalid) return;
    _invalid = value;
    markNeedsSemanticsUpdate();
  }

  // The direction of the words it adds (its label and hint).
  TextDirection? _wordsDirection;
  set wordsDirection(TextDirection? value) {
    if (value == _wordsDirection) return;
    _wordsDirection = value;
    markNeedsSemanticsUpdate();
  }

  // The controls under the field as last described, to describe it again
  // when a layout or a rebuild changes them.
  _FieldShape? _shape;

  // What it says on its node, for a node over it that carries the same
  // words (a tag input's entry) not to say them again.
  @override
  String? get saysLabel => (_shape?.carried ?? false) ? null : _label;

  @override
  String? get saysHint => (_shape?.carried ?? false) ? null : _hint;

  @override
  void performLayout() {
    super.performLayout();
    if (_shape != null && _read() != _shape) markNeedsSemanticsUpdate();
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    final shape = _shape = _read();
    config.isSemanticBoundary = true;
    if (shape.carried) {
      config.explicitChildNodes = true;
      return;
    }
    if (shape.single) {
      config.isMergingSemanticsOfDescendants = true;
    } else if (!shape.entry) {
      config.explicitChildNodes = true;
    }
    final required = _needed != null;
    // The node is the field's text entry, whose input the web marks
    // required from the flag: the flag says it, not the words.
    final flagged =
        required && RawRequiredFlag.heard && (shape.lone || shape.entry);
    final label = flagged ? _words : _label;
    if (label != null && !shape.said) config.label = label;
    final hint = [
      if ((_label == null || (shape.said && !shape.saidWhole)) && !flagged)
        ?_needed,
      ?_hint,
    ];
    if (hint.isNotEmpty) config.hint = hint.join(', ');
    if (config.label.isNotEmpty || config.hint.isNotEmpty) {
      config.textDirection = _wordsDirection;
    }
    config.validationResult = _invalid
        ? SemanticsValidationResult.invalid
        : SemanticsValidationResult.none;
    if (required) config.isRequired = true;
  }

  // Whether the child holds one control at most; whether anything it
  // brings to the semantics tree already says the label's words (a control,
  // or a group's own node that names it: a line of its own that is the
  // words, or starts with them and a comma, as a required field's name
  // does; a button's name is the button's, not the field's), and whether it
  // says the whole name, a required field's included; whether its one text
  // entry joins the field's node; and whether a control of ui_core's
  // carries the field's words.
  _FieldShape _read() {
    var controls = 0;
    var entries = 0;
    var joins = false;
    var apart = true;
    var alone = false;
    var carried = false;
    final words = _words?.trim().toLowerCase() ?? '';
    final name = _label?.trim().toLowerCase() ?? '';
    bool says(String text, String said) => text
        .split('\n')
        .map((line) => line.trim().toLowerCase())
        .any((line) => line == said || line.startsWith('$said,'));
    ({bool said, bool saidWhole}) hears(RenderObject child) {
      if (words.isEmpty) return (said: false, saidWhole: false);
      var said = false;
      var whole = false;
      void heard(String text) {
        if (says(text, words)) said = true;
        if (name.isNotEmpty && says(text, name)) whole = true;
      }

      void hear(RenderObject n) {
        if ((said && whole) || (n is RenderExcludeSemantics && n.excluding)) {
          return;
        }
        if (n is RenderSemanticsAnnotations && n.properties.button == true) {
          return;
        }
        if (n is RenderSemanticsAnnotations) {
          heard(n.properties.label ?? '');
          if (n.excludeSemantics) return;
        }
        if (n is RenderParagraph) {
          heard(n.text.toPlainText());
        }
        n.visitChildrenForSemantics(hear);
      }

      child.visitChildrenForSemantics(hear);
      return (said: said, saidWhole: whole);
    }

    bool holdsEntry(RenderObject n) {
      if (n is RenderEditable) return true;
      var found = false;
      n.visitChildrenForSemantics((c) => found = found || holdsEntry(c));
      return found;
    }

    // Counts the controls under [n]: those that hold no control of their
    // own (a text field's tap wraps its entry: one control), and an
    // adjustment round an entry (a stepper's value round the field it
    // types in), which a tap on its parts would not reach once merged
    // with them.
    int leaves(RenderObject n) {
      if (n is RenderExcludeSemantics && n.excluding) return 0;
      if (n is RenderEditable) return 1;
      var below = 0;
      if (!(n is RenderSemanticsAnnotations && n.excludeSemantics)) {
        n.visitChildrenForSemantics((c) => below += leaves(c));
      }
      if (below == 0) return _acts(n) ? 1 : 0;
      final adjusts =
          n is RenderSemanticsAnnotations &&
          (n.properties.onIncrease != null ||
              n.properties.onDecrease != null) &&
          holdsEntry(n);
      return below + (adjusts ? 1 : 0);
    }

    // Whether a text entry under [n] reaches the field's node: no node
    // of its own stands between them.
    bool reaches(RenderObject n) {
      if (_bounds(n)) return false;
      if (n is RenderEditable) return true;
      var found = false;
      n.visitChildrenForSemantics((c) => found = found || reaches(c));
      return found;
    }

    // The presses from [n] down to the text entry under it.
    int pressesTo(RenderObject n) {
      if (n is RenderEditable) return 0;
      var below = 0;
      n.visitChildrenForSemantics((c) {
        if (below == 0 && holdsEntry(c)) below = pressesTo(c);
      });
      return below + (_pressOnly(n) ? 1 : 0);
    }

    // [presses]: the presses round [n] that hold a text entry and are not
    // controls of their own (a line's tap that focuses its entry, as a text
    // field's own is): the controls under one are counted one by one.
    void visit(RenderObject n, bool below, int presses) {
      if (n is RenderExcludeSemantics && n.excluding) return;
      // A control of ui_core's marks its entry's node as the one that
      // carries the words, above or below the presses round it (a tag
      // input's entry, a number field's).
      if (n is RenderFieldWordsCarried) carried = true;
      final bounded = below || _bounds(n);
      if (_pressOnly(n) && holdsEntry(n)) {
        carried = carried || _carries(n);
        n.visitChildrenForSemantics((c) => visit(c, bounded, presses + 1));
        return;
      }
      if (n is RenderEditable || _acts(n)) {
        final count = math.max(1, leaves(n));
        controls += count;
        if (count == 1 && holdsEntry(n)) {
          entries++;
          joins = !bounded && reaches(n);
          // Two presses on one entry are two nodes: its own stands apart,
          // as one behind a node between does.
          alone = alone || !joins || presses + pressesTo(n) > 1;
        } else if (!bounded) {
          apart = false;
        }
        carried = carried || _carries(n);
        return;
      }
      n.visitChildrenForSemantics((c) => visit(c, bounded, presses));
    }

    visitChildrenForSemantics((c) => visit(c, false, 0));
    final (:said, :saidWhole) = hears(this);
    return (
      // A lone entry is merged even when it stands apart: its node must
      // hold the field's name, which a screen reader reads with the entry
      // only from the entry's own node.
      single: controls <= 1,
      said: said,
      saidWhole: saidWhole,
      entry: controls > 1 && entries == 1 && joins && apart && !alone,
      lone: controls == 1 && entries == 1,
      carried: carried,
    );
  }

  // Whether [n] is, or holds, a control of ui_core's that carries the
  // field's words.
  static bool _carries(RenderObject n) {
    if (n is RenderExcludeSemantics && n.excluding) return false;
    if (n is RenderFieldWordsCarried) return true;
    var found = false;
    n.visitChildrenForSemantics((c) => found = found || _carries(c));
    return found;
  }

  // Whether [n] is a press and nothing else: a tap or a long press, with no
  // role, state or value of its own (a line's tap, a text field's own).
  static bool _pressOnly(RenderObject n) {
    if (n is RenderSemanticsGestureHandler) {
      return (n.onTap != null || n.onLongPress != null) &&
          n.onHorizontalDragUpdate == null &&
          n.onVerticalDragUpdate == null;
    }
    if (n is RenderSemanticsAnnotations && !n.excludeSemantics) {
      final p = n.properties;
      return (p.onTap != null || p.onLongPress != null) &&
          p.button != true &&
          p.link != true &&
          p.textField != true &&
          p.slider != true &&
          p.toggled == null &&
          p.checked == null &&
          p.inMutuallyExclusiveGroup != true &&
          p.onIncrease == null &&
          p.onDecrease == null &&
          (p.value?.isEmpty ?? true);
    }
    return false;
  }

  // Whether [n] makes a node of its own, which nothing under it merges past.
  static bool _bounds(RenderObject n) =>
      n is RenderMergeSemantics ||
      (n is RenderSemanticsAnnotations &&
          (n.container || n.explicitChildNodes));

  // A node a press, a drag or an adjustment acts on, or one with a value
  // or a state of its own.
  static bool _acts(RenderObject n) {
    if (n is RenderSemanticsGestureHandler) {
      return n.onTap != null ||
          n.onLongPress != null ||
          n.onHorizontalDragUpdate != null ||
          n.onVerticalDragUpdate != null;
    }
    if (n is RenderSemanticsAnnotations) {
      final p = n.properties;
      return p.button == true ||
          p.link == true ||
          p.textField == true ||
          p.slider == true ||
          p.toggled != null ||
          p.checked != null ||
          p.inMutuallyExclusiveGroup == true ||
          p.onTap != null ||
          p.onLongPress != null ||
          p.onIncrease != null ||
          p.onDecrease != null ||
          (p.value?.isNotEmpty ?? false);
    }
    return false;
  }
}

// What a field's child brings to the semantics tree.
typedef _FieldShape = ({
  bool single,
  bool said,
  bool saidWhole,
  bool entry,
  // One control, and it is a text entry: the field's node is the entry.
  bool lone,
  bool carried,
});

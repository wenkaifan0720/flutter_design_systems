import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart'
    show Material, MaterialType, TextField;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../internal/cap_center.dart';
import '../../internal/field_frame.dart';
import '../../internal/styled.dart';
import '../../style.dart';
import '../../theme.dart';
import '../../internal/entry_open.dart';

/// A field written on a rule, as a ledger is: its [labelText] in the small
/// capitals over the line, the words typed in the medium at 16 (its [hintText]
/// in the third ink while it is empty), the ink rule under it (2 thick
/// while it has focus), its [helperText] or its [errorText] under the rule. No box:
/// the rule is the field. 48 tall at [LedgerDensity.standard], each density
/// step 4 less, the words centred in it on every platform.
///
/// [prefix] stands before the words in the serif (a currency sign) and makes
/// the field a sum's: its words are typed in the serif at 22 too, as Ledger
/// sets money ([sumOf]), sign and figures left to right in either direction,
/// across its column as every field is; [trailing] after them (a clear or a reveal
/// button). [enabled] false holds it in the third ink on the light rule.
/// Validate in a `RawForm` with a `RawFormField` around it and pass its
/// error here.
///
/// It is not a form field itself: a Material `Form`'s `reset()` and
/// `validate()` pass it by. In a `RawFormField`, the form keeps the field's
/// error and the [controller] keeps the words: `reset()` takes the error away
/// and leaves the controller's text as it is. To empty a form, call
/// `reset()` and then clear the controllers (`controller.clear()`).
///
/// The [controller] and [focusNode] are the caller's to dispose when given;
/// when not, the field makes its own and disposes them.
///
/// ```dart
/// LedgerTextField(labelText: 'Name', hintText: 'As it is on the account', controller: name)
/// ```
///
/// ```dart
/// LedgerTextField(labelText: 'Amount', prefix: r'$', hintText: '0.00', keyboardType: const TextInputType.numberWithOptions(decimal: true))
/// ```
///
/// ```dart
/// LedgerTextField(labelText: 'Email', errorText: 'Enter an email address', onChanged: (v) {})
/// ```
class LedgerTextField extends StatefulWidget {
  /// A field named [labelText] on its rule.
  const LedgerTextField({
    this.controller,
    this.focusNode,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.prefix,
    this.trailing,
    this.isRequired = false,
    this.enabled = true,
    this.readOnly = false,
    this.obscureText = false,
    this.autofocus = false,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.autofillHints,
    this.maxLines = 1,
    this.minLines,
    this.onChanged,
    this.onSubmitted,
    this.onEditingComplete,
    this.style,
    super.key,
  }) : assert(maxLines == null || maxLines > 0),
       assert(minLines == null || minLines > 0);

  /// The words; the field's own when null.
  final TextEditingController? controller;

  /// Its focus; the field's own when null.
  final FocusNode? focusNode;

  /// What the field is, over the line in the small capitals; its spoken
  /// name.
  final String? labelText;

  /// Shown while it is empty, in the third ink.
  final String? hintText;

  /// Help under the rule.
  final String? helperText;

  /// What is wrong, under the rule in the danger red; null while it is
  /// fine.
  final String? errorText;

  /// Before the words, in the serif: a currency sign, a unit. A field with
  /// one is a sum's, its words typed in the serif ([sumOf]).
  final String? prefix;

  /// After the words: a small button (a clear, a reveal).
  final Widget? trailing;

  /// Whether it must be filled: its label carries a mark, and a screen
  /// reader says so.
  final bool isRequired;

  /// Whether it takes input.
  final bool enabled;

  /// Whether its words can be selected but not changed.
  final bool readOnly;

  /// Whether the words are hidden (a password).
  final bool obscureText;

  /// {@macro ledger.autofocus}
  final bool autofocus;

  /// The keyboard the field asks for.
  final TextInputType? keyboardType;

  /// The keyboard's act key.
  final TextInputAction? textInputAction;

  /// How the keyboard capitalizes the words.
  final TextCapitalization textCapitalization;

  /// Formatters run over the words as they are typed.
  final List<TextInputFormatter>? inputFormatters;

  /// What the platform's autofill may fill in.
  final Iterable<String>? autofillHints;

  /// How many lines it grows to; 1 keeps it to one, null lets it grow.
  final int? maxLines;

  /// How many lines it stands at the least.
  final int? minLines;

  /// Called with the words as they are typed.
  final ValueChanged<String>? onChanged;

  /// Called with the words when the keyboard submits them; the field gives
  /// up the focus. A field that keeps the focus after the act key (one
  /// adding another) takes it in [onEditingComplete] instead, never both:
  /// told of a submit while it keeps the focus, a field restarts its text
  /// input, and a browser's then takes no typing.
  final ValueChanged<String>? onSubmitted;

  /// Called when the keyboard's act key is pressed, in place of the field
  /// giving up the focus; see [onSubmitted].
  final VoidCallback? onEditingComplete;

  /// The field's look, over `components.textField`. It reads `edge` (the
  /// rule's ink), `fill` (a paper behind the written line), `padding` (round
  /// the line), `foreground` (the words' ink) and `textStyle` (the words');
  /// a field is `focused`, `error` or `disabled` as it stands.
  final LedgerStyle? style;

  /// The words' style: the medium at 16 on a 24 line.
  static TextStyle wordsOf(LedgerThemeData t) => t.rowTitle
      .sized(16)
      .line(24)
      .copyWith(leadingDistribution: TextLeadingDistribution.even);

  /// A sum's words, and its prefix's: the serif at 22 on the same 24 line.
  static TextStyle sumOf(LedgerThemeData t) => t.figureSmall
      .sized(22)
      .line(24)
      .tracked(0)
      .copyWith(leadingDistribution: TextLeadingDistribution.even);

  /// The line's height at [t]'s density: 48 at standard.
  static double heightOf(LedgerThemeData t) => t.density.height(_height);

  static const double _height = 48;

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
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(StringProperty('labelText', labelText, defaultValue: null))
      ..add(StringProperty('hintText', hintText, defaultValue: null))
      ..add(StringProperty('helperText', helperText, defaultValue: null))
      ..add(StringProperty('errorText', errorText, defaultValue: null))
      ..add(StringProperty('prefix', prefix, defaultValue: null))
      ..add(FlagProperty('isRequired', value: isRequired, ifTrue: 'isRequired'))
      ..add(FlagProperty('enabled', value: enabled, ifTrue: 'enabled'))
      ..add(FlagProperty('readOnly', value: readOnly, ifTrue: 'readOnly'))
      ..add(
        FlagProperty('obscureText', value: obscureText, ifTrue: 'obscureText'),
      )
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'))
      ..add(
        DiagnosticsProperty<TextInputType>(
          'keyboardType',
          keyboardType,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<TextInputAction>(
          'textInputAction',
          textInputAction,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<TextCapitalization>(
          'textCapitalization',
          textCapitalization,
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
        IterableProperty<String>(
          'autofillHints',
          autofillHints,
          defaultValue: null,
        ),
      )
      ..add(IntProperty('maxLines', maxLines, defaultValue: null))
      ..add(IntProperty('minLines', minLines, defaultValue: null))
      ..add(
        ObjectFlagProperty<ValueChanged<String>>.has('onChanged', onChanged),
      )
      ..add(
        ObjectFlagProperty<ValueChanged<String>>.has(
          'onSubmitted',
          onSubmitted,
        ),
      )
      ..add(
        ObjectFlagProperty<VoidCallback>.has(
          'onEditingComplete',
          onEditingComplete,
        ),
      )
      ..add(
        DiagnosticsProperty<LedgerStyle>('style', style, defaultValue: null),
      );
  }

  @override
  State<LedgerTextField> createState() => _LedgerTextFieldState();
}

class _LedgerTextFieldState extends State<LedgerTextField> {
  TextEditingController? _ownController;
  FocusNode? _ownFocus;

  TextEditingController get _controller =>
      widget.controller ?? (_ownController ??= TextEditingController());
  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode());

  // The node the field listens to for its focus, to come into view whole.
  late FocusNode _listened;

  @override
  void initState() {
    super.initState();
    _listened = _focus..addListener(_focusChanged);
  }

  // A field that takes the focus comes into view whole, its label and its
  // problem with it, before Flutter's text field shows its caret and 20
  // round it (a Ledger field's label stands above those 20): a form's
  // first problem, focused after its check, is read with its name.
  void _focusChanged() {
    if (!_listened.hasFocus) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_listened.hasFocus) return;
      final box = context.findRenderObject();
      if (box is! RenderBox || !box.hasSize) return;
      // With the room a form's column keeps under the bar round it.
      box.showOnScreen(
        rect: Rect.fromLTRB(
          0,
          -_revealRoom,
          box.size.width,
          box.size.height + _revealRoom,
        ),
      );
    });
  }

  @override
  void didUpdateWidget(LedgerTextField old) {
    super.didUpdateWidget(old);
    if (!identical(_focus, _listened)) {
      _listened.removeListener(_focusChanged);
      _listened = _focus..addListener(_focusChanged);
    }
    // Flutter's TextField's swap: the words carry over when the caller
    // takes its controller back, and the input's own goes when one comes.
    if (widget.controller == null && old.controller != null) {
      _ownController = TextEditingController.fromValue(old.controller!.value);
    } else if (widget.controller != null && old.controller == null) {
      _ownController?.dispose();
      _ownController = null;
    }
  }

  @override
  void dispose() {
    _listened.removeListener(_focusChanged);
    _ownController?.dispose();
    _ownFocus?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final enabled = widget.enabled;
    final words = widget.prefix == null
        ? LedgerTextField.wordsOf(t)
        : LedgerTextField.sumOf(t);
    final so = LedgerStyleOf(
      [widget.style, t.components.textField],
      {
        if (!enabled) WidgetState.disabled,
        if (widget.errorText != null) WidgetState.error,
      },
    );
    final ink = so.foreground ?? (enabled ? t.textPrimary : t.textTertiary);
    final oneLine = widget.maxLines == 1 || widget.obscureText;
    final editable = Material(
      type: MaterialType.transparency,
      child: TextField(
        controller: _controller,
        focusNode: _focus,
        decoration: null,
        style: so.words(words, ink),
        cursorColor: t.textPrimary,
        cursorWidth: 1.5,
        enabled: enabled,
        readOnly: widget.readOnly,
        obscureText: widget.obscureText,
        autofocus: widget.autofocus,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        textCapitalization: widget.textCapitalization,
        inputFormatters: widget.inputFormatters,
        autofillHints: widget.autofillHints,
        maxLines: widget.obscureText ? 1 : widget.maxLines,
        minLines: widget.minLines,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        onEditingComplete: widget.onEditingComplete,
      ),
    );
    final hint = widget.hintText;
    final box = RawTextEntryBox(
      minHeight: LedgerTextField.heightOf(t),
      controller: hint == null ? null : _controller,
      hint: hint == null
          ? null
          : Text(
              hint,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              // A hint is words: the third ink (4.6:1), lighter in weight
              // than the words typed; the faint ink is for rules only.
              style: words
                  .copyWith(fontWeight: FontWeight.w400)
                  .colored(t.textTertiary),
            ),
      maxLines: widget.maxLines,
      child: editable,
    );
    // One line: its capitals on the box's middle, as every face's label
    // (the typed words and the hint share their baseline, so either reads).
    final entry = oneLine ? ledgerCapCenter(words, box) : box;
    final prefix = widget.prefix;
    final trailing = widget.trailing;
    final across = oneLine
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.start;
    final hinted = hint == null ? entry : Semantics(hint: hint, child: entry);
    // A combobox's entry says whether its list stands open.
    final open = LedgerEntryOpen.maybeOf(context);
    final typed = open == null
        ? hinted
        : Semantics(expanded: open, child: hinted);
    final line = Row(
      crossAxisAlignment: across,
      spacing: _gap,
      children: [
        Expanded(
          child: prefix == null
              ? typed
              // A sum reads left to right in either direction, its sign
              // before the figures.
              : Directionality(
                  textDirection: TextDirection.ltr,
                  child: Row(
                    crossAxisAlignment: across,
                    spacing: _gap,
                    children: [
                      ExcludeSemantics(
                        child: ledgerCapCenter(
                          LedgerTextField.sumOf(t),
                          Text(
                            prefix,
                            style: LedgerTextField.sumOf(t)
                                .colored(t.textSecondary),
                          ),
                        ),
                      ),
                      Expanded(child: typed),
                    ],
                  ),
                ),
        ),
        ?trailing,
      ],
    );
    final field = RawInputDecorator(
      labelText: widget.labelText,
      helperText: widget.helperText,
      errorText: widget.errorText,
      required: widget.isRequired,
      enabled: enabled,
      focusNode: _focus,
      builder: (context, parts) => LedgerFieldFrame(
        parts: parts,
        focusNode: _focus,
        labelCursor: SystemMouseCursors.text,
        line: parts.control,
        style: widget.style,
      ),
      // The whole written line is the field's: a tap on its sign or beside
      // its words focuses it as a tap on them does (its trailing act, a
      // press of its own, keeps its taps). The tap is for a pointer only,
      // as Flutter's text field's own gesture detector is: a screen reader
      // reaches the entry and the trailing act by their own nodes, and a
      // tap node round both would split the entry from the field's name.
      child: TextFieldTapRegion(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          excludeFromSemantics: true,
          onTap: enabled ? _focus.requestFocus : null,
          child: MouseRegion(
            cursor: enabled ? SystemMouseCursors.text : MouseCursor.defer,
            child: line,
          ),
        ),
      ),
    );
    // Every field, a sum's too, takes its column: one width in a form.
    return field;
  }

  static const double _gap = 6;

  /// The room kept round a field that comes into view on taking the focus.
  static const double _revealRoom = 24;
}

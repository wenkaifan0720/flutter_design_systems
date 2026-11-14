import 'package:material_ui/material_ui.dart'
    show Material, MaterialType, TextField;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../internal/cap_center.dart';
import '../../internal/field_frame.dart';
import '../../theme.dart';

/// A field written on a rule, as a ledger is: its [label] in the small
/// capitals over the line, the words typed in the medium at 16 (its [hint]
/// in the third ink while it is empty), the ink rule under it (2 thick
/// while it has focus), its [helper] or its [error] under the rule. No box:
/// the rule is the field. 48 tall at [LedgerDensity.standard], each density
/// step 4 less, the words centred in it on every platform.
///
/// [prefix] stands before the words in the serif (a currency sign) and makes
/// the field a sum's: its words are typed in the serif at 22 too, as Ledger
/// sets money ([sumOf]), sign and figures left to right in either direction,
/// and from 600 it stands at a short entry's measure
/// ([LedgerLayout.fieldMeasure]); [trailing] after them (a clear or a reveal
/// button). [enabled] false holds it in the third ink on the light rule.
/// Validate in a `DesignForm` with a `DesignFormField` around it and pass its
/// error here.
///
/// The [controller] and [focusNode] are the caller's to dispose when given;
/// when not, the field makes its own and disposes them.
///
/// ```dart
/// LedgerTextField(label: 'Name', hint: 'As it is on the account', controller: name)
/// ```
///
/// ```dart
/// LedgerTextField(label: 'Amount', prefix: r'$', hint: '0.00', keyboardType: const TextInputType.numberWithOptions(decimal: true))
/// ```
///
/// ```dart
/// LedgerTextField(label: 'Email', error: 'Enter an email address', onChanged: (v) {})
/// ```
class LedgerTextField extends StatefulWidget {
  /// A field named [label] on its rule.
  const LedgerTextField({
    this.controller,
    this.focusNode,
    this.label,
    this.hint,
    this.helper,
    this.error,
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
    super.key,
  });

  /// The words; the field's own when null.
  final TextEditingController? controller;

  /// Its focus; the field's own when null.
  final FocusNode? focusNode;

  /// What the field is, over the line in the small capitals; its spoken
  /// name.
  final String? label;

  /// Shown while it is empty, in the third ink.
  final String? hint;

  /// Help under the rule.
  final String? helper;

  /// What is wrong, under the rule in the danger red; null while it is
  /// fine.
  final String? error;

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

  /// Whether it takes focus when it first appears.
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

  /// Called with the words when the keyboard submits them.
  final ValueChanged<String>? onSubmitted;

  /// Called when the keyboard's act key is pressed.
  final VoidCallback? onEditingComplete;

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
  State<LedgerTextField> createState() => _LedgerTextFieldState();
}

class _LedgerTextFieldState extends State<LedgerTextField> {
  TextEditingController? _ownController;
  FocusNode? _ownFocus;

  TextEditingController get _controller =>
      widget.controller ?? (_ownController ??= TextEditingController());
  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode());

  @override
  void didUpdateWidget(LedgerTextField old) {
    super.didUpdateWidget(old);
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
    final ink = enabled ? t.textPrimary : t.textTertiary;
    final oneLine = widget.maxLines == 1 || widget.obscureText;
    final editable = Material(
      type: MaterialType.transparency,
      child: TextField(
        controller: _controller,
        focusNode: _focus,
        decoration: null,
        style: words.colored(ink),
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
    final hint = widget.hint;
    final box = DesignTextEntryBox(
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
    final typed = hint == null ? entry : Semantics(hint: hint, child: entry);
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
    final field = DesignField(
      labelText: widget.label,
      helperText: widget.helper,
      errorText: widget.error,
      required: widget.isRequired,
      enabled: enabled,
      focusNode: _focus,
      builder: (context, parts) => LedgerFieldFrame(
        parts: parts,
        focusNode: _focus,
        line: parts.control,
      ),
      child: line,
    );
    // A sum is a short entry: at its measure from 600, as a select is; free
    // words keep their column.
    return prefix == null ? field : LedgerLayout.measured(context, field);
  }

  static const double _gap = 6;
}

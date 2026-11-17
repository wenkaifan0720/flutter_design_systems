/// A field with its add-ons, each in a ruled column, in Ledger's hand.
library;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:ui_core/ui_core.dart';

import '../../internal/cap_center.dart';
import '../../internal/face.dart';
import '../../internal/field_frame.dart';
import '../../theme.dart';
import '../text-field/text_field.dart';

/// A field and its add-ons as one control (a web address's `https://` and
/// `.ledger.app`, a weight's `kg`, a code's copy button): each add-on in a
/// column of its own on the field's one rule, a hairline between it and the
/// words, as a ledger rules its columns. The add-on words stand in the mono
/// in the second ink, the third while the field cannot be used; [action]
/// (a Ledger icon button, say) closes the line at the reading end. A tap on
/// the frame or a word add-on puts the caret in the words. Its label, its
/// help or error, its focus rule as every Ledger field's.
///
/// ```dart
/// LedgerInputGroup(label: 'Shop address', before: 'https://', after: '.ledger.app', hint: 'your-shop')
/// ```
class LedgerInputGroup extends StatefulWidget {
  /// A field named [label] between its add-ons.
  const LedgerInputGroup({
    this.label,
    this.hint,
    this.helper,
    this.error,
    this.before,
    this.after,
    this.action,
    this.controller,
    this.focusNode,
    this.keyboardType,
    this.inputFormatters,
    this.isRequired = false,
    this.enabled = true,
    this.onChanged,
    super.key,
  });

  /// The small capitals over the line.
  final String? label;

  /// Words in the third ink while it is empty.
  final String? hint;

  /// The note under the rule.
  final String? helper;

  /// What is wrong, in the vermilion; it replaces [helper].
  final String? error;

  /// The add-on before the words.
  final String? before;

  /// The add-on after the words.
  final String? after;

  /// A control closing the line (a copy or a clear button).
  final Widget? action;

  /// Its words; null: its own.
  final TextEditingController? controller;

  /// {@macro ledger.focusNode}
  final FocusNode? focusNode;

  /// The keyboard it asks for.
  final TextInputType? keyboardType;

  /// What it lets be typed.
  final List<TextInputFormatter>? inputFormatters;

  /// Whether the label carries the required mark.
  final bool isRequired;

  /// Whether it takes words.
  final bool enabled;

  /// Called as the words change.
  final ValueChanged<String>? onChanged;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label, defaultValue: null))
      ..add(StringProperty('hint', hint, defaultValue: null))
      ..add(StringProperty('helper', helper, defaultValue: null))
      ..add(StringProperty('error', error, defaultValue: null))
      ..add(StringProperty('before', before, defaultValue: null))
      ..add(StringProperty('after', after, defaultValue: null))
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
      ..add(
        DiagnosticsProperty<TextInputType>(
          'keyboardType',
          keyboardType,
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
      ..add(FlagProperty('isRequired', value: isRequired, ifTrue: 'isRequired'))
      ..add(FlagProperty('enabled', value: enabled, ifTrue: 'enabled'))
      ..add(
        ObjectFlagProperty<ValueChanged<String>>.has('onChanged', onChanged),
      );
  }

  @override
  State<LedgerInputGroup> createState() => _LedgerInputGroupState();
}

class _LedgerInputGroupState extends State<LedgerInputGroup> {
  TextEditingController? _ownController;
  FocusNode? _ownFocus;

  TextEditingController get _controller =>
      widget.controller ?? (_ownController ??= TextEditingController());
  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode());

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
    final words = LedgerTextField.wordsOf(t);
    final height = LedgerTextField.heightOf(t);
    final hint = widget.hint;
    final box = DesignTextEntryBox(
      minHeight: height,
      controller: hint == null ? null : _controller,
      hint: hint == null
          ? null
          : Text(
              hint,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: words
                  .copyWith(fontWeight: FontWeight.w400)
                  .colored(t.textTertiary),
            ),
      child: Material(
        type: MaterialType.transparency,
        child: TextField(
          controller: _controller,
          focusNode: _focus,
          decoration: null,
          style: words.colored(enabled ? t.textPrimary : t.textTertiary),
          cursorColor: t.textPrimary,
          cursorWidth: 1.5,
          enabled: enabled,
          maxLines: 1,
          keyboardType: widget.keyboardType,
          inputFormatters: widget.inputFormatters,
          onChanged: widget.onChanged,
        ),
      ),
    );
    final entry = ledgerCapCenter(words, box);
    final typed = hint == null ? entry : Semantics(hint: hint, child: entry);
    // The add-ons' words: the mono at 14, upright. Each takes at most
    // [_share] of the line, set smaller past it (at a large text size on a
    // phone), never cut, so the typed words keep their room.
    final mono = t.amount.copyWith(fontWeight: FontWeight.w400).tracked(0);
    Widget addOn(String text, Color ink, double most) => ExcludeSemantics(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: most),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: ledgerCapCenter(
            mono,
            Text(text, maxLines: 1, softWrap: false, style: mono.colored(ink)),
          ),
        ),
      ),
    );
    final group = DesignInputGroup(
      focusNode: _focus,
      enabled: enabled,
      isError: widget.error != null,
      builder: (context, states, field) => LedgerFace(
        style: LedgerFaceStyle(
          ink: !enabled
              ? t.textTertiary
              : states.contains(WidgetState.focused) ||
                    states.contains(WidgetState.hovered)
              ? t.textPrimary
              : t.textSecondary,
        ),
        builder: (context, s, field) => LayoutBuilder(
          builder: (context, box) => IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.before case final before?) ...[
                  addOn(before, s.ink, box.maxWidth * _share),
                  const SizedBox(width: _pad),
                  _Column(ink: t.hairline),
                  const SizedBox(width: _pad),
                ],
                Expanded(child: field!),
                if (widget.after case final after?) ...[
                  const SizedBox(width: _pad),
                  _Column(ink: t.hairline),
                  const SizedBox(width: _pad),
                  addOn(after, s.ink, box.maxWidth * _share),
                ],
                if (widget.action case final action?) ...[
                  const SizedBox(width: _pad),
                  _Column(ink: t.hairline),
                  const SizedBox(width: _actionGap),
                  Center(widthFactor: 1, child: action),
                ],
              ],
            ),
          ),
        ),
        child: field,
      ),
      child: typed,
    );
    return DesignField(
      labelText: widget.label,
      helperText: widget.helper,
      errorText: widget.error,
      required: widget.isRequired,
      enabled: enabled,
      focusNode: _focus,
      builder: (context, parts) => LedgerFieldFrame(
        parts: parts,
        focusNode: _focus,
        labelCursor: SystemMouseCursors.text,
        line: parts.control,
      ),
      child: group,
    );
  }

  // An add-on 10 off its column rule; an action 4 past its rule.
  static const double _pad = 10;
  static const double _actionGap = 4;

  /// The most of the line an add-on takes before it is set smaller.
  static const double _share = .3;
}

/// A column's hairline, standing a third of the line's height clear of the
/// rule under it, as a ledger's column rules stop short of the total's.
class _Column extends StatelessWidget {
  const _Column({required this.ink});

  final Color ink;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: _clear),
    child: SizedBox(width: 1, child: ColoredBox(color: ink)),
  );

  static const double _clear = 12;
}

/// A note's words written on ruled paper, in Ledger's hand.
library;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:ui_core/ui_core.dart';

import '../../internal/face.dart';
import '../../internal/field_frame.dart';
import '../../internal/styled.dart';
import '../../style.dart';
import '../../theme.dart';
import '../text-field/text_field.dart';

/// Longer words (a memo on a payment, a note to a budget) written on
/// ruled paper: each line of the words stands on a faint rule a line apart,
/// [minLines] of them before anything is typed and more as the words run
/// on, up to [maxLines] before it scrolls; the last rule is the field's
/// ink rule, doubled while it has focus, as on every Ledger field. Its
/// [labelText] in the small capitals over the paper, its [helperText] or [errorText]
/// under. With a [maxLength] the count of what is left stands in the
/// paper's foot at the reading end, in the mono, turning vermilion once it
/// is spent. The rules grow with the text size, so large text still
/// writes on them.
///
/// ```dart
/// LedgerTextArea(labelText: 'Memo', hintText: 'What it was for', maxLength: 280)
/// ```
class LedgerTextArea extends StatefulWidget {
  /// A ruled area named [labelText].
  const LedgerTextArea({
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.controller,
    this.focusNode,
    this.minLines = 4,
    this.maxLines = 8,
    this.maxLength,
    this.isRequired = false,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.onChanged,
    this.style,
    super.key,
  }) : assert(minLines > 0),
       assert(maxLines == null || maxLines >= minLines),
       assert(maxLength == null || maxLength > 0);

  /// The small capitals over the paper.
  final String? labelText;

  /// Words in the third ink while it is empty.
  final String? hintText;

  /// The note under the paper.
  final String? helperText;

  /// What is wrong, in the vermilion; it replaces [helperText].
  final String? errorText;

  /// Its words; null: its own.
  final TextEditingController? controller;

  /// {@macro ledger.focusNode}
  final FocusNode? focusNode;

  /// The rules on the paper before anything is typed.
  final int minLines;

  /// The lines it grows to before it scrolls; null grows without end.
  final int? maxLines;

  /// The most characters it takes; its count shows when set.
  final int? maxLength;

  /// Whether the label carries the required mark.
  final bool isRequired;

  /// Whether it takes words.
  final bool enabled;

  /// Whether its words can be read and selected but not changed.
  final bool readOnly;

  /// {@macro ledger.autofocus}
  final bool autofocus;

  /// Called as the words change.
  final ValueChanged<String>? onChanged;

  /// The field's look, over `components.textField`. It reads `edge` (the
  /// rule's ink), `fill` (a paper behind the written line), `padding` (round
  /// the line), `foreground` (the words' ink) and `textStyle` (the words');
  /// a field is `focused`, `error` or `disabled` as it stands.
  final LedgerStyle? style;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('labelText', labelText, defaultValue: null))
      ..add(StringProperty('hintText', hintText, defaultValue: null))
      ..add(StringProperty('helperText', helperText, defaultValue: null))
      ..add(StringProperty('errorText', errorText, defaultValue: null))
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
      ..add(IntProperty('minLines', minLines))
      ..add(IntProperty('maxLines', maxLines, defaultValue: null))
      ..add(IntProperty('maxLength', maxLength, defaultValue: null))
      ..add(FlagProperty('isRequired', value: isRequired, ifTrue: 'isRequired'))
      ..add(FlagProperty('enabled', value: enabled, ifTrue: 'enabled'))
      ..add(FlagProperty('readOnly', value: readOnly, ifTrue: 'readOnly'))
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'))
      ..add(
        ObjectFlagProperty<ValueChanged<String>>.has('onChanged', onChanged),
      )
      ..add(
        DiagnosticsProperty<LedgerStyle>('style', style, defaultValue: null),
      );
  }

  @override
  State<LedgerTextArea> createState() => _LedgerTextAreaState();
}

class _LedgerTextAreaState extends State<LedgerTextArea> {
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
    final words = LedgerTextField.wordsOf(t).line(_lineHeight);
    // A rule a line apart: the line as the text size sets it.
    final step =
        MediaQuery.textScalerOf(context).scale(words.fontSize!) * words.height!;
    final maxLength = widget.maxLength;
    final count = maxLength == null
        ? null
        : ValueListenableBuilder<TextEditingValue>(
            valueListenable: _controller,
            builder: (context, value, _) {
              final left = maxLength - value.text.characters.length;
              return LedgerFace(
                style: LedgerFaceStyle(
                  ink: left <= 0 ? t.danger : t.textTertiary,
                ),
                builder: (context, s, _) => Text(
                  '$left',
                  style: t.meta.colored(s.ink),
                  // Material's counted words ("1 character remaining"),
                  // in the app's language with its plural forms; LedgerHost
                  // gives them where the app does not.
                  semanticsLabel: MaterialLocalizations.of(context)
                      .remainingTextFieldCharacterCount(left),
                ),
              );
            },
          );
    final so = LedgerStyleOf(
      [widget.style, t.components.textField],
      {
        if (!enabled) WidgetState.disabled,
        if (widget.errorText != null) WidgetState.error,
      },
    );
    final editable = Material(
      type: MaterialType.transparency,
      child: TextField(
        controller: _controller,
        focusNode: _focus,
        decoration: null,
        style: so.words(
          words,
          so.foreground ?? (enabled ? t.textPrimary : t.textTertiary),
        ),
        cursorColor: t.textPrimary,
        cursorWidth: 1.5,
        enabled: enabled,
        readOnly: widget.readOnly,
        autofocus: widget.autofocus,
        keyboardType: TextInputType.multiline,
        textCapitalization: TextCapitalization.sentences,
        minLines: widget.minLines,
        maxLines: widget.maxLines,
        inputFormatters: [
          if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
        ],
        onChanged: widget.onChanged,
      ),
    );
    final hint = widget.hintText;
    // The box holds one line at least; the editable's own minLines rules
    // the rest. A taller box would stand the first line where a single line
    // would (centred in it), half a box down, and the rule a line under the
    // paper's top would run through the words.
    final box = RawTextEntryBox(
      minHeight: step,
      controller: hint == null ? null : _controller,
      hint: hint == null
          ? null
          : Text(
              hint,
              style: words
                  .copyWith(fontWeight: FontWeight.w400)
                  .colored(t.textTertiary),
            ),
      maxLines: widget.maxLines,
      child: editable,
    );
    final paper = CustomPaint(
      painter: _Rules(
        step: step,
        color: enabled ? t.hairline : t.hairline.withValues(alpha: .5),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: count == null ? 0 : _countRoom),
        child: hint == null ? box : Semantics(hint: hint, child: box),
      ),
    );
    final ruled = count == null
        ? paper
        : Stack(
            children: [
              paper,
              PositionedDirectional(end: 0, bottom: _countFoot, child: count),
            ],
          );
    // The whole ruled paper takes a tap, its count's room under the words
    // too: a ground behind it focuses the memo, saying nothing of its own,
    // so what a screen reader outlines is what a finger reaches.
    final line = GestureDetector(
      behavior: HitTestBehavior.opaque,
      excludeFromSemantics: true,
      onTap: enabled ? _focus.requestFocus : null,
      child: ruled,
    );
    return RawInputDecorator(
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
      child: line,
    );
  }

  // Words at 16 on a 32 line, so each stands clear on its rule; the count
  // 20 under the last line, 6 over the foot.
  static const double _lineHeight = 32;
  static const double _countRoom = 20;
  static const double _countFoot = 6;
}

/// The paper's faint rules, one under each line.
class _Rules extends CustomPainter {
  _Rules({required this.step, required this.color});

  final double step;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    // The last line's rule is the field's own ink rule, painted over.
    for (var y = step; y < size.height - 1; y += step) {
      final at = y.floorToDouble() - .5;
      canvas.drawLine(Offset(0, at), Offset(size.width, at), paint);
    }
  }

  @override
  bool shouldRepaint(_Rules old) => old.step != step || old.color != color;
}

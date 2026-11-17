/// A one-time code in Ledger's hand: its figures each written on a short
/// rule, over ui_core's [DesignOtpField].
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../chrome_metrics.dart';
import '../../internal/face.dart';
import '../../internal/field_frame.dart';
import '../../theme.dart';

/// A one-time code (a bank's six figures, a card's PIN): each figure in the
/// serif on its own short rule, the code's halves parted by a wider gap,
/// its [label] in the small capitals over them and its [helper] or [error]
/// under, as every Ledger field. The slot the next figure goes in rules the
/// accountant's double rule while the field has focus, drawn in from the
/// reading start as a pen draws it, with the caret standing on it; an
/// error rules every slot in the vermilion. One input under the slots, so
/// a pasted code or an offered one fills them all, the figures read left
/// to right in either direction, and a screen reader hears one field.
/// [onCompleted] runs when the last slot fills. [obscureText] writes a
/// bead for each figure (a PIN).
///
/// ```dart
/// LedgerCodeField(label: 'Code from your bank', length: 6, onCompleted: (code) {})
/// ```
class LedgerCodeField extends StatefulWidget {
  /// A code field of [length] slots.
  const LedgerCodeField({
    this.length = 6,
    this.label,
    this.helper,
    this.error,
    this.controller,
    this.focusNode,
    this.enabled = true,
    this.obscureText = false,
    this.autofocus = false,
    this.semanticLabel,
    this.onChanged,
    this.onCompleted,
    super.key,
  }) : assert(length >= 1);

  /// How many figures.
  final int length;

  /// The small capitals over the slots.
  final String? label;

  /// The note under the slots.
  final String? helper;

  /// What is wrong, in the vermilion; it replaces [helper].
  final String? error;

  /// The code; null: the field's own.
  final DesignOtpController? controller;

  /// The field's focus; null: the field's own.
  final FocusNode? focusNode;

  /// Whether it takes figures.
  final bool enabled;

  /// Whether each figure is written as a bead.
  final bool obscureText;

  /// {@macro ledger.autofocus}
  final bool autofocus;

  /// What a screen reader calls it; null: the [label], else "One-time code".
  final String? semanticLabel;

  /// Called as the code changes.
  final ValueChanged<String>? onChanged;

  /// Called with the code when its last slot fills.
  final ValueChanged<String>? onCompleted;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('length', length))
      ..add(StringProperty('label', label, defaultValue: null))
      ..add(StringProperty('helper', helper, defaultValue: null))
      ..add(StringProperty('error', error, defaultValue: null))
      ..add(
        DiagnosticsProperty<DesignOtpController>(
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
      ..add(FlagProperty('enabled', value: enabled, ifTrue: 'enabled'))
      ..add(
        FlagProperty('obscureText', value: obscureText, ifTrue: 'obscureText'),
      )
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'))
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null))
      ..add(
        ObjectFlagProperty<ValueChanged<String>>.has('onChanged', onChanged),
      )
      ..add(
        ObjectFlagProperty<ValueChanged<String>>.has(
          'onCompleted',
          onCompleted,
        ),
      );
  }

  @override
  State<LedgerCodeField> createState() => _LedgerCodeFieldState();
}

class _LedgerCodeFieldState extends State<LedgerCodeField> {
  FocusNode? _ownFocus;

  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode());

  @override
  void dispose() {
    _ownFocus?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final figure = t.figureSmall
        .sized(_figure)
        .line(_line)
        .copyWith(leadingDistribution: TextLeadingDistribution.even);
    final half = widget.length > 4 && widget.length.isEven
        ? widget.length ~/ 2
        : null;
    final field = DesignOtpField(
      length: widget.length,
      controller: widget.controller,
      focusNode: _focus,
      enabled: widget.enabled,
      isError: widget.error != null,
      obscureText: widget.obscureText,
      autofocus: widget.autofocus,
      semanticLabel: widget.semanticLabel ?? widget.label ?? 'One-time code',
      onChanged: widget.onChanged,
      onCompleted: widget.onCompleted,
      layoutBuilder: (context, slots) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (i, slot) in slots.indexed) ...[
            if (i > 0) SizedBox(width: i == half ? _halfGap : _gap),
            slot,
          ],
        ],
      ),
      slotBuilder: (context, slot) {
        final ink = !slot.enabled
            ? t.border
            : slot.isError
            ? t.danger
            : slot.active && slot.focused
            ? t.textPrimary
            : t.headRule;
        final shown = slot.obscured && slot.character.isNotEmpty
            ? '•'
            : slot.character;
        return SizedBox(
          width: _slot,
          height: _height,
          child: LedgerFace(
            style: LedgerFaceStyle(ink: ink),
            duration: LedgerMotion.base,
            builder: (context, s, _) => Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  shown,
                  style: figure.colored(
                    slot.enabled ? t.textPrimary : t.textTertiary,
                  ),
                ),
                // The caret on the slot the next figure goes in.
                if (slot.active && slot.focused && slot.character.isEmpty)
                  Container(width: _caret, height: _line, color: t.textPrimary),
                PositionedDirectional(
                  start: 0,
                  end: 0,
                  bottom: 0,
                  height: 1,
                  child: ColoredBox(color: s.ink),
                ),
                // The double rule under the slot it writes in, drawn in.
                LedgerEase(
                  value: slot.active && slot.focused ? 1 : 0,
                  duration: LedgerMotion.base,
                  builder: (context, drawn, _) => PositionedDirectional(
                    start: 0,
                    end: 0,
                    bottom: 1 + LedgerChromeMetrics.focusGap,
                    height: 1,
                    child: FractionallySizedBox(
                      alignment: AlignmentDirectional.centerStart,
                      widthFactor: drawn.clamp(0.0, 1.0),
                      child: ColoredBox(color: s.ink),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    return DesignField(
      labelText: widget.label,
      helperText: widget.helper,
      errorText: widget.error,
      enabled: widget.enabled,
      focusNode: _focus,
      builder: (context, parts) => LedgerFieldFrame(
        parts: parts,
        focusNode: _focus,
        labelCursor: SystemMouseCursors.text,
        ruled: false,
        // The cells at the line's start: the field's node is their width, the
        // box a tap reaches.
        line: Align(
          alignment: AlignmentDirectional.centerStart,
          child: parts.control,
        ),
      ),
      child: field,
    );
  }

  // Each slot 40 wide and 52 tall, 8 apart (20 between a code's halves);
  // its figure the serif at 28 on a 36 line; the caret 1.5.
  static const double _slot = 40;
  static const double _height = 52;
  static const double _gap = LedgerSpacing.s8;
  static const double _halfGap = LedgerSpacing.s20;
  static const double _figure = 28;
  static const double _line = 36;
  static const double _caret = 1.5;
}

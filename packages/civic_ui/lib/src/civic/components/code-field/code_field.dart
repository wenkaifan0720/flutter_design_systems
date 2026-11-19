import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../internal/field_frame.dart';
import '../../material.dart';
import '../../theme.dart';

// A code's caller builds its controller and reads the code.
export 'package:ui_core/ui_core.dart' show DesignOtpController;

/// A code sent to someone (by text message, by email) typed back: one well,
/// as wide as the code, its figures in the mono face spread one to a
/// place, a short rule under each place still to fill. One box, not one
/// per figure: it takes a paste and a phone's offer of the code from a
/// message, and a screen reader hears one field.
///
/// [onCompleted] fires once the code is whole; [onChanged] at every change.
/// The keys and the edit menu are the platform's.
///
/// Reads [CivicStyle]'s fill, foreground and edge by state: its `style:`,
/// then [CivicThemeData.textFieldStyle]. The well's edge, its focus and the
/// rules under the places are the look's.
///
/// ```dart
/// CivicCodeField(
///   labelText: 'Security code',
///   helperText: 'We sent a 6 digit code to 07700 900 123.',
///   onCompleted: (code) => confirm(code),
/// )
/// ```
class CivicCodeField extends StatefulWidget {
  /// A code field.
  const CivicCodeField({
    super.key,
    this.length = 6,
    this.controller,
    this.focusNode,
    this.labelText,
    this.helperText,
    this.errorText,
    this.onChanged,
    this.onCompleted,
    this.onSubmitted,
    this.enabled = true,
    this.autofocus = false,
    this.obscureText = false,
    this.keyboardType = TextInputType.number,
    this.inputFormatters = const [],
    this.style,
  }) : assert(length > 0);

  /// How many characters the code has; a [controller]'s length wins.
  final int length;

  /// Holds the code, when the caller does; the caller disposes it.
  final DesignOtpController? controller;

  /// {@macro civic.focusNode}
  final FocusNode? focusNode;

  /// What the code is.
  final String? labelText;

  /// Where it was sent, and how long it lasts.
  final String? helperText;

  /// What to fix; null while the code is fine.
  final String? errorText;

  /// Called with the code as it changes.
  final ValueChanged<String>? onChanged;

  /// Called once each time the code becomes whole.
  final ValueChanged<String>? onCompleted;

  /// Called with the code when the keyboard's action key is pressed.
  final ValueChanged<String>? onSubmitted;

  /// Whether it takes input.
  final bool enabled;

  /// {@macro civic.autofocus}
  final bool autofocus;

  /// Whether the figures are hidden (a PIN).
  final bool obscureText;

  /// The keyboard the platform shows: figures by default.
  final TextInputType keyboardType;

  /// The caller's formatters (upper-casing letters, say).
  final List<TextInputFormatter> inputFormatters;

  /// Overrides for the well's look.
  final CivicStyle? style;

  @override
  State<CivicCodeField> createState() => _CivicCodeFieldState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('length', length))
      ..add(StringProperty('labelText', labelText, defaultValue: null))
      ..add(StringProperty('errorText', errorText, defaultValue: null))
      ..add(FlagProperty('enabled', value: enabled, ifFalse: 'disabled'))
      ..add(FlagProperty('obscureText', value: obscureText, ifTrue: 'hidden'))
      ..add(
        DiagnosticsProperty<CivicStyle>('style', style, defaultValue: null),
      );
  }
}

class _CivicCodeFieldState extends State<CivicCodeField> {
  FocusNode? _own;
  FocusNode get _focus => widget.focusNode ?? (_own ??= FocusNode());
  bool _hovered = false;

  @override
  void dispose() {
    _own?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final text = context.civicText;
    final hasError = widget.errorText != null;
    final field = MouseRegion(
      cursor: widget.enabled ? SystemMouseCursors.text : MouseCursor.defer,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: ListenableBuilder(
        listenable: _focus,
        builder: (context, _) {
          final states = {
            if (_focus.hasFocus) WidgetState.focused,
            if (_hovered) WidgetState.hovered,
            if (!widget.enabled) WidgetState.disabled,
            if (hasError) WidgetState.error,
          };
          final so = DesignStyleOf([widget.style, t.textFieldStyle], states);
          final figures = text.code.copyWith(
            fontSize: text.headingM.fontSize,
            height: 1.2,
            color:
                so.foreground ??
                (widget.enabled ? t.textPrimary : t.textDisabled),
          );
          return DesignOtpField(
            length: widget.length,
            controller: widget.controller,
            focusNode: _focus,
            autofocus: widget.autofocus,
            enabled: widget.enabled,
            isError: hasError,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            inputFormatters: widget.inputFormatters,
            semanticLabel: widget.labelText ?? 'Code',
            onChanged: widget.onChanged,
            onCompleted: widget.onCompleted,
            onSubmitted: widget.onSubmitted,
            slotBuilder: (context, slot) =>
                _Place(slot: slot, style: figures, rule: t.textSecondary),
            layoutBuilder: (context, slots) => Align(
              alignment: AlignmentDirectional.centerStart,
              child: CivicWell(
                fill:
                    so.fill ?? (widget.enabled ? t.background : t.disabledFill),
                edgeColor:
                    so.edge ??
                    (hasError
                        ? t.danger
                        : widget.enabled
                        ? t.border
                        : t.textDisabled),
                focused: _focus.hasFocus,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: CivicMetrics.edge + CivicSpacing.s12,
                    vertical: CivicMetrics.edge + CivicSpacing.s8,
                  ),
                  child: Directionality(
                    // A code reads left to right in every language.
                    textDirection: TextDirection.ltr,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: CivicSpacing.s4,
                      children: slots,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
    if (widget.labelText == null &&
        widget.helperText == null &&
        widget.errorText == null) {
      return field;
    }
    return DesignField(
      labelText: widget.labelText,
      helperText: widget.helperText,
      errorText: widget.errorText,
      enabled: widget.enabled,
      focusNode: _focus,
      builder: (context, parts) =>
          CivicFieldFrame(parts: parts, labelFocuses: true),
      child: field,
    );
  }
}

/// One place of the code: its figure, or a short rule while it is empty,
/// and the caret where the next figure goes.
class _Place extends StatelessWidget {
  const _Place({required this.slot, required this.style, required this.rule});

  final DesignOtpSlot slot;
  final TextStyle style;
  final Color rule;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context);
    final size = style.fontSize ?? 27;
    final w = scale.scale(size * 0.72);
    final h = scale.scale(size * 1.2);
    final shown = slot.obscured && slot.character.isNotEmpty
        ? '•'
        : slot.character;
    return SizedBox(
      width: w,
      height: h + 6,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(shown, style: style, textAlign: TextAlign.center),
          if (slot.character.isEmpty)
            PositionedDirectional(
              start: 2,
              end: 2,
              bottom: 2,
              child: Container(height: 2, color: rule),
            ),
          if (slot.active && slot.focused)
            PositionedDirectional(
              start: slot.character.isEmpty ? w / 2 - 1 : w - 2,
              top: 4,
              bottom: 6,
              child: Container(width: 2, color: style.color),
            ),
        ],
      ),
    );
  }
}

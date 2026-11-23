import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../theme.dart';

/// A text input in Ledger's type, its [hintText] shown while it is
/// empty, one line unless [maxLines] says it may grow. Plumbing of the
/// fields and the composer; pages never place one.
class LedgerTextInput extends StatefulWidget {
  /// A text input set in [style].
  const LedgerTextInput({
    required this.style,
    required this.hintStyle,
    this.controller,
    this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.onEditingComplete,
    this.focusNode,
    this.autofocus = false,
    this.keyboardType,
    this.textInputAction,
    this.maxLines = 1,
    super.key,
  });

  /// The words' style.
  final TextStyle style;

  /// The placeholder's style.
  final TextStyle hintStyle;

  /// The words typed; the input makes its own when none is given, and never
  /// disposes one it was given.
  final TextEditingController? controller;

  /// What stands while the input is empty.
  final String? hintText;

  /// Called with the words as they are typed.
  final ValueChanged<String>? onChanged;

  /// Called with the words when the keyboard submits them; the input gives
  /// up the focus.
  final ValueChanged<String>? onSubmitted;

  /// Called on the keyboard's act key in place of the input giving up the
  /// focus. An input that keeps the focus takes the act here, never in
  /// [onSubmitted] too: told of a submit while it keeps the focus, it
  /// restarts its text input, and a browser's then takes no typing.
  final VoidCallback? onEditingComplete;

  /// The input's focus; never disposed when given.
  final FocusNode? focusNode;

  /// Whether the input takes the focus when it first stands.
  final bool autofocus;

  /// The keyboard the input asks for.
  final TextInputType? keyboardType;

  /// The keyboard's act key.
  final TextInputAction? textInputAction;

  /// How many lines it grows to; 1 keeps it to one.
  final int maxLines;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<TextStyle>('style', style))
      ..add(DiagnosticsProperty<TextStyle>('hintStyle', hintStyle))
      ..add(
        DiagnosticsProperty<TextEditingController>(
          'controller',
          controller,
          defaultValue: null,
        ),
      )
      ..add(StringProperty('hintText', hintText, defaultValue: null))
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
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
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
      ..add(IntProperty('maxLines', maxLines));
  }

  @override
  State<LedgerTextInput> createState() => _LedgerTextInputState();
}

class _LedgerTextInputState extends State<LedgerTextInput> {
  TextEditingController? _own;
  FocusNode? _ownFocus;

  TextEditingController get _controller =>
      widget.controller ?? (_own ??= TextEditingController());
  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode());

  @override
  void didUpdateWidget(LedgerTextInput old) {
    super.didUpdateWidget(old);
    // Flutter's TextField's swap: the words carry over when the caller
    // takes its controller back, and the input's own goes when one comes.
    if (widget.controller == null && old.controller != null) {
      _own = TextEditingController.fromValue(old.controller!.value);
    } else if (widget.controller != null && old.controller == null) {
      _own?.dispose();
      _own = null;
    }
  }

  @override
  void dispose() {
    _own?.dispose();
    _ownFocus?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _controller,
      builder: (context, value, _) => Stack(
        alignment: AlignmentDirectional.centerStart,
        children: [
          if (value.text.isEmpty && widget.hintText != null)
            IgnorePointer(
              child: ExcludeSemantics(
                child: Text(
                  widget.hintText!,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: widget.hintStyle,
                ),
              ),
            ),
          EditableText(
            controller: _controller,
            focusNode: _focus,
            autofocus: widget.autofocus,
            style: widget.style,
            cursorColor: t.textPrimary,
            backgroundCursorColor: t.textFaint,
            selectionColor: t.accentSubtle,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            onChanged: widget.onChanged,
            onSubmitted: widget.onSubmitted,
            onEditingComplete: widget.onEditingComplete,
            minLines: 1,
            maxLines: widget.maxLines,
          ),
        ],
      ),
    );
  }
}

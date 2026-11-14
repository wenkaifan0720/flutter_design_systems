import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../theme.dart';

/// A text input in Ledger's type, its [placeholder] shown while it is
/// empty, one line unless [maxLines] says it may grow. Plumbing of the
/// fields and the composer; pages never place one.
class LedgerTextInput extends StatefulWidget {
  /// A text input set in [style].
  const LedgerTextInput({
    required this.style,
    required this.placeholderStyle,
    this.controller,
    this.placeholder,
    this.onChanged,
    this.onSubmitted,
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
  final TextStyle placeholderStyle;

  /// The words typed; the input makes its own when none is given, and never
  /// disposes one it was given.
  final TextEditingController? controller;

  /// What stands while the input is empty.
  final String? placeholder;

  /// Called with the words as they are typed.
  final ValueChanged<String>? onChanged;

  /// Called with the words when the keyboard submits them.
  final ValueChanged<String>? onSubmitted;

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
          if (value.text.isEmpty && widget.placeholder != null)
            IgnorePointer(
              child: ExcludeSemantics(
                child: Text(
                  widget.placeholder!,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: widget.placeholderStyle,
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
            minLines: 1,
            maxLines: widget.maxLines,
          ),
        ],
      ),
    );
  }
}

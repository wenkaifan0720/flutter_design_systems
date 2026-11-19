import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../internal/bidi.dart';
import '../../theme.dart';
import '../text-field/text_field.dart';

/// Words that need more than a line: the field's square well, [minLines]
/// tall and growing to [maxLines], and, with a [maxLength], a count under
/// it in words: "You can enter up to 500 characters", then "You have 12
/// characters remaining", then, past the limit, "You have 3 characters too
/// many" in the error colour with the well's edge in it too. Typing past
/// the limit is allowed, so nothing pasted is lost; the page says what to
/// fix when it is sent.
///
/// A screen reader hears the count when typing pauses, not at every key.
/// The words are the page's to give ([countMessage]); the default is
/// English.
///
/// Reads [CivicStyle] as [CivicTextField] does, through
/// [CivicThemeData.textFieldStyle].
///
/// ```dart
/// CivicTextArea(
///   labelText: 'Why do you need a visitor permit?',
///   helperText: 'Do not include personal or financial information.',
///   maxLength: 500,
///   controller: reason,
/// )
/// ```
class CivicTextArea extends StatefulWidget {
  /// A text area.
  const CivicTextArea({
    super.key,
    this.controller,
    this.focusNode,
    this.labelText,
    this.helperText,
    this.errorText,
    this.hintText,
    this.maxLength,
    this.countMessage,
    this.minLines = 5,
    this.maxLines = 12,
    this.isPageHeading = false,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.onChanged,
    this.textCapitalization = TextCapitalization.sentences,
    this.inputFormatters,
    this.style,
  }) : assert(maxLength == null || maxLength > 0),
       assert(minLines > 0 && maxLines >= minLines);

  /// The words; null keeps its own.
  final TextEditingController? controller;

  /// {@macro civic.focusNode}
  final FocusNode? focusNode;

  /// The question.
  final String? labelText;

  /// How to answer.
  final String? helperText;

  /// What to fix; null while the answer is fine.
  final String? errorText;

  /// Shown while the area is empty.
  final String? hintText;

  /// The most characters the answer may have; null for no limit and no
  /// count.
  final int? maxLength;

  /// The count's words for the characters [left] of [maxLength] (below 0
  /// past it, and [maxLength] itself while the area is empty); null: Civic's
  /// English.
  final String Function(int left, int maxLength)? countMessage;

  /// The lines it shows when empty.
  final int minLines;

  /// The lines it grows to before it scrolls.
  final int maxLines;

  /// Whether the question is the page's heading.
  final bool isPageHeading;

  /// Whether it takes input.
  final bool enabled;

  /// Whether its words can be read and copied but not changed.
  final bool readOnly;

  /// {@macro civic.autofocus}
  final bool autofocus;

  /// Called with the words as they change.
  final ValueChanged<String>? onChanged;

  /// How words are capitalised as they are typed.
  final TextCapitalization textCapitalization;

  /// Formatters run on the words as they are typed.
  final List<TextInputFormatter>? inputFormatters;

  /// Overrides for the well's look.
  final CivicStyle? style;

  /// Civic's English count: "You can enter up to 500 characters", "You have
  /// 1 character remaining", "You have 3 characters too many".
  static String englishCount(int left, int maxLength) {
    String chars(int n) => n == 1
        ? '${civicIsolate('1')} character'
        : '${civicIsolate('$n')} characters';
    if (left == maxLength) return 'You can enter up to ${chars(maxLength)}';
    if (left >= 0) return 'You have ${chars(left)} remaining';
    return 'You have ${chars(-left)} too many';
  }

  @override
  State<CivicTextArea> createState() => _CivicTextAreaState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('labelText', labelText, defaultValue: null))
      ..add(StringProperty('errorText', errorText, defaultValue: null))
      ..add(IntProperty('maxLength', maxLength, defaultValue: null))
      ..add(IntProperty('minLines', minLines, defaultValue: 5))
      ..add(IntProperty('maxLines', maxLines, defaultValue: 12))
      ..add(FlagProperty('enabled', value: enabled, ifFalse: 'disabled'))
      ..add(
        DiagnosticsProperty<CivicStyle>('style', style, defaultValue: null),
      );
  }
}

class _CivicTextAreaState extends State<CivicTextArea> {
  TextEditingController? _own;
  TextEditingController get _controller =>
      widget.controller ?? (_own ??= TextEditingController());

  Timer? _pause;
  String _spoken = '';

  @override
  void initState() {
    super.initState();
    _controller.addListener(_changed);
  }

  @override
  void didUpdateWidget(CivicTextArea old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      (old.controller ?? _own)?.removeListener(_changed);
      _controller.addListener(_changed);
    }
  }

  @override
  void dispose() {
    _pause?.cancel();
    _controller.removeListener(_changed);
    _own?.dispose();
    super.dispose();
  }

  int get _length => _controller.text.characters.length;

  void _changed() {
    if (widget.maxLength == null) return;
    setState(() {});
    // The count is said once typing rests, not at every key.
    _pause?.cancel();
    _pause = Timer(const Duration(milliseconds: 1000), () {
      if (mounted) setState(() => _spoken = _message());
    });
  }

  String _message() {
    final max = widget.maxLength!;
    final left = _controller.text.isEmpty ? max : max - _length;
    return (widget.countMessage ?? CivicTextArea.englishCount)(left, max);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final max = widget.maxLength;
    final over = max != null && _length > max;
    final field = CivicTextField(
      controller: _controller,
      focusNode: widget.focusNode,
      labelText: widget.labelText,
      helperText: widget.helperText,
      errorText: widget.errorText,
      hintText: widget.hintText,
      isPageHeading: widget.isPageHeading,
      isError: over,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      autofocus: widget.autofocus,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      textCapitalization: widget.textCapitalization,
      inputFormatters: widget.inputFormatters,
      minLines: widget.minLines,
      maxLines: widget.maxLines,
      onChanged: widget.onChanged,
      style: widget.style,
    );
    if (max == null) return field;
    final words = context.civicText.bodySmall;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        field,
        const SizedBox(height: CivicSpacing.s8),
        // Shown at once; said when typing rests ([_spoken]).
        ExcludeSemantics(
          child: Text(
            _message(),
            style: over
                ? words.copyWith(color: t.danger, fontWeight: FontWeight.w700)
                : words.copyWith(color: t.textSecondary),
          ),
        ),
        Semantics(liveRegion: true, label: _spoken, child: const SizedBox()),
      ],
    );
  }
}

/// A one-time code (OTP, PIN) field, headless.
///
/// It is ONE text input drawn as boxes, not one input per box: the platform
/// sees an ordinary field, so a paste fills every box, SMS autofill works
/// ([AutofillHints.oneTimeCode]), Backspace steps back, and nothing hands
/// focus from box to box. Typing fills the first empty box; anything the
/// code does not allow is dropped; a paste longer than the code is cut. A
/// long press or a secondary click offers Paste, in the menu the look draws
/// ([DesignOtpField.contextMenuBuilder]).
library;

import 'package:flutter/semantics.dart' show SemanticsValidationResult;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Holds a code: its text, its length, whether it is whole.
///
/// The caller makes it (a State's field, say), keeps it across rebuilds
/// and disposes it; a widget it is given to only listens to it.
///
/// ```dart
/// DesignOtpController(length: 6)
/// ```
class DesignOtpController extends ChangeNotifier {
  /// A code of [length] characters, starting at [initialValue] (filtered by
  /// [allowed]). Given [text], the code lives in that input instead (a form's
  /// own controller): its text is the code, filtered the same way, and it is
  /// the caller's to dispose.
  DesignOtpController({
    required this.length,
    String initialValue = '',
    RegExp? allowed,
    TextEditingController? text,
  }) : assert(length > 0),
       allowed = allowed ?? RegExp(r'\d'),
       _ownsText = text == null {
    this.text = text ?? TextEditingController(text: _clean(initialValue));
    if (!_ownsText) {
      // Only an input holding what the code does not take is rewritten: a
      // clean one (the usual, empty) is left alone, so the form's listeners
      // hear nothing while the field is being built.
      final clean = _clean(this.text.text);
      if (clean != this.text.text) {
        this.text.value = TextEditingValue(
          text: clean,
          selection: TextSelection.collapsed(offset: clean.length),
        );
      }
      _last = clean;
    }
    this.text.addListener(_changed);
  }

  final bool _ownsText;

  /// How many characters the code has.
  final int length;

  /// One character the code takes (a digit, by default).
  final RegExp allowed;

  /// The input under the boxes; [DesignOtpField] attaches it.
  late final TextEditingController text;

  String _last = '';

  /// The code so far.
  String get value => text.text;

  /// Whether every box is filled.
  bool get isComplete => text.text.length == length;

  /// The box the next character goes in: the first empty one, or the last
  /// when the code is whole.
  int get activeIndex =>
      text.text.length >= length ? length - 1 : text.text.length;

  /// The character in box [index], or '' while it is empty.
  String charAt(int index) => index < text.text.length ? text.text[index] : '';

  /// Empties every box.
  void clear() => text.clear();

  /// Fills the boxes from [raw] (a paste), dropping what the code does not
  /// allow and what does not fit.
  void fill(String raw) {
    final clean = _clean(raw);
    text.value = TextEditingValue(
      text: clean,
      selection: TextSelection.collapsed(offset: clean.length),
    );
  }

  /// Fills the boxes from the clipboard: for a look's own Paste control.
  Future<void> paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final raw = data?.text;
    if (raw != null) fill(raw);
  }

  String _clean(String raw) {
    final kept = raw.split('').where(allowed.hasMatch).join();
    return kept.length > length ? kept.substring(0, length) : kept;
  }

  void _changed() {
    final value = text.value;
    final clean = _clean(value.text);
    // The caret always sits after the last character: one model, no
    // selection inside the code.
    final end = TextSelection.collapsed(offset: clean.length);
    if (clean != value.text || value.selection != end) {
      text.value = value.copyWith(
        text: clean,
        selection: end,
        composing: TextRange.empty,
      );
      return;
    }
    if (clean != _last) {
      _last = clean;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    text.removeListener(_changed);
    if (_ownsText) text.dispose();
    super.dispose();
  }
}

/// One box, as [DesignOtpField.slotBuilder] gets it.
@immutable
class DesignOtpSlot {
  /// A box; the field makes these.
  const DesignOtpSlot({
    required this.index,
    required this.character,
    required this.active,
    required this.focused,
    required this.enabled,
    required this.isError,
    required this.obscured,
  });

  /// Its place, from 0.
  final int index;

  /// Its character, or '' while empty (show a dot instead when [obscured]).
  final String character;

  /// Whether the next character goes here (draw the caret, ring it while
  /// [focused]).
  final bool active;

  /// Whether the field has focus.
  final bool focused;

  /// Whether the field takes input.
  final bool enabled;

  /// Whether the code is wrong.
  final bool isError;

  /// Whether the characters are hidden.
  final bool obscured;

  /// Whether it holds a character.
  bool get filled => character.isNotEmpty;
}

/// Paints one box.
typedef DesignOtpSlotBuilder = Widget Function(
  BuildContext context,
  DesignOtpSlot slot,
);

/// Lays out the boxes (a row; a look may put a dash in the middle).
typedef DesignOtpLayoutBuilder = Widget Function(
  BuildContext context,
  List<Widget> slots,
);

/// Draws the field's edit menu: Flutter's toolbar arguments, so a look can
/// hand them on (Material's `AdaptiveTextSelectionToolbar.buttonItems`,
/// Cupertino's `CupertinoAdaptiveTextSelectionToolbar.buttonItems`) or draw
/// its own. [items] is the Paste item (its label from its
/// [ContextMenuButtonType], in the app's language); pressing it pastes and
/// closes the menu.
typedef DesignOtpContextMenuBuilder = Widget Function(
  BuildContext context,
  TextSelectionToolbarAnchors anchors,
  List<ContextMenuButtonItem> items,
);

/// A one-time code drawn as boxes over one input.
///
/// ```dart
/// DesignOtpField(length: 4, slotBuilder: (context, slot) => Text(slot.character))
/// ```
class DesignOtpField extends StatefulWidget {
  /// A code field of [length] boxes.
  const DesignOtpField({
    super.key,
    required this.slotBuilder,
    this.length = 6,
    this.controller,
    this.focusNode,
    this.layoutBuilder,
    this.onChanged,
    this.onCompleted,
    this.autofocus = false,
    this.enabled = true,
    this.isError = false,
    this.obscureText = false,
    this.keyboardType = TextInputType.number,
    this.textDirection = TextDirection.ltr,
    this.semanticLabel = 'One-time code',
    this.textInputAction,
    this.onEditingComplete,
    this.contextMenuBuilder,
    this.onSubmitted,
    this.inputFormatters = const [],
    this.autofillHints = const [AutofillHints.oneTimeCode],
  });

  /// Paints one box.
  final DesignOtpSlotBuilder slotBuilder;

  /// How many boxes; ignored when [controller] is given (its length wins).
  final int length;

  /// Holds the code, when the caller does. The caller disposes it; null:
  /// the field makes its own and disposes it.
  final DesignOtpController? controller;

  /// The input's focus. The caller's, who disposes it; null: the field
  /// makes its own and disposes it.
  final FocusNode? focusNode;

  /// Lays out the boxes; null puts them in a row.
  final DesignOtpLayoutBuilder? layoutBuilder;

  /// Called with the code as it changes.
  final ValueChanged<String>? onChanged;

  /// Called once each time the code becomes whole.
  final ValueChanged<String>? onCompleted;

  /// Whether it takes focus when it first appears.
  final bool autofocus;

  /// Whether it takes input.
  final bool enabled;

  /// Whether the code is wrong.
  final bool isError;

  /// Whether the characters are hidden (a PIN).
  final bool obscureText;

  /// The keyboard the platform shows.
  final TextInputType keyboardType;

  /// The boxes' order: left to right, as codes are read, even in right to
  /// left text.
  final TextDirection textDirection;

  /// What a screen reader calls it, as given (pass it in the app's
  /// language). The length is not added to it: the node carries it as its
  /// maximum length, which the platform reads out in the user's language.
  /// Null gives the input no name of its own, for a caller whose own
  /// semantics (a form field's) name it; so, unlike the other behaviours'
  /// words, its default is English here rather than `DesignLocalizations`'.
  final String? semanticLabel;

  /// The keyboard's action key; null: the platform's for one line (done).
  final TextInputAction? textInputAction;

  /// Called when the action key is pressed; null: the input lets go of the
  /// focus, as any one-line input does.
  final VoidCallback? onEditingComplete;

  /// Draws the menu a long press or a secondary click opens, offering Paste
  /// while the clipboard holds text; null offers none.
  final DesignOtpContextMenuBuilder? contextMenuBuilder;

  /// Called with the code when the action key is pressed.
  final ValueChanged<String>? onSubmitted;

  /// The caller's formatters (upper-casing letters, say), run before the
  /// code's own filter and length, which have the last word: nothing the
  /// code does not allow gets through.
  final List<TextInputFormatter> inputFormatters;

  /// What autofill may offer; a one-time code by default.
  final Iterable<String> autofillHints;

  @override
  State<DesignOtpField> createState() => _DesignOtpFieldState();
}

class _DesignOtpFieldState extends State<DesignOtpField> {
  DesignOtpController? _own;
  FocusNode? _ownFocus;
  bool _wasComplete = false;
  final ContextMenuController _menu = ContextMenuController();
  final GlobalKey<EditableTextState> _editable = GlobalKey<EditableTextState>();

  DesignOtpController get _controller =>
      widget.controller ??
      (_own ??= DesignOtpController(length: widget.length));

  FocusNode get _focus =>
      widget.focusNode ?? (_ownFocus ??= FocusNode(debugLabel: 'DesignOtp'));

  @override
  void initState() {
    super.initState();
    _controller.addListener(_changed);
    _focus.addListener(_focusChanged);
    _wasComplete = _controller.isComplete;
  }

  @override
  void didUpdateWidget(DesignOtpField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      (oldWidget.controller ?? _own)?.removeListener(_changed);
      _controller.addListener(_changed);
    }
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _ownFocus)?.removeListener(_focusChanged);
      _focus.addListener(_focusChanged);
    }
  }

  @override
  void dispose() {
    _menu.remove();
    _controller.removeListener(_changed);
    _focus.removeListener(_focusChanged);
    _own?.dispose();
    _ownFocus?.dispose();
    super.dispose();
  }

  void _focusChanged() {
    // The menu belongs to the focused field: it goes when focus does.
    if (!_focus.hasFocus) _menu.remove();
    setState(() {});
  }

  void _tapped() {
    _menu.remove();
    // Focuses the input, or brings its keyboard back when it already has
    // focus and the keyboard was put away.
    _editable.currentState?.requestKeyboard();
  }

  /// Opens the look's menu at [position] (global) with Paste, when the
  /// clipboard holds text.
  Future<void> _openMenu(Offset position) async {
    final builder = widget.contextMenuBuilder;
    if (builder == null || !widget.enabled) return;
    _focus.requestFocus();
    if (!await Clipboard.hasStrings() || !mounted) return;
    final items = <ContextMenuButtonItem>[
      ContextMenuButtonItem(
        type: ContextMenuButtonType.paste,
        onPressed: () {
          ContextMenuController.removeAny();
          _controller.paste();
        },
      ),
    ];
    _menu.show(
      context: context,
      contextMenuBuilder: (context) => builder(
        context,
        TextSelectionToolbarAnchors(primaryAnchor: position),
        items,
      ),
    );
  }

  void _changed() {
    setState(() {});
    final value = _controller.value;
    widget.onChanged?.call(value);
    final complete = _controller.isComplete;
    if (complete && !_wasComplete) widget.onCompleted?.call(value);
    _wasComplete = complete;
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    final focused = _focus.hasFocus;
    final slots = [
      for (var i = 0; i < c.length; i++)
        widget.slotBuilder(
          context,
          DesignOtpSlot(
            index: i,
            character: c.charAt(i),
            active: i == c.activeIndex && widget.enabled,
            focused: focused,
            enabled: widget.enabled,
            isError: widget.isError,
            obscured: widget.obscureText,
          ),
        ),
    ];
    final boxes = Directionality(
      textDirection: widget.textDirection,
      child:
          widget.layoutBuilder?.call(context, slots) ??
          Row(mainAxisSize: MainAxisSize.min, children: slots),
    );
    const clear = Color(0x00000000);
    final input = EditableText(
      key: _editable,
      // The field's own detector takes the tap and the long press; the
      // renderer's would win the long press and open no menu.
      rendererIgnoresPointer: true,
      controller: c.text,
      focusNode: _focus,
      autofocus: widget.autofocus,
      readOnly: !widget.enabled,
      obscureText: widget.obscureText,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      onEditingComplete: widget.onEditingComplete,
      onSubmitted: widget.onSubmitted,
      autofillHints: widget.autofillHints,
      autocorrect: false,
      enableSuggestions: false,
      showCursor: false,
      maxLines: 1,
      textAlign: TextAlign.center,
      inputFormatters: [
        ...widget.inputFormatters,
        FilteringTextInputFormatter.allow(c.allowed),
        LengthLimitingTextInputFormatter(c.length),
      ],
      style: const TextStyle(color: clear, fontSize: 1, height: 1),
      cursorColor: clear,
      backgroundCursorColor: clear,
      selectionColor: clear,
    );
    // One node: the input's, with the code's name, its length and whether
    // it is wrong on it. Its tap is the field's own (the input's renderer
    // ignores the pointer, so it gives the node none): a screen reader's
    // double tap focuses the code and brings the keyboard back.
    return MergeSemantics(
      child: Semantics(
        label: widget.semanticLabel,
        onTap: widget.enabled ? _tapped : null,
        maxValueLength: c.length,
        currentValueLength: c.value.length,
        validationResult: widget.isError
            ? SemanticsValidationResult.invalid
            : SemanticsValidationResult.none,
        enabled: widget.enabled,
        child: Stack(
          alignment: Alignment.center,
          children: [
            ExcludeSemantics(child: IgnorePointer(child: boxes)),
            // The input covers the boxes, so a tap anywhere on them focuses
            // it; it draws nothing.
            // Disabled, it takes neither focus nor a tap.
            Positioned.fill(
              child: IgnorePointer(
                ignoring: !widget.enabled,
                child: ExcludeFocus(
                  excluding: !widget.enabled,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    excludeFromSemantics: true,
                    onTap: widget.enabled ? _tapped : null,
                    onLongPressStart: widget.contextMenuBuilder == null
                        ? null
                        : (d) => _openMenu(d.globalPosition),
                    onSecondaryTapUp: widget.contextMenuBuilder == null
                        ? null
                        : (d) => _openMenu(d.globalPosition),
                    child: Opacity(
                      opacity: 0,
                      alwaysIncludeSemantics: true,
                      child: input,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

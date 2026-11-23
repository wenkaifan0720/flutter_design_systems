/// The text field: one line of input in a box-drawn frame, its label cut
/// into the top line and its help or error into the bottom one.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart' show RenderEditable;
import 'package:flutter/services.dart';
import 'package:ui_core/ui_core.dart';

import '../internal/list_open.dart';
import '../primitives/control.dart';
import '../primitives/field_frame.dart';
import '../style.dart';
import '../theme.dart';

/// A text field drawn as a terminal form draws one: three lines tall, a
/// frame whose top line carries [labelText] and whose bottom line carries
/// [helperText] or, while there is one, [errorText] after a `✗`; the words
/// typed on the line between, after an optional [prompt] (`$`, `>`, `~/`).
///
/// The frame doubles in the accent while the field has focus, and draws in
/// the danger ink while it has an error. The caret is a block on the cell
/// after the words (before them, right to left), behind the character it
/// is on, blinking between solid and hollow so it always shows where the
/// next key lands; under Reduce Motion it holds still.
/// A note too long for the frame's line drops under the frame, wrapped.
///
/// It takes Flutter's [TextField] arguments by their names; [controller]
/// and [focusNode], when given, are the caller's to dispose.
///
/// ```dart
/// TermTextField(
///   labelText: 'branch',
///   hintText: 'main',
///   prompt: '\u{E0A0}',
///   onSubmitted: (value) => deploy(value),
/// )
/// ```
///
/// Reads [TermStyle]'s `edge` (the frame), `foreground` (the words typed)
/// and `textStyle`.
class TermTextField extends StatefulWidget {
  /// A one-line text field in a three-line frame.
  const TermTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.prompt,
    this.onChanged,
    this.onSubmitted,
    this.onEditingComplete,
    this.enabled = true,
    this.readOnly = false,
    this.obscureText = false,
    this.autofocus = false,
    this.autocorrect = true,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.autofillHints,
    this.textDirection,
    this.style,
    this.lines = 1,
    this.prefixText,
    this.suffixText,
    this.suffix,
    this.framed = true,
  }) : assert(lines >= 1),
       inline = false,
       labelCols = null;

  /// A text field on one line, as a config file lays one out: the label,
  /// then the words typed in brackets, `name [ atlas-api ]`, the help or
  /// the error on the line under them. [labelCols] gives the label a width
  /// in cells, so the brackets of a column of fields line up.
  ///
  /// ```dart
  /// TermTextField.inline(
  ///   labelText: 'timeout',
  ///   labelCols: 16,
  ///   controller: timeout,
  ///   errorText: valid ? null : 'a number and s, m or h',
  /// )
  /// ```
  const TermTextField.inline({
    super.key,
    this.controller,
    this.focusNode,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.prompt,
    this.onChanged,
    this.onSubmitted,
    this.onEditingComplete,
    this.enabled = true,
    this.readOnly = false,
    this.obscureText = false,
    this.autofocus = false,
    this.autocorrect = true,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.autofillHints,
    this.textDirection,
    this.style,
    this.labelCols,
    this.prefixText,
    this.suffixText,
    this.suffix,
  }) : inline = true,
       framed = true,
       lines = 1;

  /// Whether it stands on one line ([TermTextField.inline]) rather than in
  /// a three-line frame.
  final bool inline;

  /// Whether it draws its own frame; false: its words alone on one line
  /// (the tap floor's height), for a part that frames them with more, as
  /// [TermTagInput] frames its tags and its words together. Its label and
  /// its help are then what a screen reader reads on it, drawn by the part
  /// round it.
  final bool framed;

  /// On one line, the label's width in cells; null for the label's own.
  final int? labelCols;

  /// The text; one given is the caller's to dispose.
  final TextEditingController? controller;

  /// {@macro term.focusNode}
  final FocusNode? focusNode;

  /// What the field is, cut into the top line and read as its name.
  final String? labelText;

  /// The dim words shown while the field is empty.
  final String? hintText;

  /// Help, cut into the bottom line.
  final String? helperText;

  /// What is wrong with the value, cut into the bottom line in place of
  /// [helperText]; null while it is fine.
  final String? errorText;

  /// A glyph or two before the input, dim: `$`, `>`, `~/`.
  final String? prompt;

  /// Called on every edit.
  final ValueChanged<String>? onChanged;

  /// Called on Return, the field then giving up its focus. A field that
  /// keeps the focus after Return takes it in [onEditingComplete] instead.
  final ValueChanged<String>? onSubmitted;

  /// Called on Return in place of giving up the focus: a field that keeps
  /// it after Return (a tag input's, a combobox's, an add-another field)
  /// takes Return here, with no [onSubmitted]. Given both, Flutter
  /// restarts the text input of a field that kept its focus, and in a
  /// browser the restarted input takes no more typing.
  final VoidCallback? onEditingComplete;

  /// Whether it takes input.
  final bool enabled;

  /// Whether the text can be selected but not changed.
  final bool readOnly;

  /// Whether the text is hidden, each character written `*`.
  final bool obscureText;

  /// {@macro term.autofocus}
  final bool autofocus;

  /// Whether the platform corrects spelling as you type.
  final bool autocorrect;

  /// The keyboard a phone shows.
  final TextInputType? keyboardType;

  /// The action key a phone shows.
  final TextInputAction? textInputAction;

  /// Rules each edit passes through.
  final List<TextInputFormatter>? inputFormatters;

  /// What autofill may put here.
  final Iterable<String>? autofillHints;

  /// The direction the words run in, when not the app's: left to right
  /// for a path, a command or a config value in a right-to-left app.
  final TextDirection? textDirection;

  /// Overrides, over the theme's [TermThemeData.textFieldStyle]: `edge`
  /// (the frame), `foreground` (the words typed) and `textStyle` (their
  /// colour and weight).
  final TermStyle? style;

  /// The lines of words the frame holds: more than one makes it a text
  /// area, Return starting a new line.
  final int lines;

  /// An add-on before the words typed, dim, ruled off from them:
  /// `https://`. It is not part of the value.
  final String? prefixText;

  /// An add-on after the words typed, dim, ruled off from them:
  /// `.slipway.dev`, `MB`.
  final String? suffixText;

  /// A control at the end of the line, inside the frame: a `[show]` that
  /// reveals a password, a `[×]` that clears.
  final Widget? suffix;

  @override
  State<TermTextField> createState() => _TermTextFieldState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('labelText', labelText, defaultValue: null))
      ..add(StringProperty('hintText', hintText, defaultValue: null))
      ..add(StringProperty('helperText', helperText, defaultValue: null))
      ..add(StringProperty('errorText', errorText, defaultValue: null))
      ..add(StringProperty('prompt', prompt, defaultValue: null))
      ..add(FlagProperty('inline', value: inline, ifTrue: 'inline'))
      ..add(IntProperty('lines', lines, defaultValue: 1))
      ..add(StringProperty('prefixText', prefixText, defaultValue: null))
      ..add(StringProperty('suffixText', suffixText, defaultValue: null))
      ..add(IntProperty('labelCols', labelCols, defaultValue: null))
      ..add(FlagProperty('enabled', value: enabled, ifFalse: 'disabled'))
      ..add(FlagProperty('readOnly', value: readOnly, ifTrue: 'readOnly'))
      ..add(
        FlagProperty('obscureText', value: obscureText, ifTrue: 'obscured'),
      );
  }
}

class _TermTextFieldState extends State<TermTextField> {
  FocusNode? _ownFocus;
  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode());
  TextEditingController? _ownController;
  TextEditingController get _controller =>
      widget.controller ?? (_ownController ??= TextEditingController());
  final _input = GlobalKey();

  // The caret's blink: solid for half a second, hollow for half, and solid
  // again from the start at every edit and move, as a terminal's is. Hollow,
  // it still marks the cell the next key lands on.
  final _caretOn = ValueNotifier<bool>(true);
  Timer? _blink;
  FocusNode? _heardFocus;
  TextEditingController? _heardController;
  var _steady = false;

  void _hear() {
    final focus = _focus;
    final controller = _controller;
    if (!identical(focus, _heardFocus)) {
      _heardFocus?.removeListener(_restartBlink);
      _heardFocus = focus..addListener(_restartBlink);
    }
    if (!identical(controller, _heardController)) {
      _heardController?.removeListener(_restartBlink);
      _heardController = controller..addListener(_restartBlink);
    }
  }

  void _restartBlink() {
    _blink?.cancel();
    _blink = null;
    _caretOn.value = true;
    if (!mounted || _steady || !_focus.hasFocus) return;
    _blink = Timer.periodic(
      const Duration(milliseconds: 500),
      (_) => _caretOn.value = !_caretOn.value,
    );
  }

  @override
  void dispose() {
    _blink?.cancel();
    _heardFocus?.removeListener(_restartBlink);
    _heardController?.removeListener(_restartBlink);
    _caretOn.dispose();
    _ownFocus?.dispose();
    _ownController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final grid = context.termGrid;
    final enabled = widget.enabled;
    final hasError = widget.errorText != null;
    final states = <WidgetState>{
      if (!enabled) WidgetState.disabled,
      if (hasError) WidgetState.error,
      if (_focus.hasFocus) WidgetState.focused,
    };
    final own = TermStyleOf([widget.style, theme.textFieldStyle], states);
    // The input is as tall as its frame (three lines; on one line, the tap
    // floor), its words on the middle line: the padding round them is
    // still the field's, so a tap anywhere in the frame reaches it.
    final lh = grid.lineHeight;
    final floor = grid.ceil(DesignTapTargets.of(context).floorOn()).height;
    final multiline = widget.lines > 1;
    final tall = widget.inline || !widget.framed
        ? math.max(lh, floor)
        : lh * (widget.lines + 2);
    final pad = multiline ? lh : (tall - lh) / 2;
    final words = theme.textStyle
        .merge(own.textStyle)
        .copyWith(
          color: own.foreground ?? (enabled ? theme.foreground : theme.rule),
        );

    // The caret is the field's own block, not Flutter's. Flutter's stands
    // two pixels before its place on iOS and macOS (Material's offset for a
    // hairline caret), and holds a margin as wide as itself at the line's
    // end, which right to left is the start: the words typed stood a cell
    // inside the label and the hint. So Flutter's caret has no width and is
    // never shown, and the block is painted behind the words on the cell
    // the caret is at. Under Reduce Motion it holds still.
    final steady = designReduceMotionOf(context);
    if (steady != _steady) {
      _steady = steady;
      // After this build: the notifier may have listeners painting.
      scheduleMicrotask(_restartBlink);
    }
    _hear();
    final caret = hasError ? theme.danger : theme.accent;
    final rtl =
        (widget.textDirection ?? Directionality.of(context)) ==
        TextDirection.rtl;
    // The one pixel Flutter still keeps after the last character (its
    // caret's gap) is, right to left, before the first: the input stands a
    // pixel further out and its hint a pixel back in, so the words and the
    // hint both start on the cell the label does.
    final gap = rtl ? 1.0 : 0.0;
    final hint = widget.hintText;

    // Material's field, on a Material surface of its own that paints
    // nothing, so it stands under any app.
    Widget control = Material(
      type: MaterialType.transparency,
      child: TextField(
        controller: _controller,
        showCursor: false,
        focusNode: _focus,
        enabled: enabled,
        readOnly: widget.readOnly,
        obscureText: widget.obscureText,
        obscuringCharacter: '*',
        autofocus: widget.autofocus,
        autocorrect: widget.autocorrect,
        // Brought into view, the field shows its whole frame, the lines
        // over and under its words too, and a line of the page past them.
        scrollPadding: EdgeInsets.symmetric(
          horizontal: grid.cols(2),
          vertical: pad + grid.lineHeight,
        ),
        keyboardType:
            widget.keyboardType ?? (multiline ? TextInputType.multiline : null),
        textInputAction:
            widget.textInputAction ??
            (multiline ? TextInputAction.newline : null),
        inputFormatters: widget.inputFormatters,
        autofillHints: widget.autofillHints,
        textDirection: widget.textDirection,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        onEditingComplete: widget.onEditingComplete,
        maxLines: widget.lines,
        minLines: widget.lines,
        style: words,
        cursorWidth: 0,
        cursorHeight: grid.fontSize * 1.25,
        textAlignVertical: multiline
            ? TextAlignVertical.top
            : TextAlignVertical.center,
        decoration:
            (rtl && hint != null
                    ? InputDecoration.collapsed(
                        hintText: null,
                        hint: Padding(
                          padding: EdgeInsetsDirectional.only(start: gap),
                          child: Text(
                            hint,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.dimStyle,
                          ),
                        ),
                      )
                    : InputDecoration.collapsed(
                        hintText: hint,
                        hintStyle: theme.dimStyle,
                      ))
                .copyWith(contentPadding: EdgeInsets.symmetric(vertical: pad)),
      ),
    );
    if (gap > 0) {
      control = Transform.translate(offset: Offset(gap, 0), child: control);
    }
    // The input of a field that opens a list (a combobox's, a tag input's)
    // says whether the list is up, as a select says it on its button.
    final open = TermListOpen.maybeOf(context);
    if (open != null) control = Semantics(expanded: open, child: control);
    if (enabled && !widget.readOnly) {
      control = CustomPaint(
        painter: _Caret(
          field: _input,
          focus: _focus,
          controller: _controller,
          on: _caretOn,
          color: caret,
          width: grid.cellWidth,
          height: grid.fontSize * 1.25,
          stroke: termStrokeWidth(theme, grid),
          rtl: rtl,
        ),
        child: KeyedSubtree(key: _input, child: control),
      );
    }

    return RawInputDecorator(
      labelText: widget.labelText,
      helperText: widget.helperText,
      errorText: widget.errorText,
      enabled: enabled,
      focusNode: _focus,
      builder: (context, parts) {
        // The input takes the frame's whole height (its words centred on
        // the line), so the frame's area is the field's.
        // An add-on stands on the first line, ruled off from the words; at
        // most [most] wide, its words cut with an ellipsis, the rule whole.
        Widget addOn(String text, {required bool before, double? most}) {
          final rule = Text(
            before ? ' │' : '│ ',
            style: theme.textStyle.copyWith(color: theme.rule),
          );
          return Align(
            alignment: multiline
                ? AlignmentDirectional.topStart
                : AlignmentDirectional.center,
            widthFactor: 1,
            child: Padding(
              padding: EdgeInsets.only(top: multiline ? pad : 0),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: most ?? double.infinity),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!before) rule,
                    Flexible(
                      child: Text(
                        text,
                        style: theme.dimStyle,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (before) rule,
                  ],
                ),
              ),
            ),
          );
        }

        // The add-ons whole while they leave the words [_wordsCols] cells;
        // past that (larger text on a phone) the longer is cut first, each
        // to no less than its rule and three cells of words (two letters
        // and the ellipsis).
        (double?, double?) addOnWidths(double width) {
          final before = widget.prefixText;
          final after = widget.suffixText;
          if (!width.isFinite || (before == null && after == null)) {
            return (null, null);
          }
          double whole(String? t) =>
              t == null ? 0 : grid.widthOf(t) + grid.cols(2);
          final a = whole(before);
          final b = whole(after);
          final prompt = widget.prompt;
          final room =
              width -
              grid.cols(_wordsCols) -
              (prompt == null ? 0 : grid.widthOf(prompt) + grid.cellWidth) -
              (before == null ? 0 : grid.cellWidth) -
              (after == null ? 0 : grid.cellWidth) -
              (widget.suffix == null ? 0 : grid.cols(4));
          if (a + b <= room) return (null, null);
          final least = grid.cols(5);
          if (before == null) return (null, math.max(least, room));
          if (after == null) return (math.max(least, room), null);
          final half = room / 2;
          if (a <= half) return (null, math.max(least, room - a));
          if (b <= half) return (math.max(least, room - b), null);
          return (math.max(least, half), math.max(least, half));
        }

        Widget rowIn(double width) {
          final (mostBefore, mostAfter) = addOnWidths(width);
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.prompt != null) ...[
                Align(
                  widthFactor: 1,
                  alignment: multiline
                      ? AlignmentDirectional.topStart
                      : AlignmentDirectional.center,
                  child: Padding(
                    padding: EdgeInsets.only(top: multiline ? pad : 0),
                    child: ExcludeSemantics(
                      child: Text(widget.prompt!, style: theme.dimStyle),
                    ),
                  ),
                ),
                SizedBox(width: grid.cellWidth),
              ],
              if (widget.prefixText != null) ...[
                addOn(widget.prefixText!, before: true, most: mostBefore),
                SizedBox(width: grid.cellWidth),
              ],
              Expanded(
                child: multiline || widget.obscureText
                    ? parts.control
                    : _EndMark(
                        controller: _controller,
                        focus: _focus,
                        child: parts.control,
                      ),
              ),
              if (widget.suffixText != null) ...[
                SizedBox(width: grid.cellWidth),
                addOn(widget.suffixText!, before: false, most: mostAfter),
              ],
              if (widget.suffix != null) ...[
                SizedBox(width: grid.cellWidth),
                Center(widthFactor: 1, child: widget.suffix),
              ],
            ],
          );
        }

        final Widget row =
            widget.prefixText == null && widget.suffixText == null
            ? rowIn(double.infinity)
            : LayoutBuilder(builder: (context, box) => rowIn(box.maxWidth));
        // A field whose words run their own way (code, a path in a
        // right-to-left app) lays its prompt and words out that way too, so
        // the prompt stands before its words: `/ token`, not `token … /`.
        final textDirection = widget.textDirection;
        final line = textDirection == null
            ? row
            : Directionality(textDirection: textDirection, child: row);
        final Widget field;
        if (!widget.framed) {
          field = SizedBox(height: tall, child: line);
        } else if (widget.inline) {
          field = TermFieldLine(
            parts: parts,
            active: parts.focused,
            edge: own.edge,
            labelCols: widget.labelCols,
            child: line,
          );
        } else {
          field = TermFieldFrame(
            parts: parts,
            active: parts.focused,
            edge: own.edge,
            lines: widget.lines,
            child: line,
          );
        }
        if (widget.prefixText == null &&
            widget.suffixText == null &&
            widget.suffix == null) {
          return field;
        }
        // With add-ons the frame is one control: a tap on an add-on puts
        // the caret in the words, and the frame is focused while anything
        // in it is.
        return DesignInputGroup(
          focusNode: _focus,
          enabled: enabled,
          isError: hasError,
          builder: (context, states, child) => child,
          child: field,
        );
      },
      child: control,
    );
  }
}

// The cells a field's words keep however long its add-ons are: a letter and
// the caret. As in Material's InputDecorator, the add-ons stay whole and the
// words have the rest, scrolling under the caret.
const _wordsCols = 2;

// The caret: a block on the cell the field's caret is at (after the
// words; before them, right to left), behind the words, while the field has
// the focus and nothing is selected: solid while the blink [on] shows it,
// else its outline in [stroke], as a terminal draws its cursor.
class _Caret extends CustomPainter {
  _Caret({
    required this.field,
    required this.focus,
    required this.controller,
    required this.on,
    required this.color,
    required this.width,
    required this.height,
    required this.stroke,
    required this.rtl,
  }) : super(repaint: Listenable.merge([focus, controller, on]));

  final GlobalKey field;
  final FocusNode focus;
  final TextEditingController controller;
  final ValueListenable<bool> on;
  final Color color;
  final double width;
  final double height;
  final double stroke;
  final bool rtl;

  static RenderEditable? _editable(RenderObject? node) {
    if (node == null || node is RenderEditable) return node as RenderEditable?;
    RenderEditable? found;
    node.visitChildren((child) => found ??= _editable(child));
    return found;
  }

  /// Where the block stands in [root]'s box, or null while there is no
  /// caret to show.
  static Rect? place(
    RenderObject? root, {
    required double width,
    required double height,
    required bool rtl,
  }) {
    final editable = _editable(root);
    if (root == null || editable == null || !editable.hasSize) return null;
    final selection = editable.selection;
    if (selection == null || !selection.isValid || !selection.isCollapsed) {
      return null;
    }
    // The caret's place on its line: the line's foot at the caret, with
    // none of the platform's offsets for a hairline.
    final foot = editable.getEndpointsForSelection(selection).first.point;
    final line = editable.preferredLineHeight;
    final top = foot.dy - line + (line - height) / 2;
    final left = rtl ? foot.dx - width : foot.dx;
    return MatrixUtils.transformRect(
      editable.getTransformTo(root),
      Rect.fromLTWH(left, top, width, height),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (!focus.hasFocus) return;
    final rect = place(
      field.currentContext?.findRenderObject(),
      width: width,
      height: height,
      rtl: rtl,
    );
    if (rect == null) return;
    if (on.value) {
      canvas.drawRect(rect, Paint()..color = color);
    } else {
      canvas.drawRect(
        rect.deflate(stroke / 2),
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke,
      );
    }
  }

  @override
  bool shouldRepaint(_Caret old) =>
      old.color != color ||
      old.focus != focus ||
      old.controller != controller ||
      old.on != on ||
      old.field != field ||
      old.width != width ||
      old.height != height ||
      old.stroke != stroke ||
      old.rtl != rtl;
}

// Words longer than their line, while the keyboard is elsewhere: the last
// cell says there is more (`feat/rate-l…`), as a pager marks a line that runs
// past the screen, rather than the words stopping as if they were whole.
// Typing in the field, the words scroll under the caret as readline's do.
class _EndMark extends StatelessWidget {
  const _EndMark({
    required this.controller,
    required this.focus,
    required this.child,
  });

  final TextEditingController controller;
  final FocusNode focus;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final grid = context.termGrid;
    return ListenableBuilder(
      listenable: Listenable.merge([controller, focus]),
      child: child,
      builder: (context, field) => LayoutBuilder(
        builder: (context, c) {
          final more =
              !focus.hasFocus &&
              c.maxWidth.isFinite &&
              grid.widthOf(controller.text) > c.maxWidth + 0.5;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: field!),
              if (more)
                ExcludeSemantics(
                  child: SizedBox(
                    width: grid.cellWidth,
                    child: Center(child: Text('…', style: theme.dimStyle)),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

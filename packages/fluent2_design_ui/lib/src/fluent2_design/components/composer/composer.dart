import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../icons.dart';
import '../../localizations.dart';
import '../../theme.dart';
import '../button/button.dart';
import '../input/field_core.dart';

/// Where a [Fluent2Composer] writes: a chat's message box or an
/// assistant's prompt box.
enum Fluent2ComposerAppearance {
  /// A message composer: a field with its send button.
  messages,

  /// An assistant's prompt: a taller field with its tools under it.
  assistant,
}

/// A multiline message field with a send button and optional attachment,
/// emoji, and custom actions. Enter sends on desktop and Shift+Enter
/// inserts a new line. Sending clears the draft.
///
/// Set [onSend] to null to disable the composer. Use [hintText] to explain
/// why the user cannot send a message.
///
/// ```dart
/// Fluent2Composer(onSend: (text) => post(text), hintText: 'Message Design team', onAttach: attach)
/// ```
class Fluent2Composer extends StatefulWidget {
  /// A composer: a field for a message, with its send button.
  const Fluent2Composer({
    required this.onSend,
    this.controller,
    this.hintText,
    this.semanticLabel,
    this.onAttach,
    this.onEmoji,
    this.actions = const [],
    this.style = Fluent2ComposerAppearance.messages,
    this.maxLines = 6,
    this.onChanged,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// Called with the trimmed message when the user sends it.
  final ValueChanged<String>? onSend;

  /// {@template fluent2.textController}
  /// The controller that holds the words; null makes its own.
  /// {@endtemplate}
  final TextEditingController? controller;

  /// Placeholder text. Defaults to the localized equivalent of “Type a message”.
  final String? hintText;

  /// The text field's spoken name; null is "Message" in the app's language.
  final String? semanticLabel;

  /// Called by the attach button; null shows none.
  final VoidCallback? onAttach;

  /// Called by the emoji button; null shows none.
  final VoidCallback? onEmoji;

  /// More commands before send (small subtle icon buttons).
  final List<Widget> actions;

  /// The message or assistant layout.
  final Fluent2ComposerAppearance style;

  /// The most lines the words grow to before they scroll.
  final int maxLines;

  /// Called with the words each time the user changes them.
  final ValueChanged<String>? onChanged;

  /// {@template fluent2.fieldFocusNode}
  /// The focus node it takes focus with; null makes its own.
  /// {@endtemplate}
  final FocusNode? focusNode;

  /// Whether it takes focus when it first appears.
  final bool autofocus;

  @override
  State<Fluent2Composer> createState() => _Fluent2ComposerState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(ObjectFlagProperty<ValueChanged<String>?>.has('onSend', onSend))
      ..add(
        DiagnosticsProperty<TextEditingController>(
          'controller',
          controller,
          defaultValue: null,
        ),
      )
      ..add(StringProperty('hintText', hintText, defaultValue: null))
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null))
      ..add(ObjectFlagProperty<VoidCallback?>.has('onAttach', onAttach))
      ..add(ObjectFlagProperty<VoidCallback?>.has('onEmoji', onEmoji))
      ..add(
        EnumProperty<Fluent2ComposerAppearance>(
          'style',
          style,
          defaultValue: Fluent2ComposerAppearance.messages,
        ),
      )
      ..add(IntProperty('maxLines', maxLines, defaultValue: 6))
      ..add(
        ObjectFlagProperty<ValueChanged<String>?>.has('onChanged', onChanged),
      )
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'));
  }
}

class _Fluent2ComposerState extends State<Fluent2Composer> {
  TextEditingController? _own;
  FocusNode? _ownFocus;

  TextEditingController get _text =>
      widget.controller ?? (_own ??= TextEditingController());
  FocusNode get _focus =>
      widget.focusNode ?? (_ownFocus ??= FocusNode(debugLabel: 'composer'));

  bool get _draft => _text.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _text.addListener(_changed);
    _focus.addListener(_changed);
  }

  @override
  void didUpdateWidget(Fluent2Composer old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      (old.controller ?? _own)?.removeListener(_changed);
      _text.addListener(_changed);
    }
    if (old.focusNode != widget.focusNode) {
      (old.focusNode ?? _ownFocus)?.removeListener(_changed);
      _focus.addListener(_changed);
    }
  }

  @override
  void dispose() {
    _text.removeListener(_changed);
    _focus.removeListener(_changed);
    _own?.dispose();
    _ownFocus?.dispose();
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  void _send() {
    final send = widget.onSend;
    if (send == null || !_draft) return;
    final words = _text.text.trim();
    _text.clear();
    widget.onChanged?.call('');
    send(words);
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final c = t.colors;
    final live = widget.onSend != null;
    final assistant = widget.style == Fluent2ComposerAppearance.assistant;
    final wide = Fluent2Layout.isWide(context);
    final draft = _draft;
    final type = t.body1;
    final own = Fluent2Localizations.of(context);
    final words = Semantics(
      label: widget.semanticLabel ?? own.message,
      child: Fluent2FieldEditor(
        controller: _text,
        focusNode: _focus,
        enabled: live,
        autofocus: widget.autofocus,
        onChanged: widget.onChanged,
        minLines: assistant ? 2 : 1,
        maxLines: widget.maxLines,
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.newline,
        style: type.c(
          live ? c.neutralForeground1 : c.neutralForegroundDisabled,
        ),
        hint: widget.hintText ?? own.typeAMessage,
        hintStyle: type.c(live ? c.neutralForeground4 : c.neutralForeground2),
        hintMaxLines: !live && widget.hintText != null
            ? widget.maxLines
            : assistant
            ? 2
            : 1,
      ),
    );
    final field = !wide
        ? words
        : CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.enter): _send,
              const SingleActivator(LogicalKeyboardKey.numpadEnter): _send,
            },
            child: words,
          );
    final commands = <Widget>[
      if (widget.onAttach != null)
        Fluent2IconButton(
          Fluent2Icons.attach,
          semanticLabel: own.attachFile,
          size: Fluent2ButtonSize.small,
          onPressed: live ? widget.onAttach : null,
        ),
      if (widget.onEmoji != null)
        Fluent2IconButton(
          Fluent2Icons.emoji,
          semanticLabel: own.emoji,
          size: Fluent2ButtonSize.small,
          onPressed: live ? widget.onEmoji : null,
        ),
      ...widget.actions,
    ];
    final canSend = live && draft;
    final send = assistant
        ? Fluent2IconButton(
            Fluent2Icons.sendFilled,
            semanticLabel: own.send,
            appearance: Fluent2ButtonAppearance.primary,
            shape: Fluent2ButtonShape.circular,
            size: Fluent2ButtonSize.small,
            onPressed: canSend ? _send : null,
          )
        : Fluent2IconButton(
            draft ? Fluent2Icons.sendFilled : Fluent2Icons.send,
            semanticLabel: own.send,
            size: Fluent2ButtonSize.small,
            color: canSend ? c.compoundBrandForeground1 : null,
            onPressed: canSend ? _send : null,
          );
    if (assistant) {
      return Fluent2FieldFrame(
        appearance: Fluent2InputAppearance.outline,
        focused: _focus.hasFocus,
        enabled: live,
        textNode: true,
        minHeight: 0,
        radius: t.radiusXLarge,
        padding: const EdgeInsets.fromLTRB(
          Fluent2Spacing.m,
          Fluent2Spacing.m,
          Fluent2Spacing.s,
          Fluent2Spacing.s,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(end: Fluent2Spacing.xs),
              child: field,
            ),
            const SizedBox(height: Fluent2Spacing.s),
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: Fluent2Spacing.xs,
                    runSpacing: Fluent2Spacing.xs,
                    children: commands,
                  ),
                ),
                send,
              ],
            ),
          ],
        ),
      );
    }
    // Centre the first line and its actions in the 40 px face, under a
    // finger the floor's target (40 too). As the entry grows, the actions stay against its bottom edge.
    final strokes = Fluent2FieldFrame.strokesOf(Fluent2InputAppearance.outline);
    final line = math.max(
      t.density.height(40) - strokes.vertical,
      Fluent2Layout.padded(context) ? Fluent2Layout.hitTargetOf(context) : 0.0,
    );
    final lineHeight = type.fontSize! * (type.height ?? 1);
    final lead = math.max(
      0.0,
      (line - MediaQuery.textScalerOf(context).scale(lineHeight)) / 2,
    );
    Widget level(Widget child, AlignmentGeometry at) => ConstrainedBox(
      constraints: BoxConstraints(minHeight: line),
      child: Align(
        alignment: at,
        widthFactor: 1,
        heightFactor: 1,
        child: child,
      ),
    );
    return Fluent2FieldFrame(
      appearance: Fluent2InputAppearance.outline,
      focused: _focus.hasFocus,
      enabled: live,
      textNode: true,
      minHeight: 0,
      padding: const EdgeInsetsDirectional.only(
        start: Fluent2Spacing.m,
        end: Fluent2Spacing.xs,
      ),
      child: _ComposerRow(
        // Past one line by half a line of text: the words run to a second.
        fold: line + MediaQuery.textScalerOf(context).scale(lineHeight) / 2,
        gap: Fluent2Spacing.xs,
        textDirection: Directionality.of(context),
        children: [
          level(
            Padding(
              padding: EdgeInsets.symmetric(vertical: lead),
              child: field,
            ),
            AlignmentDirectional.centerStart,
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final command in commands) level(command, Alignment.center),
            ],
          ),
          level(send, Alignment.center),
        ],
      ),
    );
  }
}

/// A message composer's row: the words, the commands and the send, side by
/// side while the words stand on one line beside them; once they grow past
/// [fold] there, the words take the whole width and the commands and the
/// send stand on a row under them, the commands at its start and the send
/// at its end. Decided by the words' height beside the commands, so a draft
/// that would fit one line under them never flips back.
class _ComposerRow extends MultiChildRenderObjectWidget {
  const _ComposerRow({
    required this.fold,
    required this.gap,
    required this.textDirection,
    required super.children,
  });

  final double fold;
  final double gap;
  final TextDirection textDirection;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderComposerRow(fold, gap, textDirection);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderComposerRow renderObject,
  ) {
    renderObject
      ..fold = fold
      ..gap = gap
      ..textDirection = textDirection;
  }
}

class _ComposerRowParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderComposerRow extends RenderBox
    with
        ContainerRenderObjectMixin<
          RenderBox,
          ContainerBoxParentData<RenderBox>
        >,
        RenderBoxContainerDefaultsMixin<
          RenderBox,
          ContainerBoxParentData<RenderBox>
        > {
  _RenderComposerRow(this._fold, this._gap, this._textDirection);

  double _fold;
  set fold(double value) {
    if (value == _fold) return;
    _fold = value;
    markNeedsLayout();
  }

  double _gap;
  set gap(double value) {
    if (value == _gap) return;
    _gap = value;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  /// Whether the last layout stood the commands under the words.
  bool stacked = false;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! ContainerBoxParentData<RenderBox>) {
      child.parentData = _ComposerRowParentData();
    }
  }

  (RenderBox, RenderBox, RenderBox) get _parts {
    final words = firstChild!;
    final commands = childAfter(words)!;
    return (words, commands, childAfter(commands)!);
  }

  /// The width the words keep beside the commands and the send.
  double _beside(double width, double commands, double send) =>
      math.max(0, width - _gap - commands - send);

  @override
  double computeMinIntrinsicWidth(double height) {
    final (words, commands, send) = _parts;
    return words.getMinIntrinsicWidth(height) +
        _gap +
        commands.getMinIntrinsicWidth(height) +
        send.getMinIntrinsicWidth(height);
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    final (words, commands, send) = _parts;
    return words.getMaxIntrinsicWidth(height) +
        _gap +
        commands.getMaxIntrinsicWidth(height) +
        send.getMaxIntrinsicWidth(height);
  }

  double _height(double width, double Function(RenderBox, double) of) {
    final (words, commands, send) = _parts;
    final cw = commands.getMaxIntrinsicWidth(double.infinity);
    final sw = send.getMaxIntrinsicWidth(double.infinity);
    final foot = math.max(of(commands, cw), of(send, sw));
    final beside = of(words, _beside(width, cw, sw));
    if (beside <= _fold) return math.max(beside, foot);
    return of(words, width) + foot;
  }

  @override
  double computeMinIntrinsicHeight(double width) =>
      _height(width, (c, w) => c.getMinIntrinsicHeight(w));

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _height(width, (c, w) => c.getMaxIntrinsicHeight(w));

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) =>
      defaultComputeDistanceToFirstActualBaseline(baseline);

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final (words, commands, send) = _parts;
    final loose = BoxConstraints(maxHeight: constraints.maxHeight);
    final c = commands.getDryLayout(loose);
    final s = send.getDryLayout(loose);
    final width = constraints.maxWidth;
    final beside = words.getDryLayout(
      BoxConstraints(maxWidth: _beside(width, c.width, s.width)),
    );
    final foot = math.max(c.height, s.height);
    if (beside.height <= _fold) {
      return constraints.constrain(Size(width, math.max(beside.height, foot)));
    }
    final whole = words.getDryLayout(BoxConstraints(maxWidth: width));
    return constraints.constrain(Size(width, whole.height + foot));
  }

  @override
  void performLayout() {
    final (words, commands, send) = _parts;
    final width = constraints.maxWidth;
    final loose = BoxConstraints(maxHeight: constraints.maxHeight);
    commands.layout(loose, parentUsesSize: true);
    send.layout(loose, parentUsesSize: true);
    final c = commands.size;
    final s = send.size;
    final foot = math.max(c.height, s.height);
    final besideWidth = _beside(width, c.width, s.width);
    words.layout(
      BoxConstraints(minWidth: besideWidth, maxWidth: besideWidth),
      parentUsesSize: true,
    );
    final rtl = _textDirection == TextDirection.rtl;
    // From the start edge, [w] wide, as an x from the left.
    double at(double start, double w) => rtl ? width - start - w : start;
    void place(RenderBox child, double start, double top) =>
        (child.parentData! as ContainerBoxParentData<RenderBox>).offset =
            Offset(at(start, child.size.width), top);
    stacked = words.size.height > _fold;
    if (!stacked) {
      final height = math.max(words.size.height, foot);
      place(words, 0, height - words.size.height);
      place(commands, besideWidth + _gap, height - c.height);
      place(send, width - s.width, height - s.height);
      size = constraints.constrain(Size(width, height));
      return;
    }
    words.layout(
      BoxConstraints(minWidth: width, maxWidth: width),
      parentUsesSize: true,
    );
    final top = words.size.height;
    place(words, 0, 0);
    place(commands, 0, top + foot - c.height);
    place(send, width - s.width, top + foot - s.height);
    size = constraints.constrain(Size(width, top + foot));
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}

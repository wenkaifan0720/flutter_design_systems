import 'dart:math' as math;

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

/// A message composer in the Fluent 2 family, a chat's compose box (Fluent
/// ships none of its own): an outline field (the brand underline while it
/// holds focus) whose text grows from one line to [maxLines] and then
/// scrolls, the attach and emoji commands ([onAttach], [onEmoji]; hidden
/// when null) and [actions] at its end, then the send command, its glyph
/// filled in the brand ink once there is a draft and disabled while
/// there is none. [Fluent2ComposerAppearance.assistant] is an assistant's prompt
/// box: 8 rounded, two lines at least, the commands on a row under the
/// words and a brand-filled round send. Enter sends on a desktop
/// (Shift+Enter breaks the line); a send clears the draft. Null [onSend]
/// draws it disabled.
///
/// ```dart
/// Fluent2Composer(onSend: (text) => post(text), hint: 'Message Design team', onAttach: attach)
/// ```
class Fluent2Composer extends StatefulWidget {
  /// A composer: a field for a message, with its send button.
  const Fluent2Composer({
    required this.onSend,
    this.controller,
    this.hint,
    this.label,
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

  /// Told the draft (trimmed) on a send; null disables the composer.
  final ValueChanged<String>? onSend;

  /// The controller that holds the words; null makes its own.
  final TextEditingController? controller;

  /// The empty words; null is "Type a message" in the app's language.
  final String? hint;

  /// The text field's spoken name; null is "Message" in the app's language.
  final String? label;

  /// Called by the attach button; null shows none.
  final VoidCallback? onAttach;

  /// Called by the emoji button; null shows none.
  final VoidCallback? onEmoji;

  /// More commands before send (small subtle icon buttons).
  final List<Widget> actions;

  /// Overrides its component theme and Fluent's own, slot by slot.
  final Fluent2ComposerAppearance style;

  /// The most lines the words grow to before they scroll.
  final int maxLines;

  /// Called with the words each time the user changes them.
  final ValueChanged<String>? onChanged;

  /// The focus node it takes focus with; null makes its own.
  final FocusNode? focusNode;

  /// Whether it takes focus when it first appears.
  final bool autofocus;

  @override
  State<Fluent2Composer> createState() => _Fluent2ComposerState();
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
      label: widget.label ?? own.message,
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
        hint: widget.hint ?? own.typeAMessage,
        hintStyle: type.c(
          live ? c.neutralForeground4 : c.neutralForegroundDisabled,
        ),
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
          label: own.attachFile,
          size: Fluent2ButtonSize.small,
          onPressed: live ? widget.onAttach : null,
        ),
      if (widget.onEmoji != null)
        Fluent2IconButton(
          Fluent2Icons.emoji,
          label: own.emoji,
          size: Fluent2ButtonSize.small,
          onPressed: live ? widget.onEmoji : null,
        ),
      ...widget.actions,
    ];
    final canSend = live && draft;
    final send = assistant
        ? Fluent2IconButton(
            Fluent2Icons.sendFilled,
            label: own.send,
            appearance: Fluent2ButtonAppearance.primary,
            shape: Fluent2ButtonShape.circular,
            size: Fluent2ButtonSize.small,
            onPressed: canSend ? _send : null,
          )
        : Fluent2IconButton(
            draft ? Fluent2Icons.sendFilled : Fluent2Icons.send,
            label: own.send,
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
        radius: Fluent2Radius.xLarge,
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
    // The row grows with the text and keeps its buttons at the foot, so
    // every child stands one line tall at least, centred in it (design6
    // I3): the 40 box inside its strokes, or a finger's 48. At one line the
    // foot and the middle are the same place; more lines start where the
    // one line stands.
    final strokes = Fluent2FieldFrame.strokesOf(Fluent2InputAppearance.outline);
    final line = math.max(
      t.density.height(40) - strokes.vertical,
      Fluent2Layout.padded(context) ? Fluent2Layout.touchHitTarget : 0.0,
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: level(
              Padding(
                padding: EdgeInsets.symmetric(vertical: lead),
                child: field,
              ),
              AlignmentDirectional.centerStart,
            ),
          ),
          const SizedBox(width: Fluent2Spacing.xs),
          for (final command in commands) level(command, Alignment.center),
          level(send, Alignment.center),
        ],
      ),
    );
  }
}

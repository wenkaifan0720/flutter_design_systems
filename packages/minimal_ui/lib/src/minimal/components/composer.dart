import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../chrome_metrics.dart';
import '../internal/cap_label.dart';
import '../internal/field.dart';
import '../internal/styled.dart';
import '../internal/text_entry.dart';
import '../localizations.dart';
import '../shapes.dart';
import '../theme.dart';
import 'button.dart';
import 'icon_button.dart';
import 'pressable.dart';
import 'screen.dart';

/// A [MinimalComposer]'s register: `messages` is the one-line bordered box a
/// chat or a quick reply rests in, the attach and send squares inside it;
/// `assistant` is the issue-comment box — a taller writing area over its
/// own toolbar (attach, a model or visibility pill, dictate, send).
enum MinimalComposerStyle {
  /// The one-line box of a chat or a quick reply.
  messages,

  /// The taller writing area over its own toolbar.
  assistant,
}

/// Minimal's message input: a bordered box on the surface, a large
/// control's 40 px at rest in `messages`, growing line by line as the draft
/// does, with the 32 px attach control and send square inside it, centred on
/// the first line. Focus draws the box's hairline in the focus colour, and
/// keyboard focus on the draft also draws the kit's solid 2 px ring, as a
/// text field's does.
///
/// Send is derived from the draft: the arrow when there is something to
/// send (a dimmed arrow when there is not), the solid stop square while
/// [busy],
/// the mic when the draft is empty and [onVoice] is wired. [onSend]
/// receives the trimmed draft and the field clears itself. Cmd+Enter (or
/// Ctrl+Enter) sends from the keyboard; Enter alone breaks the line.
///
/// ```dart
/// MinimalComposer(controller: draft, onSend: send)
/// ```
class MinimalComposer extends StatefulWidget {
  /// A message box.
  const MinimalComposer({
    super.key,
    this.controller,
    this.hint,
    this.onSend,
    this.onAttach,
    this.onVoice,
    this.onDictate,
    this.onStop,
    this.onModel,
    this.onRemoveAttachment,
    this.attachment,
    this.model = 'Everyday',
    this.busy = false,
    this.enabled = true,
    this.autofocus = false,
    this.style = MinimalComposerStyle.messages,
    this.action,
    this.onChanged,
    this.focusNode,
  });

  /// The draft; null keeps one of its own.
  final TextEditingController? controller;

  /// Unstated, "Message" (messages) or "Leave a comment…" (assistant).
  final String? hint;

  /// A file riding with the draft, shown as a chip above the text.
  final String? attachment;

  /// The assistant toolbar's pill label (a model, a visibility).
  final String model;

  /// Sends the trimmed draft; the field then clears itself.
  final ValueChanged<String>? onSend;

  /// Reports each edit of the draft.
  final ValueChanged<String>? onChanged;

  /// Opens a file picker: the attach control; null hides it.
  final VoidCallback? onAttach;

  /// Starts a voice message: the microphone in an empty draft; null hides it.
  final VoidCallback? onVoice;

  /// Starts dictation into the draft (assistant); null hides it.
  final VoidCallback? onDictate;

  /// Stops a streaming reply: the send seat while [busy].
  final VoidCallback? onStop;

  /// Opens the model or visibility choice behind the [model] pill.
  final VoidCallback? onModel;

  /// Removes the [attachment] chip.
  final VoidCallback? onRemoveAttachment;

  /// A reply is streaming: send becomes stop.
  final bool busy;

  /// False dims the whole box once and takes no text, taps or focus; its
  /// controls leave the semantics tree, the field announcing it disabled.
  final bool enabled;

  /// Whether it takes focus when it first shows.
  final bool autofocus;

  /// Its register: messages (a chat) or assistant.
  final MinimalComposerStyle style;

  /// A flow-owned action in the send seat (usually a
  /// [MinimalComposerAction]); it owns its own enabled state.
  final Widget? action;

  /// Its focus node, for a caller that moves focus to it; null keeps one
  /// of its own.
  final FocusNode? focusNode;

  @override
  State<MinimalComposer> createState() => _MinimalComposerState();
}

class _MinimalComposerState extends State<MinimalComposer> {
  late TextEditingController _controller =
      widget.controller ?? TextEditingController();
  bool _focused = false;

  /// The draft's focus, the caller's or one of its own: the keyboard ring
  /// shows while it has it.
  FocusNode? _ownedDraft;
  FocusNode get _draft =>
      widget.focusNode ??
      (_ownedDraft ??= FocusNode(debugLabel: 'MinimalComposer draft'));

  @override
  void initState() {
    super.initState();
    _draft.addListener(_rebuild);
    FocusManager.instance.addHighlightModeListener(_modeChanged);
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  void _modeChanged(FocusHighlightMode mode) => _rebuild();

  @override
  void didUpdateWidget(covariant MinimalComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _ownedDraft)?.removeListener(_rebuild);
      _draft.addListener(_rebuild);
    }
    if (oldWidget.controller == widget.controller) return;
    final value = _controller.value;
    if (oldWidget.controller == null) _controller.dispose();
    _controller = widget.controller ?? TextEditingController.fromValue(value);
  }

  @override
  void dispose() {
    FocusManager.instance.removeHighlightModeListener(_modeChanged);
    _draft.removeListener(_rebuild);
    _ownedDraft?.dispose();
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  bool get _live => widget.enabled && !widget.busy;

  /// A disabled composer's controls stay wired to nothing rather than
  /// unwired, so they keep their full ink: the box's own dimming is the
  /// one the eye reads, never doubled by each control's.
  static void _inert() {}

  /// A control's handler as the box's state allows it.
  VoidCallback? _wire(VoidCallback? onPressed) =>
      widget.enabled || onPressed == null ? onPressed : _inert;

  /// A control as the box's state allows it: gone from the semantics tree
  /// while the box is disabled, since it cannot be used.
  Widget _quiet(Widget control) =>
      widget.enabled ? control : ExcludeSemantics(child: control);

  void _send() {
    final value = _controller.value;
    final onSend = widget.onSend;
    if (onSend == null ||
        !_live ||
        (value.composing.isValid && !value.composing.isCollapsed)) {
      return;
    }
    final text = value.text.trim();
    if (text.isEmpty && widget.attachment == null) return;
    _controller.clear();
    onSend(text);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final assistant = widget.style == MinimalComposerStyle.assistant;
    final enabled = widget.enabled;

    final field = CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.enter, meta: true): _send,
        const SingleActivator(LogicalKeyboardKey.enter, control: true): _send,
      },
      child: TextField(
        controller: _controller,
        focusNode: _draft,
        onChanged: widget.onChanged,
        enabled: enabled,
        autofocus: widget.autofocus,
        minLines: assistant ? 3 : 1,
        maxLines: assistant ? 10 : 6,
        style: t.body.c(t.foreground),
        cursorColor: t.primary,
        cursorWidth: MinimalFieldMetrics.cursor,
        textCapitalization: TextCapitalization.sentences,
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.newline,
        // Bare: the box below draws everything, so neither the platform's
        // density nor an app's InputDecorationTheme moves the line.
        decoration: minimalBareDecoration(
          hint:
              widget.hint ??
              MinimalLocalizations.of(context)
                  .composerHint(assistant: assistant),
          hintStyle: t.body.c(t.textTertiary),
          // A chat's box starts one line tall, so its hint is one line, cut
          // with an ellipsis: a wrapped hint would hold the box at two.
          hintMaxLines: assistant ? null : 1,
        ),
      ),
    );

    // One line's band inside the rims: the large control's height at rest,
    // more when larger text needs it. Every child of the messages row takes
    // it as its height, so at one line their centres are one centre; the
    // air above the text puts a first line of several where the one was.
    final rim = t.hairline;
    final line = minimalLineHeight(context, t.body);
    final band = math.max(
      t.density.height(MinimalChromeMetrics.controlLg) - 2 * rim,
      line + 2 * MinimalSpacing.s4,
    );
    final air = minimalLineAir(height: band + 2 * rim, rim: rim, line: line);
    Widget seat(Widget control) => SizedBox(
      height: band,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: MinimalSpacing.s4 - rim),
        child: Center(child: control),
      ),
    );

    final attach = widget.onAttach == null
        ? null
        : _quiet(
            MinimalIconButton(
              LucideIcons.paperclip,
              label: MinimalLocalizations.of(context).addAttachment,
              // The assistant's toolbar is a row of small controls; the
              // messages box seats standard ones.
              size: assistant
                  ? MinimalButtonSize.small
                  : MinimalButtonSize.medium,
              variant: MinimalIconButtonVariant.ghost,
              onPressed: _wire(widget.onAttach),
            ),
          );

    final attachment = widget.attachment;
    final chip = attachment == null
        ? null
        : Padding(
            padding: const EdgeInsets.fromLTRB(
              MinimalSpacing.s8,
              MinimalSpacing.s8,
              MinimalSpacing.s8,
              0,
            ),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: _AttachmentChip(
                name: attachment,
                onRemove: _wire(widget.onRemoveAttachment),
                quiet: !enabled,
              ),
            ),
          );

    final box = ValueListenableBuilder<TextEditingValue>(
      valueListenable: _controller,
      builder: (context, value, _) {
        final ready = value.text.trim().isNotEmpty || attachment != null;
        final send = _quiet(
          widget.action ??
              (widget.busy
                  ? MinimalComposerAction(
                      icon: MinimalComposerAction.stop,
                      label: MinimalLocalizations.of(context).stopResponse,
                      style: widget.style,
                      onPressed: _wire(widget.onStop),
                    )
                  : !ready && widget.onVoice != null
                  ? _Seat(
                      icon: LucideIcons.mic,
                      label: MinimalLocalizations.of(context).voiceMessage,
                      onPressed: _wire(widget.onVoice),
                    )
                  : MinimalComposerAction(
                      style: widget.style,
                      onPressed: !enabled
                          ? (widget.onSend == null ? null : _inert)
                          : ready && _live && widget.onSend != null
                          ? _send
                          : null,
                    )),
        );

        if (!assistant) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ?chip,
              // Bottom-aligned so the seats stay by the last line as the
              // draft grows; at one line every child is the band's height,
              // so bottom and centre are one place.
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (attach != null) seat(attach),
                  Expanded(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: band),
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: MinimalSpacing.s8,
                            vertical: air,
                          ),
                          // By its line (ui_core keeps an entry that may
                          // wrap where it is laid out: it moves as lines
                          // come and go), on the seats' middle.
                          child: field,
                        ),
                      ),
                    ),
                  ),
                  seat(send),
                ],
              ),
            ],
          );
        }

        final onModel = widget.onModel;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ?chip,
            // Several lines from the top: the first where the messages
            // box's one line stands.
            Padding(
              padding: EdgeInsets.fromLTRB(
                MinimalSpacing.s12,
                air,
                MinimalSpacing.s12,
                MinimalSpacing.s4,
              ),
              child: field,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                MinimalSpacing.s4,
                0,
                MinimalSpacing.s4,
                MinimalSpacing.s4,
              ),
              child: Row(
                children: [
                  ?attach,
                  Expanded(
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: onModel == null
                          ? const SizedBox.shrink()
                          : _quiet(
                              _ModelPill(
                                label: widget.model,
                                onPressed: _wire(onModel),
                              ),
                            ),
                    ),
                  ),
                  if (widget.onDictate != null)
                    _quiet(
                      MinimalIconButton(
                        LucideIcons.mic,
                        label: MinimalLocalizations.of(context).dictateMessage,
                        size: MinimalButtonSize.small,
                        variant: MinimalIconButtonVariant.ghost,
                        onPressed: _wire(widget.onDictate),
                      ),
                    ),
                  const MinimalGap(MinimalSpacing.s4),
                  send,
                ],
              ),
            ),
          ],
        );
      },
    );

    return Material(
      type: MaterialType.transparency,
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onFocusChange: (focused) => setState(() => _focused = focused),
        child: AnimatedOpacity(
          opacity: enabled ? 1 : 0.45,
          duration: MinimalMotion.fast,
          // Disabled, the box is the one dimmed thing: nothing inside it
          // takes a tap or a focus, and its controls say nothing.
          child: IgnorePointer(
            ignoring: !enabled,
            child: ExcludeFocus(
              excluding: !enabled,
              child: AnimatedContainer(
                duration: MinimalMotion.fast,
                constraints: BoxConstraints(minHeight: band + 2 * rim),
                decoration: minimalFrame(
                  assistant ? t.shapes.medium : t.shapes.small,
                  fill: t.card,
                  side: BorderSide(
                    color: _focused && enabled ? t.ring : t.border,
                    width: t.hairline,
                  ),
                ),
                foregroundDecoration: minimalFieldRing(
                  t,
                  shown:
                      enabled &&
                      _draft.hasFocus &&
                      FocusManager.instance.highlightMode ==
                          FocusHighlightMode.traditional,
                  shape: assistant ? t.shapes.medium : t.shapes.small,
                ),
                child: box,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The send seat of a [MinimalComposer], public for a flow that owns its
/// action: a square in the accent, the act to take in both registers (32 px
/// in `messages`, 28 among the `assistant` toolbar's small controls),
/// holding the arrow (or [icon]). No [onPressed] dims it: nothing to send
/// yet.
///
/// ```dart
/// MinimalComposerAction(onPressed: send)
/// ```
class MinimalComposerAction extends StatelessWidget {
  /// A button in the composer's send seat.
  const MinimalComposerAction({
    super.key,
    this.onPressed,
    this.icon = LucideIcons.arrowUp,
    this.label,
    this.style = MinimalComposerStyle.messages,
    this.focusNode,
    this.autofocus = false,
  });

  /// Its press; null disables it.
  final VoidCallback? onPressed;

  /// Its glyph.
  final IconData icon;

  /// What a screen reader announces.
  final String? label;

  /// The composer register it matches.
  final MinimalComposerStyle style;

  /// The stop seat's glyph: passed as [icon], the seat paints a filled
  /// square in the glyph's ink — an outline square at 16 px reads as a
  /// checkbox, not a stop.
  static const IconData stop = LucideIcons.square;

  /// Its focus node, for a caller that moves focus to it; null keeps one
  /// of its own.
  final FocusNode? focusNode;

  /// Whether it takes keyboard focus when it first appears.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    // Send is the act to take in either register, so it wears the accent
    // in both; only its side follows the controls beside it.
    return _Seat(
      focusNode: focusNode,
      autofocus: autofocus,
      icon: icon,
      label: label ?? MinimalLocalizations.of(context).sendMessage,
      onPressed: onPressed,
      fill: t.primary,
      glyph: t.primaryForeground,
      small: style == MinimalComposerStyle.assistant,
    );
  }
}

/// A square control in the composer, a standard control's side (a small
/// one's in the assistant toolbar): filled when [fill] is given, else the
/// bare glyph.
class _Seat extends StatelessWidget {
  const _Seat({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.fill,
    this.glyph,
    this.small = false,
    this.focusNode,
    this.autofocus = false,
  });

  final FocusNode? focusNode;
  final bool autofocus;
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color? fill;
  final Color? glyph;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final side = t.density.height(
      small ? MinimalChromeMetrics.controlSm : MinimalChromeMetrics.control,
    );
    // Concentric inside the messages box's small step, 4 px in; the
    // toolbar's small seat keeps its own corners 2 px in.
    final seat = MinimalShapes.inset(
      t.shapes.small,
      small ? 2 : MinimalSpacing.s4,
    );
    return MinimalPressable(
      focusNode: focusNode,
      autofocus: autofocus,
      onPressed: onPressed,
      enabled: onPressed != null,
      shape: seat,
      semanticLabel: label,
      face: fill,
      ink: fill == null ? null : glyph,
      child: Container(
        width: side,
        height: side,
        decoration: minimalFrame(seat, fill: fill),
        alignment: Alignment.center,
        child: icon == MinimalComposerAction.stop
            ? Container(
                width: _stop,
                height: _stop,
                decoration: BoxDecoration(
                  color: glyph ?? t.mutedForeground,
                  borderRadius: BorderRadius.circular(t.smallRadius / 2),
                ),
              )
            : MinimalIcon(
                icon,
                size: MinimalIconSize.i16,
                color: glyph ?? t.mutedForeground,
              ),
      ),
    );
  }

  /// The solid stop square's side inside the seat.
  static const double _stop = 10;
}

/// The file riding with a draft: a 28 px hairline chip on the quiet fill,
/// the file glyph, its name, and the remove `x`.
class _AttachmentChip extends StatelessWidget {
  const _AttachmentChip({
    required this.name,
    required this.onRemove,
    required this.quiet,
  });

  final String name;
  final VoidCallback? onRemove;

  /// Keep the remove control out of the semantics tree (a disabled box).
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    return Container(
      padding: const EdgeInsetsDirectional.only(start: MinimalSpacing.s8),
      decoration: minimalFrame(
        t.shapes.mark,
        fill: t.muted,
        side: BorderSide(color: t.border, width: t.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MinimalIcon(LucideIcons.fileText, size: MinimalIconSize.i14),
          const MinimalGap(MinimalChromeMetrics.iconGap),
          Flexible(
            // A file's name is a name, in the sans, as the upload list
            // prints it; only its size would be a figure.
            child: Text(
              name,
              style: t.bodySmall.c(t.foreground),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ExcludeSemantics(
            excluding: quiet,
            child: MinimalIconButton(
              LucideIcons.x,
              label: MinimalLocalizations.of(context).removeAttachment,
              size: MinimalButtonSize.small,
              variant: MinimalIconButtonVariant.ghost,
              onPressed: onRemove,
            ),
          ),
        ],
      ),
    );
  }
}

/// The assistant toolbar's pill: its label in the quiet ink and a chevron.
class _ModelPill extends StatelessWidget {
  const _ModelPill({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    return MinimalPressable(
      onPressed: onPressed,
      enabled: onPressed != null,
      semanticLabel: label,
      child: ExcludeSemantics(
        child: Container(
          // The toolbar's small squares' height, at the theme's density.
          constraints: BoxConstraints(
            minHeight: t.density.height(MinimalChromeMetrics.controlSm),
          ),
          padding: const EdgeInsets.symmetric(horizontal: MinimalSpacing.s8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: minimalCapLabel(
                  Text(
                    label,
                    style: t.bodySmall.c(t.mutedForeground),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const MinimalGap(MinimalSpacing.s4),
              const MinimalIcon(
                LucideIcons.chevronDown,
                size: MinimalIconSize.i14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A conversation page with its composer docked at the bottom edge, over
/// the footer's hairline, and the transcript filling the rest. [bodyBuilder]
/// receives the trailing inset to give the INNER scrollable's content (never
/// the viewport), so the last message clears the composer's rule.
///
/// ```dart
/// MinimalComposerLayout(composer: MinimalComposer(onSend: send), bodyBuilder: (context, bottomInset) => ListView(padding: EdgeInsets.only(bottom: bottomInset), children: messages))
/// ```
class MinimalComposerLayout extends StatelessWidget {
  /// A page with [composer] docked under its body.
  const MinimalComposerLayout({
    super.key,
    required this.composer,
    required this.bodyBuilder,
    this.topBar,
    this.fullBleed = false,
  });

  /// The message box at the bottom.
  final Widget composer;

  /// Builds the transcript; give `bottomInset` to its scrollable's content padding.
  final Widget Function(BuildContext context, double bottomInset) bodyBuilder;

  /// The page's bar.
  final Widget? topBar;

  /// Whether the body runs to the screen's sides, without the gutter.
  final bool fullBleed;

  @override
  Widget build(BuildContext context) => MinimalScaffold(
    scroll: false,
    padding: EdgeInsets.zero,
    topBar: topBar,
    fullBleed: fullBleed,
    footer: composer,
    body: Builder(
      builder: (context) => bodyBuilder(
        context,
        MediaQuery.paddingOf(context).bottom + MinimalSpacing.s12,
      ),
    ),
  );
}

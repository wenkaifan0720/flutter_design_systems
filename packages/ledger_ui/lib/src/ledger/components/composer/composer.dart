import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../chrome_metrics.dart';
import '../../internal/text_input.dart';
import '../../theme.dart';
import '../chip/chip.dart';
import '../icon-button/icon_button.dart';
import '../pressable/pressable.dart';

/// How a [LedgerComposer] sits.
enum LedgerComposerStyle {
  /// A message box in one round of the raised paper, 46 tall, growing to five
  /// lines: attach at its start, the words, then send, voice or stop.
  messages,

  /// A slip for a longer ask: the words on top (two lines to six), a toolbar
  /// of the page's own chips under them and the send at the foot.
  assistant,
}

/// The message input that docks at the foot of a conversation: a ringed round
/// of the raised paper holding the field, [onAttachPressed] before it, and at
/// its end the green send once there are words to send, [onVoicePressed] while
/// there are none, and the ink stop while [sending] runs ([onStopPressed] ends
/// it). Enter sends from a hardware keyboard on a single line field; the field
/// grows with its words. Stand it as a `LedgerScreen(footer:)` or in a sheet's
/// foot, where the band owns the room round it. [LedgerComposerStyle.assistant]
/// is the larger slip for an ask to an assistant, with a [toolbar] under the
/// words. Says its [semanticLabel] (the hint by default), and each act its own
/// name.
///
/// ```dart
/// LedgerComposer(controller: reply, hintText: 'Write a reply', onAttachPressed: pick, onSubmitted: () => send(reply.text))
/// ```
class LedgerComposer extends StatefulWidget {
  /// A message input that sends its words with [onSubmitted].
  const LedgerComposer({
    this.controller,
    this.hintText = 'Write a message',
    this.style = LedgerComposerStyle.messages,
    this.onSubmitted,
    this.onStopPressed,
    this.onAttachPressed,
    this.onVoicePressed,
    this.sending = false,
    this.toolbar = const [],
    this.sendLabel = 'Send',
    this.semanticLabel,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// The words typed; null gives the composer one of its own.
  final TextEditingController? controller;

  /// What stands in the field while it is empty.
  final String hintText;

  /// How the composer sits.
  final LedgerComposerStyle style;

  /// Sends the words; null leaves the send inert.
  final VoidCallback? onSubmitted;

  /// Ends the send in flight (shown while [sending]).
  final VoidCallback? onStopPressed;

  /// Opens the attachment picker; the glyph is left out without it.
  final VoidCallback? onAttachPressed;

  /// Starts a spoken message; shown while the field is empty.
  final VoidCallback? onVoicePressed;

  /// Whether a send is in flight: the stop shows in the send's place.
  final bool sending;

  /// The assistant slip's chips under the words.
  final List<Widget> toolbar;

  /// What a screen reader says the send is.
  final String sendLabel;

  /// Its name for a screen reader; null speaks the hint.
  final String? semanticLabel;

  /// {@macro ledger.focusNode}
  final FocusNode? focusNode;

  /// {@macro ledger.autofocus}
  final bool autofocus;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<TextEditingController>(
          'controller',
          controller,
          defaultValue: null,
        ),
      )
      ..add(StringProperty('hintText', hintText))
      ..add(EnumProperty<LedgerComposerStyle>('style', style))
      ..add(ObjectFlagProperty<VoidCallback>.has('onSubmitted', onSubmitted))
      ..add(
        ObjectFlagProperty<VoidCallback>.has('onStopPressed', onStopPressed),
      )
      ..add(
        ObjectFlagProperty<VoidCallback>.has(
          'onAttachPressed',
          onAttachPressed,
        ),
      )
      ..add(
        ObjectFlagProperty<VoidCallback>.has('onVoicePressed', onVoicePressed),
      )
      ..add(FlagProperty('sending', value: sending, ifTrue: 'sending'))
      ..add(StringProperty('sendLabel', sendLabel))
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null))
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'));
  }

  @override
  State<LedgerComposer> createState() => _LedgerComposerState();
}

class _LedgerComposerState extends State<LedgerComposer> {
  TextEditingController? _own;

  TextEditingController get _controller =>
      widget.controller ?? (_own ??= TextEditingController());

  @override
  void didUpdateWidget(LedgerComposer old) {
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final assistant = widget.style == LedgerComposerStyle.assistant;
    return Semantics(
      container: true,
      label: widget.semanticLabel ?? widget.hintText,
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: _controller,
        builder: (context, value, _) {
          // The room each ring's target takes round its 36 (4 for a finger, none
          // for a pointer), taken from the 5 round the rings.
          final room = math.min(
            _padEnd - 1,
            math.max(
              0.0,
              (DesignTapTargets.of(context).floorOn().height -
                      LedgerChromeMetrics.ringButton) /
                  2,
            ),
          );
          final words = value.text.trim().isNotEmpty;
          final field = LedgerTextInput(
            controller: _controller,
            hintText: widget.hintText,
            style: t.body.colored(t.textPrimary),
            hintStyle: t.body.colored(t.textTertiary),
            focusNode: widget.focusNode,
            autofocus: widget.autofocus,
            maxLines: assistant ? _assistantLines : _messageLines,
            textInputAction: assistant
                ? TextInputAction.newline
                : TextInputAction.send,
            keyboardType: TextInputType.multiline,
            // The send key sends and the field keeps the focus for the next
            // message (an empty one sends nothing): in onEditingComplete,
            // never onSubmitted, whose submit restarts the text input of a
            // field that keeps the focus (a browser's then takes no typing).
            onEditingComplete: assistant
                ? null
                : () {
                    if (words) widget.onSubmitted?.call();
                  },
          );
          final end = _End(
            sending: widget.sending,
            words: words,
            sendLabel: widget.sendLabel,
            onSend: widget.onSubmitted,
            onStop: widget.onStopPressed,
            onVoice: widget.onVoicePressed,
          );
          if (assistant) {
            return DecoratedBox(
              decoration: BoxDecoration(
                color: t.surface,
                borderRadius: BorderRadius.circular(t.cardRadius),
                border: Border.all(color: t.border),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  _slipPad,
                  _slipPad,
                  _slipFoot,
                  _slipFoot,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: _slipMin),
                      child: field,
                    ),
                    const SizedBox(height: _slipGap),
                    // The toolbar's rings stand at its chips' height, so
                    // the row shows one top and one bottom at every density.
                    Row(
                      spacing: _toolGap,
                      children: [
                        if (widget.onAttachPressed != null)
                          _attach(side: LedgerChip.heightOf(t)),
                        Expanded(
                          child: Wrap(
                            spacing: _toolGap,
                            runSpacing: _toolGap,
                            children: widget.toolbar,
                          ),
                        ),
                        _End(
                          sending: widget.sending,
                          words: words,
                          sendLabel: widget.sendLabel,
                          onSend: widget.onSubmitted,
                          onStop: widget.onStopPressed,
                          onVoice: widget.onVoicePressed,
                          side: LedgerChip.heightOf(t),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }
          return DecoratedBox(
            decoration: BoxDecoration(
              color: t.surface,
              // The round of one line, kept as the box grows: its discs stay
              // concentric with the corners.
              borderRadius: BorderRadius.circular(
                math.min(t.controlRadius, LedgerChromeMetrics.searchHeight / 2),
              ),
              border: Border.all(color: t.border),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: LedgerChromeMetrics.searchHeight,
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  left: widget.onAttachPressed == null
                      ? _pad
                      : _padAttach - room,
                  right: _padEnd - room,
                  top: _padEnd - room,
                  bottom: _padEnd - room,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  spacing: _gap - room,
                  children: [
                    if (widget.onAttachPressed != null) _attach(),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: _lift + room),
                        child: field,
                      ),
                    ),
                    end,
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// The attach ring: the small icon button, or at [side] (the assistant's
  /// toolbar, beside its chips) the composer's own ring.
  Widget _attach({double? side}) => side == null
      ? LedgerIconButton.outlined(
          LucideIcons.paperclip,
          semanticLabel: 'Attach',
          size: LedgerIconButtonSize.small,
          onPressed: widget.onAttachPressed,
        )
      : _Disc(
          icon: LucideIcons.paperclip,
          label: 'Attach',
          ringed: true,
          side: side,
          onTap: widget.onAttachPressed,
        );

  // DERIVED (the source has no composer): the message round is the search
  // field's 46, its acts the 36 rings and discs of the top bar, 5 round them.
  static const int _messageLines = 5;
  static const int _assistantLines = 6;
  static const double _pad = 16;
  static const double _round = 46;
  static const double _act = 36;
  // Each act centred in the round's height.
  static const double _padAttach = (_round - _act) / 2;
  static const double _padEnd = (_round - _act) / 2;
  static const double _gap = 8;
  static const double _lift = 10;
  static const double _slipPad = 16;
  static const double _slipFoot = 10;
  static const double _slipMin = 48;
  static const double _slipGap = 8;
  static const double _toolGap = 6;
}

/// The end of the composer: send, voice or stop.
class _End extends StatelessWidget {
  const _End({
    required this.sending,
    required this.words,
    required this.sendLabel,
    required this.onSend,
    required this.onStop,
    required this.onVoice,
    this.side,
  });

  final bool sending;
  final bool words;
  final String sendLabel;
  final VoidCallback? onSend;
  final VoidCallback? onStop;
  final VoidCallback? onVoice;

  /// The side its ring stands at; null, the small icon button's.
  final double? side;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    if (sending && onStop != null) {
      return _Disc(
        icon: LucideIcons.square,
        label: 'Stop',
        fill: t.textPrimary,
        ink: t.surface,
        side: side,
        onTap: onStop,
      );
    }
    if (!words && onVoice != null) {
      return side == null
          ? LedgerIconButton.outlined(
              LucideIcons.mic,
              semanticLabel: 'Voice message',
              size: LedgerIconButtonSize.small,
              onPressed: onVoice,
            )
          : _Disc(
              icon: LucideIcons.mic,
              label: 'Voice message',
              ringed: true,
              side: side,
              onTap: onVoice,
            );
    }
    // With nothing to send it is written in pencil, as any act out of
    // reach: no fill, the light rule round it, its arrow in the third ink.
    final live = words && onSend != null;
    return _Disc(
      icon: LucideIcons.arrowUp,
      label: sendLabel,
      fill: live ? t.accent : null,
      ink: live ? t.onAccent : t.textTertiary,
      ringed: !live,
      side: side,
      onTap: words ? onSend : null,
    );
  }
}

/// A round act of the composer: 36 across at standard and 4 off each
/// density step, as the small icon button beside it is (or [side] across),
/// a glyph in its middle; filled, or [ringed] in the rule as that button.
class _Disc extends StatelessWidget {
  const _Disc({
    required this.icon,
    required this.label,
    required this.onTap,
    this.fill,
    this.ink,
    this.ringed = false,
    this.side,
  });

  final IconData icon;
  final String label;
  final Color? fill;
  final Color? ink;
  final bool ringed;
  final double? side;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final across =
        side ??
        t.density.height(
          LedgerChromeMetrics.ringButton,
          floor: LedgerChromeMetrics.densityFloor,
        );
    return TapTargetPadding(
      child: LedgerPressable(
        onTap: onTap,
        label: label,
        radius: across / 2,
        child: Container(
          width: across,
          height: across,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: fill,
            shape: BoxShape.circle,
            border: ringed ? Border.all(color: t.border) : null,
          ),
          child: Icon(
            icon,
            size: LedgerChromeMetrics.ringGlyph,
            // A ringed way that cannot act is in pencil.
            color: onTap == null && ringed
                ? t.textTertiary
                : ink ?? t.textPrimary,
          ),
        ),
      ),
    );
  }
}

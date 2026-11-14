import 'package:material_ui/material_ui.dart'
    show
        InputBorder,
        InputDecoration,
        Material,
        MaterialType,
        TextField,
        Theme,
        VisualDensity;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../glyphs.dart';

import '../../chrome_metrics.dart';
import '../../internal/face.dart';
import '../../internal/field_owner.dart';
import '../../internal/hit_slop.dart';
import '../../theme.dart';
import '../icon-button/round_button.dart';
import '../pressable/pressable.dart';
import '../../localizations.dart';
import '../../editing.dart';
import '../../internal/dim.dart';

/// How a [FrostedComposer] stands: [messages] a single round line with the
/// seat for send at its end (a thread's reply bar), [assistant] a taller
/// box with its text over a row of tools (a prompt to an assistant).
enum FrostedComposerVariant {
  /// A single round line with send at its end.
  messages,

  /// A taller box, its text over a row of tools.
  assistant,
}

/// A composer: the box a message or a prompt is written in, a pill 48 tall
/// of the high glass in its rim and edge (the search well's), 4 round its
/// parts. The text grows with what is written (to five lines, six for an
/// assistant), an attach button (a glass round) stands before it when
/// [onAttach] is given, and at its end one seat: send, a round of the ink
/// act once there is text; stop while a reply is [busy] and [onStop] is
/// given; a microphone (a glass round) while the box is empty and
/// [onVoice] is given. Send hands [onSend] the trimmed text and empties the
/// box. A false [enabled] fades it and takes no text. DERIVED: the source
/// has no composer; the search well and the round buttons lend the faces.
///
/// ```dart
/// FrostedComposer(hint: 'Message Maren', onSend: send, onAttach: attach)
/// ```
class FrostedComposer extends StatefulWidget {
  /// Creates a [FrostedComposer].
  const FrostedComposer({
    this.controller,
    this.hint,
    this.onSend,
    this.onAttach,
    this.onVoice,
    this.onStop,
    this.onChanged,
    this.busy = false,
    this.enabled = true,
    this.variant = FrostedComposerVariant.messages,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// The text, when the page owns it; the composer keeps its own otherwise.
  final TextEditingController? controller;

  /// The hint while the box is empty: "Message", or "Ask anything" for an
  /// assistant.
  final String? hint;

  /// What send does with the written text.
  final ValueChanged<String>? onSend;

  /// The node that holds this part's keyboard focus; null keeps one of its own.
  final FocusNode? focusNode;

  /// Whether this part takes keyboard focus when first shown.
  final bool autofocus;

  /// What the attach button does; null hides it.
  final VoidCallback? onAttach;

  /// What the voice button does; null hides it.
  final VoidCallback? onVoice;

  /// What stopping a reply that is streaming does.
  final VoidCallback? onStop;

  /// Called as the text changes.
  final ValueChanged<String>? onChanged;

  /// A reply is streaming: the send seat becomes stop.
  final bool busy;

  /// Whether it takes text.
  final bool enabled;

  /// How it stands.
  final FrostedComposerVariant variant;

  @override
  State<FrostedComposer> createState() => _FrostedComposerState();
}

class _FrostedComposerState extends State<FrostedComposer>
    with FrostedFieldOwner<FrostedComposer> {
  @override
  TextEditingController? controllerOf(FrostedComposer w) => w.controller;

  @override
  String? valueOf(FrostedComposer w) => null;

  @override
  FocusNode? focusNodeOf(FrostedComposer w) => w.focusNode;

  void _send() {
    final text = fieldController.text.trim();
    if (text.isEmpty) return;
    widget.onSend?.call(text);
    fieldController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final assistant = widget.variant == FrostedComposerVariant.assistant;
    final live = widget.enabled;
    final typed = fieldController.text.trim().isNotEmpty;
    final hint =
        widget.hint ??
        (assistant
            ? FrostedLocalizations.of(context).askAnything
            : FrostedLocalizations.of(context).message);
    final variant = t.textTheme.titleMedium.regular;
    final line =
        MediaQuery.textScalerOf(context).scale(variant.fontSize ?? 16) *
        (variant.height ?? 1.25);
    // Room over and under the text: half what the seat leaves round a line
    // (10 at the text's own size).
    final over = ((FrostedChromeMetrics.roundButton - line) / 2).clamp(
      0.0,
      double.infinity,
    );
    // The hint is drawn here, not by the field, so the field is named once
    // (by the label) and a screen reader never reads the hint a second time.
    final field = FrostedFieldTarget(
      label: hint,
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          alignment: AlignmentDirectional.topStart,
          children: [
            if (fieldController.text.isEmpty)
              ExcludeSemantics(
                child: IgnorePointer(
                  child: Text(
                    hint,
                    style: variant.c(t.colorScheme.textTertiary),
                  ),
                ),
              ),
            TextField(
              autofocus: widget.autofocus,
              contextMenuBuilder: FrostedTextContextMenu.editable,
              selectionControls: FrostedTextSelectionControls.of(
                Theme.of(context).platform,
              ),
              controller: fieldController,
              focusNode: fieldFocus,
              enabled: live,
              minLines: assistant ? 2 : 1,
              maxLines: assistant ? 6 : 5,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              onChanged: widget.onChanged,
              style: variant,
              cursorColor: t.colorScheme.accent,
              decoration: _bareDecoration(),
            ),
          ],
        ),
      ),
    );
    final Widget seat;
    if (widget.busy && widget.onStop != null) {
      seat = _Seat(
        icon: FrostedGlyphs.square,
        label: FrostedLocalizations.of(context).stop,
        onTap: live ? widget.onStop : null,
      );
    } else if (typed || widget.onVoice == null) {
      seat = _Seat(
        icon: FrostedGlyphs.arrowUp,
        label: FrostedLocalizations.of(context).send,
        onTap: live && typed && !widget.busy && widget.onSend != null
            ? _send
            : null,
      );
    } else {
      seat = FrostedIconButton(
        FrostedGlyphs.microphone,
        label: FrostedLocalizations.of(context).dictate,
        onPressed: live ? widget.onVoice : null,
      );
    }
    final attach = widget.onAttach == null
        ? null
        : FrostedIconButton(
            FrostedGlyphs.add,
            label: FrostedLocalizations.of(context).attach,
            onPressed: live ? widget.onAttach : null,
          );
    final Widget inside = assistant
        ? Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: FrostedSpacing.s8,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  FrostedSpacing.s12,
                  FrostedSpacing.s8,
                  FrostedSpacing.s12,
                  0,
                ),
                child: field,
              ),
              Row(
                spacing: FrostedSpacing.s8,
                children: [?attach, const Spacer(), seat],
              ),
            ],
          )
        // The row bottom-aligns (the seat stays by the last line as the text
        // grows), so the text stands at least as tall as the seat and one
        // line sits on its centre by alignment: at one line, bottom and
        // centre are the same place. Over several lines the first starts
        // where the one line stands.
        : Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            spacing: FrostedSpacing.s8,
            children: [
              ?attach,
              Expanded(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: FrostedChromeMetrics.roundButton,
                  ),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: over,
                        horizontal: FrostedSpacing.s8,
                      ),
                      child: field,
                    ),
                  ),
                ),
              ),
              seat,
            ],
          );
    final box = FrostedFace(
      material: FrostedMaterial.well,
      radius: BorderRadius.circular(
        assistant ? FrostedCorners.r22 : FrostedChromeMetrics.composer / 2,
      ),
      // Focused, the edge takes the accent, as a field's well does.
      edge: fieldFocus.hasFocus ? t.colorScheme.accent : t.glass.edge,
      sheen: t.glass.rim,
      padding: const EdgeInsets.all(FrostedChromeMetrics.composerInset),
      child: inside,
    );
    return FrostedDim(off: !live, child: box);
  }
}

/// The composer's one seat: a round of the ink act 40 across wearing a
/// glyph in the ink on it; a null [onTap] fades it.
class _Seat extends StatelessWidget {
  const _Seat({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    const d = FrostedChromeMetrics.roundButton;
    Widget orb = SizedBox.square(
      dimension: d,
      child: FrostedFace(
        material: FrostedMaterial.paint,
        radius: BorderRadius.circular(d / 2),
        gradients: [t.colorScheme.buttonFill],
        sheen: t.colorScheme.buttonSheen,
        shadows: onTap == null ? const <BoxShadow>[] : t.shadows.button,
        child: Center(
          child: Icon(
            icon,
            size: FrostedChromeMetrics.roundGlyph,
            color: t.colorScheme.onButton,
          ),
        ),
      ),
    );
    orb = FrostedDim(off: onTap == null, child: orb);
    return FrostedHitSlop(
      child: FrostedPressable(
        onPressed: onTap,
        label: label,
        radius: d / 2,
        child: orb,
      ),
    );
  }
}

// The decoration of every text entry in Frosted (kept the same in
// bare_field.dart, forms.dart and composer.dart): the hint only, and every
// field that could size or place the line set, so that no
// InputDecorationTheme above the field (its padding, isDense, its
// constraints, a fill or a border) and no platform's density moves it. The
// decorator stands exactly the line's height; the look's own well draws the
// box round it and centres the line by alignment.
// InputDecoration.collapsed alone leaves the constraints and density to the
// theme.
InputDecoration _bareDecoration({String? hint, TextStyle? hintStyle}) =>
    InputDecoration(
      hintText: hint,
      hintStyle: hintStyle,
      isCollapsed: true,
      isDense: false,
      contentPadding: EdgeInsets.zero,
      visualDensity: VisualDensity.standard,
      constraints: const BoxConstraints(),
      filled: false,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      disabledBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      focusedErrorBorder: InputBorder.none,
    );

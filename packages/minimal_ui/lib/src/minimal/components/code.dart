import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../chrome_metrics.dart';
import '../internal/edge_fade.dart';
import '../internal/styled.dart';
import '../localizations.dart';
import '../theme.dart';
import 'button.dart';
import 'icon_button.dart';
import 'toast.dart';

/// The code register's measure: the block's line height, and the key
/// cap's height, padding and type.
abstract final class _CodeMetrics {
  static const double lineHeight = 18;
  static const double kbdHeight = 20;
  static const double kbdPad = 5;
  static const double kbdType = 11;
}

/// A block of code, a command or a token in mono on the sunken well — an
/// API key to paste, a webhook payload, a CLI line — with an optional
/// caption band ([label], usually the language or the file) and a copy
/// action that puts [code] on the clipboard and confirms with a toast.
///
/// Long lines scroll sideways rather than wrapping (`wrap: true` wraps
/// them); [lineNumbers] adds a faint number column, each number beside the
/// first line of its own line of code however that line wraps. Pass [onCopy] to
/// learn that it was copied; `copyable: false` drops the action.
///
/// ```dart
/// MinimalCodeBlock('curl -X POST https://api.example.com/v1/orders', label: 'bash')
/// ```
class MinimalCodeBlock extends StatelessWidget {
  /// A block showing [code].
  const MinimalCodeBlock(
    this.code, {
    super.key,
    this.label,
    this.copyable = true,
    this.onCopy,
    this.copiedMessage,
    this.wrap = false,
    this.lineNumbers = false,
  });

  /// The code, as it prints.
  final String code;

  /// The caption band's text: the language, a file name.
  final String? label;

  /// Whether it offers a copy action.
  final bool copyable;

  /// Called after [code] reaches the clipboard.
  final VoidCallback? onCopy;

  /// The toast the copy confirms with.
  final String? copiedMessage;

  /// Wrap long lines instead of scrolling them sideways.
  final bool wrap;

  /// Whether it numbers its lines.
  final bool lineNumbers;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!context.mounted) return;
    showMinimalSnackBar(
      context,
      copiedMessage ?? MinimalLocalizations.of(context).copied,
      icon: LucideIcons.check,
    );
    onCopy?.call();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    // Code keeps the mono grid: a space is a full cell here, so
    // indentation lines up (the running-text mono's narrower word gap is
    // for dates and stamps).
    final style = t.mono.copyWith(
      height: _CodeMetrics.lineHeight / t.mono.fontSize!,
      wordSpacing: 0,
    );
    final lines = code.split('\n');
    final label = this.label;
    // One line of code's height at the text scale.
    final lineBox =
        MediaQuery.textScalerOf(context).scale(style.fontSize!) * style.height!;

    Widget text = Text(code, style: style, softWrap: wrap);
    if (lineNumbers) {
      final numberStyle = style.c(t.textTertiary);
      // As wide as the longest number at this text scale.
      final painter = TextPainter(
        text: TextSpan(
          text: '9' * lines.length.toString().length,
          style: numberStyle,
        ),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: 1,
      )..layout();
      final column = painter.width.ceilToDouble() + MinimalSpacing.s4;
      painter.dispose();
      Widget number(String n) => ExcludeSemantics(
        child: SizedBox(
          width: column,
          child: Text(
            n,
            style: numberStyle,
            textAlign: TextAlign.end,
            softWrap: false,
          ),
        ),
      );
      const gap = MinimalGap(MinimalSpacing.s12);
      text = wrap
          // Wrapped, each line is its own row, so a number stays beside
          // the line it counts.
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, line) in lines.indexed)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      number('${i + 1}'),
                      gap,
                      Expanded(child: Text(line, style: style)),
                    ],
                  ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                number(
                  [for (var i = 1; i <= lines.length; i++) '$i'].join('\n'),
                ),
                gap,
                text,
              ],
            );
    }
    // Leave the copy action's corner clear when it floats over line 1.
    final clearCorner = label == null && copyable;
    const side = MinimalSpacing.s12;
    // A scrolling line runs to the well's own edge and fades there, so a
    // line longer than the block reads as going on; its air at each end
    // scrolls with it.
    final scrollAir = EdgeInsetsDirectional.only(
      start: side,
      end: clearCorner ? 0 : side,
    ).resolve(Directionality.of(context));
    final body = Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        wrap ? side : 0,
        label == null ? MinimalSpacing.s12 : MinimalSpacing.s8,
        clearCorner ? MinimalSpacing.s40 : (wrap ? side : 0),
        MinimalSpacing.s12,
      ),
      // Code reads left to right in every language; the frame around it
      // (the copy action's corner) still follows the page.
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: wrap
            ? text
            : MinimalEdgeFade(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: scrollAir,
                  child: text,
                ),
              ),
      ),
    );
    final copy = copyable
        ? MinimalIconButton(
            LucideIcons.copy,
            label: MinimalLocalizations.of(context).copy,
            size: MinimalButtonSize.small,
            variant: MinimalIconButtonVariant.ghost,
            onPressed: () => _copy(context),
          )
        : null;

    return Semantics(
      container: true,
      label: MinimalLocalizations.of(context).code(label),
      child: Container(
        width: double.infinity,
        decoration: minimalFrame(
          t.shapes.small,
          fill: t.sunken,
          side: BorderSide(color: t.border, width: t.hairline),
        ),
        child: label != null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      start: MinimalSpacing.s12,
                      end: MinimalSpacing.s4,
                      top: MinimalSpacing.s4,
                    ),
                    child: SizedBox(
                      height: MinimalChromeMetrics.controlSm,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              label.toUpperCase(),
                              style: t.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          ?copy,
                        ],
                      ),
                    ),
                  ),
                  body,
                ],
              )
            : Stack(
                // The body spans the well, as under a caption band: a
                // short line starts at the left in every language rather
                // than hugging the start edge.
                fit: StackFit.passthrough,
                children: [
                  body,
                  // The copy action stands on the first line's middle, as
                  // it stands on the caption band's.
                  if (copy != null)
                    PositionedDirectional(
                      top: MinimalSpacing.s12 + lineBox / 2,
                      end: MinimalSpacing.s4,
                      child: FractionalTranslation(
                        translation: const Offset(0, -0.5),
                        child: copy,
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

/// An inline key cap — `⌘`, `K`, `Esc` — the shortcut a menu row or a
/// command palette prints beside an action: a small mono label on the
/// quiet fill in a flat hairline box, as every Minimal edge is.
/// [MinimalKbd.chord] prints a whole chord (`'⌘ K'`) as caps side by side,
/// left to right in every language, as a code reads, and announced as one
/// shortcut. The modifier symbols (`⌘ ⇧ ⌥ ⌃`), which the
/// mono face does not carry, are drawn as glyphs — so a component that
/// prints a shortcut prints caps, never the symbols as text.
///
/// ```dart
/// MinimalKbd.chord('⌘ K')
/// ```
class MinimalKbd extends StatelessWidget {
  /// A key cap saying [keyLabel].
  const MinimalKbd(this.keyLabel, {super.key});

  /// A chord of space-separated keys (`'⌘ ⇧ P'`) as caps side by side,
  /// announced once as `Shortcut Command Shift P`.
  static Widget chord(String keys, {Key? key}) => _Chord(keys, key: key);

  /// What the cap prints.
  final String keyLabel;

  /// How a screen reader names [key]: the modifier symbols by their names
  /// (`⌘` is `Command`), any other key as it prints.
  static String spokenName(String key) => _modifiers[key]?.$2 ?? key;

  static const Map<String, (IconData, String)> _modifiers = {
    '⌘': (LucideIcons.command, 'Command'),
    '⇧': (LucideIcons.arrowBigUp, 'Shift'),
    '⌥': (LucideIcons.option, 'Option'),
    '⌃': (LucideIcons.chevronUp, 'Control'),
  };

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final modifier = _modifiers[keyLabel];
    final ink = t.mutedForeground;
    final type = t.mono.copyWith(fontSize: _CodeMetrics.kbdType).medium.c(ink);
    return Semantics(
      label: spokenName(keyLabel),
      child: ExcludeSemantics(
        child: Container(
          constraints: const BoxConstraints(
            minWidth: _CodeMetrics.kbdHeight,
            minHeight: _CodeMetrics.kbdHeight,
          ),
          padding: const EdgeInsets.symmetric(horizontal: _CodeMetrics.kbdPad),
          // The cap on the mark step: flat, a hairline all round. No light
          // falls on Minimal, so no edge is heavier than another.
          decoration: minimalFrame(t.shapes.mark, fill: t.muted, side: t.rule),
          // Shrink to the label, centred in the cap's least square.
          child: Center(
            widthFactor: 1,
            heightFactor: 1,
            child: modifier != null
                ? MinimalIcon(
                    modifier.$1,
                    size: MediaQuery.textScalerOf(context)
                        .scale(_CodeMetrics.kbdType),
                    color: ink,
                  )
                : Text(
                    keyLabel,
                    style: type,
                    maxLines: 1,
                    textDirection: TextDirection.ltr,
                  ),
          ),
        ),
      ),
    );
  }
}

/// A chord's caps side by side, announced as one shortcut.
class _Chord extends StatelessWidget {
  const _Chord(this.keys, {super.key});

  final String keys;

  @override
  Widget build(BuildContext context) {
    final caps = keys.split(' ').where((k) => k.isNotEmpty).toList();
    return Semantics(
      label: MinimalLocalizations.of(context)
          .shortcut(caps.map(MinimalKbd.spokenName).join(' ')),
      excludeSemantics: true,
      // A chord is a code: `⌘ K` reads left to right in every language.
      child: Row(
        textDirection: TextDirection.ltr,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (i, key) in caps.indexed) ...[
            if (i > 0) const MinimalGap(MinimalSpacing.s2),
            MinimalKbd(key),
          ],
        ],
      ),
    );
  }
}

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../icons.dart';
import '../../localizations.dart';
import '../../theme.dart';
import '../button/button.dart';

/// What a [Fluent2MessageBar] tells, Fluent's `intent`: [info] (the
/// default, the neutral grey), [success], [warning], [error].
enum Fluent2MessageIntent {
  /// The neutral grey, for news.
  info,

  /// Success's green, for something done.
  success,

  /// Warning's amber, for something to watch.
  warning,

  /// Danger's red, for something that failed.
  error;

  /// The tone its tint, border and glyph are drawn in.
  Fluent2Tone get tone => switch (this) {
    info => Fluent2Tone.informative,
    success => Fluent2Tone.success,
    warning => Fluent2Tone.warning,
    error => Fluent2Tone.danger,
  };

  /// Its glyph, Fluent's `getIntentIcon`.
  IconData get glyph => switch (this) {
    info => Fluent2Icons.infoFilled,
    success => Fluent2Icons.checkmarkCircleFilled,
    warning => Fluent2Icons.warningFilled,
    error => Fluent2Icons.diamondDismissFilled,
  };

  /// What a screen reader says for its glyph, in [words]' language.
  String spokenIn(Fluent2Localizations words) => switch (this) {
    info => words.information,
    success => words.success,
    warning => words.warning,
    error => words.error,
  };
}

/// How a message bar lays its parts, Fluent's `layout`: [singleline] the
/// glyph, the words and the acts on one 36 line; [multiline] the words
/// wrapping beside the glyph with the acts under them at the end; [auto]
/// (the default) one line when it all fits, else the two.
enum Fluent2MessageLayout {
  /// One line while it fits, more when not.
  auto,

  /// One line, its actions at its end.
  singleline,

  /// Its body under its title, its actions under that.
  multiline,
}

/// Fluent 2's MessageBar: a standing message in the page's flow, on its
/// [intent]'s tint inside its border (the neutral layer for info), its
/// glyph in the tone's ink, an optional [title] in body1Strong running
/// into its [body] in body1, then its [actions] (Fluent's
/// `MessageBarActions`, medium buttons) and the dismiss ([onDismiss]).
/// For a state that holds (offline, storage nearly full, a file shared
/// read-only), never a moment's news (that is a toast). Spoken as it
/// appears, a live region.
///
/// ```dart
/// Fluent2MessageBar(intent: Fluent2MessageIntent.warning, title: 'Storage almost full', body: '9.2 GB of 10 GB used.', actions: [Fluent2Button('Manage', onPressed: manage)])
/// ```
class Fluent2MessageBar extends StatelessWidget {
  /// A message bar: [title] and [body] in [intent]'s tint.
  const Fluent2MessageBar({
    required this.body,
    this.title,
    this.intent = Fluent2MessageIntent.info,
    this.actions = const [],
    this.onDismiss,
    this.layout = Fluent2MessageLayout.auto,
    this.square = false,
    this.icon,
    this.dismissLabel,
    super.key,
  });

  /// The message's words.
  final String body;

  /// The bold words leading the body.
  final String? title;

  /// Fluent's `intent`: what the message tells.
  final Fluent2MessageIntent intent;

  /// The acts (buttons) after the words, the primary last.
  final List<Widget> actions;

  /// Dismisses the message; null draws no dismiss.
  final VoidCallback? onDismiss;

  /// Fluent's `layout`: one line, several, or picked by the room.
  final Fluent2MessageLayout layout;

  /// Square corners (Fluent's `shape: square`), for a bar spanning a
  /// pane's top edge.
  final bool square;

  /// The glyph; null wears the intent's.
  final IconData? icon;

  /// What a screen reader says for the dismiss; null is "Dismiss" in the
  /// app's language.
  final String? dismissLabel;

  /// The width the acts are reckoned to take on one line: each act at a
  /// medium button's least width, 12 apart.
  static double actionsReach(int count) =>
      count == 0 ? 0 : count * 96 + (count - 1) * Fluent2Spacing.m;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final tone = t.tone(intent.tone);
    final ink = t.textPrimary;
    final words = TextSpan(
      children: [
        if (title != null)
          TextSpan(text: '${title!} ', style: t.body1Strong.c(ink)),
        TextSpan(text: body, style: t.body1.c(ink)),
      ],
    );
    final own = Fluent2Localizations.of(context);
    final glyph = Semantics(
      label: intent.spokenIn(own),
      child: Icon(icon ?? intent.glyph, size: 20, color: tone.ink),
    );
    final dismiss = onDismiss == null
        ? null
        : Fluent2IconButton(
            Fluent2Icons.dismiss,
            semanticLabel: dismissLabel ?? own.dismiss,
            appearance: Fluent2ButtonAppearance.transparent,
            onPressed: onDismiss,
          );
    return Semantics(
      container: true,
      liveRegion: true,
      child: LayoutBuilder(
        builder: (context, box) {
          var multi = layout == Fluent2MessageLayout.multiline;
          if (layout == Fluent2MessageLayout.auto) {
            // Measured as the Text below lays it: under the ambient
            // default style, its width rounded up, so a line that only
            // just fits never ends in an ellipsis.
            final ambient = DefaultTextStyle.of(context);
            final painter = TextPainter(
              text: TextSpan(style: ambient.style, children: [words]),
              maxLines: 1,
              textDirection: Directionality.of(context),
              textScaler: MediaQuery.textScalerOf(context),
              textWidthBasis: ambient.textWidthBasis,
              textHeightBehavior: ambient.textHeightBehavior,
            )..layout();
            final reach =
                Fluent2Spacing.m +
                20 +
                Fluent2Spacing.s +
                painter.width.ceilToDouble() +
                Fluent2Spacing.m +
                actionsReach(actions.length) +
                (actions.isEmpty ? 0 : Fluent2Spacing.m) +
                (dismiss == null ? 0 : 32 + Fluent2Spacing.m) +
                2;
            painter.dispose();
            multi = reach > box.maxWidth;
          }
          final text = Text.rich(
            words,
            maxLines: multi ? null : 1,
            overflow: multi ? null : TextOverflow.ellipsis,
          );
          final Widget content;
          if (multi) {
            // The glyph, the first line of words and the dismiss share one
            // band, each centred in it: the line with its 10 above and
            // below, or the dismiss's face when that is taller (32, the
            // whole target, the floor, under a finger), however many lines
            // follow and
            // however large the words.
            final ambient = DefaultTextStyle.of(context);
            final probe = TextPainter(
              text: TextSpan(text: ' ', style: ambient.style),
              textDirection: Directionality.of(context),
              textScaler: MediaQuery.textScalerOf(context),
              textHeightBehavior: ambient.textHeightBehavior,
            )..layout();
            final line = probe.height;
            probe.dispose();
            final face = dismiss == null
                ? 0.0
                : Fluent2Layout.padded(context)
                ? Fluent2Layout.hitTargetOf(context)
                : 32.0;
            final band = math.max(line + 2 * Fluent2Spacing.mNudge, face);
            final wordsTop = (band - line) / 2;
            final glyphTop = (band - 20) / 2;
            final dismissTop = (band - face) / 2;
            content = Padding(
              padding: const EdgeInsetsDirectional.only(
                start: Fluent2Spacing.m,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: glyphTop),
                        child: glyph,
                      ),
                      const SizedBox(width: Fluent2Spacing.s),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsetsDirectional.only(
                            top: wordsTop,
                            end: Fluent2Spacing.m,
                            bottom: actions.isEmpty ? Fluent2Spacing.mNudge : 0,
                          ),
                          child: text,
                        ),
                      ),
                      if (dismiss != null)
                        Padding(
                          padding: EdgeInsetsDirectional.only(
                            top: dismissTop,
                            end: Fluent2Spacing.m,
                          ),
                          child: dismiss,
                        ),
                    ],
                  ),
                  if (actions.isNotEmpty)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        top: Fluent2Spacing.mNudge,
                        bottom: Fluent2Spacing.s,
                        end: Fluent2Spacing.m,
                      ),
                      child: Wrap(
                        alignment: WrapAlignment.end,
                        spacing: Fluent2Spacing.m,
                        runSpacing: Fluent2Spacing.s,
                        children: actions,
                      ),
                    ),
                ],
              ),
            );
          } else {
            // Under a pointer the acts stand in Fluent's 36 band (a small
            // button 6 from its top and foot). Under a finger an act's face
            // is its whole target (the floor, 40), taller than the band: the bar holds
            // it as far from its top and foot as from its end.
            final hold = Fluent2Layout.padded(context) && actions.isNotEmpty
                ? Fluent2Spacing.m
                : 0.0;
            content = Padding(
              padding: EdgeInsetsDirectional.only(
                start: Fluent2Spacing.m,
                top: hold,
                bottom: hold,
              ),
              child: Row(
                children: [
                  glyph,
                  const SizedBox(width: Fluent2Spacing.s),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(
                        end: Fluent2Spacing.m,
                      ),
                      child: text,
                    ),
                  ),
                  if (actions.isNotEmpty)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        end: Fluent2Spacing.m,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: Fluent2Spacing.m,
                        children: actions,
                      ),
                    ),
                  if (dismiss != null)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        end: Fluent2Spacing.m,
                      ),
                      child: dismiss,
                    ),
                ],
              ),
            );
          }
          return Container(
            constraints: const BoxConstraints(minHeight: 36),
            decoration: BoxDecoration(
              color: tone.tint,
              borderRadius: BorderRadius.circular(
                square ? Fluent2Radius.none : Fluent2Radius.medium,
              ),
              border: Border.all(color: tone.border),
            ),
            child: content,
          );
        },
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('body', body))
      ..add(StringProperty('title', title, defaultValue: null))
      ..add(
        EnumProperty<Fluent2MessageIntent>(
          'intent',
          intent,
          defaultValue: Fluent2MessageIntent.info,
        ),
      )
      ..add(ObjectFlagProperty<VoidCallback?>.has('onDismiss', onDismiss))
      ..add(
        EnumProperty<Fluent2MessageLayout>(
          'layout',
          layout,
          defaultValue: Fluent2MessageLayout.auto,
        ),
      )
      ..add(FlagProperty('square', value: square, ifTrue: 'square'))
      ..add(DiagnosticsProperty<IconData>('icon', icon, defaultValue: null))
      ..add(StringProperty('dismissLabel', dismissLabel, defaultValue: null));
  }
}

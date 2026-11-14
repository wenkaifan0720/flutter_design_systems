/// A notice that stands in the page: an inline alert.
library;

import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../component_themes.dart';
import '../internal/kit_paint.dart';
import '../internal/styled.dart';
import '../internal/text_entry.dart';
import '../localizations.dart';
import '../theme.dart';
import 'button.dart';
import 'icon_button.dart';
import 'tag.dart';

/// A notice that stands in the page until it is dealt with — a trial that
/// ends Friday, a sync that failed, a setting that needs a look: a framed
/// block on the `shapes.medium` step, the [tone]'s glyph at its start, a
/// [title] in the ink, a quiet [message], at most two [actions] under them
/// (Minimal's buttons, small), and a close button at its end when
/// [onDismissed] is given.
///
/// It stays calm: the surface with a hairline and the tone in the glyph
/// alone, never a tinted slab or a coloured stripe — a page with a warning
/// is still the page. A screen reader hears it when it appears.
/// For a passing confirmation use `showMinimalSnackBar`; for a choice the
/// person must make now, a dialog.
///
/// [style] dresses one banner, `components.banner` every one: fill, edge
/// or side, shape, padding and textStyle.
///
/// ```dart
/// MinimalBanner(tone: MinimalTone.warning, title: 'Your trial ends Friday', message: 'Add a card to keep your projects.', actions: [MinimalButton('Add card', size: MinimalButtonSize.small, onPressed: billing)])
/// ```
class MinimalBanner extends StatelessWidget {
  /// A banner saying [title].
  const MinimalBanner({
    super.key,
    required this.title,
    this.message,
    this.tone = MinimalTone.neutral,
    this.icon,
    this.actions = const [],
    this.onDismissed,
    this.style,
  });

  /// What it says.
  final String title;

  /// A line under the title.
  final String? message;

  /// What kind of notice: neutral information, accent news, success,
  /// warn or danger.
  final MinimalTone tone;

  /// The glyph at its start; null takes the tone's own.
  final IconData? icon;

  /// At most two small buttons under the words.
  final List<Widget> actions;

  /// Shows a close button that calls this.
  final VoidCallback? onDismissed;

  /// This banner's style, over `components.banner`.
  final MinimalStyle? style;

  static IconData _glyph(MinimalTone tone) => switch (tone) {
    MinimalTone.neutral => LucideIcons.info,
    MinimalTone.primary => LucideIcons.sparkles,
    MinimalTone.success => LucideIcons.circleCheck,
    MinimalTone.warning => LucideIcons.triangleAlert,
    MinimalTone.destructive => LucideIcons.circleAlert,
  };

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final so = MinimalStyleOf([style, t.components.banner], const {});
    final colours = t.tone(tone);
    final shape = so.shape ?? t.shapes.medium;
    final rim = so.rim(t.border, t.hairline);
    final message = this.message;
    final dismiss = onDismissed;
    final titleStyle = so.text(t.body.medium, t.foreground);
    final body = Padding(
      padding:
          so.padding ??
          const EdgeInsetsDirectional.fromSTEB(
            MinimalSpacing.s12,
            MinimalSpacing.s12,
            MinimalSpacing.s8,
            MinimalSpacing.s12,
          ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The glyph keeps its size and centres on the title's first
          // line, however large the text grows.
          SizedBox(
            height: minimalLineHeight(context, titleStyle),
            child: Center(
              widthFactor: 1,
              child: MinimalIcon(
                icon ?? _glyph(tone),
                size: MinimalIconSize.i16,
                color: tone == MinimalTone.neutral
                    ? t.mutedForeground
                    : colours.foreground,
              ),
            ),
          ),
          const MinimalGap(MinimalSpacing.s8 + 2),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: titleStyle),
                if (message != null) ...[
                  const MinimalGap(MinimalSpacing.s2),
                  Text(message, style: t.bodySmall.c(t.mutedForeground)),
                ],
                if (actions.isNotEmpty) ...[
                  const MinimalGap(MinimalSpacing.s12),
                  Wrap(
                    spacing: MinimalSpacing.s8,
                    runSpacing: MinimalSpacing.s8,
                    children: actions,
                  ),
                ],
              ],
            ),
          ),
          if (dismiss != null) ...[
            const MinimalGap(MinimalSpacing.s4),
            MinimalIconButton(
              LucideIcons.x,
              size: MinimalButtonSize.small,
              variant: MinimalIconButtonVariant.ghost,
              label: MinimalLocalizations.of(context).dismissAlert,
              onPressed: dismiss,
            ),
          ],
        ],
      ),
    );
    return Semantics(
      container: true,
      liveRegion: true,
      child: DecoratedBox(
        decoration: minimalFrame(shape, fill: so.fill ?? t.card, side: rim),
        child: MinimalGroundFill(fill: so.fill ?? t.card, child: body),
      ),
    );
  }
}

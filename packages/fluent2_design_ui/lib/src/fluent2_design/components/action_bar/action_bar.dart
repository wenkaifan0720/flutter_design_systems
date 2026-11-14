import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../internal/footer_band.dart';
import '../../theme.dart';
import '../button/button.dart';

/// The acts pinned at a page's foot in Fluent 2's idiom: the [primaryLabel] act
/// (the brand's button, the one the page exists for) and an optional
/// [secondaryLabel] one beside it, with a [summary] (and its quieter [detail])
/// at the start where the page has a figure to stand by them. It goes in a
/// [Fluent2Scaffold]'s `footer`, which draws the band (the surface over a
/// hairline, the safe area under it); the bar lays out its acts only. On
/// the desktop the acts stand at the band's end, the primary last, at the
/// medium size; under 480 wide (or with large text) they stack the
/// width of the page, the primary on top, at the large size (40). Outside
/// a footer it draws the band itself. Read as its summary, then its
/// buttons.
///
/// ```dart
/// Fluent2BottomActionBar(primaryLabel: 'Send invite', onPrimaryPressed: send, secondaryLabel: 'Cancel', onSecondaryPressed: cancel)
/// ```
class Fluent2BottomActionBar extends StatelessWidget {
  /// A bar of a page's acts pinned at its foot.
  const Fluent2BottomActionBar({
    required this.primaryLabel,
    required this.onPrimaryPressed,
    this.secondaryLabel,
    this.onSecondaryPressed,
    this.primaryIcon,
    this.summary,
    this.detail,
    super.key,
  });

  /// The primary act's words.
  final String primaryLabel;

  /// What it does; null draws it disabled (a form not yet complete).
  final VoidCallback? onPrimaryPressed;

  /// The secondary act's words.
  final String? secondaryLabel;

  /// Called by the second act; null shows none.
  final VoidCallback? onSecondaryPressed;

  /// A glyph before the primary act's words.
  final IconData? primaryIcon;

  /// A figure or a line the acts stand by (3 people invited).
  final String? summary;

  /// The quiet line under the summary.
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final summary = this.summary;
    final detail = this.detail;
    final secondaryLabel = this.secondaryLabel;
    final scaled = MediaQuery.textScalerOf(context).scale(1) >= 1.2;
    final content = LayoutBuilder(
      builder: (context, box) {
        final narrow = box.maxWidth < 480 || scaled;
        final size = narrow
            ? Fluent2ButtonSize.large
            : Fluent2ButtonSize.medium;
        final first = Fluent2Button(
          primaryLabel,
          appearance: Fluent2ButtonAppearance.primary,
          size: size,
          icon: primaryIcon,
          expand: narrow,
          onPressed: onPrimaryPressed,
        );
        final second = secondaryLabel == null
            ? null
            : Fluent2Button(
                secondaryLabel,
                size: size,
                expand: narrow,
                onPressed: onSecondaryPressed,
              );
        final words = summary == null
            ? null
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: t.body1Strong,
                  ),
                  if (detail != null)
                    Text(
                      detail,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: t.caption1.c(t.textTertiary),
                    ),
                ],
              );
        if (narrow) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: Fluent2Spacing.s,
            children: [
              if (words != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: Fluent2Spacing.xs),
                  child: words,
                ),
              first,
              ?second,
            ],
          );
        }
        return Row(
          spacing: Fluent2Spacing.s,
          children: [
            Expanded(child: words ?? const SizedBox.shrink()),
            ?second,
            first,
          ],
        );
      },
    );
    if (Fluent2FooterBand.around(context)) return content;
    // Outside a screen's footer: the band the screen would draw.
    final mq = MediaQuery.of(context);
    final side = Fluent2Layout.gutter(context);
    return Fluent2BottomStand(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: t.colors.neutralBackground1,
          border: Border(top: BorderSide(color: t.colors.neutralStroke2)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            side,
            Fluent2Spacing.m,
            side,
            math.max(Fluent2Spacing.m, mq.viewPadding.bottom),
          ),
          child: Fluent2FooterBand(child: content),
        ),
      ),
    );
  }
}

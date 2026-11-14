import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../chrome_metrics.dart';
import '../../internal/face.dart';
import '../../internal/footer_band.dart';
import '../../localizations.dart';
import '../../theme.dart';
import '../../internal/measure.dart';
import '../button/button.dart';

/// The page's persistent footer: a [summary] figure with its [detail] under
/// it at the start and the one act ([label], a [FrostedButton] in the ink) at
/// the end, standing in the footer band a screen carries (the canvas, the
/// page fading into it above; the Review page's "Transfer $500.00").
/// Placed outside a screen's footer it draws that band itself: the canvas,
/// 16 in at the sides, 12 over the act and the safe area under it. Floating
/// it stands off the edges on a tile of the high glass. Once the text is
/// large (1.2) or the room narrow (under 320) the summary stands over the
/// act. While [busy] the act reads "Working…" and takes no press, announced
/// as it changes. Without a summary the act takes the whole width.
///
/// ```dart
/// FrostedActionBar(summary: '\$500.00', detail: 'To Maren Holt · arrives Thursday', label: 'Transfer', onPressed: transfer)
/// ```
class FrostedActionBar extends StatelessWidget {
  /// Creates a [FrostedActionBar].
  const FrostedActionBar({
    required this.label,
    required this.onPressed,
    this.summary,
    this.detail,
    this.busy = false,
    this.floating = false,
    super.key,
  });

  /// The act's word.
  final String label;

  /// What the act does; null draws it disabled.
  final VoidCallback? onPressed;

  /// A total, a count or a time, in the figure type.
  final String? summary;

  /// A quiet line under the summary.
  final String? detail;

  /// Whether the act is under way.
  final bool busy;

  /// Whether the bar stands off the edges on a tile.
  final bool floating;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final inset = MediaQuery.paddingOf(context).bottom;
    final scaled =
        MediaQuery.textScalerOf(context).scale(1) >=
        FrostedChromeMetrics.actionBarStackScale;
    // Busy, the act keeps its full strength and takes no press or focus: a
    // disabled pill's dim put "Working…" under 4.5:1 (law 8), and the act
    // is at work, not unavailable.
    final act = Semantics(
      liveRegion: busy,
      child: IgnorePointer(
        ignoring: busy,
        child: ExcludeFocus(
          excluding: busy,
          child: FrostedButton(
            busy ? FrostedLocalizations.of(context).working : label,
            expand: summary == null,
            onPressed: busy ? _atWork : onPressed,
          ),
        ),
      ),
    );
    final words = summary == null
        ? null
        : Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                summary!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.textTheme.amount.tabular,
              ),
              if (detail != null) Text(detail!, style: t.textTheme.bodyMedium),
            ],
          );
    final content = LayoutBuilder(
      builder: (context, box) {
        // From 600 wide the lone act keeps a button's measure at the bar's
        // end, rather than running across it.
        if (words == null) {
          return MediaQuery.sizeOf(context).width >= frostedMeasureFrom
              ? Align(
                  alignment: AlignmentDirectional.centerEnd,
                  heightFactor: 1,
                  child: act,
                )
              : act;
        }
        if (scaled || box.maxWidth < FrostedChromeMetrics.actionBarStackWidth) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: FrostedChromeMetrics.actionBarGap,
            children: [words, act],
          );
        }
        return Row(
          spacing: FrostedChromeMetrics.actionBarGap,
          children: [
            Expanded(child: words),
            act,
          ],
        );
      },
    );
    if (floating) {
      return FrostedBottomStand(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            FrostedChromeMetrics.tabBarSide,
            0,
            FrostedChromeMetrics.tabBarSide,
            math.max(FrostedChromeMetrics.tabBarSide, inset),
          ),
          child: FrostedFace(
            material: FrostedMaterial.bar,
            radius: BorderRadius.circular(FrostedCorners.r22),
            edge: t.glass.edge,
            sheen: t.glass.rim,
            shadows: t.shadows.tile,
            padding: const EdgeInsets.symmetric(
              horizontal: FrostedChromeMetrics.actionBarSide,
              vertical: FrostedChromeMetrics.actionBarTop,
            ),
            child: content,
          ),
        ),
      );
    }
    // In a screen's footer the screen draws the band; the bar is its content.
    if (FrostedFooterBand.around(context)) return content;
    return FrostedBottomStand(
      child: ColoredBox(
        color: t.colorScheme.background,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            FrostedChromeMetrics.actionBarSide,
            FrostedChromeMetrics.actionBarTop,
            FrostedChromeMetrics.actionBarSide,
            math.max(FrostedChromeMetrics.actionBarTop, inset),
          ),
          child: FrostedFooterBand(child: content),
        ),
      ),
    );
  }
}

// What the act does while it is at work: nothing (it takes no press then).
void _atWork() {}

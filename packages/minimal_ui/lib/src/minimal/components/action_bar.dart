import 'package:flutter/widgets.dart';

import '../chrome_metrics.dart';
import '../internal/styled.dart';
import '../localizations.dart';
import '../theme.dart';
import 'button.dart';

/// A page's persistent commit strip: a summary of what is about to happen
/// on the leading side (a total, a count, the one line that matters) and
/// the primary action on the trailing side. In `MinimalScaffold(footer:)` leave
/// [floating] false — the screen owns the ground, the hairline and the
/// insets; `floating: true` stands it on its own bordered card for a body
/// that keeps its edges.
///
/// Without a summary the action takes the whole width. At large text
/// scales, or narrower than [stackBelow], the summary stacks over the
/// action rather than squeezing it.
///
/// ```dart
/// MinimalActionBar(summary: '3 of 5 kept', detail: 'Two to go', label: 'Log all', onPressed: logAll)
/// ```
class MinimalActionBar extends StatelessWidget {
  /// A bar holding the page's one action, [label].
  const MinimalActionBar({
    super.key,
    this.label = '',
    this.summary,
    this.detail,
    this.summaryContent,
    this.action,
    this.onPressed,
    this.busy = false,
    this.busyLabel,
    this.floating = false,
  }) : assert(action != null || label != '');

  /// What the action says.
  final String label;

  /// The summary's figure — a total, a count, a time — printed in the mono
  /// [MinimalThemeData.figure], and the quiet prose line under it.
  final String? summary, detail;

  /// A composed summary in place of [summary] and [detail].
  final Widget? summaryContent;

  /// A composed action in place of the built-in button.
  final Widget? action;

  /// Runs the action; null disables it.
  final VoidCallback? onPressed;

  /// Busy state for the built-in button; a custom action owns its state.
  final bool busy;

  /// Set while the action runs: the button says it, with a spinner, and takes
  /// no presses.
  final String? busyLabel;

  /// Whether it stands on its own bordered card over the body, rather than on
  /// the screen's footer band.
  final bool floating;

  /// The width under which the summary stacks over the action.
  static const double stackBelow = 320;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final summaryWidget =
        summaryContent ??
        (summary == null
            ? null
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    summary!,
                    style: t.figure,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (detail != null)
                    Text(
                      detail!,
                      style: t.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ));
    final button =
        action ??
        // A busy button is its own live region: its spinner and words are
        // announced as they change.
        MinimalButton(
          busy ? busyLabel ?? MinimalLocalizations.of(context).working : label,
          size: MinimalButtonSize.large,
          expand: summaryWidget == null,
          busy: busy,
          onPressed: onPressed,
        );
    final body = LayoutBuilder(
      builder: (context, constraints) {
        if (summaryWidget == null) return button;
        if (MediaQuery.textScalerOf(context).scale(1) >
                MinimalChromeMetrics.actionBarStackScale ||
            constraints.maxWidth < stackBelow) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              summaryWidget,
              const MinimalGap(MinimalSpacing.s12),
              button,
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: summaryWidget),
            const MinimalGap(MinimalSpacing.s12),
            button,
          ],
        );
      },
    );
    if (!floating) return body;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MinimalSpacing.s12,
        vertical: MinimalChromeMetrics.actionBarPad,
      ),
      decoration: minimalFrame(
        t.shapes.medium,
        fill: t.card,
        side: BorderSide(color: t.border, width: t.hairline),
        shadows: t.shadowMd,
      ),
      constraints: const BoxConstraints(
        minHeight:
            MinimalChromeMetrics.controlLg +
            2 * MinimalChromeMetrics.actionBarPad,
      ),
      child: body,
    );
  }
}

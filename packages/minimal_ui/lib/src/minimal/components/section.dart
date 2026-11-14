import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../chrome_metrics.dart';
import '../internal/cap_label.dart';
import '../theme.dart';
import 'card.dart';
import 'group_header.dart';
import 'pressable.dart';

/// A page region: the uppercase group-header label over its content, with
/// an optional mono [count] and a trailing text action on the header's end,
/// and the page's rhythm above it.
///
/// The header IS the Minimal group header ([MinimalSectionHeader]: 14 px of
/// air above, 6 below, [MinimalThemeData.label] upper-cased, the count in
/// mono),
/// so a section and a list's group read as one register — a heading in a
/// list of facts, not a card. `gutter: true` insets the header to line up
/// with a [MinimalListSection]'s rows under it — the screen gutter on a
/// full-bleed page (`MinimalScaffold(padding: EdgeInsets.zero)`), the card's
/// row inset inside a [MinimalCard] — while the rows run edge to edge; the
/// content is never padded.
///
/// ```dart
/// MinimalSection(title: 'Last 12 weeks', count: '71 / 84', child: heatmap)
/// ```
class MinimalSection extends StatelessWidget {
  /// A titled band around [child].
  const MinimalSection({
    super.key,
    required this.title,
    required this.child,
    this.count,
    this.actionLabel,
    this.onAction,
    this.gutter = false,
  });

  /// The heading, in sentence case: the section prints it upper-cased.
  final String title;

  /// Its content.
  final Widget child;

  /// A figure beside the heading's end, in mono: `2/3`, `71 / 84`, `6`.
  final String? count;

  /// Trailing text action, e.g. "View all". With no [onAction] it is shown
  /// disabled.
  final String? actionLabel;

  /// The header's text action's press.
  final VoidCallback? onAction;

  /// Inset the header to the rows of a full-bleed list:
  /// [MinimalChromeMetrics.gutter] on the page, [MinimalCard.rowInsetOf] in a
  /// card.
  final bool gutter;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final label = actionLabel;
    final figure = count;
    final side = !gutter
        ? EdgeInsets.zero
        : MinimalCard.rowInsetOf(context) ?? MinimalInsets.gutter;
    final Widget? action = label == null
        ? null
        : MinimalPressable(
            onPressed: onAction,
            // An action label with nothing behind it is a disabled control:
            // the ink, which the pressable dims as it dims every disabled
            // control (the muted ink dimmed again all but vanished).
            enabled: onAction != null,
            shape: t.shapes.mark,
            child: minimalCapLabel(
              Text(
                label,
                style: t.caption.medium.c(
                  onAction == null ? t.foreground : t.primaryInk,
                ),
              ),
            ),
          );
    final header = MinimalSectionHeader(
      title,
      // A lone count is the header's own; a count beside an action rides
      // with it in the trailing slot.
      count: action == null ? figure : null,
      trailing: action == null
          ? null
          : figure == null
          ? action
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                minimalCapLabel(
                  Text(figure, style: t.mono.medium.c(t.mutedForeground)),
                ),
                const MinimalGap(MinimalSpacing.s12),
                action,
              ],
            ),
      padding: EdgeInsets.fromLTRB(
        side.left,
        MinimalSectionHeader.inset.top,
        side.right,
        MinimalSectionHeader.inset.bottom,
      ),
    );
    return DesignKeylineRegion(
      label: 'MinimalSection',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [header, child],
      ),
    );
  }
}

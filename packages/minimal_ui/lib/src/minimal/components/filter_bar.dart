import 'package:flutter/widgets.dart';

import '../chrome_metrics.dart';
import '../internal/cap_label.dart';
import '../internal/controls.dart';
import '../internal/edge_fade.dart';
import '../internal/styled.dart';
import '../shapes.dart';
import '../theme.dart';
import 'pressable.dart';

/// A filter's side padding (shared through [MinimalChromeMetrics]).
abstract final class _FilterMetrics {
  static const double pad = MinimalChromeMetrics.filterPad;
}

/// One count filter: a quiet word with its mono count beside it (`Open 2`).
/// The selected filter takes an ink hairline and the ink at medium weight,
/// as a chosen chip does; the rest print in the secondary ink on nothing at
/// all.
///
/// A set of them lives in a [MinimalFilterBar], one selected at a time, the
/// page holding the index.
///
/// ```dart
/// MinimalFilter('Open', count: 2, selected: view == 1, onPressed: () => setView(1))
/// ```
class MinimalFilter extends StatelessWidget {
  /// A filter saying [label].
  const MinimalFilter(
    this.label, {
    super.key,
    this.count,
    this.icon,
    this.leading,
    this.selected = false,
    this.onPressed,
    this.focusNode,
    this.autofocus = false,
  });

  /// What it filters by.
  final String label;

  /// How many records the filter keeps, printed in mono after the label;
  /// null prints none.
  final int? count;

  /// A glyph before the label, for filters by kind.
  final IconData? icon;

  /// A drawn mark before the label in place of [icon] — a filter by status
  /// leads with the state's own glyph:
  /// `leading: MinimalStatusIcon(MinimalTaskStatus.done, size: 14)`.
  final Widget? leading;

  /// Whether it is on.
  final bool selected;

  /// Null disables the filter (a view with nothing to show yet).
  final VoidCallback? onPressed;

  /// The filter's height: a small control's.
  static const double height = MinimalChromeMetrics.controlSm;

  /// Its focus node, for a caller that moves focus to it; null keeps one
  /// of its own.
  final FocusNode? focusNode;

  /// Whether it takes keyboard focus when it first appears.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final count = this.count;
    final icon = this.icon;
    final leading = this.leading;
    final ink = selected ? t.foreground : t.mutedForeground;
    return MinimalPressable(
      focusNode: focusNode,
      autofocus: autofocus,
      onPressed: onPressed,
      enabled: onPressed != null,
      selected: selected,
      shape: MinimalShapes.inset(t.shapes.small, 1),
      semanticLabel: count == null ? label : '$label, $count',
      child: ExcludeSemantics(
        child: Container(
          // A small control's height at the theme's density, level with a
          // small button or icon button beside the strip.
          constraints: BoxConstraints(
            minHeight: minimalGrownHeight(context, t.density.height(height)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: _FilterMetrics.pad),
          decoration: minimalFrame(
            MinimalShapes.inset(t.shapes.small, 1),
            // Every filter keeps the hairline's width so selecting one
            // never shifts its neighbours; only the selected one shows it,
            // in the ink, as a chosen chip's does (no tinted pill).
            side: BorderSide(
              color: selected
                  ? t.foreground
                  : t.foreground.withValues(alpha: 0),
              width: t.hairline,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[
                leading,
                const MinimalGap(MinimalChromeMetrics.iconGap),
              ] else if (icon != null) ...[
                MinimalIcon(icon, size: MinimalIconSize.i14, color: ink),
                const MinimalGap(MinimalChromeMetrics.iconGap),
              ],
              minimalCapLabel(
                Text(
                  label,
                  style: (selected ? t.bodySmall.medium : t.bodySmall).c(ink),
                  maxLines: 1,
                ),
              ),
              if (count != null) ...[
                const MinimalGap(MinimalChromeMetrics.iconGap),
                minimalCapLabel(
                  Text(
                    '$count',
                    // A count is data: the secondary ink, which clears AA,
                    // never the tertiary.
                    style: t.countFigure.c(t.mutedForeground),
                    maxLines: 1,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A strip of [MinimalFilter]s over a list: full bleed, a hairline under it,
/// the filters left to right with a [trailing] control (a display menu, a
/// sort) held at the end, at the filters' height (a `small` icon button). When the filters outrun the width — more of them,
/// or a larger text scale — they scroll sideways rather than wrap, so the
/// list below never moves.
///
/// ```dart
/// MinimalFilterBar(children: [for (final (i, f) in filters.indexed) MinimalFilter(f.label, count: f.count, selected: i == view, onPressed: () => setView(i))])
/// ```
class MinimalFilterBar extends StatelessWidget {
  /// A row of filters.
  const MinimalFilterBar({
    super.key,
    required this.children,
    this.trailing,
    this.divider = true,
    this.padding = defaultPadding,
  });

  /// The filters, usually [MinimalFilter]s.
  final List<Widget> children;

  /// A control held at the strip's end, outside the scroll.
  final Widget? trailing;

  /// Draw the hairline under the strip; off when a table header or another
  /// rule already follows.
  final bool divider;

  /// The strip's inset, start and end in reading order: the trailing
  /// control keeps [EdgeInsetsDirectional.end] on its far side.
  final EdgeInsetsDirectional padding;

  /// The strip's inset: the gutter, so the first filter's frame stands on
  /// the page's keyline with the rows under it.
  static const EdgeInsetsDirectional defaultPadding =
      EdgeInsetsDirectional.symmetric(
        horizontal: MinimalChromeMetrics.gutter,
        vertical: MinimalSpacing.s8,
      );

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final trailing = this.trailing;
    return Container(
      decoration: BoxDecoration(
        border: divider ? Border(bottom: t.rule) : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: MinimalEdgeFade(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: padding.copyWith(
                  end: trailing == null ? padding.end : MinimalSpacing.s8,
                ),
                // The 28 px filters stand in a strip that hugs them; the hit
                // target hands their 44 px margin on into the strip's
                // padding.
                child: MinimalHitTarget(
                  line: MinimalFilter.height,
                  child: Row(
                    children: [
                      for (final (i, child) in children.indexed) ...[
                        if (i > 0) const MinimalGap(MinimalSpacing.s4),
                        child,
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (trailing != null)
            Padding(
              padding: EdgeInsetsDirectional.only(end: padding.end),
              child: trailing,
            ),
        ],
      ),
    );
  }
}

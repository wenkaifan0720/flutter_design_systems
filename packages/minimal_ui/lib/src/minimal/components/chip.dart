import 'package:flutter/widgets.dart';

import '../chrome_metrics.dart';
import '../component_themes.dart';
import '../internal/cap_label.dart';
import '../internal/controls.dart';
import '../internal/face.dart';
import '../internal/styled.dart';
import '../theme.dart';
import 'pressable.dart';

/// A filter pill — the control a filter strip or a single-choice row is made
/// of: 28 px, a hairline edge with 7 px corners, a 12.5 px medium label, an
/// optional 14 px glyph before it and an optional mono [count] after it.
/// Put a set of them in a [MinimalChipRow].
///
/// A selected chip says so in ink alone — its hairline, label and glyph turn
/// to [MinimalThemeData.foreground] on the same plain face, no tint — and
/// announces itself selected; the rest stay paper-quiet in the muted ink on
/// a plain hairline. Counts print in the secondary ink either way. A null
/// [onPressed] disables the chip: it dims, its words stay in the muted ink
/// and a chosen one keeps only its hairline, in the muted ink too, so a
/// disabled chip never reads stronger than an enabled one. The hit area
/// pads out to 44 (inside a [MinimalChipRow], whose own box pads out with
/// it).
///
/// [style] dresses one chip, `components.chip` every one, resolved with
/// [WidgetState.selected] when chosen: every slot. Its outline is the
/// theme's capsule, `shapes.pill` (square under a square scale); `density`
/// moves its height and side padding; `t.rim` is its rim.
///
/// ```dart
/// MinimalChip('Open', count: 2, selected: filter == 1, onPressed: () => setFilter(1))
/// ```
class MinimalChip extends StatelessWidget {
  /// A chip saying [label].
  const MinimalChip(
    this.label, {
    super.key,
    this.selected = false,
    this.onPressed,
    this.icon,
    this.leading,
    this.count,
    this.style,
    this.focusNode,
    this.autofocus = false,
  });

  /// What it says.
  final String label;

  /// Whether it is on.
  final bool selected;

  /// Null disables the chip.
  final VoidCallback? onPressed;

  /// A glyph before the label, drawn at 14.
  final IconData? icon;

  /// A drawn mark before the label in place of [icon]: a chip by status
  /// leads with `MinimalStatusIcon(status, size: 14)`.
  final Widget? leading;

  /// How many things the filter matches, in mono after the label.
  final int? count;

  /// This chip's style, over `components.chip`.
  final MinimalStyle? style;

  /// Its focus node, for a caller that moves focus to it; null keeps one
  /// of its own.
  final FocusNode? focusNode;

  /// Whether it takes keyboard focus when it first appears.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final glyph = icon;
    final leading = this.leading;
    final count = this.count;
    final layers = <MinimalStyle?>[style, t.components.chip];
    // A disabled chip's choice is said by its hairline alone, in the muted
    // ink: the full ink would read stronger than the enabled chips beside
    // it once dimmed, most of all on a dark ground.
    final enabled = onPressed != null;
    final chosenInk = enabled ? t.foreground : t.mutedForeground;
    // A chip is a capsule by role, in the scale's own family.
    final own = t.shapes.pill;
    final pad = t.density.padding(
      EdgeInsets.only(
        left: glyph != null || leading != null
            ? MinimalControlMetrics.pillPadGlyph
            : MinimalControlMetrics.pillPad,
        right: MinimalControlMetrics.pillPad,
      ),
    );
    return MinimalPressable(
      focusNode: focusNode,
      autofocus: autofocus,
      onPressed: onPressed,
      // A chip with no action is disabled.
      enabled: enabled,
      shape: own,
      style: MinimalStyleOf(layers, const {}).press,
      selected: selected,
      builder: (context, states) {
        final so = MinimalStyleOf(layers, states);
        final inkTo =
            so.foreground ??
            (selected && enabled ? t.foreground : t.mutedForeground);
        final least = so.minimumSize;
        // The face and its ink lerp to each state (Minimal's short fade).
        return MinimalFace(
          duration: MinimalMotion.fast,
          ink: inkTo,
          constraints: BoxConstraints(
            minWidth: least?.width ?? 0,
            minHeight:
                least?.height ??
                minimalGrownHeight(
                  context,
                  t.density.height(MinimalChromeMetrics.controlSm),
                ),
          ),
          padding:
              so.padding ??
              EdgeInsetsDirectional.only(start: pad.left, end: pad.right),
          decoration: minimalFrame(
            so.shape ?? own,
            fill: so.fill ?? t.card,
            side: so.rim(selected ? chosenInk : t.border, t.rim),
          ),
          builder: (context, lerped) {
            final ink = lerped ?? inkTo;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (leading != null) ...[
                  leading,
                  const MinimalGap(MinimalChromeMetrics.iconGap),
                ] else if (glyph != null) ...[
                  MinimalIcon(
                    glyph,
                    size: so.iconSize ?? MinimalIconSize.i14,
                    color: ink,
                  ),
                  const MinimalGap(MinimalChromeMetrics.iconGap),
                ],
                Flexible(
                  child: minimalCapLabel(
                    Text(
                      label,
                      style: so.text(
                        t.control.copyWith(
                          fontSize: MinimalControlMetrics.pillLabel,
                        ),
                        ink,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                if (count != null) ...[
                  const MinimalGap(MinimalControlMetrics.countGap),
                  minimalCapLabel(
                    Text(
                      '$count',
                      style: t.countFigure.c(t.mutedForeground),
                      maxLines: 1,
                    ),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }
}

/// A chip strip that cannot overflow: its chips wrap onto new lines, 6 px
/// apart each way, the rhythm of the create form's property pills. The row
/// pads its own hit region by the 8 px a 28 px chip needs to reach 44, so
/// the first line keeps its targets above it and the last below it.
///
/// ```dart
/// MinimalChipRow(children: [for (final f in filters) MinimalChip(f.name, count: f.count, selected: f == on, onPressed: () => pick(f))])
/// ```
class MinimalChipRow extends StatelessWidget {
  /// Lays out [children] in rows that wrap.
  const MinimalChipRow({
    super.key,
    required this.children,
    this.spacing = MinimalChromeMetrics.iconGap,
    this.runSpacing = MinimalChromeMetrics.iconGap,
  });

  /// The chips.
  final List<Widget> children;

  /// Air between chips in a row.
  final double spacing;

  /// Air between rows.
  final double runSpacing;

  @override
  Widget build(BuildContext context) => MinimalHitTarget(
    line: MinimalChromeMetrics.controlSm,
    child: Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: children,
    ),
  );
}

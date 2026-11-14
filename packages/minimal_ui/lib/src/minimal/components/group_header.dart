/// The uppercase group label with its mono count.
library;

import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../chrome_metrics.dart';
import '../internal/cap_label.dart';
import '../theme.dart';
import 'pressable.dart';

/// The header over a group of full-bleed rows — `MORNING  2/3`: the label
/// upper-cased in the label register, with a mono count (or any trailing
/// widget) at the end, on the gutter with 14 px of air above and 6 below.
/// No rule of its own: the rows under it draw theirs.
///
/// With [onExpansionChanged] the header collapses its group: a chevron leads
/// the label, the band from the chevron to the count is the control, and it
/// announces [expanded]. A [trailing] widget stays outside that control,
/// its own node beside it, so a small icon button or a menu there never
/// nests a button in a button.
/// Pass [padding] to set it inside an already padded body.
///
/// ```dart
/// MinimalSectionHeader('Morning', count: '2/3')
/// ```
class MinimalSectionHeader extends StatelessWidget {
  /// A header labelling the group under it.
  const MinimalSectionHeader(
    this.label, {
    super.key,
    this.count,
    this.trailing,
    this.leading,
    this.expanded = true,
    this.onExpansionChanged,
    this.padding = MinimalSectionHeader.inset,
  }) : assert(
         count == null || trailing == null,
         'a group header ends in a count or a trailing widget, not both',
       );

  /// The group's name, printed upper-cased.
  final String label;

  /// A mono figure at the end (`2/3`, `12`, `71 / 84`).
  final String? count;

  /// Any other end widget (a small icon button, a menu); with
  /// [onExpansionChanged] it sits beside the disclosure control, not inside
  /// it.
  final Widget? trailing;

  /// A mark before the label (a status glyph for a status group).
  final Widget? leading;

  /// Whether the group's rows are showing; read only with
  /// [onExpansionChanged].
  final bool expanded;

  /// Makes the header a disclosure control for its group: called with the
  /// next state, the opposite of [expanded].
  final ValueChanged<bool>? onExpansionChanged;

  /// Space round the header.
  final EdgeInsetsGeometry padding;

  /// The header's band inset: the gutter at the sides, 14 above, 6 below.
  static const EdgeInsets inset = EdgeInsets.fromLTRB(
    MinimalChromeMetrics.gutter,
    14,
    MinimalChromeMetrics.gutter,
    6,
  );

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final onExpansionChanged = this.onExpansionChanged;
    final toggle = onExpansionChanged == null
        ? null
        : () => onExpansionChanged(!expanded);
    final end = count;
    final action = trailing;
    final turn = context.minimalStill ? Duration.zero : MinimalMotion.fast;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final resolved = padding.resolve(Directionality.of(context));
    final endInset = rtl ? resolved.left : resolved.right;
    // With a toggle the trailing widget stands outside the pressable, so
    // the pressable's band stops short of the end inset and the trailing
    // widget carries it instead.
    final split = toggle != null && action != null;
    final heading = Row(
      children: [
        if (toggle != null) ...[
          AnimatedRotation(
            turns: expanded ? 0 : -0.25,
            duration: turn,
            curve: MinimalMotion.out,
            child: MinimalIcon(
              LucideIcons.chevronDown,
              size: MinimalIconSize.i14,
            ),
          ),
          const MinimalGap(MinimalSpacing.s4),
        ],
        if (leading != null) ...[leading!, const MinimalGap(MinimalSpacing.s8)],
        Expanded(
          child: minimalCapLabel(
            Text(
              label.toUpperCase(),
              style: t.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        if (end != null) ...[
          const MinimalGap(MinimalSpacing.s8),
          minimalCapLabel(Text(end, style: t.mono.medium.c(t.mutedForeground))),
        ] else if (action != null && !split) ...[
          const MinimalGap(MinimalSpacing.s8),
          action,
        ],
      ],
    );
    if (toggle == null) {
      return Semantics(
        header: true,
        child: Padding(padding: resolved, child: heading),
      );
    }
    // The pressable is the outermost layer of the disclosure (its hit area
    // and its node); the header and expanded flags land on that node from
    // inside.
    final disclosure = MinimalPressable(
      onPressed: toggle,
      radius: 0,
      child: Semantics(
        header: true,
        expanded: expanded,
        child: Padding(
          padding: !split
              ? resolved
              : rtl
              ? resolved.copyWith(left: 0)
              : resolved.copyWith(right: 0),
          child: heading,
        ),
      ),
    );
    if (!split) return disclosure;
    return Row(
      children: [
        Expanded(child: disclosure),
        Padding(
          padding: EdgeInsetsDirectional.only(
            start: MinimalSpacing.s8,
            top: resolved.top,
            end: endInset,
            bottom: resolved.bottom,
          ),
          child: action,
        ),
      ],
    );
  }
}

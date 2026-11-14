import 'package:flutter/widgets.dart';

import '../../internal/flush_end.dart';
import 'structure.dart';
import '../../theme.dart';

/// A section of rows of one kind on the glass: a tile in its list face (room
/// for rows at its top and foot) holding a [FrostedRowGroup] of the [rows],
/// under a [FrostedCardHeader] saying the [title] when it has one (its
/// [aside] or [trailing] at the head's end); or,
/// when [tile] is false, a [FrostedSectionHeader] on the canvas over the rows'
/// tile (the desktop, whose tiles carry their own heads, draws the first
/// form either way). [timeline] and [hairlines] are the group's.
///
/// ```dart
/// FrostedListSection(title: 'Transactions', aside: '32 in October', rows: [FrostedDayHead('Today', first: true), row, row])
/// ```
class FrostedListSection extends StatelessWidget {
  /// Creates a [FrostedListSection].
  const FrostedListSection({
    required this.rows,
    this.title,
    this.aside,
    this.trailing,
    this.tile = true,
    this.timeline = false,
    this.hairlines = false,
    this.label,
    super.key,
  });

  /// What the section is of (Transactions); null for rows with no head.
  final String? title;

  /// The rows, a day's head or a row each.
  final List<Widget> rows;

  /// Words at the head's end (32 in October).
  final String? aside;

  /// An act at the head's end (See all).
  final Widget? trailing;

  /// Whether the head stands in the tile (true) or on the canvas above it.
  final bool tile;

  /// Whether the group runs a timeline's thread down its rows.
  final bool timeline;

  /// Whether the group rules hairlines between its rows.
  final bool hairlines;

  /// What a screen reader calls the section; null for no name of its own.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final wide = FrostedBreakpoints.isWide(context);
    final aside = this.aside;
    final trailing = this.trailing;
    final group = FrostedRowGroup(
      timeline: timeline,
      hairlines: hairlines,
      children: rows,
    );
    final title = this.title;
    if (title == null) {
      return FrostedFacedCard(
        face: FrostedCardFace.list,
        label: label,
        child: group,
      );
    }
    if (tile || wide) {
      // .tile-h .cap { white-space: nowrap } .list-tile--h { padding-top:
      // var(--pad) } and padding-bottom 12 on the desktop.
      final pad = FrostedBreakpoints.pad(context);
      final asideText = aside == null
          ? null
          : Text(aside, style: t.textTheme.labelMedium, maxLines: 1);
      // As much under the last row's content as over the head (design6 P):
      // the room the last row leaves under its words is given back.
      return FrostedFacedCard(
        face: FrostedCardFace.list,
        label: label,
        padding: EdgeInsets.all(pad),
        child: FrostedFlushEnd(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FrostedCardHeader(
                title,
                trailing: trailing == null
                    ? asideText
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: FrostedSpacing.s8,
                        children: [?asideText, trailing],
                      ),
              ),
              group,
            ],
          ),
        ),
      );
    }
    // The head and its glass are `.main`'s siblings in the source: its gap
    // stands between them (the head's words stood 4 over the glass's rim).
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FrostedBreakpoints.gap(context),
      children: [
        FrostedSectionHeader(title, aside: aside, trailing: trailing),
        FrostedFacedCard(
          face: FrostedCardFace.list,
          label: label,
          child: group,
        ),
      ],
    );
  }
}

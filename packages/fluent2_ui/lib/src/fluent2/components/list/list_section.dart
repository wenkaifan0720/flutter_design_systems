import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../theme.dart';
import 'list.dart';

/// A titled section of rows of one kind (a team's files, today's meetings,
/// a channel's chats): a [Fluent2SectionHeader] ([title], a quiet
/// [aside], its one [action] at the end), the [selector] that picks a set
/// of rows when they come in sets (a Fluent2TabList: Recent, Shared,
/// Favourites) 8 under it, then the [rows] in a [Fluent2ListGroup] on a
/// card ([asCard] false lays them on the ground) with a hairline between
/// each pair ([dividers]) and a quiet [footer].
///
/// ```dart
/// Fluent2ListSection(title: 'Recent files', aside: '12', action: Fluent2SectionHeader.link('See all', onPressed: openFiles), rows: [Fluent2ListItem(icon: Fluent2Icons.document, title: 'Q3 plan.docx', onTap: open)])
/// ```
class Fluent2ListSection extends StatelessWidget {
  /// A list section headed [title].
  const Fluent2ListSection({
    required this.title,
    required this.rows,
    this.aside,
    this.action,
    this.selector,
    this.footer,
    this.asCard = true,
    this.dividers = true,
    super.key,
  });

  /// The section's heading.
  final String title;

  /// The rows (Fluent2ListItems), all of one kind.
  final List<Widget> rows;

  /// A count or a note after the title.
  final String? aside;

  /// The head's act (a Fluent2SectionHeader.link).
  final Widget? action;

  /// What picks the set of rows shown (tabs), under the head.
  final Widget? selector;

  /// A quiet line under the rows.
  final String? footer;

  /// Whether the rows stand on a card.
  final bool asCard;

  /// Whether a hairline stands between rows.
  final bool dividers;

  @override
  Widget build(BuildContext context) {
    final selector = this.selector;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      // The head, the selector and the card share the section's keylines
      // (the keyline check; the card's rows hold their own).
      child: DesignKeylineRegion(
        label: title,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Fluent2SectionHeader(title, aside: aside, action: action),
            if (selector != null) ...[
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: selector,
              ),
              const SizedBox(height: Fluent2Spacing.s),
            ],
            Fluent2ListGroup(
              footer: footer,
              asCard: asCard,
              dividers: dividers,
              children: rows,
            ),
          ],
        ),
      ),
    );
  }
}

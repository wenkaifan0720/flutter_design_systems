import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../theme.dart';

/// A heading over a section of a page, a screen reader's heading, with an
/// [action] at its end (a link: View all, Change). [title] is the medium
/// heading; [isLarge] makes it the large one, for a page's main sections.
///
/// ```dart
/// CivicSectionHeader(title: 'Your permits', action: CivicLink(onPressed: openAll, child: const Text('View all')))
/// ```
class CivicSectionHeader extends StatelessWidget {
  /// A section's heading.
  const CivicSectionHeader({
    super.key,
    required this.title,
    this.action,
    this.isLarge = false,
  });

  /// The heading's words.
  final String title;

  /// What stands at the heading's end.
  final Widget? action;

  /// Whether it is the large heading.
  final bool isLarge;

  @override
  Widget build(BuildContext context) {
    final text = context.civicText;
    final heading = Semantics(
      header: true,
      child: Text(title, style: isLarge ? text.headingL : text.headingM),
    );
    final end = action;
    return Padding(
      padding: const EdgeInsets.only(bottom: CivicSpacing.s12),
      child: end == null
          ? heading
          : Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: CivicSpacing.s16,
              children: [heading, end],
            ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title))
      ..add(FlagProperty('isLarge', value: isLarge, ifTrue: 'large'));
  }
}

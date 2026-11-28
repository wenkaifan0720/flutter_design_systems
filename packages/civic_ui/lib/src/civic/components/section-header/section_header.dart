import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../internal/fit_words.dart';
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
      child: CivicFitWords(
        title,
        style: isLarge ? text.headingL : text.headingM,
        most: isLarge ? CivicLayout.headingScaleMost : double.infinity,
      ),
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

/// A page's title: the extra-large heading at the top of a page's content,
/// a screen reader's heading, so a reader who moves by headings lands on it
/// first. One to a page, under the top bar, which names the page's place
/// ("Add"); the heading says what the page is for ("Add a book"). With a
/// [caption], a quieter line over it names the section or the step the page
/// belongs to ("Your reading list"). It takes no room of its own round it:
/// the page's column sets the gap under it.
///
/// Its words grow with the reader's text size, up to the cap Civic's large
/// headings keep, and wrap; a word too long for the width shrinks to fit.
///
/// ```dart
/// CivicPageHeading('Add a book', caption: 'Your reading list')
/// ```
class CivicPageHeading extends StatelessWidget {
  /// A page's title saying [title].
  const CivicPageHeading(this.title, {super.key, this.caption});

  /// The heading's words: what the page is for.
  final String title;

  /// A quieter line over the heading: the section or the step the page
  /// belongs to; null shows none.
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final text = context.civicText;
    final over = caption;
    final heading = Semantics(
      header: true,
      child: CivicFitWords(
        title,
        style: text.headingXL,
        most: CivicLayout.headingScaleMost,
      ),
    );
    if (over == null) return heading;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: CivicSpacing.s8,
      children: [
        Text(
          over,
          style: text.headingM.copyWith(
            color: context.civicTheme.textSecondary,
            fontWeight: FontWeight.w400,
          ),
        ),
        heading,
      ],
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title))
      ..add(StringProperty('caption', caption, defaultValue: null));
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../theme.dart';

/// What a list or a page says when it has nothing to show, or cannot show
/// it: a [title] in a heading's weight that says so plainly ("No
/// applications yet", "No results for 'Harbour'", "Sorry, the service is
/// unavailable"), then [children]: what it means and what to try, then
/// [actions], what the reader can do, as far under the words as a page's
/// Continue stands. No picture: the words do the work.
///
/// [announce] says the title to a screen reader as it appears, for a
/// state that replaces a list the reader was in (a search that found
/// nothing).
///
/// ```dart
/// CivicEmptyState(
///   title: 'No applications yet',
///   actions: [
///     CivicButton(onPressed: apply, child: const Text('Apply for a permit')),
///   ],
///   children: [const Text('When you apply for a permit it will show here.')],
/// )
/// ```
class CivicEmptyState extends StatelessWidget {
  /// What there is not.
  const CivicEmptyState({
    super.key,
    required this.title,
    this.children = const [],
    this.actions = const [],
    this.announce = false,
    this.isPageHeading = false,
  });

  /// What there is not, in a sentence.
  final String title;

  /// What it means and what to try, a paragraph apart.
  final List<Widget> children;

  /// What the reader can do (try again, apply): a button, then any link
  /// for another way.
  final List<Widget> actions;

  /// Whether a screen reader hears [title] as it appears.
  final bool announce;

  /// Whether [title] is the page's heading: a page that is only this
  /// state (the service unavailable).
  final bool isPageHeading;

  @override
  Widget build(BuildContext context) {
    final text = context.civicText;
    // A live region: a screen reader hears it as it appears.
    final heading = Semantics(
      header: true,
      liveRegion: announce,
      child: Text(title, style: isPageHeading ? text.headingXL : text.headingM),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        heading,
        for (final child in children) ...[
          const SizedBox(height: CivicSpacing.s16),
          DefaultTextStyle.merge(style: text.body, child: child),
        ],
        // The actions stand off the words as a page's Continue does.
        for (final (i, action) in actions.indexed) ...[
          SizedBox(height: i == 0 ? CivicSpacing.s32 : CivicSpacing.s16),
          Align(alignment: AlignmentDirectional.centerStart, child: action),
        ],
      ],
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title))
      ..add(IntProperty('actions', actions.length, defaultValue: 0))
      ..add(FlagProperty('announce', value: announce, ifTrue: 'announce'))
      ..add(
        FlagProperty(
          'isPageHeading',
          value: isPageHeading,
          ifTrue: 'page heading',
        ),
      );
  }
}

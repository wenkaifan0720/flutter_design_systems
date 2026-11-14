import 'package:flutter/widgets.dart';

import '../heads.dart';
import '../theme.dart';

/// A section with nothing in it yet: a drawing of your own if you like, a lettered title, a line, a way forward.
///
/// ```dart
/// ComicEmptyState(title: 'All caught up', body: 'No new messages.')
/// ```
class ComicEmptyState extends StatelessWidget {
  /// Creates a [ComicEmptyState].
  const ComicEmptyState({
    super.key,
    required this.title,
    this.body,
    this.art,
    this.action,
  });

  /// The primary heading.
  final String title;

  /// The main content of the page or section.
  final String? body;

  /// A `ComicMark` or a `ComicThought`, for what is missing.
  final Widget? art;

  /// The optional action beside this content.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (art != null) ...[art!, const SizedBox(height: 10)],
          Semantics(
            label: title,
            excludeSemantics: true,
            child: ComicLetters(title, textAlign: TextAlign.center),
          ),
          if (body != null) ...[
            const SizedBox(height: 6),
            Text(body!, textAlign: TextAlign.center, style: t.type.small),
          ],
          if (action != null) ...[const SizedBox(height: 14), action!],
        ],
      ),
    );
  }
}

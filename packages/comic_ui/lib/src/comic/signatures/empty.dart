import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../heads.dart';
import '../theme.dart';
import '../knobs.dart' show ComicSpace;

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

  /// An `Icon` or a `ComicThought`, for what is missing.
  final Widget? art;

  /// The optional action beside this content.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: ComicSpace.gap,
        horizontal: ComicSpace.near,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (art != null) ...[art!, const SizedBox(height: ComicSpace.close)],
          Semantics(
            label: title,
            excludeSemantics: true,
            child: ComicLetters(title, textAlign: TextAlign.center),
          ),
          if (body != null) ...[
            const SizedBox(height: ComicSpace.close),
            Text(body!, textAlign: TextAlign.center, style: t.type.small),
          ],
          if (action != null) ...[
            const SizedBox(height: ComicSpace.gap),
            action!,
          ],
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title))
      ..add(StringProperty('body', body, defaultValue: null));
  }
}

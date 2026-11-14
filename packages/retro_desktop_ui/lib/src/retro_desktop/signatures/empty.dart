import 'package:flutter/widgets.dart';

import '../theme.dart';

/// A window with nothing in it yet: an optional drawing, a title in the system face and a line.
///
/// ```dart
/// RetroDesktopEmpty(title: 'Nothing here yet', body: 'Notes you file here show up in this window.')
/// ```
class RetroDesktopEmpty extends StatelessWidget {
  /// Creates a [RetroDesktopEmpty].
  const RetroDesktopEmpty({
    super.key,
    required this.title,
    required this.body,
    this.art,
  });

  /// The heading displayed above the content.
  final String title;

  /// The main content shown beneath the heading.
  final String body;

  /// A drawing of what's missing: a `RetroDesktopSystemMark` will do.
  final Widget? art;

  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (art != null) ...[art!, const SizedBox(height: 8)],
          Text(title, textAlign: TextAlign.center, style: t.type.small),
          const SizedBox(height: 4),
          Text(body, textAlign: TextAlign.center, style: t.type.note),
        ],
      ),
    );
  }
}

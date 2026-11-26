import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme.dart';
import '../link/link.dart';

/// One place in a [CivicBreadcrumbs] trail.
@immutable
class CivicBreadcrumb {
  /// A place called [label].
  const CivicBreadcrumb({required this.label, this.onPressed, this.url});

  /// Its name.
  final String label;

  /// Goes there; null for the page the reader is on, said in plain words.
  final VoidCallback? onPressed;

  /// The place's address, a route or a web address: with one, the crumb
  /// is read as a link to it ([CivicLink.url]); without one, as a button.
  final Uri? url;
}

/// Where a page sits in the service, above its heading: the places over
/// it, each a quiet link in the smaller size, a chevron between them that
/// points the reading way. It wraps rather than shrinks.
///
/// The trail leads to the page; leave the page itself out, or give it
/// last with no `onPressed`.
///
/// ```dart
/// CivicBreadcrumbs(
///   items: [
///     CivicBreadcrumb(label: 'Home', onPressed: goHome, url: Uri.parse('/')),
///     CivicBreadcrumb(
///       label: 'Your applications',
///       onPressed: goBack,
///       url: Uri.parse('/applications'),
///     ),
///   ],
/// )
/// ```
class CivicBreadcrumbs extends StatelessWidget {
  /// A trail of [items], from the top of the service down.
  const CivicBreadcrumbs({super.key, required this.items});

  /// The places, from the top down.
  final List<CivicBreadcrumb> items;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final small = context.civicText.bodySmall;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      // The places and chevrons stand 4 apart face to face, a link's target
      // reaching into the room between (ui_core's RawChipGroup).
      child: RawChipGroup(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: CivicSpacing.s4,
        children: [
          for (final (i, item) in items.indexed) ...[
            if (i > 0)
              ExcludeSemantics(
                child: Transform.flip(
                  flipX: rtl,
                  child: Icon(
                    LucideIcons.chevronRight,
                    size: _chevron,
                    applyTextScaling: true,
                    color: t.textSecondary,
                  ),
                ),
              ),
            if (item.onPressed case final go?)
              CivicLink.quiet(
                onPressed: go,
                url: item.url,
                textStyle: small,
                child: Text(item.label),
              )
            else
              Text(item.label, style: small.copyWith(color: t.textPrimary)),
          ],
        ],
      ),
    );
  }

  static const double _chevron = 16;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      IterableProperty<String>('items', items.map((i) => i.label)),
    );
  }
}

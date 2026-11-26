import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../theme.dart';

/// The acts that end a page, side by side: a button first (the one most
/// readers want), then a second button or a link, each centred on the
/// row; below 600 wide they stack, a button its full width so a thumb finds
/// it. It wraps rather than shrinks at any width.
///
/// ```dart
/// CivicButtonGroup(
///   children: [
///     CivicButton(onPressed: save, child: const Text('Save and continue')),
///     CivicLink(onPressed: later, child: const Text('Save and come back later')),
///   ],
/// )
/// ```
class CivicButtonGroup extends StatelessWidget {
  /// A group of [children]: buttons and links.
  const CivicButtonGroup({super.key, required this.children});

  /// The buttons and links, the main act first.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final narrow =
        (MediaQuery.maybeSizeOf(context)?.width ?? CivicLayout.medium) <
        CivicLayout.medium;
    if (narrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: CivicSpacing.s16,
        children: children,
      );
    }
    // The faces stand 24 apart, 16 run under run, a link's target reaching
    // into the room between (ui_core's RawChipGroup).
    return RawChipGroup(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: CivicSpacing.s24,
      runSpacing: CivicSpacing.s16,
      children: children,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('children', children.length));
  }
}

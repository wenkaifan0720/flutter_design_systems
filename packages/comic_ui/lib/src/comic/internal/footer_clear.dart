import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Where a `ComicScaffold`'s footer stands, so that a snack bar or a toast
/// raised from its page stands above the footer rather than over it, as a
/// `Scaffold` keeps a snackbar above its footer. The raised parts live in
/// the navigator's overlay, out of reach of ui_core's
/// `RawToasterKeepClear`, so the page tells them where its footer is.
class ComicFooterClear extends InheritedWidget {
  /// Marks [footer] as the footer of the page under [child].
  const ComicFooterClear({
    super.key,
    required this.footer,
    required super.child,
  });

  /// The footer's box (no box while the page has no footer).
  final GlobalKey footer;

  /// How far above [overlay]'s foot a part raised from [context] stands to
  /// clear its page's footer: the height the footer covers there, less the
  /// screen's safe inset the raised part keeps already. 0 without a footer.
  static double of(BuildContext context, OverlayState overlay) {
    final scope = context.getInheritedWidgetOfExactType<ComicFooterClear>();
    final box = scope?.footer.currentContext?.findRenderObject();
    final host = overlay.context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return 0;
    if (host is! RenderBox || !host.attached || !host.hasSize) return 0;
    final top = box.localToGlobal(Offset.zero, ancestor: host).dy;
    final covered = host.size.height - top;
    final safe = MediaQuery.maybeViewPaddingOf(overlay.context)?.bottom ?? 0;
    return math.max(0.0, covered - safe);
  }

  @override
  bool updateShouldNotify(ComicFooterClear oldWidget) =>
      oldWidget.footer != footer;
}

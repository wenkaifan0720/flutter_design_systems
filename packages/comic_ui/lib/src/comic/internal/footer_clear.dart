import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Where a `ComicScaffold`'s footer (or `ComicAppShell`'s tab bar) stands, so that a snack bar or a toast
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
  /// clear the footers round it (its page's, the app shell's tab bar): the
  /// most any of them covers there, less the screen's safe inset the raised
  /// part keeps already. 0 without a footer, or with one outside [overlay]
  /// (a tab bar under a branch's own navigator).
  static double of(BuildContext context, OverlayState overlay) {
    final host = overlay.context.findRenderObject();
    if (host is! RenderBox || !host.attached || !host.hasSize) return 0;
    final hostTop = host.localToGlobal(Offset.zero).dy;
    final safe = MediaQuery.maybeViewPaddingOf(overlay.context)?.bottom ?? 0;
    var most = 0.0;
    Element? scope = context
        .getElementForInheritedWidgetOfExactType<ComicFooterClear>();
    while (scope != null) {
      final footer = (scope.widget as ComicFooterClear).footer;
      final box = footer.currentContext?.findRenderObject();
      if (box is RenderBox && box.attached && box.hasSize) {
        final top = box.localToGlobal(Offset.zero).dy - hostTop;
        most = math.max(most, host.size.height - top - safe);
      }
      Element? parent;
      scope.visitAncestorElements((element) {
        parent = element;
        return false;
      });
      scope = parent
          ?.getElementForInheritedWidgetOfExactType<ComicFooterClear>();
    }
    return most;
  }

  @override
  bool updateShouldNotify(ComicFooterClear oldWidget) =>
      oldWidget.footer != footer;
}

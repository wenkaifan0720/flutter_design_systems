import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

/// How far the desktop sidebar stands over the left of the pages under it:
/// a page lays its content out to the right of [inset], as the source's
/// grid does. The shell publishes it on
/// the desktop; elsewhere it is none. Plumbing of the shell and the screen;
/// pages never place one.
class LedgerSideInset extends InheritedWidget {
  /// Publishes the sidebar's [inset] to [child].
  const LedgerSideInset({required this.inset, required super.child, super.key});

  /// How far the sidebar stands over the pages' start.
  final double inset;

  /// The sidebar's reach over [context]'s page: 0 off the desktop, in a
  /// sheet, or outside a shell.
  static double of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LedgerSideInset>()?.inset ?? 0;

  @override
  bool updateShouldNotify(LedgerSideInset oldWidget) =>
      inset != oldWidget.inset;
}

/// The most a surface aligned to its anchor's end (a split button's menu)
/// may be wide without reaching under the sidebar: from the anchor's end
/// back to the sidebar, one margin clear of it. A page's overlay runs
/// under the sidebar and ui_core keeps a surface inside the overlay alone,
/// so a menu wider than that room would slide under the bar. Null without
/// a sidebar over the overlay [context] stands in, beside a surface that
/// opens to a side, or with less room than a menu's words need (it then
/// keeps its width).
double? ledgerRoomBesideSide(BuildContext context, DesignOverlayInfo info) {
  final inset = LedgerSideInset.of(context);
  if (inset == 0 || !info.side.isVertical) return null;
  const margin = DesignOverlayPlacement();
  final padding = MediaQuery.paddingOf(context);
  final anchor = info.anchorRect;
  final room = switch (Directionality.of(context)) {
    TextDirection.ltr => anchor.right - inset - margin.margin,
    // The overlay's width: the room ui_core gives a surface, its margins
    // and the window's padding.
    TextDirection.rtl =>
      padding.left +
          info.maxSize.width +
          2 * margin.margin +
          padding.right -
          inset -
          margin.margin -
          anchor.left,
  };
  return room < _leastRoom ? null : room;
}

// A menu's words at their least: two 16s and a short word or two.
const double _leastRoom = 120;

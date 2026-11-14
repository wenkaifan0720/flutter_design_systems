import 'package:flutter/widgets.dart';

/// Where a screen stands its authored top bar: the phone's paper strip
/// pinned over the page, or the masthead at the top of the page's scroll.
/// [LedgerScreen] places the one bar in both; each draws its own part.
enum LedgerBarSlot {
  /// The phone's paper strip, pinned over the page.
  strip,

  /// The masthead, at the top of the page's scroll.
  masthead,
}

/// Tells a `LedgerTopBar` which part of it a screen stands here. Plumbing of
/// the screen and the bar.
class LedgerBarSlotScope extends InheritedWidget {
  /// Tells the bar under it its [slot].
  const LedgerBarSlotScope({
    required this.slot,
    required super.child,
    super.key,
  });

  /// The part of the bar the screen stands here.
  final LedgerBarSlot slot;

  /// The slot at [context], or null outside a screen.
  static LedgerBarSlot? of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<LedgerBarSlotScope>()?.slot;

  @override
  bool updateShouldNotify(LedgerBarSlotScope oldWidget) =>
      slot != oldWidget.slot;
}

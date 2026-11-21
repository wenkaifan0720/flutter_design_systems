import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

/// How far the desktop sidebar stands over the left of the pages under it:
/// a page lays its content out to the right of [inset], as the source's
/// grid does. The shell publishes it on
/// the desktop; elsewhere it is none. Plumbing of the shell and the screen;
/// pages never place one.
class LedgerSideInset extends InheritedWidget {
  /// Publishes the sidebar's [inset] to [child].
  const LedgerSideInset({
    required this.inset,
    required super.child,
    this.beside = false,
    super.key,
  });

  /// How far the sidebar stands over the pages' start.
  final double inset;

  /// Whether the pages stand beside the sidebar or the rail rather than
  /// under it (ui_core's shell lays them beside it): nothing to pad, but a
  /// page's masthead heads it as beside a bar.
  final bool beside;

  /// The sidebar's reach over [context]'s page: 0 off the desktop, in a
  /// sheet, or outside a shell.
  static double of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LedgerSideInset>()?.inset ?? 0;

  /// Whether [context]'s page stands by a sidebar or a rail: under one (an
  /// [inset] over 0) or [beside] one.
  static bool besideOf(BuildContext context) {
    final side = context.dependOnInheritedWidgetOfExactType<LedgerSideInset>();
    return side != null && (side.beside || side.inset > 0);
  }

  @override
  bool updateShouldNotify(LedgerSideInset oldWidget) =>
      inset != oldWidget.inset || beside != oldWidget.beside;
}

/// Publishes the sidebar's [inset] over [child] ([LedgerSideInset]) and
/// keeps every surface ui_core opens there (a split button's menu, a
/// select's list, a popover, a tooltip) clear of the bar
/// ([RawPopoverPadding] at the reading start): a page's overlay runs
/// under the sidebar, which stands over it. No padding at an [inset] of 0.
Widget ledgerBesideSide({required double inset, required Widget child}) =>
    LedgerSideInset(
      inset: inset,
      child: inset == 0
          ? child
          : RawPopoverPadding(
              padding: EdgeInsetsDirectional.only(start: inset),
              child: child,
            ),
    );

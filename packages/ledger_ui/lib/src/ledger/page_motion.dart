import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'theme.dart';

/// Ledger's page motion, for a `PageTransitionsTheme`: a pushed page is a
/// leaf laid down on the ledger. It fades in as it rises the last [rise]
/// onto the page, in [LedgerMotion.base] on [LedgerMotion.out]; a pop lifts
/// it off the same way, and the page under it stays where it is. Under
/// reduced motion it lands at once. A destination chosen from the side bar,
/// the rail or the tab bar is no push: it changes in place.
///
/// The host sets it on the Material Ledger is built on, so a `LedgerPage`
/// and that library's page routes take it. Flutter's own `MaterialPageRoute`
/// reads the app's `ThemeData` instead: give it [ledgerPageTransitions] there
/// too, as the README's install does. On iOS it replaces Cupertino's slide,
/// and with it the edge swipe back, which is that slide's own:
/// [ledgerPageTransitions] puts the swipe back round it there (ui_core's
/// `SwipeBackPageTransitionsBuilder`).
///
/// ```dart
/// const PageTransitionsTheme(builders: {TargetPlatform.android: LedgerPageTransitions()})
/// ```
class LedgerPageTransitions extends PageTransitionsBuilder {
  /// Ledger's page motion.
  const LedgerPageTransitions();

  /// How far a leaf rises as it is laid down.
  static const double rise = LedgerSpacing.s8;

  @override
  Duration get transitionDuration => LedgerMotion.base;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => _Leaf(animation: animation, child: child);
}

/// [LedgerPageTransitions] on every platform: one map for the
/// `PageTransitionsTheme` of either Material, Flutter's own or the one
/// Ledger is built on. On iOS a swipe from the screen's leading edge still
/// takes a page back (ui_core's `SwipeBackPageTransitionsBuilder`
/// round the leaf): the page follows the finger as on every iOS screen, and
/// a push or a pop is Ledger's leaf.
///
/// ```dart
/// ThemeData(pageTransitionsTheme: const PageTransitionsTheme(builders: ledgerPageTransitions))
/// ```
const Map<TargetPlatform, PageTransitionsBuilder> ledgerPageTransitions = {
  TargetPlatform.android: LedgerPageTransitions(),
  TargetPlatform.fuchsia: LedgerPageTransitions(),
  TargetPlatform.iOS: SwipeBackPageTransitionsBuilder(LedgerPageTransitions()),
  TargetPlatform.linux: LedgerPageTransitions(),
  TargetPlatform.macOS: LedgerPageTransitions(),
  TargetPlatform.windows: LedgerPageTransitions(),
};

/// A leaf laid down: [child] fading in as it rises onto the page.
class _Leaf extends StatelessWidget {
  const _Leaf({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (LedgerMotion.isReduced(context)) return child;
    final laid = animation.drive(CurveTween(curve: LedgerMotion.out));
    return FadeTransition(
      opacity: laid,
      child: AnimatedBuilder(
        animation: laid,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, LedgerPageTransitions.rise * (1 - laid.value)),
          child: child,
        ),
        child: child,
      ),
    );
  }
}

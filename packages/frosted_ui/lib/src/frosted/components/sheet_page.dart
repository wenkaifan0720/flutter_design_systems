// The page sheet as a [Page]: what an app's router raises a sheet with.
// Part of the host layer, exported from the host library, not the main one.
import 'package:material_ui/material_ui.dart';
import 'package:ui_core/host.dart';

import '../theme.dart';
import 'sheet.dart';

/// The [Page] whose route is Frosted's page sheet, created on the
/// root navigator so it rises over the shell's bar. [drawer] stands it as
/// tall as its content; [fullScreen] raises a full-screen cover on the
/// ground instead, with no barrier, drawn as a pushed page whose exit is
/// the close. Either publishes `RoutePresentation.sheet` around its child, so
/// the screen inside derives its close, or with [back] the way back.
///
/// ```dart
/// Navigator(pages: [FrostedSheetPage<void>(name: 'goal-new', drawer: true, child: NewGoalPage())], onDidRemovePage: (page) {})
/// ```
class FrostedSheetPage<T> extends Page<T> {
  /// Creates a [FrostedSheetPage].
  const FrostedSheetPage({
    required this.child,
    this.drawer = false,
    this.fullScreen = false,
    this.back = false,
    super.key,
    super.name,
  });

  /// The sheet's content.
  final Widget child;

  /// As tall as its content (at most the sheet's tallest).
  final bool drawer;

  /// A full-screen cover: no barrier, no card.
  final bool fullScreen;

  /// Closes by the way back rather than the close: a detail read and left
  /// like a page.
  final bool back;

  /// Whether the sheet page [context] stands in closes by the way back
  /// ([back]); the top bar reads it to derive its exit.
  static bool closesBack(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_BackExit>() != null;

  @override
  Route<T> createRoute(BuildContext context) {
    // Read off the route's CURRENT page, not this one: when the router updates
    // the page in place (same key, new child: a changed query parameter), the
    // route keeps its object and rebuilds with the new one.
    Widget current(BuildContext sheetContext) {
      final page = ModalRoute.of(sheetContext)?.settings;
      final shown = page is FrostedSheetPage ? page.child : child;
      return back ? _BackExit(child: shown) : shown;
    }

    if (fullScreen) {
      return MaterialPageRoute<T>(
        settings: this,
        fullscreenDialog: true,
        builder: (sheetContext) => RoutePresentationScope(
          presentation: RoutePresentation.sheet,
          child: ColoredBox(
            color: sheetContext.frostedTheme.colorScheme.background,
            child: current(sheetContext),
          ),
        ),
      );
    }
    return FrostedSheet.pageRoute<T>(
      context: context,
      settings: this,
      drawer: drawer,
      builder: current,
    );
  }
}

/// Marks a sheet page that closes by the way back ([FrostedSheetPage.back]).
class _BackExit extends InheritedWidget {
  const _BackExit({required super.child});

  @override
  bool updateShouldNotify(_BackExit oldWidget) => false;
}

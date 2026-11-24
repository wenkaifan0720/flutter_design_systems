import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../theme.dart';

/// A page pushed on the one before it, for a navigator's pages or a
/// router's page builder (go_router's `pageBuilder`), on Civic's ground. It
/// changes as every Civic page does ([CivicPageRoute]: nothing travels),
/// whatever app it stands in. A [CivicTopBar] on it derives the way back
/// ([CivicTopBar.autoLeading]).
///
/// ```dart
/// Navigator(
///   pages: [
///     const CivicPage<void>(key: ValueKey('home'), child: PermitsHome()),
///     if (permit != null)
///       const CivicPage<void>(key: ValueKey('permit'), child: PermitPage()),
///   ],
///   onDidRemovePage: (page) => setState(() => permit = null),
/// )
/// ```
class CivicPage<T> extends Page<T> {
  /// A pushed page of [child].
  const CivicPage({required this.child, super.key, super.name});

  /// The page.
  final Widget child;

  @override
  Route<T> createRoute(BuildContext context) => CivicPageRoute<T>(
    settings: this,
    builder: (context) {
      // The route keeps its first page; a router updating it in place (a
      // new query) hands a new one, read here.
      final page = ModalRoute.of(context)?.settings;
      return page is CivicPage ? page.child : child;
    },
  );
}

/// A task raised over the whole app, for the pages of its root navigator (or
/// a router's page builder there). Civic has no sheet that half covers a page: a task is a
/// page of its own, with all of the reader's attention, so it stands over
/// everything, comes in as any page does ([CivicPageRoute]: it does not
/// rise), and its [CivicTopBar.autoLeading] closes it rather than going
/// back. [drawer] asks for a short sheet; Civic gives the same page.
///
/// ```dart
/// Navigator(
///   pages: [
///     const CivicPage<void>(key: ValueKey('home'), child: PermitsHome()),
///     if (applying)
///       const CivicSheetPage<void>(key: ValueKey('apply'), child: ApplyPage()),
///   ],
///   onDidRemovePage: (page) => setState(() => applying = false),
/// )
/// ```
class CivicSheetPage<T> extends Page<T> {
  /// A raised task of [child].
  const CivicSheetPage({
    required this.child,
    this.drawer = false,
    super.key,
    super.name,
  });

  /// The task's page.
  final Widget child;

  /// Whether a short sheet was asked for; Civic stands the same page.
  final bool drawer;

  @override
  Route<T> createRoute(BuildContext context) => CivicPageRoute<T>(
    settings: this,
    fullscreenDialog: true,
    builder: (context) {
      final page = ModalRoute.of(context)?.settings;
      return RoutePresentationScope(
        presentation: RoutePresentation.sheet,
        child: page is CivicSheetPage ? page.child : child,
      );
    },
  );
}

/// A page on Civic's ground that changes as Civic's pages do, in any app (a
/// MaterialApp, a CupertinoApp, a WidgetsApp): nothing travels. The page's
/// ground first covers the page it leaves, then its own words fade in over
/// that ground; going back is the same the other way. A service's page
/// changes as a web page loads, in place, and a reader who is unsettled by
/// motion is never moved. [CivicPage] and [CivicSheetPage] build on it; an
/// app pushes it as it would any route.
///
/// ```dart
/// Navigator.of(context).push(
///   CivicPageRoute<void>(builder: (context) => const PermitPage()),
/// )
/// ```
///
/// On iOS a page also pops with a swipe from the screen's leading edge, as
/// every iOS page does ([SwipeBackPageTransitionsBuilder]): the page
/// follows the finger while it drags; a full-screen task takes no swipe.
///
/// A place switched in the app's frame (a tab, the side navigation) is no
/// page change: it changes at once, in place.
class CivicPageRoute<T> extends PageRoute<T> {
  /// A route to [builder]'s page.
  CivicPageRoute({
    required this.builder,
    super.settings,
    super.fullscreenDialog,
    this.maintainState = true,
  });

  /// Builds the page.
  final WidgetBuilder builder;

  @override
  final bool maintainState;

  /// How long a page takes to come in.
  static const Duration forward = Duration(milliseconds: 240);

  /// How long a page takes to go.
  static const Duration reverse = Duration(milliseconds: 200);

  @override
  Duration get transitionDuration => forward;

  @override
  Duration get reverseTransitionDuration => reverse;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => Semantics(
    scopesRoute: true,
    explicitChildNodes: true,
    child: ColoredBox(
      color: context.civicTheme.background,
      child: builder(context),
    ),
  );

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => defaultTargetPlatform == TargetPlatform.iOS
      ? const SwipeBackPageTransitionsBuilder(
          CivicPageTransitions(),
        ).buildTransitions(this, context, animation, secondaryAnimation, child)
      : _civicPageChange(context, animation, child);
}

// The ground covers the page left over the first third; the words come in
// over the rest. Driven tweens, not curved animations: nothing to dispose
// when the change is rebuilt.
final Animatable<double> _cover = CurveTween(curve: const Interval(0, 1 / 3));
final Animatable<double> _words = CurveTween(
  curve: const Interval(1 / 3, 1, curve: Curves.easeOut),
);

// Civic's page change over [animation]: the ground, then the words.
Widget _civicPageChange(
  BuildContext context,
  Animation<double> animation,
  Widget child,
) => Stack(
  fit: StackFit.expand,
  children: [
    FadeTransition(
      opacity: animation.drive(_cover),
      child: ColoredBox(color: context.civicTheme.background),
    ),
    FadeTransition(opacity: animation.drive(_words), child: child),
  ],
);

/// Civic's page change on every platform, for the `pageTransitionsTheme` of
/// the app's own Material theme, Flutter's or material_ui's: one map of
/// widgets-level builders fits both. An app on Flutter's `MaterialApp`
/// pushes Flutter's `MaterialPageRoute`, which reads only the app's theme
/// (on a Mac it would play the Cupertino slide), so the app puts it there.
/// On iOS the change keeps the swipe back from the screen's leading edge
/// round it ([SwipeBackPageTransitionsBuilder]).
///
/// ```dart
/// MaterialApp(
///   theme: ThemeData(
///     pageTransitionsTheme: const PageTransitionsTheme(
///       builders: civicPageTransitions,
///     ),
///   ),
///   builder: (context, child) => CivicTheme(data: theme, child: child!),
///   home: const PermitsHome(),
/// )
/// ```
const Map<TargetPlatform, PageTransitionsBuilder> civicPageTransitions = {
  TargetPlatform.android: CivicPageTransitions(),
  TargetPlatform.fuchsia: CivicPageTransitions(),
  // iOS's swipe back from the screen's edge, round Civic's page change.
  TargetPlatform.iOS: SwipeBackPageTransitionsBuilder(CivicPageTransitions()),
  TargetPlatform.linux: CivicPageTransitions(),
  TargetPlatform.macOS: CivicPageTransitions(),
  TargetPlatform.windows: CivicPageTransitions(),
};

/// Civic's page change as a widgets-level [PageTransitionsBuilder], so a
/// plain Material route changes as a [CivicPageRoute] does
/// ([civicPageTransitions] puts it on every platform). [CivicHost] puts
/// [civicPageTransitions] in the Material theme it builds.
class CivicPageTransitions extends PageTransitionsBuilder {
  /// Civic's page change.
  const CivicPageTransitions();

  @override
  Duration get transitionDuration => CivicPageRoute.forward;

  @override
  Duration get reverseTransitionDuration => CivicPageRoute.reverse;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => _civicPageChange(context, animation, child);
}

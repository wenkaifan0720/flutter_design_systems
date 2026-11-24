import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show Icons;
import 'package:ui_core/ui_core.dart';

import 'button.dart';

/// The design's push: the new page fades in as it rises 8 px into place, and
/// only fades under Reduce Motion.
class TendPageTransitionsBuilder extends PageTransitionsBuilder {
  /// The design's push.
  const TendPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // A driven animation, not a CurvedAnimation: nothing to dispose.
    final eased = animation.drive(CurveTween(curve: Curves.easeOutCubic));
    final faded = FadeTransition(opacity: eased, child: child);
    if (rawReduceMotionOf(context)) return faded;
    return AnimatedBuilder(
      animation: eased,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, 8 * (1 - eased.value)),
        child: child,
      ),
      child: faded,
    );
  }
}

/// The design's push on every platform, for an app's
/// `PageTransitionsTheme(builders: tendPageTransitions)`. On iOS it keeps
/// the swipe back from the screen's leading edge. An app that builds its
/// own pages takes [TendPage] instead.
const Map<TargetPlatform, PageTransitionsBuilder> tendPageTransitions = {
  TargetPlatform.android: TendPageTransitionsBuilder(),
  TargetPlatform.iOS: SwipeBackPageTransitionsBuilder(
    TendPageTransitionsBuilder(),
  ),
  TargetPlatform.macOS: TendPageTransitionsBuilder(),
  TargetPlatform.windows: TendPageTransitionsBuilder(),
  TargetPlatform.linux: TendPageTransitionsBuilder(),
  TargetPlatform.fuchsia: TendPageTransitionsBuilder(),
};

/// A page of the design's screens, for an app that builds its own routes or
/// its router's pages (a go_router `pageBuilder`): the design's push, the
/// swipe back on iOS and a fade under Reduce Motion, from ui_core's
/// [RawPage].
///
/// ```dart
/// Navigator(
///   pages: const [TendPage<void>(child: InboxScreen()), TendPage<void>(child: ThreadScreen())],
///   onDidRemovePage: (page) {},
/// )
/// ```
class TendPage<T> extends RawPage<T> {
  /// A page showing [child], raised as a sheet when [fullscreenDialog].
  const TendPage({
    required super.child,
    super.fullscreenDialog,
    super.key,
    super.name,
    super.arguments,
  }) : super(transitionsBuilder: const TendPageTransitionsBuilder());
}

/// A route to one of the app's screens for `Navigator.push`: the design's
/// push, the swipe back on iOS and a fade under Reduce Motion, from ui_core's
/// [RawPageRoute]. A [fullscreenDialog] route stands as a sheet: its bar
/// shows close, not back.
class TendPageRoute<T> extends RawPageRoute<T> {
  /// A route to the screen [builder] builds.
  TendPageRoute({
    required super.builder,
    super.fullscreenDialog,
    super.settings,
  }) : super(transitionsBuilder: const TendPageTransitionsBuilder());
}

/// The key a screen's bar shows to leave it: back on a pushed page, close
/// on a sheet, nothing on a root, named in the app's language. The route
/// says where the screen stands ([RoutePresentation.of]); the page never
/// decides it.
class TendDismissKey extends StatelessWidget {
  /// The dismiss key of the screen it stands in.
  const TendDismissKey({super.key});

  @override
  Widget build(BuildContext context) {
    final at = RoutePresentation.of(context);
    final label = at.dismissLabel(context);
    if (label == null) return const SizedBox.shrink();
    return TendIconButton(
      icon: at == RoutePresentation.sheet ? Icons.close : Icons.arrow_back,
      semanticLabel: label,
      onPressed: () => Navigator.maybePop(context),
    );
  }
}

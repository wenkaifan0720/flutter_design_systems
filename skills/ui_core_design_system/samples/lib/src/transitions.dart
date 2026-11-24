import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show Icons;
import 'package:ui_core/ui_core.dart';

import 'button.dart';

/// The look's push: the new page fades in as it rises 8 px into place, and
/// only fades under Reduce Motion.
class LookPageTransitionsBuilder extends PageTransitionsBuilder {
  /// The look's push.
  const LookPageTransitionsBuilder();

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

/// The look's push on every platform, for an app's
/// `PageTransitionsTheme(builders: lookPageTransitions)`. On iOS it keeps
/// the swipe back from the screen's leading edge. An app that builds its
/// own pages takes [LookPage] instead.
const Map<TargetPlatform, PageTransitionsBuilder> lookPageTransitions = {
  TargetPlatform.android: LookPageTransitionsBuilder(),
  TargetPlatform.iOS: SwipeBackPageTransitionsBuilder(
    LookPageTransitionsBuilder(),
  ),
  TargetPlatform.macOS: LookPageTransitionsBuilder(),
  TargetPlatform.windows: LookPageTransitionsBuilder(),
  TargetPlatform.linux: LookPageTransitionsBuilder(),
  TargetPlatform.fuchsia: LookPageTransitionsBuilder(),
};

/// A page of the look's screens, for an app that builds its own routes or
/// its router's pages (a go_router `pageBuilder`): the look's push, the
/// swipe back on iOS and a fade under Reduce Motion, from ui_core's
/// [RawPage].
///
/// ```dart
/// Navigator(
///   pages: const [LookPage<void>(child: InboxScreen()), LookPage<void>(child: ThreadScreen())],
///   onDidRemovePage: (page) {},
/// )
/// ```
class LookPage<T> extends RawPage<T> {
  /// A page showing [child], raised as a sheet when [fullscreenDialog].
  const LookPage({
    required super.child,
    super.fullscreenDialog,
    super.key,
    super.name,
    super.arguments,
  }) : super(transitionsBuilder: const LookPageTransitionsBuilder());
}

/// The key a screen's bar shows to leave it: back on a pushed page, close
/// on a sheet, nothing on a root, named in the app's language. The route
/// says where the screen stands ([RoutePresentation.of]); the page never
/// decides it.
class LookDismissKey extends StatelessWidget {
  /// The dismiss key of the screen it stands in.
  const LookDismissKey({super.key});

  @override
  Widget build(BuildContext context) {
    final at = RoutePresentation.of(context);
    final label = at.dismissLabel(context);
    if (label == null) return const SizedBox.shrink();
    return LookIconButton(
      icon: at == RoutePresentation.sheet ? Icons.close : Icons.arrow_back,
      semanticLabel: label,
      onPressed: () => Navigator.maybePop(context),
    );
  }
}

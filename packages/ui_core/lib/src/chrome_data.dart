/// What a design system's chrome is drawn from, with no router: the data the
/// runtime hands a shell ([NavTab], [ShellAction]); the platform chrome
/// is drawn for and how its route is presented ([PreviewPlatform],
/// [RoutePresentation]); the ground a page stands on ([ChromeGround]); and
/// the bottom inset a bar asks its pages to keep clear ([ShellInsets]).
///
/// The runtime's chrome contract and its go_router glue export all of it.
/// This file imports only the widgets layer, so a look's package stands on
/// it without taking a router.
library;

import 'package:flutter/widgets.dart';

/// One tab of the shell's navigation: a branch's root, with the glyph and
/// the words it wears. The runtime emits one per `StatefulShellBranch`, in
/// branch order; the system decides how it looks.
@immutable
class NavTab {
  /// Creates a [NavTab].
  const NavTab({
    required this.icon,
    required this.label,
    required this.location,
    this.selectedIcon,
    this.key,
    this.ground = ChromeGround.surface,
  });

  /// The glyph the tab wears.
  final IconData icon;

  /// The glyph the tab wears while its branch is selected; null wears
  /// [icon] in the system's selected treatment.
  final IconData? selectedIcon;

  /// The tab's name — printed or announced, as the system draws tabs.
  final String label;

  /// The location of the branch's root page, e.g. `/today`.
  final String location;

  /// The walkthrough key of the step that selects this tab, set on the
  /// tab's hit target; null when no declared step taps it.
  final Key? key;

  /// The ground the branch's root stands on. It paints the BAR only, while
  /// this tab is selected; the root page publishes its own
  /// [ChromeGroundScope] (`ChromeRoutes.page(..., ground:)` in the branch
  /// root's builder), never a scope above the branch container, which would
  /// restyle the offstage branches too.
  final ChromeGround ground;
}

/// The app-level act beside the shell's tabs: the one thing reachable from
/// every root — add, compose, capture — with the glyph it wears and what it
/// does. A system draws it in its own way (a floating action button, a
/// disc in the bar, a square at its end).
@immutable
class ShellAction {
  /// Creates a [ShellAction].
  const ShellAction({
    required this.icon,
    required this.onPressed,
    this.label,
    this.accent = false,
    this.key,
  });

  /// The glyph the act wears.
  final IconData icon;

  /// The act: the declared step's write and the route it lands on, run with
  /// a context under the router.
  final void Function(BuildContext context) onPressed;

  /// What the act does, announced for an icon-only control; a system may
  /// also print it (an extended action). Null announces nothing beyond the
  /// system's default.
  final String? label;

  /// Whether the act is the app's standing invitation, drawn in the
  /// system's accent rather than its quieter default.
  final bool accent;

  /// The walkthrough key of the declared step the act performs, set on the
  /// act's hit target.
  final Key? key;
}

/// The platform a preview is drawn for: its device size and the platform
/// whose behaviour applies inside it. The look is the system's everywhere;
/// behaviour (scroll physics, back gestures, text handling) follows this
/// platform.
enum PreviewPlatform {
  /// An Android phone: a preview's default.
  android,

  /// An iPhone.
  ios;

  /// The framework's name for this platform.
  TargetPlatform get targetPlatform => switch (this) {
    android => TargetPlatform.android,
    ios => TargetPlatform.iOS,
  };
}

/// How a route is presented, which is what a screen derives its bar from:
/// the title on a [root], the back affordance on a [pushed] page, the
/// dismiss affordance on a [sheet]. A page never authors its own back or
/// close; it reads its presentation ([of]).
enum RoutePresentation {
  /// A route nothing sits beneath in its navigator: a shell branch's root,
  /// or an app's first page.
  root,

  /// A route pushed over another.
  pushed,

  /// A route raised as a sheet or a full-screen cover.
  sheet;

  /// The presentation in force at [context]: the one a
  /// [RoutePresentationScope] publishes (a sheet page publishes [sheet]), else the route's own
  /// position — [pushed] when the route implies a dismissal (a route stands
  /// below it in its navigator), [root] otherwise, and [root] outside any
  /// route.
  ///
  /// Asked of the route, never of the navigator's `canPop`: a sheet raised
  /// over a root on the same navigator makes `canPop` true for the root
  /// too, which would give the root a back affordance under the sheet.
  static RoutePresentation of(BuildContext context) {
    final published = RoutePresentationScope.maybeOf(context);
    if (published != null) return published;
    final route = ModalRoute.of(context);
    return (route?.impliesAppBarDismissal ?? false) ? pushed : root;
  }
}

/// Publishes the [RoutePresentation] of the route it stands in, overriding
/// what the route's position implies. A system's sheet page wraps its child
/// in one with [RoutePresentation.sheet]; a preview or a hand-built
/// navigator may publish any presentation.
class RoutePresentationScope extends InheritedWidget {
  /// Creates a [RoutePresentationScope].
  const RoutePresentationScope({
    required this.presentation,
    required super.child,
    super.key,
  });

  /// How the route is presented.
  final RoutePresentation presentation;

  /// The nearest published presentation, or null when none is.
  static RoutePresentation? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<RoutePresentationScope>()
      ?.presentation;

  @override
  bool updateShouldNotify(RoutePresentationScope oldWidget) =>
      presentation != oldWidget.presentation;
}

/// The ground a page stands on, which is what its chrome is drawn against:
/// the system's own [surface], or [media] — a full-bleed feed of video or
/// photographs, over which the chrome is dark and solid.
///
/// On media every system draws its bar as an opaque near-black surface from
/// its own dark tokens, with light icons and a light status bar, and blurs
/// nothing (over solid black a frost buys nothing, and a filter over a live
/// video texture costs every frame). A page's body ends at the bar's top.
/// A pushed media page (a full-screen player) has no bar; its top bar
/// stands over the media and keeps a legible back affordance.
///
/// Independent of [RoutePresentation]: a root, a pushed page and a sheet may
/// each stand on media.
enum ChromeGround {
  /// The system's own surface: every page's default.
  surface,

  /// A full-bleed media feed.
  media;

  /// The ground published at [context] ([ChromeGroundScope]), [surface]
  /// when none is.
  static ChromeGround of(BuildContext context) =>
      ChromeGroundScope.maybeOf(context) ?? surface;
}

/// Publishes the [ChromeGround] of the page it wraps. `ChromeRoutes.page`
/// mounts one inside a pushed page and inside a branch root (from its
/// [NavTab.ground]); a system's chrome inside the page reads it.
class ChromeGroundScope extends InheritedWidget {
  /// Creates a [ChromeGroundScope].
  const ChromeGroundScope({
    required this.ground,
    required super.child,
    super.key,
  });

  /// The ground the page stands on.
  final ChromeGround ground;

  /// The nearest published ground, or null when none is.
  static ChromeGround? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ChromeGroundScope>()?.ground;

  @override
  bool updateShouldNotify(ChromeGroundScope oldWidget) =>
      ground != oldWidget.ground;
}

/// The bottom inset the shell's bar asks every branch root to keep clear:
/// published by a system's shell over its branch container (and by a
/// preview that stands the bar under a lone page), spent by the system's
/// screen on its scroll padding and by its toast on its inset.
class ShellInsets extends InheritedWidget {
  /// Creates a [ShellInsets].
  const ShellInsets({
    required this.bottomInset,
    required super.child,
    super.key,
  });

  /// The height above the screen's bottom edge a page keeps clear, as the
  /// system measures it (its bar, any accessory, any bottom inset it
  /// covers).
  final double bottomInset;

  /// The bottom inset [context]'s page keeps clear: the published one on a
  /// root, 0 outside any shell and on any route that is not first in its
  /// navigator — a pushed page, where the bar has yielded, or a sheet,
  /// which covers it.
  static double of(BuildContext context) =>
      ModalRoute.of(context)?.isFirst == false
      ? 0
      : context
                .dependOnInheritedWidgetOfExactType<ShellInsets>()
                ?.bottomInset ??
            0.0;

  @override
  bool updateShouldNotify(ShellInsets oldWidget) =>
      bottomInset != oldWidget.bottomInset;
}

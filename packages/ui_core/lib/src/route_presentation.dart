/// Where a screen stands, which is what its top bar is drawn from: at the
/// root of its navigator, pushed over another page, or raised as a sheet
/// ([RoutePresentation]), and the words its back or close control says.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'localizations.dart';

/// How a route is presented, which is what a screen derives its bar from:
/// the title on a [root], the back affordance on a [pushed] page, the
/// dismiss affordance on a [sheet]. A page never authors its own back or
/// close; it reads its presentation ([of]) and the words its dismiss control
/// says ([dismissLabel]).
///
/// A look's top bar, its back or close key labelled in the app's language:
///
/// ```dart
/// Builder(
///   builder: (context) {
///     final at = RoutePresentation.of(context);
///     final label = at.dismissLabel(context);
///     if (label == null) return const SizedBox.shrink();
///     return Semantics(
///       button: true,
///       label: label,
///       onTap: () => Navigator.maybePop(context),
///       child: Text(at == RoutePresentation.sheet ? '×' : '‹'),
///     );
///   },
/// )
/// ```
enum RoutePresentation {
  /// A route nothing sits beneath in its navigator: a shell branch's root,
  /// or an app's first page.
  root,

  /// A route pushed over another.
  pushed,

  /// A route raised as a sheet or a full-screen cover.
  sheet;

  /// The presentation in force at [context]: the one a
  /// [RoutePresentationScope] publishes, else the route's own. A route that
  /// implies no dismissal (nothing stands below it in its navigator) is a
  /// [root], as is [context] outside any route. One that does is a [sheet]
  /// when it is raised over the page, as a popup (a bottom or side sheet, a
  /// dialog) or a full-screen dialog page, whose bar closes it as Material's
  /// `AppBar` does; else it is [pushed].
  ///
  /// Asked of the route, never of the navigator's `canPop`: a sheet raised
  /// over a root on the same navigator makes `canPop` true for the root
  /// too, which would give the root a back affordance under the sheet.
  ///
  /// ```dart
  /// RoutePresentation.of(context)
  /// ```
  static RoutePresentation of(BuildContext context) {
    final published = RoutePresentationScope.maybeOf(context);
    if (published != null) return published;
    final route = ModalRoute.of(context);
    if (route == null || !route.impliesAppBarDismissal) return root;
    final raised =
        route is PopupRoute || (route is PageRoute && route.fullscreenDialog);
    return raised ? sheet : pushed;
  }

  /// What the dismiss control of a screen presented so says, in the app's
  /// language ([RawWidgetsLocalizations]): none on a [root], which has no
  /// dismiss control; [RawWidgetsLocalizations.backButtonTooltip] on a
  /// [pushed] page; [RawWidgetsLocalizations.closeButtonLabel] on a [sheet].
  ///
  /// ```dart
  /// RoutePresentation.of(context).dismissLabel(context)
  /// ```
  String? dismissLabel(BuildContext context) => switch (this) {
    root => null,
    pushed => RawWidgetsLocalizations.of(context).backButtonTooltip,
    sheet => RawWidgetsLocalizations.of(context).closeButtonLabel,
  };
}

/// Publishes the [RoutePresentation] of the route it stands in, overriding
/// what the route's position implies. A page that is a sheet but no popup or
/// full-screen dialog (a look's own sheet page) wraps its child in one with
/// [RoutePresentation.sheet]; a preview or a hand-built navigator may
/// publish any presentation.
///
/// ```dart
/// const RoutePresentationScope(presentation: RoutePresentation.sheet, child: Text('Share'))
/// ```
class RoutePresentationScope extends InheritedWidget {
  /// Publishes [presentation] for [child].
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      EnumProperty<RoutePresentation>('presentation', presentation),
    );
  }
}

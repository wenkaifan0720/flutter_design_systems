import 'package:material_ui/material_ui.dart' show MaterialRouteTransitionMixin;
import 'package:flutter/widgets.dart';

import '../internal/layer.dart';

/// The go_router [Page] for a route pushed off a root: on Material's page
/// transitions, so the push runs the platform's own transition (the host
/// never pins a platform), standing on the ground (on the desktop, the content
/// layer the shell stands its pages on).
///
/// Its chrome is derived, never authored: a [Fluent2Scaffold] inside reads
/// the route's register and draws the way back. Build one through
/// `ChromeRoutes.page(fluent2Chrome, ...)`, which keys it and, on a media
/// ground, stands it in the dark tokens under a light status bar.
///
/// ```dart
/// Fluent2Page<void>(child: const FilePage())
/// ```
class Fluent2Page<T> extends Page<T> {
  /// A page that builds [child].
  const Fluent2Page({required this.child, super.key, super.name});

  /// The page's content.
  final Widget child;

  @override
  Route<T> createRoute(BuildContext context) => _Fluent2PageRoute<T>(this);
}

/// [Fluent2Page]'s route: Material's page route, read from the page each
/// time the navigator updates it, its content on the ground.
class _Fluent2PageRoute<T> extends PageRoute<T>
    with MaterialRouteTransitionMixin<T> {
  _Fluent2PageRoute(Fluent2Page<T> page) : super(settings: page);

  Fluent2Page<T> get _page => settings as Fluent2Page<T>;

  @override
  Widget buildContent(BuildContext context) =>
      ColoredBox(color: Fluent2Layer.groundOf(context), child: _page.child);

  @override
  bool get maintainState => true;

  @override
  String get debugLabel => '${super.debugLabel}(${_page.name})';
}

import 'package:material_ui/material_ui.dart' show MaterialRouteTransitionMixin;
import 'package:flutter/widgets.dart';

import '../theme.dart';

/// The go_router [Page] for a route pushed off a root: its route runs the
/// platform's own transition (the host never pins a platform), standing on
/// the theme's ground.
///
/// Its chrome is derived, never authored: an [LedgerScreen] inside reads the
/// route's register and draws the round back button. Build one through
/// `ChromeRoutes.page(ledgerChrome, ...)`, which keys it and, on a media
/// ground, stands it in the dark tokens under a light status bar.
///
/// ```dart
/// LedgerPage<void>(name: 'account', child: const AccountPage())
/// ```
class LedgerPage<T> extends Page<T> {
  /// The page for a pushed route of [child].
  const LedgerPage({required this.child, super.key, super.name});

  /// The page's content.
  final Widget child;

  @override
  Route<T> createRoute(BuildContext context) => _LedgerPageRoute<T>(this);
}

/// The route of a [LedgerPage]: the platform's page transition, its content
/// on the theme's ground, rebuilt from the page whenever the page changes.
class _LedgerPageRoute<T> extends PageRoute<T>
    with MaterialRouteTransitionMixin<T> {
  _LedgerPageRoute(LedgerPage<T> page) : super(settings: page);

  LedgerPage<T> get _page => settings as LedgerPage<T>;

  @override
  Widget buildContent(BuildContext context) =>
      ColoredBox(color: context.ledgerTheme.background, child: _page.child);

  @override
  bool get maintainState => true;

  @override
  String get debugLabel => '${super.debugLabel}(${_page.name})';
}

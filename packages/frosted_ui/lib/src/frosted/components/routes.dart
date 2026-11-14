import 'package:material_ui/material_ui.dart' show MaterialRouteTransitionMixin;
import 'package:flutter/widgets.dart';

import '../theme.dart';

/// The [Page] for a route pushed off a root: it runs the platform's own
/// push transition (the host never pins a platform) and stands [child] on
/// the theme's ground.
///
/// Its chrome is derived, never authored: an [FrostedScaffold] inside reads the
/// route's register and draws the glass back button. A router's page builder
/// returns one, keyed by its route; on a media ground the host stands it in
/// the dark tokens under a light status bar.
///
/// ```dart
/// Navigator(pages: [FrostedPage<void>(name: 'account', child: AccountPage())], onDidRemovePage: (page) {})
/// ```
class FrostedPage<T> extends Page<T> {
  /// Creates a [FrostedPage].
  const FrostedPage({
    required this.child,
    this.maintainState = true,
    this.fullscreenDialog = false,
    super.key,
    super.name,
  });

  /// The page's content, under its scaffold.
  final Widget child;

  /// Whether the route keeps its state while another covers it.
  final bool maintainState;

  /// Whether the route is a full-screen dialog: on iOS it rises from the
  /// bottom and its way back is a close.
  final bool fullscreenDialog;

  @override
  Route<T> createRoute(BuildContext context) => _FrostedPageRoute<T>(this);
}

// A route that reads its page on every build, so a page updated in place
// (same key, new child) shows its new content.
class _FrostedPageRoute<T> extends PageRoute<T>
    with MaterialRouteTransitionMixin<T> {
  _FrostedPageRoute(FrostedPage<T> page) : super(settings: page);

  FrostedPage<T> get _page => settings as FrostedPage<T>;

  @override
  Widget buildContent(BuildContext context) => ColoredBox(
    color: context.frostedTheme.colorScheme.background,
    child: _page.child,
  );

  @override
  bool get maintainState => _page.maintainState;

  @override
  bool get fullscreenDialog => _page.fullscreenDialog;

  @override
  String get debugLabel => '${super.debugLabel}(${_page.name})';
}

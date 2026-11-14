import 'package:material_ui/material_ui.dart';

import '../ground.dart';
import 'sheet.dart';

/// The go_router [Page] for a route pushed off a root: a page route that
/// runs the page transition the host's theme installs (Minimal's push under
/// [MinimalHost]), as Material's own page does.
///
/// A page on [MinimalGround.media] (a feed root whose tab is
/// `MinimalNavItem.media`, a full-screen player pushed off one) stands in a
/// [MinimalGroundScope]: dark tokens and a light status bar. A surface page is
/// built as it is.
/// A go_router `pageBuilder` returns it with `key: state.pageKey`.
///
/// ```dart
/// MinimalPage<void>(key: const ValueKey('habit'), child: const HabitPage())
/// ```
class MinimalPage<T> extends Page<T> {
  /// A page showing [child].
  const MinimalPage({
    required this.child,
    this.ground = MinimalGround.surface,
    super.key,
    super.name,
  });

  /// The page's content.
  final Widget child;

  /// The ground the page stands on.
  final MinimalGround ground;

  @override
  Route<T> createRoute(BuildContext context) => _MinimalPageRoute<T>(this);
}

/// [MinimalPage]'s route: built from the page it currently carries, so a
/// page updated under the same key rebuilds in place.
class _MinimalPageRoute<T> extends PageRoute<T>
    with MaterialRouteTransitionMixin<T> {
  _MinimalPageRoute(MinimalPage<T> page) : super(settings: page);

  MinimalPage<T> get _page => settings as MinimalPage<T>;

  @override
  Widget buildContent(BuildContext context) =>
      _page.ground == MinimalGround.surface
      ? _page.child
      : MinimalGroundScope(ground: _page.ground, child: _page.child);

  @override
  bool get maintainState => true;

  @override
  String get debugLabel => '${super.debugLabel}(${_page.name})';
}

/// The go_router [Page] whose route is Minimal's page sheet: the modal
/// card (or, with `drawer: true`, the edge-attached drawer), created on the
/// root navigator so it rides above the shell's bar. In a wide window
/// ([MinimalBottomSheet.centresAt]) the card stands centred over the page
/// instead ([MinimalBottomSheet.centredRoute]); the drawer stays a drawer.
/// A go_router route on the root navigator (`parentNavigatorKey:`) returns
/// it from its `pageBuilder` with `key: state.pageKey`.
///
/// ```dart
/// MinimalSheetPage<void>(key: const ValueKey('new-habit'), child: const NewHabitPage())
/// ```
class MinimalSheetPage<T> extends Page<T> {
  /// A sheet route's page around [child].
  const MinimalSheetPage({
    required this.child,
    this.drawer = false,
    super.key,
    super.name,
  });

  /// The page: a [MinimalScaffold].
  final Widget child;

  /// Whether it is the full-width drawer, rather than the inset card.
  final bool drawer;

  @override
  Route<T> createRoute(BuildContext context) =>
      !drawer && MinimalBottomSheet.centresAt(MediaQuery.sizeOf(context).width)
      ? MinimalBottomSheet.centredRoute<T>(
          context: context,
          settings: this,
          builder: (_) => child,
        )
      : MinimalBottomSheet.pageRoute<T>(
          context: context,
          settings: this,
          floating: !drawer,
          builder: (_) => child,
        );
}

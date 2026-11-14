/// The go_router pages that raise a sheet: [ExpressiveSheetPage] (a modal
/// bottom sheet, or a full-screen dialog) and
/// [ExpressiveFullScreenDialogPage]. Part of the host layer: an app raises
/// a sheet from code with `showExpressiveBottomSheet`.
library;

import 'package:flutter/widgets.dart';

import '../component_themes.dart';
import '../theme.dart';
import 'sheet.dart' show expressiveSheetPageRoute;

/// The go_router [Page] for a route raised as a sheet: a modal bottom
/// sheet, or with [drawer] a full-screen dialog. The route names the root
/// navigator (`parentNavigatorKey`), so the sheet stands above the shell
/// and the bar under it does not move. The page publishes
/// [RoutePresentation.sheet], so the screen inside derives its dismiss
/// affordance; the sheet draws only its container, handle, scrim and
/// anchors.
///
/// The modal sheet rises to its partial anchor (half the screen, or its
/// own height when shorter) and is dragged between its anchors or away;
/// its own pop, a tap on the scrim and the system back close it (the
/// system back first settling an expanded sheet to its partial anchor).
/// The full-screen dialog has no scrim; its pop and the system back close
/// it.
class ExpressiveSheetPage<T> extends Page<T> {
  /// A page showing [child] as a sheet, or as a full-screen dialog when [drawer].
  const ExpressiveSheetPage({
    required this.child,
    this.drawer = false,
    this.skipPartiallyExpanded = false,
    this.theme,
    this.themeListenable,
    this.style,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  /// Stateful visual overrides for the modal bottom-sheet container.
  final ExpressiveComponentThemeData? style;

  /// The sheet's page.
  final Widget child;

  /// The theme the whole modal sheet wears — its container, handle and page
  /// — in place of the one around the navigator: a player tinted from the
  /// playing artwork (`ExpressiveArtwork`). The route builds the sheet with
  /// the navigator's themes, so a scope inside [child] would tint only the
  /// page, not the container under it. Called under the route whenever the
  /// sheet builds, with the navigator's theme ambient: a new page (the
  /// router's rebuild) and whatever it depends on rebuild it, and so does
  /// [themeListenable] (a scheme that springs between two artworks). Null
  /// keeps the navigator's theme. The full-screen dialog ignores it.
  final ExpressiveThemeData Function(BuildContext context)? theme;

  /// Rebuilds [theme] when it notifies.
  final Listenable? themeListenable;

  /// Whether the page is a full-screen dialog rather than a modal bottom
  /// sheet.
  final bool drawer;

  /// Whether the modal sheet skips its partial anchor and rises straight
  /// to its content's height.
  final bool skipPartiallyExpanded;

  @override
  Route<T> createRoute(BuildContext context) => expressiveSheetPageRoute<T>(
    context,
    this,
    drawer: drawer,
    skipPartiallyExpanded: skipPartiallyExpanded,
  );
}

/// The go_router [Page] for a full-screen dialog: a focused task that
/// covers the whole screen and is closed explicitly (its pop, the system
/// back). An [ExpressiveSheetPage] with `drawer: true`; the screen inside
/// draws its close and confirm actions.
class ExpressiveFullScreenDialogPage<T> extends ExpressiveSheetPage<T> {
  /// A full-screen dialog page showing [child].
  const ExpressiveFullScreenDialogPage({
    required super.child,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  }) : super(drawer: true);
}

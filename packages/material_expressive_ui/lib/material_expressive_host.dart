/// Material Expressive's host layer, for an app that shows the look's screens in a shell of its own: the scaffold every
/// look shares (`package:ui_core/host.dart`: its tabs, its main action, its background and insets, the
/// preview frame and platform) and Material Expressive's own part of it. An app that draws its screens from
/// `package:material_expressive_ui/material_expressive_ui.dart` does not need this library; the look's own chrome, example and tests import it
/// beside that one.
///
/// Outside semver: this library may change in any version, a patch included; the CHANGELOG says how to move.
///
/// {@canonicalFor artwork}
/// {@canonicalFor artwork.ExpressiveArtwork}
/// {@canonicalFor artwork.ExpressiveArtworkScheme}
/// {@canonicalFor chrome_metrics}
/// {@canonicalFor chrome_metrics.ExpressiveChromeMetrics}
/// {@canonicalFor host}
/// {@canonicalFor host.ExpressiveMediaGround}
/// {@canonicalFor page}
/// {@canonicalFor page.ExpressivePage}
/// {@canonicalFor page.ExpressivePageTransitionsBuilder}
/// {@canonicalFor page.ExpressivePredictiveBackRoute}
/// {@canonicalFor page.ExpressivePredictiveBackTransition}
/// {@canonicalFor page.predictiveBackGeometry}
/// {@canonicalFor preview}
/// {@canonicalFor preview.ExpressiveNavigationMode}
/// {@canonicalFor preview.ExpressivePreview}
/// {@canonicalFor sheet_page}
/// {@canonicalFor sheet_page.ExpressiveFullScreenDialogPage}
/// {@canonicalFor sheet_page.ExpressiveSheetPage}
/// {@canonicalFor shell_action}
/// {@canonicalFor shell_action.ExpressiveShellAction}
/// {@canonicalFor shell_insets}
/// {@canonicalFor shell_insets.ExpressiveShellInsets}
/// {@canonicalFor shell_scaffold}
/// {@canonicalFor shell_scaffold.ExpressiveShellScaffold}
/// {@canonicalFor inventory}
/// {@canonicalFor inventory.ExpressiveInventoryGallery}
/// {@canonicalFor inventory.expressiveInventory}
library;

export 'package:ui_core/host.dart';

export 'src/material_expressive/artwork.dart';
export 'src/material_expressive/chrome_metrics.dart';
export 'src/material_expressive/components/host.dart';
export 'src/material_expressive/components/page.dart';
export 'src/material_expressive/components/preview.dart';
export 'src/material_expressive/components/sheet_page.dart';
export 'src/material_expressive/components/shell_action.dart';
export 'src/material_expressive/components/shell_insets.dart';
export 'src/material_expressive/components/shell_scaffold.dart';
export 'src/material_expressive/inventory.dart';

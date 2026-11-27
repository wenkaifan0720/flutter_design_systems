/// Minimal's host layer, for an app that shows the look's screens in a shell of its own: the scaffold every
/// look shares (`package:ui_core/host.dart`: its tabs, its main action, its background and insets, the
/// preview frame and platform) and Minimal's own part of it. An app that draws its screens from
/// `package:minimal_ui/minimal_ui.dart` does not need this library; the look's own chrome, example and tests import it
/// beside that one.
///
/// Outside semver: this library may change in any version, a patch included; the CHANGELOG says how to move.
///
/// {@canonicalFor chrome_metrics}
/// {@canonicalFor chrome_metrics.MinimalChromeMetrics}
/// {@canonicalFor hit_target}
/// {@canonicalFor hit_target.MinimalHitTarget}
/// {@canonicalFor media_slots}
/// {@canonicalFor media_slots.MinimalMediaImage}
/// {@canonicalFor media_slots.MinimalMediaReference}
/// {@canonicalFor media_slots.MinimalMediaSource}
/// {@canonicalFor pages}
/// {@canonicalFor pages.MinimalPage}
/// {@canonicalFor pages.MinimalSheetPage}
/// {@canonicalFor preview}
/// {@canonicalFor preview.MinimalPresentation}
/// {@canonicalFor preview.MinimalPreview}
/// {@canonicalFor route_chrome}
/// {@canonicalFor route_chrome.MinimalRouteChrome}
/// {@canonicalFor shell_frame}
/// {@canonicalFor shell_frame.MinimalShellInsets}
/// {@canonicalFor ground}
/// {@canonicalFor ground.MinimalGround}
/// {@canonicalFor ground.MinimalGroundScope}
/// {@canonicalFor inventory}
/// {@canonicalFor inventory.MinimalInventoryGallery}
/// {@canonicalFor inventory.minimalInventory}
library;

export 'package:ui_core/host.dart';

export 'src/minimal/chrome_metrics.dart';
export 'src/minimal/components/hit_target.dart';
export 'src/minimal/components/media_slots.dart';
export 'src/minimal/components/pages.dart';
export 'src/minimal/components/preview.dart';
export 'src/minimal/components/route_chrome.dart';
export 'src/minimal/components/shell_frame.dart';
export 'src/minimal/ground.dart';
export 'src/minimal/inventory.dart';

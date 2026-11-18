/// Retro Desktop's host layer, for an app that shows the look's screens in a shell of its own: the scaffold every
/// look shares (`package:ui_core/host.dart`: its tabs, its main action, its background and insets, the
/// preview frame and platform) and Retro Desktop's own part of it. An app that draws its screens from
/// `package:retro_desktop_ui/retro_desktop_ui.dart` does not need this library; the look's own chrome, gallery and tests import it
/// beside that one.
///
/// Outside semver: this library may change in any version, a patch included; the CHANGELOG says how to move.
///
/// {@canonicalFor chrome_metrics}
/// {@canonicalFor chrome_metrics.RetroDesktopChromeMetrics}
/// {@canonicalFor host}
/// {@canonicalFor host.RetroDesktopChromeScope}
/// {@canonicalFor host.RetroDesktopHost}
/// {@canonicalFor host.RetroDesktopPage}
/// {@canonicalFor host.RetroDesktopPresentation}
/// {@canonicalFor host.RetroDesktopPreview}
/// {@canonicalFor host.RetroDesktopSheetPage}
/// {@canonicalFor host.RetroDesktopShellAction}
/// {@canonicalFor host.RetroDesktopUtility}
/// {@canonicalFor inventory}
/// {@canonicalFor inventory.RetroDesktopInventoryGallery}
/// {@canonicalFor inventory.retroDesktopInventory}
/// {@canonicalFor inventory.retroDesktopInventoryHeights}
library;

export 'package:ui_core/host.dart';

export 'src/retro_desktop/chrome_metrics.dart';
export 'src/retro_desktop/host.dart';
export 'src/retro_desktop/inventory.dart';

/// Frosted's host layer, for an app that shows the look's screens in a shell of its own: the scaffold every
/// look shares (`package:ui_core/host.dart`: its tabs, its main action, its background and insets, the
/// preview frame and platform) and Frosted's own part of it. An app that draws its screens from
/// `package:frosted_ui/frosted_ui.dart` does not need this library; the look's own chrome, example and tests import it
/// beside that one.
///
/// Outside semver: this library may change in any version, a patch included; the CHANGELOG says how to move.
///
/// {@canonicalFor chrome_metrics}
/// {@canonicalFor chrome_metrics.FrostedChromeMetrics}
/// {@canonicalFor account}
/// {@canonicalFor account.FrostedAccount}
/// {@canonicalFor account.FrostedAccountMarks}
/// {@canonicalFor account.FrostedAccountScope}
/// {@canonicalFor account.FrostedBell}
/// {@canonicalFor nav_bar}
/// {@canonicalFor nav_bar.FrostedNavAction}
/// {@canonicalFor nav_bar.FrostedNavItem}
/// {@canonicalFor nav_bar.FrostedNavigationBar}
/// {@canonicalFor preview}
/// {@canonicalFor preview.FrostedPresentation}
/// {@canonicalFor preview.FrostedPreview}
/// {@canonicalFor rail}
/// {@canonicalFor rail.FrostedNavigationRail}
/// {@canonicalFor sheet_page}
/// {@canonicalFor sheet_page.FrostedSheetPage}
/// {@canonicalFor side_bar}
/// {@canonicalFor side_bar.FrostedNavigationDrawer}
/// {@canonicalFor side_bar.FrostedSidebarAction}
/// {@canonicalFor inventory}
/// {@canonicalFor inventory.FrostedInventoryGallery}
/// {@canonicalFor inventory.frostedInventory}
library;

export 'package:ui_core/host.dart';

export 'src/frosted/chrome_metrics.dart';
export 'src/frosted/components/account.dart';
export 'src/frosted/components/nav_bar.dart';
export 'src/frosted/components/preview.dart';
export 'src/frosted/components/rail/rail.dart';
export 'src/frosted/components/sheet_page.dart';
export 'src/frosted/components/side_bar.dart';
export 'src/frosted/inventory.dart';

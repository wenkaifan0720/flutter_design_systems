/// Fluent 2's host layer, for an app that shows the look's screens in a shell of its own: the scaffold every
/// look shares (`package:ui_core/host.dart`: its tabs, its main action, its background and insets, the
/// preview frame and platform) and Fluent 2's own part of it. An app that draws its screens from
/// `package:fluent2_design_ui/fluent2_design_ui.dart` does not need this library; the look's own chrome, gallery and tests import it
/// beside that one.
///
/// Outside semver: this library may change in any version, a patch included; the CHANGELOG says how to move.
///
/// {@canonicalFor chrome_metrics}
/// {@canonicalFor chrome_metrics.Fluent2ChromeMetrics}
/// {@canonicalFor account}
/// {@canonicalFor account.Fluent2Account}
/// {@canonicalFor account.Fluent2AccountScope}
/// {@canonicalFor account.Fluent2Bell}
/// {@canonicalFor host}
/// {@canonicalFor host.Fluent2Host}
/// {@canonicalFor host.Fluent2MediaGround}
/// {@canonicalFor preview}
/// {@canonicalFor preview.Fluent2Presentation}
/// {@canonicalFor preview.Fluent2Preview}
/// {@canonicalFor routes}
/// {@canonicalFor routes.Fluent2Page}
/// {@canonicalFor sheet_page}
/// {@canonicalFor sheet_page.Fluent2SheetPage}
/// {@canonicalFor shell_frame}
/// {@canonicalFor shell_frame.Fluent2ShellAction}
/// {@canonicalFor shell_frame.Fluent2ShellInsets}
/// {@canonicalFor inventory}
/// {@canonicalFor inventory.Fluent2InventoryGallery}
/// {@canonicalFor inventory.fluent2Inventory}
/// {@canonicalFor inventory.fluent2InventoryHeights}
library;

export 'package:ui_core/host.dart';

export 'src/fluent2_design/chrome_metrics.dart';
export 'src/fluent2_design/components/account.dart';
export 'src/fluent2_design/components/host.dart';
export 'src/fluent2_design/components/preview.dart';
export 'src/fluent2_design/components/routes.dart';
export 'src/fluent2_design/components/sheet_page.dart';
export 'src/fluent2_design/components/shell_frame.dart';
export 'src/fluent2_design/inventory.dart';

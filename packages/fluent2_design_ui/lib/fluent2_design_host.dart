/// Fluent 2's host layer, for an app that shows the look's screens in a shell of its own: the scaffold every
/// look shares (`package:ui_core/host.dart`: its tabs, its main action, its background and insets, the
/// preview frame and platform) and Fluent 2's own part of it. An app that draws its screens from
/// `package:fluent2_design_ui/fluent2_design_ui.dart` does not need this library; the look's own chrome, gallery and tests import it
/// beside that one.
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

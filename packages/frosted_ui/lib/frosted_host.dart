/// Frosted's host layer, for an app that shows the look's screens in a shell of its own: the scaffold every
/// look shares (`package:ui_core/host.dart`: its tabs, its main action, its background and insets, the
/// preview frame and platform) and Frosted's own part of it. An app that draws its screens from
/// `package:frosted_ui/frosted_ui.dart` does not need this library; the look's own chrome, gallery and tests import it
/// beside that one.
library;

export 'package:ui_core/host.dart';

export 'src/frosted/chrome_metrics.dart';
export 'src/frosted/components/account.dart';
export 'src/frosted/components/host.dart';
export 'src/frosted/components/preview.dart';
export 'src/frosted/components/routes.dart';
export 'src/frosted/components/sheet_page.dart';
export 'src/frosted/inventory.dart';

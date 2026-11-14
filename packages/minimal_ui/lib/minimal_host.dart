/// Minimal's host layer, for an app that shows the look's screens in a shell of its own: the scaffold every
/// look shares (`package:ui_core/host.dart`: its tabs, its main action, its background and insets, the
/// preview frame and platform) and Minimal's own part of it. An app that draws its screens from
/// `package:minimal_ui/minimal_ui.dart` does not need this library; the look's own chrome, gallery and tests import it
/// beside that one.
library;

export 'package:ui_core/host.dart';

export 'src/minimal/chrome_metrics.dart';
export 'src/minimal/components/host.dart';
export 'src/minimal/components/media_slots.dart';
export 'src/minimal/components/pages.dart';
export 'src/minimal/components/preview.dart';
export 'src/minimal/components/route_chrome.dart';
export 'src/minimal/components/shell_frame.dart';
export 'src/minimal/ground.dart';
export 'src/minimal/inventory.dart';

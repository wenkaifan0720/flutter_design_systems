/// Comic's host layer, for an app that shows the look's screens in a shell of its own: the scaffold every
/// look shares (`package:ui_core/host.dart`: its tabs, its main action, its background and insets, the
/// preview frame and platform) and Comic's own part of it. An app that draws its screens from
/// `package:comic_ui/comic_ui.dart` does not need this library; the look's own chrome, gallery and tests import it
/// beside that one.
library;

export 'package:ui_core/host.dart';

export 'src/comic/chrome_metrics.dart';
export 'src/comic/host.dart';
export 'src/comic/inventory/registry.dart';

/// Clay's host layer, for an app that shows the look's screens in a shell of its own: the scaffold every
/// look shares (`package:ui_core/host.dart`: its tabs, its main action, its background and insets, the
/// preview frame and platform) and Clay's own part of it. An app that draws its screens from
/// `package:clay_ui/clay_ui.dart` does not need this library; the look's own chrome, gallery and tests import it
/// beside that one.
///
/// Outside semver: this library may change in any version, a patch included; the CHANGELOG says how to move.
library;

export 'package:ui_core/host.dart';

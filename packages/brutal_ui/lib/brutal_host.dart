/// Brutal's host layer, for an app that shows the look's screens in a shell of its own: the scaffold every
/// look shares (`package:ui_core/host.dart`: its tabs, its main action, its background and insets, the
/// preview frame and platform) and Brutal's own part of it. An app that draws its screens from
/// `package:brutal_ui/brutal_ui.dart` does not need this library; the look's own chrome, example and tests import it
/// beside that one.
///
/// Outside semver: this library may change in any version, a patch included; the CHANGELOG says how to move.
///
/// {@canonicalFor host}
/// {@canonicalFor host.BrutalPresentation}
/// {@canonicalFor host.BrutalPreview}
library;

export 'package:ui_core/host.dart';

export 'src/brutal/host.dart';

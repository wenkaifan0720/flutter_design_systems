/// Ledger's host layer, for an app that shows the look's screens in a shell of its own: the scaffold every
/// look shares (`package:ui_core/host.dart`: its tabs, its main action, its background and insets, the
/// preview frame and platform) and Ledger's own part of it. An app that draws its screens from
/// `package:ledger_ui/ledger_ui.dart` does not need this library; the look's own chrome, example and tests import it
/// beside that one.
///
/// Outside semver: this library may change in any version, a patch included; the CHANGELOG says how to move.
///
/// {@canonicalFor chrome_metrics}
/// {@canonicalFor chrome_metrics.LedgerChromeMetrics}
/// {@canonicalFor host}
/// {@canonicalFor host.LedgerHost}
/// {@canonicalFor host.LedgerMediaGround}
/// {@canonicalFor preview}
/// {@canonicalFor preview.LedgerPresentation}
/// {@canonicalFor preview.LedgerPreview}
/// {@canonicalFor routes}
/// {@canonicalFor routes.LedgerPage}
/// {@canonicalFor sheet_page}
/// {@canonicalFor sheet_page.LedgerSheetPage}
library;

export 'package:ui_core/host.dart';

export 'src/ledger/chrome_metrics.dart';
export 'src/ledger/components/host.dart';
export 'src/ledger/components/preview.dart';
export 'src/ledger/components/routes.dart';
export 'src/ledger/components/sheet_page.dart';

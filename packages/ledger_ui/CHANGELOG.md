## 0.1.0

- First release.
- The theme: `LedgerTheme` (the whole install, under a `MaterialApp`, a `CupertinoApp` or a `WidgetsApp`),
  `LedgerThemeData` with `copyWith` and `lerp`, five presets (quire, terracotta, indigo, verdigris, carbon) by day and
  by lamplight, `LedgerThemeData.from` for an app's own paper, ink and accent, `AnimatedLedgerTheme`, three densities
  (`LedgerDensity`) and the bundled faces (`ledgerLoadFonts`). The words a part says by itself come from ui_core's
  `DesignLocalizations`.
- The parts: buttons (`LedgerButton` with `.filled`, `.ink` and `.text`, `LedgerIconButton`), fields, selects,
  checkboxes, radios, switches, the segmented control, chips, the stepper and the date picker; ruled rows with their
  dot leaders, section heads on their rules, slips, receipts, the engraved figure, the mono amount, the seal and the
  charts; the top bar, the tab bar, the rail and the side bar (`LedgerNavigationFrame`), dialogs, sheets and toasts.
- `package:ledger_ui/ledger_parts.dart`: everything the components are drawn with, for a component copied into an app.

## 0.1.1

Needs ui_core 0.2.1.

- Reduce Motion on iOS calms Brutal too. Flutter puts iOS's Reduce Motion in dart:ui's
  `AccessibilityFeatures.reduceMotion`, not in `MediaQuery.disableAnimationsOf`, which was all Brutal read, so on an
  iPhone with Reduce Motion on, Brutal's colour changes, theme changes, arrows, tab and page-dot bars and loops still
  ran. Brutal now reads ui_core's `designReduceMotionOf`, which also covers Android's Remove animations and the web's
  `prefers-reduced-motion`. The spinner, the running progress bar and the skeleton stop looping, and when the setting
  changes while one runs, it stops or starts at once.
- A data table's counts under its pages were English whatever the app's language, with no plural form. Each now
  comes from the localizations with its number: the selection's from ui_core's `DesignLocalizations` ("1 item
  selected", "2 items selected"; was "2 selected"), translated in its 30 languages, and the rows' from the new
  `BrutalLocalizations` ("1 row", "2 rows"), English unless an app gives its own through a
  `LocalizationsDelegate<BrutalLocalizations>`.
- From ui_core 0.2.1: a menu or popover its anchor opened gives the focus back to the anchor as it closes, and Home and
  End in a list keep the row they reach in view.
- The tests run in tiers. `flutter test --exclude-tags goldens,sweep` is the everyday run and keeps a case of every
  matrix; `flutter test` runs every tier.

## 0.1.0

- First release. The theme (light and dark, three densities), the surface (the rule, the hard shadow, the press, the
  focus rule) and the everyday parts: `BrutalButton`, `BrutalIconButton`, `BrutalTextField`, `BrutalSelect`,
  `BrutalCheckbox`, `BrutalRadio`, `BrutalSwitch`, `BrutalSegmentedButton`, `BrutalStepper`, `BrutalListGroup`,
  `BrutalListTile`, `BrutalSectionHeader`, `BrutalBlock`, `BrutalTag`, `BrutalAppBar`, `BrutalTabBar`,
  `BrutalNavigationBar`, `BrutalNavigationRail`, `BrutalSideNavigation`, `BrutalScaffold`, `BrutalDialog`,
  `showBrutalBottomSheet` and `BrutalToaster`.
- The app frame: `BrutalHost` (the theme, the toaster and the paper above the navigator), `BrutalScreen` (a page's
  margins, column, bar, footer and keyboard), `BrutalPage` and `BrutalSheetPage`, `BrutalAppShell` with `BrutalTab`s and
  a `BrutalShellAction`, `BrutalLoadingState`, `BrutalErrorState`, `BrutalInput` and `BrutalPreview`.
- Buttons take their words first, as Flutter's text does: `BrutalButton('Save', onPressed: save)`.

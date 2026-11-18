## 0.1.0

- First release. The theme (light and dark, three densities, a brand factory that keeps words readable on its gel),
  the material (glazed faces raised, level and sunken under one light, the grained chrome bar, letterpressed words,
  the engraved line, the focus ring) and the everyday parts: `GlossButton`, `GlossIconButton`, `GlossTextField`,
  `GlossSelect`, `GlossCheckbox`, `GlossRadio`, `GlossSwitch`, `GlossSegmentedButton`, `GlossStepper`,
  `GlossSlider`, `GlossChip`, `GlossWell`, `GlossListTile`, `GlossSectionHeader`, `GlossCard`, `GlossTopBar`,
  `GlossTabBar`, `GlossNavigationBar`, `GlossNavigationRail`, `GlossSidebar`, `GlossScaffold`, `GlossDialog`,
  `showGlossSheet` and `GlossToaster`, and `glossPageTransitions`, the look's own page change.
- The app frame: `GlossHost` (the theme, the toaster and the porcelain above the navigator), `GlossScreen` (a page's
  margins, column, bar, footer and keyboard), `GlossPage` and `GlossSheetPage`, `GlossAppShell` with `GlossTab`s and a
  `GlossShellAction` (a gel bead in the chrome, never floating), `GlossLoadingState`, `GlossErrorState`, `GlossInput`
  and `GlossPreview`; `GlossTopBar.autoLeading` gives a pushed page its back glyph and a sheet its close.
- Counted words: `glossPlural` picks a phrase's form for a count in the reader's language (CLDR's rules for the 30
  languages ui_core speaks), and `glossPluralCategory` names the category.
- On ui_core 0.3.0, which runs the behaviour while Gloss paints: `GlossDialog` and `showGlossDialog` (focus on the
  safe key, Escape, an `isAlert` dialog read as an alert, keys stacking when they do not fit), `showGlossSheet`,
  `GlossSheetPage` and `showGlossActionSheet` (a sheet that follows the finger and settles or slides away),
  `showGlossSideSheet`, `GlossTabBar` (one tab stop, the arrows, Home and End), `GlossScaffold` and `GlossAppShell`
  from the rail up (the places one tab stop, F6 between them and the page; a phone's bar, which holds the act, stays
  Gloss's, and `showNavigation` hides it), `GlossWheelPicker` and `GlossTimePicker` (each drum one tab stop, typing jumps to a row),
  `GlossTooltip` (one at a time, Escape hides it), `GlossRating` (a drag sweeps, Home clears, a digit sets), the
  charts' axes (ui_core's scale), and `GlossSwipeRow` (closes as its list scrolls). `GlossCombobox` and
  `GlossTagInput` show a search on its way and a failed one with Try again, and take a `debounceDuration`.

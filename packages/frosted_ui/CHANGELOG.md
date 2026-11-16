## 0.2.0

Frosted 0.2.0 stands on ui_core 0.2.0.

- Fields, sheets and menus no longer crash in apps set to a language other than English; their built-in labels now
  follow the app's language. The theme brings the Material and Cupertino words its parts need when the app gives none
  (in every language Flutter translates, English for the rest), and a field's text menu says Cut, Copy and Paste in
  the app's language.
- The words every look shares (Cancel, Close, Today, ...) come from ui_core in 30 languages; `DesignLocalizations` is
  exported beside `FrostedLocalizations`. A pending transaction's note is a word of `FrostedLocalizations`
  (`pending`), so it is translated with the rest.
- Every control is a finger's target: 48 px under a finger and 44 px under a pointer, through ui_core's
  `DesignTapTarget`, so what a tap reaches, what a screen reader outlines and the layout agree. A field answers a tap
  anywhere on its well; a removable tag answers in its lane; the filter chips and a phone's tab strip run on under
  the screen's gutters and take taps there.
- Shadows are whole: a strip, a sheet or a swipe row no longer cuts the shadow of a chosen plate, a lifted card or an
  action; a swipe row clips only along its swipe.
- Large text: filter chips and segmented buttons grow with the reader's text size; a shared strip ends a word too
  long for its share in an ellipsis; a form row's control moves under its words when they have no room beside it.
- Spacing on a 2-point grid: the gaps and insets that sat at 3, 5, 11 or 13 now sit at 2, 4 or 12; the segmented
  control is 28 tall in a 32 strip, as iOS's.
- The tab bar stands on the page's margin with its chosen plate set in evenly; a list group's hairline is a rule over
  the row, not a box round it; the command palette dims and softens the page behind it as every raised slab does.
- Pages move in Frosted's own way on every platform, rather than the platform's: a page pushed over another clears in
  as it settles 24 px toward the end (300 ms), the page under it standing still, and goes back the way it came. A
  `FrostedPage` takes it, and so does every page route of an app on `material_ui`, the Material Frosted is built on;
  an app on Flutter's own `MaterialApp` puts `frostedPageTransitions` in its theme's `PageTransitionsTheme` (the
  README's set-up does), and its `MaterialPageRoute`s and go_router's pages match. A full-screen dialog rises 24 px
  instead, iOS keeps its drag from the edge to go back (ui_core's `DesignSwipeBackPageTransitionsBuilder` round
  Frosted's motion, in the map's iOS entry), and Reduce Motion makes it a cut. Switching tabs or sidebar
  destinations changes the page in place.
- By night a switch that is on shows a dark knob on its light track (it read as off or disabled), and a field, a code
  box or a well in error is edged in red rather than in a pale pink that read as focus; by day the error edge is a
  clearer red too. The empty state's light no longer stands in a pale box.
- Open lists show the chosen option at a glance. In a select's or a menu's list, and in the lists a combobox, a
  multi-select or a menu bar opens, the chosen row stands on the brighter chosen glass, as a chosen chip or tab does
  (it was a checkmark on the same quiet tint a hover used). A pointer over another row, or the keyboard holding one,
  lights it with the quieter tint, never the chosen glass, so neither reads as a second choice; a menu's rows now
  light under a pointer too. A multi-select's tags, typed words and hint start where every other field's words do
  (they stood 4 px further out).
- Every menu lights one row at a time: a select's or a menu's, a menu bar's and a split button's. A pointer moving
  over a row moves the lit row there and the keys go on from it (Return takes the pointer's row in a menu); a pointer
  resting on a row the keys left lights nothing. Opened by a pointer, a menu lights no row until the pointer or a key
  moves (a menu bar's or a split button's lit its first row); the first Down then lights the first row. The keyboard's
  ring stands inside its row, the menu's inset clear all round it and its corners concentric with the menu's (it stood
  4 px outside the row, about 2 px from the menu's edge).
- A select's and a menu's open list take the keyboard: opened by a key (Enter or Space, or an arrow on a select) the
  chosen option takes the focus, or the first when none is chosen; the arrows move at once (right after a pointer
  opened it too) and go round the ends, Home and End go to them, a typed letter jumps to the next option it starts,
  Enter or Space chooses and closes, and Escape closes and gives the field the focus back. A select tells a screen
  reader whether its list is open.
- A combobox's and a multi-select's lists take ui_core 0.2.0's keys: the arrows go round the ends, and on a closed
  list they open it without moving. A combobox opened before its words are edited lists every option with the chosen
  one held (it listed only that one); edited words narrow it. `isOptionEnabled` on `FrostedCombobox` and
  `FrostedMultiSelect` dims an option the arrows then pass over and neither a press nor Return takes, nor typing in a
  multi-select. Their pointer and keys hold one row: a pointer moving over a row lights it and the arrows go on from
  there, so the list never shows two lit rows. A long list opens with its chosen row in view and keeps the row the
  keys light in view; a combobox at the foot of the screen opens its list above it when there is more room there (it
  opened below with room for a row). In a menu bar's menu a typed letter goes to the next item it starts.
- In a browser, typing goes on after Return in a combobox, a multi-select and a command palette's search: Return
  takes the option, adds the tag or runs the command, and the field keeps the focus and takes the next letters (a
  multi-select's next tag needed a click, and the letters after Return went nowhere). `FrostedTextField` takes
  `onEditingComplete` for a field of your own that keeps the focus after Return, such as an "add another" field; use
  it in place of `onSubmitted`, never with it.
- Android's back closes what is open over a page before the page: a sheet, a dialog, a menu or a select's list, and
  now a popover, a split button's or a menu bar's menu (the focus back on its control) and a combobox's or a
  multi-select's list (the focus staying in the field).
- A tablet is no longer a stretched phone. From 600 wide (`FrostedBreakpoints.medium`, where Material's medium window
  class starts; `FrostedBreakpoints.isCompact` says a phone's) a sheet stands as the centred card it is on the
  desktop, and the tab bar hugs its tabs in the middle of the foot rather than spanning the window. A menu, a popover
  or a split button's menu opened by a key gives its first row the focus as it opens (its panel built nothing on its
  first frame).
- `FrostedTheme.of` gives the default theme when no `FrostedTheme` is above (as `Theme.of` does), so text selected on
  iOS under a host placed below `home:` no longer throws; `FrostedTheme.maybeOf` still gives null.
- Every public widget describes its fields in the inspector and in a failing test's tree, its defaults hidden; the
  parts that take a value in a range (sliders, a rating, page dots, pagination, a number field, a resizable split, a
  meter, a badge, a code field) assert it in debug builds.
- `FrostedStyle` is ui_core's `DesignStyle`, shared by every look; code that builds one changes nothing.
- Deprecated: `FrostedLocalizations`' `cut`, `copy`, `paste`, `lookUp`, `searchWeb`, `share` and `scanText`, which
  the text menu no longer reads; use `MaterialLocalizations`' button labels.
- Deprecated: `FrostedThemeData.copyWith`'s `shadows`, `glass`, `pearl` and `sheens`. A free shadow could make
  Frosted's soft lift a hard one, and an opaque or dark tint turned its glass into paint. Take them from a preset
  (`FrostedThemeData.preset`), or set `opaqueMaterials: true`, the solid form for high contrast. They still work until
  they are removed; no `dart fix` moves them, since no value stands in for them one for one.
- **Breaking** in debug builds: the ink act keeps its pill. A `FrostedButton` whose own `style:` gives it a shape that
  squares its ends fails an assert naming law 6 (the ink pill); a release build draws the pill. The theme's button
  shape (`FrostedComponentThemes.button`) still shapes every glass button and now passes the ink act by, so a theme
  of square buttons squares the glass ones only. To shape a button, shape a `FrostedButton.glass`.

## 0.1.1

- Filter chips (`FrostedFilterChipGroup`) no longer slide a chosen plate across the gaps between them: each chip
  carries its own chosen glass, which fades in where the chip stands while the chip left fades back. The segmented
  control, whose segments share one capsule, still slides.
- `FrostedSlider` shows the click cursor under a mouse, over its whole track and its thumb; while it is off, the
  cursor of what is under it.
- More parts show their cursor under a mouse: the click cursor on `FrostedNavigationBar`'s tabs, `FrostedNavAction`,
  `FrostedRangeSlider`'s track and `FrostedColorPicker`'s hue and opacity tracks (their thumbs keep the resize
  cursor); the open hand on `FrostedReorderableListView`'s grip, a `FrostedSwipeActions` row and a phone sheet's
  grabber.

## 0.1.0

- First release of Frosted as a package: light through frosted glass, by the names Material gives its components
  (`FrostedButton`, `FrostedTextField`, `FrostedSelect`, `FrostedAppBar`, `FrostedNavigationBar`,
  `FrostedNavigationDrawer`, `FrostedListTile`, `FrostedCheckbox`, `FrostedSwitch`, `FrostedSlider`,
  `FrostedSegmentedButton`, `FrostedTabBar`, `FrostedDialog`, `FrostedSnackBar`, ...), with `onPressed`,
  `value`/`onChanged` and `selectedIndex` throughout, from a phone to a desktop (menu bar, command palette, data
  table, tree view, resizable panes, hover card).
- `FrostedThemeData` shaped like Material's: `colorScheme`, `textTheme` (`displayLarge` to `labelSmall`, and the look's
  figures), `shadows`, and the look's own `glass`, `pearl`, `toast` and `hues`, each with `copyWith`; the theme has
  `copyWith`, `lerp` and value equality.
- `FrostedTheme` as an `InheritedTheme` and the whole install, in any app's `builder:` (Material, Cupertino or
  Widgets), with `darkData:` for the dark appearance; `AnimatedFrostedTheme`.
- Seven presets (opal, quartz, garnet, glacier, cobalt, jade, copper), each designed in light and dark, and
  `FrostedThemeData.from(accent:)` for a palette of your own that keeps 4.5:1 for words.
- `FrostedDensity` (standard, comfortable, compact), following the platform until set (compact on macOS, Windows and
  Linux); `FrostedTypeface` for your own faces; `components` for every part's theme; `style:` on the parts, a
  `FrostedStyle` with `ButtonStyle`'s slots.
- Tokens for your own parts: `FrostedCorners` (radii and the look's outlines), `FrostedSpacing`, `FrostedStrokes`,
  `FrostedMotion`.
- `FrostedGlyphs` (the glyphs the components draw, by meaning) and `FrostedLocalizations` (every word they say).
- Frosted's own text selection handles and context menu on every field; nothing of Material shows.
- Every control's target is 48 px under a finger and 44 px under a pointer; faces keep their size.
- `frostedLoadFonts`, to set the first frame in the bundled faces.
- No router: the package takes none.
- Bricolage Grotesque and DM Sans bundled (SIL OFL 1.1); icons from Lucide (ISC).

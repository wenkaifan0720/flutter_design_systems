## 0.3.1

- The time wheel names its hour, minute and day-period columns, and says AM and PM, in the reader's language: Frosted's own words when an app gives them, else ui_core's `DesignLocalizations` (it said Hour and Minute in English in every locale).
- Keyboard focus now lights the glass instead of ringing it: the rim goes bright, the frost brightens and a soft glow of light stands round the part. By day the glow is a clear tone of the theme's focus hue, never a dark slate line; by night a pale one. It meets 3:1 against the unfocused part on every preset, day and night, at 1x and 2x text. Rows in a list, a menu, a settings group (`FrostedValueRow`) and a form (`FrostedFormRow`) light from inside their edge, their plate reaching a little past the row into the group's inset, so the light never covers a row's words, its chevron or trailing button, its neighbours or its panel's edge. Focused fields and the search field light the same way.
- `FrostedFormField` keeps each control of a group in its own semantics node, under the field's label. Groups are a segmented button, radios, choices, a toggle or button group, filter chips, a number field, a colour or icon picker, or controls in a row, column or wrap. Previously a group was merged into one node, so with semantics on (a screen reader, or a web app with semantics enabled) every tap went to its first control. `mergeSemantics` is now `bool?`; null, the default, decides by the child. A group that names itself in the field's words, such as a segmented button labelled as its field, is announced once instead of twice.
- `FrostedNumberField` shows a plain number by default, with an optional `unit` after it (`unit: (n) => n == 1 ? 'person' : 'people'`), read with the figure. Set `money: true` for an amount with its currency sign. Each round goes out of use at its bound. `FrostedAmountField` takes a `sign` (null for none) and a `suffix`.
- `FrostedNumberField`'s minus and plus rounds are now as tall as the figure's well between them (64 at 100%, growing with the text), so the row stands at one height. They were 48 beside a 64 well. Where the row is too narrow for that (200% text on a phone), the rounds give way only as far as the well's three figures need, centred on it, never below 48, so the figure is never cut.
- Menus widen with the text size, up to the window's margins, and a long entry name wraps to a second line. At 200% on a phone, month names no longer truncate beside their amounts.
- A full-width button whose words wrap at large text keeps a line's room above and below them, so its first and last lines stay off the face's edge and its round ends.
- `FrostedButton.destructive` is glass tinted with the theme's danger hue. Its word holds 4.5:1 on the tint, day and night.
- A filled button out of use is now faint glass (the dimmed pane a glass button out of use shows) with its word over it in the quiet ink at full strength, not a dimmed ink pill whose word fell under 3:1.
- The calendar, the week strip and date marks show their days in the reader's digits (Arabic's ١٨), matching how they are read.
- Harbor Activity now searches merchants, categories, accounts, transaction status and amounts. The detail pane follows the selected filter and clears when there are no matches.
- Split a transaction into equal shares, with any leftover cents allocated exactly. Save or cancel a split and reopen it from the transaction. Get help opens assistance for the selected transaction. The monthly spending limit opens an editor and retains the saved amount.
- Tables keep file types and sizes legible at larger text sizes and inset their selection controls. At the reader's own text size a table keeps to its width (on a phone its checks give up their inset first); it scrolls sideways only once larger text would break its words. Weekday labels and dates scale together. Segmented choices stack when they outgrow a row, sign-in labels wrap, and swipe actions allow space for their full labels.
- Sliders and range sliders use a contrasting active track and thumb outline.
- The month menu keeps the chosen month in Arabic, and the gallery heading stays on one line at the phone’s 2× text setting.

## 0.3.0

Frosted 0.3.0 stands on ui_core 0.3.0: its dialog, sheets, tooltip, tab bar, wheels, number field and rating keep
their paint and take their behaviour from ui_core's parts, and it gains a context menu.

**Breaking**

- `FrostedNumberField` hands back a typed figure at each key only while it stands between `min` and `max`; one
  outside waits until it is taken (Return, or the focus leaving) and is clamped then: with a floor of 5, typing 12 no
  longer snaps to 5 at the 1. A round moves the value to the next multiple of `step` from `min`, so a round at 5 of a
  step of 10 lowers it to 0. A screen reader hears one field that steps up and down, not two buttons beside it.
- `FrostedRating` can be cleared: Home or 0 sets none, where the arrows stopped at one step.
- `FrostedTooltip` is a `StatelessWidget` and `FrostedTabBar` a `StatefulWidget`.
- In `package:frosted_ui/frosted_parts.dart`: `FrostedSoftDialogRoute` is a ui_core `DesignDialogRoute` (its page is
  `builder: WidgetBuilder`, not `pageBuilder`, and it has no `transitionDuration`); `FrostedSoftSideSheetRoute` has no
  `transitionDuration` (ui_core's side sheet moves on a spring); `FrostedSoftensBelow` is gone, the routes softening
  the page below through `frostedSoftBarrier`, their `barrierBuilder`.
- The checks Frosted's own tests ran from `ui_core` are in `ui_core_test` (a dev dependency).

**Moves**

- The dialog and the sheets open and close on a spring (ui_core's sheet spring, which settles in about a quarter of a
  second), from wherever they are when they turn; a sheet let go mid-drag carries the finger's speed. Under Reduce
  Motion the panel cuts in while the page below dims, rather than fading: glass under a fade reads clear.
- `showFrostedDialog` grows its card in over the page as `FrostedDialog.show` does, rather than fading it.

**Added**

- `FrostedContextMenu`: a menu of `DesignMenuEntry`s opened where the user asks for it, by a right click, a long
  press, Shift+F10 or the Menu key, its rows the menu bar's.
- `frostedShortcutLabel(context, activator)`: a shortcut written as Frosted's menus write it, "⇧⌘Z" on a Mac (each
  symbol its glyph) and "Ctrl+Shift+Z" elsewhere. The gallery's menus and palette write theirs with it.
- `FrostedCombobox` and `FrostedMultiSelect` say a `search` is loading, and say when it failed with a Try again row
  that Down reaches and Return runs; `debounceDuration` waits for typing to rest.
- `FrostedAmountField` takes `onEditingComplete`, `inputFormatters` and `keyboardType`; `FrostedSheet.raise` takes a
  `semanticLabel`, and `FrostedSheet.show` names its sheet by its title.
- In `package:frosted_ui/frosted_parts.dart`: `theme.dart` copied out of the package analyzes on its own. The baked
  token records (`FrostedTokens` and its parts) are a library of their own, and the theme's glass and control edge
  are drawn from its colours (`frostedMaterialsOf`, `frostedRestRingOn`), not from a theme of the package's.
  `frostedFocusInk` gives the ink focus is drawn in.

**Flutter 3.50**

- The example and the tests stand on `material_ui` and `cupertino_ui`, which Flutter 3.50 asks for in place of
  `package:flutter/material.dart` and `cupertino.dart`. The README's set-up starts an app on `material_ui`'s
  `MaterialApp`, whose page routes take Frosted's motion from `FrostedTheme` with no `ThemeData` of their own.
- `FrostedPreview`'s app stands in a semantics container of its own. The route under a nested app stands a modal
  barrier, which hides from a screen reader whatever painted before it in its container, and `material_ui`'s
  `MaterialApp` holds none of its own as Flutter's did: a heading above a preview left the page's semantics. The
  gallery's demo apps and Harbor's navigator stand in containers of their own too.
- `FrostedNavigationBar` stands on its fade into the canvas again, 104 up from the screen's foot, as the source's
  tab bar does: a card scrolling on under the glass dissolves into the canvas there, so its rim no longer runs beside
  the slab's sides on the same gutter and its rounded foot no longer frames the slab from under it. The inventory
  stands the bar on a stage of the canvas the fade's height, so the fade meets the canvas rather than drawing a box
  on the card.
- Keyboard focus shows as light, never a dark line round glass. By day a theme whose accent is its words' ink (opal)
  draws focus in its cool blue, not near black: the focus ring's line and a focused field's edge (still under its
  white glow). Themes with a coloured accent draw focus as before, and by night focus is as it was.

**From ui_core 0.3.0**

- The tooltip stays while the pointer moves onto it, one shows at a time, and along a toolbar the next shows at once.
- The tab bar is one Tab stop; the arrows move along it (mirrored right to left), Home and End to its ends, and a
  screen reader hears a tab bar, each tab with its place ("Income, tab 2 of 3").
- The wheels take Page Up and Page Down, Home and End, and a row's first letters; Left and Right move between the time
  picker's wheels; a row crossing the band ticks.
- The rating shows where a press would set it while a pointer rests over it, and takes End and the digits.
- The dialog tells a screen reader it is a dialog, `FrostedDialog.show`'s an alert; the dialog and the sheets keep
  focus inside them and give it back as they close, and a sheet, a side sheet or a page dragged and let go where it
  was holds the focus again. Escape closes a dialog or a sheet whose barrier a tap does not dismiss, however the focus
  sits (a `PopScope` still refuses it).
- A tab whose words grow where it stands (larger text, the chosen tab's words turning bold) lays the tab bar out
  again rather than cutting its words.

## 0.2.1

Frosted 0.2.1 stands on ui_core 0.2.1. Nothing is renamed or removed.

- iOS's Reduce Motion now calms Frosted. Flutter reports it in `AccessibilityFeatures.reduceMotion`, not
  `MediaQuery.disableAnimationsOf`, which was all `FrostedMotion.of` read, so on an iPhone set to Reduce Motion every
  switch, toast, menu and sheet still eased. `FrostedMotion.of` reads ui_core's `designReduceMotionOf` (Android's Remove
  animations, the web's `prefers-reduced-motion` and iOS's Reduce Motion), and the progress indicators, the skeleton
  and the loading state stop and start their loops as the setting changes.
- An insight's visit dots no longer say "1 visits": `FrostedLocalizations.visits(count)` speaks them in the app's
  plural forms, "1 visit" and "13 visits" in English by default. It has a body, so localizations written for 0.2.0
  still build.
- From ui_core 0.2.1: a menu or popover gives focus back to the control that opened it as it closes, a combobox's list
  no longer opens again on that returned focus (so Android's back pops the page), and Home and End keep the item they
  focus in view.

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

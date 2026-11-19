## 0.2.2

- Dates, times and the number field write their figures in the reader's
  digits (Arabic's Arabic-Indic ones), and the time field reads either
  those or ASCII ones. The date fields' hints, the time field's help line
  and the calendar's month arrows take ui_core's words for the reader's
  language; the time field's help and its error show the times it takes,
  `00:00–23:59`, instead of English words.
- The number field is one keyboard stop, as a spin button is: Up and Down
  step it, Home and End take it to its ends, and its `[-]` and `[+]` keys
  are the pointer's. A screen reader hears its name, its value and the
  values a step gives, in place of two keys named in English.
- A toggle group measures its choices' words as they are set before it
  puts them on one line, so words in a face other than the grid's (a
  script JetBrains Mono lacks) wrap instead of running past the line.
- Keyboard focus is now the cursor: an accent block over the focused
  part, its words and edge glyphs cut out of it, as a terminal shows a
  selection. It replaces the doubled brackets and focus rings on buttons,
  chips, toggles, tabs, checkboxes, radios, switches, sliders, ratings,
  rows, menus, links, crumbs, pages, calendar days and colour swatches.
  A chosen or filled part goes hollow, so chosen, pressed and focused
  read apart without colour. A checkbox, radio or switch puts its label
  under the cursor too, and a slider its whole rail. A select or date
  field also puts its value line under the cursor. A colour area takes it
  round its edge, and a line chart on its scale column. Text fields keep
  their doubled frame and caret. Focus shows only for the keyboard; a
  click never leaves it. The cursor glides in, and under Reduce Motion it
  (and a field's or pane's doubled frame) stands at once, with no fade. Against the part at rest, it changes at least a
  2 px line's area at 3:1 on every theme, night and paper, monochrome
  included. Page dots now show focus and a press.
- A calendar's days and weekdays grow with the system text size up to
  twice their size, as Material's calendar's do, so every day reads whole
  at 300%. A one-time code grows up to twice its size or the width it is
  given, whichever is smaller, so all its cells show on a phone. A bar
  chart's names and values grow up to 1.3 times their size, so its values
  stay on screen.

## 0.2.1

- Navigation destinations keep their names at large text sizes. Calendar
  highlights stay within their day columns, and date-range fields show both
  dates even when they need separate lines.
- Phone confirmation sheets start with the warning visible. Disabled
  filled buttons have readable labels on both the night and paper palettes.
- A typed confirmation's field stays whole beside the buttons while a long
  warning scrolls, and a dialog or sheet whose body is cut shows an arrow
  for the hidden part. Buttons stacked on a narrow sheet no longer leave a
  blank line between them.
- Slipway opens the run selected in the overview. At large text sizes the
  desk switches to a list with detail navigation when its panes no longer fit.
  The package title stays on one line on a phone.
- Deployment commands open the requested environment. The form requires a
  branch or commit, confirms production deployments, and discards edits on
  Cancel. Queued runs can be opened from the notification. Canceling an
  active run updates its status, steps, log and history.
- Progress bars leave room for the percentage, and toggle groups wrap
  their choices on narrow screens. Long confirmation titles wrap inside the dialog.
- Deleting a Slipway project removes it from Home, deployment targets and
  the run history, including its active run and logs.
- Requires `ui_core` 0.3.1.

## 0.2.0

Built on `ui_core` 0.3.0. Terminal's dialogs and sheets, tab bar, shell,
tooltip, rating and line and area charts take their behaviour from
`ui_core` (focus, keys, semantics, gestures) and keep Terminal's paint and
motion: they look as they did, and they do more. The constructors are
unchanged; the breaks below touch only code that told a dialog by its
route's type or held a tab bar's state.

### Breaking

- `showTermDialog`, `showTermSheet`, `showTermConfirmDialog` and
  `showTermActionSheet` push `ui_core`'s `DesignDialogRoute`, no longer
  Flutter's `RawDialogRoute`; the side sheet runs on a spring
  (`TermMotion.surface`, which keeps the 120 ms fade), as `ui_core` 0.3.0
  removed `DesignSideSheetRoute.transitionDuration`.
- `TermTabBar` is a `StatefulWidget` (it owns a `DesignTabController`),
  no longer a `StatelessWidget`. Its constructor is unchanged.

### Behaviour that changes

- A dialog or a sheet keeps Tab inside and gives the focus back to what
  opened it; Escape, Android's back and a tap outside close it through any
  `PopScope` in it. The y/N question is an alert to a screen reader.
- `TermTabBar` is one stop for Tab, on the current tab: the arrows move
  and choose (mirrored right to left), Home and End go to the ends, and a
  screen reader hears a tab and its place ("log, Tab 2 of 3").
- `TermScaffold`'s places (the window list, the rail, the side pane) are
  one stop, the arrows moving along them and Enter or Space going there;
  F6 moves between them and the page; a screen reader hears each place as
  a tab and the side pane as the navigation menu.
- `TermTooltip` shows on hover, on keyboard focus and after a long press;
  the pointer may rest on the tip, Escape hides it, one shows at a time.
- `TermRating` takes a drag across the marks and the digits (End all, Home
  none), with a step's haptic; a tap left of the first mark still gives
  none.
- `TermLineChart` and `TermAreaChart` are a stop: a pointer, a finger or
  the arrows pick a point (its column shaded, its value over the plot); a
  screen reader hears the data in a sentence, in the app's language, or
  the point picked, and steps through the points. A change of data springs.
- A key drawn by `TermKey.of` (`^K`) is heard in the reader's words
  ("Ctrl+K").
- A menu the pointer opened keeps the focus on itself (`ui_core` 0.3.0):
  the first Down shows the first row, as before, and Return or Space
  chooses nothing; Return no longer shows the first row.
- In `TermSplitButton`'s, `TermMenuBar`'s and `TermContextMenu`'s menus
  (`ui_core`'s rows) the pointer leaving the menu lights no row, and the
  next Down starts at the first. `TermMenu` keeps the last row the pointer
  was on, as before.

### Fixed

- `TermCombobox`'s list goes over a field with too little room under it
  (less than six lines, and more over it), as `TermSelect`'s does; at the
  foot of a screen it was held to the sliver under the field, its words
  cut off. `TermTagInput`'s still opens under.
- The caret of `TermTextField` (and every field on it) is the look's own
  block, on the cell after the words on every platform, behind the
  character it is on. On iOS and macOS it stood two pixels before its
  cell, over the last character's edge.
- Right to left, the words typed start on the cell the label and the hint
  do; they stood a cell inside (the room Flutter keeps for its caret). A
  line of words now runs to the frame's last cell, the caret past it.
- The keys' block on a chosen tab, window, rail item or menu row is in the
  ground's colour, cut out of the inverse cell; in the accent it was all
  but lost there (1.3:1 by night).
- Right to left, `TermBanner`'s title stands first, by its glyph, when the
  title and the message are in Latin letters.
- `TermNavigationBar`'s names stand on the character grid: the room left
  over is shared in whole cells.
- A double frame's sides are whole pixels, as its top and bottom are (a
  focused field, a dialog, a list's pane): they were astride two, at half
  strength.

### New, from ui_core 0.3.0

- `TermContextMenu`: a menu over a region, opened at the pointer by a
  right click or a long press, at the focus by Shift+F10 or the Menu key;
  its rows are `TermMenuBar`'s.
- `TermCombobox` and `TermTagInput` take `search` (looked up, async) and
  `debounceDuration`; while a search runs the list says `loadingText` by
  the spinner, and when it fails, `errorText` over a `retryText` row.
- `showTermDialog` and `showTermSheet` take `isAlert` and `semanticLabel`.
- `TermMotion.surface`, the spring a dialog, a sheet and a side sheet come
  up on.

The package page links to the live gallery, the API reference and the
source, and includes desktop and phone screenshots of Slipway.

## 0.1.1

- On iOS, Reduce Motion stills the look as Android's Remove animations and a
  browser's reduced motion do: a spring settles without overshoot, the caret
  stands as a steady block, the spinner holds, and a screen, a dialog, a
  sheet, a side sheet and the command palette come up at once. Flutter gives
  iOS's setting apart from `MediaQuery.disableAnimations`, which the look
  read alone; it now reads both, through `ui_core` 0.2.1's
  `designReduceMotionOf`, and follows the setting as it changes.
- What a screen reader hears for an avatar group follows the app's language
  and its plural forms: the words come from
  `TermLocalizations.avatarGroupLabel`, English by default ("1 person: …",
  "2 people: …"), and an app extends `DefaultTermLocalizations`, with a
  delegate, to word every form its language has. It said "1 people".
- The package's tests come in three tiers. `flutter test --exclude-tags
  goldens,sweep` is the one to run on every change: each matrix of widths,
  themes, directions and text sizes runs one case per screen or part in
  turn, so every width, both themes, right to left and twice the text are
  still met. `--tags sweep` runs the rest of those matrices, and
  `--tags goldens` the pictures (recorded on macOS), before a release.

## 0.1.0

- First release: 84 of `ui_core`'s 89 inventory components (actions,
  fields, pickers, choices and ranges, rows and collections, navigation,
  overlays, states and charts), drawn on one character grid, on
  `ui_core`'s behaviours; `termInventory` and `TermInventoryGallery`.
- `style:` on every part over its slot in `TermThemeData` (one a part, one a
  kind of button); a style sets colour and weight, never a size.
- `TermThemeData.from(palette, accentSlot:, accent:)` holds the accent to
  4.5:1 (`termReadable` pulls a colour until it does); `TermFace`,
  `TermStroke`, `AnimatedTermTheme`; the painters and faces public.
- `TermThemeData` with night, paper and monochrome presets, `copyWith`,
  `lerp` and value equality; `TermTheme` as an `InheritedTheme`.
- Tap floors on the lattice: one line under a pointer, two under a finger.
- Open lists by the keys: a select comes up on its chosen item, the arrows
  wrap, Home and End go to the ends, a typed letter jumps to the next item
  it starts, Return chooses and Escape gives the keys back to the field;
  menus walk the same way. The chosen item is the inverse bar; the pointer
  marks an item's words with the accent, and the keys add a block at its
  start (`TermListTile.option`). A combobox's and a tag input's list
  takes `ui_core`'s keys, and `isOptionEnabled` passes an option over.
- An open menu (`TermMenu`, `TermSplitButton`'s, `TermMenuBar`'s) has one
  current row, the keys': the pointer moving onto a row takes it there.
  Opened by the pointer it lights no row until the pointer or a key moves
  (the first Down shows the first row, Return chooses nothing unseen);
  opened by the keys it lights the first.
- A select's open list and a date field's calendar do the same: opened by
  the pointer, only the chosen row's bar or day reads current until a key
  (with nothing chosen, no row; the first Down shows the first). A date
  field's calendar opens with the keys on its chosen day, not on the
  month's arrow. A field's list (a select's, a combobox's, a tag input's)
  stands a cell inside its frame each side, as a menu does, its words a
  cell in from the field's.
- A press on a select or a date field focuses it, as a select does, so
  its list or calendar, closed by Escape or a choice, gives the focus back
  to the field (Return opens it again).
- A long select's or menu's list shows the row with the focus: the chosen
  one as it opens, the keys' row as it moves (past the end and round, or
  by a letter), scrolled no further than it takes.
- Right to left: a glyph button draws its glyph as given (a `>` stays
  `>`); a field whose words run their own way (code, a path) lays its
  prompt out that way too; the title line's steps read in order.
- `TermPageRoute` and `TermPageTransitionsBuilder`: screens change in a cut
  or a 120 ms fade in place; menus, dialogs and toasts come up where they
  stay. `TermTheme` sets it on `material_ui`'s theme;
  `termPageTransitions`, the same map, gives it to Flutter's own
  `MaterialPageRoute` through an app's `ThemeData`. Its iOS entry is
  `ui_core`'s `DesignSwipeBackPageTransitionsBuilder` round Terminal's
  change: a swipe from the screen's leading edge takes a page back.
- Return in a field that keeps the focus (a combobox's, a tag input's, the
  palette's search) keeps its input, so typing goes on in a browser too:
  they take it in `onEditingComplete`, which `TermTextField` now passes
  to Flutter's field, with no `onSubmitted`.
- `TermTimeField` holds a `TermTime` (an hour on a 24-hour clock and a
  minute, `copyWith` and value equality): no Material type in the API.
- Keys are written where a keyboard reaches the app and left out under
  touch (`termKeysShown`, from `DesignTapTargets`' input): a `TermKey`, a
  button's keys, a menu row's, the status line's and the rail's, and the
  keys in a palette's, dialog's, sheet's and toast's bottom line.
- JetBrains Mono and Liberation Mono bundled (SIL OFL 1.1).

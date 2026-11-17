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

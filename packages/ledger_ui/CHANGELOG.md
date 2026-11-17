## 0.2.0

- **The ordinary parts, in Ledger's hand.** Ledger now carries a part for every row of ui_core's inventory of the
  controls a design system is expected to have (`ledgerInventory`, shown whole by `LedgerInventoryGallery`; a row it
  leaves out says why). New:
  - fields: `LedgerPasswordField` (its reveal on ui_core's), `LedgerTextArea` (a ruled memo with a count),
    `LedgerCombobox` (suggestions as you type), `LedgerMultiSelect`, `LedgerCodeField`, `LedgerInputGroup` (a sign
    or a unit beside the words), `LedgerRangeSlider`, `LedgerFileUpload` and `LedgerDateRangePicker`;
  - wayfinding: `LedgerBreadcrumb`, `LedgerPagination`, `LedgerStepProgress`, `LedgerPageDots` and
    `LedgerCommandPalette`;
  - in the margins: `LedgerDivider`, `LedgerBadge`, `LedgerDisclosure`, `LedgerTimeline`, `LedgerMedia` and
    `LedgerKbd`;
  - under way: `LedgerProgressBar`, `LedgerProgressRing`, `LedgerSkeleton`, `LedgerPieChart` and
    `LedgerSparkline`;
  - over the page: `LedgerSideSheet`, `LedgerActionSheet`, `LedgerPopover`, `LedgerTooltip` and `LedgerBanner`;
  - collections: `LedgerDataTable` (sorted by its headings, rows chosen by a press), `LedgerReorderableList`,
    `LedgerCarousel`, `LedgerScrollArea`, `LedgerPullToRefresh` and `LedgerSwipeActions` (every act also a screen
    reader's action);
  - acts: `LedgerToggleGroup` and `LedgerSplitButton`.
- **`LedgerHost`** is the whole install in one widget for an app's `builder:`: the theme by day and by lamplight,
  the Material bridge under it and the toasts over the app. `LedgerTheme` alone still works as before.
- **Your own look per part.** The ordinary parts (the buttons, the icon button, the fields, the chip, the checkbox,
  the switch, the segmented control, the toggle group and the filters, the badge, the banner, the tooltip, the
  toast, the dialog and the slip) take a `style:`, a `LedgerStyle` (ui_core's `DesignStyle`, read as Material's
  `ButtonStyle` is), and `LedgerThemeData.components` sets one per part across the app. A field's style keeps it
  written on a rule: it reads the rule's ink, the paper, the padding and the words, never a shape. The select, the
  radio, the slider, the rows, the tabs, the bars and the sheet take no `style:` yet; the theme's roles restyle them.
- **Paper keeps a paper's corners.** `cardRadius` stands from 0 to 22, `smallRadius` from 0 to 10 and
  `sheetRadius` from 0 to 28 (`LedgerThemeData.cardRadiusMost`, `smallRadiusMost`, `sheetRadiusMost`), the range
  Ledger's own presets span, which keep their corners. A theme built or copied past them fails an assert in debug
  builds that says why: a slip rounded like a pill reads as plastic, not paper. `controlRadius` stays free, round or
  square, and a theme animated on an overshooting curve holds its paper within the bounds.
- **The money tones are documented as meaning, not decoration.** `moneyIn` is the accent's green, `over` the
  vermilion for spending past a limit and `move` a quiet ink. `LedgerThemeData.from` and the presets keep them tied
  to the accent, the over colour and the ink; change the accent with `from`, since `copyWith(accent:)` changes the
  act alone and leaves money in green.
- **Any value in a segmented control or the filters.** `LedgerSegmentedControl<T>` and `LedgerFilters<T>` take
  values of any type, worded by `labelOf` (their `toString()` when you give none), as `LedgerSelect<T>` does.
  Calls written with strings work unchanged. **Breaking** for a test that finds one by its type:
  `find.byType(LedgerSegmentedControl)` no longer matches a `LedgerSegmentedControl<String>`; use
  `find.byWidgetPredicate((w) => w is LedgerSegmentedControl)`. A `LedgerFilters` whose `value` is `null` and whose
  other arguments name no type needs it spelled: `LedgerFilters<String>(...)`.
- **Fields, sheets and menus no longer crash in apps set to a language other than English; their built-in labels now
  follow the app's language.** An app on Flutter's `MaterialApp` with `flutter_localizations` gives Flutter's own
  words, which a part built on `material_ui` cannot read: a text field and a sheet threw "No MaterialLocalizations
  found" in German, Arabic or any language but English. Ledger now loads `material_ui`'s and `cupertino_ui`'s own
  translations for the app's language (a text field's menu, Cut, Copy, Paste and Select all, on iOS too) whenever
  the app gives none of theirs, and English for a language they do not know.
- **30 languages.** The words a part says by itself come from ui_core's `DesignLocalizations` in 30 languages: add
  `DesignLocalizations.delegate` and `supportedLocales: DesignLocalizations.supportedLocales` to your app. Confirm,
  Try again and the toasts' region are among them now.
- **Touch.** Every control's 44 point reach is ui_core's `DesignTapTarget`, so what a screen reader outlines is
  what a finger reaches. A text field takes a tap anywhere on its line, its sign and margins too, and on its help
  or error under it; a memo anywhere on its ruled paper, its count's room too; a tag field and the command
  palette's search take one anywhere on their line; a code field is as wide as its cells. A sheet's close now stands on the card's column instead of hanging 6 points into its margin,
  so all of its target takes a tap (`LedgerChromeMetrics.sheetCloseHang` is deprecated). `LedgerHitSlop` is
  deprecated: use `DesignTapTarget`.
- **A field's list opens on its field.** A select's options, a combobox's and a tag field's suggestions open at the
  field's width on its leading edge, wider only to fit the widest option (at most 320), at any window width and in
  either direction; their words stand 16 in from the field's, the rows' own inset. From 600 a select stands at a
  short entry's measure at the start of its slot instead of spanning a wide column.
- **An open list shows its chosen option.** In a select's, a combobox's and a menu's list the chosen option stands on
  the menu's paper, its words semibold, the green tick at its end; it used to show the tick alone. A pointer
  underlines an option's words, and the keyboard doubles the rule under them, both on the option's own row: the
  keyboard's rule used to run under the whole row, past the rules between options, reading as a break in the list,
  and a suggestion under the pointer used to take a wash a second choice could be taken for.
  `LedgerPressable.rulesFocus: false` lets a face write focus in its own words.
  With nothing matching, a combobox's "No results" stands on paper the field's width, as its options do; it used
  to stand on a slip as wide as its words.
- **Typing goes on after Enter, in a browser too.** The fields that keep the focus after Enter, the combobox's,
  the tag field's (`LedgerMultiSelect`), the command palette's search and the composer's, take Enter without
  restarting their text input. In a browser a restarted input took no more typing: after Enter took an option or
  added a tag the field still looked focused and the arrows worked, but letters and Backspace did nothing. The
  composer keeps the focus once it sends, for the next message. `LedgerTextField`'s `onSubmitted` and
  `onEditingComplete` say which to use: a field that keeps the focus takes Enter in `onEditingComplete`, never both.
- **One current row in a menu.** A split button's menu and the menu slip mark one row at a time, the one the
  pointer or the keys moved to last: the pointer's underline or the keyboard's double rule, under the words alone.
  The pointer moves the keys' place with it, so a pointer resting on one row and the keys on another no longer
  read as two current rows. A menu a click opened marks none until the pointer or the keys move (Down, Enter or
  Space then mark its first rather than pass it or press it unseen); one the keys opened marks its first. A split
  button's menu used to rule the keyboard's place across the whole row to the paper's edge, to light its first
  row however it was opened once a key had been pressed, and, beside the desktop's side bar, to slide under the
  bar; it now keeps to the room between the bar and its button's end, its words wrapping.
- **A select from the keyboard.** Down opens its list as Enter and Space do, and an open list puts the keyboard on
  the chosen option (the first while none is), however it was opened: the arrow keys move at once, round from the
  last to the first, Home and End go to its ends, a letter to the next option it starts, Enter chooses and closes,
  and Escape closes, the keyboard back on the field either way. It used to open on the first option.
- **Toasts** run on ui_core's toaster: a pointer or the keyboard over one holds it, F6 reaches it, Escape and a
  swipe dismiss it, and a screen reader hears it. `LedgerToast.show` is unchanged.
- **Spacing** is LedgerSpacing's steps throughout, on a 2 point grid the host declares to ui_core. A few gaps
  move a point to land on it: the ends of a chip, a filter, a toggle group's pill and a quiet button are 12 (were
  13), a focus ring stands 2 clear of what it rings (was 3), a row's second line stands 4 under its first (was 3),
  and a few rows grow a point or two (a key and value row is 44 tall).
- **Ledger's page motion.** A pushed page is a leaf laid down: it fades in as it rises 8 points, in 200 ms, and a pop
  lifts it off the same way; under reduced motion it lands at once. Pages used to fly in by the platform's slide or
  zoom. `LedgerTheme` and `LedgerHost` set it (`LedgerPageTransitions`), so a `LedgerPage` takes it (under the host
  it used to fly in still: the host's own Material theme left the motion out); Flutter's own
  `MaterialPageRoute` reads your app's `ThemeData`, so give it `ledgerPageTransitions` there, as the README's install
  does. A destination chosen in the side bar, the rail or the tab bar changes in place, and its mark lands in the
  same frame (it used to ease over 120 ms, so the new page showed under the old destination's mark). On iOS the
  swipe back from the screen's leading edge stays round the leaf (`ledgerPageTransitions` wraps its iOS entry in
  ui_core's `DesignSwipeBackPageTransitionsBuilder`): the page follows the finger and goes past half way or on a
  fling.
- **Back closes what is open first.** Android's back (any pop the app asks for) closes a select's list, a popover
  or a field's suggestions before it pops the page under them (ui_core 0.2.0); they used to go with the page. A
  sheet and a dialog are routes and closed first already.
- **A tablet's page.** Beside the rail (600 to 1023 wide) a pushed page heads itself with the crumb back, as at
  desktop width; it had no way back there, the phone's bar not standing beside a rail. A bottom sheet stands at 640
  at most (`LedgerLayout.sheetMeasure`, Material's), centred, where it used to stretch across a tablet.
- **Buttons answer a pointer.** Under a mouse a filled button lifts toward its words' colour, a ringed one takes a
  wash of the ink and a frameless one its underline, so a desktop sees what a click will reach.
- **Right to left.** `LedgerFormat.isolated` holds a figure left to right inside words of either direction, so a
  Hebrew or Arabic line prints "+$73.42" and "··4821" as written, never "$73.42+".
- **Fixes.** A receipt's sum shrinks to fit beside its seal instead of running under it; a docked act keeps its
  shadow at the column's edge; at a large text size the phone tab bar's names set at one shared size, a checkbox's
  or a radio's words grow its line instead of being cut, and a day's date drops whole under the day instead of
  breaking mid-date. A perforation punches whole holes only, so none is sliced at a slip's notch, and the empty and
  error pages' ruling breaks round each block across the whole line instead of leaving stubs beside the words.
- Every public widget lists its settings in Flutter's inspector (`debugFillProperties`), and out-of-range values
  (a negative count, a carousel's viewport past 1, a chart's empty month) fail an assert in debug builds.
- `LedgerTheme.of` gives the default theme (quire, by day or by lamplight as the platform is) where no `LedgerTheme`
  stands, as Material's `Theme.of` does, instead of throwing; `LedgerTheme.maybeOf` still gives null.
- Every example in the API docs is compiled and run by the package's tests, and the tests run with Flutter's leak
  tracking.

## 0.1.1

- A mouse over the slider now shows the pointing hand, on its track and on its knob, as it does over every other
  control; a slider that is off keeps the cursor of what it stands on.
- The tabs of the phone's tab bar, and its raised action, show the pointing hand too, and so does a select's label;
  a text field's label shows the text cursor, since a click on it puts the caret in the field.

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

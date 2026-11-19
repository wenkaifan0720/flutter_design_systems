## 0.3.2

- `LedgerStepper` and `LedgerPieChart` no longer assume money. Without a `format`, both show the plain number in the reader's digits, so a count of copies reads 2 instead of $2 and an estimate in minutes reads 45. To show money, pass a format: `format: (value) => LedgerFormat.money(value, showCents: false)` for a budget in whole dollars, or `format: LedgerFormat.money` for a pie chart of amounts. The gallery, the inventory and Quill pass these where their numbers are money. If your app relied on the dollar default, add the format.
- `LedgerPieChart` speaks the reader's language. Its parts of the whole use the language's digits and percent sign (٧٠٪ in Arabic). The word under the whole, Total in English, comes from the new `totalLabel`. Outside English, if `totalLabel` is not set, the whole stands alone rather than showing an English word.

## 0.3.1

- `LedgerTabs.children` displays swipeable pages and gives each panel its tab's accessible name. The Selection example includes Entries, Notes and Files panels.
- `LedgerStepper.format` formats quantities and their screen-reader values. The default still displays whole dollars. The Copies example counts in single units.
- `LedgerStepper(size: LedgerStepperSize.field)` is a form's number field. The number sits on a text field's rule at the same height, with its label above and help or error text below, and the minus and plus buttons sit at the end of the line. It accepts typed numbers within `min` and `max` and shows an error while a typed number is out of range. Up and Down step the value, and Page Up and Page Down move ten steps. The new `max` also stops both sizes' plus button at that value. The default size is still the budget's large figure.
- Inline search accepts taps across the field’s height and supports keyboard and screen-reader input. One-time codes and selects announce their label once, and a multi-select's tags can be reached separately from its text field.
- Standalone navigation destinations can be focused and activated with the keyboard.
- Field captions and compact date pickers make room for long labels. Step counts keep the current step first in right-to-left layouts.
- Month charts place overlapping first-day and current-day labels on separate lines. Pie chart legends wrap their amounts and percentages below the labels when space is tight.
- The refresh prompt stays inside its visible area during short drags. Segmented controls follow their outer corners when the theme uses a small radius. The clear button sits evenly inside the search field.
- A segmented control in a wider slot keeps its ring to its segments, at the slot's start. Its keyboard focus rule spans the focused segment and touches it.
- In a sheet, the date picker's month, arrows and closing rule span the sheet, so a tablet's date sheet no longer leaves an empty column beside the calendar.
- The date picker speaks the app's language. Outside English, its pills, calendar and wheels use ui_core's words, date order and digits: an Arabic due date reads ٢٠ نوفمبر ٢٠٢٦ at ٠٩:٣٠, and a German one 20. Nov. 2026 at 21:05. Its wheels use a 24-hour clock where the language does, and weeks still start on Monday. English reads as before. Each pill is named by the picker's label, with its date or time as the value. At large text sizes the month's name wraps instead of being cut. Outside English, the stepper field's range error shows the range in the language's digits (٥–٤٨٠).
- Tables keep amounts and whole words readable. When columns are too narrow, each record shows its remaining fields below the name with their column labels. Swipe actions size their solid backgrounds to fit their labels. Calendar dates and weekday labels grow with the system text size.
- Validation messages use higher-contrast red text. Page titles can use the full width beside the back button when there are no actions.
- At large text sizes, two-word tab bar names such as New entry wrap onto a second line instead of shrinking every name to fit the longest on one line. At twice the text size, the names in a five-column phone bar grow to about 1.6 times their normal size. `LedgerNavBar.bandIn` accepts the names and the bar's width to reserve room for the second line.
- In Quill, the example app, saved entries appear in the register, its search and Home. Amounts entered with a decimal comma keep their cents. Validation errors update as the fields are corrected. Signing out hides the account, register and receipts until you sign in again. Profile changes are kept when you leave Settings. The register count includes only entries the register contains. Settings shows the currency as US dollar because Ledger formats amounts in dollars.

## 0.3.0

Needs ui_core 0.3.0. Ledger's behaviours move onto ui_core's: Ledger keeps its paper, its ink and its motion, and
ui_core runs the keys, the focus, the gestures and what a screen reader hears. No public name is removed or renamed;
the changes in behaviour are listed at the end.

- **Dialogs and sheets** (`LedgerDialog.show`, `LedgerSheet.show`, `LedgerSheet.pageRoute`) ride ui_core's
  `DesignDialogRoute` and `DesignBottomSheetRoute`: they move on ui_core's springs (a short fade under Reduce Motion),
  keep Tab inside them and give the focus back to what opened them, Escape closes them, and a phone's sheet follows a
  drag and lets go on a drag down or a fling. A raised `LedgerDialog` opens with the focus on its safe act: Cancel
  beside a destructive confirm, the confirm otherwise.
- **Tabs** (`LedgerTabs`) are ui_core's `DesignTabBar`: one tab stop, the arrows (mirrored right to left, wrapping)
  and Home and End moving the choice, the change on a spring, the rule drawn out under the old tab as it is drawn in
  under the new. Each tab says its count and its place ("Entries, 12, Tab 2 of 3").
- **The navigation frame** (`LedgerNavigationFrame`) is ui_core's `DesignAdaptiveShell` at Ledger's widths, painted
  by `LedgerNavBar` and `LedgerSideBar`: the destinations are one tab stop that the arrows move along, Enter or Space
  choosing; F6 moves between the navigation and the page; the phone's bar is a tab bar to a screen reader, its act a
  button beside it, and the side bar is the navigation menu. The phone's tabs gain the keyboard and a focus rule. The
  page keeps its state as the window crosses a width.
- **The split button's menu** keeps one current act through ui_core's `highlightFollowsPointer`: the hovered act
  while the pointer moved last, the focused one while the keys did, none in a menu a click opened (Down lights the
  first act, Up the last).
- **The tooltip** (`LedgerTooltip`) is ui_core's `DesignTooltip` round Ledger's slip: it also shows while the keys
  hold its anchor, the pointer may move onto it, Escape hides it, and one shows at a time after a warm-up.
- **Wheels** (`LedgerDatePicker`'s wheel presentation) turn on ui_core's `DesignWheelPicker`: Page Up and Down, Home
  and End and typing join the arrows, a fling settles on a row, and the keyboard's focus draws Ledger's double rule
  under the wheel.
- **Searching**: `LedgerCombobox` takes a `search` (and a `debounceDuration`) in place of `options` and paints
  ui_core's loading and failed states on its paper, with a "Try again" line the keys reach.
- **Shortcut keys**: `LedgerKbd.shortcut` prints a `SingleActivator` as the platform writes it (⌘K on Apple's
  platforms, Ctrl+K elsewhere) and spells it for a screen reader.
- **Surfaces beside the side bar**: a menu, list, popover or tooltip opened in a page beside a side bar of
  Ledger's keeps clear of the bar through ui_core's `DesignOverlayPadding`.
- **Right to left**: the preview frame's side bar stood at the left in RTL while its pages stood beside it at the
  reading start; it stands at the start now.
- **Symbols in a figure**: Instrument Serif has no ±, arrows, fractions, ≈ ≤ ≥ or ₹ ₩ ₽; a figure, a title or a
  monogram now sets them in Inter Tight, which ships with Ledger, rather than in the platform's fallback face.
- Updated the installation example to use `material_ui` and `cupertino_ui` on Flutter 3.50.

Changes in behaviour:

- Enter in a split button's menu that a click opened presses nothing until an act is lit (it pressed the first).
- `LedgerTabs` is one tab stop rather than one per tab, and its arrows wrap from the last tab to the first.
- Under `LedgerNavigationFrame` the page stands above the tab bar and beside the rail or the side bar rather than
  under them, so `ShellInsets.of` reads 0 there and a page pads for neither.
- A sheet or dialog's motion is ui_core's spring; `LedgerSheet.motionOf` still gives Ledger's timed motion for an
  app's own transitions.
- `LedgerDatePicker` reports a wheel's value once the wheel comes to rest, not at every row it passes.
- `LedgerPreview`'s app stands in a semantics container of its own, so a screen reader still reads the page round
  the preview (a route's barrier hid what was painted before it). The example gallery's Navigator and nested apps do
  the same; on material_ui's `MaterialApp` the side bar's destinations were missing from the semantics tree.
- A phone's sheet opened with `LedgerSheet.pageRoute` names its scrim to a screen reader ("Dismiss"), which closes
  the sheet; it was silent.

## 0.2.1

Needs ui_core 0.2.1.

- Reduce Motion on iOS calms Ledger too. Flutter puts iOS's Reduce Motion in dart:ui's
  `AccessibilityFeatures.reduceMotion`, not in `MediaQuery.disableAnimationsOf`, which was all Ledger read, so on an
  iPhone with Reduce Motion on, Ledger's eases, sheets and loops still ran. `LedgerMotion.isReduced` now reads ui_core's
  `designReduceMotionOf`, which also covers Android's Remove animations and the web's `prefers-reduced-motion`, so
  `LedgerMotion.of` and `LedgerSheet.motionOf` give cuts under any of them. The progress bar, the progress ring, the
  skeleton and the loading state's leader stop looping, and when the setting changes while one runs, it stops or
  starts at once.
- Counted words take their plural form. A text area's count of what is left says Material's words ("1 character
  remaining", "No characters remaining"), in the app's language with its plural forms; it said "1 characters left".
  `LedgerVisitRuler`'s own label says "1 payment this month".
- `LedgerDisclosure` opens and closes at once under Reduce Motion. At a zero duration its size animation re-dirtied
  its own layout, an assertion in debug builds, on Android's Remove animations as on iOS's Reduce Motion.
- From ui_core 0.2.1: a menu or popover its anchor opened gives the focus back to the anchor as it closes, and Home
  and End in a menu keep the row they reach in view.

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

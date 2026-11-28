## 0.9.1

- Needs ui_core 0.8.7: a bottom sheet opened over `LedgerAppShell` ends at the top of its tab bar, where it ran to the screen's foot and covered the bar. The bar stays under the veil and a tap on it closes the sheet. The gallery's account page at 390 shows it.
- `ledgerLoadFonts` loads the Lucide icon font Ledger's parts draw their glyphs from, as well as its faces, so on the web a glyph never comes up as an empty box on the first frames.
- `LedgerHost` takes a `density` beside its `palette` and `brightness`; it stands over the theme by day and by night, a palette's or the app's own. The host's doc says how `theme`, `darkTheme`, `palette` and `density` combine, and that the window's width changes none of them.
- `LedgerTextField`'s doc says what a form does to it: a Material `Form` passes it by; in a `RawFormField`, `reset()` takes the error away and leaves the controller's text, so a form empties with `reset()` and then `controller.clear()`.
- README: one delegate list (`RawWidgetsLocalizations.delegate` and `GlobalMaterialLocalizations.delegates`, with `RawWidgetsLocalizations.supportedLocales`), and no `flutter_localizations` on material_ui; the example lists the same delegates. The Forms section clears the form after a save, shows a `RawForm` that checks itself and names `autovalidateMode`. The corners example is a tab's, its top round and its foot square.
- The gallery's Overview "Corners of its own" slip and its button round their top corners and keep their foot square, the same on both sides, in place of two diagonal cuts.

## 0.9.0

- Needs ui_core 0.8.6.
- **Shapes an app can change, within Ledger's laws.** Ledger's corner steps live on the theme, in `LedgerThemeData.shapeScheme` (ui_core's `RawShapeScheme`): 3, 6, 6, 6 and 12, and full for what the hand holds (`LedgerThemeData.defaultShapeScheme`). `LedgerThemeData.light`, `dark`, `from`, the constructor and `copyWith` take an app's own scheme and hold each step to its band (`LedgerThemeData.shapeLimits`): extraSmall 2–5, small 2–10, medium 2–12, large 4–16 and extraLarge 8–16. Rounder than those, a slip reads as a plastic card and a bar as a pill. A full step is round at any height, or at most the scale's `fullMaxRadius` when an app gives one. Corners stay round, and Ledger opens no stroke and no depth: its rules are ink to be read and its paper lies flat. A value past its band is held to the band's end, with a note in debug builds. A change of shapes moves across with the rest of the theme.
- **A part's own corners.** A style's `corners` (ui_core's `RawCorners`) gives a part a step of the theme's scale at each corner. For example, `LedgerStyle(corners: WidgetStatePropertyAll(RawCorners(topEnd: RawCorner.none, bottomStart: RawCorner.none)))` cuts a button's two diagonal corners square. Ledger opens a step per corner (`shapeLimits.cornerFreedom` is `perCorner`), from square to extra large and full. A full corner beside corners of other steps is 20 (half the 40 tap floor), or the scale's `fullMaxRadius`. Start and end follow the reading direction. A style's `shape` still wins and is drawn as given.
- Every part with an outline it takes a style for reads them: `LedgerButton` (each kind), `LedgerChip`, `LedgerFilters`, `LedgerToggleGroup`, `LedgerSegmentedControl`, `LedgerSlip` (a `LedgerSlipBand` follows the slip's top corners), `LedgerBanner`, `LedgerToastCard`, `LedgerDialog` and `LedgerTooltip`. Their press washes, focus rings and clips follow the outline they draw. The other parts follow the theme's steps.
- `LedgerKeyValue` wraps a long value beside its name, the dot leader running from the name to the value's first line; at 390 a 70-letter value was cut mid-letter on one line. A value in the mono (a mask) stays on one line and ends in an ellipsis where it cannot stand whole. New `LedgerLeaderLine.wrapsEnd` lets any leader line's end wrap so.
- `LedgerDatePicker` with no `value` opens with no day struck, and its Done keeps the date unset until a day is picked; it chose today, against its own documentation. New `onClear`: a chosen date's sheet offers Clear beside Done.
- A palette changes the colours only. Terracotta, indigo, verdigris and carbon set their own type and spacing, so a page moved as the reader changed palette (a head 14 wider and 3 taller); each now keeps Ledger's type, spacing and corners.
- A radio's and a checkbox's empty ring reads at 3:1 or more on every palette's paper (verdigris measured 2.6:1, indigo 2.1:1 by day). A filled button under a pointer keeps its words at 4.5:1 or more (prussian measured 3.9:1 by night, and verdigris's hover lifted the face toward its white words by day).
- **Breaking:** `LedgerThemeData.cardRadius`, `controlRadius`, `smallRadius` and `sheetRadius`, with `cardRadiusMost`, `smallRadiusMost` and `sheetRadiusMost`, are gone; read `shapeScheme.corners.medium`, `fullMaxRadius`, `small` and `large`, and `shapeLimits` for the bands. `LedgerCorners` is gone with them.
- **Breaking:** `LedgerThemeData`'s constructor is no longer `const`, because it holds the scheme to its bands. `LedgerThemeData.fromTokens` is gone; a palette is `LedgerThemeData.fromPalette` or `LedgerThemeData.from`.
- **Breaking:** `LedgerPressable` takes a `borderRadius` (a `BorderRadiusGeometry`) where it took a `radius`. In `ledger_parts.dart` (outside semver), `LedgerRadioPress`, `LedgerStateFace` and `LedgerFocusRing` take a `borderRadius` too, `LedgerImpression.wash` is a `BorderRadius`, and `ledgerRadius`, `ledgerRadiusOf`, `ledgerStep` and `ledgerInset` resolve a part's corners.
- The gallery's Overview shows a slip and a button with corners of their own. Foundations gives the corner steps from the theme.

## 0.8.0

- Requires ui_core 0.8.2.
- `LedgerNavigationFrame` is `LedgerAppShell`, the name every look's shell takes; `dart fix --apply` renames it. The old name stays, deprecated, until 1.0. It stands on ui_core's `RawAdaptiveShell` at every width: the tab bar along a phone's foot, the rail from 600 wide and the side bar from 1024.
- New `LedgerAppShell.branches`: each place keeps its own stack of pages (`branches`, one builder each; `navigatorKeys`, `backBehavior`). A page pushed on a place stands beside the rail or the side bar; on a phone the tab bar steps away for it (`hideBarOnPush`). Back pops it, choosing the place again goes back to its first page, and another place keeps its own pages. A toast keeps clear of the bar.
- `LedgerShellAction` is a class of its own (the shell's, the tab bar's and the side bar's `action` took a `ShellAction`), with the same fields. `LedgerNavItem.fromTab` and `LedgerNavItem.ground` are gone: no part of the main library names a type from the host library.
- `LedgerHost` and `LedgerMediaGround` are in `package:ledger_ui/ledger_ui.dart`, the one import an app needs; `ledger_host.dart` keeps the previews. `LedgerHost(palette:)` takes one of the six palettes or an app's own.
- Palettes: `LedgerThemeData.palettes` holds Ledger's six as ui_core's `RawNamedPalette` (an id to store, a label to show, the swatch by day and by night); `LedgerThemeData.fromPalette` builds a book from one. `LedgerThemeData.presets` is gone; use `palettes`. Where a palette inks money in as its ink (Carbon's black), its caution is the second ink, so a goal behind reads apart from money in.
- A control's `label` that was only spoken is `semanticLabel`: `LedgerPressable`, `LedgerRadioPress`, `LedgerMoreLink`, `LedgerAvatarStack`, `LedgerAvatar`, `LedgerBadge`, `LedgerCheck`, `LedgerChipRow`, `LedgerFilters`, `LedgerToggleGroup` and `LedgerWeekStrip`. `dart fix --apply` renames them.
- Removed what 0.7.0 deprecated: `LedgerLayout.minHitTarget`, `LedgerChromeMetrics.minHit` (read `RawTapTargets.of(context).floorOn()`) and `LedgerThemeData.contrast` (use `RawPalette.contrastRatio`; `dart fix --apply` moves it).
- `LedgerDatePicker.value` may be null: the field then asks for a date (the words in the second ink) and its sheet opens on `currentDate`. Its date is the medium one with the year ("Mar 3, 2026"; `MaterialLocalizations.formatMediumDate` in another language).
- Fields in one column take one width: `LedgerSelect` and the sum field span their column as a text field does (they stood at their content's width). `LedgerScreen.form` sets the column, at most `LedgerLayout.formMeasure` (640) from the page's start, and its `footer`'s acts keep to it on a desktop; `LedgerLayout.formColumn` is the same column for a page of its own. A record's page stands on it too.
- A `LedgerRow`'s `trailing` control keeps its own node and press (a row's menu was merged into the row's name), and takes at most half the row. A row's padding follows the density (4 off a step), as a toggle group's pills and the filters do.
- `LedgerHead`'s note wraps under a narrow width beside its rubric (a long note overflowed the row). `LedgerFacts` stacks its facts by the room it is given (under `LedgerFacts.stackUnder`, 480), not by the window's width.
- `LedgerFormat.initials` takes the first and the last word ("Ursula K. Le Guin" is "UG"; it took the first two). `LedgerMonogram` and `LedgerAvatar` grow with larger text up to 130%, as tags do (they stayed one size).
- On a phone a page scrolls under its top bar's strip, not behind it: a field brought into view (a form's first problem, focused after its check) stands under the strip, where it stood hidden behind it.
- `LedgerTextField` comes into view whole when it takes the focus, its label and its problem with it and 24 round it, the room a form's column keeps under the bar (Flutter's text field shows only its line and 20 round it).
- In a `LedgerButtonRow` an act that expands takes its share of the row from 600 too, where it kept its lone 320 and the two stood one above the other on a desktop's form column.
- `LedgerRadio.leading`: a part drawn between the ring and the words, 12 from each (a palette's colour), out of the radio's name.
- `LedgerSwipeActions` says its acts on the row's own node (ui_core's `RawSwipeActions`). An open row is cut at its own sides (it slid into the page's gutter), and only there: a focused row in a swipe row draws its double rule again (the cut took it).
- The documentation speaks to an app's author: no words of the stylesheet Ledger was drawn from, every example compiles.
- The example is one app to copy, a reading list: the host by day, by night or as the device is, in any of the six palettes (each shown by its colour and its name); `LedgerAppShell.branches` with three places; a list with a page pushed for each book; a form that checks its answers, with an optional date; a dialog popped with its answer; the settings. The gallery is `example/lib/gallery.dart`.
- The README is rewritten: the install line that makes every snippet compile, the host as the one mount, and how to build an app (the shell, a list and its pages, forms, dialogs, a palette picker), with a table of the building blocks. Every Dart block in it compiles in the tests.

## 0.7.1

- By day `terracotta`, `indigo` and `verdigris` write in their accent's hue, as `prussian` writes in its seal's: each preset's three inks keep their tones and take the accent's hue and a share of its colour (at least enough to read as the hue), so the presets read apart by their words as well as by their paper. Terracotta's ink is a terracotta brown (`0xFF3D180D`, was the brown-black `0xFF2B2118`), indigo's a deep indigo (`0xFF1B1C4B`, was the slate `0xFF1A2230`), verdigris's a deep teal (`0xFF00262C`, was the slate `0xFF18232B`) over a teal second ink (`0xFF457079`, was `0xFF5D6B75`); the words read as they did (the ink 13:1 on its papers, the second and third inks at least 4.5:1). Quire keeps its own slate ink and carbon its black; by lamplight every preset keeps its inks.

## 0.7.0

- Requires ui_core 0.7.2. Ledger's tap floor is ui_core's, 40 by 40 for a finger (it was 44), and every part reads the floor in force: an app's `RawTapTargetScope` above the theme sets its own. What drew a fixed 44 or 48 (a slider's and a range slider's touch strip, a date picker's and a date range picker's day cells, the pagination's cells, a field stepper's rings) stands on the floor; faces drawn larger keep their size. The pagination counts its row as it lays out before it writes its figures. `LedgerLayout.minHitTarget` and `LedgerChromeMetrics.minHit` are deprecated (they go in 0.8.0): read `RawTapTargets.of(context).floorOn()`.
- `LedgerFilters`, `LedgerChipRow` and `LedgerBreadcrumb` stand their faces their gap apart, their targets reaching into the room between (ui_core's `RawChipGroup`): two runs of filters stand 8 apart under a finger (their 40 targets meet) and 6 under a pointer, where they stood 18.
- A sixth preset, `prussian`: a bank's account book, a buff paper in a navy ink with the seal in Prussian blue, and by lamplight a deep Prussian paper under the buff. `LedgerThemeData.presets` names the six; the example's Foundations page shows them side by side.
- `LedgerThemeData.from` builds the night of a day book: asked for `Brightness.dark` with a light paper it takes a dark paper in the paper's hue, the paper's cream for its ink and the accent at the nearest tone that reads (it built a light page labelled dark). `nightPaper`, `nightInk` and `nightAccent` set any of the three; a night book asked for by day turns the same way. Its second ink stands darker than its third by day (they had crossed), the night toast's act reads on the toast, its raised paper by day stands half way to white as the quire's does (it stood 6% off the page), and an ink that doesn't stand 7:1 off its paper takes the book's own ink tone in its hue (a slate ink on a black paper read 1.1:1 by night).
- Words that must read take the nearest tone of their own hue that does (ui_core's `RawPalette.readableTone`, Material's colour space) where they were blended toward the ink: the vermilion's words, the presets' third ink, money in, the accent's words and the toast's act, and the kit's tokens (their words on the accent too). A few inks move by a shade. `LedgerThemeData.contrast` is deprecated (it goes in 0.8.0): use `RawPalette.contrastRatio`.
- `LedgerSwipeActions` lays no paper of its own under its row: its acts are built only in the strip a drag uncovers, so the row shows the ground it stands on (on a slip or a sheet it showed a band of the page's paper, the row's words at its edge).
- A `LedgerToggleGroup`'s pills grow with larger text and keep their words clear of their rules (at twice the size the words sat on the foot); at the words' own size a pill stays 32.
- `LedgerPagination`'s page written out on a narrow width, `LedgerPageDots` and `LedgerStepProgress` say their place in the app's language (ui_core's `positionLabel`: "٢ من ٩" in Arabic); English keeps "PAGE 2 OF 9", "Page 2 of 5" and "Step 2 of 3".

## 0.6.0

- Requires ui_core 0.6.0, whose `Design*` names are `Raw*` now (`RawTapTargets`, `RawInventoryEntry`, `RawModalDialogRoute` and the rest). `dart fix --apply` renames them in an app (ui_core's `lib/fix_data.yaml` holds them); Ledger's code, docs and examples use the new names.
- A multi-select's text entry under its tags is as tall as a tag, the touch floor. On a run of its own its node and a tap reach a target's size (they were 24 tall), and the field grows by the run.
- A multi-select's runs of tags stand in the field's line as one run does, centred: the first and the last keep the same room from the label and the rule whatever the count (four tags rested on the rule). With a pointer the runs stand the tags' gap apart; they touched, a pill being taller than a pointer's floor. On touch the floor already parts them.
- A date range picker writes its days in the app's digits (`RawCalendarDayDetails.label`), Arabic-Indic in Arabic, as the date picker does. `LedgerDateTab` writes its day the same way.

## 0.5.0

- Needs ui_core 0.5.1.
- Parameters take the names Flutter gives the same thing. A field's words are named as `InputDecoration` names them: `labelText`, `hintText`, `helperText` and `errorText`. Each parameter's field takes the new name too. `dart fix --apply` makes every rename below; `ledger_ui`'s `lib/fix_data.yaml` holds them.
  - `light` → `theme`: `LedgerHost`, `LedgerPreview`
  - `dark` → `darkTheme`: `LedgerHost`, `LedgerPreview`
  - `activeIndex` → `selectedIndex`: `LedgerPreview`
  - `dark` → `darkData`: `LedgerTheme`, `AnimatedLedgerTheme`
  - `placeholder` → `hintText`: `LedgerTextInput`
  - `placeholderStyle` → `hintStyle`: `LedgerTextInput`
  - `destructive` → `isDestructiveAction`: `LedgerSheetAct`
  - `label` → `labelText`: `LedgerDatePicker`, `LedgerCodeField`, `LedgerCombobox`, `LedgerFileUpload`, `LedgerInputGroup`, `LedgerField`, `LedgerChequeAmount`, `LedgerStepper`, `LedgerMultiSelect`, `LedgerPasswordField`, `LedgerSelect`, `LedgerTextArea`, `LedgerTextField`
  - `today` → `currentDate`: `LedgerDatePicker`, `LedgerDateRangePicker`
  - `helper` → `helperText`: `LedgerCodeField`, `LedgerCombobox`, `LedgerInputGroup`, `LedgerStepper`, `LedgerMultiSelect`, `LedgerPasswordField`, `LedgerSelect`, `LedgerTextArea`, `LedgerTextField`
  - `error` → `errorText`: `LedgerCodeField`, `LedgerCombobox`, `LedgerInputGroup`, `LedgerStepper`, `LedgerMultiSelect`, `LedgerPasswordField`, `LedgerSelect`, `LedgerTextArea`, `LedgerTextField`
  - `hint` → `hintText`: `LedgerCombobox`, `LedgerCommandPalette`, `LedgerComposer`, `LedgerFileUpload`, `LedgerInputGroup`, `LedgerSearchField`, `LedgerSearchEntry`, `LedgerField`, `LedgerMultiSelect`, `LedgerPasswordField`, `LedgerSelect`, `LedgerTextArea`, `LedgerTextField`
  - `labelOf` → `displayStringForOption`: `LedgerCombobox`, `LedgerMultiSelect`
  - `count` → `pageCount`: `LedgerPageDots`
  - `index` → `page`: `LedgerPageDots`
  - `current` → `currentStep`: `LedgerStepProgress`
  - `multiple` → `multiSelectionEnabled`: `LedgerToggleGroup`
  - `allowEmpty` → `emptySelectionAllowed`: `LedgerToggleGroup`
  - `onChanged` → `onSelectionChanged`: `LedgerToggleGroup`
- Removes the members deprecated since 0.2.0 and 0.4.1, which the package no longer used. No `dart fix` moves them; each deprecation named its replacement.
  - `LedgerChromeMetrics.sheetCloseHang`, `emptyBodyTop`, `emptyBodyLine`, `emptyActTop` and `pressSink`.
  - `LedgerHitSlop`: use ui_core's `DesignTapTarget(minSize: Size.square(target), child: child)`.
- A multi-select's help and error are read on its field: its entry joins the field's node, with its name. A combobox's and a multi-select's entry says whether its list stands open (expanded or collapsed). The parts' `LedgerEntryOpen` carries it to a text field's entry.
- A select opened from the keys focuses its chosen option as the option mounts, and the list keeps it in view, with no post-frame focus.
- A field marked invalid with no words to say why (ui_core's `RawInputDecorator.invalid`) is ruled in the danger red, as one with an error is.
- A pushed page's masthead on the desktop keeps its title under the crumb at a text scale under 1. The gap under the crumb gave up more than it had, a negative height that threw in debug builds.
- Diagnostics name `displayStringForOption` and `onSelectionChanged` as the parameters are named.

## 0.4.1

- Needs ui_core 0.4.1.
- The blank page's words stand on its rules. Its head is left unruled; the title's last line stands on the first rule, each line of the body on the rules after it, and the act's words on a rule, on the act's own paper. The ruling runs whole across the page, where it broke round each block of words. This applies to `LedgerEmptyState` and `LedgerErrorState`.
- `LedgerErrorState` rules its margin in the vermilion, where a faint red read as the empty page's green.
- `LedgerEmptyState`'s green margin crosses the rules in one ink. Before, each crossing printed a darker knot by day and a lighter one by night.
- `LedgerTextArea`'s hint and first line stand on its first line. Before, they stood half a box down, with a rule through the hint.
- A sheet or dialog centred on a desk stands on whole pixels, so its hairlines print crisp.
- A held filled button shows the press past its hover, with or without a pointer. A filled face sinks a quarter of the way into the page's ink. A key already in the ink (`LedgerButton.ink`) goes deeper still: darker by day, lighter by night.
- `LedgerDialog` takes `actions`, a list of `LedgerDialogAction`s in place of the two labels. They share the card's width, or stack across it with the last on top when their words don't fit. `LedgerDialog.showActions` raises one and completes with the pressed action's `value`. The slip carries one filled seal: the `isDefaultAction`, or with none a destructive action. A destructive action beside the seal is ringed in the vermilion. The two-label form is unchanged.
- Deprecates `LedgerChromeMetrics.emptyBodyTop`, `emptyBodyLine` and `emptyActTop`, which the package no longer uses.

## 0.4.0

- Needs ui_core 0.4.0 and Flutter 3.47. `ledger_ui` re-exports ui_core, whose types now take `Raw` names (`DesignPressable` is `RawButton`). The old names stay through ui_core 0.4 as deprecated typedefs, and `dart fix --apply` renames them.
- `LedgerRadio` is a Flutter `RawRadio`. Under a `RadioGroup` it is one of the group's radios, as Flutter's `Radio` is: the group holds the choice, Tab reaches the group at its choice, and the arrows move and choose (with ui_core's `RadioGroupKeyboardFix` inside the group). Alone it takes `groupValue` and `onChanged` as before, both now optional, and a new `enabled` turns it off.
- `LedgerSegmentedControl` and a `LedgerToggleGroup` of one choice are Flutter's `RadioGroup`, each chip or pill a `RawRadio`, with ui_core's `RadioGroupKeyboardFix` inside. They answer Tab, the arrows, Home and End as before. A chip reads as a radio, where it read as a button as well. A radio shows its focus as Flutter's `Radio` does.
- `LedgerTooltip` is Flutter's `RawTooltip`, with ui_core's `RawTooltipFocusFix` and `RawTooltipPlacement`. It fades on Flutter's tooltip timing, and each tooltip along a row of controls waits its half second.

## 0.3.3

- A pressed control stays where it is drawn; its ink deepens instead of moving, and the bare paper of its face takes the same ink. A press now shows over a hover on every control, by day and by night, including those it barely changed or left as they were: the tab bar's tabs and Move disc, tabs, the check, ringed, icon and text buttons, the back button, menu commands, disclosures, page dots and page numbers, the select, the side bar, breadcrumbs, a heading's link, the file picker and a multi-select's remove cross.
- Adds `LedgerImpression`, which deepens a held control's ink in place and, given a `wash`, the paper under it.
- Filled buttons no longer cast a shadow: `LedgerThemeData.primaryShadow` is empty in every Ledger theme.
- The tab bar's Move disc no longer casts a shadow: `LedgerThemeData.discShadow` is empty in every Ledger theme.
- A held menu command's underline thickens.
- In a text field with a trailing button (the password field's Show password, a copy button), the text box now carries the field's label and help for a screen reader, and the button keeps its own name.
- Deprecates `LedgerChromeMetrics.pressSink`, which the package no longer uses.
- The example bank is named Wren, and the test files are named for what they check.
- Radios of one choice are one Tab stop: Tab lands on the chosen radio (the first that can be chosen when none is), the arrow keys move and choose, wrapping at the ends and skipping disabled options, and a second Tab leaves. Group sibling `LedgerRadio`s with ui_core's `DesignRadioGroup` where you keep their choice; each radio keeps the `focusNode` you give it.
- `LedgerSegmentedControl`'s segments, and a one-choice `LedgerToggleGroup`'s pills (unless `allowEmpty`), are radios of one group: screen readers announce each as a checked or unchecked radio, and all four arrow keys move and choose. Home and End choose the first and the last pill.
- A checklist's `LedgerCheck` is announced as a checkbox, no longer as a button too.
- Stands on ui_core 0.3.4.

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

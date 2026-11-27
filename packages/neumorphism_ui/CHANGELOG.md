## 0.8.0

- Requires ui_core 0.8.2.
- A field turning wrong, or right again, eases where it changed in one frame: its failure line fades in as the room
  under the field opens, so what stands below slides rather than jumps, and the error mark at its end fades in as the
  entry gives it room; a date field's calendar crosses to the mark. A field's label lights in the pigment's ink as the
  field takes the focus, easing across as its groove deepens. Under Reduce Motion each cuts.
- New `NeumorphicAppShell`, the app's frame, on ui_core's `RawAdaptiveShell.branches`: its places in the raised tab
  bar on a phone and a tablet and on the pilaster down the start edge from 1024 wide, each place keeping its own stack
  of pages, the one shown pressed into the wall. A page pushed in a place keeps the pilaster beside it while the tab
  bar steps away (`hideBarOnPush`); back pops it. Toasts keep clear of the tab bar.
- `NeumorphicHost` moves to the main library, under semver (it was in `neumorphism_host.dart`), and is the one mount:
  it takes a `palette` and picks the theme for the brightness in force from it, and eases a change of palette or
  appearance (a cut under Reduce Motion). Its `light` and `darkData` are `theme` and `darkTheme`, Material's names.
  `dart fix --apply` makes the renames.
- `NeumorphicChromeMetrics` (the density's line, `lineOf`, and the tap floor in effect, `targetOf`) moves to the main
  library, under semver: an app built on `neumorphism_ui.dart` needs nothing from `neumorphism_host.dart`.
- Palettes: `NeumorphicThemeData.palettes` is the six as ui_core's `RawNamedPalette` (an `id` to store, a `label`
  to show, swatches by day and by night), for an app's palette picker. `NeumorphicThemeData.presets` is removed: read
  `NeumorphicThemeData.palettes.map((p) => p.id)`. `NeumorphicThemeData.preset` takes an id it doesn't know (a
  stored one from an older build) as the first palette, porcelain, where it threw.
- New `NeumorphicRadio.suffix`: a part that follows the words, right beside them at any width (a palette's swatches
  in a palette picker). It is drawn, not read; the label names the choice.
- New `NeumorphicTextFormField`, a `FormField` with `validator`, `onSaved` and reset, and `NeumorphicDateField`, a
  nullable day in a field's groove, shown with its year ("Nov 26, 2026"), picked from the look's calendar. New
  `NeumorphicFormat.mediumDate` writes a day the same way. New glyph `NeumorphicGlyphs.pencil`.
- A wrong field shows the error's mark at its end, in the error's ink, and its message leads with the mark: the field
  itself reads as wrong, not only its message.
- Form fields take their column's width at every size, as a text field does: a select and a select field too, as
  Material's dropdown in a form. One alone in a row (a filter) keeps to its content.
- A name only a screen reader hears is `semanticLabel`; `label` is kept for words a part draws. Renamed on
  `NeumorphicIconButton`, `NeumorphicRoundButton`, `NeumorphicTap`, `NeumorphicSwitch`, `NeumorphicSlider`, `NeumorphicCheckbox`, `NeumorphicChoiceBox`, `NeumorphicTabBar`, `NeumorphicPageDots`, `NeumorphicRating`, `NeumorphicCarouselView`, `NeumorphicScrollArea`, `NeumorphicDataTable`, `NeumorphicTreeView`, `NeumorphicPopover`, `NeumorphicHoverCard`, `NeumorphicMenuBar`, `NeumorphicContextMenu`, `NeumorphicMenu`, `NeumorphicWheelPicker`, `NeumorphicButtonGroup`, `NeumorphicToggleGroup`, `NeumorphicNavigationRail`, `NeumorphicNavigationDrawer`, `NeumorphicSkeleton`, `NeumorphicMedia`, `NeumorphicAvatarGroup`, `NeumorphicBadge`, `NeumorphicLoadingState`, `NeumorphicCircularProgressIndicator`, `NeumorphicTimeline`, `NeumorphicDescriptionList`, `NeumorphicPanel`, `NeumorphicTable`, `NeumorphicTableRow`, `NeumorphicChart`, `NeumorphicPieChart`, `NeumorphicSparkline`, `NeumorphicLineChart`, `NeumorphicBarChart`, `NeumorphicAreaChart`, `NeumorphicRadioGroup` and `NeumorphicSegmentedButton` (each constructor). `dart fix --apply` makes the renames.
- A control inside `NeumorphicFormField` is heard once, by the field's label. A `NeumorphicListTile` that opens says
  its title, its line, its note and its trailing status (a `NeumorphicStatus`, a `NeumorphicTag` or a `Text`), and
  leaves out its mark, which repeats the title; its `action` stays a stop of its own.
- New `NeumorphicScaffold.maxWidth` (`neumorphicPageMaxWidth`, 1264, by default): the bar's title and actions, the
  body and the footer hold to one column, centred on a wide window, its margins included.
- `NeumorphicDescriptionList` keeps each value beside its term up to 480 wide, at the start of a wider column, so a
  value never drifts to the far end of a desktop page.
- A grouped list's first row stands under the card's rim with no rule above it: the rim already closes it. After a
  section's label the first row keeps its rule.
- A list row whose trailing figure is wider than its share (a long `NeumorphicTag` on a phone) comes to rest: it was
  laid out at its share and at the row's width on every layout, so its shape flipped and `pumpAndSettle` timed out.
- A `NeumorphicListTile` whose title wraps keeps its trailing status and its action on one line: beside three lines
  of words both stand on the title's first line, beside fewer both stand on the words' middle.
- `NeumorphicIconWell`'s glyph grows with the reader's text, as a tag's words and a monogram's letters do, and the
  well grows round it: at 200% a 20 glyph is 40, in a 64 well.
- Removed `NeumorphicChromeMetrics.target`, `touchTarget`, `targetSize` and `padded`, deprecated in 0.7.0: read the
  floor in effect, `NeumorphicChromeMetrics.targetOf(context)` or `RawTapTargets.of(context).touch`. Removed
  `NeumorphicCalendar.maxMonthWidth`, deprecated in 0.7.0; a month is laid out up to seven days of the medium line.
  Both read the floor from a `BuildContext`, so `dart fix` cannot make the change.
- Removed `NeumorphicSheet.edge`, which drew nothing: the sheet is a slab, every corner round, and
  `showNeumorphicSheet(edge:)` stands it on the page's side. `dart fix --apply` drops the argument.
- The docs say what each part is in plain words.
- `example/lib/main.dart` is Shelf, one app to copy: the host, the shell with three places, a list with a pushed page,
  a form, a dialog and settings with the six palettes. The gallery is `example/lib/gallery.dart`. `example/lib/minimal.dart`,
  which mounted the theme without the host, is gone: the README's snippets compile as written.
- The README: the install line every snippet compiles after, the host, building an app (the shell, a list and its
  page, forms, dialogs and toasts, the palette picker) and the building blocks.

## 0.7.0

- Requires ui_core 0.7.2.
- Tap targets follow ui_core's floor (`RawTapTargets`): every control lays out at least 40 square, ui_core's touch floor, on every platform. An app's `RawTapTargetScope` raises it. Before, 48 square.
- A medium control in a line (a button, a field, a select, a switch, check or list row, a round key, a picker's day, a segment) stands at `NeumorphicChromeMetrics.lineOf(context)`: the density's height, 48 standard, 44 comfortable and 40 compact (the desktop default), never under the floor. Before, every one stood at 48.
- `NeumorphicTheme` declares the floors it stands on, ui_core's (`RawTapTargets.fallback`), in a `RawTapTargetScope` for its subtree, unless the app declared its own above it. Before, only `NeumorphicHost` declared one, of 48.
- Deprecated: `NeumorphicChromeMetrics.target`, `touchTarget`, `targetSize` and `padded`, which name only the default floor or a platform's habit. Read the floor in effect, `NeumorphicChromeMetrics.targetOf(context)` or `RawTapTargets.of(context).touch`. The first three are now getters, no longer constants. Deprecated too: `NeumorphicCalendar.maxMonthWidth`; a month is laid out up to seven days of the medium line.
- `NeumorphicLocalizations.less` and `.more` are no longer deprecated: a dial's step keys say them.
- `NeumorphicBreadcrumb` lays out as ui_core's chip group (`RawChipGroup`): each crumb's reach takes the room between the faces, so the crumbs stand 4 apart as drawn and a trail that wraps starts each line at its start edge. Before, each crumb's reach was added to the spacing.
- `NeumorphicThemeData.from` derives its palette with ui_core's palette maths (`RawPalette`). The wall keeps the ground's hue at a plaster's lightness (tone 85 to 93 by day, 10 to 20 by night); the words, the pigment's ink and the bars each take the nearest tone of their own hue that reads on every face and well; and a filled control carries white words by day and the wall's own ink by night. Before, they were mixed toward black or white until they read.
- A sixth palette, capri: `NeumorphicThemeData.capri()`, a sea-grey wall with Capri's blue-green, and the same blue-green lit over slate at night. `NeumorphicThemeData.presets` lists the six, porcelain first.
- `NeumorphicTypeface.fallback`: the families to draw a script the faces lack, given to every text style and to the Material theme the look builds, as `ThemeData.fontFamilyFallback` does.
- `NeumorphicLocalizations` in a language it does not ship writes numbers and percentages in the app's digits and separators (ui_core's `formatDecimal` and `formatPercent`): Arabic-Indic in Arabic, `1.240,5` in German. Before, intl's Western digits. A date picker's and a time picker's titles there are in the app's language (ui_core's `RawPickerWords`); before, "Choose a date" and "Choose a time" in every language. English reads as before.
- `NeumorphicSelectField` keeps 8 pixels of its well above and below its words at large text sizes, as a text field does. Before, at twice the size its words filled the well edge to edge.
- A `NeumorphicBanner` with a close key stands its mark and its title on the key's middle at every density. Before, they stood above it: 8 pixels on a phone, 4 on a desk.
- The README opens with a first app of ten lines; the example's Colour roles page shows the six palettes.

## 0.6.3

- Requires ui_core 0.6.1.
- `NeumorphicTimePicker` writes its time and its hour and minute keys in the app's digits, through ui_core's `formatHour`, `formatMinute` and `formatDecimal` (`RawTimeFormatting`), as its calendar's days are: in Arabic 9:05 reads ٩:٠٥ ص, in Persian ۹:۰۵ ق.ظ., with or without `NeumorphicLocalizations.delegate`. They were written in Western digits in Arabic (intl's Arabic writes them so, and with no delegate the numbers were English's). The face, the half day's words and English are as before.
- `NeumorphicPagination`'s page keys write their pages in the app's digits (ui_core's `formatDecimal`), as their spoken names already did.

## 0.6.2

- Keyboard focus by night lights a long part (a wide button, a field, a stepper) with a soft light that falls off over several pixels, as it lights a small part and as every relief light does. Before, a focused part at least 40 tall and half again as wide drew its light as a hard-edged copy of its outline, with a notch at its lower corner. Day drawing is unchanged.

## 0.6.1

- The light stands at the top start: the top left, and the top right under a right-to-left `Directionality`. Every relief takes its light and shade from it, raised, pressed in, pressed down, focused and out of use, on every part (buttons, fields, cards, switches, sliders, segmented buttons, calendar days, dialogs, sheets, toasts and the rest), so a part right to left is the mirror of itself left to right, through a press as at rest. Before, the light stood at the top left in either direction. Left-to-right drawing is unchanged.
- `NeumorphicTheme.of` and `maybeOf` place the light by the `Directionality` where they are read.

## 0.6.0

- Requires ui_core 0.6.0, whose `Design*` names are `Raw*` now (`RawTapTargets`, `RawInventoryEntry`, `RawModalDialogRoute` and the rest). `dart fix --apply` renames them in an app (ui_core's `lib/fix_data.yaml` holds them); Neumorphism's code, docs and examples use the new names.
- A calendar writes its days in the app's digits (`RawCalendarDayDetails.label`): Arabic-Indic in Arabic, as its dates and times already were.
- A three-line `NeumorphicListTile` stands its key at the top a little lower, so the key's light no longer reaches the divider above the row.

## 0.5.0

- Needs ui_core 0.5.1.
- Field words take `InputDecoration`'s names: `label` is `labelText`, `hint` (and `NeumorphicSelect.prompt`) is `hintText`, `helper` (and `NeumorphicFormField.help`, `NeumorphicFormGroup.help`, `NeumorphicNumberField.note`) is `helperText`, and `error` is `errorText`, on `NeumorphicTextField`, `NeumorphicSearchField`, `NeumorphicTextArea`, `NeumorphicPasswordField`, `NeumorphicInputGroup`, `NeumorphicInputOtp`, `NeumorphicSelect`, `NeumorphicCombobox`, `NeumorphicMultiSelect`, `NeumorphicFormField`, `NeumorphicFormGroup`, `NeumorphicNumberField`, `NeumorphicInput` and `NeumorphicCommand`. `dart fix` renames them.
- `NeumorphicTextField.lines` and `NeumorphicTextArea.lines` are `maxLines`, as `TextField` names it. `dart fix` renames them.
- `NeumorphicCheckbox.error` and `NeumorphicCheckRow.error` are `isError`, as `Checkbox` names it. `dart fix` renames them.
- `note` is `subtitle` on `NeumorphicCheckRow`, `NeumorphicSwitchRow` and `NeumorphicDisclosure`, as `CheckboxListTile`, `SwitchListTile` and `ExpansionTile` name it. `dart fix` renames them.
- `NeumorphicCombobox.displayString`, `NeumorphicMultiSelect.displayString` and `NeumorphicWheelPicker.itemLabel` are `displayStringForOption`, as `Autocomplete` names it. `dart fix` renames them.
- `NeumorphicDatePicker` and `showNeumorphicDatePicker`: `first`, `last` and `today` are `firstDate`, `lastDate` and `currentDate`, as `showDatePicker` names them. `dart fix` renames them.
- `NeumorphicChromeScope.active` is `selectedIndex`, as `NavigationBar` names it. `dart fix` renames it.
- `NeumorphicChip.enabled` is `isEnabled`, as `InputChip` names it. `dart fix` renames it.
- `NeumorphicScrollArea.alwaysShown` is `thumbVisibility`, as `Scrollbar` names it. `dart fix` renames it.
- `NeumorphicLevelRow.onLevel` is `onLevelChanged`, beside the row's `onChanged`. `dart fix` renames it.
- The form wiring leaves the public API: `decorate`, `failureLine` and `nameOnly` on `NeumorphicTextField`, and `decorate` and `failureLine` on `NeumorphicSearchField` and `NeumorphicInputOtp`, are gone. A field in a form takes its words from the `NeumorphicFormField` around it.
- `NeumorphicTheme` is a `const` `StatelessWidget` over a private inherited theme, as `Theme` is. Read it with `NeumorphicTheme.of` or `maybeOf`; `dependOnInheritedWidgetOfExactType<NeumorphicTheme>()` no longer finds it.
- `NeumorphicThemeData` carries a `motion` (`copyWith(motion: ...)`), which `NeumorphicMotion.of` and the page transitions read. Before, a `NeumorphicMotion` you built reached nothing.
- `NeumorphicMultiSelect.onChanged` may be null: the field is then out of use, its chips without a ✕ and its field taking no typing, as other controls with no callback are.
- `NeumorphicScrollArea.controller` is optional. Without one, the area makes its own and hands it to its scroll view as the `PrimaryScrollController`, so `NeumorphicScrollArea(child: ListView(children: rows))` scrolls with the area's bar and keys.
- `NeumorphicCalendar` and `NeumorphicDateRangePicker` work without a `controller`: give `firstDate` and `lastDate` (and `initialDate` or `initialDateRange`), and read the choice in `onChanged`.
- `NeumorphicColorPicker.controller` is optional, with the new `initialColor` and `onChanged`; `onChanged` also tells the changes of a controller handed in.
- A controller handed to any of these is the caller's and is never disposed; one handed in or taken away while the part shows takes over.
- A field's label names it for a screen reader, and its help and error are said on its input, with the field marked invalid while in error, also with no words (ui_core's `RawInputDecorator`).
- A combobox's and a multi-select's text input say whether their list is open (expanded).
- A date picker opens with its chosen day focused: `showNeumorphicDatePicker`, and `NeumorphicDatePicker` with the new `autofocus`.
- Toasts keep clear of the navigation bar and a page's footer (ui_core's `RawToasterKeepClear`), rising and settling as the bar comes and goes. A bar of your own does the same wrapped in `RawToasterKeepClear`.
- A chart's first series prints in the look's pigment, flat, by night in its night step, at 3:1 or more on every surface (where the other two inks need the room, a few L* lighter or darker); the other series step from it in its hue. Bars lose their ink outline; a zero stands as a 2 px stub on the baseline. Before, the series printed in the text ink.
- A chart's gridline labels write as many decimals as the step needs, in the reader's digits, and its readout and what a screen reader hears write the values the same way (ui_core's `DesignChartValueFormat`).
- A `NeumorphicListTile` of three lines or more (a title, its subtitle and a note, or words that wrap) stands its mark and its `action` at the top by itself, as Material 3's list items do, both on the middle of the title's first line. `top` still does it for a shorter row.
- A `NeumorphicSheet`'s actions stand side by side at the end while they fit and otherwise stack, each as wide as the sheet, the main one on top, as a dialog's do. Before, a sheet's actions wrapped onto a second line at their own widths.
- A `NeumorphicSectionHeader`, and so a `NeumorphicCard`'s title, tells a screen reader it is a heading, as a `NeumorphicListSection`'s label already did. Before, it read as plain text.

## 0.4.3

- A `NeumorphicListTile`'s compact `action` (an icon key, no wider than its touch target) stays at the row's end, beside its words, at every width, the selected plate running under it, and the row keeps the height it has without it. Only a wider action (a `NeumorphicButton` with words, a `NeumorphicNumberField`) goes under the words in a tile narrower than 520. At large text in a narrow tile the title wraps word by word first; the key goes under the words only when the title's widest word can't fit beside it. Before, below 520 wide every action went under the words, and each row grew.

## 0.4.2

- Stands on ui_core 0.4.1. A menu entry marked `isDestructiveAction` (Remove, Delete) in a `NeumorphicMenuBar` or a `NeumorphicContextMenu` takes the danger tone, its warning mark in the glyph slot, as `NeumorphicMenu`'s destructive entries do.
- A selected `NeumorphicListTile` that opens and holds an `action` (a row's menu key) is pressed in under one plate that runs to the row's end, with the action inside it. The action stays a key of its own: a screen reader hears the row and the action as two buttons, and a tap on the action presses only the action.
- By night, a focused field's well stands deeper than one at rest, as plainly as by day: the lit lip along its bottom and end lifts toward twice its reach. In 0.4.0 and 0.4.1, a focused field by night looked the same as one at rest.
- A `NeumorphicButton.filled` or `NeumorphicRoundButton.filled` with no `onPressed` lays its pigment down and stands as a plain key or cap out of use. It keeps the act's size, its glyph included, so its row doesn't shift. Before, it kept a pale pigment face, half raised.
- `NeumorphicErrorState` stands in a well, as `NeumorphicEmptyState` does, and its dome carries a glyph: a triangle alert by default, or the new `icon`. Before, its dome was bare.
- The bars of `NeumorphicColumnBars`, `NeumorphicTwoWayBars` and `NeumorphicShareBars` are printed in one flat ink. Before, they were shaded from top to foot, like tubes.
- Charts read in the page's direction. In right-to-left text, `NeumorphicColumnBars`, `NeumorphicTwoWayBars`, `NeumorphicStepLine`, `NeumorphicLineChart`, `NeumorphicBarChart`, `NeumorphicAreaChart` and `NeumorphicSparkline` run from the right, with their scale on the right. Before, they ran left to right in every language.
- A `NeumorphicColumnBars` with nothing above zero stands on a scale of round steps from 0 to 1. Before, every gridline read 0. Its gridlines also write as many decimals as the step needs, so a quarter step reads 0.25 rather than 0.3.
- `NeumorphicTextTheme` is a value: it has `==`, `hashCode`, `copyWith` and `lerp`.
- `NeumorphicColors` has `copyWith`, and is marked `@immutable`.

## 0.4.1

- When a `NeumorphicDialog`'s or a `NeumorphicBottomSheet`'s keys don't fit side by side (long labels on a phone, large text), they stack, each as wide as the slab, the main one on top. Before, they stacked at their own widths at the end, a staircase.

## 0.4.0

- **Breaking:** stands on ui_core 0.4.0. Flutter 3.47 or later, as before.
- **Renamed:** the ui_core types in this package's API take ui_core 0.4.0's `Raw` names. For example, `NeumorphicContextMenu.menuChildren` is a `List<RawMenuEntry>`, and `showNeumorphicToast` returns a `RawToastController`. The old names still work as deprecated typedefs, and `dart fix --apply` renames them.
- `NeumorphicRadioGroup` is built on Flutter's `RadioGroup`, with a `RawRadio` for each option. The keys work as before. As with Flutter's `Radio`, a radio shows hover and focus while focus highlights are traditional (on a desktop, or once a mouse or a key was used), so its focus also shows after a mouse click. On iOS and macOS an unchosen radio reads as not selected.
- `NeumorphicTooltip` is built on Flutter's `RawTooltip`. It shows on hover after its wait, on keyboard focus and on a long press, and fades in and out on the look's spring, as before. Run the pointer along a row of controls, and each tip waits its turn, as Flutter's do. Before, the next tip showed at once. A press hides a tip the pointer brought, as Flutter's do; before, the tip stayed while the control was held.
- Keyboard focus on a field, a text area, a select or any other well deepens it softly again, as in 0.3.1: its inner shadow grows a little longer and darker, with no crisp shade and light along its rim. A checkbox's box, a radio's socket, a switch's slot and a slider's groove deepen the same soft way. Raised parts still rise for focus.
- An empty checkbox prints no rim. It reads by its moulding alone, as every part does, and high contrast still prints its edge.

## 0.3.5

- A focused checkbox, radio or switch now stays in the wall. The checkbox's box and the radio's socket go deeper, with a crisp shade inside the rim, and the switch's thumb rises inside its slot while the slot goes deeper. In 0.3.2 to 0.3.4, a raised plate grew round them on focus. A check row or switch row outside a grouped list shows focus the same way, in its box or its switch. A grouped row still rises as a band.
- Inside a focused card, list row or key, the hollows (an icon's well, a picture's window) keep their depth. Only the part with focus rises, so focus no longer appears twice.
- A disabled part keeps its moulding. Its colours move halfway toward the wall, so its relief is half as strong and its words are quiet. Previously a disabled button, field, radio or switch lay flat, some with a hairline edge. A carousel's step key at either end is now a disabled key, rather than a flat ring.
- A radio group takes its keyboard from ui_core's shared radio group, as every look's does. Tab enters on the chosen option, or on the first one you can choose, and a second Tab leaves the group. The arrow keys move and choose, wrap at the ends and skip options that are out of use; in right-to-left text, Left moves forward. Home and End no longer jump to the first or last option in a radio group. Use the arrows instead.
- A selectable row in a table, such as a room you can pick, reads to a screen reader as a checkable row rather than a button.
- Stands on ui_core 0.3.4.
- Comments and test names describe the code rather than how it was reviewed.

## 0.3.4

- A focused text field, text area, search field, select, number field, date segment, code cell or other well now stays inset. It goes deeper, with a crisp shade inside its rim, and a field's label turns to the pigment's ink. In 0.3.2 and 0.3.3, focus raised the well off the wall, so a focused field read as a raised slab with a heavy shadow. Buttons, keys, chips, toggles, rows and other raised parts still rise when focused.
- A focused slider raises its thumb, as in 0.3.1. Its groove now stays inset and goes deeper round the thumb, where 0.3.2 raised it with the thumb.

## 0.3.3

- `NeumorphicLocalizations.delegate` now serves every locale. It served English alone, so an app in another language that installed it was warned at startup that its locale had no Neumorphism delegate. With it installed, dates and numbers are the app's locale's (English where `intl` lacks it), and the time picker names its hour, minute and day-period wheels, and says AM and PM, in ui_core's `DesignLocalizations` words for the reader (German's Stunde), as Done, Try again, a field's required mark and a table's sort hints do. An English app keeps Neumorphism's own words ("Morning or evening"), and an app's own `NeumorphicLocalizations` still wins.

## 0.3.2

- `NeumorphicFormField` now keeps each control of a group in its own semantics node, under the field's label. This covers a segmented button, radios, choices, a toggle or button group, and chips in a row or wrap. Previously the field merged the group into one node, so with semantics on (a screen reader, or a web app with semantics enabled) every tap went to the group's first control. The field now decides by its child. Set `group` to choose yourself. A group that names itself in the field's words, such as a segmented button labelled as its field, is announced once instead of twice.
- A select, combobox or chips input now opens its list 8 apart from the field, above or below. While the list is open, the field stays at rest, and it rises again once the list closes and the field still has focus.
- `showNeumorphicDatePicker` now fits its sheet to the month on wider windows, so the month, its arrows and the sheet's buttons span the same width. A day that ends up under a resting pointer as the sheet opens stays at rest until the pointer moves.
- At night, a long focused part (a stepper's groove, a wide button) rises with a crisp light along its lit edge instead of a wide soft light, so it no longer reads as a glow beside its neighbours.
- Keyboard focus now shows by raising the focused part, with deeper and sharper shadows in its own light and shade. The pigment glow and the extra line are gone. This applies to buttons, keys, toggles, chips, tabs, segments, rows, sliders and fields. A focused field now rises around its well. A focused slider now raises its groove and thumb together.
- In every menu (split button, menu bar, context menu, select and combobox), a hovered row now sits as one soft, even hollow inside the panel, with corners that follow the panel's. The row the keys reach sits a little deeper, and no row glows. Menu panels have tighter padding: 6 around the rows and 10 to either side of a row's words.
- The chips input now puts its cursor on the same line, after the last chip, and wraps to a new line only when that line is full. The field is no taller than its chips need, and the first chip stays the same distance from the field's top and side. Its suggestions now sit within the panel as flat rows.
- `NeumorphicNumberField` now shows its number, with its unit after it, in a groove as tall as its keys, with a gap on either side. When focused, the groove rises.
- `NeumorphicDialog`, opened with `showNeumorphicDialog`, now moves focus to its first action (the dismissive one), unless its content has already taken focus. This means Enter and Escape work straight away. That focus shows after a keyboard open but not after a touch.
- Tappable list tiles announce their title, subtitle and note together. Set `NeumorphicListTile.semanticLabel` for a custom name.
- Split menus open at the reading-order start of the button in both left-to-right and right-to-left layouts.
- Phone navigation labels use the requested text size and wrap into additional rows. Thermostat settings stay on the face at larger text sizes, with longer descriptions below.
- `showNeumorphicDatePicker` accepts a `today` date. The gallery uses the same Today marker in its inline calendar and sheet, and shows renewal dates in Arabic when reading right to left.
- Hearth retains saved account details between screens, sends the order receipt to the saved address, and identifies missing delivery fields before placing an order.

## 0.3.1

### Fixed

- Fixed the flat, square-edged rectangle inside text fields, Hearth’s stat tiles and other pressed wells. The inset shadow now fades smoothly from the rim underneath the content, including when a field has focus.
- Opening a split button now sinks only its chevron in the button’s own colour. Its menu fits the button and its actions, and text-only actions no longer start after an empty icon slot. Pressed keys and menu rows with custom fills keep their own colour at the rim.
- Unchecked checkboxes now have a visible rim in day and night, including the gallery’s “Include a receipt” option.
- If you call `neumorphicPaintPressed` or `neumorphicPaintCast` directly through `neumorphism_parts.dart`, remove the former `contentBounds` and `outlineRadius` arguments.

## 0.3.0

Built on ui_core 0.3.0. Neumorphism's dialog, sheet pages, tabs, tooltip, number field, wheel picker, rating and
charts now take their behaviour from ui_core (focus, keys, meaning to a screen reader, gestures and springs) and keep
the look's paint: they look as they did, and they do more. A context menu is new, and a combobox can search.

### Breaking

- `NeumorphicNumberField` is a number field on ui_core's `DesignNumberField`: `value` is a `double?` and `onChanged`
  a `ValueChanged<double?>` (null when the field is emptied), with `min`, `max`, `step`, `label`, `focusNode` and
  `autofocus`; `onDecrease` and `onIncrease` are gone. The figure is written in the reader's digits and separators
  (Arabic-Indic under `ar`, where 0.2.1 wrote ASCII) and takes typing in them or in ASCII (taken on Enter or as the
  focus leaves), Up and Down step it, Page Up and Page Down ten steps, and a held key repeats and stops at `min` or
  `max`. With focus the figure sinks into a well, as a field's groove is pressed in; at rest it is the bare figure it
  was.
- `NeumorphicRating`'s `onChanged` can report 0: Home clears the score.
- `NeumorphicTooltip` and `NeumorphicWheelPicker` are `StatelessWidget`s, on ui_core's `DesignTooltip` and
  `DesignWheelPicker` (a `GlobalKey<State<...>>` no longer fits them). Their constructors are unchanged.
- `NeumorphicSheetPage` raises ui_core's `DesignBottomSheetRoute` on a phone and `DesignDialogRoute` on a desktop,
  no longer Flutter's `ModalBottomSheetRoute` and `RawDialogRoute`: code that tells a sheet by its route's type
  checks for these.

### Behaviour that changes

- A dialog rises a step and fades in on a spring as long as the theme's `raise`; Tab stays inside it, its title names
  it for a screen reader, and the focus goes back to what opened it. Under Reduce Motion it dissolves where it
  stands, where it cut.
- A sheet page on a phone follows a finger down and away, its screen's list handing the drag over at its top; on
  both a phone and a desktop it closes on Escape and gives the focus back.
- `NeumorphicTabBar` is heard as a tab bar of tabs, each with its place ("Week, Tab 2 of 3"), where each was a
  button; it is still one stop for Tab, on the chosen tab, and the arrows, Home and End still choose. A press on the
  chosen tab no longer reports `onChanged` again.
- The rating is one stop: a tap or a drag across the stars sets it, hovering shows the score a tap would give, the
  arrows, Home, End and the digits set it, and a screen reader hears a slider.
- The wheel picker turns by Page Up and Page Down, Home and End and a typed letter as well as the arrows, a tap on a
  row turns it there, and it ticks as rows pass on a phone. A press on it gives it the keys; its well deepens with
  the keyboard's focus only.
- A chart is one stop: the arrows walk its samples (a donut's slices), Escape lets go, a finger scrubs or holds, and a
  screen reader steps the samples. The look's plot still reads left to right and its donut runs clockwise in every
  language.
- A tooltip stays while the pointer moves onto it, Escape puts it away, one shows at a time, and a pointer run along a
  row of keys reads each tip at once; after a long press it stays 1.5 s. A screen reader hears the tip on its
  control's own node, where it was a node of its own.
- The catalog's and the example's menu and palette keys are spelled by ui_core: `⌘ N` on Apple's platforms,
  `Ctrl+N` elsewhere, where they were written "Ctrl N". A row's keys read left to right, in the order they are held,
  in a right-to-left page too.
- `NeumorphicCommand` lights one row, its active one: the pointer moving onto a row makes it the active row, and a row
  the page scrolls under a still pointer no longer stands up beside it.

### New

- `NeumorphicContextMenu`: a menu over any region, opened at the pointer by a right click or a long press, at the
  focused control by Shift+F10 or the Menu key, and by a screen reader's Show menu; its rows, checks, submenus and
  dividers are the menu bar's.
- `NeumorphicCombobox` and `NeumorphicMultiSelect` take `search` and `debounceDuration`: options found over the
  network or in a database. While a search runs the list says it is loading; when one fails it says so and offers
  Try again, which Down then Enter, or a press, runs, the focus staying in the field.

### Fixes

- A tab the keys reach in a `NeumorphicTabBar` no longer scrolls the page until the bar sits on the window's top edge;
  when the bar is too long for its width, the bar alone scrolls, the least way that shows the tab whole.
- `NeumorphicRating` and `NeumorphicNumberField` in a stretching column are as wide as their stars and their row: a tap
  in the empty space beside the stars sets nothing, and a screen reader frames the field, not the column.
- A row in a `NeumorphicListSection` is focused and framed as the band of its card that it draws: keyboard focus, a
  screen reader's outline and the scroll to a focused row take the band, not just its words. The row takes the same
  room as before and draws the same pixels.
- `NeumorphicNavigationBar`'s chosen plate is concentric in the bar: 12 in from the bar's shoulders at the top and the
  ends alike, rounded by the shoulders' 20 less that inset. It stood 16 in from the ends under 12 from the top, a
  control's 12 corner out of round with the shoulders.
- `NeumorphicMultiSelect`'s first chip stands as far in from the well's top as from its side (it stood 3 lower).

### Deprecated

- `NeumorphicLocalizations.less` and `.more`: the number field's keys are the steps of its one node, with no words.

### Docs

- The package's homepage is the live gallery, and the README opens on Hearth by day at 1440 beside the same home by
  night on a phone, with links to the gallery, the API reference and all the looks. Every picture is linked by its
  full address, so pub.dev shows them all.

### Development

- The review checks come from `package:ui_core_test` (a dev dependency, 0.1.0), where ui_core 0.3.0 moved them.

## 0.2.1

- On iOS, Reduce Motion stills the look as Android's Remove animations and a browser's reduced motion do: a page
  change, a press and every part's move go straight to their end. Flutter gives iOS's setting apart from
  `MediaQuery.disableAnimations`, which the look read alone; `NeumorphicMotion.of` now reads both, through ui_core
  0.2.1's `designReduceMotionOf`.
- A date range picker's count of nights follows the app's language and its plural forms: the words come from
  `NeumorphicLocalizations.nights`, English by default ("1 night", "2 nights"), and a translation gives every form
  its language has with `Intl.plural`. It was English in every language.
- The package's tests come in three tiers. `flutter test --exclude-tags goldens,sweep` is the one to run on every
  change: each matrix of sizes, modes, directions and text sizes runs one case per page or part in turn, so every
  size, both modes, right to left and twice the text are still met. `--tags sweep` runs the rest of those matrices,
  and `--tags goldens` the pictures (recorded on macOS), before a release. The two largest matrices, which took over 5
  GB of one test process, keep no stack trace per object for leak tracking and are held to every leak instead.
- The example's drawer no longer makes an eased animation on every frame of its slide without disposing it.

## 0.2.0

A quality release: the parts behave, line up and hold their shadows as a designer would ship them, on phones,
tablets and desktops, by day and by night, right to left and at twice the text size.

- **Breaking:** `NeumorphicStyle` and `NeumorphicStyleOf` are ui_core's `DesignStyle` and `DesignStyleOf` under the
  look's names, so a style reads the same way in every look. Building, copying, merging and blending a style work as
  before.
- **Breaking:** `NeumorphicStyle.cascade` is now `NeumorphicStyle.layered`, and takes a list. The old name can't stay
  beside it as a deprecated alias (it would have to live on ui_core's `DesignStyle`), so `dart fix --apply` renames
  your calls.
- **Breaking:** every control stands at the platform's least tap target (48 on touch): a round key, a check, a
  switch, a star, a chip's cross and a field's own key take a press anywhere in it, and a screen reader outlines the
  same box. Faces keep their size and stand on the row's edges, so most screens look the same; a row packed tighter
  than the target grows to it.
- A press anywhere in a text field's well reaches its words, as a Material field's does.
- Fields, sheets and menus no longer crash in apps set to a language other than English; their built-in labels now
  follow the app's language. On iOS a field's copy and paste menu reads in it too.
- A part with no `NeumorphicTheme` above it takes Porcelain instead of throwing, so selecting text in a field whose
  theme sits under the app's `home` shows its handles and menu. `NeumorphicTheme.maybeOf` still returns null there.
- Every public widget and style lists its settings in Flutter's widget inspector, and a value out of range (a size
  below zero, a progress past 1, a month of 13, a meter whose low is above its high) fails an assert in debug builds,
  naming the value, instead of drawing oddly.
- A snack bar's first line and its glyph sit level with its act and dismiss keys.
- The gallery's calendar, table, tree, colour and scroll specimens let go of their controllers when they close; the
  tests run with Flutter's leak tracking.
- Every example in the API docs compiles and runs as a test, so the docs can't drift from the code.
- Shadows are never cut flat: swipe rows, the pilaster and the side bar clip only along the way they move, and the
  catalog's pictures and the gallery's framed phones keep a shadow's room round every part.
- A round key that ends a row (a sheet's close, a snack bar's dismiss, a calendar's next month, a search's clear)
  stands its face on the row's end edge.
- A sheet's or dialog's title keeps its words whole at large text, stepping its size down only as far as its longest
  word needs.
- A bottom sheet's barrier is outlined for a screen reader only over the screen above the sheet.
- A bank of push keys shares its keys evenly across its rows.
- A pagination is one row of keys: its steps take the pages' own face, size and gap at every width, and on a phone
  no two keys touch. A page held under a finger goes down toward the wall, never into a well, and comes back when it is let go, so it
  never reads as a second current page, and keyboard focus lifts a key's whole face.
- A pressed part's inset fades into its face along the part's own outline: a radio, a round icon well and a stat's
  well no longer show a square inside them, nor a field's round ends a box.
- A text field with an error carries the warning mark at its end, so the field that failed is plain at a glance.
- A chosen `NeumorphicChoiceBox` of one line carries its light at the line's end, where a radio's mark stands; a
  taller box keeps it in its corner.
- A `NeumorphicSwitchRow` or `NeumorphicCheckRow` in a `NeumorphicListSection` lifts its whole band of the card
  under keyboard focus, as a list tile does, and not a tight face round its words and control.
- Side by side, the sections of a `NeumorphicRow` are columns for the keyboard too: Tab walks a list to its end
  before the pane beside it, instead of zigzagging between them by height. On the web, Tab past the last control
  now leaves the page instead of starting again in the middle of it.
- On a phone or a tablet, Tab walks a `NeumorphicScaffold`'s page to its end before the app's tab bar or rail,
  instead of stepping out to the bar between rows the page had scrolled below it.
- Pages change in the look's own way on every platform: a page pushed over another fades up with a 16 px step from
  the reading end while the page under it holds still, and a pop runs it back. The look's own routes (a router's
  `NeumorphicPage`) change this way; an app's own `MaterialPageRoute`s do when its `ThemeData` lists
  `neumorphicPageTransitions` (the README's setup shows it), on macOS, Windows, Linux and the web too, instead of the platform's
  slide or zoom that flew a page in from the edge. Reduce Motion cuts it. Switching between top-level places (a side
  bar, a tab bar, a rail) changes the page in place. On iOS a swipe from the leading edge still takes a page back: the
  page follows the finger with the one under it showing, as on every iOS screen, and settles back if let go short of
  half way (ui_core's `DesignSwipeBackPageTransitionsBuilder`, in `neumorphicPageTransitions` and a router's
  `NeumorphicPage`).
- `NeumorphicRow` takes `from`: below the desk, the narrowest the row itself may be, as a window class of its own
  width, for its sections to stand side by side. With `from: NeumorphicWindow.medium` a tablet shows a list beside
  the item it opens, instead of the item under the list and below the fold; a row narrower than 600 still stacks.
- A `NeumorphicSelect`'s open list starts at its field's width and widens as far as its widest option needs, so
  the chosen option, set bold with its check, stays on one line ("Living room" broke onto two).
- An open list (a select's, a combobox's, a multi-select's, a menu's) shows its chosen option pressed in under the
  pigment's wash, as a segmented control's chosen cell. The pointer's row stands up as a part does, by night too, and
  the keyboard's place lifts, so neither reads as a second choice, and a move of the pointer takes the keys' place, so a
  list has one place, as a native menu; a row held under a finger presses in only while it is held. A
  `NeumorphicSelect` opens on Enter, Space, Down or Up with focus on its chosen option (the first with none
  chosen); the arrows wrap, Home and End go to the ends, a letter jumps, and Escape gives focus back to the field.
- `NeumorphicCombobox` and `NeumorphicMultiSelect` take `isOptionEnabled`: an option out of use is drawn out of use and
  the keys pass over it. Their lists take ui_core 0.2.0's keys: Up and Down wrap, Down on a closed list only opens it,
  a combobox opens on its value and lists every option until its words are edited, and a long list opens with its value
  in view and keeps the lit row in view as it moves. The pointer and the keys share one lifted row, as in a native menu,
  so two rows never read as two current options. A `NeumorphicMenuBar` menu goes to the item a typed letter starts.
- Every open menu (`showNeumorphicMenu`'s, a select's list, a `NeumorphicMenuBar` menu, a `NeumorphicSplitButton`
  menu) has one lit row: whichever moved last, the pointer or the keys, has it, and the keys go on from the pointer's
  row. Opened by the pointer a menu lights nothing until the pointer or the keys move; opened by Enter, Space or Down it
  lights its first row. A lit row keeps the menu's inset round it, so its lift never meets the menu's edge, and the
  keys scroll a row of a long select or `showNeumorphicMenu` list in with that inset.
- A `NeumorphicSplitButton` in a stretching column keeps its own width, and its menu its own (it took the column's).
- Typing goes on after Enter in a `NeumorphicCombobox`'s field, a `NeumorphicMultiSelect`'s and a
  `NeumorphicCommand`'s search: Enter took the focus from them, so a multi-select needed a click for each tag. They
  keep the focus now, and take Enter in `onEditingComplete`. A field of your own that should keep the focus after
  Enter takes it the same way, never with `onSubmitted`: in a browser, a field told of a submit while it keeps the
  focus shows the caret but takes no more letters.
- In a browser, a pressed well's inset stops where its content starts, as on every other platform: it ran on
  across a field's words, a calendar's days and a list's rows, a grey wash over what the well holds.
- Android's back closes an open list or popover before it pops the page, as it does a menu, a sheet or a dialog.
- `NeumorphicEmptyState` takes an `icon`, set on its mark, to say what is empty.
- **Breaking:** a theme casts its relief within the look's band: `NeumorphicElevation.depth` from `leastDepth` (0.5)
  to `mostDepth` (1.5) and `strength` from `leastStrength` (0.5) to 1. Shallower or fainter read as flat print and
  deeper as a skeuomorphic object, so `NeumorphicThemeData` clamps a value outside the band to its nearer end, silently,
  as a slider stops at its ends (`NeumorphicElevation.clamped`). `depth: 0` no longer lays every part flat: flat is
  how a part out of use lies (`NeumorphicFlatScope`).
- A style's `shape`, on a part or in a component theme, is held to the look's family in debug builds: a
  `NeumorphicRoundedBorder` at least `NeumorphicRadii.least` (6) round, a `NeumorphicStadiumBorder` or a
  `NeumorphicCircleBorder`. A sharper corner or another `OutlinedBorder` fails an assert that names the rule: plaster
  is moulded, with no sharp corner, and its relief is drawn round its own borders only. Release builds are unchanged.
- `style.side` and `style.edge` are documented as off the look's rule: relief is the only edge, and the fine outline
  is what high contrast draws. They still take precedence, for a high-contrast rim of your own.
- The README no longer shows a hover wash, which the look's state rules leave out; its example of a style of your own
  casts a quieter panel shallower instead.
- The gallery reads in Arabic right to left, speaks ui_core's 30 languages, and opens at each of ten everyday screens
  (`everyday_screens.dart` in the example).
- Needs ui_core 0.2.0.

## 0.1.0

- First release of the Neumorphism design system.
- Five presets in light and dark: porcelain, pompeii, verona, siena and tyrian.
- Theme value APIs, animated inherited themes, custom palettes, component themes and state-resolved styles.
- Paired shadows on one surface colour and no printed line; high contrast, the device's unless the app sets it, prints a fine outline.
- Rounded, stadium and circle shapes assigned by role, with content-safe insets and rounded fallbacks for wrapped labels. Density follows the platform unless set (compact with a pointer, standard on touch).
- Buttons, fields, selection controls, navigation, cards, charts, status displays, date and time pickers, dialogs, sheets, menus, tooltips and snack bars.
- Keyboard activation, focus in the relief, native editing gestures, an own selection menu and reduced motion. The built-in words are ui_core's `DesignLocalizations` (English until an app registers a `DefaultDesignLocalizations` subclass of its own).
- Bundled Manrope fonts and a font loader; public drawing parts for copying a component into an app.
- Out of use is said in the material, not a fade: a part out of use lies flat, flush with the ground, its words in the quiet ink (`NeumorphicFlatScope(flat:)`).
- Progress fills its groove with the pigment and the spinner turns a pigment arc; rating stars stand raised in the pigment or press in; a badge is a raised bead with its figure in the ink, warmed by the pigment when its count goes up; a skeleton is pressed wells that breathe.
- A notice's tone is in the material as well as its glyph and words: information and success are carved in its floor, a warning's mark stands on a raised bead, and an error's bead is warmed by the pigment.
- Hover changes nothing: the pointer's cursor says what a part does (click, text, grab), and `WidgetState.hovered` stays available to app styles.
- A press sinks the part in its own outline. Focus draws no line: a focused field's well deepens, and any other part, on keyboard focus only, lifts off the wall with its lit side warmed by the pigment and a near shade under its foot.
- Segmented controls, latches and tab bars are banks of equal cells, the chosen cell pressed in edge to edge, with labels that never move.
- The phone's tab bar carries a screen's own foot over its tabs in the same slab (`NeumorphicNavigationBar.header`: a cart's total and its act), so two bars at the foot are one piece.
- A grouped list's row is a band of its card out to the card's rim: its focus lift and its press go round the whole row, in the card's corners where it meets them (`NeumorphicTap.faceOutset`).
- A bare text link presses by darkening its underline and lies flat when disabled; a badge overlaps its child's corner by a fixed amount and leaves the child on its own line; the month keeps its grid on a 390 phone; a narrow table keeps each name and value on one line.
- A chart's gridlines stand on round steps, each labelled in a gutter beside the plot.
- A live example of 24 pages behind the look's own navigation (a rail on wide screens, a drawer on phones), every exported widget live on some page, plus customization of presets, colours, density, relief and contrast.
- The whole shared inventory, answered: `neumorphicInventory` gives each of its 89 rows a live `Neumorphic<Stem>` specimen, and `NeumorphicInventoryGallery` lists them.
- One API across looks: fourteen parts take the shared names (`NeumorphicLink`, `NeumorphicNumberField`, `NeumorphicFileUpload`, `NeumorphicBreadcrumb`, `NeumorphicListSection`, `NeumorphicSectionHeader`, `NeumorphicAvatarGroup`, `NeumorphicMedia`, `NeumorphicEmptyState`, `NeumorphicBanner`, `NeumorphicPieChart`, `NeumorphicCarouselView`, `NeumorphicInputOtp`, `NeumorphicScaffold`).
- Actions: `NeumorphicButtonGroup`, `NeumorphicToggleGroup`, `NeumorphicSplitButton` and `NeumorphicKbd`.
- Inputs: `NeumorphicPasswordField`, `NeumorphicInputGroup`, `NeumorphicCombobox`, `NeumorphicMultiSelect`, `NeumorphicFormField`, `NeumorphicRangeSlider`, `NeumorphicColorPicker`, `NeumorphicWheelPicker`, `NeumorphicCalendar` and `NeumorphicDateRangePicker` (and `showNeumorphicDateRangePicker`).
- Navigation and overlays: `NeumorphicNavigationRail`, `NeumorphicMenuBar`, `NeumorphicCommand` (and `showNeumorphicCommand`), `NeumorphicPopover`, `NeumorphicHoverCard`, `NeumorphicSheet` (and `showNeumorphicSheet`), `NeumorphicActionSheet` (and `showNeumorphicActionSheet`) and `NeumorphicToaster` (and `showNeumorphicToast`).
- Collections: `NeumorphicDataTable`, `NeumorphicScrollArea`, `NeumorphicResizable`, `NeumorphicReorderableListView`, `NeumorphicSwipeActions`, `NeumorphicTreeView`, `NeumorphicTimeline` and `NeumorphicDescriptionList`.
- Feedback and charts: `NeumorphicStatusView`, `NeumorphicMeter`, `NeumorphicLineChart`, `NeumorphicBarChart` and `NeumorphicAreaChart`.
- These take ui_core's values (`DesignMenuEntry`, `DesignCommand`, `DesignSwipeAction`, `DesignCalendarController`, `DesignTableController`, and so on), which the barrel exports, so an app needs one import.
- `NeumorphicHost` mounts a `NeumorphicToaster`, and `showNeumorphicSnackBar` queues there when the call sets no placement or style of its own: snack bars stack and wait their turn instead of replacing each other.
- `NeumorphicInputOtp` runs on ui_core's code field: one slot a character, Paste offered, `onCompleted` once per completion, and a form's submit, formatters and autofill passed through.
- `NeumorphicCombobox` says when no option fits the words, in its own list, instead of closing.
- `NeumorphicRating(enabled: false)` lays a rating flat and keeps its targets' size; null `onChanged` still shows a score only.
- `NeumorphicCarouselView` turns by its buttons, dots and arrow keys on ui_core's carousel, opens on `initialPage`, and stands 28 px taller so its clip never cuts a slide's relief.
- Large text: a button's padding and its glyph grow with its words (the glyph up to half again), a field's groove grows to its line, and instrument faces and tab words grow only so far (1.3) so they keep their room.
- Disabled reads at a glance: a round key, an icon button, latches, a choice box, a number field and a text field lie flat as one part, at any corner family.

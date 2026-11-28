## 0.6.3

- Requires ui_core 0.8.8 (ui_core_test 0.6.3 for the checks). On a phone a date's sheet covers the page's foot and
  stands on the navigation bar, as a modal sheet does; it stopped above the foot, the dimmed Save key showing under
  it. A swiped row is cut at its start, so its title no longer shows on the well's wall.
- `KeycapSegmentedButton`: keys too wide for one row reflow onto as few rows as hold them, the rows balanced (four
  keys: two and two; five: three and two), and below 600 each row shares the row's width. Before, they wrapped as
  they came: a Density row at 390 (Auto, Compact, Comfortable, Standard) stood three and one, the first
  row short of the edge and Standard alone. A row that fits stays one row.
- `KeycapScreen`: a hairline under its top bar shows while the page is scrolled under it, as Material's app bar
  marks a scrolled page; at the top the bar and the page stay one surface. Before, scrolled rows were cut straight
  off at the bar's edge, with nothing to show more lay above.
- `KeycapListGroup`: the rules beside a lit (selected) row run wall to wall, as its tint does. They were inset, so
  the tint showed a 1 px step at each end.
- `KeycapHost`: `density`, how tight the keys stand in the themes it builds from its palette (by the platform when
  null). Its doc says which theme it gives by day and by night.
- `keycapLoadFonts` loads the Lucide icon font the parts draw with, as well as Rubik, so no icon arrives late.
- `KeycapTextField`'s doc says what `reset()` does with a controller: it clears the errors and the field's saved
  value; the text stays the controller's, so to empty the field, clear the controller.
- README: one list of localization delegates (ui_core's and material_ui's), and that an app on material_ui needs no
  `flutter_localizations`; the example lists the same. The form clears after a save, and a line says how to check
  as the reader types (`autovalidateMode`).

## 0.6.2

- `KeycapTooltip`: over a key whose menu or popover is open, no tooltip opens at all (it had opened an empty one).
  On Flutter 3.50, whose `RawTooltip` dismisses open tips before anything else hears Escape, the empty tip took
  the first Escape after a pointer came back over the key, and the menu stayed open. The key keeps its focus, press
  and hover as the tooltip comes and goes. As before, a mouse resting on the key when its menu closes brings no
  tooltip back until it leaves and returns, and a screen reader still hears the key's name. Its docs say where
  it goes over a menu's or a popover's key: in their `builder`, round the key.

## 0.6.1

- Requires ui_core 0.8.5 (ui_core_test 0.6.2 for the checks).
- `KeycapSwitch`, `KeycapCheckbox` and `KeycapRadio` keep their own size in any parent, as Material's do: under a
  `KeycapField` in a stretching column (the README's form) each stands at the field's start, and only its own key
  takes a press. A switch had stretched to the column's width, its key stopping a key's width along the slot.
- `KeycapColors.info`, a note's ink, stays apart from the accent's words in every colourway: the classic's cobalt, or
  the ocean's teal where the key itself is cobalt or near it (classic, lilac). A note (a tag, a banner, a toast in
  `KeycapTone.info`) had been drawn in the accent's ink in five colourways, so it read as a link or a choice. A brand's
  theme from `KeycapThemeData.from` takes the same rule.
- A part's corners stay fixed: a style's `corners` (ui_core 0.8.5's `RawCorners`) leaves them as they are, since a
  keycap's profile is the look.
- The README's form shows a switch in its field, and its colours section says which tones stay apart from what.

## 0.6.0

- Requires ui_core 0.8.2.
- **Breaking:** `KeycapSelect.maxWideWidth` is removed: a select, a date, range and time field take their column's width at every width, as a text field does (they stood at most about 336 wide from 600 up), so a form's fields stand on one edge. A date field's month keeps seven days' width, at the field's start.
- **Breaking:** `KeycapCalendar.dayExtent` is removed, as 0.5.0 said: read `RawTapTargets.of(context).touch`. `dart fix` has no move for it, since the floor needs a `BuildContext`.
- `KeycapScaffold` stands on ui_core's `RawAdaptiveShell` at every width: the row of places under 600, the rail to 1024, the side column past it (`KeycapScaffold.modeFor`; `modeForWidth` picks others). On a phone a screen reader hears the places as tabs, the current one selected (they were plain buttons there). `KeycapScaffold.branches` keeps a stack per place: a pushed page keeps the rail or the side column while the phone's row steps away, and back pops the place's stack (`navigatorKeys`, `backBehavior`, `hideBarOnPush`).
- `KeycapHost.palette` builds both appearances from one of `KeycapThemeData.palettes`, the six colourways as ui_core's `RawNamedPalette`s (id, label, and the accent, a modifier and an alpha as swatches by day and by night) for an app's colourway picker.
- `KeycapColors.info`, the information tone, and `KeycapTone.inkIn`: a note's ink stays apart from a success's, the accent's and a warning's in every colourway (in sage the info tone was the success green); tags and banners read it.
- `KeycapScreen`'s footer stands on the body's column (`maxWidth`, at the page's start), so a form's Save key ends where its fields do; on a desk it stood at the window's far edge.
- `KeycapTextField` takes `validator`, `onSaved` and `autovalidateMode`, as `TextFormField` does: in a `RawForm` (or a `Form`) it checks with the form, its error under it with the well's edge in the danger colour, and takes the focus when it is the first one wrong.
- `KeycapFormat.date`: one medium date with the year in the reader's language, "Nov 14, 2026" in English, as the date field writes its day.
- A date, range or time field reads its label once: the label names the field, and `semanticLabel`, when given, replaces it (both were read).
- On a phone a menu, a popover and a hover card keep inside the page's margin (they opened 8 px from the screen's edge).
- By night, a destructive key's words and a date, range or time field's hint read 4.5:1 on their key in every colourway: they take the nearest tone of the danger ink and of the quiet ink that reads there (3.7:1 at worst before).
- A glyph beside a key's words, a tag's and a segment's glyph grow with the reader's text, and a `KeycapAvatar`'s face with its letters up to twice its side.
- The example is an app to copy (`example/lib/main.dart`, Shelf): `KeycapHost` with light, dark or the platform's appearance and a colourway, `KeycapScaffold.branches` with three places, a list that pushes a page and its dialog, a form that checks its fields with a date, and settings showing each colourway's swatches, in the device's language; on a desk its list and form keep to one column 720 wide. The gallery (Jotter and every part's page) runs with `flutter run -t lib/gallery.dart`.
- The README builds an app: the install line names `lucide_icons_flutter` beside `material_ui`; `KeycapHost` as the one mount, a list and its page, a dialog that pops with its answer, a checked form with a date, the colourway picker and `KeycapScaffold.branches`; a Building blocks table; labels and density stated. Every Dart block in it compiles as written (ui_core_test's `DesignReadmeCheck`).

## 0.5.0

- Six colourways, each by day and by night: `classic` (the default), `retro`, `sage`, `rose`, `lilac` and `ocean` (`KeycapThemeData.presets`, `KeycapThemeData.preset`, `KeycapColors.preset`). The example's Foundations shows them.
- Requires ui_core 0.7.1. Parts take ui_core's touch floor, 40 by 40 (was Keycap's own 48 under a finger and 44 elsewhere), or an app's `RawTapTargetScope`: calendar days, a slider's cap, page dots' strip (was 44), a reorderable row's grip and the close key in a sheet's head. `KeycapCalendar.dayExtent` is deprecated: read `RawTapTargets.of(context).touch`.
- `KeycapTagInput`'s tags and `KeycapBreadcrumb`'s places lay out in `RawChipGroup`: a tag input's runs stand 40 apart (were 48 under a finger), and a run of tags sits as far in from the well's top as from its start.
- Below 600 wide, `KeycapDatePicker`, `KeycapDateRangePicker` and `KeycapTimePicker` open in a sheet, the month and the wheels the sheet's width; from 600 they open over the keyboard as before. On a phone the month had opened narrower than the field, over the labels round it.
- `KeycapTimePicker`'s AM and PM keys share a row of their own above the done key, each half its width (they had stood at their words' widths beside the done key).
- A calendar's days outside the month stand 3:1 in a quiet tone of their own (were 2.4:1 by day).
- `KeycapThemeData.from` and `KeycapColors.from` work out their colours with ui_core's `RawPalette` (`RawAccentRule.named`): the accent's words read 4.5:1 on the case, the wells, the pages, a chosen row and the panels; a cream `alpha` tint keeps its night alphas a warm graphite. A toast's action takes the nearest tone of the accent that reads on the toast. `keycapContrast` is `RawPalette.contrastRatio`.

## 0.4.3

- `KeycapTimePicker`'s wheels keep hours before minutes, left to right, under a right-to-left `Directionality` too, as Material's time picker keeps them and as the key above them reads the time ("٩:٠٥"). In Arabic the hour's wheel stood on the right, so the chosen row read "٠٥ : ٩" under a key reading ٩:٠٥. The half day's keys keep the reading side. Left-to-right drawing is unchanged.

## 0.4.2

- Requires ui_core 0.6.1.
- `KeycapTimePicker` writes its time and its wheels' hours and minutes in the app's digits, through ui_core's `formatHour` and `formatMinute` (`RawTimeFormatting`), as Material's time picker does through `MaterialLocalizations.formatHour`: in Arabic 09:05 reads ٠٩:٠٥ on the 24-hour face and ٩:٠٥ ص on the 12-hour one, in Persian ۹:۰۵. They were written in Western digits in every language. The face is still the platform's choice (`MediaQuery.alwaysUse24HourFormat`), and on the 12-hour face the hour is the hour of the half day in every language. English reads as before.
- `KeycapPagination`'s page keys write their pages in the app's digits (ui_core's `formatDecimal`), as their spoken names and a phone's "3 of 12" already did.

## 0.4.1

- A toast stands above `KeycapScreen`'s `footer` (ui_core's `RawToasterKeepClear`), as a `Scaffold` keeps a snackbar above its persistent footer buttons, and as it already stands above `KeycapScaffold`'s tab bar. It stood over the page's keys.

## 0.4.0

- Requires ui_core 0.6.0. The kit's names the look shows take ui_core 0.6.0's `Raw` names (`RawWidgetsLocalizations` for `DesignLocalizations`, `RawCalendarController` for `DesignCalendarController`, `RawOverlayAnchor` for `DesignOverlayAnchor`, and the rest); the old names still compile, deprecated, and `dart fix` moves them.
- Under a finger a calendar's day is as tall as the look's floor, 48 (`KeycapTheme.tapTargets`), so the month's grid closes up, in `KeycapCalendar` and the date pickers; with a mouse it stays 44.
- The day numbers in `KeycapCalendar` and the date pickers come from ui_core's calendar (`RawCalendarDayDetails.label`), in the app's language and digits, as before.
- A `KeycapTooltip` on the key that opens a `KeycapMenu` or a `KeycapPopover` stays away while the menu is open, so a pointer back over the key no longer lays its name over the menu's rows.
- `KeycapLegendKey`'s legend takes a second line where one can't hold it (a long legend in Arabic on a phone), the key growing by it, its icon on the first line and its value standing clear below it. Before, it was cut short. Keys in a row that should stand equally tall take the row's height (`IntrinsicHeight` and `CrossAxisAlignment.stretch`), as Material's cards do.
- `KeycapLegendKey`'s value reads at 4.5:1 on its key by night too (4.8:1; it was 4.4:1): it stands a quarter of the way from the legend's ink to the key's top, not three tenths.

## 0.3.0

- Needs ui_core 0.5.1.
- **Breaking:** parameters and fields take the names Flutter's widgets give the same jobs. `dart fix --apply` moves each call and read below; the old names are gone.
- Fields: `label`, `hint`, `helper` and `error` are `labelText`, `hintText`, `helperText` and `errorText`, as on `InputDecoration`: `KeycapTextField`, `KeycapPasswordField`, `KeycapInputGroup`, `KeycapSelect`, `KeycapCombobox`, `KeycapTagInput`, `KeycapDatePicker`, `KeycapDateRangePicker`, `KeycapTimePicker`, `KeycapSearchField`, `KeycapFieldMessage`, `KeycapCommandPalette` and `showKeycapCommandPalette`. `KeycapInputGroup`'s `prefix` and `suffix` are `prefixText` and `suffixText`.
- `KeycapHost`: `light` and `dark` are `theme` and `darkTheme`, as on `MaterialApp`.
- `KeycapScaffold`, `KeycapNavigationBar`, `KeycapNavigationRail` and `KeycapSideNavigation`: `onSelected` is `onDestinationSelected`, as on `NavigationBar`.
- `KeycapListTile`, `KeycapSheetAction` and `KeycapMenuRow`: `destructive` is `isDestructiveAction`, as on `CupertinoDialogAction` and `RawMenuEntry`.
- `KeycapIconButton.selected` is `isSelected` (`IconButton`), `KeycapStepProgress.current` is `currentStep` (`Stepper`), and `KeycapRadioGroup.value` is `groupValue` (`RadioGroup`). `KeycapDisclosure`'s `open`, `initiallyOpen` and `onChanged` are `expanded`, `initiallyExpanded` and `onExpansionChanged` (`ExpansionTile`).
- `KeycapPageDots`: `count`, `index` and `onChanged` are `pageCount`, `page` and `onPageChanged`, the names `KeycapPagination` takes. `KeycapPagination.onChanged` is `onPageChanged` (`PageView`).
- `KeycapTextTheme.of` is `KeycapTextTheme.from`: in Flutter, `of` looks a value up from a `BuildContext`.
- **Breaking:** `KeycapMenu.destructive`, deprecated in 0.2.1, is removed, with no `dart fix`: mark the entry instead, `RawMenuEntry(isDestructiveAction: true)`.
- Every field stands in `KeycapField`, on ui_core's `RawInputDecorator`: the label over it and the help or error under it are drawn as before, and a screen reader hears the help and error on the field's own node, not as words of their own after it. A password field's input is that node, beside its reveal key.
- `KeycapField.invalid` marks a field wrong without words, and an empty `errorText` on a field does the same: a screen reader hears it invalid and the help stays hidden; a text field's rim takes the danger ink.
- `KeycapCombobox` and `KeycapTagInput` read as expanded while their list shows, and the combobox's chevron turns on the panel's spring as it opens and closes.
- A tag input holding tags reads its label, help and error on its typing line, as with none; each tag keeps its own name and remove action.
- A date picker opened from the keys puts the focus on its chosen day. It stayed on the field.
- `KeycapDialog`'s keys and `KeycapSheet`'s footer stand in ui_core's `RawActionBar`, laid out as in every look: side by side while each fits at its own width, else stacked as wide as the panel, the confirming key on top. Whether they fit is read from their words at the reader's text size.
- A toast stands above a phone's `KeycapNavigationBar` in `KeycapScaffold` rather than over its places, and at the screen's foot on a page pushed over the bar.
- A chart writes its figures at its scale's decimals, in the reader's digits (ui_core's `DesignChartValueFormat`), and its value axis is as wide as its widest tick at the reader's text size. The axis was measured from the data's lowest and highest values, so a wider tick could be cut.

## 0.2.1

- Needs ui_core 0.4.1.
- `KeycapMenu`, `KeycapContextMenu` and `KeycapMenuBar` print an entry marked `RawMenuEntry.isDestructiveAction` in the danger ink. `KeycapMenu.destructive`, a set of labels, is deprecated: mark the entry instead.
- `KeycapCombobox` and a row's `KeycapValueCap` end in the select's chevron, so every field that opens a list carries one sign.
- A dialog's keys that don't fit in one row (long words, large text) stack, each as wide as the panel, the main key on top. They stood as a staircase of different widths at the panel's end.
- Charts and `KeycapMeter` write their figures in the reader's digits (Arabic-Indic in Arabic): a chart's scale, readout, total and shares, and a meter's percentage. `valueText` still takes over, for units.
- `KeycapCalendar` numbers its days in the reader's digits too. At a large text size its figures shrink to keep inside their cell, so a row's days no longer run together on a phone.
- An open list (`KeycapMenuReveal`: a select's, a menu's) is opaque from its first frame. It faded in over about 60 ms, the field below showing through its rows.
- A key that does nothing stands as a level, matte plate: no dish, rim, walls or shadow, so it no longer reads as one to press. `KeycapFace.sculpt` sets how much of the moulding shows.
- `KeycapDatePicker` and `KeycapDateRangePicker` open their calendar on the side with more room, so it stays on a phone's screen.
- A text area's hint (`KeycapTextField` with `maxLines` over 1) wraps over its lines as its words would. It was cut to one line with an ellipsis, so a large text size left "What goes in this f…".
- A disabled `KeycapTextField`'s hint fades to the disabled ink with its label and well.
- A `KeycapListTile` that opens a choice never breaks its title inside a word: when the title's longest word and the value cap don't fit side by side (large text on a phone), the cap goes under the title. At the usual size it stays at the row's end.
- A `KeycapListTile`'s chevron points to the row's end in right to left too.
- `KeycapPageDots` by night: a page not showing is drawn in the plastic's wall shade, lighter than the case, as by day it stands off it. It was a shade the case hid.
- A `KeycapDonutChart` legend line starts with its swatch on either reading side, a gap before the label, centred on the first line of words. Right to left, an English label carried it to the label's far side.
- `KeycapScaffold`'s body keeps its parts' semantics nodes apart: a field opened over a nested `Navigator`'s page keeps its focus.
- `KeycapSectionHeader` keeps to one line, and takes two at a larger text size, as a list row's title does. A long header was cut to its first words at 200%.
- `KeycapInputGroup`'s add-ons keep their words whole. They take their own width, the entry keeps a third of the well, and where large text leaves them too little their words print smaller. They were held to a quarter each and cut ("…htt").
- A `KeycapMenuRow`'s words come before its end: where the words and a shortcut don't fit side by side (large text on a phone), the shortcut prints smaller. A command palette cut its command's name beside a whole shortcut.

## 0.2.0

- Needs ui_core 0.4.0 and Flutter 3.47. `keycap_ui` re-exports ui_core, whose types now take `Raw` names (`DesignPressable` is `RawButton`). The old names stay through ui_core 0.4 as deprecated typedefs, and `dart fix --apply` renames them.
- `KeycapRadioGroup`, a one-choice `KeycapSegmentedButton` and a one-at-a-time `KeycapToggleGroup` are Flutter's `RadioGroup`, each key a `RawRadio`, with ui_core's `RadioGroupKeyboardFix` inside. They answer Tab and the arrows as before, and a row that may be left empty still lets its chosen key up on a press. A radio shows its focus and its press as Flutter's `Radio` does, and on iOS and macOS a key also reads as selected.
- `KeycapTooltip` is Flutter's `RawTooltip`, with ui_core's `RawTooltipFocusFix` and `RawTooltipPlacement`. It fades on Flutter's tooltip timing, and each tooltip along a row of keys waits its half second.
- A latching `KeycapIconButton`, a selectable `KeycapChip` and a password field's reveal key read as buttons, selected while on, as `IconButton(isSelected:)` does. Before, they read as switches.

## 0.1.0

- First release: controls as keycaps on a mechanical keyboard, in day and night colourways on Rubik. Keys you press
  are sculpted caps that travel when pressed; what you read sits in wells cut into the case, and large reading and
  writing areas are light pages; menus, dialogs and sheets are flat panels laid over the keyboard.
- Keys: alpha, modifier and accent keys, printed and square keys, latching keys, two-legend keys, keyboard
  shortcuts, split buttons, toggle groups and toolbars.
- Fields: text fields, search, password, input groups with add-ons, one-time codes, number steppers, selects,
  comboboxes, tag inputs, chips, a colour picker and a drop zone.
- Choices: checkboxes, radios, switches and switch rows, segmented buttons and tab bars, whose legends reflow rather
  than cut short.
- Dates and values: a calendar, date, range and time pickers, sliders, range sliders, ratings and wheel pickers.
- Lists and layout: list groups and rows, cards, tables and data tables, trees, timelines, disclosures, carousels,
  reorderable lists, swipe actions, pull to refresh, split views and scroll areas.
- Navigation: the top bar, the phone's bar, the tablet's rail and the desktop's side column, breadcrumbs,
  pagination, step progress and page dots.
- Overlays and feedback: dialogs, bottom and side sheets, menus, context menus, a menu bar, a command palette,
  popovers, hover cards, tooltips, toasts, banners, progress bars, spinners, meters, skeletons, empty and status
  views; avatars, badges, tags, media, description lists and charts (line, area, bar, donut, sparkline).
- Ready for the world: right to left, text at 200%, a screen reader and the keyboard; calm motion that respects
  Reduce Motion. Checkboxes, radios and switches read as Flutter's do, not as buttons. A radio group, a one-choice
  segmented button and a one-at-a-time toggle group are each one Tab stop, at the choice; the arrows choose the next
  or the previous option, wrap, pass over options that are off and run the other way right to left, as Flutter's
  `RadioGroup` does.
- Requires ui_core 0.3.4.

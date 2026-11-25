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

## 0.4.0

- Requires ui_core 0.6.0, whose parts that still began with `Design` take `Raw` names (`DesignStyleOf` is `RawStyleOf`, `DesignDialogRoute` is `RawModalDialogRoute`). Clay's code and docs say the new names. The old names stay through ui_core 0.6 as deprecated aliases, and `dart fix --apply` moves an app's code.

## 0.3.0

- Needs ui_core 0.5.1.
- **Breaking:** parameters and fields take the names Flutter's widgets give the same jobs. `dart fix --apply` moves each call and read below; the old names are gone.
- Fields: `label`, `hint`, `helper` and `error` are `labelText`, `hintText`, `helperText` and `errorText`, as on `InputDecoration`: `ClayTextField`, `ClayInput`, `ClayTextArea`, `ClayPasswordField`, `ClayInputGroup`, `ClaySelect`, `ClayCombobox`, `ClayTagInput`, `ClayDatePicker`, `ClayDateRangePicker`, `ClayTimeField`, `ClaySearchField`, `ClayFileDrop`, `ClayFieldMessage`, `ClayCommandPalette` and `showClayCommandPalette` (and `ClayEntryText.hint` in `clay_parts.dart`). `ClayInput.obscure` is `obscureText`, as on `TextField`.
- `ClayHost` and `ClayPreview`: `light` and `dark` are `theme` and `darkTheme`, as on `MaterialApp`. `ClayPreview.activeIndex` is `selectedIndex`.
- `ClayAppShell`, `ClayScaffold`, `ClayNavigationBar`, `ClayNavigationRail` and `ClaySidebar`: `onSelected` is `onDestinationSelected`, as on `NavigationBar`. `ClayTabBar.onSelected` is `onTap`, as on `TabBar`.
- `ClayDialogAction`: `primary` and `destructive` are `isDefaultAction` and `isDestructiveAction`, as on `CupertinoDialogAction`. `ClayListTile.destructive` is `isDestructiveAction` too, as are `ClayMenuEntry.destructive` and `ClayMenuRow.destructive` in `clay_parts.dart`.
- `ClayIconButton.selected` is `isSelected` (`IconButton`), `ClayDisclosure.onChanged` is `onExpansionChanged` (`ExpansionTile`), `ClayStepProgress.current` is `currentStep` (`Stepper`), `ClayBadge.max` is `maxCount` (`Badge.count`), and `ClayRadioGroup.value` is `groupValue` (`RadioGroup`).
- `ClayPageDots`: `count`, `index` and `onChanged` are `pageCount`, `page` and `onPageChanged`, the names `ClayPagination` takes. `ClayPagination`: `count` and `onChanged` are `pageCount` and `onPageChanged` (`PageView`).
- `ClayTextTheme.of` is `ClayTextTheme.from`: in Flutter, `of` looks a value up from a `BuildContext`.
- A field's help and error are read with the field. The fields stand on ui_core's `RawInputDecorator` (`ClayFieldDecorator` in `clay_parts.dart`): the label, help and error are drawn as before, and a screen reader hears them on the field's own node rather than as words of their own after it. A password field's input is that node, beside its reveal key.
- `ClayCombobox` and `ClayTagInput` read as expanded while their list shows, and the combobox's chevron turns with it.
- A tag input holding tags reads its label, help and error on its typing line, as with none; each tag keeps its own name and remove action.
- A select's list opened from the keys puts the focus on its chosen option, and keeps it in view whether the keys or a pointer opened it. The focus stayed on the field.
- A toast stands above a phone's `ClayNavigationBar` dock rather than over its places, and at the screen's foot on a page pushed over the dock.
- A phone's bottom sheet is cut at the screen's foot: its slab, set below the foot to hide its lower corners, no longer paints past it.

## 0.2.1

- Needs ui_core 0.4.1. `ClayMenuItem.isDestructiveAction` reaches ui_core's `RawMenuEntry` in a context menu and a menu bar.
- `ClayPieChart`'s shares and `ClayMeter`'s percentage are written in the reader's digits (Arabic-Indic in Arabic), as the charts' values already were.
- `ClayCalendar` numbers its days in the reader's digits, and at a large text size shrinks them to keep inside their balls, so a row's days don't run together on a phone.
- `ClayCombobox` and `ClayTagInput` ring an option only after a key, as a select's list does: a list a tap or a click opened marks its chosen option alone (its words in the accent's ink and a check), and the pointer lights the row it is over. The ring showed on the chosen option at once, where it read as the keys' place.
- `ClayMenu` is as wide as its widest row, between 160 and 320, under its key. It spread across the window.
- A floating list (`ClayMenuReveal`: a select's, a menu's, a date picker's) and a tooltip are opaque from their first frame, as clay is. They faded in over about 120 ms, the page under them showing through their rows.
- `ClayDatePicker` and `ClayDateRangePicker` open their calendar on the side with more room, so it stays on a phone's screen.
- `ClayScaffold`'s body keeps its parts' semantics nodes apart: a field opened over a nested `Navigator`'s page keeps its focus.
- `ClayTable` and `ClayDataTable` never break a word inside a cell: where a column is narrower than its widest word (large text on a phone), the table scrolls sideways. A `ClayDataTable` heading also keeps to its line whole, with room for its sort arrow. At the usual text size they lay out as before.
- `ClayStepProgress` never breaks a step's name inside a word: a name with a word too wide for its cell lowers its own size to fit.
- A `ClayNavigationBar` place's name shrinks to fit whole, rather than lose its end to an ellipsis ("Settin…" at a large text size).
- `ClayButtonGroup`'s keys, where they don't fit their row, scroll inside the slab and are cut at its ends. They spilled past the slab, off a phone's screen right to left.
- `ClayWheelPicker`, `ClayTimePicker` and the other drums grow their rows with the text, so a row's figures keep clear of the next row's at a large text size. At the usual size a row is 40 high, as before.
- `ClayInputGroup`'s add-ons keep their words whole. They take their own width, the entry keeps a third of the well, and where large text leaves them too little their words print smaller. They were held to 45% each and cut ("…glasses").

## 0.2.0

- On ui_core 0.4.0, on Flutter 3.47 or later as before. The ui_core names Clay's API uses are 0.4.0's: `dart fix` renames them in an app. Clay draws and moves as before.
- Radio groups are Flutter's own. `ClayRadioGroup`, `ClaySegmentedButton` and a one-choice `ClayToggleGroup` are a `RadioGroup`, each choice a `RawRadio`, with ui_core's `RadioGroupKeyboardFix`. They take one Tab stop, on the choice, or on the first radio that can be chosen when the choice is turned off. Down and Right choose the next radio and Up and Left the previous one (Left and Right swap right to left), and Space chooses. A radio shows its focus rim after a click, as Flutter's radios do.
- `ClayRadio` is a `RawRadio`. In an app's `RadioGroup` it takes the group's choice; `groupValue` and `onChanged` are now optional, for a radio outside a group. It takes `enabled`. `ClayGroupRadio`, in `clay_parts.dart`, is one choice of a group.
- Toggle buttons read as buttons. A selected `ClayIconButton` and an on filter `ClayChip` say "button, selected", as Flutter's `IconButton(isSelected:)` does, not "switch, on".
- `ClayTooltip` is Flutter's `RawTooltip`, with ui_core's `RawTooltipFocusFix` and `RawTooltipPlacement`. It shows when the pointer rests on the control, after a long press, or when the control takes the keys' focus. The tip springs in and out as before, and a screen reader still reads it with the control, on the control's own node.

## 0.1.1

- Charts in clay. The donut is made of pieces of pastel clay: a small gap of the ground between slices instead of a white stroke, ends rounded with continuous corners, a soft light inside each piece's top-leading edge and a shade inside its bottom-trailing edge, one soft shadow straight down in its own hue, and a hole pressed into the ground that holds the total. Each piece's area is exactly its share of the clay, so the gaps and round ends never change how big a share looks; a piece too small to round keeps square ends. When a value changes the pieces spring to their new shares without a jump, and the picked piece rises.
- Every series weighs the same. By day the first is the accent itself, and each other slice, bar and line takes its pastel's hue at the accent's lightness and strength, so no series looks more important and each is told by its hue; legends, labels and values carry the data. By night the accent leads and chalky pastels follow (`claySliceColor`, `claySeriesColor`). A line, its area and its legend's ball share one colour.
- An area lies under its line as a slab of pastel clay with rounded feet; lines and sparklines are coils lit along their top and shaded along their foot; a picked bar's band dents the ground as a well.
- Progress rings: the band is clay, lit and shaded as every part is, its round ends standing exactly at 0 and at its value, closing into a whole ring at 100%.

## 0.1.0

- First release. Clay's theme: a palette designed by day and by night, the Rubik type scale, spacing on a 4 pt grid, rounded shapes, calm spring motion and a density setting; `ClayThemeData.from` builds a brand's theme from one accent, keeping its words readable.
- The clay material: soft volumes with cached light and shade, wells pressed into the ground, a press that squashes a part into it, and a focus rim in the part's own shape. Every part takes a `style:` and has a slot in the theme.
- Actions and choices: keys, icon balls, links, button, toggle and split groups, checkboxes, radios and a radio group, switches, segmented buttons, chips, sliders and a range slider, ratings, and a file drop.
- Fields: text, password, search, number, code and grouped fields, a note with its count, selects, a combobox and a tag field; a field's label, help, error and count stand on the line its words start on.
- Pickers: a calendar, date and date-range fields, wheels, a time field and a colour picker.
- Navigation: the top bar, a floating dock, a rail and a sidebar under one adaptive scaffold, tabs, breadcrumbs, pagination, page dots, step progress, a menu bar and a command palette.
- Content: slabs of rows, cards, section heads, description lists, tables and a data table, timelines, avatars and their group, badges, tags, media, a carousel, disclosures, a tree, split panes, and reorderable, swipeable and refreshable lists.
- Over a page: dialogs, bottom, side and action sheets, menus, popovers, hover cards, tooltips, toasts and banners.
- Feedback: progress bars and rings, a spinner, skeletons, meters and state views (empty, loading, error, done).
- Charts: line, area, bar and pie charts and sparklines, their bars moulded in clay.
- An app frame: `ClayHost` over the navigator, `ClayScreen` round each page, `ClayPage` and `ClaySheetPage` for the routes, `ClayAppShell` with `ClayTab`s and one `ClayShellAction`, `ClayPreview`, `ClayLoadingState`, `ClayErrorState` and `ClayInput`.
- Keyboard and screen reader: radio groups, segmented buttons and one-choice toggle groups take one Tab stop and choose with the arrows, on ui_core's `DesignRadioGroup`; a radio keeps the focus node its caller gives it; checkboxes, radios, switches and rows that are one (`ClayListTile.checked`, `toggled`) say what they are and their state, never a button.
- Large text and right to left: rows keep their title's line and move a wide part under it, segments show their words alone, and every part mirrors.
- Page transitions with the iOS swipe back; plurals in the reader's language with `clayPlural`.

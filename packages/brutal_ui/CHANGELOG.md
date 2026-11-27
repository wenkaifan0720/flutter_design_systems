## 0.7.0

- Requires ui_core 0.8.2.
- **Breaking:** `BrutalAppShell.action` is a `BrutalShellAction` (icon, tooltip, onPressed, accent), from the main library; it was the host library's `ShellAction`. `BrutalShellAction(icon: LucideIcons.plus, tooltip: 'New event', onPressed: (context) => create())` replaces `ShellAction(icon: ..., label: 'New event', onPressed: ...)`.
- **Breaking:** `BrutalPreview` and `BrutalPresentation` move to the host library, `package:brutal_ui/brutal_host.dart` (a page previewed alone, with no router); an app that used them imports it.
- **Breaking:** `brutalContrast` is removed, as 0.6.0 said: `dart fix --apply` moves a caller to `RawPalette.contrastRatio`.
- **Breaking:** `BrutalBlock.label` is `debugLabel`: it only names the block in the keyline check's findings, never drawn or spoken. `dart fix --apply` renames it.
- **Breaking:** `BrutalSelect.maxWideWidth` is removed: a select takes its column's width at every width, as a text field does (it stood at most 320 wide from 600 up), so a form's fields stand on one edge.
- `BrutalAppShell` stands on ui_core's `RawAdaptiveShell` at every width: the bar under 600, the rail to 1024, the side list past it (`modeForWidth` picks others). `BrutalAppShell.branches` keeps a stack per place: a pushed page keeps the rail or the side list while the phone's bar steps away and the act goes, and back pops the place's stack. A screen reader hears the places as tabs.
- `BrutalHost.palette` builds both appearances from one of `BrutalThemeData.palettes`, the six presets as ui_core's `RawNamedPalette`s (id, label, and the signal, lead block and page as swatches by day and by night) for an app's palette picker. A new palette or appearance blends: `BrutalHost` animates the theme (it snapped).
- On a desktop the app bar's title and `BrutalScreen`'s footer stand on the page's column (1200 at most, centred past it), where the body starts; they stood at the window's edges.
- `BrutalAppBar(large: true)` keeps its one 56 px row, its headline in it, so its rule meets the rule under a rail's or a side list's head; it stood an empty 56 px row over a second band. The headline grows with text to 1.6 times, the most the row holds.
- `BrutalTextField` takes `validator`, `onSaved` and `autovalidateMode`, as `TextFormField` does: in a `RawForm` (or a `Form`) it checks with the form, its error under it in red, and takes the focus when it is the first one wrong.
- A slider's and a range slider's track meet the column's edges, the ink running to the thumbs' centres (the track stopped half a thumb in).
- A field's hint is drawn in the off grey, a step lighter than help, so it never reads as a typed value: at least 4.5:1 on the box and 2.5:1 from typed words in every palette.
- `BrutalFormat.date`: one medium date with the year, "14 Nov 2026". `BrutalDatePicker` writes its day so (it wrote the day without the year).
- `BrutalNotice.fillOf`: a notice's lead-cell colour for its tone. A success and a warning keep the look's own lime and orange in every palette, told apart from each other and from the ink (in Blueprint both were blue); `BrutalStateView`'s success reads it too.
- A `BrutalListTile`'s `leading` is decoration, out of the row's name: a `BrutalAvatar` there no longer says the title twice. The row's name reads its status tag, and a control at its end keeps its own node.
- A chip's, a segment's and a button's glyph grow with the words beside it; a `BrutalAvatar` grows with text up to twice its side, its letters inside.
- `BrutalShellAction.tooltip` names the act in its tooltip and to a screen reader.
- A phone bar's name that is too long for its cell shrinks to it a tight step clear of its sides (an Arabic "الإعدادات" touched them).
- The example is an app to copy (`example/lib/main.dart`, Shelf): `BrutalHost` with light, dark or the platform's appearance and a palette, `BrutalAppShell.branches` with three places, a list that pushes a page and its dialog, a form that checks its fields with a date, and settings, in the device's language; on a desk its list and form keep to one column 720 wide. The gallery (Admit and every part's page) runs with `flutter run -t lib/gallery.dart`.
- The README builds an app: the install line names `lucide_icons_flutter` beside `material_ui`; `BrutalHost` as the one mount, a list and its page, a dialog that pops with its answer, a checked form with a date, the palette picker and `BrutalAppShell.branches`; a Building blocks table; density stated. Every Dart block in it compiles as written (ui_core_test's `DesignReadmeCheck`).

## 0.6.1

- Requires ui_core 0.7.2.
- An app's face behind the bundled Space Grotesk (an Arabic or CJK face in `BrutalTypeface.fallback`) draws the glyphs Space Grotesk lacks. Fallbacks are named as they are registered: an app's faces as it names them, a package's as `packages/<package>/<family>`. Before, they were read as faces of the typeface's own package (`packages/brutal_ui/Noto Sans Arabic`), which no app registers, so the platform's face drew those glyphs.
- `BrutalThemeData.copyWith(typeface:)` keeps the typeface's fallback when its family is the theme's own. Before, it dropped it, while `BrutalThemeData.light(typeface:)` kept it.

## 0.6.0

- Requires ui_core 0.7.1.
- Touch targets are 40 by 40 under a finger (they were 48) and 24 by 24 under a pointer; `BrutalChromeMetrics.touchTarget` is 40. Sliders stand 40 tall; a calendar's week stands 44 under a finger (it was 48).
- `BrutalTagInput` and `BrutalBreadcrumb` wrap in ui_core's `RawChipGroup`: the targets meet between the lines, which stand the look's spacing apart. A tag's remove key is 40 by 40.
- Six palettes, each designed by day and by night: `BrutalThemeData.presets` is `raw` (the default), `poster`, `zine`, `riso`, `blueprint` and `acid`; `BrutalThemeData.preset(name, brightness)` takes one.
- `BrutalThemeData.from`: an unnamed `lime` (the lead block) takes the signal's hue, its black words at 4.5:1. The signal keeps its colour under black or white words, as before.
- The focus ink is the signal's nearest tone that holds 3:1 on its ground.
- `brutalContrast` is deprecated: use `RawPalette.contrastRatio`. It goes in 0.7.0.

## 0.5.3

- `BrutalTimePicker`'s wheels keep hours before minutes, left to right, under a right-to-left `Directionality` too, as Material's time picker keeps them and as the time reads in a line of text ("٠٩:٠٥"). In Arabic the hour's wheel stood on the right. Left-to-right drawing is unchanged.
- `BrutalPagination` shows a page where its ellipsis would have stood for that one page alone: on a phone, page 3 of 12 reads 1 2 3 … 12, not 1 … 3 … 12. A gap of two pages or more keeps its ellipsis.

## 0.5.2

- Requires ui_core 0.6.1.
- `BrutalTimePicker`'s wheels write the hours and minutes in the app's digits on the locale's 24-hour clock, through ui_core's `formatHour` and `formatMinute` (`RawTimeFormatting`), as Material's time picker does: in Arabic 09 and 05 read ٠٩ and ٠٥, in Persian ۹ and ۰۵. They were written in Western digits in every language. English reads as before.
- `BrutalPagination` writes its pages, and "3 / 12" where it is too narrow for its keys, in the app's digits (ui_core's `formatDecimal`), as its spoken words already did.
- `BrutalDateRangePicker`'s field writes a span's days in the app's digits, as it already wrote the month and year: in Arabic "١٤ – ٢٠ نوفمبر ٢٠٢٦", where it read "14 – 20 نوفمبر ٢٠٢٦".

## 0.5.1

- `BrutalDatePicker`'s and `BrutalDateRangePicker`'s calendar drops in a panel of its own, as a menu does: the look's rule round the panel's fill on the hard ink shadow, the month's ruled table inside at the look's medium inset. It still meets its field on the field's rule, edge to edge with a phone's field, and stands 360 wide from a wide field's start (a span's two months at least 628). A popover over a form reads as one surface standing over it. In 0.5.0 the month's table was its only frame: on a phone, a calendar that opened above its field ended partway into the field above it, with a strip of half-cut words over its top rule.
- A toast stands above `BrutalScreen`'s `footer` (ui_core's `RawToasterKeepClear`), as a `Scaffold` keeps a snackbar above its persistent footer buttons. It stood over the page's one action.

## 0.5.0

- Requires ui_core 0.6.0 (and ui_core_test 0.4.0 in tests).
- Types take ui_core 0.6.0's names: each `style` parameter and the theme's style fields are a `RawStyle` (it was `DesignStyle`), the charts' `valueFormat` a `RawChartValueFormat` and their `painter` a `RawStyleOf`, `BrutalThemeData.density` a `RawDensity`, `BrutalTheme.tapTargets` a `RawTapTargets` and `BrutalInventory.registry` a `RawInventory`; `BrutalTreeController` extends `RawTreeController`. ui_core keeps each old name but `DesignInventory` as a deprecated alias of the same type, and `dart fix --apply` moves them all.
- Under a finger a calendar's day stands 48 tall, the look's tap floor, so each day's face fills the tap target ui_core 0.6.0 gives it and the rules between the weeks meet; under a pointer it stays 44. At 44 the weeks stood apart, each rule broken by a strip of the page, and on a phone's fractional pixel ratio a white pixel showed beside the chosen day.
- A calendar's rules run a device pixel on under the next cell's, and a chosen day's fill under its own rules, so on a phone's fractional pixel ratio the chosen day, a span's ends and the rules round them meet with nothing of the page between, by day and by night. Where a column fell on a fraction of a pixel, a grey line ran down each side of the chosen day.
- A calendar writes its days in the app's digits (`RawCalendarDayDetails.label`), as Material's does: in Arabic the 20th reads ٢٠, not 20.
- `BrutalDatePicker`'s and `BrutalDateRangePicker`'s calendar meets its field on the field's own rule, below it or above it, its ruled table the only frame on the hard shadow. It stood 4 off the field in a padded frame of its own.
- Under a field more than half again the calendar's own width (360 a month) the calendar stands at its own width from the field's start, as Material's docked date picker does; under a phone's field it stays edge to edge with it. On a desk window it spread the field's whole width, over the form's actions.
- `BrutalMenuBar` spans the width it is given, its menus from the start, as a desk app's menu bar spans its window; a rule closes each menu but the last where it meets the bar's end rule. It hugged its menus, and the last menu's rule stood doubled against the bar's own.
- Keyboard focus marks a field's lower edge in the look's accent, as on `BrutalTextField`: `BrutalDatePicker`, `BrutalDateRangePicker`, `BrutalSelect`, `BrutalInputGroup`, `BrutalCodeField`, `BrutalTagInput`, `BrutalFileDrop` and `BrutalLink`, and a calendar's keyed day and turns, as a segmented button's cells. They marked it in ink (paper on ink): an open date field's bar read as another kind of mark than a combobox's, and a calendar's keyed day as today's underline.
- Where a `BrutalTagInput`'s entry takes a line of its own under the tags, it reaches the look's 48 tap floor. It reached 46.

## 0.4.1

- `BrutalDatePicker`'s and `BrutalDateRangePicker`'s calendar stands as wide as its field, edge to edge with it, as a select's list does, on a phone and on a wide window. It stood a fixed width: about 10 narrower than a phone's field, and about half as wide as a wide one.
- The calendar's header is a row of its day grid: the arrows are each a day's column wide and the month's name spans the five between, every rule on the grid's rules. The arrows stood a fixed width, off the columns below.
- A `BrutalCombobox`'s and a `BrutalTagInput`'s suggestions meet the field on one rule, below it or above it, as a select's list meets its button. They stacked two rules (4 px of ink) where they met.
- A toast stands as every raised Brutal surface does: a paper face in the ink rule, on the look's hard ink shadow, clear of the tab bar. It stood flat, an ink band. A focused toast's bar now shows on the shadow.

## 0.4.0

- Needs ui_core 0.5.1.
- **Breaking:** parameters and fields take the names Flutter's widgets give the same jobs. `dart fix --apply` moves each call and read below; the old names are gone.
- Fields: `label`, `hint`, `helper` and `error` are `labelText`, `hintText`, `helperText` and `errorText`, as on `InputDecoration`: `BrutalTextField`, `BrutalInput`, `BrutalSearchField`, `BrutalPasswordField`, `BrutalInputGroup`, `BrutalCodeField`, `BrutalSelect`, `BrutalCombobox`, `BrutalTagInput`, `BrutalDatePicker`, `BrutalDateRangePicker`, `BrutalFileDrop`, `BrutalFieldMessage`, `BrutalCommandPalette` and `showBrutalCommandPalette`.
- `BrutalCombobox` and `BrutalTagInput`: `labelOf` is `displayStringForOption`, as on `Autocomplete`.
- `BrutalHost` and `BrutalPreview`: `light` and `dark` are `theme` and `darkTheme`, as on `MaterialApp`. `BrutalPreview.activeIndex` is `selectedIndex`.
- `BrutalAppShell`, `BrutalScaffold`, `BrutalNavigationBar`, `BrutalNavigationRail` and `BrutalSideNavigation`: `onSelected` is `onDestinationSelected`, as on `NavigationBar`. `BrutalTabBar.onSelected` is `onTap`, as on `TabBar`.
- `BrutalDialogAction`: `primary` and `destructive` are `isDefaultAction` and `isDestructiveAction`, as on `CupertinoDialogAction`. `BrutalListTile.destructive` and `BrutalSwipeAction.destructive` are `isDestructiveAction`, as on the look's buttons and menu items.
- `BrutalIconButton.selected` is `isSelected` (`IconButton`), `BrutalDisclosure.onChanged` is `onExpansionChanged` (`ExpansionTile`), `BrutalStepProgress.current` is `currentStep` (`Stepper`), and `BrutalBadge.max` is `maxCount` (`Badge.count`).
- `BrutalPageDots`: `count`, `index` and `onChanged` are `pageCount`, `page` and `onPageChanged`, the names `BrutalPagination` takes. `BrutalPagination.onChanged` is `onPageChanged` (`PageView`).
- `BrutalTextTheme.of` is `BrutalTextTheme.from`: in Flutter, `of` looks a value up from a `BuildContext`.
- **Breaking:** `BrutalLineChart`, `BrutalAreaChart` and `BrutalBarChart` take ui_core's `valueFormat` in place of `valueLabel`, which is gone (no fix moves it: the two are different kinds of value). For `valueLabel: (v) => '${v.round()} h'`, pass `valueFormat: const DesignChartValueFormat(suffix: ' h', fractionDigits: 0)`, or `DesignChartValueFormat.custom` for words of your own. The format writes the value axis, the read-out and what a screen reader hears in the reader's language, and the axis stands as wide as its widest label at the reader's text size.
- A field's label, help and error (`BrutalTextField`, `BrutalPasswordField`, `BrutalInputGroup`, `BrutalCodeField`, `BrutalSelect`, `BrutalCombobox`, `BrutalTagInput`, `BrutalDatePicker`, `BrutalDateRangePicker`) are read through ui_core's `RawInputDecorator`: a screen reader hears them on the field itself, its help and then its error, and hears an error when it comes. Before, the help and the error were loose words after the field.
- `BrutalCombobox`'s and `BrutalTagInput`'s text input reads as expanded while its list shows and collapsed once it closes, as a combo box does; the combobox's mark turns over with the list.
- A `BrutalDialog`'s actions are laid out by ui_core's `RawActionBar`: side by side in equal cells while every action's words fit its cell, else one above another, each the dialog's width, the main action on top.
- At large text on a phone a `BrutalInputGroup`'s add-ons wrap their words within a quarter of the row each, a `BrutalMenuBar` wider than the screen scrolls along, and a `BrutalSplitButton`'s main half gives way (its words end in an ellipsis) before its menu half. Before, each ran off the screen's edge.
- On a phone a toast stands above `BrutalScaffold`'s tab bar: ui_core 0.5.0's `DesignAdaptiveShell` keeps its navigation clear of the toaster. It used to cover the bar.

## 0.3.1

- Needs ui_core 0.4.1.
- `BrutalDatePicker` and `BrutalDateRangePicker` open their calendar where the whole month fits: below while below holds it, else above. Before, a field low on a phone opened it below in the room left, the month cut off at its second week.
- `BrutalScaffold`'s body keeps its children's semantics nodes apart, so a navigator in it (a router's shell) keeps its page's node when a list opens over the page. On the web a combobox on such a page lost the focus its first tap gave it, and took a second tap.
- `BrutalCombobox` ends in `BrutalSelect`'s mark, the solid triangle, at the same place, instead of two chevrons, so the two read as one kind of field.
- In a combobox's list, a menu, a menu bar, a command palette, a tag input's list and a split button's menu, the row the keys are on is marked in the row's own ink, rather than in the signal orange that marks a screen's main action.
- In those lists and a select's, the row the keys or the pointer are on is ruled round inside its edges. Before, a bar along its foot alone read, on a list's last row, as the panel's bottom rule doubled.
- A control in the `trailing` of a selected or pressed `BrutalListTile` (a ⋯ button, say) turns over with the row: paper on the inked row. Before, it drew in ink on ink.
- A `BrutalSegmentedButton` that hugs its words stands on whole pixels, so its rules are crisp. Before, a chosen cell could show a grey seam inside its rules, and the end rule was soft.
- `BrutalSegmentedButton`, `BrutalStepper`, `BrutalTabBar`, `BrutalStepProgress` and `BrutalTable` measure their words again when a face arrives after the first frame (on the web, Space Grotesk, or the face for Arabic). Before, they kept widths measured in the stand-in face, so a segment or a tab could clip its words or leave a gap. A chart's axes are redrawn then too.
- `BrutalLineChart`, `BrutalAreaChart` and `BrutalBarChart` take a `valueLabel`: the words for a value with its unit (`(v) => '${v.round()} h'`), on the value axis and in what a screen reader hears.
- A chart whose values are all 0 counts its axis 0 and 1, rather than 0.0, 0.2 … 1.0.
- When a `BrutalDialog`'s actions stack (at large text, or where one's words don't fit its cell), the main action, the last, stands on top and the others under it, as Material's dialog's actions overflow. Before, the main action stood at the foot.

## 0.3.0

- **Breaking:** stands on ui_core 0.4.0. Flutter 3.47 or later, as before.
- **Renamed:** the ui_core types in this package's API take ui_core 0.4.0's `Raw` names. For example, `BrutalDataColumn` extends `RawDataColumn`, and `BrutalTableController` extends `RawDataTableController`. The old names still work as deprecated typedefs, and `dart fix --apply` renames them.
- `BrutalRadio` is built on Flutter's `RawRadio`. Put a set in Flutter's `RadioGroup`, with ui_core's `RadioGroupKeyboardFix` round the radios. Inside a group, a radio takes the group's choice, and `enabled: false` turns it off. On its own, a radio still reads `groupValue` and calls `onChanged`.
- `BrutalSegmentedButton`'s cells are the radios of a Flutter `RadioGroup`. The keys work as before, Home and End included.
- As with Flutter's radios, a press, Enter or Space on the chosen radio or segment keeps it chosen and no longer calls `onChanged`. A radio shows hover and focus while focus highlights are traditional (on a desktop, or once a mouse or a key was used), so its focus also shows after a mouse click. On iOS and macOS an unchosen radio reads as not selected.
- A selected `BrutalChip` reads to a screen reader as a selected button, as a filter chip does, rather than as a switch.
- `BrutalTooltip` is built on Flutter's `RawTooltip`. It shows on hover after half a second, on keyboard focus and on a long press, and fades on the look's spring, as before. Run the pointer along a row of controls, and each tip waits its turn, as Flutter's do. Before, the next tip showed at once. A press hides a tip the pointer brought, as Flutter's do; before, the tip stayed while the control was held.

## 0.2.3

- Stands on ui_core 0.3.4.
- Keyboard focus marks one edge of a control with a solid accent block.
- A disabled checkbox with a validation error keeps a warning square beside it.
- The slider thumb sinks on pointer down and rises after release or cancellation.
- `BrutalSegmentedButton` is one radio group, as Flutter's `RadioGroup` is: Tab stops once, on the chosen cell, and the arrow keys move the choice, wrapping at the ends and moving on with Left in right-to-left text. Home and End still choose the first and last cell. A screen reader hears each cell as a checked or unchecked radio.
- `BrutalRadio`'s documentation shows how to group a set with ui_core's `DesignRadioGroup`, passing the group's node to `focusNode`. The example app's radios are grouped that way.

## 0.2.2

- `BrutalFormField.mergeSemantics` is now `bool?` and defaults to null: ui_core's field decides from the child. A child with one control, such as a switch, a checkbox or a slider, is one node named by the field's label. A child with several controls, such as segments, chips, radios or a stepper's buttons and number, keeps each control's own node, so a screen reader's double tap, or a click on the web with semantics on, reaches the control under it. The label names the group and is read once. Previously the default merged a group into one node, so a tap through the semantics tree reached only its first control and a stepper's tap did nothing. Pass `true` to keep the old merge or `false` to always name the child as a group. Needs ui_core 0.3.2.
- Wheels (the time picker's and `BrutalWheelPicker`'s) keep their rows' size at any text size, as Cupertino's do, so a larger figure no longer cuts its neighbours.
- Tables never break a figure or a word. Each column is at least as wide as its widest number or word at the current text size, so a time reads 19:30 and a price £18.00, and the table scrolls sideways when they don't fit, as Material's data table does.
- Button groups and the calendar grow their words with the system text size up to twice their size, as Material's time picker and calendar do, so a toolbar's 100% and a two-digit day stay inside their cells at larger sizes.
- Chips grow with their words at larger text sizes instead of cutting them, as Material's filter chips do.
- The time picker's wheels are named in the reader's language, from ui_core's `DesignLocalizations` (`timePickerHourLabel` and `timePickerMinuteLabel`), so a screen reader says "Stunde" in German and "ساعة" in Arabic. Previously they were "Hour" and "Minute" in English in every locale.

## 0.2.1

- Calendar popovers scroll when the available height is short. The last day of the month stays reachable at large text sizes.
- Step progress displays the steps in a vertical list when their names would be cut off.
- Line, area and bar charts scale the axis labels with the system text size. Category labels stay within the frame and leave space between neighbouring labels.
- Large app bar titles use the available height above the bottom rule. Equal-width tabs and segments keep their full labels when text is enlarged.
- The stepper's number cell fits its widest value at the current text size, and its step cells match its height. Date fields wrap a long date onto a second line instead of cutting it off.
- In Admit, event dates keep both day digits together, the English event count reads in order in right-to-left layouts, and the purchase footer stacks when its price and button cannot share a line.
- In the selection gallery, tapping a checkbox, radio or switch label activates its control.
- Admit validates checkout details and brings the first field that needs attention into view. The saved card is shown by its last four digits.
- Purchased tickets appear in Upcoming with their quantities, prices and a scannable order code. Cancelling removes the order and its code. Undo restores it.
- Account edits carry through to checkout. Signing out hides the account and its tickets until the demo account is opened again.

## 0.2.0

Built on ui_core 0.3.0. Brutal's tooltip, menus, dialog, sheets, tab bar, places, wheels, stepper, rating and chart
axis now take their behaviour from ui_core (its focus, keys, semantics, gestures and springs) and keep Brutal's paint:
they look as they did, and they do more. The breaks below touch only code that named a stepper's cell labels or took a
part for a `StatefulWidget` or a `StatelessWidget`.

### Breaking

- `BrutalStepper.decreaseLabel` and `increaseLabel` are gone. The minus and plus cells are no longer tab stops or
  screen reader nodes: the number is one adjustable field a screen reader steps and names by `semanticLabel`.
- `BrutalTabBar` is a `StatefulWidget` (it holds ui_core's tab controller) and `BrutalMenuPanel` a `StatelessWidget`;
  their constructors are unchanged.
- `showBrutalDialog` pushes ui_core's `DesignDialogRoute` and `showBrutalSheet`, `showBrutalBottomSheet`, the action
  sheet and `BrutalSheetPage` its `DesignBottomSheetRoute`, no longer a `RawDialogRoute`: code that tells them apart by
  the route's type checks for those.

### Behaviour that changes

- `BrutalTooltip` shows at once when the keys bring the focus to its control, the pointer may move onto it, Escape
  hides it, and running the pointer along a row of controls shows each one's at once.
- A menu a pointer opened lights no row, as before, and its surface holds the keys: Down goes to the first row, Up to
  the last.
- A dialog keeps Tab inside it and gives the focus back to what opened it; it and the sheets move on springs with the
  speeds they had (ζ 1, k 700, about 240 ms). A sheet follows a drag down and closes when let go low or flung, its
  body handing the drag over once scrolled to its top.
- `BrutalTabBar` and the places of `BrutalScaffold` and `BrutalAppShell` are each one stop for Tab, on the chosen
  one; the arrows move round them (mirrored right to left), Home and End go to the ends; a tab chooses as the keys
  reach it, a place on Enter or Space. A screen reader hears tabs, and places, with their place ("Past, Tab 2 of 2";
  "Home, Tab 2 of 5", where a place was a button); a desk's side list is the navigation menu. F6 moves between the
  places and the page. The chosen tab's bar grows on the tabs' spring and follows a swipe. A tab that hugs its words
  keeps the room of its words in bold whether chosen or not, so choosing one no longer moves the rules by a pixel.
- A phone's bar of places springs away under a page pushed over the root (`BrutalScaffold.showNavigation`), where it
  was taken out at once.
- `BrutalWheelPicker` and `BrutalTimePicker` take Page Up and Down, Home and End and a typed name, and Left and Right
  move between the time's two wheels; a key, or a tap on a row, turns a wheel to it on a spring. A drag that starts
  on the rule between the time's wheels turns a wheel, where it scrolled the page, and a mouse drag turns them too.
- `BrutalStepper`'s number takes typing in the reader's digits, read on Enter or as the keyboard leaves, clamped to
  `min` and `max`; Up and Down step it, Page Up and Down by ten, and a held cell repeats.
- `BrutalRating` is one tab stop: the arrows step it, End fills it, Home or 0 clears it, a digit sets that many; a
  drag sweeps along it, and a resting pointer inks the cells up to it; a press on the strip's end rule or shadow
  fills it, where it did nothing. A screen reader hears a slider.
- A chart's value axis stands on whole steps of 1, 2 or 5 × 10ⁿ (an axis to 250 is marked every 50, where it was
  62.5), labelled in the reader's numbers, as is the read-out a screen reader hears.
- Right to left the charts are mirrored: the categories and time run from the right, the value axis and its numbers
  stand on the right, a sparkline runs from the right and a pie's slices go round the other way from the top.
- `BrutalPreview`'s app is a semantics container of its own, so a screen reader still meets what the page paints
  before it (its routes' barriers hid it).
- Right to left every hard shadow falls the same way, down and to the left: the kits' raised and floating shadows
  (they fell to the right) and a reordered row's lift, now up and to the right, against its shadow.

### New

- `BrutalCombobox` and `BrutalTagInput` take a `search` that may take time and fail, with `debounceDuration`: the list
  says "Loading" by a small spinner while it runs, and a failed one says so over a "Try again" row that Down reaches.
  `options` is no longer required.
- `BrutalKbd.shortcut(activator)` prints a keyboard shortcut's keys in the platform's order and the reader's words,
  and `BrutalMenuItem.activator` shows one at a menu row's end (`⌘S` on a Mac, `Ctrl+S` elsewhere).

The package gallery includes six screenshots of the Admit example on desktop and mobile.

## 0.1.1

Needs ui_core 0.2.1.

- Reduce Motion on iOS calms Brutal too. Flutter puts iOS's Reduce Motion in dart:ui's
  `AccessibilityFeatures.reduceMotion`, not in `MediaQuery.disableAnimationsOf`, which was all Brutal read, so on an
  iPhone with Reduce Motion on, Brutal's colour changes, theme changes, arrows, tab and page-dot bars and loops still
  ran. Brutal now reads ui_core's `designReduceMotionOf`, which also covers Android's Remove animations and the web's
  `prefers-reduced-motion`. The spinner, the running progress bar and the skeleton stop looping, and when the setting
  changes while one runs, it stops or starts at once.
- A data table's counts under its pages were English whatever the app's language, with no plural form. Each now
  comes from the localizations with its number: the selection's from ui_core's `DesignLocalizations` ("1 item
  selected", "2 items selected"; was "2 selected"), translated in its 30 languages, and the rows' from the new
  `BrutalLocalizations` ("1 row", "2 rows"), English unless an app gives its own through a
  `LocalizationsDelegate<BrutalLocalizations>`.
- From ui_core 0.2.1: a menu or popover its anchor opened gives the focus back to the anchor as it closes, and Home and
  End in a list keep the row they reach in view.

## 0.1.0

- First release. The theme (light and dark, three densities), the surface (the rule, the hard shadow, the press, the
  focus rule) and the everyday parts: `BrutalButton`, `BrutalIconButton`, `BrutalTextField`, `BrutalSelect`,
  `BrutalCheckbox`, `BrutalRadio`, `BrutalSwitch`, `BrutalSegmentedButton`, `BrutalStepper`, `BrutalListGroup`,
  `BrutalListTile`, `BrutalSectionHeader`, `BrutalBlock`, `BrutalTag`, `BrutalAppBar`, `BrutalTabBar`,
  `BrutalNavigationBar`, `BrutalNavigationRail`, `BrutalSideNavigation`, `BrutalScaffold`, `BrutalDialog`,
  `showBrutalBottomSheet` and `BrutalToaster`.
- The app frame: `BrutalHost` (the theme, the toaster and the paper above the navigator), `BrutalScreen` (a page's
  margins, column, bar, footer and keyboard), `BrutalPage` and `BrutalSheetPage`, `BrutalAppShell` with `BrutalTab`s and
  a `BrutalShellAction`, `BrutalLoadingState`, `BrutalErrorState`, `BrutalInput` and `BrutalPreview`.
- Buttons take their words first, as Flutter's text does: `BrutalButton('Save', onPressed: save)`.
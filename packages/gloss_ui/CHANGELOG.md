## 0.5.1

- By night a destructive pearl key (a dialog's destructive action, `GlossButton(isDestructiveAction: true)`) is a smoked pearl with rose words at 4.5:1, plainly apart from the ruby gel key beside it. It was moulded in ruby, the same as the gel.
- A `GlossTextField` with `errorText` rims its well in ruby, as the search, password and other fields do; focused, the light along its floor is ruby. It kept the plain well and said so only under it.
- A `GlossCheckbox` with `isError` rims its socket in ruby. The warning glyph beside the socket is gone, so its words stand at the same gap as the other checkboxes'.
- A `GlossTextField`'s words start 8 px after its `prefixIcon`, as in `GlossSearchField`. They started 16 px after.
- By night a disabled `GlossSwitch`'s bead sinks halfway to the page, as a disabled key does. It shone as bright as an enabled switch's.
- `GlossPageDots`: the pages not shown read at 3:1 on the page, by day and by night. They read at about 1.1:1.
- A `GlossBreadcrumb` that wraps keeps each separator with the place after it, so no row ends on a separator, and its rows stand one touch target apart. The page's own place stood shorter than a link, so a row of it stood 30 px below the one above where the others stood 40.
- A `GlossDataTable`'s select-all tick stands over the rows' ticks, and each heading over its column: a number's heading ends where its numbers do. The tick stood 2 px toward the start, a number's heading 4 px past its numbers.
- A table row's empty tick and a `GlossTimeline`'s step to come keep a fine rim round the socket, as an empty `GlossCheckbox` does, so they read by night. They read at about 1.4:1 on their ground.
- A `GlossFormField`'s label reads as a text field's: 14 px in ink, grey when off. It stood larger, in secondary ink, as if off.
- A `GlossTextField`'s `suffix` words read at the value's size in secondary ink, as a `GlossInputGroup`'s add-on does and as Material's suffix text does. They stood 14 px.
- A `GlossSlider`'s bead travels between the ends a `GlossRangeSlider`'s beads do, a touch target's half in from its sides, so the two line up when stacked. Its travel stood 6 px wider at each end.

## 0.5.0

- Requires ui_core 0.7.2 (and ui_core_test 0.5.2 in tests).
- **Breaking:** `GlossMetrics.focusGap` and `GlossMetrics.focusWidth`, deprecated since 0.1.4 and both 0, are removed.
- Six gels on the same porcelain, each by day and by night: `GlossThemeData.presets` lists `jade` (the default), `sapphire`, `amethyst`, `amber`, `rose` and `teal`, where it listed jade alone, and `GlossThemeData.preset(id, brightness)` builds each. A gel's white words read 5.3:1 or more on its middle, as on jade's by night, so they still read where the glaze lightens toward the gel's crown.
- `GlossThemeData.from`'s `finish` tints the porcelain and pearl toward its hue at the look's own tones. It mixed in 8% of the finish itself, so a dark finish by day darkened the page and a light one by night paled it. Its gel holds its words as a preset's does, and the theme's words, links, focus and errors read on every ground they stand on: 4.5:1 on the page, a bar, a well and a porcelain tile (the focus 3:1), and at least 3:1 on a pearl part (the ink 4.5:1). Before, the gel's words were held on the well alone and the focus on the page alone, so under a dark finish by day, a pale gel or any gel by night they read under 4.5:1 on another ground.
- By night the ink, the secondary words, the jade's words and the focus are a little lighter, so they read on the moonlit pearl: secondary words #A6AFB8 to #BAC2CC (2.4:1 to 3:1 on a pearl's crown), jade words #52CDA0 to #5DD7A9, focus #4FD3A2 to #54D8A6, ink #E6EAEE to #E7EBEF. By day jade is unchanged.
- Parts drawn at a finger's size take ui_core's touch floor, 40 by 40, on every input (they were 44): a slider's row, a range slider's beads, a tag and its remove bead, a table's header row and a calendar's days. An app's `RawTapTargetScope` raises the floor.
- `GlossTagInput`'s tags and `GlossBreadcrumb`'s places lay out in ui_core's `RawChipGroup`.
- Below 600 wide, `GlossDatePicker` and `GlossDateRangePicker` open their month in a sheet titled "Select date", centred and at most 400 wide, the month's name at the title's edge. On a phone the panel used to cover the labels round the field. From 600 wide the panel opens under the field, as before.
- On a selected `GlossListTile` the supporting words read 4.5:1 on the row's pearl plate. By night they read 3.7:1.
- An avatar's initials are sized to the disc as it is laid out. In a list row's 24 px leading slot, a 32 px avatar's initials stood 3 px from the rim.

## 0.4.1

- A toast stands above `GlossScreen`'s `footer` (ui_core's `RawToasterKeepClear`), as a `Scaffold` keeps a snackbar above its persistent footer buttons. It stood over the page's one gel key.

## 0.4.0

- Requires ui_core 0.6.0 (and ui_core_test 0.4.0 in tests).
- Types take ui_core 0.6.0's names: each `style` parameter and the theme's style fields are a `RawStyle` (it was `DesignStyle`), the charts' `valueFormat` a `RawChartValueFormat`, `GlossThemeData.density` a `RawDensity`, `GlossTheme.tapTargets` a `RawTapTargets` and `GlossInventory.registry` a `RawInventory`; `GlossTreeController` extends `RawTreeController`. ui_core keeps each old name but `DesignInventory` as a deprecated alias of the same type, and `dart fix --apply` moves them all.
- A calendar writes its days in the app's digits (ui_core's `RawCalendarDayDetails.label`), as Material's does: in Arabic the 20th reads ٢٠, not 20.
- The days of the months either side in a `GlossCalendar`, a `GlossDatePicker` or a `GlossDateRangePicker` read at 4.5:1 in the secondary ink, one step under the month's own days. A press on one picks it, yet its figure stood at 2.67:1.

## 0.3.1

- The row the pointer or the keys are on in a `GlossCombobox`'s or a `GlossSelect`'s list, a menu and the command palette stands on a plate plainly deeper than the rows beside it, by day as by night. By day it stood about 3/255 from them.
- By night a key that destroys (a dialog's "Remove recipe") is a pearl moulded in ruby, its light words at 4.5:1 or more, plainly red beside a neutral key at rest, hovered, focused and pressed. Its rose words read at about 2.6:1 on the slate pearl, nearly lost beside its neighbour. By day it is unchanged.
- By night a toast's action ("Undo") is a lighter jade that reads at 4.5:1 on the toast. It read at about 3.1:1.
- `GlossDatePicker`'s and `GlossDateRangePicker`'s calendar opens clear of the whole field, its label too, as Material's menus do: above a field low on a wide window it covered the label. One month stands at the field's width, edge to edge with it, where on a phone it ran about 7 past each side.
- Right to left, Gloss's light comes from the right, the reading start: the glaze on a lit row, a focused field's lip, a key, a switch, a checkbox, a slider and a range runs from the right, mirrored. It ran from the left in both directions.
- The calendar's chosen day, and a range's two ends, sit in a well lit jade, as an on switch's groove and a slider's run do, rather than as a raised gel bead, the key Gloss keeps for a screen's one action.

## 0.3.0

- Needs ui_core 0.5.1.
- **Breaking:** parameters and fields take the names Flutter's widgets give the same jobs. `dart fix --apply` moves each call and read below; the old names are gone.
- Fields: `label`, `hint`, `helper` and `error` are `labelText`, `hintText`, `helperText` and `errorText`, as on `InputDecoration`: `GlossTextField`, `GlossInput`, `GlossSearchField`, `GlossPasswordField`, `GlossInputGroup`, `GlossTextArea`, `GlossSelect`, `GlossCombobox`, `GlossTagInput`, `GlossDatePicker`, `GlossDateRangePicker`, `GlossFileDrop`, `GlossFieldMessage`, `GlossCommandPalette` and `showGlossCommandPalette`. `GlossInput.obscure` is `obscureText`, as on `TextField`.
- `GlossHost` and `GlossPreview`: `light` and `dark` are `theme` and `darkTheme`, as on `MaterialApp`. `GlossPreview.activeIndex` is `selectedIndex`.
- `GlossAppShell`, `GlossScaffold`, `GlossNavigationBar`, `GlossNavigationRail` and `GlossSidebar`: `onSelected` is `onDestinationSelected`, as on `NavigationBar`. `GlossTabBar.onSelected` is `onTap`, as on `TabBar`.
- `GlossDialogAction`: `primary` and `destructive` are `isDefaultAction` and `isDestructiveAction`, as on `CupertinoDialogAction`. `GlossListTile.destructive` is `isDestructiveAction` too.
- `GlossIconButton.selected` is `isSelected` (`IconButton`), `GlossDisclosure.onChanged` is `onExpansionChanged` (`ExpansionTile`), `GlossStepProgress.current` is `currentStep` (`Stepper`), `GlossBadge.max` is `maxCount` (`Badge.count`), and `GlossRadioGroup.value` is `groupValue` (`RadioGroup`).
- `GlossPageDots`: `count`, `index` and `onChanged` are `pageCount`, `page` and `onPageChanged`, the names `GlossPagination` takes. `GlossPagination.onChanged` is `onPageChanged` (`PageView`).
- `GlossTextTheme.of` is `GlossTextTheme.from`: in Flutter, `of` looks a value up from a `BuildContext`.
- **Breaking:** `GlossLineChart`, `GlossAreaChart` and `GlossBarChart` take ui_core's `valueFormat` in place of `valueLabel`, which is gone (no fix moves it: the two are different kinds of value). For `valueLabel: (v) => '${v.round()} h'`, pass `valueFormat: const DesignChartValueFormat(suffix: ' h', fractionDigits: 0)`, or `DesignChartValueFormat.custom` for words of your own. Left unset, the figures are Gloss's own, compact past a thousand (1.2k). The format writes the value axis and what a screen reader hears in the reader's language, and the axis stands as wide as its widest label at the reader's text size.
- A field's label, help and error (`GlossTextField`, `GlossPasswordField`, `GlossInputGroup`, `GlossSelect`, `GlossCombobox`, `GlossTagInput`, `GlossDatePicker`, `GlossDateRangePicker`) are read through ui_core's `RawInputDecorator`: a screen reader hears them on the field itself, its help and then its error, and hears an error when it comes. Before, the help and the error were loose words after the field.
- `GlossCombobox`'s and `GlossTagInput`'s text input reads as expanded while its list shows and collapsed once it closes, as a combo box does. The combobox's pearl bead turns with its list, where it turned with the focus and stayed turned after Escape closed the list.
- On a phone `showGlossSheet`'s and `GlossSheetPage`'s panel stands on the screen's foot, rounded at its top corners only. It used to run a corner's height past the foot, out of the screen.
- At large text on a phone a `GlossStepper`'s figure shrinks to fit its readout, a `GlossTag`'s words end in an ellipsis, and a `GlossSplitButton`'s main half gives way (its words end in an ellipsis) before its menu half. Before, each ran past its edge.
- On a phone a toast stands above `GlossScaffold`'s tab bar (ui_core's `RawToasterKeepClear`), as a `Scaffold` keeps a snackbar above its navigation bar. It used to cover the bar.

## 0.2.1

- Needs ui_core 0.4.1.
- `GlossDatePicker` and `GlossDateRangePicker` open their calendar where the whole month fits: below while below holds it, else above; where neither side does, the panel shrinks to the room and the month scrolls in it. Before, a field low on a phone opened it below, off the screen's foot.
- `GlossScaffold`'s body keeps its children's semantics nodes apart, so a navigator in it (a list-and-detail pane) keeps its page's node when a list opens over the page. On the web a combobox on such a page lost the focus its first tap gave it, and took a second tap.
- `GlossCombobox` ends in `GlossSelect`'s pearl dial bead, seated as the select seats it, instead of a bare chevron, so the two read as one kind of field.
- The field the keys are in lights its well jade from inside, its rim and a glow up from its foot, so it is found at a glance by day and by night: `GlossTextField`, `GlossSelect`, `GlossCombobox`, `GlossSearchField`, `GlossPasswordField`, `GlossInputGroup`, `GlossOtpField`, `GlossTagInput`, `GlossCommandPalette`'s field and the date and time pickers' fields. Before, only a faint reflection changed; that reflection along the well's floor now gives way to the rim, so a lit field carries one mark.
- `GlossSegmentedButton`'s chosen segment is a raised pearl thumb with its words lit jade, as a latched chip's, rather than the jade gel of a screen's one action, and no longer engraved with the gel's dark line above them. By night the jade of its words is lifted until it reads at 4.5:1 on the slate pearl, up to its crown.
- By night the chevron on a select's, a combobox's and a disclosure's pearl bead takes the pearl's ink. The grey of supporting words read at 2.4:1 on the slate bead.
- The charts give their figures in the reader's digits (Arabic-Indic on an Arabic page): on the value axis, in a pie's middle and legend, and in what a screen reader hears.
- `GlossLineChart`, `GlossAreaChart` and `GlossBarChart` take a `valueLabel`: the words for a value with its unit (`(v) => '${v.round()} h'`), on the value axis and in what a screen reader hears.
- A chart whose values are all 0 counts its axis 0 and 1, rather than 0, 0.2 … 1.
- On a right-to-left page a chart's plot is its left-to-right one mirrored. Before, the figures' side and the far side swapped their insets, so the grid ran nearer the far wall.

## 0.2.0

- Needs ui_core 0.4.0 and Flutter 3.47. `gloss_ui` re-exports ui_core, whose types now take `Raw` names (`DesignPressable` is `RawButton`). The old names stay through ui_core 0.4 as deprecated typedefs, and `dart fix --apply` renames them.
- `GlossRadioGroup` and `GlossSegmentedButton` are Flutter's `RadioGroup`, each radio a `RawRadio`, with ui_core's `RadioGroupKeyboardFix` inside. They answer Tab and the arrows as before, and `GlossRadioGroup` Home and End. A radio shows its focus as Flutter's `Radio` does.
- `GlossTooltip` is Flutter's `RawTooltip`, with ui_core's `RawTooltipFocusFix` and `RawTooltipPlacement`. It fades on Flutter's tooltip timing, and each tooltip along a toolbar waits its half second.
- A latching `GlossIconButton` reads as a button, selected while latched, as `IconButton(isSelected:)` does. It read as a switch.

## 0.1.5

- Invalid text fields keep their recessed glaze and display the error below. Invalid checkboxes show a warning symbol beside the socket.
- Menu, select and combobox rows grow to fit large text, including letters with descenders.
- Chrome bars reuse their speckled texture across repaints.
- Stands on ui_core 0.3.4 and uses ui_core_test 0.1.4 for qualification. `GlossRadioGroup` is built on ui_core's `DesignRadioGroup`, over Flutter's `RadioGroup`. Tab enters at the checked option, or at the first option that can be chosen when the checked one is turned off or nothing is chosen. A turned-off option that is chosen still reads as checked. The arrows, Home, End and Space choose as before.
- `GlossSegmentedButton` reads as a group of radios, the chosen segment checked, where each segment read as a button before. Tab reaches it once, at the chosen segment, where each segment was a Tab stop before. The arrows choose the next or the previous segment and wrap.
- A selectable `GlossDataTable` row reads as a checkbox, checked when selected, from ui_core 0.3.4's `DesignDataTable`. It read as a button as well.

## 0.1.4

- Keyboard focus sharpens the reflection on glazed controls. Pale surfaces keep their body color in daylight and colored glazes deepen slightly. Recessed fields catch the light on their lower inner edge. Pointer hover gives a softer reflection and pressing a control shifts it. Reduce Motion makes these changes immediate.

## 0.1.3

- A time picker speaks the reader's language, from ui_core's words: a screen reader names its drums "Stunde", "Minute" and "Tageshälfte" in German, "ساعة", "دقيقة" and "ص/م" in Arabic ("Hour", "Minute" and "AM/PM" in English; the last was "AM or PM"), its half-of-day drum and `GlossTime.format` write "ص" and "م" in Arabic, and they were English in every language before.
- A time picker's figures and `GlossTime.format` are in the reader's digits (Arabic-Indic in Arabic: ٦:٣٠ م), as Material's time picker sets its hours.
- `GlossRadioGroup`: radios and their words, one choice, the whole row a radio's target. Tab reaches the group once, at its choice, and the next Tab leaves it; the arrows choose the next or the previous and wrap (mirrored right to left in a row), Home and End its ends, Space chooses, as Flutter's `RadioGroup` does. A screen reader hears a radio group of radios, in a `GlossFormField` too, whose label names the group while each radio keeps its own node. The gallery's radios are one.
- A radio, a checkbox and a data table's select-all box read as Flutter's do: a checkable (in a mutually exclusive group, for a radio), not a button as well.
- A chart's labels thin evenly when they crowd: every other one, or every third..., by their own widths, no two closer than a word's space. Before, the stride assumed every label 44 px wide and then skipped any that still touched, so a long or enlarged label left the rest uneven. The scale's figures thin the same way, from 0 up, where the top one was drawn even when it touched the one below. Where there is room for only two, they are the first and the last: Mon and Sun, and the scale's 0 and its top.
- A `GlossFormField` left to choose (`mergeSemantics` null) reads its child by what it brings to the semantics tree, on ui_core 0.3.2's `DesignField`, where it went by the child's type: one control is one node named by the label, and any group keeps each control's own node and tap. A group that names itself, a segmented button named as its field, is read once, where it read the field's label twice.

## 0.1.2

- A stepper's pearl beads stand as tall as its readout (40 px beads beside a 48 px readout before), and both grow with the text, so its words stay whole in the window at 200% and 300%.
- Keyboard focus is a soft halo of jade round the glazed part, as Aqua's was, in place of a ring standing 2 px off it: a band of light against the part's edge that fades into a glow, and the part's highlight brightens. A part with no room round it (a list row, a menu's, a select's or a combobox's row, a position in a slot or a bank, a card's frame) glows inward from its own edge (in white on a chosen segment's jade, where jade would not show); a text button or a link, with no glaze, lights a faint plate just beyond its words. The band reads at 3:1 or more against the part unfocused over a 2 px perimeter, by day and night: by day the focus jade is deeper (`0xFF0C7A54`, 4.4:1 on the page), and `GlossThemeData.from` keeps a brand's at 4:1. `paintGlossHalo` and `GlossFocusHalo` (with an optional `color`) give a part of one's own the same light. `GlossMetrics.focusWidth` is the band's width (3), `focusReach` the glow's (6); `focusGap` is deprecated.
- A form field holding a group of controls (a row, column or wrap of them, a segmented choice, a stepper, a toggle group, a range slider, a tag input, a time picker) keeps each control's own node and tap, and its label names the group. Before, with semantics on (a screen reader, or a browser that turned them on), a tap on any of them went to the first. `GlossFormField.mergeSemantics` is now null by default and decides by the child; true and false still force it.

## 0.1.1

- Date and date-range panels scroll on short screens. Calendar dates, weekday labels, and the month heading follow the system text size.
- Line, area, and bar charts scale their axis labels. The plot makes room for larger text and skips labels that would overlap.
- The pie chart places its legend below the ring when labels need more width. Long entries wrap so their amounts remain visible. In the gallery, the inline sparkline and its total stay together when the caption wraps.
- The range slider's track meets both handles at the minimum and maximum. The colored interval follows the handle positions in both reading directions.
- At large text sizes, list rows measure their trailing control. The filter switches stay aligned and a servings stepper leaves room for its label.
- Simmer keeps the same weekly plan on Today, in the planner and in recipe details. Adding a dinner or clearing the week can be undone.
- Simmer builds its shopping list from the week's dinners and household size. Checked items and handwritten extras carry over when the list is rebuilt.
- Recipe tags grow with their text, the account address has room to wrap, and search keeps durations and quoted queries readable in right-to-left layouts.

## 0.1.0

- Added glazed buttons, fields, selection controls, calendars, lists, and charts, with light and dark themes, three densities, and a custom brand palette.
- Added `GlossHost`, `GlossScreen`, and `GlossScaffold` for app setup and layout. `GlossAppShell` adapts navigation to the window width.
- Added dialogs, sheets, menus, toasts, tooltips, and `glossPageTransitions` for navigation.
- Integrated keyboard navigation, screen reader labels, and reduced-motion behavior through `ui_core` 0.3.0.
- Added localized plural selection through `glossPlural` and `glossPluralCategory`. Searchable fields support asynchronous results, retries, and debouncing.
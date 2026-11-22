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

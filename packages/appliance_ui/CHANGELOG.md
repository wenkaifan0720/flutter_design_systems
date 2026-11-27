## 0.6.0

- Requires ui_core 0.8.3.
- **The frame**: `ApplianceScaffold` stands on ui_core's `RawAdaptiveShell` at every width: a phone's key strip, the rail from 600, the side panel from 1024. A phone's places are tabs that say which is chosen (they were plain buttons). With `.branches` each place keeps its own pages; a pushed page keeps the rail or side panel beside it while a phone's key strip steps away, and choosing a place again returns to its first page. `ApplianceShellAction` is Appliance's own act.
- **Palettes**: `ApplianceThemeData.palettes`, the six finishes as ui_core's `RawNamedPalette` (an `id` to store, a `label` to show, swatches by day and by night), replace the `presets` list of names; `ApplianceThemeData.preset(id, brightness)` builds one and `ApplianceHost(palette:)` builds both appearances from one, easing between them.
- **Tones**: no finish's signal is green or red, so the ready and danger lamps stay apart from it in all six, by day and by night (mint's signal is teal, Reading and Done read apart; ui_core's `DesignToneCheck`).
- **Forms**: `ApplianceForm` and `ApplianceTextFormField`, a text field in a form as `TextFormField` in a `Form` (`validator`, `onSaved`, `autovalidateMode`), on ui_core's `RawForm`; a failed `ApplianceForm.submit` focuses the first field in error. Any other control takes part through ui_core's `RawFormField`: `ApplianceDatePicker` and `ApplianceRadioGroup` take a `focusNode` for it.
- **Dates**: `ApplianceFormat.date(context, day)` writes a day as the date field does, a medium date with its year in the app's language ("Nov 23, 2026" in English), for a page that shows the same day (the gallery's detail read "Monday, 23 November 2026" beside the field's "Nov 23, 2026").
- **List rows**: the end slot takes its own width up to two thirds of the row, so a long tag ellipsizes rather than overflowing (it overflowed at 390). A tag is said as written and stays in the row's name; an avatar repeating the title stays out of it; a control at the row's end keeps its own node.
- **The page's measure**: `ApplianceScreen` holds its app bar and its footer to the body's `maxWidth`, so on a wide window the title and the footer's keys line up with the content (the title stood at the window's edge).
- **Keys**: a focused filled key's rim glows a pale lamp-light; the faint line under its words after a press, which read as a link, is gone.
- **Text size**: a tag's lamp, a row's glyph, a menu row's glyph, a chip's glyph, a key's glyph beside its legend and an avatar up to 40 grow with the reader's text, as the words beside them do; a larger avatar is a portrait and keeps its size, and its initials fill the disc at either.
- **Radios**: `ApplianceRadioGroup(secondaryOf:)` shows a widget right after an option's words, as `RadioListTile.secondary` does (a palette's swatches); a screen reader hears the words alone.
- **Icons**: `LucideIcons` comes with `package:appliance_ui/appliance_ui.dart`.
- **The example** is one app to copy, `example/lib/main.dart`: Shelf, a reading list with three places, a list with a pushed page, a form that checks itself, a dialog and settings with the six finishes, each with its colours beside its name. The gallery and Larder are `example/lib/gallery.dart`.
- **The README** builds an app: forms, rows, the page's measure, the alert dialog, the palette picker and the example; every Dart block compiles.
- **Switches**: `ApplianceSwitch` keeps its slot's size at the start of a line that stretches its children (an `ApplianceField`); it was drawn across the line.
- **Messages under fields**: a field's error or help line grows open as it fades in, and fades before it folds away, so the fields under it move rather than jump; under Reduce Motion it is there at once.
- **Selects in a form**: an `ApplianceSelect` in an `ApplianceForm` spans the form's column, as the fields beside it do; it stopped at 320 on a wide window. Alone it still stops there.
- **Switches' marks**: the exposed I or O stands midway in the room the cap leaves bare; it stood against the cap.
- **Rows**: a row's title eases to its hover and focus ink with the row's face; it switched in one frame.
- **The top bar's keys**: an icon key an app puts at the bar's end stands 40 square, as the way back at its start does (it stood 48 beside it); an app's own `iconButtonStyle` size still wins.
- **The side panel's brand** stands on the top bar's title line, the app's act under it (it stood lower, out of line with the page's title).

## 0.5.0

- Six finishes, each by day and by night: `warm` (the default), `mint`, `butter`, `powder`, `blush` and `slate` (`ApplianceThemeData.presets`, `ApplianceThemeData.preset`, `ApplianceColors.preset`). The example's Foundations shows them, and its colour swatches show again (they had shrunk to a hairline).
- Requires ui_core 0.7.2. Parts take ui_core's touch floor, 40 by 40 (was Appliance's own 48 under a finger), or an app's `RawTapTargetScope`: a slider's cap (was 44 on every input), a reorderable row's grip, a sheet's grip and every key and row that stood at the floor. A calendar's days stay 44.
- `ApplianceTagInput`'s tags and `ApplianceBreadcrumb`'s places lay out in `RawChipGroup`. A tag's remove key stands in the floor's target (was 48 under a finger), so a tag is 8 narrower and more of them fit a run; the runs keep the field's row, 44. A breadcrumb's runs stand 40 tall (were 48 under a finger).
- Below 600 wide, `ApplianceDatePicker` and `ApplianceDateRangePicker` open in a sheet titled Select date (`RawPickerWords`, in the app's language), the month the sheet's width; from 600 they open on a plate as before. On a phone the plate had opened narrower than the field, over the labels round it.
- A calendar's days outside the month read 2.9:1 in a quiet tone of their own (were 1.9:1 by day).
- `ApplianceThemeData.from` and `ApplianceColors.from` work out their colours with ui_core's `RawPalette` (`RawAccentRule.named`): the signal's words read 4.5:1 on the housing, a faceplate, a well and a key, its focus 3:1 on the housing and a faceplate, and muted words keep 4.5:1 on every plastic; a `finish` keeps its night plastic a tinted graphite, never brown. A toast's action takes the nearest tone of the signal that reads on the toast. By day a chart's first trace is the signal itself, or its nearest tone that stands 3:1 on the display (was the signal's words, deeper and duller). `applianceContrast` is `RawPalette.contrastRatio`.
- Warm reads better. By day the signal's words are a tone deeper, so a link on the housing reads 4.5:1 (was 2.9:1), and the focus a tone deeper, 3:1 on the housing (was 2.65:1). By night the signal's words and muted words (a field's hint, a caption) are a hair lighter and read 4.5:1 on a key (were 4.2:1).

## 0.4.0

- Requires ui_core 0.6.0. The kit's names the look shows take ui_core 0.6.0's `Raw` names (`RawWidgetsLocalizations` for `DesignLocalizations`, `RawStyleOf` for `DesignStyleOf`, `RawChartValueFormat` for `DesignChartValueFormat`, and the rest); the old names still compile, deprecated, and `dart fix` moves them.
- Under a finger a calendar's day is as tall as the look's floor, 48 on a phone (`RawTapTargets`), in `ApplianceCalendar` and the date pickers' plates; with a mouse it stays 44.
- The day numbers in `ApplianceCalendar` and the date pickers come from ui_core's calendar (`RawCalendarDayDetails.label`), in the app's language and digits: Arabic-Indic in Arabic.
- `ApplianceDatePicker` and `ApplianceDateRangePicker` open their plate from the label and the key together: opened above, the plate stands over the label rather than on it; opened below, it still hangs from the key.
- A chart's day labels stand under the glass, the first and last no longer running under the scale's figures at its side.
- At large text a key grows with its words, as Material's buttons do: `ApplianceButton` (not `ApplianceButton.text`) and the keys of `ApplianceToggleGroup`. Before, a desktop key held its words on its foot at text scale 2.
- When `ApplianceToggleGroup` runs its keys onto a second row, the rows stand as far apart as the keys in a row. Before, the second row stood three times as far.

## 0.3.0

- Needs ui_core 0.5.1.
- Field words take `InputDecoration`'s names: `label` is `labelText`, `hint` is `hintText`, `helper` is `helperText`, `error` is `errorText`, on `ApplianceTextField`, `AppliancePasswordField`, `ApplianceSearchField`, `ApplianceInputGroup`, `ApplianceSelect`, `ApplianceCombobox`, `ApplianceTagInput`, `ApplianceDatePicker`, `ApplianceDateRangePicker`, `ApplianceInput`, `ApplianceFieldMessage` and `ApplianceCommandPalette`, as `ApplianceField` already names them. `dart fix` renames them.
- `ApplianceListTile`, `ApplianceMenuRow` and `ApplianceSheetAction`: `destructive` is `isDestructiveAction`, as Flutter names it. `dart fix` renames it.
- `ApplianceMenuRow`: `chosen` is `selected`, as Flutter names it. `dart fix` renames it.
- `ApplianceInput`: `obscure` is `obscureText`, as Flutter names it. `dart fix` renames it.
- `ApplianceSlider`: `valueText` is `semanticFormatterCallback`, as `Slider` names it: only a screen reader hears it. `dart fix` renames it.
- `AppliancePreview`: `activeIndex` is `selectedIndex`, as Flutter names it. `dart fix` renames it.
- `ApplianceTime` goes: `ApplianceTimePicker` takes ui_core's `RawTimeOfDay(hour:, minute:)`, whose `replacing` is `ApplianceTime.copyWith`. `dart fix` makes the move.
- `ApplianceThemeData.of(brightness)` is `ApplianceThemeData.from(brightness: brightness)`, the same theme, and `ApplianceTextTheme.of` is `ApplianceTextTheme.from`: in Flutter `of` looks a value up in a `BuildContext`. `dart fix` makes the move.
- `ApplianceTab` takes its `key` by name, `ApplianceTab(icon, label, key: ...)`, as every widget does. A positional key no longer compiles; the analyzer offers to name it.
- `ApplianceSheetPage(drawer:, fullScreen:)` is `ApplianceSheetPage(size:)`, an `ApplianceSheetSize` (`standard`, `drawer`, `fullScreen`), one choice where two flags could contradict.
- `ApplianceThemeData.h1` and `ApplianceThemeData.body` go: read `textTheme.title` and `textTheme.body`.
- `ApplianceMetrics.focusGap` and `ApplianceMetrics.focusRadius` go, deprecated since 0.1.2: focus lights the part's own rim.
- `ApplianceRadio` reads the `RadioGroup` above it, as Flutter's `Radio` does: its `groupValue` and `onChanged` move to a `RadioGroup<T>` round the radios, which gives them one Tab stop and the arrow keys. `ApplianceRadio.enabled` turns one radio off.
- `ApplianceChip.enabled` goes: a null `onSelected` puts a chip out of use, as `FilterChip`'s does. `selected` may be null: a chip given neither `selected` nor `onSelected` is shown only, as `Chip` is, and one given `selected` latches, as `FilterChip` does.
- `ApplianceTagInput.enabled` goes, and `onChanged` may be null: a null `onChanged` puts the field out of use.
- `ApplianceScrollArea`, `ApplianceCalendar` and `ApplianceColorPicker` take an optional `controller`: with none, each makes its own and disposes it, and a controller handed in is never disposed. The scroll area hands its own to its child as the `PrimaryScrollController`; the calendar's chooses one day, 1900 through 2100. `ApplianceColorPicker.onChanged` says each new colour.
- `ApplianceCombobox` and `ApplianceTagInput` say on their text input whether their list is open, as a select's key does.
- `ApplianceDatePicker` and `ApplianceDateRangePicker` open their month whole: on a phone, a field low on the screen opens it above rather than in a strip that scrolls.
- `ApplianceDialog`'s keys and the footer keys of `ApplianceSheet` and `ApplianceSideSheet` stand on ui_core's `RawActionBar`: side by side while they fit, else one column of one width, the main key on top. A sheet's footer stacks where it squeezed its keys before.
- Every field reads its label, help and error on its control's own node (ui_core's `RawInputDecorator`), the error announced as it appears, and a select's or a date picker's key is named by its field. `ApplianceFieldMessage(parts)` draws a decorator's `helper` and `error`; `ApplianceFieldMessage(helperText:, errorText:)` no longer compiles: put the control in an `ApplianceField`.
- On a phone a toast stands above `ApplianceScaffold`'s key strip, and at the screen's foot while a page covers the strip.
- `ApplianceToggleGroup` runs its keys onto a second row of the strip when large words no longer fit one.
- A key's words run onto a second line, centred, where one line can't hold them (an ellipsis cut them before).
- Charts write their values with ui_core's `DesignChartValueFormat`: the scale at its decimals, the readout at the value's own (up to three), and the scale takes the room its widest figure needs.
- `ApplianceMedia` takes an `image` (an `ImageProvider`), shown over `slotId` when both are given; `slotId` is optional when there is an image.

## 0.2.1

- Stands on ui_core 0.4.1. A menu entry marked `isDestructiveAction` (Delete, Remove) prints its words in the danger ink, in `ApplianceMenu`, `ApplianceContextMenu` and `ApplianceMenuBar`, as an action sheet's destructive row does. An all-zero chart counts up from zero, its bars flat on the floor; it was scaled from −1 to 1.
- `ApplianceCombobox` carries the select's up-and-down legend at its end, so it reads as a field that opens a list. A tap on the legend opens the list.
- A disabled key stands level and matte with grey words, never brighter than a key in use. It kept its raised, lit body and looked pressable. This covers `ApplianceButton` and its filled form, `ApplianceIconButton`, a stepper's key at its bound, the toggle strip, chips, tags, the date field's key and the select. `ApplianceFace.asDisabled` gives the same face to a part of your own.
- `ApplianceErrorState` stands on the faceplate of `ApplianceEmptyState`. Its display window reads a fault code (`reading`, "Err" by default) and a lamp lit in the danger colour stands beside its heading. It was a red bead in a halo on the bare housing.
- `ApplianceStepper` writes its value in the reader's digits (Arabic-Indic in Arabic) and takes `valueText` for a value with its unit ("45 min"), which a screen reader hears too. Chart figures and a donut's shares are in the reader's digits as well.
- An empty chart's idle window keeps its dashes at one size, so a 134 px chart holds its words at text scale 2. It overflowed on a phone.
- A screen reader hears an `ApplianceListTile`'s trailing control (a row's menu key) as a button of its own, beside the row's. The row's node took the control's name.
- In a combobox and a tag field, the row the pointer or the keys are on sits down as a pressed key, as it does in a select. It was underlined in orange. Menu commands still light their legend and sink only while held.
- An open list's plate casts a lid's shade, close round its edge and soft under it, so words it half covers at its corners sink into shade. They showed as a stray mark.
- A `Navigator` in `ApplianceScaffold`'s body keeps a semantics node per route, as the app's own navigator does, so on the web a tap on a combobox on a pushed page keeps the focus it gives. A list opening over the page made a node above it, and the browser blurred the field.
- A selected `ApplianceChip` with no `onSelected` stays latched down and reads as selected, disabled, as a disabled `FilterChip` does. It showed as a chip that is not selected.
- A chosen part out of use keeps its lamp lit in the disabled print, as `ApplianceRadio` does: an `ApplianceChip`, an `ApplianceSegmentedButton` segment, an `ApplianceSwitch`, an `ApplianceToggleGroup` key and the AM/PM key of `ApplianceTimePicker`. Its lamp went out, as an unchosen part's does.
- `ApplianceAvatar` takes an `image` (an `ImageProvider`, such as a `NetworkImage`), shown over `slotId` when both are given.
- `ApplianceThemeData.copyWith(colors:)` recolours the text theme and keeps its family, package and sizes. It rebuilt the text in Barlow, dropping a family set through `ApplianceThemeData.from(fontFamily:)`.
- `ApplianceChevronPainter` has a const constructor.
- The example app resolves from pub.dev alone: it imported `ui_core_review`, which is not published, for a review overlay.

## 0.2.0

- Needs ui_core 0.4.0 and Flutter 3.47. `appliance_ui` re-exports ui_core, whose types now take `Raw` names (`DesignPressable` is `RawButton`). The old names stay through ui_core 0.4 as deprecated typedefs, and `dart fix --apply` renames them.
- `ApplianceRadioGroup` and `ApplianceSegmentedButton` are Flutter's `RadioGroup`, each radio a `RawRadio`, with ui_core's `RadioGroupKeyboardFix` inside. They answer Tab, the arrows, Home and End as before. A radio shows its focus as Flutter's `Radio` does.
- `ApplianceTooltip` is Flutter's `RawTooltip`, with ui_core's `RawTooltipFocusFix` and `RawTooltipPlacement`. It fades on Flutter's tooltip timing, and each tooltip along a row of keys waits its half second.
- When an `ApplianceDialog`'s keys do not fit side by side (long labels, large text), they stack, each as wide as the dialog, the main one on top. They stood in a staircase of their own widths at the end, the main one at the foot.
- A latching `ApplianceIconButton`, an `ApplianceChip` and the password field's eye read as a button, selected while latched, as `IconButton(isSelected:)` does. They read as switches.

## 0.1.5

- Hover and keyboard focus brighten the fitted pilot lamps, legends and bezels. The orange action key lights its legend. Menu commands depress only while held.
- A part whose lamp is already lit (a chosen selector position or radio) shows keyboard focus by lighting its inner bezel, since a brighter lamp would barely show. A switch and a chip light their bezel on focus too, on or off, and their lamp shows only whether they are on or selected.
- Stands on ui_core 0.3.4 and uses ui_core_test 0.1.4 for qualification. `ApplianceRadioGroup` is built on ui_core's `DesignRadioGroup`, over Flutter's `RadioGroup`. Tab enters at the checked option, or at the first option that can be chosen when the checked one is turned off or nothing is chosen. A turned-off option that is chosen still reads as checked. The arrows, Home, End and Space choose as before.
- `ApplianceSegmentedButton` reads as a group of radios, the chosen position checked. Tab reaches the selector once, at its choice, where each position was a Tab stop before. The arrows choose the next or the previous position and wrap at the ends, and the focus moves with the choice; Home and End still choose the first and the last.
- The component inventory's radio group specimen is an `ApplianceRadioGroup`, read as two radios. It was two list rows, each read as a button holding a radio.
- A selectable `ApplianceDataTable` row reads as a checkbox, checked when selected, from ui_core 0.3.4's `DesignDataTable`. It read as a button as well.

## 0.1.4

- Date pickers show the month, digits and date order from the reader’s ui_core localization. For example, 20 November 2026 reads «٢٠ نوفمبر ٢٠٢٦» in Arabic. Date ranges use the same words and show both years when they cross New Year.
- Requires ui_core 0.3.3 and uses ui_core_test 0.1.3 for qualification.

## 0.1.3

- A time picker speaks the reader's language, from ui_core's words: a screen reader names its figures "Stunde" and "Minute" in German, "ساعة" and "دقيقة" in Arabic ("Hour" and "Minute" in English, where they were "Hours" and "Minutes"), and its keys for the halves of the day read "ص" and "م" in Arabic. They were English in every language before.
- `ApplianceTimePicker.semanticLabel` is a `String?`, null by default: with none, the field round the picker names it with its label, where the picker called itself "Time" in English in every language. A `String` passed as before still names it.
- A time picker's figures are in the reader's digits (Arabic-Indic in Arabic), as Material's time picker sets its hours: they are text in the display window, not a segment display.
- An `ApplianceField` holding a time picker keeps each figure's and key's own node and tap, as it does a stepper's, and its label names the picker. Before, a screen reader's tap on the PM key went to the field's one node.
- `ApplianceRadioGroup`: preset keys and their words, one choice, the whole row a key's target. Tab reaches the group once, at its choice, and the next Tab leaves it; the arrows choose the next or the previous and wrap (mirrored right to left in a row), Home and End its ends, Space chooses, as Flutter's `RadioGroup` does. A screen reader hears a radio group of radios, in an `ApplianceField` too, whose label names the group while each radio keeps its own node. The gallery's preset keys are one.
- A radio and a checkbox read as Flutter's do: a checkable (in a mutually exclusive group, for a radio), not a button as well.
- An `ApplianceListTile`'s `trailingText` takes its own width, up to under half the row, and the title the rest: before, the value's slot took half the row's room however short it was, so a title wrapped early beside a date (a four-word task name wrapped beside its due date in a 390 px list). A long value still ends in an ellipsis.
- An `ApplianceField` left to choose (`mergeSemantics` null) reads its child by what it brings to the semantics tree, on ui_core 0.3.2's `DesignField`, where it went by the child's type: one control is one node named by the label, and any group keeps each control's own node and tap. A group that names itself, a selector named as its field, is read once, where it read the field's label twice.

## 0.1.2

- A field holding a group of controls (a row, column or wrap of them, a selector, a stepper, a toggle group, a range slider, a tag input) keeps each control's own node and tap, and its label names the group. Before, with semantics on (a screen reader, or a browser that turned them on), a tap on any of them went to the first. `ApplianceField.mergeSemantics` is now null by default and decides by the child; true and false still force it.
- `ApplianceStepper` takes a `step` (one by default): each press moves the number by it, a step past a bound stops at the bound, and a key at its bound stands disabled.
- By day the display windows (charts, readouts, the time picker, the stepper's figure, code cells, badges, toasts and tooltips) are a pale LCD with dark figures, as on a clock radio; by night they stay smoked glass with lit figures. Chart traces on the LCD are inks that read at 3:1 or more, and the scale's figures at 4.5:1.
- Keyboard focus lights the part's own rim from inside, as a backlit key's edge glows, in place of a ring drawn around it. It reads at 3:1 or more against the part at rest, day and night; on the signal key the rim takes the legend's ink, and on a lit switch the ink by day and white by night. A text button or a link, with no face of its own, lights a plate just beyond its words (`ApplianceFace.focusReach`), so the light crosses no letter. `ApplianceMetrics.focusWidth` is the lit rim's width (2.5); `focusGap` and `focusRadius` are deprecated. `applianceFocusLight` gives a part that paints its own focus the same light.
- A stepper's window is as tall as its keys and wide enough for the longest number it can show, at any text size.
- Each position of a slide selector has its lamp just before its glyph and words, as a chip does (stacked in a narrow space, beside its glyph or over its words); the chosen one's is lit.
- A switch's slot lights in the signal when it is on, so on and off read at a glance; the cap's place and the bar and ring marks still say it without colour.
- On the day's LCD a toast's action reads at 4.5:1, and a tooltip stands off the panel in a dark bezel with a soft shadow.
- Large text, as Material copes with it: a time picker's figures and a calendar's days grow with the text up to twice their size, as Material's time picker's and calendar's do, their cells and keys with them, so the figures show whole and the keys stand clear; a calendar's weekdays keep apart. A date field and a chip grow with their words, so a date or a chip's descenders are never cut. A strip's and a rail's key names and badges grow up to 1.3x, as Material's navigation bar labels do. Stacked over its words in a narrow space, a selector position's lamp stands just above them.

## 0.1.1

- A selected radio keeps its lamp centred. Toolbar keys and tag-input keys fit the corners of their recesses.
- The light inside a fader or progress bar now stops the same distance from the end as from the sides.
- The toast glass follows its bezel. Toast keys and the banner close key sit evenly inside their frame and animate when pressed or focused.
- Confirmation buttons, navigation keys, delivery stages and timeline timestamps make room for larger text.
- Chart axes follow the system text size. Range sliders accept a `semanticFormatterCallback` for values such as prices.
- Empty-state messages are shown on a smooth panel, and their number display grows with the text. Product cards wrap availability badges below the price when space is limited.
- Appearance selectors keep their full labels at large text sizes. Disabled key labels have stronger light- and dark-theme contrast.
- Larder's account settings edit the name, address and saved card. Help opens delivery information and a local message form. Signing out hides the account and purchase history.
- Shop prices and filters respect the tax display preference. Checkout itemizes tax, and payment retries and receipts use the submitted delivery details and masked card number.

## 0.1.0

- Initial release with light and dark themes, form controls, responsive navigation, dialogs, sheets and interactive charts.
- Includes the Larder example app.

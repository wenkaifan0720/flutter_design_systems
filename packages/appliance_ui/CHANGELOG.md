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

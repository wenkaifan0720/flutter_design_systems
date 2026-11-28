## 0.9.0

- Requires ui_core 0.8.7: a sheet opened over a nav root, the date picker's too, stands above the shell's tab bar.
- **Corners on the theme**: `MinimalThemeData.shapeScheme` (ui_core's `RawShapeScheme`) holds Minimal's corners, 4, 8, 10, 14 and 18 by default, so nothing moves at rest. It is held to `MinimalThemeData.shapeLimits`: round only, each step from square to the most it holds before it reads as a pill (8, 12, 14, 20, 24), no stroke and no depth. Every part reads it, through `cardRadius`, `controlRadius`, `smallRadius`, `sheetRadius` and `theme.shapes`, now a view of the scheme. A square scheme squares the capsules too. A change eases across with the theme (at once under Reduce Motion); `copyWith`, `lerp`, `==` and `hashCode` see it. `MinimalShapes(radius: r).scheme` still sets every step from one radius.
- **A part's own corners**: a style's `corners` (ui_core's `RawCorners`) name a step per corner, start and end as the part reads, so they turn right to left. Minimal holds each to its steps, a corner the style leaves keeps the part's own, and a style's `shape` wins as given. A segmented control, a toggle group, a button group, a split button, a menu bar and a one-time code take them on their outer corners only: the cells or the thumb at the ends follow, concentric, and the joins stay square. A sheet takes its top corners (a drawer's foot stays square), a side sheet those of its inner edge. A press that changes a part's corners eases them. Radios, slider thumbs, avatars and status dots keep their own forms. The gallery's Foundations page shows one.
- **Forms**: `MinimalDatePickerPresentation.field` stands a date picker as a text field stands, its label over a box at the text field's edges, height and rim (a date and a time in two boxes), so a form of boxed fields keeps one field style; the README's form uses it. A `MinimalSegmentedButton` a `MinimalFormField` labels takes the column's width, as the fields beside it do (alone it keeps `MinimalLayout.controlMax`). A labelled `MinimalSwitch` prints its words in the ink on or off; the quiet ink read as disabled.
- **Pages**: on a wide window `MinimalScaffold.maxWidth` holds the page's column in the middle of its pane, not on its start edge: the bar, the body and the footer together, and a toast, centred on the pane, stands on the column. A nav root may own a `footer` or a `floating` control: it docks above a phone's tab bar, in both `MinimalAppShell` forms, so a form that is itself a place keeps its Save where the same form pushed does.
- **Dates**: a date picker writes its day as the app's language writes a date in a field (`RawWidgetsLocalizations.formatMediumDate`), so the field reads like the calendar it opens: "Nov 9, 2026" in English, "9 Nov 2026" in British English, Arabic in its own months and digits, as Material's date field does. It wrote "9 Nov 2026" in every English. The calendar's weeks start where the language's do (Sunday in English). `MinimalFormat.date` stays the app's own helper, day first, month as a word.
- **Host**: `MinimalHost(palette:, customize:)` builds the palette's day and night themes and hands both through `customize` (the app's own corners, density or type); a change of palette or appearance still blends.
- **Docs**: a swipe action says `destructive: true` for the danger ink (Minimal never reads a label's words), and the README's list shows it. A control in a `MinimalFormField` takes no `semanticLabel` of its own. `MinimalAppShell.header` is inset to the sidebar's gutter. The README's palette picker draws each palette's accent on a tile of its ground, as the example does; the ground alone was the surface's own colour.
- Deprecated `MinimalThemeData(shapes:)` and `copyWith(shapes:)`: pass `shapeScheme: MinimalShapes(radius: r).scheme`. They go in 0.10.0.

## 0.8.0

- Requires ui_core 0.8.3.
- **`MinimalAppShell`**, the app's frame, on ui_core's `RawAdaptiveShell`: the places in a tab bar under 600 wide, a rail under 960, a sidebar from there. With `.branches` each place keeps its own pages; a pushed page keeps the rail or sidebar beside it (and in the screen reader's tree) while a phone's tab bar steps away; choosing a place again returns to its first page. `MinimalShellAction` and `MinimalHost` are in the main library.
- **Palettes**: `MinimalThemeData.palettes`, the six as ui_core's `RawNamedPalette` (an `id` to store, a `label` to show, swatches by day and by night), replace the `presets` list of names; `MinimalThemeData.preset(id, brightness)` builds one. `MinimalHost(palette:)` builds both appearances from one and eases a change of palette or appearance.
- **Labels**: a label only a screen reader hears is `semanticLabel` on `MinimalIconButton`, `MinimalToggleGroup`, `MinimalCircularProgressIndicator`, `MinimalLinearProgressIndicator`, `MinimalComposerAction`, `MinimalBadge`, `MinimalCarouselView`, `MinimalMenu` (and `.button`, `.popover`, `showMinimalMenu`), `MinimalCheckbox`, `MinimalCheckMark`, `MinimalPopover`, `MinimalRadio`, `MinimalRadioGroup`, `MinimalMenuBar`, `MinimalTreeView`, `MinimalScrollArea`, `MinimalResizable`, `MinimalRating` and `MinimalSegmentedButton`; a drawn label stays `label`. `dart fix --apply` renames them. A list row's avatar of the title's own name stays out of the row's name; a status tag stays in it.
- **Forms**: `MinimalTextFormField` is a text field in a `MinimalForm`, as `TextFormField` in a `Form` (`validator`, `onSaved`, `autovalidateMode`; a failed `MinimalForm.submit` focuses the first field in error). `MinimalTextField.required` marks a field. `MinimalDatePicker.value` is nullable: an unset field shows its hint, in the sans at the value's size. A focused field in error keeps its danger edge. In a column every field takes the column's width.
- **Switches**: a `MinimalSwitch` in a column that stretches its children (a form's column) keeps its track's own size at the column's start; it stood the column's width. The example's and the README's Favourite switch print their words (`showLabel`).
- **Lists**: a row's trailing part takes its own width up to two thirds of the line, and a long tag ellipsizes instead of overflowing; a trailing menu keeps its own node (a swipe row's too).
- **Pages**: `MinimalScaffold.maxWidth` holds the app bar's title and actions, the body and the footer to one measure on a wide window.
- **Focus**: a menu row, a segment, a slider, a page number, a date wheel and every pressable show their focus as ui_core's parts do (`RawFocusShown`): after a key, not after a click, on the web too, where a click focuses through the semantics tree. A menu that closes after a click gives its trigger back the focus without a ring.
- **Text size**: a tag's glyph, the status and priority marks and an avatar up to a row's 40 px grow with the reader's text; dots stay 6 px.
- Removed: `MinimalLayout.minHitTarget`, `MinimalLayout.pointerHitTarget` and `MinimalChromeMetrics.sheetBar` (read `RawTapTargets.of(context).floorOn()`). `MinimalHitTarget` moves to `package:minimal_ui/minimal_host.dart`.
- **Sidebar**: `MinimalAppShell.extended` false folds a wide shell's sidebar to the rail, as `NavigationRail.extended` does; with `onExtendedChanged` a key at the sidebar's head (and the folded rail's top) folds and unfolds it, heard as the navigation menu, expanded or collapsed. The side's width eases between the two (at once under Reduce Motion) and the page keeps its state.
- **Tabs with panels**: `MinimalTabBar.controller` takes ui_core's `RawTabController`, shared with a `RawTabBarView` of the panels: a tap moves the panels, a swipe of the panels moves the strip, and a screen reader hears each tab control its panel. `selectedIndex` and `onChanged` stay the controller-free form. `MinimalTabBar.icons` puts a glyph before a tab's name, growing with the reader's text.
- **Alerts**: `showMinimalDialog(isAlert: true)` raises a question that wants an answer: a screen reader hears an alert (ui_core's `RawModalDialogRoute.isAlert`), and a tap on the scrim leaves it standing; Escape and its keys still answer. `barrierDismissible` is nullable: null closes a dialog from the scrim and leaves an alert. The example's and the gallery's delete and archive questions are alerts.
- **Any control in a form**: a select, a date, a checkbox or a radio group validates in a `MinimalForm` inside ui_core's `RawFormField`, its `errorText` on a `MinimalFormField` round it (the README's form shows one). `MinimalDatePicker.focusNode` and `MinimalRadioGroup.focusNode` let a failed submit focus them, and a date in error draws its pill's edge in the danger colour.
- **README**: each part in the building-blocks table links its page on the docs site, with Minimal chosen.
- `MinimalRadioOption.secondary` shows a widget after the label, as `RadioListTile.secondary` does (a palette's swatches); a screen reader hears the label alone.
- The example is Shelf, one app to copy (`example/lib/main.dart`): a list with a pushed page, a form that checks itself, a dialog and settings with the six palettes, each with its colours beside its name. The gallery is `example/lib/gallery.dart`. The README builds an app from it, and every Dart block in it compiles after its install line.
- **Messages under fields**: a field's error or help line grows open as it fades in, and fades before it folds away, so the fields under it move rather than jump; under Reduce Motion it is there at once.
- **The bar's keylines**: a pushed page's back button and the last action stand on the page's gutter, as the bar's doc says, their targets growing inward; they stood 4 px inside it, out of line with the page's words. The breadcrumb stands `barCrumbGap` from the back button's face.
- **Tags and select rows**: a neutral tag's hairline stands inside its edge, so it is as tall and as tight as a toned tag (it stood 2 px taller). A select row's up-down glyph, and the forward chevron of one that opens a sheet, ends its ink on the row's end keyline, as a list row's chevron does; it stood 4 px inside. Select and date rows that follow one another stand rule to rule (the example's form).
- **Focus after a mouse**: a Tab lights a part's focus after a mouse that came before any other input (a trackpad on an iPad, a mouse on Android); it stayed unlit. The pressable, menu rows, segments, the slider, page numbers and the date wheel feed `RawFocusShown` the focus itself, not the detector's highlight, which such a mouse leaves stale.

## 0.7.0

- Requires ui_core 0.7.1. Tap targets follow ui_core's tap floor, `RawTapTargets.of(context).floorOn()`: 40 × 40 at a finger, 24 × 24 at a pointer (Minimal held 44 of its own). List rows stay 44 at the standard density.
- Deprecated `MinimalLayout.minHitTarget`, `MinimalLayout.pointerHitTarget` and `MinimalChromeMetrics.sheetBar`: read `floorOn()` instead. They go in the next minor.
- `MinimalChipRow`, a combobox's tags and `MinimalPropertyBar` space their chips with ui_core's `RawChipGroup`, so neighbouring targets meet rather than overlap. On touch a multi-select's rows of tags stand 40 apart, so each tag's remove button keeps the 40 floor; at a pointer they stay 4 px apart.
- Three new presets, `iris`, `lagoon` and `berry`, join `standard`, `graphite` and `ember`, each in light and dark. The example's Foundations page shows all six.
- `MinimalThemeData.from` derives its colours with ui_core's `RawPalette`, so text, borders and the accent meet contrast on every ground. A brand colour stays the button's fill wherever white or the ink reads on it.
- Small reading marks meet contrast: step numbers, a selected row's caption, the tree's chevron, grips, a field's clear button, and a field's leading icon when it is the field's only name.
- Page info and spoken positions use ui_core's `positionLabel` (Arabic: "٦ من ١٢").
- `MinimalDatePicker` and `MinimalTimePicker` open in a sheet with Cancel and Done on windows under 600 px wide.
- `MinimalTypeface.fallback` names fallback font families for every text style.

## 0.6.0

- Requires ui_core 0.6.0, whose `Design*` names are `Raw*` now (`RawTapTargets`, `RawInventoryEntry`, `RawModalDialogRoute` and the rest). `dart fix --apply` renames them in an app (ui_core's `lib/fix_data.yaml` holds them); Minimal's code, docs and examples use the new names, the README's `RawWidgetsLocalizations` among them.
- A calendar writes its days in the app's digits (`RawCalendarDayDetails.label`): Arabic-Indic in Arabic, as its dates and times already were.

## 0.5.0

- Needs ui_core 0.5.1.
- Field words take `InputDecoration`'s names: `label` is `labelText`, `hint` is `hintText`, `helper` (and `MinimalFormField.help`) is `helperText`, `error` is `errorText`, and `MinimalSelect.prompt` is `hintText`, on `MinimalDatePicker`, `MinimalDateRangePicker`, `MinimalCombobox`, `MinimalMultiSelect`, `MinimalTextField`, `MinimalSearchField`, `MinimalComposer`, `MinimalFormField`, `MinimalTextArea`, `MinimalInputGroup`, `MinimalPasswordField`, `MinimalInputOtp`, `MinimalInputRow`, `MinimalTimePicker`, `MinimalSelect`, `MinimalNumberField`, `MinimalCommand`. `dart fix` renames them.
- `MinimalToggleGroup`: `onChanged` is `onSelectionChanged`, `multiple` is `multiSelectionEnabled`, `allowEmpty` is `emptySelectionAllowed`, as Flutter names them. `dart fix` renames them.
- `MinimalDatePicker`: `first` is `firstDate`, `last` is `lastDate`, `today` is `currentDate`, as Flutter names them. `dart fix` renames them.
- `MinimalCalendar`: `today` is `currentDate`, as Flutter names it. `dart fix` renames it.
- `MinimalDateRangePicker`: `today` is `currentDate`, as Flutter names it. `dart fix` renames it.
- `MinimalCombobox`: `displayString` is `displayStringForOption`, as Flutter names it. `dart fix` renames it.
- `MinimalMultiSelect`: `displayString` is `displayStringForOption`, as Flutter names it. `dart fix` renames it.
- `MinimalTextField`: `onFocusChanged` is `onFocusChange`, as Flutter names it. `dart fix` renames it.
- `MinimalSearchField`: `onFocusChanged` is `onFocusChange`, as Flutter names it. `dart fix` renames it.
- `MinimalDisclosure`: `onChanged` is `onExpansionChanged`, `leading` is `icon`, as Flutter names them. `dart fix` renames them.
- `MinimalPageDots`: `count` is `pageCount`, `selectedIndex` is `page`, `onChanged` is `onPageChanged`, as Flutter names them. `dart fix` renames them.
- `MinimalComposer`: `style` is `variant`, as Flutter names it. `dart fix` renames it.
- `MinimalRadioOption`: `description` is `subtitle`, as Flutter names it. `dart fix` renames it.
- `MinimalMenuItem`: `destructive` is `isDestructiveAction`, as Flutter names it. `dart fix` renames it.
- `MinimalComposerAction`: `style` is `variant`, as Flutter names it. `dart fix` renames it.
- `MinimalComposerStyle` is `MinimalComposerVariant`, and `MinimalTextTheme.of` is `MinimalTextTheme.from`. `dart fix` renames them.
- `MinimalThemeData.lerp` is static, `MinimalThemeData.lerp(a, b, t)`, as `ThemeData.lerp` is.
- `MinimalSheetAction.onPressed` is required and may be null, as `ElevatedButton.onPressed` is: a null callback disables the action. An action that only closes its sheet is `MinimalSheetAction.cancel(label)`.
- `MinimalRadio.onPressed` is required and may be null, and `enabled` is gone: a null `onPressed` disables the radio. The mark alone, for a row that takes the press itself, is `MinimalRadio.mark(selected: ...)`.
- `MinimalMultiSelect.enabled` is gone: a null `onChanged` disables the field.
- A sheet's actions sit side by side while they fit, on one line with its accessory (a "create another" switch) when there is room, and stack once they don't (ui_core's `RawActionBar`).
- A dialog in place stacks its actions as wide as its card, the main one on top, as a raised one does (ui_core's `RawActionBar`). Before, stacked, each kept its own width at the card's end.
- A field's label names it for a screen reader, and its error and help are its hint, with the field marked invalid while in error (ui_core's `RawInputDecorator`).
- A combobox's and a multi-select's text input say whether their list is open (expanded).
- The date range picker's calendar opens on the side where its whole month fits (`RawPopoverFit.whole`).
- A select's sheet opens with its chosen option focused, so the keys go on from it, as its menu does; `MinimalSelectionList.autofocus` does the same for a list of your own.
- A date picker's calendar, in its popover or its sheet, opens with the focus on its chosen day, so the arrow keys walk on from it; `MinimalDatePicker.autofocus` does the same for an inline one. Before, the focus stayed on the popover (or, in the sheet, nowhere).
- A chart writes its figures in the reader's digits and separators (German's 1,5), its scale's gutter measured by ui_core (`DesignChartValueFormat`, `DesignScaleTick.widestLabel`); the line, area and pie charts still write thousands as 1.2k and 12k.
- Toasts keep clear of whatever bar runs along the screen's foot (the navigation bar, a screen's footer) through ui_core's `RawToasterKeepClear`, rising and settling as the bar comes and goes. A bar of your own does the same wrapped in `RawToasterKeepClear`.
- `MinimalPageFoot` goes: wrap a footer of your own in ui_core's `RawToasterKeepClear` to keep toasts clear of it; `MinimalScaffold.footer` already does.
- By night a destructive fill is the danger tone at 60% over the ground (less where its white words need it for 4.5:1), quieter than the accent, so Discard is not as loud as Save.
- A menu bar's items stand 44 px tall on touch; 32 with a pointer, as before.
- A `MinimalMenu.button` in a `MinimalListTile`'s trailing slot is ghost: its glyph alone, in the row's quiet ink, with no hairline square at rest. Elsewhere it keeps the square.
- The date range picker ends in the up-down chevron, as the select and the combobox do.
- `MinimalMultiSelect.onChanged` may be null, which disables the field as `enabled: false` does: it dims, its tags lose their remove keys and it takes no typing.
- `MinimalColorPicker.onChanged` may be null, which disables the picker: it dims, and its area, sliders, hex field and swatches take no press, drag, typing or focus.
- `MinimalComposer.model` defaults to null: the comment box's pill shows only when `model` and `onModel` are both set, never a default "Everyday" label.

## 0.4.1

- Stands on ui_core 0.4.1. `MinimalMenuEntry` takes `isDestructiveAction`: a menu bar command that destroys something (Delete) stands in the destructive ink, as a `MinimalMenuItem` marked `destructive` does.
- `MinimalDialog` takes `actions`, a list of `DesignDialogAction`s, for a question with more than a confirm and a cancel (Cancel, Discard, Save changes): the dismissive one first, the main one last. They stand in a row at the end and stack, the main one on top, when they don't share a line, raised or in place. An in-place card's two buttons stack the same way (they used to wrap, the confirm under the cancel).
- A form section's date, time and choice rows span the column, ending on the same edge as the text fields beside them (they stopped at a control's width).
- A pressable `MinimalListTile` keeps a control in its trailing slot (a row's menu key) a node of its own: a screen reader hears the row by its words, and reaches and presses the control alone.
- `MinimalMenu.button`'s square is a hairline on whatever it stands on, so a selected row's wash runs under it.
- A stat's value keeps its word space at a tile's and a strip's size (`15h 45m` read as `15h45m`).
- The check on a chosen row (a menu's, a select's sheet, a `MinimalSelectionGroup`) is in the row's ink, not the accent.
- A `MinimalMenu` opens on its key's leading edge, its right edge under right to left, and still opens, in what room there is, with a keyboard up on a short screen.
- A `MinimalIconButton` without `onPressed` dims as `MinimalButton` does: a toned variant (`primary`, `destructive`) turns to the muted face and the foreground ink.
- `MinimalBarChart` takes `format` for the value a screen reader hears. Charts' read values use the locale's digits (`MinimalLocalizations.digits`), and line, area and donut labels follow the reading direction.
- A `MinimalSparkline` of zeros lies along its foot; any other flat series still runs through the middle.
- A `MinimalDateRangePicker` opens its calendar where the whole month fits, below the field or else above it; where neither side holds it, the panel scrolls within the room.
- A `MinimalMultiSelect` with `enabled: false` keeps its tags when a screen reader runs a tag's Remove action.
- `MinimalDensity.copyWith` replaces either step, as `VisualDensity.copyWith` does.
- By night the standard preset's filled button, and every solid accent, stands in a crisp indigo with white words, and a destructive button in a deep red with white words; the accent's and the danger's words and links keep their lighter inks.

## 0.4.0

- Stands on ui_core 0.4.0, on Flutter 3.47 or later as before. The ui_core types minimal_ui's API names take their new names (`DesignOverlayPlacement` is `RawPopoverPlacement`, and so on); `dart fix --apply` moves your code.
- `MinimalRadioGroup` stands on Flutter's `RadioGroup`, each option a `RawRadio`, with ui_core's `RadioGroupKeyboardFix` round them, in place of ui_core's `DesignRadioGroup` (deprecated). Its API, its look and its keys are unchanged: one Tab stop, at the choice or else the first option that can be chosen (also while the chosen one is turned off), and arrows that choose as they move, wrap, pass an option that is off and swap Left and Right right to left. The selection click now sounds for a choice made from the keys too, not only for a tap. On iOS and macOS a screen reader also hears an option as selected or not, as Flutter's `Radio` reads.
- `MinimalSelectionGroup` is a radio group too: its `MinimalChoiceRow`s stand in Flutter's `RadioGroup` as `RawRadio`s. The group is one Tab stop, on the chosen row (the first row Tab can reach while there is none), and the arrow keys choose the next or the previous row, as a radio group's do; a choice calls the row's `onPressed`, and a tap, Enter or Space on the chosen row still calls it again (a sheet that closes on a choice closes on the chosen row too). Previously each row was a Tab stop of its own, and Up and Down moved the focus without choosing. A `MinimalChoiceRow` outside a group is unchanged.
- Radios that draw their own rows group in Flutter's `RadioGroup`: each row a `RawRadio` that draws a `MinimalRadio`, without `onPressed`, as its mark. `MinimalRadio`'s documentation shows how.

  ```dart
  // Before
  DesignRadioGroup<String>(
    options: const ['free', 'pro'],
    value: plan,
    onChanged: (value) => setState(() => plan = value),
    itemBuilder: (context, value, node, select) => Row(
      children: [
        MinimalRadio(selected: value == plan, onPressed: select, focusNode: node),
        Text(value),
      ],
    ),
  )

  // After
  RadioGroup<String>(
    groupValue: plan,
    onChanged: (value) => setState(() => plan = value!),
    child: RadioGroupKeyboardFix<String>(
      child: Column(
        children: [
          for (final value in const ['free', 'pro'])
            Builder(
              builder: (context) => RawRadio<String>(
                value: value,
                mouseCursor: WidgetStateMouseCursor.clickable,
                toggleable: false,
                focusNode: nodes[value]!, // one FocusNode per value, the State's
                autofocus: false,
                groupRegistry: RadioGroup.maybeOf<String>(context),
                enabled: true,
                builder: (context, radio) => Row(
                  children: [
                    MinimalRadio(selected: radio.value ?? false),
                    Text(value),
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
  )
  ```
- `MinimalTooltip` stands on Flutter's `RawTooltip`, with ui_core's `RawTooltipFocusFix` (the keyboard's focus shows it) and `RawTooltipPlacement` (where it goes), in place of ui_core's `DesignTooltip` (deprecated). It looks, moves and reads as before. One difference: running the pointer along a toolbar, each tip now waits its `waitDuration`; ui_core's tooltip showed the next one at once.
- In `minimal_parts`, `MinimalBareTextField`, the bare `TextField` that Minimal's text entries share, takes the place of `minimalBareDecoration`, so no Material type stands in the parts' API. It draws and behaves as before.

## 0.3.5

- In a menu, the command the keyboard is on wears Minimal's thin accent focus ring, drawn inside its row so it fits between the rows above and below, as every other part shows the keyboard's focus. The pointer's row keeps the muted fill alone. Previously the keyboard's row showed only the fill, which by night read as the pointer's hover. This holds in every menu: `MinimalMenu`'s and the lists `MinimalSelect` and `MinimalProperty` open, `MinimalMenuBar`'s, a context menu (`MinimalMenuTrigger.longPress`) and `MinimalSplitButton`'s. `MinimalKitRow` gains `ring` (off by default) for a list of commands; a combobox's or a multi-select's list, whose keys stay in its text field, keeps the ring on the field.
- A checkbox, a switch, a radio, a `MinimalChoiceRow`, a `MinimalStatusIcon` with an action and a data table's select-all box read as that control alone, with its state, and no longer also as a button, as Flutter's do. `MinimalPressable` adds the button role only to a control that is not checked, toggled or one of a set where one is chosen, the rule ui_core 0.3.4's `DesignPressable` follows. An on/off `MinimalIconButton` (`selected` set) reads as Flutter's `IconButton(isSelected:)` does: a button, selected or not. It used to be a button toggled on or off. In a browser, Enter no longer chooses a `MinimalChoiceRow`; Space does, as for every radio.
- `MinimalRadioGroup` takes its keys from ui_core's `DesignRadioGroup`, over Flutter's `RadioGroup`, and answers them as before: one Tab stop, at the choice or else the first option that can be chosen, and arrows that choose as they move, wrap and pass an option that is off. A press on the option already chosen no longer reports it again.
- `MinimalInventoryGallery` wraps a checkbox's words within its column where they are wider than it (a narrow phone at a large text size), instead of running past it.
- Stands on ui_core 0.3.4.

## 0.3.4

- A time's figures and a calendar's days are in the reader's digits: the time picker's hours and minutes, the compact row's time, and the days of the month (Arabic-Indic in Arabic, so the row prints ٧:٣٠ م), as Material's time picker writes its hours. Previously they were ASCII digits in every locale. `MinimalLocalizations` gains `digits` (ASCII by default, so a subclass keeps compiling; `MinimalLocalizationsEn` writes the shared words' digits), and `MinimalFormat.clock` and `MinimalFormat.time` take `words`, as `time12` does. English and German read as before.
- A date picker's compact row prints its date in the reader's months and digits (Arabic: ٢٠ نوفمبر ٢٠٢٦), as Material's date picker does. Previously it read "20 Nov 2026" in every language. `MinimalLocalizationsEn`'s `months` and `monthsShort` come from the shared words (`formatMonth`, `formatShortMonth`), as its weekdays already did, so they are unchanged in English, and an app's own `MinimalLocalizations` months still win. `MinimalFormat.date`, `dayMonth` and `stamp` write the digits of the `words` they are given, and `MinimalCalendar`'s range reads the same way. With no `words`, they print as before.

## 0.3.3

- The time picker's column names and a 12-hour clock's AM and PM come from ui_core's `DesignLocalizations` (`timePickerHourLabel`, `timePickerMinuteLabel`, `anteMeridiemAbbreviation`, `postMeridiemAbbreviation`), in all 30 of its locales: a screen reader says "Stunde" in German, and Arabic prints 7:30 م. Previously they were "Hour", "Minute", "AM" and "PM" in English in every locale. `MinimalLocalizations` gains `anteMeridiem` and `postMeridiem` (English by default, so a subclass keeps compiling), and `MinimalFormat.time12` takes `words`.
- `MinimalLocalizations.delegate` loads Minimal's words for every locale: the shared ones in the locale's language, from ui_core's translations or the app's own `DesignLocalizations`, and Minimal's own in English. These are the words the parts already used with no Minimal delegate registered.
- A date picker's compact row prints its date with the words in force (an app's own `MinimalLocalizations` months).
- When a date picker's pill grows at a large text size, the row keeps its inset above and below the pill, so the pill no longer sits on the row's rule.
- `MinimalRadioGroup` works from the keyboard as Flutter's `RadioGroup` does. It is one Tab stop: Tab lands on the chosen option (the first while none is chosen) and the next Tab leaves the group. The arrow keys choose the next or previous option, skipping disabled ones and wrapping at the ends: Down and Right for the next, Up and Left for the previous, with Left and Right swapped in a right-to-left layout. Previously Tab stepped through every option and the arrows moved focus without choosing.
- A `MinimalRadioGroup` with `direction: Axis.horizontal` lays its options side by side, each as wide as its words. Previously each option took the full width, so the options stacked as in a column.

## 0.3.2

- At large text sizes a date picker's value grows with the text: its pill and row get taller and the date wraps between its words (20 Nov over 2026) instead of losing the year or the foot of its figures.
- Bar chart axis labels grow with the text size up to 1.3× (`MinimalBarChart.maxLabelScale`), so a week's day names stay whole in their columns at 300%.
- In the ember preset's light theme, secondary text is slightly darker, so a read-only field's prompt reads at 4.5:1 on the sunken fill.
- In themes from `MinimalThemeData.from` with a `neutral`, secondary text is slightly darker, to keep 4.5:1 on sunken fills.

## 0.3.1

- A focused field shows focus by its own edge: text fields, fields with add-ons, search, multi-select, combobox, password, text area and the composer turn their outline to the accent, 1.5 px thick and drawn inward, with no ring outside it. A click or a tap shows it as Tab does, and an invalid field takes the accent while it has focus. The active verification-code cell uses the same 1.5 px accent, and keeps it when validation fails.
- Multi-select chips follow the field’s corner radius and have even padding at compact and standard density, including at large text sizes.
- Menu highlights fill the entire touch row and follow custom menu corners.
- Snack-bar actions and banner close buttons sit evenly inside the message outline.
- Keyboard focus outlines the reorder grip. Navigation rails grow with text size. Chart callouts show the full series name and value.
- Escape dismisses an empty command palette on the first press. Enter or Space activates the first enabled action in a newly opened action sheet.
- Field prompts and disabled button labels are easier to read in light and dark themes.
- Picker rows and the gallery’s customization choices wrap at large text sizes. Settings rows show the full label, and the switch and checkbox examples respond to taps and keyboard input.
- Filters and switches give pointer hover feedback. Picker labels and dialog actions stay vertically centered.
- Ritual downloads current habits as CSV on the web and copies them on native platforms. Favourite choices survive navigation. After erasing all habits, Today offers to create one.
- Lund Bakery filters orders and revenue by date. Order details show the customer’s full name at large text sizes.

## 0.3.0

Built on ui_core 0.3.0. Minimal's menus, tooltips, dialogs, sheets, tabs, swipe-to-delete, rating and charts now take
their behaviour from ui_core (its focus, keys, semantics and gestures) and keep Minimal's paint and motion: they look
as they did, and they do more. Two shortcut fields change type; the other breaks, below, touch only code that
took a tooltip for a `StatefulWidget` or told a sheet by its route's type.

### Breaking

- `MinimalMenuItem.shortcut` and `MinimalMenuEntry.shortcut` are a `MenuSerializableShortcut`, no longer a `String`:
  `shortcut: const SingleActivator(LogicalKeyboardKey.keyK, meta: true)` where `shortcut: '⌘ K'` was. The caps print
  in the platform's order and words (`⇧ ⌘ N` on a Mac, `Ctrl Shift N` elsewhere) and are read out once in words; a
  split button's menu prints the same. The command palette and search keep their string hints (sequences such as
  `G T` and `/` are no single shortcut). `MinimalKbd.shortcut(activator)` prints one anywhere; `MinimalKbd.chord`
  stays for a hint of your own.
- `MinimalTooltip` is a `StatelessWidget` on ui_core's `DesignTooltip`, no longer a `StatefulWidget` (a
  `GlobalKey<State<MinimalTooltip>>` no longer fits it). Its constructor is unchanged.
- `MinimalSheet.pageRoute` and the action sheet build ui_core's `DesignBottomSheetRoute`, no longer Flutter's
  `ModalBottomSheetRoute`: code that tells a sheet by `route is ModalBottomSheetRoute` checks for
  `DesignBottomSheetRoute` too, as `MinimalRouteChrome` does. The side sheet and the dialog move on springs
  (`MinimalChromeMetrics.routeDamping`, `sheetStiffness` and `dialogStiffness`, which keep the 180 ms and 120 ms
  they took before); ui_core 0.3.0 removed `DesignSideSheetRoute.transitionDuration`.

### Behaviour that changes

- A dialog opens with focus on its safe answer: Enter on a destructive question ("Delete 3 files?") keeps, where it
  confirmed before; on any other question Enter still confirms. Tab stays inside, Escape closes, and its title names
  the route for a screen reader.
- `MinimalTabBar` is one stop for Tab, on the current tab; the arrows move and choose, round the strip, and a screen
  reader hears a tab and its place ("Inbox, Tab 2 of 4") where it heard a button.
- `MinimalDismissible` deletes past 40 % of the row, as Flutter's `Dismissible` does; a shorter swipe holds the
  Delete word open for a tap, and the keyboard opens it. The page removes the row, so it no longer folds its height
  away.
- `MinimalRating` takes a drag and the number keys (End for all, Home for none) as well as a tap; without
  `allowClear` it holds at one star or more. A mouse over the stars previews what a click would set in the quiet ink,
  and a click answers at once: its score shows in the full ink until the pointer moves again.
- A line or area chart's readout is one point of one series at a time ("Mon, Runs: 3"): Left and Right walk the
  labels, Up and Down the series, Home and End go to the ends. A donut's arrows stop at its first and last slice
  instead of going round, and each slice says its share ("60%, Rent: 60"). Right to left, a donut runs
  counter-clockwise.

### New, from ui_core 0.3.0

- Context menus open on a right click, a long press, Shift+F10 or the context-menu key; tooltips on hover, focus and
  a long press, and Escape puts one away. A menu bar's menu takes focus as it opens.
- `MinimalCombobox(search: ..., debounceDuration: ...)` searches as you type, with its loading, empty and error
  rows.
- A bottom sheet closes on a drag down (handing the drag to its list when the list can scroll), on Escape and on the
  barrier, gives focus back to what opened it, and rises above the keyboard.
- Haptics go through ui_core's `DesignHaptics`, so an app can turn them off or swap them in one place.

### Fixes

- "Try again" was English in every language; `MinimalLocalizations.tryAgain` now reads the app's own.
- `dart doc` reports no warnings: the host library is the documented home of its names (it was the parts library),
  and four references that pointed at nothing are code spans.
- A `MinimalPreview` placed on a page hid everything above it from screen readers: the route under its own app
  stands a modal barrier, which hides what painted before it in its semantics container. The preview is now a
  container of its own (the gallery's demo windows too).
- `showMinimalActionSheet` on a wide window spread its card across the whole window; it now stands centred at a
  bottom sheet's width (`MinimalBottomSheet.widthCap`), as its inventory specimen and `showMinimalBottomSheet` do.

### Development

- The review checks come from `package:ui_core_test` (a dev dependency, 0.1.0), where ui_core 0.3.0 moved them.
- The example and the tests import `material_ui` and `cupertino_ui` rather than Flutter's Material and Cupertino
  libraries, which Flutter 3.50 deprecates: the package analyzes clean on Flutter 3.47 and 3.50.
- The package's page leads to the live gallery (its homepage) and the issue tracker, and opens on the Tracker app
  at 1440 px beside a phone.

## 0.2.1

Built on ui_core 0.2.1. Nothing is renamed or removed: an app on 0.2.0 compiles on 0.2.1 unchanged.

### Fixes

- Reduce Motion now includes iOS's. Minimal read only `MediaQuery.disableAnimations`, which Flutter never sets on
  iOS, so on an iPhone with Reduce Motion on, a switch's thumb, a counter, a reveal and the press feedback moved as
  designed, and the busy button's mark, the spinner, the progress bar of no known total, the skeleton, the loading
  state and a media slot's sheen ran on. `context.minimalStill` now reads ui_core's `designReduceMotionOf` (Android's
  Remove animations, the web's `prefers-reduced-motion` and iOS's Reduce Motion), and each of those loops stops and
  starts again as the setting changes, on any platform.
- A heatmap's label said "1 of 1 days kept", and in English whatever the app's language. It now comes from
  `MinimalLocalizations.daysKeptOf(kept, total)` ("1 of 1 day kept"), with both counts as numbers, so a translation
  says them in its own plural forms. `daysKept(count)`, a week's dots, reads it.
- An avatar group's "Ana, Ben and 3 more" was English in every language; it now comes from
  `MinimalLocalizations.namesAndMore(names, more)`, the count as a number.
- From ui_core 0.2.1: a menu, a select or a popover gives focus back to the control that opened it as it closes; a
  combobox's or a tag input's list no longer opens again on the focus given back to its field; Home and End in a
  menu keep the row they reach in view.

### Development

- The tests come in three tiers. `flutter test --exclude-tags goldens,sweep`, the everyday tier, runs every check
  with each matrix (pages by width, text size and direction; apps by width and appearance; platforms; corner
  families; languages; densities) once, in turn; `--tags sweep` runs the rest of the matrices, and `--tags goldens`
  the pixel goldens, recorded on macOS. All three together are the whole suite.
- The tests' walks of whole gallery pages and app screens run with leak tracking paused (ui_core's test template's
  `longWalkLeakTesting`); each part's own tests, and the apps' happy path, keep it. Tracked, a file of page walks grew
  test by test to 3.4 GB in one test process and ran two and a half times as long.

## 0.2.0

Built on ui_core 0.2.0. Nothing is renamed or removed: an app on 0.1.0 compiles on 0.2.0 unchanged (one widget it
no longer needs is deprecated, below). In a debug build, a value out of its range now fails at once.

### Fixes

- Fields, sheets and menus no longer crash in apps set to a language other than English; their built-in labels now
  follow the app's language.
- Selecting text on iOS no longer throws when the theme sits under `home` rather than in the app's `builder`:
  `MinimalTheme.of` now gives the standard theme where no `MinimalTheme` is in scope, as `Theme.of` does, and
  `maybeOf` still answers null.
- A field's selection handles and text menu follow the platform the app's theme sets, or a debug session switches
  to; they kept the platform Minimal's theme was first built on.
- Page routes move Minimal's way under `MinimalTheme` alone, on every platform: a page fades in over 8 px, and a pop
  reverses it. Only `MinimalHost` set it before; elsewhere a pushed page took the platform's slide or zoom and flew
  in. That reaches the routes of the Material the package is built on (`material_ui`). An app on Flutter's own
  `package:flutter/material.dart` names the new `minimalPageTransitions` map in its `ThemeData`, as the README's
  setup and the example do.
- An open list shows its choice at a glance, as Minimal shows every choice. In a select's menu or sheet, a
  combobox's list and a menu that picks one, the chosen option's words are in the full ink at medium weight beside
  its check, and the other options are muted. The row under the pointer or the keyboard takes the muted fill instead
  of the selection's tint, so it never reads as a second choice. A checked menu-bar item's words are medium weight
  too.
- A menu's keys are a menu button's, from a select, a property, a property pill or `MinimalMenu`. Opened from a key
  (Enter, Space, or Down, which now opens it too) it starts on the chosen item, else the first enabled one. The
  arrows walk the enabled items round, Home and End go to the ends, a letter goes to the next item it starts, Enter
  takes the item, and Escape closes the menu; either way the keys go back to the control. A menu the pointer opened
  takes the arrows at once: before, they did nothing until Tab reached an item. The item the keyboard or the
  pointer is on takes the muted fill, and a screen reader hears it focused; before, the pointer showed nothing and
  the keyboard a ring.
- A combobox's and a multi-select's list keys are ui_core's: Up and Down go round the ends, Down or Up on a closed
  list only opens it, on the chosen option, the list shows every option until the words are edited, and a long list
  opens with its chosen option in view and keeps the highlighted row in view. The pointer moves the one highlighted
  row, as in a menu; before, the pointer's row and the keys' row were two, both filled. A menu bar's menu goes to the
  item a typed letter starts.
- A menu bar's menu keeps a menu's one place: the row with the keys alone is filled, and the pointer moves the keys.
  Before, the keys' row and the pointer's were two, both filled, and an arrow went on from the keys' row. A menu the
  pointer opened lights no row and its first arrow lands on the first; before, the first arrow went to the second,
  or after any key the first row lit as the pointer opened it.
- In a browser Enter presses a button, a link, a menu's trigger and a menu's item, as Space does: Flutter maps Enter
  on the web to a button's press alone (`ButtonActivateIntent`), which Minimal's buttons did not take. A checkbox and
  a radio keep to Space there, as on the web.
- In a browser, typing goes on after Enter in a combobox's field, a multi-select's and the command palette's
  search: each keeps the focus after Enter, and took it in `onSubmitted`, so Flutter restarted its text input,
  which in a browser then took no typing (the field looked focused, letters went nowhere). They take Enter in
  `onEditingComplete` now. `MinimalSearchField` gains `onEditingComplete` for a search that stays focused. On a
  phone the palette's search ran nothing on the keyboard's action key: it gave up the focus first.
- A multi-select's entry is no longer built again as its first tag comes or its last goes, which closed its text
  input mid-typing.
- On iOS a swipe from a page's leading edge pops it again, the page following the finger: `minimalPageTransitions`
  wraps Minimal's push in ui_core's `DesignSwipeBackPageTransitionsBuilder`. Minimal's push replaced iOS's, and with
  it iOS's edge swipe.
- Android's back closes a combobox's or a multi-select's open list, a split button's or a menu bar's menu, a popover
  and a date range's calendar before it pops the page (ui_core's); it popped the page with them open.

### Words in the app's language

- Opt in as ui_core's README shows, with `DesignLocalizations.delegate` beside Flutter's
  (`...GlobalMaterialLocalizations.delegates`): the words Minimal shares with every look (Back, Cancel, Search, the
  months and weekdays) then come in the app's language, of the 30 ui_core speaks, and the text menu's Copy and Paste
  in Material's and Cupertino's own translations. A language neither speaks gets English.
- Minimal's own words (task statuses, priorities, counts) load through a delegate, `MinimalLocalizations.delegateOf`,
  so an app can give them in its language; the status icon, badge and segment bar speak them. A status's and a
  priority's names are words of their own (`taskDone`, `priorityHigh` …; `MinimalTaskStatus.labelIn(context)`
  picks one), so a status component copied into an app still speaks the app's words.
- The example's right-to-left mode speaks Arabic rather than English reordered.

### Taps and keys

- Every control's tap target is at least 44 by 44 at a finger and 24 by 24 at a pointer, laid out where it is drawn
  (ui_core's `DesignTapTarget`), so a parent smaller than 44 no longer cuts it. `MinimalPressable` takes
  `tapAlignment`: a bare checkbox, switch or radio stands on its start edge, a row's trailing control on its end.
- A field takes a tap anywhere in its outline, its edge included, and puts the caret on its line; its clear key and
  password eye each own a finger-wide slot as tall as the box, so in the taller toolbar search a tap above or below
  the clear glyph clears too.
- The composer's attach and send take the air over them when the draft grows or an attachment chip stands above
  (under a chip the row stands a finger tall); a multi-select tag's rim, and the air over it, belong to its remove
  key; a code block's copy key reaches the block's top edge.
- Rows, sortable headers, tree rows, activity entries and folding group headers that press stand at least 44 tall at
  a finger, whatever the density; a pointer keeps the compact heights. A segment takes its track's whole height, a
  joined strip's cells stand a finger wide, and page dots are one pager control (a tap before the current dot steps
  back, after it on; a screen reader adjusts it). The time wheel picks the row a tap lands on.
- A whole radio option (mark and words) presses as one control and reads as a radio in its group.
- A tap on the top of a field just under a focused one reaches it: the focused field's hidden selection handle, which
  Flutter keeps under its caret, no longer takes it.
- Tab no longer stops on a raised dialog's card, where it showed nothing; focus still rests there, so Enter answers.
- `MinimalHitTarget` is deprecated: each control now lays its own target out, so the wrapper does nothing a caller
  needs. Remove it.

### Text, layout and cursors

- Text grows to 200% (it was capped at 130%): the rail and the menu bar scroll rather than overflow, and from 160% a
  list row's trailing part and meta, a property's value (on up to two lines), a form row's control and an activity's
  time move under the words they belong to.
- Data reads left to right in a right-to-left app: an activity's time and a section header's count keep their order
  (`28 Aug 09:06`, `71 / 82`). A short weekday in a script that does not abbreviate by letters prints whole.
- A navigation drawer's head stands in a band a page's bar tall, so it lines up with the bars of the panes beside it.
- On a phone a dialog and every floating sheet start on the page's margin; the side sheet is square, running the
  screen's height from an edge.
- Fields show the text cursor over their whole row, a radio option and a donut the click cursor, a line chart's plot
  the crosshair; a disabled slider takes no drag.
- No square shape stands inside a round card: the command palette's rows and a card's revealed note are drawn on the
  card itself.

### Customisation

- `MinimalThemeData.iconStroke` lies between 1.5 and 2, the strokes of the two Lucide cuts the icon font draws: a
  debug build asserts it, with Minimal's rule in the message (an assert rather than a clamp, so a stroke the look
  cannot draw is seen where it is set).
- The docs of the chip's and the segmented button's component themes and of the three shadows name what Minimal never
  draws: a selected fill (the tinted pill) and a coloured or spread shadow (a glow).
- The README's "Make it yours" lists the knobs and the 23 component themes as they are.

### Development

- Every public widget describes its fields in the widget inspector and in test failures (`debugFillProperties`).
- A value out of its range fails at once in a debug build, with what was given, as a slider's and a number
  field's already did: a range slider's or a rating's value past its ends, a pager's page or a dot past the last, a
  step past all done, a heatmap's day or level out of its list, a non-positive size, stroke, height or code length.
- Parameters that mean the same on every part (`focusNode`, `autofocus`, `textInputAction`, `readOnly`, `loading`)
  share one doc.

## 0.1.0

First release of Minimal as a package.

- **The theme.** `MinimalTheme(data:)`, the one install widget, with `of`/`maybeOf`, and `AnimatedMinimalTheme`.
  `MinimalThemeData` is shaped like `ThemeData` (`copyWith`, `lerp`, equality, diagnostics), with three presets
  (standard, graphite, ember), each designed in light and dark, and `MinimalThemeData.from(primary:, neutral:)` for an
  app's own colours, which keeps every role's contrast whatever colours it is given. The colour roles take shadcn's
  names: `background`, `foreground`, `card`, `muted`, `mutedForeground`, `primary`, `primaryForeground`,
  `destructive`, `border`, `input`, `ring`, with subtle fills and text inks beside the status colours.
- **The knobs.** `MinimalShapes` (one radius and the corner scale derived from it, `pill` for capsule roles),
  `MinimalDensity` (the platform's own unless set) and `MinimalTypeface`; per-part `MinimalStyle`s in
  `MinimalComponentThemes`, and a `style:` on each part that takes one. A part inside another is its frame's outline
  moved in (`MinimalShapes.inset`), and a press wash or focus ring takes the part's exact outline.
- **The parts**, by the names Material gives them: buttons (`MinimalButton` with `primary`, `secondary`, `ghost` and
  `destructive` variants in `small`, `medium` and `large`, `MinimalIconButton`, `MinimalButtonGroup`,
  `MinimalSplitButton`, `MinimalToggleGroup`, `MinimalSegmentedButton`, `MinimalLink`); fields (`MinimalTextField`,
  `MinimalTextArea`, `MinimalPasswordField`, `MinimalInputOtp`, `MinimalInputGroup`, `MinimalSelect`,
  `MinimalCombobox`, `MinimalMultiSelect`, `MinimalSearchField`, `MinimalFormField`, `MinimalForm`,
  `MinimalFileUpload`); choices (`MinimalCheckbox`, `MinimalSwitch`, `MinimalRadioGroup`, `MinimalSlider`,
  `MinimalRangeSlider`, `MinimalRating`); dates and times (`MinimalCalendar`, `MinimalDatePicker`,
  `MinimalDateRangePicker`, `MinimalTimePicker`, which takes a `DateTime`'s clock); lists and data (`MinimalListTile`,
  `MinimalListSection`, `MinimalDataTable`, `MinimalTreeView`, `MinimalReorderableListView`,
  `MinimalRefreshIndicator`, `MinimalStat` and `MinimalStatRow`, line, area and donut charts); navigation
  (`MinimalAppBar`, `MinimalNavigationBar`, `MinimalNavigationRail`, `MinimalNavigationDrawer`, `MinimalTabBar`,
  `MinimalBreadcrumb`, `MinimalMenuBar`, `MinimalPagination`, `MinimalPageDots`, `MinimalStepProgress`); overlays
  (`MinimalDialog`, `MinimalBottomSheet`, the side `MinimalSheet`, `MinimalActionSheet`, `MinimalPopover`,
  `MinimalHoverCard`, `MinimalMenu`, `MinimalTooltip`, the command palette, `MinimalSnackBar` under a
  `MinimalToaster`); and feedback (`MinimalBanner`, `MinimalCircularProgressIndicator`, `MinimalSkeleton`,
  `MinimalMeter`, `MinimalBadge`, `MinimalStatusView`). Every public member is documented, with an example.
- **Behaviour from ui_core.** State, keys, focus, semantics, right to left, Reduce Motion and 44 px targets are
  ui_core's; every pixel is Minimal's. Values the behaviours share are ui_core's types (`DesignRangeValues`,
  `DesignDateRange`), so an app's own `flutter/material.dart` import never clashes with them.
- **Every size of screen.** From 960 px wide a sheet page stands as a card centred over the dimmed page, not one rising
  from the bottom edge; the example's apps put their list beside the open record.
- **States at idle size.** Pressed, disabled and wrong each read on the control at its idle size, and none moves the
  layout. A hovering pointer changes nothing unless the app sets an `overlay` for `WidgetState.hovered`.
- **Text entry built one way.** The look draws the box and the editable inside is bare, one line centred in it, so
  neither a desktop's density nor an app's own `InputDecorationTheme` moves a field's line.
- **Sign-in buttons.** `MinimalSignInButton` and `MinimalSignInStack`, with the Apple, Google and GitHub marks bundled;
  an app's own `assets/logos/<slug>_mark.png` adds a provider or replaces a mark.
- **Words.** The words every look shares (Back, Close, Search, Today, the months and weekdays) come from ui_core's
  `DesignLocalizations`, English unless an app registers a `DefaultDesignLocalizations` subclass for its language;
  `MinimalLocalizations.of(context)` reads them with Minimal's own words (English in 0.1.0). `MinimalFormat` prints
  dates, times, money and counts.
- **The host library.** `minimal_host.dart` carries what an app builder's host draws pages under (`MinimalHost`,
  `MinimalPreview`, the route pages, the chrome metrics, `minimalInventory`); the main library leaves it out.
- Geist and Geist Mono bundled (SIL OFL 1.1), loaded by `minimalLoadFonts()`; icons from Lucide (ISC). No router.

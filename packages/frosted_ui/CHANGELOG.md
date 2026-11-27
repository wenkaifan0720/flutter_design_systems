## 0.8.1

- Requires ui_core 0.8.3.
- A screen's footer stands on the bar's glass, edged on top by the lit hairline, as a phone's bar is at its foot: the
  page passes under it, blurred, and rests a margin over it, where an opaque band of the canvas cut it off under a
  fade. A docked `FrostedActionBar` stands on the same glass.
- From 600 wide a footer's acts stand at the column's end, as the action bar's one act does, where a `FrostedButtonRow`
  in a footer stood at the line's start. A row in a page's body keeps the line's start; on a phone the acts span it.
- `FrostedChromeMetrics.footerFade` is deprecated: nothing draws a fade over the page any more.

## 0.8.0

- Requires ui_core 0.8.2.
- New `FrostedAppShell`, the app's frame in the main library, on ui_core's `RawAdaptiveShell.branches`: its places in
  the glass tab bar on a phone and a tablet and in the sidebar from 1024 wide, each place keeping its own stack of pages.
  A page pushed in a place keeps the sidebar beside it while the tab bar steps away (`hideBarOnPush`); back pops it.
  Toasts keep clear of the tab bar. The sidebar has a width of its own (`sidebarWidth`).
- `FrostedNavigationBar`, `FrostedNavItem`, `FrostedNavAction`, `FrostedNavigationRail`, `FrostedNavigationDrawer`
  and `FrostedSidebarAction` move to `package:frosted_ui/frosted_host.dart`, for an app that builds a frame of its
  own: import it beside `frosted_ui.dart` (`dart fix --apply` adds the import). `FrostedHost` and `FrostedPage` are in the main library.
- Palettes: `FrostedThemeData.palettes` is the six as ui_core's `RawNamedPalette` (an `id` to store, a `label` to
  show, swatches by day and by night), for an app's palette picker. `FrostedHost(palette:)` and
  `FrostedThemeData(palette:)` take one; the host eases a change of palette. `FrostedThemeData.presets` is removed:
  read `FrostedThemeData.palettes.map((p) => p.id)`. `FrostedThemeData.preset` takes an id it doesn't know (a stored
  `'cobalt'`) as the first palette, opal, where it threw.
- New `FrostedRadio.suffix`: a part that follows the words, right beside them at any width (a palette's swatches in a
  palette picker). It is drawn, not read; the label names the choice.
- A wrong `FrostedTextField` (and the fields on it) and a wrong `FrostedDateField` show the danger's mark at the
  field's end, in the danger's ink, beside the glass's tint: the field itself reads as wrong, not only its label and
  message.
- A field turning wrong, or right again, eases where it changed in one frame: its message fades in as the room under
  the field opens, so what stands below slides rather than jumps, and the label's ink and the mark at the field's end
  ease to the danger's; a date field's calendar crosses to the mark. A radio group's and a code entry's message ease
  the same way. Under Reduce Motion each cuts. `FrostedHintSlot` and `FrostedLabelInk` (in `frosted_parts.dart`)
  draw it for a field of an app's own.
- By day a part the keyboard focuses rises a little, on a close, faint shadow (the raised shade at its own strength,
  3 px below), where it cast a broad, dark one. The frost clearing and the rim's light are unchanged.
- Removed `FrostedThemeData.cobalt`, deprecated in 0.7.0: use `FrostedThemeData.from(accent: Color(0xFF0668DE))`.
- A name only a screen reader hears is `semanticLabel`; `label` is kept for words a part draws. Renamed on
  `FrostedIconButton`, `FrostedSwitch`, `FrostedCheckbox`, `FrostedSlider`, `FrostedRating`, `FrostedChoices`,
  `FrostedToggleGroup`, `FrostedButtonGroup`, `FrostedPressable`, `FrostedTabBar`, `FrostedBreadcrumb`,
  `FrostedPagination`, `FrostedPageDots`, `FrostedScrollArea`, `FrostedCarouselView`, `FrostedFilterChipGroup`,
  `FrostedMonthSwitch`, `FrostedQuickActions`, `FrostedActionTiles`, `FrostedQuickAmounts`, `FrostedSwapButton`,
  `FrostedPopover`, `FrostedHoverCard`, `FrostedMenuBar`, `FrostedContextMenu`, `FrostedMenu` (and
  `FrostedMenu.show`), `FrostedWheelPicker`, `FrostedDataTable`, `FrostedTreeView`, `FrostedCard` (each
  constructor), `FrostedFacedCard`, `FrostedInsight` and `FrostedNavigationRail`. `dart fix --apply` makes the
  renames.
- A control inside `FrostedFormField` (a slider, a switch, a rating) is heard once, by the field's label. A row's name
  leaves out a monogram that repeats its title and keeps its status tag; a control at the row's end (its `action`)
  stays a stop of its own.
- `FrostedListTile`'s trailing part keeps to two thirds of the line, at the row's end in either direction; a long tag
  gives way with an ellipsis where it overflowed the row.
- New `FrostedScaffold.maxWidth`: the bar's title and actions, the body and the footer's acts hold to one column on
  the start edge of a wide window.
- `FrostedWordmark` sets the app's name as written (it lower-cased it), and takes the app's own `logo` in place of
  the ink mark.
- An on `FrostedSwitch` tints its glass with the palette's act inside the track's lit rim, so on and off read apart
  at a glance and the rim is the same; the knob's side still says which.
- An on toggle of `FrostedToggleGroup` stands on the chosen plate, the brightest glass on the strip, as a
  `FrostedSegmentedButton`'s choice does (it stood on a solid plate, by night as dark as the strip).
- Form fields take their column's width at every size, as a text field does; one alone in a row keeps to its content.
  New `FrostedDateField` (a nullable day, shown with its year: "Nov 9, 2026") and `FrostedTextFormField` (a
  `FormField` with `validator`, `onSaved` and reset). A wrong field's glass takes the danger's tint, its rim the
  glass's; its label takes the danger's ink and its message leads with the danger mark.
- A filled `FrostedSegmentedButton` shares its field's width equally among its segments while each label fits its
  share, as Material's segmented button does (each took its label's width and an equal share of the rest).
- The status inks (information, success, warning, danger) stand apart from each other and from the quiet ink in every
  palette, by day and by night, each with as much colour as its tone holds (ui_core_test's `DesignToneCheck`): a tag,
  a banner or an amount says which it is by its colour. By night the washes dim until the page's words read 9:1 on
  every peak, so the inks keep their colour there; a warning stands 40 degrees of hue from the danger.
- By night the quiet inks (a note, a figure's cents, a caption) read 4.5:1 on a pane tinted by any hue of the spectrum.
  By day and by night a hue's ink reads 4.5:1 on its small solid (a monogram's letters, a glyph token) as well as on
  its tint, so by day most hue inks are a step deeper.
- A switch, a slider, a rating and a navigation tab show their focus after a key and not after a press of a pointer,
  as ui_core's parts do (`RawFocusShown`).
- `FrostedWordmark` stands at the start of a slot wider than it, in either direction (a right-to-left sidebar's).
- `FrostedRowEnd`'s note gives way with an ellipsis in a narrow row.
- Tags, monograms, glyph tokens and date blocks grow with the reader's text, as large as the row's words at 130% and
  200%.
- The docs say what each part is in plain words, without the design notes they were written from.
- `example/lib/main.dart` is Shelf, one app to copy: the host, the shell with three places, a list with a pushed page, a
  form, a dialog and settings with the six palettes. The gallery is `example/lib/gallery.dart`.
- The README: the install line every snippet compiles after, the host, building an app (the shell, a list and its page,
  forms, dialogs, the palette picker), the building blocks and which row to use.

## 0.7.0

- Requires ui_core 0.7.1. Every target's floor is 40 by 40 (WCAG 2.2's minimum) under a finger and a pointer; it was 48 and 44.
- Removed `FrostedBreakpoints.touchHitTarget` and `FrostedBreakpoints.minHitTarget`; read `FrostedBreakpoints.hitTargetOf`, or the new `touchTargetOf`. `FrostedBreakpoints.targets` is `final`.
- `FrostedChoices`, `FrostedBreadcrumb` and `FrostedRecordHero`'s chips stand their spacing apart, targets reaching into the room between (ui_core's `RawChipGroup`). A breadcrumb's page stands as tall as its links' targets, so a wrapped trail's lines step evenly.
- New `FrostedThemeData.fontFamilyFallback` (constructor, `from`, `copyWith`): the fonts every text style falls back to.
- Colours are walked with ui_core's `RawPalette`; presets move by at most 31/255 on a channel, most by under 8. Opal's quiet ink by night reads on the lit wash too (#C6C3D4 to #D1CFDE).
- Six palettes: opal (the default), quartz, garnet, glacier, jade and copper. `FrostedThemeData.cobalt` is deprecated and leaves `presets`; use `FrostedThemeData.from(accent: Color(0xFF0668DE))`. The example's Foundations page shows the six.
- The time and date pickers show no English title in another language; a screen reader names the card a dialog.
- 12-hour time wheels stand together at the middle; the 24-hour clock is unchanged.
- The date picker's card holds its month's weeks with its head fixed; new `FrostedDatePicker.onDisplayedMonthChanged`.
- Today's figure takes the days' ink; its ring marks it.
- At 200% text a pill and a wrapped button keep their words 4 or more from their edges.
- A dimmed `FrostedAvatar` or `FrostedPerson` reads 4.5:1 (it was 3.7:1); a disabled `FrostedSwitchRow` says it is off to a screen reader.
- A chosen tab's words by night, and a pane's share, note and due days, read 4.5:1 (they were 3.5-4.4:1).
- `FrostedIconPicker`'s wells are each their own target, 8 apart.
- The README opens with a whole app in 12 lines, and its pictures show this release.

## 0.6.3

- Requires ui_core 0.6.1. `FrostedTimePicker`'s wheels, and `FrostedTime.format`, write a time in the app's digits through ui_core's `formatHour` and `formatMinute`: Arabic's ٩ (٢١ on the 24-hour clock) and ٠٥, not 9 and 05, also when the app gives Frosted words of its own. English is unchanged. The hour wheel stays left of the minutes in a right-to-left app. `FrostedFormat.time` says it is English and points to `formatTimeOfDay`.
- A chosen day in a grid casts no drop shadow: `FrostedCalendar`, `FrostedDatePicker` (and so `showFrostedDatePicker`) and a range's ends in `FrostedDateRangePicker` ink the day in place. By day the shadow smudged the band beside a range's ends. Buttons keep their shadow.
- By night a range's band is the accent's wash laid twice, 1.34:1 on the night canvas, where it was 1.13:1 and a range's run barely showed. By day it is unchanged.
- By night `FrostedDialog` and the cards `showFrostedDatePicker` and `showFrostedTimePicker` raise wear their rim lit from above: bright along the top, fading down the sides, gone at the foot. It was an even stroke all round, as if lit from every side.
- By night the ink `FrostedButton`'s word, and a chosen day's figure, set one weight heavier (700, from 600), where they are dark on a light pill: at the same weight they read lighter than the light word on the glass beside them. The act keeps the room it takes by day: the heavier word is centred on its day width, so a pill is as wide by night and nothing beside it moves when the theme turns.
- `FrostedThemeData.from` changes colour only: every word keeps Opal's type, the look's own (its faces, sizes, weights, lines and tracking), in the seeded theme's inks. It took the base colour set's tracking (0.1 on 13 px), so every label set wider than the default's (about 1.2 px on "Switch task") and a phone's pair of wide acts could stack under a seeded theme where the default kept them side by side.
- `showFrostedDatePicker`'s and `showFrostedTimePicker`'s cards stand on `FrostedDialog`'s inset (24) and end in its acts: Cancel and OK are the dialog's pair, the same pills and words, 10 apart (16 wide) and stacked when they don't fit side by side. They stood on a 16 inset, 8 apart, as wide acts a size larger than the dialog's. A month's inset gives way, down to 16, only where its seven columns would lose the touch target (a phone under a finger).

## 0.6.2

- `FrostedDateRangePicker`'s and `FrostedCalendar`'s months side by side each title their month over the centre of its own grid. A month with one arrow kept no room for the other, so its title leaned half an arrow (24 under a finger) toward the gutter.
- A range's band runs on at a row break, square to the row's edge, as Material's range band does, and an end day at its row's edge keeps its half there: one range reads as one across the break. The ink discs at its ends, and a preview's end, are its only round ends. The band was round at every row break (20–21 | 22–24 read as two ranges), and an end at its row's edge had no half (in Arabic, a range from a Friday).
- `FrostedDatePicker`'s arrows, and so `showFrostedDatePicker`'s, stand on the centres of the last two columns, over the days they step from, where a column holds an arrow's touch target (a desk's card under a pointer); in a narrower card they stand side by side at the end as before, each target whole. At 1440 they sat up to 3.5 off Fr and Sa.

## 0.6.1

- Today is one mark in every view: `FrostedCalendar`, `FrostedDateRangePicker` and `FrostedDatePicker` (and so `showFrostedDatePicker`) ring today in a hairline of the quiet ink, by day and by night. By day it was a white bead in the calendar and a disc darker than the dialog in the date picker. When today is the day chosen, the ring stands just inside the ink disc in the disc's words at half strength, so today still reads and stays a quiet mark.
- By day `FrostedDialog` and the card `showFrostedDatePicker` raises wear the glass's lit rim: the lit hairline round the card, the sheen under it along the top, and no dark ring inside it.
- By day a glass `FrostedButton` standing on another glass (a dialog's or a sheet's Cancel) catches the light from above, as glass does: brighter along its top under its sheen, where it was a flat step of grey. It keeps its size and stays quieter than the ink act beside it.

## 0.6.0

- Requires ui_core 0.6.0, whose parts that still began with `Design` take `Raw` names (`DesignStyleOf` is `RawStyleOf`, `DesignDialogRoute` is `RawModalDialogRoute`). Frosted's code and docs say the new names. The old names stay through ui_core 0.6 as deprecated aliases, and `dart fix --apply` moves an app's code.
- A calendar's and a date picker's head writes its year in the app's digits also when the app gives Frosted words of its own: Arabic's "نوفمبر ٢٠٢٦", not "نوفمبر 2026". `FrostedCalendar` paints its days with ui_core's `RawCalendarDayDetails.label`, in the same digits as before.
- `FrostedDatePicker`, and so `showFrostedDatePicker`, numbers its days in the app's digits (Arabic's ٢٠, not 20), as `FrostedCalendar` already did.

## 0.5.0

- Needs ui_core 0.5.1.
- Parameters take the names Flutter gives the same thing. A field's words are named as `InputDecoration` names them: `labelText`, `hintText`, `helperText` and `errorText`. Each parameter's field takes the new name too. `dart fix --apply` makes every rename below; `frosted_ui`'s `lib/fix_data.yaml` holds them.
  - `label` → `labelText`: `FrostedTextField`, `FrostedTextArea`, `FrostedPasswordField`, `FrostedInputGroup`, `FrostedInputOtp`, `FrostedFormField`, `FrostedAmountField`, `FrostedSearchField`, `FrostedSearchLink`, `FrostedNumberField`, `FrostedSelect`, `FrostedCombobox`, `FrostedMultiSelect`, `FrostedFileUpload`, `FrostedRadioGroup`, `FrostedBareField`, `FrostedCommand`
  - `hint` → `hintText`: `FrostedTextField`, `FrostedTextArea`, `FrostedPasswordField`, `FrostedInputGroup`, `FrostedAmountField`, `FrostedSearchField`, `FrostedSearchLink`, `FrostedCombobox`, `FrostedMultiSelect`, `FrostedFileUpload`, `FrostedBareField`, `FrostedCommand`, `FrostedCommand.show`, `FrostedComposer`
  - `helper` → `helperText`: `FrostedTextField`, `FrostedTextArea`, `FrostedPasswordField`, `FrostedInputGroup`, `FrostedInputOtp`, `FrostedFormField`, `FrostedAmountField`, `FrostedSelect`, `FrostedCombobox`, `FrostedMultiSelect`
  - `error` → `errorText`: `FrostedTextField`, `FrostedTextArea`, `FrostedPasswordField`, `FrostedInputGroup`, `FrostedInputOtp`, `FrostedFormField`, `FrostedSelect`, `FrostedCombobox`, `FrostedMultiSelect`, `FrostedFileUpload`, `FrostedRadioGroup`
  - `obscure` → `obscureText`: `FrostedInputOtp`
  - `prompt` → `hintText`: `FrostedSelect`
  - `displayString` → `displayStringForOption`: `FrostedCombobox`, `FrostedMultiSelect`
  - `light` → `theme`: `FrostedHost`, `FrostedPreview`
  - `dark` → `darkTheme`: `FrostedHost`, `FrostedPreview`
  - `activeIndex` → `selectedIndex`: `FrostedPreview`
  - `multiple` → `multiSelectionEnabled`: `FrostedToggleGroup`
  - `allowEmpty` → `emptySelectionAllowed`: `FrostedToggleGroup`
  - `onChanged` → `onSelectionChanged`: `FrostedToggleGroup`
  - `first` → `firstDate`: `FrostedDatePicker`
  - `last` → `lastDate`: `FrostedDatePicker`
  - `count` → `pageCount`: `FrostedPageDots`
  - `destructive` → `isDestructiveAction`: `FrostedMenuItem`, `FrostedActionSheetAction`, `FrostedPanelRow`, `FrostedDialog`, `FrostedDialog.show`
- Removes the members deprecated since 0.2.0 and 0.3.4, which nothing in the package read or drew. No `dart fix` moves them; each deprecation named its replacement.
  - `FrostedLocalizations.cut`, `copy`, `paste`, `lookUp`, `searchWeb`, `share` and `scanText`: the text menu says `MaterialLocalizations`' words.
  - `FrostedThemeData.copyWith`'s `shadows`, `glass`, `pearl` and `sheens`: a preset keeps them, and `opaqueMaterials` is the solid form for high contrast.
  - `FrostedFocusRing.layers`, `FrostedFocusLight`, `frostedFocusLight`, `frostedFocusInk`, `frostedFocusWash`, `frostedFocusGlow` and `frostedErrorEdge`: focus clears the frost (`FrostedFocusRing`), and an invalid field keeps its neutral rim.
- A field's help and error are read on the field. `FrostedTextField`, `FrostedTextArea`, `FrostedPasswordField`, `FrostedInputGroup`, `FrostedAmountField`, `FrostedSelect`, `FrostedCombobox` and `FrostedMultiSelect` lay out their label, help and error through ui_core's `RawInputDecorator`. A screen reader hears them on the field's node, and the drawn words stay out of the tree. A text field's entry is that node, also beside a key (a password's reveal). An amount field's node reads its label, its sign and the figure; a multi-select's entry is the field's node, alone or beside its tags, and that node spans the entry's lane, a touch target tall (beside its tags it stood at its line's height and said the field's name twice). The parts' `frostedFieldColumn` lays a field out, and `FrostedFieldTarget.ownNode` and `FrostedBareField.ownNode` leave the node to the field round them.
- A dialog's and a sheet's acts stand on ui_core's `RawActionBar` (the parts' `FrostedActBar`). They share the row while each fits its share, else they stack at full width with the confirming one (the last given) on top. A dialog's own `actions` of three or more used to stack with the first on top.
- A combobox's and a multi-select's entry says whether its list stands open (expanded or collapsed), and the combobox's and the select's chevrons turn while it does. The parts' `FrostedEntryOpen` carries it to the entry.
- A menu opened from the keys focuses its chosen row as the row mounts, with no post-frame focus.
- Toasts stand 12 over what ui_core's `RawToasterKeepClear` keeps clear: the tab bar, a screen's footer and a floating action bar. They follow the bar as it moves, and stand 12 over the safe inset where nothing is kept clear (16 before, on a screen with no inset). Toasts are no longer padded by a measured bar height. These go with it, and no `dart fix` moves them:
  - `FrostedToastLook.bottom`: the toaster places the toast.
  - `FrostedBottomStand.reachOf`: a stand keeps the toasts clear itself.
  - `FrostedChromeMetrics.toastBottom`: `toastOverBar` is the gap.
- Diagnostics name `displayStringForOption` and `onSelectionChanged` as the parameters are named.
- `FrostedLastInput.keys` is a `ValueListenable<int>`. An app reads the count and listens to it; only Frosted counts. Code that set or disposed it no longer compiles, and no `dart fix` changes it.

## 0.4.1

- Needs ui_core 0.4.1.
- A menu bar's or a context menu's entry with `isDestructiveAction` sets its words in the over tone, as a destructive `FrostedMenuItem` does.
- `FrostedCombobox` opens its list where ui_core's combobox opens it: under the field, or above it when the room below can't hold the list and there is more room above.
- An app's leak-tracked test that opens a Frosted menu stays leak free. Before, the menus' app-wide key count, a `ValueNotifier` that is never disposed, was reported as a leak by the first such test.
- A combobox's open list is its own glass: it frosts the card, and the words on it, under it, by day and by night. Before, a list dropping over a card showed the card through it.
- `showFrostedDialog` dims and softens the page under its dialog, as `FrostedDialog.show` does.
- `FrostedMenuItem` takes `destructive`: its words are set in the over ink, as the action sheet sets a loss.
- `FrostedErrorState` stands on the empty state's glass tile, with a band of the over hue along its top edge where the empty state has the spectrum, and its warning on an over disc.
- Pages standing side by side under a `FrostedHost` (a list beside its detail) stand on one light, with no seam where they meet.
- `FrostedListTile` takes `action`, a control after the row's end (its menu button). It stands on the chosen row's plate and stays its own target, apart from the row's press and its words.

## 0.4.0

- Needs ui_core 0.4.0 and Flutter 3.47. `frosted_ui` re-exports ui_core, whose types now take `Raw` names (`DesignPressable` is `RawButton`). The old names stay through ui_core 0.4 as deprecated typedefs, and `dart fix --apply` renames them.
- `FrostedRadioGroup` and a one-at-a-time `FrostedToggleGroup` are Flutter's `RadioGroup`, each option a `RawRadio`, with ui_core's `RadioGroupKeyboardFix` inside. They answer Tab and the arrows as before, and a toggle strip with `allowEmpty` still clears on a press of its chosen toggle. A radio shows its focus and its press as Flutter's `Radio` does, and on iOS and macOS an option also reads as selected.
- `FrostedTooltip` is Flutter's `RawTooltip`, with ui_core's `RawTooltipFocusFix` and `RawTooltipPlacement`. It fades on Flutter's tooltip timing, and each tooltip along a toolbar waits its half second.
- A `FrostedIconButton` with `selected` reads as a button, selected while on, as `IconButton(isSelected:)` does, and so does a `FrostedWeekStrip` day, selected while kept. Before, they read as switches.

## 0.3.4

- Chosen glass stays glass. A chosen chip prints a check before its word, an on switch a check beside its knob, a checkbox its check, a radio its dot and a menu's chosen option its tick, inside the glass, and the chosen glass is a little clearer. A chosen quick amount or icon well prints a dot in its corner, and a toggled icon button a dot under its glyph. Each mark stands at 3:1 or more against the unchosen part. The calendar's chosen days stay ink.
- Rims are thin and neutral. The credit card's rim is white to grey, not pink to blue. The switch and slider knobs take the glass rim, not a dark edge, also while dragged.
- Glass has no dark edge. An empty checkbox, round or square, an unchosen radio, an empty star, a menu option's empty check, an off switch's track and a segmented strip are each a small bead of glass in a field's language: the lit white rim by day, a faint inner shade, the night glass's rim by night. By day the calendar's and the date picker's today is a bead too; by night it keeps its light ring. They no longer draw a dark 3:1 ring: by day they stand about 1.2:1 off the glass, no darker than a field's edge. A knob's day shade is broad and faint, with no line round it, and the chosen segment's plate lifts on a broader, fainter shadow. By day no line of a preset built from tokens is darker than Opal's: where its palette's hairline or its menu, sheet or track edge is an opaque grey darker than Opal's line, it takes the preset's ink at Opal's strength instead. A banner's day edge is the lit hairline.
- An invalid field keeps its neutral rim; its message says what is wrong. An invalid checkbox keeps its neutral rim and prints `!` (or its check) in the error ink.
- By day, keyboard focus also lifts the part: its soft shadow deepens a little, as a pane rising off the glass. At night the rim light alone shows focus.
- A pointer over the credit card clears it a little: its pearl thins and a reflection crosses its face. Focus clears it more, on the tilted face.
- `frosted_parts` adds `frostedLift`, the day lift's shadows for a part built outside the package.
- A radio group and a one-at-a-time toggle strip answer the keyboard as a radio group (ui_core's `DesignRadioGroup`). Tab lands on the chosen option, or the first that can be chosen, and a second Tab leaves the group. The four arrows choose as they move, wrapping and passing over an option out of use; Left moves forward right to left. A strip of toggles that are each on or off keeps its arrows between them.
- A table row that can be chosen is heard as a checkbox, checked or not, not as a button (ui_core 0.3.4).
- Deprecated, to be removed in 0.4.0: `frostedErrorEdge`.
- Stands on ui_core 0.3.4 and ui_core_test 0.1.4.

## 0.3.3

- Keyboard focus clears the frost and lights the part's rim instead of drawing a coloured halo round the part. The focused part's frost wipes partway clear: more of the colour behind it comes through, with less milk under the part and less blur on its own glass. Its own thin rim brightens to white: the rim it already has, no wider, or a hairline just inside its outline where it has none (a filled button, a chosen check or radio, a row in a list or a menu). A rim that is the part's dark outline (an empty check, an off switch's track) stays, and the light comes in just inside it. The slider lights its knob, not its tracks, and the credit card clears and lights on its own tilted face. There is no accent colour and nothing outside the part. Words on a cleared part read as they do at rest over any backdrop, because the clearing never takes the glass below the ground its words are held on. A pointer over a part only clears it a little, with no rim light; a press still sinks it. A focused field no longer turns white, and a lit row in a menu or a list clears instead of showing the wash, which now shows only while it is pressed; the row the keys hold also lights its rim.
- `FrostedFocusRing` takes `hovered`, the lighter clearing under a pointer. For parts built outside the package, `frosted_parts` adds `FrostedCleared`, `FrostedClearing` (with `litOf`, for a part that draws its own rim), `FrostedClearPatch`, `FrostedClearingHeld`, `frostedRimLight` and `frostedRimIsBoundary`.
- Deprecated, drawn by nothing and to be removed in 0.4.0: `FrostedFocusRing.layers`, `FrostedFocusLight`, `frostedFocusLight`, `frostedFocusInk`, `frostedFocusWash` and `frostedFocusGlow`.
- The card glow makes its two blurs once instead of on every build, and the flow chart repaints only when its layout or source hue changes. The example builds Harbor's Settings when it is first shown.
- Stands on ui_core 0.3.3 and ui_core_test 0.1.3.

## 0.3.2

- `FrostedLocalizations.delegate` now serves every locale. It served English alone, so an app in another language that installed it was warned at startup that its locale had no Frosted delegate. With it installed, a reader of another language hears ui_core's `DesignLocalizations` words wherever a part says a word every design system shares: the month and day names of the calendar and the date picker, a picked time (`FrostedTime.format`), the error state's Try again, the done mark's Done, and the time wheel's columns. An app's own Frosted words still win, and English readers keep Frosted's own ("Monday, March 9, 2026").

## 0.3.1

- The time wheel names its hour, minute and day-period columns, and says AM and PM, in the reader's language: Frosted's own words when an app gives them, else ui_core's `DesignLocalizations` (it said Hour and Minute in English in every locale).
- Keyboard focus now lights the glass instead of ringing it: the rim goes bright, the frost brightens and a soft glow of light stands round the part. By day the glow is a clear tone of the theme's focus hue, never a dark slate line; by night a pale one. It meets 3:1 against the unfocused part on every preset, day and night, at 1x and 2x text. Rows in a list, a menu, a settings group (`FrostedValueRow`) and a form (`FrostedFormRow`) light from inside their edge, their plate reaching a little past the row into the group's inset, so the light never covers a row's words, its chevron or trailing button, its neighbours or its panel's edge. Focused fields and the search field light the same way.
- `FrostedFormField` keeps each control of a group in its own semantics node, under the field's label. Groups are a segmented button, radios, choices, a toggle or button group, filter chips, a number field, a colour or icon picker, or controls in a row, column or wrap. Previously a group was merged into one node, so with semantics on (a screen reader, or a web app with semantics enabled) every tap went to its first control. `mergeSemantics` is now `bool?`; null, the default, decides by the child. A group that names itself in the field's words, such as a segmented button labelled as its field, is announced once instead of twice.
- `FrostedNumberField` shows a plain number by default, with an optional `unit` after it (`unit: (n) => n == 1 ? 'person' : 'people'`), read with the figure. Set `money: true` for an amount with its currency sign. Each round goes out of use at its bound. `FrostedAmountField` takes a `sign` (null for none) and a `suffix`.
- `FrostedNumberField`'s minus and plus rounds are now as tall as the figure's well between them (64 at 100%, growing with the text), so the row stands at one height. They were 48 beside a 64 well. Where the row is too narrow for that (200% text on a phone), the rounds give way only as far as the well's three figures need, centred on it, never below 48, so the figure is never cut.
- Menus widen with the text size, up to the window's margins, and a long entry name wraps to a second line. At 200% on a phone, month names no longer truncate beside their amounts.
- A full-width button whose words wrap at large text keeps a line's room above and below them, so its first and last lines stay off the face's edge and its round ends.
- `FrostedButton.destructive` is glass tinted with the theme's danger hue. Its word holds 4.5:1 on the tint, day and night.
- A filled button out of use is now faint glass (the dimmed pane a glass button out of use shows) with its word over it in the quiet ink at full strength, not a dimmed ink pill whose word fell under 3:1.
- The calendar, the week strip and date marks show their days in the reader's digits (Arabic's ١٨), matching how they are read.
- Harbor Activity now searches merchants, categories, accounts, transaction status and amounts. The detail pane follows the selected filter and clears when there are no matches.
- Split a transaction into equal shares, with any leftover cents allocated exactly. Save or cancel a split and reopen it from the transaction. Get help opens assistance for the selected transaction. The monthly spending limit opens an editor and retains the saved amount.
- Tables keep file types and sizes legible at larger text sizes and inset their selection controls. At the reader's own text size a table keeps to its width (on a phone its checks give up their inset first); it scrolls sideways only once larger text would break its words. Weekday labels and dates scale together. Segmented choices stack when they outgrow a row, sign-in labels wrap, and swipe actions allow space for their full labels.
- Sliders and range sliders use a contrasting active track and thumb outline.
- The month menu keeps the chosen month in Arabic, and the gallery heading stays on one line at the phone’s 2× text setting.

## 0.3.0

Frosted 0.3.0 stands on ui_core 0.3.0: its dialog, sheets, tooltip, tab bar, wheels, number field and rating keep
their paint and take their behaviour from ui_core's parts, and it gains a context menu.

**Breaking**

- `FrostedNumberField` hands back a typed figure at each key only while it stands between `min` and `max`; one
  outside waits until it is taken (Return, or the focus leaving) and is clamped then: with a floor of 5, typing 12 no
  longer snaps to 5 at the 1. A round moves the value to the next multiple of `step` from `min`, so a round at 5 of a
  step of 10 lowers it to 0. A screen reader hears one field that steps up and down, not two buttons beside it.
- `FrostedRating` can be cleared: Home or 0 sets none, where the arrows stopped at one step.
- `FrostedTooltip` is a `StatelessWidget` and `FrostedTabBar` a `StatefulWidget`.
- In `package:frosted_ui/frosted_parts.dart`: `FrostedSoftDialogRoute` is a ui_core `DesignDialogRoute` (its page is
  `builder: WidgetBuilder`, not `pageBuilder`, and it has no `transitionDuration`); `FrostedSoftSideSheetRoute` has no
  `transitionDuration` (ui_core's side sheet moves on a spring); `FrostedSoftensBelow` is gone, the routes softening
  the page below through `frostedSoftBarrier`, their `barrierBuilder`.
- The checks Frosted's own tests ran from `ui_core` are in `ui_core_test` (a dev dependency).

**Moves**

- The dialog and the sheets open and close on a spring (ui_core's sheet spring, which settles in about a quarter of a
  second), from wherever they are when they turn; a sheet let go mid-drag carries the finger's speed. Under Reduce
  Motion the panel cuts in while the page below dims, rather than fading: glass under a fade reads clear.
- `showFrostedDialog` grows its card in over the page as `FrostedDialog.show` does, rather than fading it.

**Added**

- `FrostedContextMenu`: a menu of `DesignMenuEntry`s opened where the user asks for it, by a right click, a long
  press, Shift+F10 or the Menu key, its rows the menu bar's.
- `frostedShortcutLabel(context, activator)`: a shortcut written as Frosted's menus write it, "⇧⌘Z" on a Mac (each
  symbol its glyph) and "Ctrl+Shift+Z" elsewhere. The gallery's menus and palette write theirs with it.
- `FrostedCombobox` and `FrostedMultiSelect` say a `search` is loading, and say when it failed with a Try again row
  that Down reaches and Return runs; `debounceDuration` waits for typing to rest.
- `FrostedAmountField` takes `onEditingComplete`, `inputFormatters` and `keyboardType`; `FrostedSheet.raise` takes a
  `semanticLabel`, and `FrostedSheet.show` names its sheet by its title.
- In `package:frosted_ui/frosted_parts.dart`: `theme.dart` copied out of the package analyzes on its own. The baked
  token records (`FrostedTokens` and its parts) are a library of their own, and the theme's glass and control edge
  are drawn from its colours (`frostedMaterialsOf`, `frostedRestRingOn`), not from a theme of the package's.
  `frostedFocusInk` gives the ink focus is drawn in.

**Flutter 3.50**

- The example and the tests stand on `material_ui` and `cupertino_ui`, which Flutter 3.50 asks for in place of
  `package:flutter/material.dart` and `cupertino.dart`. The README's set-up starts an app on `material_ui`'s
  `MaterialApp`, whose page routes take Frosted's motion from `FrostedTheme` with no `ThemeData` of their own.
- `FrostedPreview`'s app stands in a semantics container of its own. The route under a nested app stands a modal
  barrier, which hides from a screen reader whatever painted before it in its container, and `material_ui`'s
  `MaterialApp` holds none of its own as Flutter's did: a heading above a preview left the page's semantics. The
  gallery's demo apps and Harbor's navigator stand in containers of their own too.
- `FrostedNavigationBar` stands on its fade into the canvas again, 104 up from the screen's foot, as the source's
  tab bar does: a card scrolling on under the glass dissolves into the canvas there, so its rim no longer runs beside
  the slab's sides on the same gutter and its rounded foot no longer frames the slab from under it. The inventory
  stands the bar on a stage of the canvas the fade's height, so the fade meets the canvas rather than drawing a box
  on the card.
- Keyboard focus shows as light, never a dark line round glass. By day a theme whose accent is its words' ink (opal)
  draws focus in its cool blue, not near black: the focus ring's line and a focused field's edge (still under its
  white glow). Themes with a coloured accent draw focus as before, and by night focus is as it was.

**From ui_core 0.3.0**

- The tooltip stays while the pointer moves onto it, one shows at a time, and along a toolbar the next shows at once.
- The tab bar is one Tab stop; the arrows move along it (mirrored right to left), Home and End to its ends, and a
  screen reader hears a tab bar, each tab with its place ("Income, tab 2 of 3").
- The wheels take Page Up and Page Down, Home and End, and a row's first letters; Left and Right move between the time
  picker's wheels; a row crossing the band ticks.
- The rating shows where a press would set it while a pointer rests over it, and takes End and the digits.
- The dialog tells a screen reader it is a dialog, `FrostedDialog.show`'s an alert; the dialog and the sheets keep
  focus inside them and give it back as they close, and a sheet, a side sheet or a page dragged and let go where it
  was holds the focus again. Escape closes a dialog or a sheet whose barrier a tap does not dismiss, however the focus
  sits (a `PopScope` still refuses it).
- A tab whose words grow where it stands (larger text, the chosen tab's words turning bold) lays the tab bar out
  again rather than cutting its words.

## 0.2.1

Frosted 0.2.1 stands on ui_core 0.2.1. Nothing is renamed or removed.

- iOS's Reduce Motion now calms Frosted. Flutter reports it in `AccessibilityFeatures.reduceMotion`, not
  `MediaQuery.disableAnimationsOf`, which was all `FrostedMotion.of` read, so on an iPhone set to Reduce Motion every
  switch, toast, menu and sheet still eased. `FrostedMotion.of` reads ui_core's `designReduceMotionOf` (Android's Remove
  animations, the web's `prefers-reduced-motion` and iOS's Reduce Motion), and the progress indicators, the skeleton
  and the loading state stop and start their loops as the setting changes.
- An insight's visit dots no longer say "1 visits": `FrostedLocalizations.visits(count)` speaks them in the app's
  plural forms, "1 visit" and "13 visits" in English by default. It has a body, so localizations written for 0.2.0
  still build.
- From ui_core 0.2.1: a menu or popover gives focus back to the control that opened it as it closes, a combobox's list
  no longer opens again on that returned focus (so Android's back pops the page), and Home and End keep the item they
  focus in view.

## 0.2.0

Frosted 0.2.0 stands on ui_core 0.2.0.

- Fields, sheets and menus no longer crash in apps set to a language other than English; their built-in labels now
  follow the app's language. The theme brings the Material and Cupertino words its parts need when the app gives none
  (in every language Flutter translates, English for the rest), and a field's text menu says Cut, Copy and Paste in
  the app's language.
- The words every look shares (Cancel, Close, Today, ...) come from ui_core in 30 languages; `DesignLocalizations` is
  exported beside `FrostedLocalizations`. A pending transaction's note is a word of `FrostedLocalizations`
  (`pending`), so it is translated with the rest.
- Every control is a finger's target: 48 px under a finger and 44 px under a pointer, through ui_core's
  `DesignTapTarget`, so what a tap reaches, what a screen reader outlines and the layout agree. A field answers a tap
  anywhere on its well; a removable tag answers in its lane; the filter chips and a phone's tab strip run on under
  the screen's gutters and take taps there.
- Shadows are whole: a strip, a sheet or a swipe row no longer cuts the shadow of a chosen plate, a lifted card or an
  action; a swipe row clips only along its swipe.
- Large text: filter chips and segmented buttons grow with the reader's text size; a shared strip ends a word too
  long for its share in an ellipsis; a form row's control moves under its words when they have no room beside it.
- Spacing on a 2-point grid: the gaps and insets that sat at 3, 5, 11 or 13 now sit at 2, 4 or 12; the segmented
  control is 28 tall in a 32 strip, as iOS's.
- The tab bar stands on the page's margin with its chosen plate set in evenly; a list group's hairline is a rule over
  the row, not a box round it; the command palette dims and softens the page behind it as every raised slab does.
- Pages move in Frosted's own way on every platform, rather than the platform's: a page pushed over another clears in
  as it settles 24 px toward the end (300 ms), the page under it standing still, and goes back the way it came. A
  `FrostedPage` takes it, and so does every page route of an app on `material_ui`, the Material Frosted is built on;
  an app on Flutter's own `MaterialApp` puts `frostedPageTransitions` in its theme's `PageTransitionsTheme` (the
  README's set-up does), and its `MaterialPageRoute`s and go_router's pages match. A full-screen dialog rises 24 px
  instead, iOS keeps its drag from the edge to go back (ui_core's `DesignSwipeBackPageTransitionsBuilder` round
  Frosted's motion, in the map's iOS entry), and Reduce Motion makes it a cut. Switching tabs or sidebar
  destinations changes the page in place.
- By night a switch that is on shows a dark knob on its light track (it read as off or disabled), and a field, a code
  box or a well in error is edged in red rather than in a pale pink that read as focus; by day the error edge is a
  clearer red too. The empty state's light no longer stands in a pale box.
- Open lists show the chosen option at a glance. In a select's or a menu's list, and in the lists a combobox, a
  multi-select or a menu bar opens, the chosen row stands on the brighter chosen glass, as a chosen chip or tab does
  (it was a checkmark on the same quiet tint a hover used). A pointer over another row, or the keyboard holding one,
  lights it with the quieter tint, never the chosen glass, so neither reads as a second choice; a menu's rows now
  light under a pointer too. A multi-select's tags, typed words and hint start where every other field's words do
  (they stood 4 px further out).
- Every menu lights one row at a time: a select's or a menu's, a menu bar's and a split button's. A pointer moving
  over a row moves the lit row there and the keys go on from it (Return takes the pointer's row in a menu); a pointer
  resting on a row the keys left lights nothing. Opened by a pointer, a menu lights no row until the pointer or a key
  moves (a menu bar's or a split button's lit its first row); the first Down then lights the first row. The keyboard's
  ring stands inside its row, the menu's inset clear all round it and its corners concentric with the menu's (it stood
  4 px outside the row, about 2 px from the menu's edge).
- A select's and a menu's open list take the keyboard: opened by a key (Enter or Space, or an arrow on a select) the
  chosen option takes the focus, or the first when none is chosen; the arrows move at once (right after a pointer
  opened it too) and go round the ends, Home and End go to them, a typed letter jumps to the next option it starts,
  Enter or Space chooses and closes, and Escape closes and gives the field the focus back. A select tells a screen
  reader whether its list is open.
- A combobox's and a multi-select's lists take ui_core 0.2.0's keys: the arrows go round the ends, and on a closed
  list they open it without moving. A combobox opened before its words are edited lists every option with the chosen
  one held (it listed only that one); edited words narrow it. `isOptionEnabled` on `FrostedCombobox` and
  `FrostedMultiSelect` dims an option the arrows then pass over and neither a press nor Return takes, nor typing in a
  multi-select. Their pointer and keys hold one row: a pointer moving over a row lights it and the arrows go on from
  there, so the list never shows two lit rows. A long list opens with its chosen row in view and keeps the row the
  keys light in view; a combobox at the foot of the screen opens its list above it when there is more room there (it
  opened below with room for a row). In a menu bar's menu a typed letter goes to the next item it starts.
- In a browser, typing goes on after Return in a combobox, a multi-select and a command palette's search: Return
  takes the option, adds the tag or runs the command, and the field keeps the focus and takes the next letters (a
  multi-select's next tag needed a click, and the letters after Return went nowhere). `FrostedTextField` takes
  `onEditingComplete` for a field of your own that keeps the focus after Return, such as an "add another" field; use
  it in place of `onSubmitted`, never with it.
- Android's back closes what is open over a page before the page: a sheet, a dialog, a menu or a select's list, and
  now a popover, a split button's or a menu bar's menu (the focus back on its control) and a combobox's or a
  multi-select's list (the focus staying in the field).
- A tablet is no longer a stretched phone. From 600 wide (`FrostedBreakpoints.medium`, where Material's medium window
  class starts; `FrostedBreakpoints.isCompact` says a phone's) a sheet stands as the centred card it is on the
  desktop, and the tab bar hugs its tabs in the middle of the foot rather than spanning the window. A menu, a popover
  or a split button's menu opened by a key gives its first row the focus as it opens (its panel built nothing on its
  first frame).
- `FrostedTheme.of` gives the default theme when no `FrostedTheme` is above (as `Theme.of` does), so text selected on
  iOS under a host placed below `home:` no longer throws; `FrostedTheme.maybeOf` still gives null.
- Every public widget describes its fields in the inspector and in a failing test's tree, its defaults hidden; the
  parts that take a value in a range (sliders, a rating, page dots, pagination, a number field, a resizable split, a
  meter, a badge, a code field) assert it in debug builds.
- `FrostedStyle` is ui_core's `DesignStyle`, shared by every look; code that builds one changes nothing.
- Deprecated: `FrostedLocalizations`' `cut`, `copy`, `paste`, `lookUp`, `searchWeb`, `share` and `scanText`, which
  the text menu no longer reads; use `MaterialLocalizations`' button labels.
- Deprecated: `FrostedThemeData.copyWith`'s `shadows`, `glass`, `pearl` and `sheens`. A free shadow could make
  Frosted's soft lift a hard one, and an opaque or dark tint turned its glass into paint. Take them from a preset
  (`FrostedThemeData.preset`), or set `opaqueMaterials: true`, the solid form for high contrast. They still work until
  they are removed; no `dart fix` moves them, since no value stands in for them one for one.
- **Breaking** in debug builds: the ink act keeps its pill. A `FrostedButton` whose own `style:` gives it a shape that
  squares its ends fails an assert naming law 6 (the ink pill); a release build draws the pill. The theme's button
  shape (`FrostedComponentThemes.button`) still shapes every glass button and now passes the ink act by, so a theme
  of square buttons squares the glass ones only. To shape a button, shape a `FrostedButton.glass`.

## 0.1.1

- Filter chips (`FrostedFilterChipGroup`) no longer slide a chosen plate across the gaps between them: each chip
  carries its own chosen glass, which fades in where the chip stands while the chip left fades back. The segmented
  control, whose segments share one capsule, still slides.
- `FrostedSlider` shows the click cursor under a mouse, over its whole track and its thumb; while it is off, the
  cursor of what is under it.
- More parts show their cursor under a mouse: the click cursor on `FrostedNavigationBar`'s tabs, `FrostedNavAction`,
  `FrostedRangeSlider`'s track and `FrostedColorPicker`'s hue and opacity tracks (their thumbs keep the resize
  cursor); the open hand on `FrostedReorderableListView`'s grip, a `FrostedSwipeActions` row and a phone sheet's
  grabber.

## 0.1.0

- First release of Frosted as a package: light through frosted glass, by the names Material gives its components
  (`FrostedButton`, `FrostedTextField`, `FrostedSelect`, `FrostedAppBar`, `FrostedNavigationBar`,
  `FrostedNavigationDrawer`, `FrostedListTile`, `FrostedCheckbox`, `FrostedSwitch`, `FrostedSlider`,
  `FrostedSegmentedButton`, `FrostedTabBar`, `FrostedDialog`, `FrostedSnackBar`, ...), with `onPressed`,
  `value`/`onChanged` and `selectedIndex` throughout, from a phone to a desktop (menu bar, command palette, data
  table, tree view, resizable panes, hover card).
- `FrostedThemeData` shaped like Material's: `colorScheme`, `textTheme` (`displayLarge` to `labelSmall`, and the look's
  figures), `shadows`, and the look's own `glass`, `pearl`, `toast` and `hues`, each with `copyWith`; the theme has
  `copyWith`, `lerp` and value equality.
- `FrostedTheme` as an `InheritedTheme` and the whole install, in any app's `builder:` (Material, Cupertino or
  Widgets), with `darkData:` for the dark appearance; `AnimatedFrostedTheme`.
- Seven presets (opal, quartz, garnet, glacier, cobalt, jade, copper), each designed in light and dark, and
  `FrostedThemeData.from(accent:)` for a palette of your own that keeps 4.5:1 for words.
- `FrostedDensity` (standard, comfortable, compact), following the platform until set (compact on macOS, Windows and
  Linux); `FrostedTypeface` for your own faces; `components` for every part's theme; `style:` on the parts, a
  `FrostedStyle` with `ButtonStyle`'s slots.
- Tokens for your own parts: `FrostedCorners` (radii and the look's outlines), `FrostedSpacing`, `FrostedStrokes`,
  `FrostedMotion`.
- `FrostedGlyphs` (the glyphs the components draw, by meaning) and `FrostedLocalizations` (every word they say).
- Frosted's own text selection handles and context menu on every field; nothing of Material shows.
- Every control's target is 48 px under a finger and 44 px under a pointer; faces keep their size.
- `frostedLoadFonts`, to set the first frame in the bundled faces.
- No router: the package takes none.
- Bricolage Grotesque and DM Sans bundled (SIL OFL 1.1); icons from Lucide (ISC).

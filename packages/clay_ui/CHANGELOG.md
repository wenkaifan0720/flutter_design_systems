## 0.6.2

- Needs ui_core 0.8.7.
- A date field writes a chosen day in the app's locale, as Material's does (ui_core 0.8.6): English writes the month first, Oct 2, 2026, where it wrote 2 Oct 2026. British English and the other English regions Material speaks keep their own order when the app lists them in `supportedLocales`. The README says so.
- A `ClaySwipeRow` in a `ClayGroup` stays on the group's slab. The slab clips its rows at its round outline, so an open row's words and actions no longer stand past its corners. An action is a plate of clay level with the row, which a press dents. It had cast a shadow that the row's box cut square: a tinted rectangle round the Delete plate, over the groove. On a slab, the plates keep concentric with its corners, as a row's plate does.
- `ClaySelect`, `ClayDatePicker` and `ClayDateRangePicker` say their label once. They said it twice ("Date started, Date started"). A date field says a chosen day once, in full, as its value; it also said the short form in its name.
- A slider says its value as a whole percentage of its range by default, as Material's does. `ClaySlider.semanticFormatterCallback` and `ClayRangeSlider.semanticFormatterCallback` say so, and the README's Forms section shows how to say a count instead. The example's reading goal says "12 books" (it said "17%").
- The README's list section puts a `ClaySwipeRow` round each tile in the group.

## 0.6.1

- Needs ui_core 0.8.5.
- **A part's own corners.** A style's `corners` (ui_core's `RawCorners`) gives a part one step of the theme's scale on every corner: `ClayStyle(corners: WidgetStatePropertyAll(RawCorners.all(RawCorner.extraLarge)))` rounds a card past its own large step, and `RawCorner.full` makes a key a pill. The step is the theme's, so it follows a rounder or a squarer scheme and its lerps. Clay opens one step on every corner (`ClayThemeData.shapeLimits.cornerFreedom` is `uniform`), because a piece of clay is one inflated volume that rounds evenly. An override whose corners differ (two diagonal cuts, one corner alone) is set aside, and a square step goes to the extra-small step, because clay holds no sharp corner. A debug build says so once. A style's `shape` still wins and is drawn as given.
- Every part with an outline of its own reads it: keys (`ClayButton`, `ClayButtonGroup`, `ClaySplitButton`), fields (`ClayTextField`, `ClaySelect`, `ClayDatePicker`, `ClayInputGroup`, `ClayNumberField`, `ClayOtpField`), `ClayFileDrop`, `ClayCard`, `ClayGroup`, `ClayDisclosure`, `ClayDisclosureGroup`, `ClayTable`, `ClayDataTable`, `ClayMedia`, `ClayBanner`, `ClayCarousel`, `ClayReorderableList`, `ClayDialog`, `ClayPopover` and `ClayCommandPalette`. A key group's and a split key's own keys keep concentric with the slab's corners. A group's rows keep concentric with the corners it is given. Corners that change with a state, such as a press, move there on Clay's press spring.

## 0.6.0

- Needs ui_core 0.8.4.
- **Breaking:** `ClayRadius` is gone. Clay's corner steps live on the theme, in `ClayThemeData.shapeScheme` (ui_core's `RawShapeScheme`), so an app can change them in one place. Read a step from the theme: `ClayRadius.small` is `ClayTheme.of(context).shapeScheme.corners.small`, `control` is `corners.medium`, `large` is `corners.large` and `extraLarge` is `corners.extraLarge`. `ClayThemeData.defaultShapeScheme` holds Clay's own steps (6, 9, 16, 24 and 32). `dart fix` can't make this move, because a step is now read from a theme rather than from a constant.
- Shapes an app can change, within Clay's laws (`ClayThemeData.shapeLimits`). Corners stay continuous. The bands are extraSmall 4–8, small 6–12, medium 12–20, large 18–30 and extraLarge 24–40. The relief's `depth` runs from 0.75 to 1.5: how soft and far the shadows fall, how deep the light and shade reach in, and how far a press sinks. Round parts stay stadiums and circles, and Clay draws no lines, so it opens no stroke. A value past its band is held to the band's end, with a note in debug builds. A table's rows and cells, a menu's rows and a picker's inner well follow their container's step. A change of shapes moves across with the rest of the theme.
- **Breaking:** `ClayAppShell`, `ClayTab` and `ClayShellAction` move to `package:clay_ui/clay_host.dart`, the host layer, and leave the main library. They frame one page that a host or a preview hands over. An app's own frame is `ClayScaffold` or `ClayScaffold.branches`. Code that uses them imports `clay_host.dart` beside `clay_ui.dart`.
- `ClayScaffold.branches` gives each place its own stack of pages. A page pushed with `Navigator.of(context).push` stands over its place. A phone's dock steps away while it stands (`hideBarOnPush`), and the rail or sidebar stays beside it. Back pops it, and choosing the place again goes back to its first page. `navigatorKeys` push onto a place from outside, and `backBehavior` says where back goes from a first page. `ClayScaffold.body` is null with branches.
- `ClayScaffold` draws a phone's dock through ui_core's adaptive shell, as it already drew the rail and the sidebar. A screen reader hears the dock as a tab bar, each place a tab with its position ("Tab 1 of 3"). The places are one tab stop: the arrows move along them, and Enter or Space chooses one. F6 moves between the dock and the page. With `showNavigation: false` the dock steps away on the shell's spring, at once under Reduce Motion (it had vanished in a single frame). The page's fade above the dock leaves with it.
- The example is Shelf, a reading list you can copy. `ClayHost` over `MaterialApp`, in the reader's appearance, palette and text size. `ClayScaffold.branches` with Books, Add and Settings. A page pushed for each book, a form that checks its answers, a dialog that asks before a book is deleted, a toast whose Undo brings the book back, and the settings with Clay's six palettes. The gallery moves to `example/lib/gallery.dart` (`flutter run -t lib/gallery.dart`).
- `ClayWell.radius` and `ClayMedia.radius` are nullable. Null takes the theme's step (was a fixed 16 and 24).
- Palettes for an app's settings: `ClayThemeData.palettes` lists the six as ui_core `RawNamedPalette`s, each with its day and night swatches, for a palette menu. `ClayThemeData.fromPalette` builds the theme for one, and `ClayHost.palette` takes the app's stored choice.
- `ClayHost` moves to a new theme over a moment (`AnimatedClayTheme`), as a Material app's theme change does: day to night, or one palette to another. Under Reduce Motion it changes at once.
- At large text, the rows of one list agree. Either every row puts its end beside its heading, or every row puts it below. On a phone at 160%, each row had decided for itself, so one list mixed the two.
- At desk widths, `ClayTopBar` and `ClayScreen`'s `footer` stand on the page's column, `ClayMetrics.pageWidth` (1080) wide, over the body they belong to. They had run the window's full width.
- A `ClayGroup`'s header, the grooves between its rows and its footer start where its rows' words start (`ClayListTile.inset`, 16), which is also where a form's labels and a field's words start, so a page has one edge down it. They had stood 4 further in. The same goes for `ClaySectionHeader`.
- `ClayFormField`'s label, error and helper start where the field's words start. `inset: false` lines them up with the field's edge instead, for a control that has no inset of its own.
- The status tones stand apart in every palette, by day and by night: danger by day is a rosier red (#F0577F, from #F2617A), apart from Clay's coral accent, and success by night is a leaf green (#B5E6A0, from #7FD8AE), apart from Mint's accent. A test holds every palette to ui_core_test's tone check.
- The example's gallery no longer imports ui_core_review, which pub.dev does not serve.
- A `ClayListTile`'s `leading` stays out of what a screen reader hears for the row: an avatar's monogram no longer says the title twice. A status tag at its end is still in the row's name.
- A `ClayGroove` is a cut whose lower lip catches the light: under the line runs a 1 px line of white, at 75 % by day (as a well's lit edge) and 8 % by night. By night a dark line alone sank into the dark ground (1.04:1), so a `ClayDescriptionList` on the page lost its rows; the lip reads there at 1.24:1. By day the lip lifts a groove on the ground beside its 1.11:1 line. On a slab of white clay it hardly shows, and the line reads as before.
- `ClayDescriptionList` sets a term and its description on one baseline. They were top-aligned, so the smaller term stood 2.5 px above the words it names.
- The sidebar's first place stands on the top bar's line, level with the page's title and its back ball: 10 below the top (it was 20, 10 lower than the bar's line).
- `ClayDatePicker` shows a medium date ("Nov 26, 2026"), and a screen reader hears it in full.
- `ClayIconButton` shows its `tooltip` on hover and on a long press, as Material's `IconButton` does, and the tooltip is the button's name. In tests, find it with `find.byTooltip`. A `ClayTooltip` above the navigator, where there is no overlay to draw in, still gives its child the name, without the bubble.
- A `ClayListTile` with a `trailing` control keeps that control as a node of its own, so a screen reader reaches it.
- `ClayTag`'s glyph grows with the text size.
- Through ui_core 0.8: a toast shown after a page pops stands above the phone's dock, as it did before the push. A desk's toast centres on the page beside the sidebar. A calendar opened low on a phone's page opens above its field, not over the dock.

## 0.5.0

- Six palettes, each by day and by night: `clay` (the default), `mint`, `sky`, `butter`, `peach` and `lavender` (`ClayThemeData.presets`, `ClayThemeData.preset`, `ClayColors.preset`). The example's Foundations shows them.
- Requires ui_core 0.7.1. Parts take ui_core's touch floor, 40 by 40 (was Clay's own 44), or an app's `RawTapTargetScope`: slider and rating slots, calendar days, tags and their remove keys, time-field figures, stacked segments, table headings and the desk menu bar. `ClaySplitView` asks ui_core which input the app is on.
- `ClayTagInput`'s tags and `ClayBreadcrumb`'s places lay out in `RawChipGroup`.
- Contrast: a calendar's days outside the month stand 3:1 in a quiet tone of their own (were 2.5:1 by day); a step still to come sits in a plain well and its figure reads 4.5:1 (was 2:1); `ClayTag`'s words and `ClayTimePicker`'s night colon read 4.5:1; a chosen `ClayListTile`'s second line, value, glyph and chevron read 4.5:1 by night (were 3.6:1); `ClaySidebar`'s chosen glyph stands 3:1 in any accent.
- `ClayThemeData.from` works out its colours with ui_core's `RawPalette` (`RawAccentRule.named`), and a dark brand accent's night chart line lifts to 3:1 in its own hue. Clay's own palette is unchanged.
- `fontFamilyFallback` on `ClayTextTheme.from` and every `ClayThemeData` factory.
- `clayContrast` is `RawPalette.contrastRatio`, with the same results.

## 0.4.2

- A press reads as a dent, as Clay's third law has it. A pressed part sinks 1.5 into the ground, its shadow fades out as it goes in, and its light and its lower trailing shade go. A shade comes up inside its top-leading edge, where the light was (mirrored right to left), and its lower trailing lip catches a little light, as a well's does. A pressed key had kept a shadow and a raised part's shading, and read as raised. This holds for every part a press sinks: keys, balls, rows, selects (an open select stays pressed in), pickers, chips and scrollbar thumbs.
- A toast stands above `ClayScreen`'s `footer`, as a `Scaffold` keeps a snackbar above its persistent footer buttons. It covered the page's Save key.
- `ClaySidebar` grows with the text size from its 264 width, as Material's extended rail grows to its labels, up to 360 (Material's navigation drawer) at twice the text. Its key, its places and its foot keep their words on one line. At the usual text size it stays 264 wide.
- Example: by night each palette swatch whose colour sinks into the dark ground (the clay and the six pastels) catches a soft light inside its top and leading edges, in its own hue, so they stand 3:1 from the ground; the light fades down the leading side, and the bottom and the trailing side stay in shade. The Overview's inflated volume is the night's risen clay, 1.8:1 from its card, where it had matched the card.

## 0.4.1

- At a large text size on a phone, parts keep their words whole and inside their shapes, following Material at the same size:
  - `ClayAvatar`'s initials and `ClayAvatarGroup`'s count keep their size at every text scale, as `CircleAvatar`'s do.
  - `ClayBadge`'s count grows with the text up to 1.3 times, as `NavigationBar` caps its labels. Its pill starts 12 inside its child's top end corner and a longer count runs on outward, as `Badge`'s does, rather than back over the child.
  - `ClayTag` and `ClayTagInput`'s tags grow taller with their words, as Material's chips do.
  - `ClayTable` keeps a numeric cell's figures on one line ("6 of 7"); a table too wide for the phone scrolls sideways.
  - `ClayListTile`: from 1.5 times the text size, on a row narrower than twelve of its words' ems (a phone's), the row's `trailing` or `trailingText` stands under its words at the row's end and the words take the row's whole width. A list's rows share their width, so they all do it or none do. On a wider row (a desk's pane) the end stays beside the words where both fit and a part too wide for that goes under them, as in 0.4.0. The chevron stays beside them.
  - `ClayProgressRing`'s child, `ClayPieChart`'s centre words and `ClayStepProgress`'s figures shrink when they must to stay inside their round.
  - `ClayCalendar` draws all of a month's days at one size, the size its widest day fits at, and its days grow to twice their size at most, as Material's day grid does.
  - `ClayTimePicker`'s columns widen with their figures, so AM and PM keep clear of the pill's ends.
  - `ClayTimeField`'s well and its pills grow taller with the figures, as a text field's well does, rather than cut them at the foot.
  - `ClayNavigationBar`'s place names keep clear of the chosen pill's round ends when they shrink to fit.
- Example: Today's ring card, the sparklines and the settings' profile set their side part above or below the words when the words would break beside it. A habit's month grows each day's ball with its number, up to 44, so two-figure days keep inside it.

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

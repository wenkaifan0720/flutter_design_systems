## 0.5.0

- Needs ui_core 0.5.1.
- **Breaking:** parameters and fields take the names Flutter's widgets give the same jobs. `dart fix --apply` moves each call and read below; the old names are gone.
- `CivicInput`: `label`, `hint`, `error` and `obscure` are `labelText`, `hintText`, `errorText` and `obscureText`, as on `TextField` and `InputDecoration` (and as `CivicTextField` already names them).
- `CivicShellFrame`: `places` and `onSelected` are `destinations` and `onDestinationSelected`, as on `NavigationBar`.
- `CivicHost` and `CivicPreview`: `light` and `dark` are `theme` and `darkTheme`, as on `MaterialApp`. `CivicPreview.activeIndex` is `selectedIndex`.
- `CivicPageDots`: `count`, `index` and `onChanged` are `pageCount`, `selectedIndex` and `onPageChanged` (`PageView`).
- `CivicStepIndicator.current` is `currentStep` (`Stepper`), `CivicIconButton.selected` is `isSelected` (`IconButton`), and `CivicBadge.max` is `maxCount` (`Badge.count`).
- On a wider screen a `CivicDialog`'s and a `CivicSheet`'s actions are laid out by ui_core's `RawActionBar`: side by side from the start, the main action first, while they all fit; else one column, every button its width, the main action on top. Before, a `Wrap` put the action that no longer fitted alone on a second line, and a stack kept each button at its words' width. On a phone they stand one under another, the whole width, as before.
- `CivicDatePicker` opens its calendar on the side of the field that holds the whole month, as ui_core's `RawPopoverFit.whole` places it. Before, a field low on a phone could open it below in the room left, the month cut off.
- `CivicCombobox`'s and `CivicMultiSelect`'s text input reads as expanded while its list shows and collapsed once it closes, as a combo box does; the combobox's chevron points up while the list is open.
- A `CivicSelect` opened from the keys puts them on its chosen answer as the list opens, without waiting a frame.
- At large text on a phone `CivicPagination`'s previous and next links and `CivicColorPicker`'s swatch names wrap their words beside their arrow or well. Before, they ran off the screen's edge.
- On a phone a toast stands above `CivicScaffold`'s navigation bar (ui_core's `RawToasterKeepClear`), as a `Scaffold` keeps a snackbar above its navigation bar. It used to cover the bar.

## 0.4.1

- Needs ui_core 0.4.1.
- `CivicTextField`'s line tap, which focuses the entry from the padding beside its words, is out of the semantics
  tree, as Flutter's text field keeps its own: a screen reader's tap reaches the entry's own. With ui_core 0.4.1 the
  entry is then the field's one node, named by its label, as a clear key (`suffixIcon`) comes and goes with the first
  letter; on the web a new node there was a new input, and the keys typed while it was made were lost.
- By night a solid `CivicButton` (and a destructive one) keeps its weight: its face is the action's (or the error's)
  own hue, deep enough to carry white words at 4.5:1, where it was the pale tone that colour takes for words on the
  night page, with dark words. A pointer over it deepens it, by day and by night.
- `CivicCombobox` ends in the select's chevron, as far in, so it reads as a box that opens a list; a press on the
  chevron opens it as a press on the box does.
- The list a `CivicSelect`, `CivicCombobox` or `CivicMultiSelect` opens stands on the field's own 2 pt ink edge,
  square, so it reads as the field's: it was a card on a grey hairline and a soft shadow. Under the keys' yellow
  plate the chosen answer is marked by its bold words and tick alone; its inset rule, drawn over the plate, read as
  a gap at the list's edge by night and a second, heavier edge by day.
- On a phone the current place's bar stands at the place's foot, under its name. At its top it stood on the band's
  rule against the page and read as an underline on whatever scrolled behind it. While the keys are on the place,
  the focus plate's ink bar says it alone.

## 0.4.0

- **Breaking:** stands on ui_core 0.4.0. Flutter 3.47 or later, as before.
- **Renamed:** the ui_core types in this package's API take ui_core 0.4.0's `Raw` names. For example, `CivicCalendar.controller` is a `RawCalendarController`, and `CivicColorPicker.controller` is a `RawColorController`. The old names still work as deprecated typedefs, and `dart fix --apply` renames them.
- `CivicRadioGroup` is built on Flutter's `RadioGroup`, with a `RawRadio` for each `CivicRadio`. `CivicSegmentedControl`'s segments and `CivicColorPicker`'s named swatches are the radios of a Flutter `RadioGroup` too. The keys work as before, Home and End on a segmented control included.
- As with Flutter's radios, a press, Enter or Space on the chosen answer, segment or swatch keeps it chosen and no longer calls `onChanged`. A `CivicRadio` with `toggleable: true` clears the choice instead. A radio shows hover and focus while focus highlights are traditional (on a desktop, or once a mouse or a key was used), so its focus also shows after a mouse click. On iOS and macOS an unchosen radio reads as not selected.
- A `CivicIconButton` that is on, and a selected `CivicChip`, read to a screen reader as a selected button, as Flutter's `IconButton(isSelected:)` does, rather than as a switch.
- `CivicTooltip` is built on Flutter's `RawTooltip`. It shows on hover after half a second, on keyboard focus and on a long press, and rises on the look's spring, as before. Run the pointer along a row of controls, and each tip waits its turn, as Flutter's do. Before, the next tip showed at once. A press hides a tip the pointer brought, as Flutter's do; before, the tip stayed while the control was held. Over no `Overlay`, as on a toast shown above the app's `Navigator`, it gives its words to a screen reader and floats no tip.

## 0.3.2

- Stands on ui_core 0.3.4.
- The yellow focus plate keeps its dark ink bar in light and dark themes.
- Switches and tabs tint their surface on hover and deepen the tint while pressed.
- `CivicRadioGroup`, `CivicSegmentedControl` and `CivicColorPicker`'s named swatches are radio groups built on Flutter's `RadioGroup` through ui_core's `DesignRadioGroup`. Each is one Tab stop, on the chosen answer or the first that can be chosen, and the arrow keys move the choice, wrap at the ends and pass over answers that cannot be chosen. A `CivicRadio`'s own `focusNode` stays its focus node.
- Right to left, an underlined part (a link, a back link, a breadcrumb, a summary row's or an error summary's link, a
  card's title, a page number, a tab, a sortable heading, the accordion's and the details' toggles, the top bar's way
  home, the skip link) draws one line under each line of its words, at the depth of its deepest word. Under Arabic
  words the line stepped up at every space, whose face is shallower than Noto Sans Arabic's.

## 0.3.1

- A calendar's month stands at most `CivicCalendar.monthWidth` wide (392: seven days of 56, near Material's calendar),
  from the start of its column, and widens only as far as the reader's larger text needs (`CivicCalendar.monthWidthOf`).
  On a wide page a month stretched to the page's width, its days 200 apart. Its words (the month's name, the weekdays,
  the days) grow at most twice with the reader's text (`CivicCalendar.textScaleMost`), as Material's calendar on a
  phone: at three times a phone's days broke mid-number.
- The date picker's, the date range picker's and the time input's typed figures grow at most twice with the reader's
  text, as Material's typed date does. The question above them keeps growing. At three times the text a date
  outgrew a phone's well.
- A field's question is read once (ui_core 0.3.2). Civic's fields no longer set `mergeSemantics: false`: where a
  control already says the question (the number field's stepper, the time input, the date picker), the field no
  longer says it again over it, and every control keeps a node of its own. A date range's ends say From and To under
  the question, not the question twice.
- The inventory's wheel of hours and minutes names its columns in the app's language: ui_core's
  `DesignLocalizations.timePickerHourLabel` and `timePickerMinuteLabel`, in its 30 languages. It said "Hour" and
  "Minute" in English in every one.
- A `CivicRadioGroup` is one stop for Tab, as Flutter's `RadioGroup` and a browser's radios are: Tab and Shift+Tab
  come to the chosen answer (the first, while none is) and leave the group, where a second Tab walked its answers one
  by one. The arrow keys move the choice, Left and Right swapped right to left, and pass over an answer that cannot
  be chosen.

## 0.3.0

Civic now has its own version of every common part, in the same look: large type, plain words, the yellow
keyboard focus, by day and by night, right to left, and at twice the text size.

- Inputs: `CivicTextArea`, `CivicNumberField`, `CivicCodeField`, `CivicSlider` and `CivicRangeSlider`,
  `CivicRating`, `CivicMultiSelect`, `CivicSegmentedControl` and `CivicToggleGroup`, `CivicChip`,
  `CivicColorPicker` and `CivicWheelPicker`.
- Dates and times: `CivicCalendar`, `CivicDatePicker`, `CivicDateRangePicker` and `CivicTimeInput`.
- Menus and overlays: `CivicMenu`, `CivicPopover`, `CivicTooltip`, `CivicSplitButton`, `showCivicBottomSheet`,
  `showCivicSideSheet`, `showCivicActionSheet` and `showCivicCommandPalette`.
- Containers and layout: `CivicCard`, `CivicAccordion`, `CivicGrid`, `CivicScrollArea`, `CivicSplitView` (one pane
  at a time below 600 wide), `CivicCarousel` with `CivicPageDots`, `CivicImage`, `CivicReorderableList`,
  `CivicSwipeActions`, `CivicTree` and `CivicActionBar`.
- People and figures: `CivicAvatar` and `CivicAvatarGroup`, `CivicBadge`, `CivicKbd`, `CivicAmount`,
  `CivicKeyFigure` and `CivicStepIndicator`.
- Progress and data: `CivicSpinner`, `CivicProgressBar`, `CivicMeter`, `CivicSkeleton`, `CivicPullToRefresh`, and
  `CivicLineChart`, `CivicAreaChart`, `CivicBarChart`, `CivicPieChart` and `CivicSparkline`. Each chart can show its
  figures as a table, and says a missing figure in words.
- The controllers and values these parts take (calendar, time, wheel, code, command, range and colour) are
  exported with them.
- `CivicButton` can show that it is working (`busy`, `busyLabel`): it keeps its focus and ignores presses until
  the work is done.
- `CivicLink`, breadcrumbs, pagination, summary-list actions and error-summary items (and the new `CivicCard`) can
  take a `url`, which opens as a web link does (in a new tab with Ctrl or ⌘ on the web). Civic now depends on
  `url_launcher`.
- A table that needs more room than there is shows each row as a block instead of scrolling sideways, and a
  column is at least as wide as its longest word.
- Toasts taller than the screen scroll, with the newest in view.
- Screen readers: a page's heading names the page; a field's placeholder is read only where there is no help or
  error; `CivicIconButton` can be a toggle (`selected`, `semanticValue`); `CivicListRow` takes a `semanticValue`;
  and `CivicNotificationBanner.announce` says whether a banner is read as it appears.
- A list group draws no divider for a row that shows nothing.
- A focused page number or sortable table heading shows one line, the ink bar under the yellow plate, where
  it kept its underline over the bar. Right to left, a sortable heading's underline keeps clear of Arabic's
  tails, as a link's does.
## 0.2.2

- Tabs keep a solid selection marker up to the ends of a scrolling strip.
  Arabic labels share the same baseline as other labels and keep clear of their underlines.
- The top bar grows with the title. On wide screens, the service name in the side navigation
  aligns with the first line of the page title.
- Bottom navigation and rail destinations use the system text size. At larger sizes, labels wrap
  and the bottom bar can use additional rows.
- Long attachment names wrap so readers can see the extension. Sortable table headings keep each word
  whole and place the sort arrow below the label when space is tight.
- Select and combobox highlights follow the inside corners of the menu.
- The embedded permit service keeps the gallery’s language and reading direction. The timeline example
  shows Arabic dates in Arabic, and the RTL Back link draws one chevron.
- Links that run an action are announced as buttons.

## 0.2.1

Fixes for what a reader sees, from a look at 0.2.0 in the gallery.

- The side navigation (from 1024 wide) is as wide as its words need at the reader's text size, from 240 to a third of
  the window: at twice the text the service's name and the places wrap by words, never inside one, and the app's act
  ("Apply for a permit") stands on one line at the reader's own size. The choice moving along the places leaves its
  width alone.
- More tabs than fit (a phone at twice the text) say so: the strip fades at an edge with tabs past it, and a chevron
  there points on, mirrored right to left.
- Right to left, a tab's words no longer settle as it is chosen: an underlined label's words stand lifted clear of
  the underline, and a chosen label's now stand there too.
- A keyboard focus reads by night: the bar under the yellow plate meets the page in the words' light ink where the
  plate's dark ink would vanish into the dark ground, 3:1 against the page either way (`CivicThemeData.focusBar`).
- The gallery's app frame names its service one way.

## 0.2.0

Needs ui_core 0.3.0. Civic stops writing what ui_core now does, and keeps its painting: it looks as it did and moves
as it did or better. No public name changed.

- The dialog is ui_core's `DesignDialogRoute` under Civic's painting. Its scrim comes up on Civic's panel spring under
  a dialog that stands whole from its first frame; the focus stays inside it and goes back to what opened it. A dialog
  that must be answered (`barrierDismissible: false`) is an alert to a screen reader, and now Android's back leaves it
  open as Escape always did: only its own buttons close it. Under Reduce Motion it is up within 150 ms, a short fade
  (it was there at once).
- `CivicTabBar` is ui_core's `DesignTabBar` under Civic's painting: one tab stop, the arrow keys moving along it
  (mirrored right to left, Home and End to the ends) and choosing the tab they reach; a screen reader hears each tab
  with its place ("Tab 1 of 3"); the chosen tab's bar comes on Civic's state spring and the strip scrolls it into view.
  Each tab keeps the room its label takes in bold, so a chosen tab's label is never cut and the tabs beside it stand
  still.
- `CivicShellFrame` is ui_core's `DesignAdaptiveShell` at Civic's widths (a bar below 600, a rail to 1024, the site's
  side navigation from there; `CivicShellFrame.modeFor`). The places are one tab stop: the arrow keys move along them
  and Enter or Space picks one; F6 moves the focus between the places and the page. A screen reader hears each place
  as a tab with its place, and the side navigation as the navigation menu. A phone's bar springs away under a pushed
  page. `CivicNavigationBar` and `CivicSideNavigation` on their own are as they were.
- `CivicCombobox` takes a `search` in place of `options`, for answers looked up as the reader types (a register): the
  list says "Loading" in words while it looks (nothing spins), and when the search fails it says so, with "Try again"
  under it, which a press or Down and Enter runs again.
- On material_ui's `MaterialApp`, the page change an app puts in its `ThemeData` (`civicPageTransitions`) now plays
  under `CivicTheme`: the Material theme Civic puts under its parts had the default page change, which a
  `MaterialPageRoute` under them read (a Mac played the Cupertino slide).
- The pub.dev page: the homepage is the live gallery, the README opens with a picture of Civic at desktop and phone
  width and the links to the gallery and the API, and the package shows six screenshots. Install with
  `flutter pub add civic_ui material_ui`: the example and the tests stand on `material_ui`, as Flutter 3.50 asks.
- `dart doc` documents the package with no warnings.

## 0.1.1

Needs ui_core 0.2.1.

- Reduce Motion on iOS calms Civic too. Flutter puts iOS's Reduce Motion in dart:ui's
  `AccessibilityFeatures.reduceMotion`, not in `MediaQuery.disableAnimationsOf`, which was all Civic read, so on an
  iPhone with Reduce Motion on, Civic's colour and opacity changes kept their usual pace and a dialog's scrim still
  faded in. Civic now reads ui_core's `designReduceMotionOf`, which also covers Android's Remove animations and the
  web's `prefers-reduced-motion`: under any of them a colour or opacity change is a short fade, settled within
  150 ms, and a dialog's scrim is up at once. Civic's moves were critically damped already and stay as they were.
- From ui_core 0.2.1: a list or menu gives the focus back to what opened it as it closes, a combobox's list no
  longer opens on focus given back to its field (only on a tap, Tab, Down or typing), and Home and End in a list keep
  the row they reach in view.
- The example service says its counts in Arabic in the form each number takes (zero, one, two, few, many and other,
  CLDR's), where it had one form for every count: "5 شوارع", "23 شارعًا", "100 شارع".
- The tests run in tiers. `flutter test --exclude-tags goldens,sweep` is the everyday run: every screen of the
  example once, the settings dealt round them (each width, each theme, right to left, twice the text), and every
  part's specimen once, by day and by night in turn. Every screen in every setting, and every specimen both ways, is
  tagged `sweep`; `flutter test` runs every tier. The doc examples' test lets an example that loads a font finish, and
  runs the frame the font change asks for, so it passes on Flutter 3.50 as on 3.47.

## 0.1.0

- First release. Civic, the plain look of public services, on ui_core: the theme by day and by night, Atkinson
  Hyperlegible Next and Mono (with Noto Sans Arabic for right-to-left pages), and the parts a service is built from:
  buttons that say what happens next, links and the back link, breadcrumbs, text fields sized for their answers, the
  password field, the date input, the file upload, radios with hints, checkboxes, the select, the combobox and the
  switch under a fieldset's question, the search field, the error summary, the answers summary and its card, list
  rows and tags, the table, the timeline, pagination, the inset rule, the warning, the details reveal, the
  confirmation panel and the banner, the empty, loading and error states, the top bar, the navigation bar, the side
  navigation and the tabs, the page with its skip link, the dialog and the toast.
- An app below 1024 wide, the service's site from it (`CivicLayout.isApp`). In an app: the top bar's way back and the
  page's place (`CivicTopBar.backButton`), lists as rows on cards (`CivicListGroup`, `CivicListRow` with its
  chevron, its `endIcon` and its `selected` mark), radios, checkboxes and the answers summary on cards by themselves,
  the page's one act kept at its foot while the page scrolls and above the keyboard (`CivicPageBody(action:)`), the
  places along a phone's foot and in a rail on a tablet, a tablet's page on a centred measure. On the site: the
  masthead, the side navigation and one measured column.
- White cards on a cool ground (`CivicThemeData.ground`), no strokes round them, corners of 4 on a control and 8 on a
  card; the strong ink edge is a field's alone, a secondary button the action's tint, and only an open list and a
  dialog cast a soft shadow.
- An app's frame: `CivicHost` round the app, `CivicShellFrame` for its places (along a phone's foot, in a rail from
  600 wide, down the start under the service's name from 1024) and its one main action, `CivicScreen` for a page,
  and `CivicPage` and `CivicSheetPage` for a router's pushed pages and raised tasks.
- `CivicPageRoute`, Civic's page change in any app, and `CivicPageTransitions`, the same for a Material theme on every
  platform, which `CivicHost` puts in place, and `civicPageTransitions`, the same as a map an app on Flutter's own
  `MaterialApp` puts in its `ThemeData`: nothing travels. The page's ground covers the page left, then the new
  page's words fade in; going back is the same the other way. On iOS a page also pops with a swipe from the screen's
  leading edge (ui_core's `DesignSwipeBackPageTransitionsBuilder` round Civic's change); Android's back pops a page
  and closes an open list or dialog first.
- A wide window keeps a service's pages in one centred frame: the top bar's words stand still from page to page,
  `CivicScaffold`'s side navigation starts its places under them (`CivicLayout.navigationOffset`), and every page ends
  where the frame ends. The side navigation is words alone; the navigation bar keeps its glyphs.
- The combobox's box keeps the focus after Enter takes an answer, and typing goes on in it, in a browser too (it
  takes Enter in `onEditingComplete`, with no `onSubmitted`); a search field and a submitting text field give the
  focus up.
- `CivicFormat` writes dates, times and counts in plain words ("3 November 2026", "5:30pm", "today").
- Make it yours: your brand's colour (held to 7:1 against the page, by day and by night) and face through
  `CivicThemeData.from`, each part's slot in the theme, or one part's `style:`. The yellow focus over its ink bar, the
  fields' 2 pt edges and the 48 and 24 tap targets stay the look's.
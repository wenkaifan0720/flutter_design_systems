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

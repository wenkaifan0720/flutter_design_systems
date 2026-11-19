## 0.3.3

- A spin button grows with the system text size, as a text field does, so its
  value is no longer cut at the bottom at 200%; its stepper buttons take the
  field's height.
- `Fluent2FormField` builds on ui_core 0.3.2's `DesignField` (this release
  needs ui_core 0.3.2). One control in a field, such as a text field, a
  switch or a slider, is still one accessibility node with the field's
  label, help and error. A spin button's entry and steppers, a range
  slider's thumbs and a group of choices keep their own nodes under the
  label. With a screen reader on, a click on a spin button's stepper now
  steps it instead of landing on the field. The label is read once. The
  new `mergeSemantics` argument, null by default, forces one node (`true`)
  or a group (`false`).
- A text field with a button at its end (a password field's reveal button,
  a search field's clear button) keeps an accessibility node as large as
  its frame inside a form field or with a validation message, rather than
  the 20-pixel line of its words, so it meets the 44 and 48 pixel touch
  target sizes.
- A form field's info label no longer reads the label a second time: the
  field says it once, and the info button says "Information about" it.
- A time picker's hour and minute and the AM and PM marks are ui_core's
  words in the app's language (Arabic's ساعة and ص, German's Stunde), where
  they were English in every language. `Fluent2Localizations.of` takes them
  from the `DesignLocalizations` in force; an app's own words still win.

## 0.3.2

- The password visibility button now responds to Tab, Space and Enter.
- The calendar shows the full month and year and scales day numbers with the
  system text size. Opening a date popover focuses the calendar. Escape closes
  it and returns focus to the field.
- Line and area chart callouts size to their series names and values.
- Data grid cells wrap long values. When the column headings need more space,
  the table scrolls horizontally.
- The disabled composer wraps its placeholder and uses a higher-contrast text color.
- In the gallery, website addresses retain their order in right-to-left layouts,
  Arabic progress captions keep quantities with their units, and confirmation
  dialogs cover the gallery controls.

## 0.3.1

- Touch menu and list rows fill their 48 px targets. Selected rows have a
  consistent 4 px inset on all sides.
- Actions in a single-line message bar have 12 px of padding on touch devices.

## 0.3.0

Requires ui_core 0.3.0 for keyboard navigation, screen reader support, focus handling, and route transitions.

Breaking:

- `showFluent2Sheet` no longer takes `transitionDuration`: ui_core's side sheet moves on a spring
  (`dampingRatio`, `stiffness`). It travels in Fluent's gentle 250 ms, as before.
- `Fluent2WindowClass` is gone: use ui_core's `DesignWindowSizeClass` (exported here), on the same Material
  breakpoints, which from 1600 wide says `extraLarge`. Compare classes by `index`.
- `Fluent2Tooltip` and `Fluent2Rating` are now `StatelessWidget`s (each builds ui_core's part); code that named their
  `State` types no longer compiles.

Changes:

- **Dialogs and sheets.** `Fluent2Dialog.show` uses a `DesignDialogRoute`: it rises from .95 and
  fades in on a spring that settles in Fluent's 250 ms; focus moves in, Tab stays inside, and the focus goes back where
  it was. `Fluent2Dialog.confirm` is an alert dialog to a screen reader (`show` takes `isAlert`). A phone's bottom
  sheet (`Fluent2Sheet.show`, the router's sheet page, `showFluent2BottomSheet`) is a `DesignBottomSheetRoute`: it
  follows a drag down, a fling puts it away, its scroll hands over to that drag, and it lifts with the keyboard; a page
  sheet rests at Fluent's 90%. On a wide window the sheet page's drawer is ui_core's side sheet. Under Reduce Motion
  these routes now fade briefly (about 150 ms) where they cut before.
- **`Fluent2Tooltip` is ui_core's `DesignTooltip`** in Fluent's bubble. It still waits 250 ms and stands above its
  control, 4 from it, and its arrow now points at the control even where the bubble is pushed along the edge. It stays
  while the pointer moves onto it, closes on Escape, shows one at a time, and opens at once along a toolbar after the
  first.
- **`Fluent2TabList` is ui_core's `DesignTabBar`** in Fluent's tabs: one tab stop, the arrows along the row (mirrored
  right to left), Home and End, tabs out of use skipped; a screen reader hears "Files, Tab 2 of 3". The indicator
  slides on a spring that settles in Fluent's 300 ms. Its hang, its fit to the reader's text size and its scrolling
  are unchanged.
- **`Fluent2Rating` is ui_core's `DesignRating`.** Home or 0 now clears it to no stars; the keys and the drag are
  ui_core's.
- **`Fluent2SpinButton` is ui_core's `DesignNumberField`.** A step lands on a multiple of `step`; Page Up and Page Down
  go to the next multiple of ten steps; the field shows its error state while its words are no number; the step buttons are no longer tab stops
  (the field's arrows step). `format` still shows the value in its own words while the field is at rest.
- **`Fluent2WheelPicker` is ui_core's `DesignWheelPicker`** on Fluent's band: Page Up and Page Down step five, typing
  jumps to a value, and a snap springs.
- **The charts pick and read their points through ui_core.** `Fluent2LineChart` and `Fluent2AreaChart` are
  `DesignChart`s, `Fluent2PieChart` a `DesignPieChart`, each drawn by Fluent's painter: one tab stop, the arrows step
  point by point (Up and Down between lines), Home and End go to the ends, Escape lets go, and a screen reader steps
  through the points. The values spring from one set to the next.
- **A search's states.** `Fluent2Combobox` and `Fluent2MultiSelect` take `search` and `debounceDuration`. While an
  app's search is on its way the list shows a spinner and "Loading"; when it fails it says "Couldn't load results"
  and offers Try again, which Down reaches.
- **`Fluent2Kbd.shortcut(activator)`** writes an app's shortcut as ui_core does: the platform's order and the reader's
  words ("Ctrl+Shift+N"), Apple's symbols on macOS and iOS.
- **From ui_core 0.3.0.** A menu opened by a click lights no row until the pointer or the keys move; Enter in a
  combobox keeps the field's focus on the web.

Fixed:

- Right to left, a line or bar chart's value card opens to the crosshair's left, toward the reading direction, where
  it opened to the right and covered the points still to read.
- A listbox option that is both chosen and the keyboard's active one draws its focus ring over the brand pill at its
  leading edge, as a menu's row does; the pill used to cut the ring.
- A tab list's indicator stands over the tabs, as Fluent's does, so a focused tab's ring no longer covers it; it
  darkens with the chosen tab under the pointer and the press, and keeps to the tab's face in a column.
- `Fluent2Preview`'s app stands in a semantics container of its own: the route under it no longer hides the heading
  an app places above the preview from a screen reader.

The package homepage links to the live gallery. The README includes screenshots and a quick start using `material_ui`.

## 0.2.1

- **Reduce Motion on iPhone and iPad.** iOS's Reduce Motion now calms Fluent 2 as Android's Remove animations and the
  web's prefers-reduced-motion do: every change of state, every push and pop is a cut, the spinner, progress bar and
  skeleton hold still, and a swiped row lands at once. Flutter carries iOS's switch outside `MediaQuery`, so
  `Fluent2Motion.on` reads it through ui_core's `designReduceMotionOf`, and the moving parts stop and start as it
  flips. Requires `ui_core: ^0.2.1`.
- **Counts in any language.** A rating's spoken score ("Rated 4 out of 5, 1 rating") and an avatar group's ("Ana, Kai
  and 3 more") now come from `Fluent2Localizations` (`ratedOutOf`, `ratingsCount`, `ratingValue`, `namesAndMore`), each
  given its count, so a language picks its own plural form. They have English bodies, so a language written for 0.2.0
  still builds.
- **From ui_core 0.2.1.** A menu or list that a button opened gives the focus back to that button as it closes; a
  combobox's list no longer opens again when the focus comes back to its field (Android's back then leaves the page);
  Home and End in an open list keep the row they reach in view.

## 0.2.0

- **Breaking: tap targets take room.** Every control stands in a target at least 48 square under a finger and 24
  under a pointer (ui_core's `DesignTapTarget`, as Material pads its tap targets), so the area a tap reaches, the box a
  screen reader outlines and the layout are one, and neighbours no longer reach into each other's taps. Under a finger
  a control smaller than 48 now lays out 48 (a check box row, a tag, a standalone link); on a desk a control takes clicks
  on its own face, where 0.1 reached 44 round it. Wrap an app's controls in a `DesignTapTargetScope` to raise either
  floor.
- **Any language.** Fields, sheets and menus no longer crash in apps set to a language other than English; their
  built-in labels now follow the app's language (a field's menu reads "Kopieren" in German), from Material's and
  Cupertino's own translations, with English for a language they lack. `Fluent2Localizations.delegate` now loads in
  any locale, in English until an app gives Fluent 2 words of its own.
- **`Fluent2Theme.of` falls back.** With no Fluent 2 theme above, it gives the default preset's light theme, as
  `Theme.of` does, and `maybeOf` gives null: a text selection's handles and menu, which build in the root overlay
  above a theme placed under `home:`, no longer throw on iOS.
- **A `style:` on the themed parts.** The slider, tab list, dialog, bottom sheet, menu, a field's list surface, toast,
  tooltip, label badge and avatar take a `style:` that wins over their component theme, as the buttons, check box,
  radio, switch, segmented control, card, list item and tag do. So does every field: the text field, text area,
  search box, select, combobox, spin button, date picker and tag picker each take a `style:` over the text field
  theme. `Fluent2Style` and `Fluent2StyleOf` are now ui_core's `DesignStyle` and `DesignStyleOf` under the same
  names, so a style written for one look reads the same in another; code that builds a `Fluent2Style(...)` is
  unchanged.
- **The menu theme reaches every menu.** `Fluent2ThemeData.menuTheme` now styles `Fluent2Menu`, which drew a fixed
  surface, and a neutral `Fluent2Popover` or `Fluent2Flyout` (its fill, ink and stroke), as it already styled the
  menus inside the split button and the menu bar. The brand and inverted popovers keep Fluent's own faces.
- **Page motion of its own.** A page the look pushes (a `Fluent2Page` in go_router, a sheet's page) now moves as
  Fluent 2 moves one: it fades in over the page it leaves, which holds still, travelling 20 px from the reading end in
  250 ms, and a pop runs it back in 200 ms; a full-screen dialog rises 20 px from below. Before, on macOS and the web a
  page slid in from a window's width away, and on Windows and Linux it zoomed. On iOS the same push plays, and a
  swipe from the screen's leading edge still pops the page, following the finger (ui_core's swipe back round it).
  Reduce Motion makes a push and a pop cuts. The routes your app pushes itself (a
  `MaterialPageRoute`) read your app widget's theme: give it `fluent2PageTransitions` as its
  `pageTransitionsTheme` (the README shows how) and they move the same way; `Fluent2PageTransition` does it for a route
  you build yourself.
- **Heard once, with their state.** A list row you can press no longer reads its title, subtitle and value twice to
  a screen reader. A check row, a selectable card and a table's select boxes now say whether they are checked at the
  same stop as their name, as a check box does, rather than at a nameless stop before it.
- **Deprecated: a free acrylic and free elevations.** `Fluent2ThemeData.copyWith(acrylic:)`, `copyWith(shadows:)` and
  `copyWith(brandShadows:)` are deprecated and go in a later release. Fluent's acrylic and its shadow ramp stay
  Fluent's: a brand-tinted acrylic spends the brand on what floats, and a flat or hard shadow loses the layers'
  depth. `dart fix` removes `shadows:` and `brandShadows:`, and the theme keeps the preset's elevations. In place of
  an acrylic recipe, `copyWith(solidAcrylic: true)` stands the acrylic's opaque fallback in for the blur everywhere,
  which is Fluent's own reduce-transparency fallback, for a device that should not pay for the blur or a reader who
  needs a steady ground.
- **`Fluent2Colors.fromMap` is an expert's escape.** Its docs now say that it sets Fluent's alias tokens raw and holds
  no contrast; `Fluent2ThemeData.from(brand:)` builds a brand's colours with contrast held.
- **Thirty languages.** Add `DesignLocalizations.delegate` to an app's `localizationsDelegates` and the words every
  look shares (Cancel, Close, Today, the calendar's months, "2 of 5") speak the app's language, among the 30 in
  `DesignLocalizations.supportedLocales`. A text field in a language the app has no Material words for still works.
- **Toolbar groups.** `Fluent2ToolbarGroup` gathers related commands under one name, and
  `Fluent2ToolbarToggleGroup` with `Fluent2ToolbarToggle` holds toggles that choose one or many, as Fluent's
  ToolbarGroup, ToolbarRadioGroup and ToolbarToggleButton do: the button group and toggle group of other kits.
- **Hover cards.** `Fluent2Popover(openOnHover: true)` opens a card when the pointer rests on its trigger and closes it
  a moment after the pointer leaves (`mouseLeaveDelay`), as Fluent's Popover does.
- **A ring with a value.** `Fluent2Spinner(value:)` draws WinUI's determinate progress ring, easing to each new value,
  and a screen reader hears it as a percentage: a meter for storage used or a goal reached.
- **Text fields take a tap anywhere on their frame**, not only on their line of words: the field takes focus and the
  caret goes where you tapped. The same holds for a combobox and for a tag picker's input beside its tags.
- **Form fields and groups.** A radio group, segmented control, toolbar toggles or tags inside `Fluent2FormField` are
  named as a group, and each choice keeps its own place for a screen reader. From 600 px wide, a field's control is
  outlined at its own width.
- **Hover and press you can see on any ground.** By day, the subtle grey under a pointer or a press (a subtle button, a
  list or tree row, a tab, a navigation item, a calendar day) darkens whatever it sits on, so it shows on the tinted
  page and on a card alike, and a press is always darker than a hover.
- **A tablet's navigation down the side.** From 640 wide (a tablet, or a narrow desktop window) the app's
  navigation is the nav pane folded to its rail of glyphs down the start edge, its hamburger opening it, as Fluent's
  iPad apps keep their tabs down the side; a select, a date field or a menu there opens its list as a popover on the
  field, its rows still a finger's height, as Fluent's iPad apps open their pickers; and a sheet raised there stands
  no wider than the desktop's dialog, centred over the window's foot. Before, a phone's tab bar, its pickers' bottom
  sheets and its sheets stretched across the tablet's width, and a landscape tablet's popover rows stood a pointer's
  32 tall under a finger.
- **The back button closes what is open first.** On Android, the system back closes an open list first (a select's
  or a date field's popover over a large window, a combobox's or a multi-select's list, the focus staying in the
  field) and keeps you on the page; the next back goes back a page. Before, the first went back a page.
- **Typing on after Enter, in a browser too.** Enter in a combobox takes its option, and Enter in a multi-select adds
  its option, while the field keeps the focus and the same text input, so the next letters go into it. Before, Enter
  restarted the field's text input, and in a browser the restarted input could miss the typing that followed.
- **The choice you made, at a glance.** In every list that opens (a select's popover and its phone sheet, a
  combobox's list, a menu with a choice), the chosen option now wears Fluent's selected-item fill in the brand, the
  brand's selection pill at its leading edge and its check in the brand, rather than a small grey check alone. The
  pointer over another option still shows only the neutral grey, and the keyboard's focus only its ring, so neither
  reads as a second choice. A select whose options have glyphs shows the chosen option's glyph before its words and
  keeps that column while its prompt shows, so its words line up with the list's. A select's list is the field's width,
  wider only for its widest option: a narrow field at a window's edge no longer opens a list that juts past it. An
  option's second word (a count) stands at its row's end rather than midway along it.
- **Lists you can drive from the keyboard.** A select's list (its popover and its phone sheet) and a menu opened from a
  control now put the focus on the chosen option, or the first, as they open, whether a key or a pointer opened them.
  Down and Up move round the list and wrap, past options out of use; Home and End go to its ends; a typed letter goes
  to the next option it starts; Enter chooses and Escape closes, the focus back on the field or the control. Before,
  the arrows moved by position and could leave the list for the field under it. A combobox's and a multi-select's
  lists go round the same way, past options out of use, and a combobox opened on its choice lists every option, its
  choice marked, until you edit the words; a choice by Enter keeps the focus in the combobox. Before, the arrows
  stopped at the ends and could land on an option out of use, and a combobox listed only its own choice. A long list
  opens with its choice in view, though it stands near the end, and the option the keys light stays wholly in view as
  they move, round the ends too; before, a select's list opened at its top and its focus could move out of sight.
- **One lit row in a menu.** A menu a control opens, a split button's menu and a field's menu light one row at a time,
  as Fluent's menus do. Opened by a click, a menu lights no row until the pointer or a key moves; before, on a desktop
  its first or checked row wore the focus ring at once. Opened by a key, the row in focus wears the ring. The pointer
  over a row lights it and takes the focus there, so the arrows go on from it; a key then rings its own row and puts
  the pointer's grey out until the pointer moves. A split button's menu keeps its rows 4 inside its stroke, as the
  other menus do; they stood 1 closer.
- **A composer that makes room.** Once a draft runs past one line beside the attach and emoji commands, the words take
  the whole width and the commands and the send move to a row beneath them, as Teams does.
- **Large text.** A tab row that scrolls grows with the reader's text size, as one that fits already did; a phone top
  bar keeps room above and below a page name that runs to two lines.
- **Desktop page column.** The page's column, up to 1120 wide, now lines up with the head's margin when the window is
  only a little wider than the column, rather than stopping just short of it.
- **Message bars.** A multi-line message keeps its glyph and dismiss on its first line, at any text size.
- **Phone top bar at large text.** With two or more glyph commands, the bar folds them into one More menu before the
  page's name runs on or shrinks.
- **Motion.** A radio's dot grows in as it is chosen and shrinks away as another is; tree and table rows ease their
  fills between rest, hover and press. Reduce Motion still cuts every one.
- **Right to left.** The navigation pane keeps clear of the screen's safe area on its start side. A teaching tip's
  step count ("2 of 3") now comes from the app's localizations, so another language orders it.
- **The inspector.** Every widget and theme class lists the settings it was built with in Flutter's inspector and in
  a failing test's widget tree; a setting left at its default stays hidden.
- **Values out of range stop early.** In a debug build, a value outside its range fails at once with a message
  instead of drawing wrong: a rating or progress past its max, a negative badge count or chart segment, page dots past
  their count, a slider with a zero step, a spinner's value outside 0 to 1, an avatar group that shows no faces.
- **Docs you can trust.** Every example in the API docs is compiled and run by the package's tests. The date range
  picker's and colour picker's examples now show the controller as the app's own, made and disposed by the app.
  `Fluent2BarGutter` is exported beside `Fluent2BarBand`, so a bar placed outside a screen can keep the screen's
  margins.
- **Type without tracking.** Fluent 2's words now draw with no letter spacing, as Fluent's type tokens specify. Under
  a Material ancestor they took Material's 0.25, so a word stood a little wider than Fluent draws it. Most lines of
  text move slightly, so golden images of an app's own screens need updating.
- **Fixes.** Calendar days on a phone no longer reach into their neighbours' taps; a swipe row shows the click cursor
  while it stands open, and cuts its sliding face only at its start and end, so a focus ring or shadow above and below
  stays whole; a section header's aside ("3 meetings") wraps as a whole; a split button's halves and an interaction
  tag's two parts are each their own target, and a screen reader names each. A toast shown without a `Fluent2Toaster` now leaves
  with its app instead of keeping its timer running. A combobox's field and a slider are each one node a screen reader
  outlines at the size a tap reaches, named, rather than a bare line or rail inside it. A calendar's days and their
  numbers sit on whole pixels at any width. Toolbar groups keep to their own width, and at a large text size their
  commands run on to a second line instead of past the screen's edge. A dialog, sheet, menu or popover leaves no
  animation behind when it closes, and a chart no longer keeps the text it measured. A scroll area whose bar always
  shows gives the bar a gutter of its own, so a tap at a row's edge reaches the row rather than the bar. A select's
  list, a date or time picker's popover and a field's popover now close when an alert, dialog or sheet is pushed over
  them, on their own navigator or the app's root one, leaving the focus to it; before, they stayed open under it and
  were still open once it was gone.
- **Example.** The gallery's right-to-left mode now reads in Arabic, with the parts' own words in Arabic too (ui_core's
  for the words every look shares), and the
  inventory marks the button group, toggle group, hover card and meter rows as present. Ten everyday screens
  (`example/lib/everyday_screens.dart`) open the gallery's sample app, top bar, dialog, sheet, states, composer and
  menu pages as an app would show them. On a desktop, the sheet and toast specimens stand at their own widths and the
  top bar specimens on the screen's margin.

## 0.1.0

First release: an independent Flutter implementation of Fluent 2, not affiliated with or endorsed by Microsoft.

- **Theme.** `Fluent2Theme` and `Fluent2ThemeData` with Fluent's alias tokens by their spec names (from
  `@fluentui/tokens` 1.0.0-alpha.24, MIT), the shared palette, the brand ramp, the type ramp, acrylic and shadows;
  `AnimatedFluent2Theme`; `Fluent2ThemeData.from(brand:)` for your own brand colour, held to 4.5:1 for words and 3:1
  for edges; a density (`standard`, `comfortable`, `compact`) and a typeface setting; a component theme per part
  (`Fluent2Style`).
- **Seven presets**, each in light and dark: `lapis` (Fluent's web blue, the default), `iris`, `juniper`, `clover`,
  `pumpkin`, `berry` and `flint`.
- **Components** on Fluent's measures: buttons (with split, toggle and compound buttons and menu buttons), links,
  text fields, text areas, password and search boxes, spin buttons, selects, comboboxes, tag groups, check boxes,
  radios, switches, sliders and range sliders, segmented buttons, ratings, file drop zones, date and time pickers, a
  calendar and a week strip, cards, list items and grouped lists, a tree, a data grid, tabs (`Fluent2TabList`),
  breadcrumbs, a toolbar, an accordion, avatars and persona rows, badges and presence, tags and interaction tags,
  message bars, toasts, tooltips, popovers, menus, dialogs, sheets and drawers, a spinner, progress and segment bars,
  skeletons, stats, charts, a carousel, resizable panes, swipe actions, pull to refresh, an activity feed and empty,
  error and success states. Parts Fluent never drew are built from its own laws (the README's "How Fluent 2 is
  built").
- **Navigation and pages**: a scaffold and top bar, a phone tab bar and a desktop navigation pane.
- **Motion**: every change of state eases the part's whole face (fills, strokes, inks, a card's shadow) over Fluent's
  durations and curves, turning mid-way without a jump; day to night eases every token; `Fluent2Eased` for your own
  parts. Reduce Motion cuts.
- **Accessibility**: Fluent's two-tone focus ring, screen-reader names and values on every control, 44 and 48 px touch
  targets, right-to-left layouts, text scaling to 2.0 and Reduce Motion.
- **Fonts and glyphs**, bundled: Selawik (SIL OFL 1.1) as the text face and a subset of Fluent UI System Icons (MIT).
- **Example**: the gallery, every component on its page in every preset, light and dark, with a sample app's screens.

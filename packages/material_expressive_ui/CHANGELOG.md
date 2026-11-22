## 0.4.1

- Needs ui_core 0.4.1.
- `ExpressiveMenuBarEntry` takes `destructive`: its label takes the `error` role, as an `ExpressiveMenuItem`'s does (ui_core's `RawMenuEntry.isDestructiveAction`).
- `ExpressiveDockedDatePicker` keeps its calendar 360dp wide under its field, as Compose's docked picker does. Before, on a wide window the calendar spanned the whole window.
- A list opened from a field (a select's, a combobox's) takes `ExposedDropdownMenu`'s shape, `MenuDefaults.shape` (extra-small corners), not a standalone menu group's large ones. Its corners no longer show the field under them.
- A select, a combobox and any field whose menu is open show their focus while it is open: the label and the 2dp indicator in `primary`, as Compose's exposed dropdown field does. `ExpressiveDockedDatePicker`'s field does the same while its calendar is open, and says it is expanded.
- A select's list as wide as a wide field marks its choice with the check at the row's end. Before, a row stopped laying out its content at 280dp, so the check stood short of the row's end.
- A read-only field that opens something (a select's, a date's) never selects its value as text: neither when it takes the focus on the web and desktop nor by a drag, as Flutter's `DropdownMenu` field that takes no typing.
- A combobox's arrow keeps the name Show suggestions open or closed; its expanded state says which. `ExpressiveLocalizations.hideSuggestions` is no longer read and is deprecated, to be removed in 0.5.0.
- `ExpressiveTooltip` merges its tip into its control's own semantics node (a button's, a link's), so a screen reader hears the control's name with its tip.
- `ExpressiveMenuItem` takes `destructive`: in a standard menu its label and icons take the `error` role.
- `ExpressiveErrorState` stands its glyph on a round `errorContainer` ground, as the empty state stands its own on a tonal one.
- `ExpressiveDialog` stands its actions in one row while they all fit, and otherwise stacks them all in one column, the confirm action on top, as Material's `AlertDialog` does. Before, three actions could wrap as two in a row with the third under them.
- `ExpressiveToggleButtonColors`, `ExpressiveCardColors` and `ExpressiveStatusColors` take `copyWith`, as Compose's colour classes take `copy`. `ExpressiveToggleButtonColors` compares by value.
- `ExpressiveDialogAction` takes `destructive`: a text action's label takes the `error` role, and a filled one fills in `error` under `onError`.

## 0.4.0

- Needs ui_core 0.4.0 and Flutter 3.47. `material_expressive_ui` re-exports ui_core, whose types now take `Raw` names (`DesignPressable` is `RawButton`). The old names stay through ui_core 0.4 as deprecated typedefs, and `dart fix --apply` renames them.
- `ExpressiveRadioGroup`, a one-choice `ExpressiveSegmentedButton` and a one-choice `ExpressiveToggleGroup` are Flutter's `RadioGroup`, each option a `RawRadio`, with ui_core's `RadioGroupKeyboardFix` inside. They answer Tab and the arrows as before, `ExpressiveToggleGroup` Home and End too, and `ExpressiveRadioGroup` still reports its checked option when it is pressed again. On iOS and macOS an option also reads as selected, as Flutter's `Radio` does.
- A one-choice `ExpressiveToggleGroup` segment shows its press from Flutter's `RawRadio`, as Flutter's `Radio` does: a held press after the tap timeout, and no tap sound or haptic.
- A toggle button reads as a button, selected while on, as `IconButton(isSelected:)` does: `ExpressiveToggleButton`, `ExpressiveIconToggleButton`, a checkable `ExpressiveSplitTrailingButton`, the `ExpressiveFabMenu` button and a text field's reveal button. A segment of a many-choice segmented button reads the same way. Before, they read as switches.
- `ExpressivePressable.focusTarget` lays a widget that takes the keyboard focus over the pressable, as the radio groups lay their `RawRadio`. The pressable keeps its tap, ripple and state layers, and shows the focus while the target holds it.

## 0.3.4

- Stands on ui_core 0.3.4.
- Radio rows and single-choice segments select with all four arrow keys. Tab enters on the checked enabled option, or on the first enabled option if the checked option is disabled. Each group occupies one Tab stop in either text direction.

## 0.3.3

- A radio group is one Tab stop, as Flutter's `RadioGroup`: Tab lands on the chosen option, or the first enabled one while none is chosen, and the next Tab leaves the group. The arrow keys choose the next or previous option, skip disabled ones and wrap at the ends. Left and Right swap in right-to-left layouts.
- `ExpressiveTextField` and `ExpressiveTextArea` take `decorate`, which wraps the editable alone inside the field's node. A form that names its inputs passes its decorator there, so a screen reader reads the input's name and hint once and the reveal and clear buttons stay controls of their own. `ExpressiveFormField` reads its child as ui_core's `DesignField` does: one control takes the label, while several (a stepper's buttons and entry) keep their own nodes.
- A disabled text field is one disabled control to a screen reader: its label, input and supporting text sit in a single disabled node.
- A date picker caps its month label at 2× text, as Material's does, and keeps it whole on up to two lines without breaking a word; at 300% it broke mid-word. A month whose name is wider than its line ends with an ellipsis. A range picker's calendar caps its weekday letters, month headings and days at 1.3×, as Material's does, so its first month is no longer cut under the weekday row.
- `ExpressiveDockedDatePicker` prints its day as the app's language writes a short date, in its digits, as Material's date field does: an Arabic app read "11/20/2026". English keeps MM/DD/YYYY, and a `format` still wins.
- A time picker names its hour and minute fields and its AM/PM pair, and says AM and PM, in the app's language: from the app's `DesignLocalizations`, which ui_core speaks in 30 languages, unless the app supplies its own `ExpressiveLocalizations`. `ExpressiveLocalizations.delegate` takes every locale, so a German or Arabic app that installs it no longer gets Flutter's warning that no delegate supports its locale.

## 0.3.2

- A select no longer rebuilds every frame after its window widens past 600 px (0.3.1). A read-only value now decides whether it wraps while it is laid out, from the width it is given, rather than in a frame after.

## 0.3.1

- Switches keep the Material 52 × 32 dp track at every density. The thumb has an even 8 dp inset when off, 4 dp when on or showing an icon, and 2 dp when pressed. It moves without overshooting its end.
- Menus light one row at a time: the selected row gives its fill to the row under the pointer or the keys, and a select's chosen option keeps a check at its end. Lit and selected rows share one shape and sit 4 dp from each other and from the menu's edges at every density.
- A multi-select's suggestions open at the field's full width, 4 dp below it, or 4 dp above it when there is no room below. A chip reached with the keys draws its focus ring round the chip, inside the field.
- Multi-select fields, menu rows and banner actions leave an even margin around their rounded corners. Snackbar actions use square state layers inside the bar's small corners.
- Keyboard users can choose a clock value, reveal swipe actions, reorder a list from its handle and read a focused control's tooltip. Screen readers announce a split menu button's expanded state and a rating's current score.
- Calendar headings, selected field values and timeline entries wrap at larger text sizes. Navigation badges stay inside the bar and status headings keep whole words together when space allows.
- Navigation bars, rails and drawers cap their labels and badges at 1.3× text, as Material's navigation bar does. A date picker's header caps at 1.6× (1.4× while a date is typed) and its weekday letters at 2×, so at 300% text no label, count, date or letter is cut.
- An editable rating is as wide as its stars, not the column it stands in.
- Charts place points, tick labels and inspected values in reading order. Target bands and disabled menu commands have greater contrast. Meters preserve the order of the current value and its limit in right-to-left layouts.
- The Trip planner confirms before discarding edits and offers a clear action when a search has no matches.

## 0.3.0

Requires ui_core 0.3.0 or later in the 0.3 series.

- **Breaking** `ExpressiveWindowSizeClass` is gone: use ui_core's `DesignWindowSizeClass`, the same five classes at the
  same breakpoints (600, 840, 1200, 1600). `ExpressiveWindowSizeClass.ofWidth(w)` is
  `DesignWindowSizeClass.fromWidth(w)`, `.of(context)` is unchanged, and `minWidth` has no counterpart (compare
  classes by `index`).
  `ExpressiveTable.stackBelow` takes a `DesignWindowSizeClass`; the shell scaffold chooses its bar and rail by them.
- `showExpressiveDialog` raises ui_core's `DesignDialogRoute`, on the same spring: focus moves into the dialog and
  stays there (Tab from its last control comes round to its first), goes back to what held it when the dialog closes,
  and Escape closes it even where a tap on the scrim does not. A screen reader hears a dialog, named by its title.
- `ExpressiveMultiSelect` searches: `search` finds the suggestions for what is typed (a server's, say), once typing
  rests for `debounceDuration`. While a search runs the panel shows a menu row with a spinner, and a failed one shows a
  Try again row the arrows reach and Enter runs. Its words are ui_core's (`loadingLabel`, `searchFailedMessage`,
  `retryButtonLabel`).
- The menu bar's menus light their rows through ui_core 0.3.0's own highlight: a menu the pointer opened lights no
  row until a key or the pointer moves (Down lights the first, Up the last), as before, now without the look's own
  bookkeeping.
- A number field's step plays ui_core's `selectionChanged` haptic, which an app swaps or silences in a
  `DesignHapticsScope`.
- The example's menus write their shortcuts with ui_core's `designShortcutLabel`: ⌘ on macOS and iOS, Ctrl elsewhere,
  in the reader's words.
- A full-screen dialog swiped down on iOS and let go open, and a page or full-screen dialog whose Android predictive back
  is cancelled, keep the keyboard focus they had: Flutter's route lets go of it while the gesture runs and nothing gave
  it back, so Escape and the keys went to the page under it. ui_core 0.3.0 gives it back on its own routes; the look's
  own routes now do the same.
- A menu bar entry's `shortcut` reads in the order its keys are pressed in a right-to-left layout too ("⌘ N", not
  "N ⌘"). A menu row's `trailingText` is free text and keeps the row's direction, as Material's does.
- `ExpressiveInventoryGallery` names a ui_core behaviour under a part only when the part paints it ("ExpressiveDialog
  · on DesignDialogRoute"). It named one for every behaviour row, so thirteen parts that keep Expressive's own (the
  split button, combobox, range slider, date range picker, command palette and others) read as built on ui_core's.

## 0.2.1

- Reduce Motion includes iOS's: Expressive stands on ui_core 0.2.1, whose `designReduceMotionOf` reads iOS's Reduce
  Motion as well as Android's Remove animations and the web's `prefers-reduced-motion`. On an iPhone with Reduce
  Motion on, springs used to run as designed; now spatial springs are critically damped, effects become a short fade,
  the loading and progress indicators and the skeleton's pulse hold still, and the splash fades instead of handing
  off. The indicators and the pulse follow it both ways while shown. Needs `ui_core: ^0.2.1`.
- Counted words take their plural form: a time picker says "1 hour" and "1 minute" (not "1 hours", "1 minutes"), a
  code field "Code, 1 character", a one-step indicator "The step is done". `ExpressiveLocalizations` hands each of
  these the count, so a translation words every count its own way (Arabic's one, two, few and many among them).
- The package's tests come in tiers: `flutter test --exclude-tags goldens,sweep` meets every kind of check once
  (each preset, mode, setting, width, direction and text scale, each part's behaviours) and leaves the rest of
  each matrix to `sweep`; `flutter test` runs them all. No test process passes 4 GB (the gallery walks peaked at
  10 GB), and `media_test.dart` no longer fails in `tearDownAll` when it runs sharded.

## 0.2.0

- Fields, sheets and menus no longer crash in apps set to a language other than English; their built-in labels now
  follow the app's language.
- Pressing and holding in a field no longer crashes when `ExpressiveTheme` sits under the app's `home` rather than in
  its `builder`: the theme a dialog, menu or magnifier carries over adds nothing to their layout, and a field's
  Copy and Paste menu brings its own words, in the app's language, wherever the theme sits.
- **Breaking** `ExpressiveComponentThemeData.merge` keeps its own slots and fills the rest from the other style, as
  `ButtonStyle.merge` and ui_core's `DesignStyle.merge` do; the other style used to win. Where the other should win,
  write `other.merge(style)`, or `ExpressiveComponentThemeData.layered([other, style])` for the old fall-through state
  by state. `layered` is new, as ui_core's `DesignStyle.layered`.
- `ExpressiveThemeData.from(seed:)` takes Material's `contrastLevel`: 0 (standard, the default, as
  `ColorScheme.fromSeed`) or 1 (high). It was pinned to 1, so a seed's scheme is now standard contrast unless asked:
  pass `contrastLevel: 1` for the earlier colours. Any other level fails an assert in a debug build and takes the
  nearer of the two in a release build: words stay at 4.5:1 on every surface, under a state layer too, which a reduced
  level breaks, and so does Material's medium level, whose light containers take a dragged row's words to 3.7:1.
- Every preset comes at standard and high contrast: `ExpressiveThemeData.preset(id, brightness, contrastLevel: 1)`.
  `baseline`, Compose's fixed scheme, takes its high level from its seed. Medium is left out for the reason above, and
  the README no longer promises three levels.
- `ExpressiveHost` follows the platform's high-contrast setting (`MediaQuery.highContrastOf`) as `MaterialApp` does:
  it wears `highContrastLight` and `highContrastDark` when given, else the default preset at high contrast when it was
  handed no theme. A part outside any theme does the same.
- Pages no longer fly in across the whole window on macOS, Windows, Linux or the web: an `ExpressivePage` pushes with
  the look's fade-forwards (a 96 dp travel and a fade, the page beneath moving 96 dp the other way) on every platform
  but iOS, which keeps the Cupertino slide and its edge swipe. `ExpressiveHost`'s theme names a page transition for
  every platform, so an app's own `MaterialPageRoute` or go_router `MaterialPage` pushes the same way instead of falling
  back to Flutter's default (a full-width slide on macOS, a zoom on Windows and Linux); on Android they keep Flutter's
  fade-forwards and predictive back. An app on Flutter's own `MaterialApp` names the same map,
  `expressivePageTransitions` (new, in the main library), in its `ThemeData`, since Flutter's `MaterialPageRoute` reads
  only that theme: `ThemeData(pageTransitionsTheme: const PageTransitionsTheme(builders: expressivePageTransitions))`,
  as the README's setup does.
- A combobox's suggestions, a non-modal `ExpressiveMenu` and a split button's menu close when a route is pushed over
  their page (an alert, a dialog, a sheet), on its navigator or another, and leave the focus to it; before, they
  stayed open under it and were still open once it was gone. `ExpressiveBackHandle(closeWhenCovered: true)` does the
  same for an overlay of the app's own.
- A select's or combobox's menu (`matchAnchorWidth`) is as wide as its field and wider only as far as its widest
  option needs, up to the 280 dp a menu item may be, from its first frame; in a narrow field, long options used to
  wrap onto two lines.
- A combobox holding an option's label (one chosen, or set by the app) offers every option when it opens again, that
  one marked by the row's fill as a select marks its choice; it used to filter down to the one option, unmarked.
- The keys in an open select, combobox or menu: a list opened from a key (Enter, Space, Down or Up) starts on its
  chosen option, else its first; Down and Up move at once and wrap, Home and End go to the ends, and a typed letter
  goes to the next option it starts; Enter chooses and closes, Escape closes and gives the focus back to the field.
  The arrows work right after a pointer opened the list too, counting from the chosen option. A long list opens with
  its chosen option in view (in its middle, as far as it scrolls), and the keys keep their option in view.
  `ExpressiveMenuController.focusChosenItem` is new.
- One lit row in every menu (an overflow or context menu, a split button's, a grouped or vibrant one, a select's list,
  an `ExpressiveMenuBar` menu): the pointer moving over a row lights it on the hover layer, and in a menu that holds the
  focus the keys go on from that row; the keys light their row with the focus indicator alone (3dp `secondary`, inside
  the row, no fill under it). Either puts the other's light out, so a menu no longer shows the keys' ring on one row and
  the pointer's fill on another. A menu the pointer opened lights no row until the pointer or a key moves (a menu bar's
  menu used to ring its first row, and a menu opened under a resting pointer lit that row); one a key opened lights its
  first, or its chosen. A menu on a page lights the row under the pointer without taking the focus.
  `ExpressivePressable.focusRing` is new.
- An `ExpressiveSplitButton`'s menu takes the keys as every menu does: opened from a key, its first row takes the
  focus; Down and Up move and wrap, from the row the pointer lit when no row holds the focus yet; Home and End go to
  the ends; Escape, or a row that closes it, gives the focus back to the chevron (Down used to scroll the page, and
  the focus was lost when the menu closed).
- An `ExpressiveFabMenu` lights one item, as every menu does: the pointer moving over an item lights it and, with the
  keys among the items, takes their focus there, so they go on from it; the keys' item alone shows the focus
  indicator (the pointer's item and the keys' used to be lit at once). Escape closes it on any route, as Back does
  (only a route that took Escape as a dismissal closed it). Closing it with the focus on an item gives the toggle the
  focus back, so Enter opens it again (the focus used to be lost).
- `showExpressiveMenu` closed with nothing chosen (Escape, a tap outside, Back) gives the focus back to what opened it,
  even a button the pointer pressed, so Enter opens it again (the rail's add menu lost the focus).
- Enter in an `ExpressiveMultiSelect` adds a value and the field keeps the focus for the next; Enter in an
  `ExpressiveCombobox` tells `onSubmitted` and the field keeps the focus. Both take Enter as `onEditingComplete`, never
  `onSubmitted`: Flutter restarts the text input of a field that has `onSubmitted` and keeps the focus, and in a
  browser the restarted input takes no typing. Before, Enter took the focus away from both (a click for each tag).
- An open menu's rows tell a screen reader their boxes as drawn: the popup's scale-in moved only their pixels, so
  the boxes a screen reader (and the web's semantics) read stayed those of the animation's first frame, smaller and
  off their rows.
- Enter opens an `ExpressiveMenu` from its anchor in a browser, as Space does (the web maps Enter to a button's press
  alone, and the anchor took only the general one).
- A menu's rows stand 4dp clear of its container on every side, at every density: at the compact density of a desktop
  the 2dp above and below them fell to nothing, so the first row's ring met the container's top and its corner cut it,
  and the last row's fill ran into the bottom. A one-group menu scrolls its rows inside that inset, its container and
  corners standing still (it used to scroll the container away).
- `ExpressiveMultiSelect` offers a disabled option dimmed, as a select does, and its keys pass over it; neither a tap
  nor Enter takes it (it used to be left out of the suggestions). Its suggestions' keys go round past the ends, and on a
  closed list Down only opens it; the pointer moves its highlight (`highlightFollowsPointer`), so a list never shows two
  rows lit; an `ExpressiveMenuBar` menu goes to the item a typed letter starts (ui_core 0.2.0's `DesignTagInput` and
  `DesignMenuBar`).
  Typing filters again. Its options are the select's chosen-or-not items, so its list reads as a select's does.
- A context menu opened by a long press (`ExpressiveMenuTrigger.longPress`) no longer tells a screen reader it is a
  collapsed control that a tap expands (a tap opens nothing); it says a long press shows its menu.
- A brand's typeface reaches every part: `type.copyWith(textFamily: 'Inter')` no longer looks for Inter inside this
  package and silently falls back. `ExpressiveTextTheme.fontPackage` now names the package of an app's own faces and
  is null by default (the app's assets); the faces this package bundles, Roboto Flex and Jost, always come from it.
  `copyWith` takes `fontPackage`. Flutter's own widgets under `ExpressiveHost` (a Material list tile, a tooltip) wear
  the theme's text face, where they wore a fixed Roboto Flex.
- **Breaking** A standalone `ExpressiveLink` keeps the 48 dp touch target every control does, so it now lays out 48 dp
  tall. A link inside a sentence (`ExpressiveLink.span`) takes none, as WCAG 2.5.8 exempts a target in running text.
- Touch targets are ui_core's `DesignTapTarget`: the area a tap reaches, the control's layout and the box a screen
  reader outlines are one. `ExpressiveTheme` declares the look's floors (`DesignTapTargetScope`): 48 dp for a finger
  and for a pointer, as Compose keeps `minimumInteractiveComponentSize` on every platform.
- `ExpressivePressable.tapTargetAlignment` and `ExpressiveMinimumInteractiveSize.alignment` stand a control on the
  edge a keyline holds, its target growing away from it. The number field's stepper uses it: its circles stay on the
  row's edges.
- A screen reader outlines only what a tap reaches: a search bar's box ends at its trailing actions, an input chip's
  ends at its remove target (a node of its own, so a multi-select tag is no longer one chip-wide Remove button), and
  a text field is its own node over its container, so a field in a list row no longer takes in the row's words.
  `ExpressiveOutsideOutline` keeps a part out of the pressable round it.
- The whole slot of a bare field (input group, multi-select, search field) takes a tap, not just its line of text.
- A menu item's focus ring stands inside the item, so the menu's clip no longer cuts it.
- Checkbox, radio and switch rows with supporting text are two-line list items (72 dp, 10 dp above and below), so
  larger text grows them with room round them.
- No word breaks in the middle at 200% text: tables stack their rows when a column's words do not fit, and the
  gallery's labels wrap between words.
- The gallery's right-to-left mode shows the trip planner in Arabic, the components' own words (dates, the date
  picker, Clear, Search) included.
- No dp or colour literal is left in the components: each size is a token or a named constant.
- A split button's halves are a 48 dp target each, one screen reader node each; a tap above or below a half, inside
  the 48 dp band, presses that half.
- A row whose highlight bleeds to the screen's edges (a selection row in a padded page) is outlined by a screen reader
  at the row, where a tap reaches, not at the highlight.
- `focusNode` and `autofocus` on the time picker's mode toggle, `ExpressiveDisclosure`, `ExpressiveFileUpload` and
  `ExpressiveScrollField`, as on every other interactive part.
- Under Reduce Motion, effects (colour, opacity) settle in a short fade with no overshoot; movement keeps its own
  stiffness without the bounce.
- A select's or combobox's field is its own screen reader node, as a text field is, saying whether its menu is open;
  its supporting text is read as its own line.
- A chip in a multi-select reads as its words, with Remove as an action on it, not as a disabled button; its remove
  target is a button of its own.
- Tab walks a navigation rail or bar as one group: on a wide window the keyboard no longer alternates between the
  rail and the page row by row.
- At large text a tab whose label shrinks to keep its word whole stands as tall as the label prints, not as tall as
  the unshrunk label.
- The gallery's overview, everyday dialog, tabs, card grid and feedback states read Arabic right to left, as the
  trip planner does.
- In the gallery, Tab reaches every control on a page and brings it into view: from the rail or the app bar into a
  page scrolled past its top (Flutter's Tab scrolls only forward, which left the focus above the window), and on
  into the sections a reference page builds only as they scroll into view (Tab went to the rail instead).
- On the web, Tab goes on from an `ExpressivePreview` to the page around it. Its page stood on its app's own
  navigator, which hands focus out of the browser window at its last control, so the page's controls after the
  preview could not be reached by keyboard.
- An `ExpressivePreview` reads in the language of the page it stands in, as it already read in its direction: its
  parts' own words (an error state's Try again, a dialog's Cancel) were its own app's English.
- A tab with an icon and a label printed smaller to keep its word whole stands tall enough for both.
- The words ui_core shares come in its 30 languages when an app loads `DesignLocalizations.delegate`; a menu bar's
  name and a menu's barrier label are among them (the menu bar now reads "Menu bar").

- Built on ui_core 0.2.0.
- Every public widget and style class describes itself in Flutter's inspector and in a failing test's widget tree:
  each field it was built with, the ones at their defaults left out.
- A value a part cannot take fails an assert where it is made, in a debug build: a slider's value outside its `min`
  and `max`, a range slider whose `start` passes its `end`, a negative `selectedIndex` on a navigation bar, tab bar or
  shell scaffold, an `ExpressiveResizable` fraction outside 0 to 1, a chart domain upside down or stepping by
  nothing, a multi-select whose `maxValues` allows none.
- A chart no longer keeps its labels' text layouts after each paint, a bottom sheet's route disposes the controller
  it made, and a snack bar still showing when its app goes away takes its overlay entry with it.
- The examples in the API docs are compiled and run by the package's tests.

## 0.1.1

- A mouse over a slider (`ExpressiveSlider`, `ExpressiveRangeSlider`, `ExpressiveVerticalSlider`) now shows the
  click cursor over the whole slider, its track as well as its handle, as Material's slider does. A disabled slider
  keeps the cursor of what it sits on.
- A text field shows the text cursor over the whole field, its container and label as well as the line you type in.
  A read-only field that opens something when clicked (a select, a date field) shows the click cursor.
- The time picker's dial and its scrolling hour and minute fields show the click cursor, as a slider does.
- A carousel's page dots and a select's suggestions arrow show the click cursor on the web, as the package's buttons
  do. In a desktop app they show the platform's arrow, as Flutter's own buttons do.
- The chips in a multi-select show the field's text cursor, since a click there goes to the field; their remove glyph
  keeps the click cursor.

## 0.1.0

First release: an independent Flutter implementation of Material 3 Expressive, ported from Jetpack Compose
`material3` 1.5.0-alpha29 and held to Compose's own renders. Not affiliated with or endorsed by Google.

- Material's names and Flutter's words. Components are named as Material names them (`ExpressiveButton`,
  `ExpressiveTextField`, `ExpressiveNavigationBar`, `ExpressiveSnackBar`, `ExpressiveLinearProgressIndicator`, ...)
  and take the parameters a Flutter developer expects: `onPressed`, `value`/`onChanged`, `selectedIndex`/
  `onDestinationSelected` over `destinations`, a button's `child`, a list tile's `onTap` and `tileColor`, `hintText`,
  `helperText`, `obscureText`, `title`/`subtitle`, `currentDate`. A part without its handler is disabled, as in
  Flutter, with no separate `enabled` flag; every interactive part takes `focusNode` and `autofocus`. Every public
  member has a dartdoc.
- `ExpressiveTheme` is the whole install, in the `builder:` of a `MaterialApp`, `CupertinoApp` or `WidgetsApp`, an
  `InheritedTheme`. `ExpressiveThemeData` has `of`, `copyWith`, `lerp`, diagnostics and a factory per preset;
  `AnimatedExpressiveTheme` springs from one theme to the next as Compose animates colour.
- Five presets baked from their seeds by material-color-utilities (baseline, slate, bloom, grove, ember), each light
  and dark at standard, medium and high contrast, and `ExpressiveThemeData.from(seed:)` for an app's own colour.
  Success and warning tones (`theme.status`), harmonised to each preset's seed, on `ExpressiveBanner` and
  `ExpressiveTag`.
- Component themes with Flutter's slots: `ExpressiveComponentThemeData` holds `backgroundColor`, `foregroundColor`,
  `outline`, `overlayColor`, `side`, `shape`, `padding`, `minimumSize`, `textStyle` and `iconSize`, each a
  `WidgetStateProperty`. A `shape` takes any `OutlinedBorder`, the shape library's `ExpressiveMaterialShapeBorder`
  among them, and morphs when it changes. The shape scale, `ExpressiveDensity` (Flutter's steps, adaptive by
  default), the motion scheme and the type families.
- The look in its own material: the thirty-five library shapes for avatars, pictures, indicators and image
  placeholders (an unloaded picture is two seeded library shapes on its tone, not a grey box); charts with
  round-capped 4 dp lines, shape points and a band on the extra-large corner; skeletons on the large corner in
  `secondaryContainer`; the loading indicator's seven shapes; wavy progress; the button group that widens the
  pressed button.
- `ui_core`'s shared inventory: 83 of its 89 rows live, each under the shared name (`Expressive<Stem>`), and
  `expressiveInventory` answers every row. The other six say what Material uses instead: a keyboard key, a command
  palette, a tree view, an action sheet, a hover card and a wheel picker are not Material components (a number
  wheel is `ExpressiveScrollField`, a word wheel the select, an action sheet's rows a bottom sheet's list).
- On `ui_core`'s behaviours, painted in Material's states: `ExpressiveToggleGroup`, `ExpressivePasswordField`,
  `ExpressiveInputGroup`, `ExpressiveFormField`, `ExpressiveMultiSelect`, `ExpressiveMenuBar`,
  `ExpressiveCalendar`, `ExpressiveColorPicker`, `ExpressiveDataTable`, `ExpressiveSheet` (the side sheet),
  `ExpressiveScrollArea` and `ExpressiveResizable`. The data table's state (`DesignTableController`,
  `DesignTableColumn`, ...) comes with the package's one import.
- Drawn whole from Expressive's parts where Material has none: `ExpressiveTimeline`, `ExpressiveDescriptionList`,
  `ExpressiveStatusView`, `ExpressiveLineChart`, `ExpressiveAreaChart`, `ExpressiveBarChart`, `ExpressivePieChart`,
  `ExpressiveSparkline` and `ExpressiveNavigationDrawer`.
- Accessibility: every control has a semantics role and name and takes focus and the keyboard; Material's focus
  ring, concentric with the part's corners (inside parts that sit flush); state layers in the part's own shape;
  every target at least 48 dp (Compose's `minimumInteractiveComponentSize`) with the face at its own size. A
  checkbox, radio or switch without a handler is disabled at full size, as in Flutter's own controls.
- Right to left, large text and other scripts: every part mirrors under a right-to-left `Directionality` (start and
  end, `EdgeInsetsGeometry`), lays out at 200% text, and draws Arabic, Hebrew, Chinese, Japanese, Devanagari and Thai
  in the platform's fallback fonts. Built-in words are English; dates and numbers are English-only in this release.
- Three libraries: `material_expressive_ui.dart` for an app's screens; `material_expressive_host.dart` for its frame
  (`ExpressivePage`, `ExpressiveSheetPage`, `ExpressiveFullScreenDialogPage`, `ExpressiveShellScaffold`, the
  preview frame and the inventory), on any `Navigator` with no router package; `material_expressive_parts.dart`,
  everything the components are drawn with, for a component you copy into your app. The parts library's generated
  token and behaviour classes keep Compose's names (`ButtonSmallTokens`, `AlertDialogBehavior`, ...); everything
  hand-written carries the `Expressive` prefix.
- The words a component says by itself, English built in: the shared ones from `ui_core`'s `DesignLocalizations`
  (translated once for every look by extending `DefaultDesignLocalizations`), the look's own in
  `ExpressiveLocalizations` (its delegate, or `ExpressiveLocalizationsScope` for a subtree); `firstDayOfWeek` starts
  the date pickers' and the calendar's weeks.
- `ExpressiveCombobox` says when nothing matches (`emptyBuilder` for your own words); `ExpressiveMenuNote` is that
  line, for any menu.
- An example app built on the package: an overview, a trip planner (home, a plan form, a shared list, a packing
  checkout and settings) and every exported widget live, its destinations in the navigation rail or the modal
  drawer. Customize re-themes every page.
- Roboto Flex and Jost (SIL OFL 1.1) and a Material Symbols Rounded subset (Apache-2.0) bundled.

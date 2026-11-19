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

## 0.3.2

- Focus shows as a browser's `:focus-visible` shows it. A dialog, sheet, menu or popover opened with a mouse, a touch or a screen reader still focuses its safe action or first control, so Enter, Tab and Escape work as before, but paints no focus until the next key press. Opened from the keyboard, it paints the focus at once. A mouse press anywhere hides a shown focus until the next key. Buttons, value handles, wheel pickers, colour areas, calendars, carousels, scroll areas, tooltips and hover cards follow it; text fields still show their focus on a click. An app that sets `FocusHighlightStrategy.alwaysTraditional` shows focus whatever the input, as before.
- A mouse over a value handle (a slider's or a colour slider's thumb, a knob) shows the grab cursor, and the grabbing cursor while it is dragged; a range slider's and a colour slider's track show the click cursor, and the grabbing cursor over the whole slider while a thumb moves; a wheel picker grabs and is grabbing while the mouse turns it; a split view's divider shows the resize cursor along its axis. A disabled one shows the basic arrow. A cursor a look passes still wins.
- Moving a calendar's keyboard focus to another day scrolls that day into view inside a scroll view, such as a date picker's popup.
- `DesignField` no longer makes one node of a group of controls. With `mergeSemantics` left null, the new default, a child that holds one control (a text field, a select, a switch, a slider) is still one node with the field's label, help and error. A child that holds several (a stepper's buttons and its field, segmented buttons, chips, radios) keeps each control's own node under the label, so a screen reader's tap, or a click on the web with semantics on, reaches the control under it. The label is not added again when the child already says it, as a stepper named as its field or a group that names itself does; a required field then says it is required at the start of its hint. `true` and `false` keep 0.3.1's behaviour.

## 0.3.1

- Escape dismisses a chart's hovered or touch-selected point while keyboard focus stays in place. A dialog or menu above the chart handles Escape first.
- Combobox and tag suggestions open on the side of the field with more space. Enter selects the highlighted suggestion on a hardware keyboard, including when the field already contains tags.
- Split-button menus keep their trailing alignment. Use `placement` to align the menu with the leading edge or choose a different side.
- Moving the pointer away from a menu bar clears its highlight immediately. The open menu still accepts keyboard input. Switching menus highlights the new title as soon as it opens.
- Buttons announce matching visible and supplied labels or values once. Additional text, such as a row subtitle, remains available to screen readers.
- Plain reorder handles accept keyboard focus. Press Alt+Up or Alt+Down to move the item and keep its focus.
- Number fields expose their configured minimum and maximum in Flutter semantics.
- Wheel pickers support mouse dragging. Ratings expose the pressed state on the item under the pointer.
- On compact screens, dialog actions share the row equally and stack when their labels need more space. Use `DesignDialog.actionWidgets` to supply custom actions.
- Use `DesignSheetPageRoute` for a full-screen sheet with native back navigation and reduced-motion support.
- Opening a bottom sheet from a focused control puts keyboard focus on its first action, or on the control with autofocus.
- Pass `divisions` to `DesignLinearScale.nice` for an exact number of chart intervals with a rounded domain.

## 0.3.0

Forty behaviours, up from 24. Overlays open at a point and keep clear of the on-screen keyboard, menus light one row,
and there are a context menu, a tooltip, shortcut labels and a search that may take time and fail. Routes add a dialog,
a bottom sheet, tabs, an adaptive shell and a list beside its detail, each moving on a spring, with F6 between panes.
Values add a wheel picker, date and time fields typed in segments, a number field, a rating and headless charts, with
numbers, dates and times in the reader's language, and haptics in one table. Every new word is in all 30 languages.
The checks a look's tests run moved to a package of their own, `ui_core_test`, so an app carries none of them.
It compiles on Flutter 3.50, where `RawDialogRoute` gained a `barrierBuilder` that the command palette's route
clashed with.

### Breaking

- `package:ui_core/alignment.dart` is removed: its 24 names (the alignment matrix and sheet, the text entry check,
  the screen checks and their results) moved, unchanged, to `ui_core_test`. Add `ui_core_test: ^0.1.0` to
  `dev_dependencies` and import `package:ui_core_test/ui_core_test.dart` in its place (see Tooling).
- `DesignSideSheetRoute.transitionDuration` is removed: the sheet moves on a spring. Give `dampingRatio` and
  `stiffness` (ζ 1, k 700 by default) in its place.
- `DesignLocalizations` has 59 new members, the new behaviours' words and the number, date and time formatters
  (`formatDecimal`, `parseDecimal`, `formatTimeOfDay` and the rest). A subclass of `DefaultDesignLocalizations` gets
  them, in English until it translates them; a class that implements `DesignLocalizations` itself must add them.

### Overlays
<!-- 0.3.0 overlays -->
- A surface opens at a point: `controller.open(position:)` on a `DesignAnchoredOverlay` (an offset in its anchor)
  places it below the point from its start in reading order, above it or towards its other end where there is no
  room, never under the point; `DesignOverlayInfo.position` says where. A list opened at a point does not take its
  anchor's width.
- Every anchored surface (menus, lists, popovers) keeps clear of the on-screen keyboard: one below a field the
  keyboard covers flips above it, and one open as the keyboard comes up moves. It reads the keyboard and the safe area
  from the overlay's own view, so a scaffold that took them out of its page no longer hides them. A look's own chrome
  over its pages (a desktop side bar) is kept clear of with `DesignOverlayPadding` round the pages.
- `DesignOverlayInfo.surfaceRect`: where the surface landed after any flip or shift, set as it is laid out, so a
  painter given it as its `repaint` points a tail or an arrow at the anchor from the first frame and follows it.
- A menu (`arrowKeyNavigation`) that a pointer opened starts with the focus on the surface itself and no item lit, as
  a clicked menu does on every desktop: Down then goes to the first item, Up to the last, Tab to the first and
  Shift+Tab to the last. Opened from the keys or by a screen reader, it starts on its first item as before. On the
  web with semantics on, a click arrives as a screen reader's tap: a mouse resting on the anchor makes it the
  pointer's. A look's test that tapped a menu open and expected its first item focused should press Down first.
- In a menubar's menus and a split button's menu the highlight follows the pointer (`highlightFollowsPointer`, new,
  true by default, as on every desktop): a pointer over an item moves the keys there, and one item is lit, the current
  one, hovered when the pointer moved last and focused when the keys did; no other item is hovered or focused, a
  disabled item under the pointer lights none, and the pointer leaving the menu lights none. A submenu a pointer opened
  lights none of its items, its own item staying selected. False keeps 0.2's states, each item's own. A look that
  drew the hover and the focus apart (Ledger's split menu) can drop its own bookkeeping, and one that left an item
  unlit until the first key after a pointer open (Comic's quiet menu) must: the menu surface now takes that first key
  itself, so a wrapper waiting for it never hears it and the next key is spent waking it.
- `DesignMenuSurfaceBuilder` names the menu panel builder's type (`DesignMenuBar.surfaceBuilder`'s, unchanged).
- `DesignContextMenu`, new: a menu of `DesignMenuEntry`s over a region, opened at the pointer by a right click or a
  long press of a finger (with `DesignHaptics.longPress`), at the focused widget by Shift+F10 or the Menu key, and by
  a screen reader's "Show menu" (a custom action, and the long press's hint). Its rows are the menubar's. On the web
  the browser's own menu stays shut while a pointer is over the region or pressed in it, focus is in it, or its menu
  is open, and is left alone when the app shut it itself. A region inside another opens alone. Focus goes back where
  it was, not to the region's first control.
- `DesignTooltip`, new: a message beside a control, shown after a pointer rests on it (`hoverDelay`), at once when it
  takes the keyboard's focus, and after a long press of a finger (with `DesignHaptics.longPress`; `triggerMode` takes
  Flutter's `TooltipTriggerMode`). As WCAG 1.4.13 asks: the pointer may move onto the tip, Escape hides it without
  moving the focus and goes no further, and it stays until the pointer or the focus leaves. One at a time, app-wide;
  the next shows at once within `DesignTooltip.warmUpDuration` (300 ms). A screen reader hears the message as the
  control's tooltip, in one node; the tip itself stays out of the tree. Its placement (above, centred, flipping below)
  and `surfaceRect` are the anchored overlay's; it fades on an effects spring. `DesignTooltip.dismissAll()` hides it.
- `designShortcutLabel` and `designShortcutKeys`, new: a `SingleActivator`'s or a `CharacterActivator`'s keys as
  Flutter's own menu rows (`MenuItemButton`) show them, for a look's `DesignMenuEntry.shortcut`: ⌃ ⌥ ⇧ ⌘ in Apple's
  order on macOS and iOS ("⇧ ⌘ N"), Alt, Ctrl, Win or Meta and Shift elsewhere ("Ctrl+Shift+N"), arrows and Enter as
  symbols, the other named keys in the reader's words. `appleSymbols: false` spells Apple's keys out
  ("Shift+Command+N") for a look whose font draws no ⌘. Fifteen key names are Material's own translations
  (`keyboardKeyControl`, `keyboardKeyMetaMacOs` and the rest, under Material's names); `keyboardKeyOption`,
  `keyboardKeyEnter` and `keyboardKeyTab` are ui_core's own, translated, awaiting a native speaker's check.
- A combobox's, a tag input's and a command palette's field takes Enter in its input's `onEditingComplete`
  (`onEditingComplete: field.submit`), never `onSubmitted`, as the docs and their examples now say: the field keeps
  the focus for the next words. With `onSubmitted`, Flutter restarts the text input's connection after Enter, and on
  the web the restarted input never takes the browser's focus, so letters stop reaching a field that still looks
  focused. A look that wired `onSubmitted` should move to `onEditingComplete`; nothing else changes.
- A combobox's and a tag input's `search` may take time and fail: `debounceDuration`, `loadingBuilder` and
  `errorBuilder`, new on both, null by default (0.2's behaviour). `debounceDuration` runs the search once typing
  rests, not at every letter. `loadingBuilder` paints the list's surface while a search is pending; a screen reader
  hears `loadingLabel` as it appears. `errorBuilder` paints a failed search with a way to try again
  (`DesignSearchError.retry`, lit while `focused`: Down moves the keys there and Enter runs it, the focus staying in
  the field); a screen reader hears `searchFailedMessage` ("Couldn't load results", new, ui_core's own, translated,
  awaiting a native speaker's check) as it appears. Only the latest words' result shows: a search that ends after a
  later one started is dropped, as is one pending when the list closes. A search that fails with no `errorBuilder`
  closes the list and goes to `FlutterError.reportError`, where 0.2 left an unhandled error.
<!-- 0.3.0 overlays end -->

### Routes
<!-- 0.3.0 routes -->
- A dialog route, `DesignDialogRoute`: it opens and closes on a spring (ζ 1, k 1400 by default; under Reduce Motion it
  fades), keeps Tab inside it and gives focus back to what opened it as it closes. Escape, Android's back, a barrier
  tap and its `close` go through `Navigator.maybePop`, so a `PopScope` may refuse them. An alert (`isAlert`) is heard as
  an alert dialog and its barrier does not close it; Escape does. `DesignDialog` lays out a title and words that scroll
  over actions that stay put, side by side at the end while they fit and stacked, the confirm on top, when they do
  not; focus opens on the safe action (`DesignDialog.safeActionIndex`). New words: `dialogLabel`, `alertDialogLabel`,
  `bottomSheetLabel`, `drawerLabel` and `tabLabel`, Flutter's own in every locale.
- A bottom sheet route, `DesignBottomSheetRoute`: it rises on a spring (ζ 1, k 700) and rests at one of its
  `snapSizes` (shares of the room above the on-screen keyboard), laid out at its size, or at its content's own
  height. A drag moves it with the finger; let go, it settles on the nearest size, or the next one a fling points to,
  and below half its smallest size, or flung down from it, it closes through `Navigator.maybePop` (a `PopScope` that
  refuses springs it back). The scroll view given `details.scrollController` hands drags over: up, the sheet grows to
  its largest size first; down with the content at its top, it shrinks. `DesignBottomSheetController` moves it from
  outside; `DesignBottomSheetDragHandle` is the handle's behaviour (a press to the next size, Up and Down, a screen
  reader's increase and decrease). It plays `thresholdCrossed` as a drag passes the point where letting go closes it
  and `selectionChanged` as a drag settles it on another size. New word: `dragHandleLabel`, in every locale.
- The side sheet (`DesignSideSheetRoute`) moves on the routes' spring: `dampingRatio` and `stiffness` (ζ 1, k 700 by
  default); a drag let go settles at its speed. `transitionDuration` is removed (see Breaking).
- Escape closes a dialog, a bottom sheet or a side sheet whose barrier does not dismiss however the focus sits. With
  nothing in it focused (the focus on the route's own scope, from the push until something in it takes the focus) it
  stopped at the barrier, as Flutter's own Escape does; a side sheet's stopped there wherever the focus was. A
  `PopScope` still refuses it. The command palette's barrier always dismisses, so its Escape already reached it.
- The dialog, bottom sheet and side sheet routes take a close token, `closeDampingRatio` and `closeStiffness`, so a
  look can close on a spring of its own (a quicker fall than the rise, or a slower one). Each defaults to the open
  token's, so a route that gives neither closes as before. Under Reduce Motion a close still fades, and a sheet
  dragged away carries the drag's speed into the close spring.
- Swipe rows (`DesignSwipeActions`) in one scroll view open one at a time: opening one closes the others, and the
  scroll view scrolling closes it (`closeOnScroll`, on by default). A `DesignSwipeActionsController` opens either side
  or closes it from outside and says whether it is open. The slide and the edge action's widening move on a spring
  (`dampingRatio`, `stiffness`; ζ 1, k 700), a let-go carrying its speed, and a full swipe plays `thresholdCrossed` as
  it arms.
- iOS's swipe back (`DesignSwipeBackPageTransitionsBuilder`) follows the finger from where it went down on a page that
  paints nothing at its leading edge. Before, the route's barrier held the gesture there until the drag passed its
  slop, and the page trailed the finger by it (18 px).
- A drag that leaves a sheet open, or a swipe back that leaves the page, gives the focus back to where it was inside
  it, and a swipe back that pops the page gives the page under it its focus, as a back button does. Flutter takes the
  focus out of every route while a drag or swipe runs and does not bring it back, so Escape and the keys went to the
  page under the sheet.
- Tabs: `DesignTabController`, `DesignTabBar` and `DesignTabView`, Material's three on the widgets layer. The bar is one
  tab stop; the arrows move along it (mirrored right to left, Up and Down when vertical), wrapping, Home and End, disabled
  tabs skipped, and choose as they move unless `selectionFollowsFocus` is false. Swiping the pages moves the selection
  (`controller.animation`), so the look's indicator (`indicatorBuilder`) and each tab's `selection` follow the finger;
  pages, indicator and a scrolling bar (`isScrollable`) settle on the controller's spring. A screen reader hears a tab
  bar of tabs, "Inbox, Tab 1 of 3", each controlling its page, a tab panel.
- A tab is laid out along the bar at the extent it was measured at (its share, or its own in a scrolling bar), never
  held at a size: a tab whose words grow where it stands (twice the text size, a tab renamed, the chosen tab's words
  turning bold as a tap or an arrow key chooses it) lays the bar out again rather than cutting its words or
  overflowing. Across the bar every tab's face stands as tall as the tallest face (as wide as the widest,
  in a column). A tab whose touch target (`DesignTapTarget`) stands larger than its face keeps the target as its hit
  area and the face at its own size in it, on both axes: a 32 high face in a 48 target was stretched to 48.
- The indicator is laid out in the selected tab's face (`DesignTabIndicatorDetails.rect`: what a touch target larger
  than the face holds, else the whole tab), the whole tab in `tabRect`, and is handed the selected tab's states
  (`states`: hovered, pressed, focused), so it can take the tab's hover and press inks. `indicatorPosition` paints it
  under the tabs (`DecorationPosition.background`, the default: a pill or a fill behind the words must not cover
  them) or over them (`foreground`: a line a tab's own fill would hide).
- An adaptive shell, `DesignAdaptiveShell`: the destinations in a bar along the bottom, a rail or a sidebar at the start
  by the shell's width (`DesignNavigationMode.fromWidth` on Material's window size classes, `DesignWindowSizeClass`), the
  body beside or above. The destinations are one tab stop with the tabs' arrow keys; Enter or Space chooses. A bar is a
  tab bar to a screen reader, a sidebar the "Navigation menu". A tab bar holds tabs and nothing else (Flutter fails one
  that holds anything else), so a look whose bar holds more than its destinations (a compose button beside them)
  places `DesignNavigationDetails.group` round the destinations alone, which is then the tab bar.
  `showNavigation: false` springs the bar away.
  `DesignAdaptiveShell.branches` gives each destination its own navigator, built when first shown and kept; choosing
  the selected one again pops it to its root, and back pops the selected branch, then goes where `backBehavior` says.
- A list and its detail, `DesignListDetail`: side by side from 840 wide (resizable with a `dividerBuilder`), else the
  list alone and the chosen item's detail pushed in the look's route, its pop clearing the choice. Crossing the width
  keeps the reader where they were.
- F6 and Shift+F6 move focus between panes: a shell's navigation and body, a list-detail's list and detail, and a
  shown `DesignToaster`'s toasts, landing where each pane last had focus. With no other pane about, a toaster's F6
  still goes to its newest toast.
<!-- 0.3.0 routes end -->

### Values
<!-- 0.3.0 values -->
- Haptics in one table, `DesignHaptics`: a step (`selectionChanged`), a long press (`longPress`) and a drag past its
  threshold (`thresholdCrossed`), each the platform's own feedback by default, swapped or silenced below a
  `DesignHapticsScope`. A slider's or a range slider's thumb plays a step as a drag crosses each division.
- A wheel picker, `DesignWheelPicker`: columns of rows that turn past a centre line, linked (the columns are a function
  of the selection, so a pick refills the others, February's days included), with rows that can't be chosen
  (`DesignWheelColumn.minIndex`, `maxIndex`, `isItemEnabled`) passed on to the nearest live one, looping columns, the
  keys (Up and Down, Page Up and Down, Home and End, typing a row's name, Left and Right between columns) and an
  adjustable node per column for a screen reader. Keys and a parent's new selection turn the wheels on a spring.
- Numbers, dates and times in the reader's language, on `DesignLocalizations`: `formatDecimal` and `parseDecimal`
  (German's `1.234,5`, India's `12,34,567`, Arabic's `١٬٢٣٤٫٥`; a grouping separator out of place does not read),
  `formatPercent`, `formatYear`, `formatShortMonth`, `formatShortMonthDay`, `formatTimeOfDay` (`DesignTimeOfDay`, a
  time with no date) and the fields' patterns, `dateFieldPattern` and `timeFieldPattern` (CLDR's yMd, jm, Hm). The
  symbols and patterns are CLDR's through package:intl's data, read when the translations are generated: no
  dependency on intl. With them 24 words: five of Material's, the segment names from CLDR, the empty segments'
  letters, and the rating's and the charts' (counts in each language's plural forms), the last 11 awaiting a native
  speaker's check.
- Date and time fields, `DesignDateField` and `DesignTimeField`: a date or a time typed segment by segment in the
  reader's order (`M/d/y`, `d.M.y`, `y/M/d`; `h:mm a`, `HH:mm`, Korean's `a h:mm`), each segment a tab stop and an
  adjustable node a screen reader steps and hears by name ("Month, November"). Digits, the reader's or ASCII, fill a
  segment and move on once no further digit fits; Up and Down step and wrap, Home and End go to the ends, Backspace
  clears and then moves back, Left and Right move as drawn, a typed separator moves on; a phone's keyboard types through
  one text input, a number pad but for AM/PM. A day past the month's end moves back to its last day; outside
  `firstDate` and `lastDate` the field reads as invalid and says so once. Right to left, a run of digits reads left to
  right, as a number does (Hebrew's `16.11.2026`, Arabic's `٣:٠٥`). With them `DesignLocalizations.formatMonth`, a
  month's standalone name, which a month segment's value speaks.
- A number field, `DesignNumberField`: a number typed in the reader's digits and separators (German's `1.234,5`,
  Arabic's `١٢`, or ASCII), taken on Enter (`onEditingComplete`: the focus stays), as the focus leaves or on a step,
  clamped to `min` and `max` and rounded to `fractionDigits` (by default the step's and `min`'s); text that does not
  read puts the last value back. A step goes to the next multiple of `step` (1 by default) counted from `min`, exactly
  in decimals; Up and Down step, Page Up and Down by `pageStep`, Home and End stay the caret's. Two step buttons
  (`buttonBuilder`, placed by `layoutBuilder`) step on a press and repeat while held; they are no tab stops and no
  nodes, as the field is adjustable itself. A whole step gets a number pad with no decimal key, a `min` of 0 or more
  no minus, and formatters keep out what can't become a number. The field's node takes its value from the input's; an
  input that says itself whether it is enabled (Material's `TextField`) stays a node of its own, so a look gives the
  value round it (`Semantics(value:)` on the field's text, as `DesignNumberField`'s docs show), or Flutter 3.47
  asserts that a node that steps has next and previous values but no value.
- A rating, `DesignRating`: a row of `itemCount` items filled up to a value, in whole steps or halves (`allowHalf`),
  a fraction shown as one. A tap sets the item tapped (a tap on the value already set changes nothing); hovering
  previews (`DesignRatingItemDetails.isPreview`); a drag sweeps across, changing the value as it goes, a step played at
  each, between `onChangeStart` and `onChangeEnd`. One tab stop: Right and Up step up, Left and Down down (mirrored
  right to left), End fills it, Home or 0 clears it, a digit sets that many; a screen reader hears a slider, "Rating,
  3 of 5", and steps it. `readOnly` shows a value (an average of 3.7): no input, no tab stop, not read as disabled.
- Charts, headless: the look draws every mark, axis and readout from the details it is handed. Scales with no
  widgets: `DesignLinearScale` (`.nice`: whole 1, 2 or 5 × 10ⁿ ticks), `DesignTimeScale` (ticks on calendar steps,
  seconds to centuries) and `DesignBandScale` (categories, `indexAt`), their ticks labelled in the reader's numbers and
  dates. `DesignChart` (line, area, bars, a sparkline; x as numbers, times or categories) and `DesignPieChart` (a pie or
  a donut) pick a point: a mouse the nearest along x, its series the nearest by y (a pie, the slice under it); a finger
  scrubs with a horizontal drag and a list still scrolls; a tap holds it until a tap elsewhere; one tab stop, Left and
  Right along x (mirrored right to left), Up and Down across series, Home, End and Escape. A screen reader hears the
  data in a sentence ("2 series, 12 points, January 2026 to December 2026, lowest 820, highest 1,640") or the picked
  point, steps through every point, and is offered "Show data table": `DesignChartTable`, the data as a table with
  its roles. New data springs from the values drawn, critically damped under Reduce Motion; x runs right to left in
  right-to-left text.
<!-- 0.3.0 values end -->

### Tooling
<!-- 0.3.0 tooling -->
- **Breaking: moved to ui_core_test.** The checks a design system's tests run, and the sheets that draw them for
  review, left `package:ui_core/alignment.dart` for a package of their own, `ui_core_test` (0.1.0, its versions its
  own), which a design system takes as a dev dependency, as an app takes flutter_test. An app compiles, analyzes and
  downloads none of it now: ui_core's library is about 9,700 lines smaller. `package:ui_core/alignment.dart` is gone,
  with no stand-in. To move: add `ui_core_test: ^0.1.0` to `dev_dependencies` (to a gallery example's
  `dependencies` when a page of it shows a sheet) and import `package:ui_core_test/ui_core_test.dart` where you
  imported `package:ui_core/alignment.dart`. The names are unchanged:
  - the alignment matrix: `DesignAlignmentMatrix`, `DesignAlignmentRow`, `DesignAlignmentEntry`,
    `DesignAlignmentBuilder`, `DesignAlignmentTheme`, `DesignInlineControl`, `DesignAlignmentSheet`;
  - the text entry check: `DesignTextEntryCheck`, `DesignTextEntryBuilder`;
  - the screen checks: `DesignKeylineCheck`, `DesignKeylineSheet`, `DesignLabelCheck`, `DesignRowCheck`,
    `DesignWidthCheck`, `DesignWidthLimit`, `DesignWidthKind`, `DesignWordBreakCheck`, `DesignClipCheck`,
    `DesignTapTargetCheck`, `DesignCursorCheck`, `DesignShadowClipCheck`, `DesignSpacingCheck`;
  - their results: `DesignAlignmentReport`, `DesignAlignmentError`.

  `DesignSpacing`, `DesignSpacingScope`, `DesignInput`, `DesignTapTargets` and `DesignTapTargetScope`, which
  `alignment.dart` also passed on, stay in `package:ui_core/ui_core.dart`. What a look's widgets wear for the checks
  stays too: `DesignCapCenter`, `DesignKeylineRegion` and `DesignKeylineFace`.
- `RenderDesignCapCenter`, `DesignCapCenter`'s render object, is public, as `RenderBaseline` is `Baseline`'s, so that
  a check in ui_core_test can find the cap center a label is drawn in and read its `capHeightFactor`.
<!-- 0.3.0 tooling end -->

## 0.2.1

- A menu or popover (`DesignAnchoredOverlay`) that its anchor opened gives focus back to the anchor as it closes
  (Escape, Android's back, a choice), even when a tap on the anchor left focus elsewhere. Before, focus went back to
  whatever held it before the tap: a combobox's field, say, whose list then opened again and held Android's next back,
  so the page did not pop.
- A combobox's or a tag input's list no longer opens on focus that ui_core gives back to its field (a popover the app
  opened, closing). Focus the user gives (a tap, Tab) opens it as before, and Down, a press or typing opens it at any
  time.
- Home and End in a menu or popover (`DesignAnchoredOverlay` with `arrowKeyNavigation`) focus its first or last item
  and keep it wholly in view, a lazy list run to that end first so the row is built; the item focused as it opens is
  kept in view too. Before, focus could land on a row scrolled out of sight, or, in a lazy list, on the last row built
  rather than the last item.
- Reduce Motion now includes iOS's. Flutter puts iOS's Reduce Motion in dart:ui's `AccessibilityFeatures.reduceMotion`,
  not `MediaQuery.disableAnimationsOf`, which is all ui_core read, so on an iPhone with Reduce Motion on, every spring
  ran as designed. A new read, `designReduceMotionOf(context)`, is true for Android's Remove animations, the web's
  `prefers-reduced-motion` and iOS's Reduce Motion. A widget that read it builds again when any of them changes.
  `DesignMotionPolicy.of` and every part that calms its motion (the carousel, side sheet, pull to refresh, command
  palette, scroll area, swipe actions and toasts) now read it. A look's own `MediaQuery.disableAnimationsOf` reads
  should move to it.

## 0.2.0

Nothing is renamed or removed: an app on 0.1.0 compiles on 0.2.0 unchanged. In a debug build, a value out of its
range now fails at once (see Behaviours). A list opened from a field is now the field's width, wider only to fit its
widest item (see Behaviours).

### Words in 30 languages

- `DesignLocalizations.delegate` loads the words for an app's locale: English and 29 more
  (`DesignLocalizations.supportedLocales`), English for any other. Translations are opt in: add the delegate beside
  Flutter's (`...GlobalMaterialLocalizations.delegates`, from `flutter_localizations`), as the README shows; a look
  supplies its own Material and Cupertino words.
- Dates, plurals and digits come from CLDR, through `DesignLocaleData`; the words Material already translates are
  Material's own. Our own 38 messages are new translations, awaiting a native speaker's check in every language but
  English (the README lists them).
- Three more shared words: Try again, Done and Confirm (`retryButtonLabel`, `doneButtonLabel`,
  `confirmButtonLabel`).

### Tap targets, density, spacing and style

- `DesignTapTargetScope` and `DesignTapTargets` declare the floors a look's controls stand at (44 by 44 for a finger,
  24 by 24 for a pointer, by default), and `DesignTapTarget` lays a control out at its floor, aligned where you say,
  with its semantics node spanning the whole target. `DesignInput` says whether a finger or a pointer reaches the
  controls.
- `DesignDensity` tightens a control's face in steps, never its tap target.
- `DesignSpacingScope` and `DesignSpacing` declare the grid a look's spacing stands on (4 pt by default).
- `DesignStyle`: one per-part style (fill, foreground, edge, overlay, side, shape, padding, minimum size, text
  style, icon size, each resolved against the part's states) for every look, in place of a copy in each.
  `DesignStyleOf` reads a part's own `style:` and then its component theme, first wins.

### The checks a look is held to

- `DesignTapTargetCheck`: every control's tap target reaches the look's floor for its input, where it is drawn.
- `DesignCursorCheck`: a live control shows the click cursor (or one that says more) over its whole hit area, an off
  control nothing of its own.
- `DesignShadowClipCheck`: no shadow, glow or rim is cut flat by a clip, and none shows square behind a round face.
  A scroll view's edge along its scroll, with more content past it, is scrolling, not a cut. `near:` reads only the
  casts that reach one control, for a test of its press, hover or focus.
- `DesignSpacingCheck`: a page's margin, concentric insets and gaps on the grid; `literals` reads a look's sources
  for spacing off its grid.
- `DesignWidthCheck.checkList` also fails a list wider than the larger of its field and its widest item, and names
  both widths. It reads a text field's face round its entry (an autocomplete's field view, with no toggle), a
  right-to-left line's words from the end they start at (Latin words in a right-to-left layout too), and a list as
  drawn where it can (one laid out with room round its face for a shadow is as wide as its face), its face too where
  it lies over the field's edge by a rule they share. It takes only a list across from its field, nearest first (a
  dialog's button beside the field's column is none of its), and reads a face lit from one corner (a groove's
  highlight too faint to stand off) to its box on its lit sides, so right to left its leading edge is not read short.
- `DesignAlignmentReport.advisories`: what a check notes without failing (uneven gaps, say).
- `test/moving_states.dart`: holds a press, a hover, a focus, a sheet and a swipe halfway, so a test can capture and
  check the moments between states.

### Behaviours

- A list opened from a field (`DesignAnchoredOverlay` above or below, `DesignOverlayPlacement.matchAnchorWidth`, on
  by default) is the field's width, wider only as far as its widest item needs, up to
  `DesignOverlayPlacement.maxWidth` (320 by default), never to the screen; its width is set before its first frame,
  so a reveal inside it stays under the field from the start. Before, a list whose rows stretched spread to the
  screen's width. Its widest item is read from its intrinsic width: rows in a `Column` (in a
  `SingleChildScrollView` when they scroll) say it; a lazy `ListView` keeps the field's width. A popover that keeps
  its own width (a calendar, a picker) turns `matchAnchorWidth` off, as before.
- A menu, select or popover (`DesignAnchoredOverlay`, the menu bar's menus) closes when a route is pushed over its
  anchor's (an alert, a dialog, a sheet), on the anchor's navigator or another (an alert on the root navigator over a
  page in a nested one), and leaves focus to that route. Before, it stayed open under the new route, and was still
  open when the route was popped.
- A quick tap shows its press, in a list and beside a long press: `DesignPressable` takes its pressed state from the
  pointer, and holds it at least `minimumPressDuration`.
- Under Reduce Motion an effects spring (opacity, colour) is a short fade with no overshoot, as a spatial one already
  was.
- `DesignScrollArea.thumbLength` gives the thumb one length whatever the content's (null keeps it proportional).
- `showDesignCommandPalette` and `DesignSideSheetRoute` take a `barrierBuilder`, so a look can paint its own barrier;
  `barrierColor` stays the default.
- An open swipe row shows the click cursor, and its strip clips only along the swipe, so an action's shadow is not
  cut at its top and bottom.
- A combobox's and a tag input's field keep a node of their own, so a screen reader outlines the field, not the
  options beside it.
- A combobox's and a tag input's list keys are ui_core's own, over `RawAutocomplete`'s: Up and Down go round past the
  ends; on a closed list, Down or Up opens it without moving; an opened list's highlight starts on the combobox's
  `value` (else the first option that can be taken). Opened before the user edits the words (by Down, a press, focus,
  a look's toggle), a combobox lists every option (with a `search`, what it finds for no query), its value
  highlighted; it filters once the user edits them. Home, End and letters stay with the text. Before, the keys stopped
  at the ends, Down on a closed list opened it one past the highlight, and a combobox reopened on its value listed
  only that option.
- `isOptionEnabled` (`DesignCombobox`, `DesignTagInput`) disables an option: it is painted with
  `WidgetState.disabled`, the keys pass over it, and neither a tap nor Enter takes it (nor, in a tag input, its name
  typed before a separator, pasted, or entered as free text).
- `highlightFollowsPointer` (`DesignCombobox`, `DesignTagInput`; off by default) makes the pointer and the keys one
  place, as in a native menu: a pointer moving over an option that can be taken highlights it, the keys go on from
  there, the highlight stays when the pointer leaves the list, and no option shows `WidgetState.hovered` apart. Off,
  the pointer's option is hovered and the keys' focused, for a look that paints them apart.
- A long list opened from a field (`DesignCombobox`, `DesignTagInput`) or in a command palette opens with its value
  (else its highlighted option) in view, and keeps the highlighted row wholly in view as the keys move it: round the
  ends, a page at a time, to the first or the last, rows of differing heights too. Before, a lazily built list never
  scrolled to a row it had not built yet, and the highlight moved out of sight.
- Android's back (its button or gesture) closes what ui_core holds open, the innermost first, and the page stays; the
  back after the last pops it. A menu or popover (`DesignAnchoredOverlay`: the menu bar's menus, a split button's, a
  popover) returns focus to its anchor; a combobox's or a tag input's list closes as Escape closes it, focus staying in
  the field; a list in a popover closes before the popover. Before, the back popped the page under them.
- In a menu bar's menu, a typed letter goes to the next item it starts (the same letter steps through them), and
  letters typed in a run spell the start, as a select's do.
- Every public widget describes its fields in the widget inspector and in test failures (`debugFillProperties`).
- A value out of its range fails at once in a debug build, with what was given: a slider's or a handle's value past
  its `min` and `max`, a `min` over its `max`, a split view's fraction outside 0 to 1, a non-positive step, size or
  spring.

### For a look's package

- ui_core's `analysis_options.yaml` is a template a look copies: the strict modes and Flutter's lints, with
  `public_member_api_docs`, `avoid_dynamic_calls`, `unawaited_futures` and a few more.
- `test/flutter_test_config.dart` turns on Flutter's leak tracking for every test, the test helpers' own objects left
  to them as in Flutter's config; `test/doc_examples.dart` compiles and runs every example in a package's docs. Copy
  them into your package's `test/`. A test that walks a whole gallery in one go passes the config's
  `longWalkLeakTesting` as its `experimentalLeakTesting:`: it tracks no leaks of its own, where a stack kept for every
  object it makes would run it out of memory.
- A rename keeps its old name, deprecated, for one minor version, with a `dart fix` (`lib/fix_data.yaml`) and a
  `test_fixes/` pair; the README shows the pattern, and how a theme's `.of` falls back. A package's `test_fixes/` has
  analysis options of its own, as Flutter's has, so `dart fix --compare-to-golden test_fixes` reads it through the
  package's exclude.
- A look's page transitions (the README's "A look's page transitions"): a look exposes its push as a map of
  widgets-level `PageTransitionsBuilder`s, one map for both Materials, and its example puts it in the app's
  `ThemeData`. Installed only in the Material theme a look builds (material_ui's), it never reaches Flutter's
  `MaterialPageRoute`. `example/test/page_transitions_test.dart` holds the pattern for a look's example to copy.
- `DesignSwipeBackPageTransitionsBuilder` keeps iOS's swipe back from the screen's leading edge round a look's own
  push, which drops Cupertino's transition and the swipe with it; `designSwipeBack` wraps a map's iOS entry in it. The
  README's page-transition pattern puts it in a look's map, and the example's test swipes a page back on iOS.
- `host.dart`, `inventory.dart` and `alignment.dart`, and a look's `<look>_parts.dart` and `<look>_host.dart`, say in
  their library docs that they are outside semver: tooling for looks that may change in any version.

## 0.1.0

- First release: 24 headless behaviours (see the README), the press and the value handle they are built from,
  `DesignLocalizations` for the words they and a look say by themselves, and spring motion that respects Reduce Motion.
- `host.dart`: the scaffold contract the look packages share (tabs, the shell's action, how a route is presented,
  preview frames, the media slot, English formats). It leaves the package in a later minor version.
- `inventory.dart`: the component checklist a design system answers, and the gallery that lists its answers.
- `alignment.dart`: the checks a design system's tests and review pages run on its screens: that its controls line
  up where they share a line, on Android, iOS and macOS, from their drawn pixels (`DesignAlignmentMatrix`,
  `DesignRowCheck`), that each label sits on the middle of its face (`DesignLabelCheck`), that a card's or a
  gallery section's contents start and end on shared lines (`DesignKeylineCheck`), that controls keep to their
  content's width on a wide screen (`DesignWidthCheck`), that no word breaks across lines
  (`DesignWordBreakCheck`) and nothing is cut (`DesignClipCheck`), and the sheets that draw them for review.
  `DesignKeylineRegion`, in the main library, marks a card or a section for them.
- `DesignControlBox` and `DesignTextEntryBox`: the layout that keeps a control or a text entry on its line.
- `DesignCapCenter`: a one-line label drawn with its capitals on the middle of its box.

## 0.5.0

- Needs ui_core 0.5.1.
- Field words take `InputDecoration`'s names: `label` is `labelText`, `hint` is `hintText`, `helper` (and `RetroDesktopNumberField.note`, `RetroDesktopFormField.help`) is `helperText`, and `error` is `errorText`, on `RetroDesktopTextField`, `RetroDesktopTextArea`, `RetroDesktopSearchField`, `RetroDesktopPasswordField`, `RetroDesktopInputGroup`, `RetroDesktopInputOtp`, `RetroDesktopSelect`, `RetroDesktopRadioGroup`, `RetroDesktopCombobox`, `RetroDesktopFormField`, `RetroDesktopNumberField`, `RetroDesktopInput` and `RetroDesktopDateRangePicker`. `dart fix` renames them.
- `RetroDesktopInputOtp.obscure` is `obscureText`, as `TextField` names it. `dart fix` renames it.
- `RetroDesktopCheckRow.error` and `RetroDesktopPressable.error` are `isError`, as `Checkbox` names it. `dart fix` renames them.
- `note` is `subtitle` on `RetroDesktopCheckRow`, `RetroDesktopSwitchRow`, `RetroDesktopRadio`, `RetroDesktopListTableRow`, `RetroDesktopDisclosure`, `RetroDesktopSectionHeader`, `RetroDesktopPartHead`, `RetroDesktopFolder`, `RetroDesktopFile`, `RetroDesktopFigureHero`, `RetroDesktopReadingHead` and `RetroDesktopChoice`, as `ListTile` names it. `RetroDesktopListTile` keeps its `note`, the line under its `subtitle`. `dart fix` renames them.
- `RetroDesktopPartHead.open` and `RetroDesktopTreeRow.open` are `isExpanded`, as `ExpansionPanel` names it. `dart fix` renames them.
- `RetroDesktopDatePicker` and `showRetroDesktopDatePicker`: `first` and `last` are `firstDate` and `lastDate`, as `showDatePicker` names them. `dart fix` renames them.
- `RetroDesktopTooltip.wait` is `waitDuration`, as `Tooltip` names it. `dart fix` renames it.
- `RetroDesktopScaffold.topBar` is `appBar`, as `Scaffold` names it, and `who` is `initials`, the two letters it shows. `dart fix` renames them.
- `RetroDesktopThemeData.type` is `textTheme`, as `ThemeData` names it. `dart fix` renames it.
- `RetroDesktopChip.enabled` is `isEnabled`, as `FilterChip` names it. `dart fix` renames it.
- `RetroDesktopArrowButtonPainter.c` and `RetroDesktopDeskPainter.c` are `colors`. `dart fix` renames them.
- `RetroDesktopShapes.of` is `RetroDesktopShapes.forAppearance`: in Flutter an `of` takes a `BuildContext`. `dart fix` renames it.
- `RetroDesktopColors.dark` and `RetroDesktopThemeData.dark` are `brightness`, a `Brightness`, as `ColorScheme` and `ThemeData` name it; `RetroDesktopColors(brightness:)` and `copyWith(brightness:)` take one. Code that read the bool compares with `Brightness.dark` instead.
- `RetroDesktopTextField.password` and `revealLabels` are gone: a password with its eye, its autofill hints and no suggestions is a `RetroDesktopPasswordField`. A text field with `obscureText`, or one asking for a visible password, takes no corrections or suggestions.
- The form wiring leaves the public API: `decorate`, `failureLine` and `nameOnly` on `RetroDesktopTextField`, and `decorate` and `failureLine` on `RetroDesktopSearchField` and `RetroDesktopInputOtp`, are gone.
- `showRetroDesktopSnackBar` shows its notice in ui_core's toaster, in the new `RetroDesktopToaster` that `RetroDesktopHost` installs above the navigator. A notice stands above `RetroDesktopNavigationBar` and a `RetroDesktopScaffold`'s footer (ui_core's `RawToasterKeepClear`), following them as they come and go, and at the foot on a page pushed over the bar. Before, it stood on the screen's foot, over the bar. A new notice still replaces the one showing; F6 now takes the keyboard to it and back, and a swipe sideways dismisses it.
- `showRetroDesktopSnackBar`'s `bottom` is gone: a notice keeps clear of the bars by itself, and a bar of your own does the same wrapped in `RawToasterKeepClear`. `dart fix` removes it.
- A `RetroDesktopCombobox`'s text input says whether its list is open (expanded), where a screen reader hears it.
- `RetroDesktopDatePicker(autofocus:)` focuses the chosen day when the picker appears; `showRetroDesktopDatePicker` opens on it, so the arrows go on from there.
- A focused chosen day in `RetroDesktopDatePicker` and `RetroDesktopCalendar`, and a focused chosen row in `RetroDesktopTreeView` and `RetroDesktopDataTable`, ring in the chosen words' colour, as a focused face already does. Before, Platinum drew the ring in the highlight on the highlight, where it didn't show, and Chisel's dots stayed dark on it.
- A field's help and its error are read on its text field in `RetroDesktopInputGroup`, `RetroDesktopSearchField`, `RetroDesktopCombobox` and `RetroDesktopInputOtp`, as in `RetroDesktopTextField`: a screen reader heard the help nowhere, and the error only apart from the field.
- `RetroDesktopSectionHeader`'s title is a heading to a screen reader, on a node of its own: under `RetroDesktopScaffold` it was not a heading, and the words after it joined it.
- `RetroDesktopColorPicker` takes a `value` and an `onChanged`, as Flutter's pickers do, and its `controller` is optional. Without one, the picker keeps a controller of its own, starts at `value`, moves to a new `value`, and disposes it. A handed-in controller is still the caller's to dispose.
- `RetroDesktopCalendar` takes `firstDate`, `lastDate` and a `value`, and its `controller` is optional. Without one, the calendar keeps a controller of its own for one day, chooses a new `value` and turns to its month, and disposes it. Hand in a controller for a range or a set of days.

## 0.4.1

- A default `RetroDesktopButton` with no `onPressed` lays its highlight down and stands as a plain button out of use in its grey ring, as it does in a window behind. Before, it kept a washed-out highlight face, so a button out of use looked two ways.
- A destructive `RetroDesktopButton` carries the alerts' stop sign before its words, the look's own pixel picture, on the face it would have anyway. Before, it carried a line caution glyph.
- `RetroDesktopDialogAction` takes `isDestructiveAction`. In the button row of a `RetroDesktopDialog` or `RetroDesktopBottomSheet`, one destructive action that isn't the default stands apart at the row's start, at least 24 from the others, as the period's alerts set Don't Save. When the buttons stack, they keep their order.
- On a desk, a `RetroDesktopWindow` with `onClose` has a title bar as tall as one without, so two windows side by side keep their titles level and the bar holds still as a closable window opens. Before, the close box's padded target made the bar 7 taller. A finger's reach still grows the bar.
- `RetroDesktopGlyphs.signOut` turns with the text: in right-to-left text its arrow points out of the words, to the left. It is now Lucide's `logOutDir`.
- `RetroDesktopDatePicker` and `showRetroDesktopDatePicker` take a `today`, as Material's `currentDate` does. The calendar outlines that day. Before, it outlined the device's date, which could stand beside the chosen day and read as a span.
- A list that opens under a focused `RetroDesktopSelect` hangs clear of the field's focus ring, so the ring stays whole. Before, the list sat on the ring's foot.
- A `RetroDesktopChart` whose values are all zero stands on a scale from 0 to 1. Before, its scale ran from −1 to 1.
- On a phone, a `RetroDesktopColorPicker`'s hue and alpha strips reach 48 high, as every control does there, each still drawn 14 high in the middle. Before, they reached 44. On a desk they keep 44.
- `RetroDesktopColors`, `RetroDesktopIllustrationColors`, `RetroDesktopChartSeries`, `RetroDesktopChart` and `RetroDesktopShellAction` have const constructors. The lists they take (`tones`, `sky`, `values`, `series`, `labels`) are kept as given, not copied, as Flutter's widgets keep theirs: don't change a list after handing it in.
- The example app opens a page from the shared link form only, `/#/text-fields?theme=dark&dir=rtl`. The older `?page=…&night=1` form is gone.

## 0.4.0

- **Breaking:** stands on ui_core 0.4.0. Flutter 3.47 or later, as before.
- **Renamed:** the ui_core types in this package's API take ui_core 0.4.0's `Raw` names. For example, `RetroDesktopMenuBar.menus` is a `List<RawMenuEntry>`, and `RetroDesktopDataTable.controller` is a `RawDataTableController`. The old names still work as deprecated typedefs, and `dart fix --apply` renames them.
- `RetroDesktopRadioGroup` is built on Flutter's `RadioGroup`, with a `RawRadio` for each option. The keys work as before. As with Flutter's `Radio`, a radio shows hover and focus while focus highlights are traditional (on a desktop, or once a mouse or a key was used), so its focus also shows after a mouse click. On iOS and macOS an unchosen radio reads as not selected.
- `RetroDesktopTooltip` is built on Flutter's `RawTooltip`. It shows on hover after its wait, on keyboard focus and on a long press, and rises and falls on the look's spring, as before. Run the pointer along a row of controls, and each tip waits its turn, as Flutter's do. Before, the next tip showed at once. A press hides a tip the pointer brought, as Flutter's do; before, the tip stayed while the control was held. A finger held anywhere on the area the tip belongs to shows it, as a resting pointer already did; before, only a finger held on the control itself did.
- When the buttons of a `RetroDesktopDialog` or a `RetroDesktopBottomSheet` don't fit in one row (long labels on a phone, large text), they stand in one column at the trailing end, each as wide as the widest, the default one on top. Before, the ones that didn't fit wrapped onto a row below.

## 0.3.3

- In Chisel, a focused radio's dotted rectangle stands round its label, a pixel clear of the words, as the PC drew it. The radio's sunken disc keeps its bevel and its dot. Platinum's focus ring is unchanged.
- A radio group takes its keyboard from ui_core's shared radio group, as every look's does. Tab enters on the chosen option, or on the first one you can choose, and a second Tab leaves the group. The arrow keys move and choose, wrap at the ends and skip options that are out of use; in right-to-left text, Left moves forward. Home and End no longer jump to the first or last option in a radio group. Use the arrows instead.
- Stands on ui_core 0.3.4.

## 0.3.2

- A chart's axes are measured again when a face arrives after the first frame, in the reader's locale. An Arabic reader's values (on the web their digits come from a fallback face fetched after the first frame) read whole instead of ending in "…٤", and the day letters under the chart are no longer clipped.

## 0.3.1

- Keyboard focus follows the rounded ends of Platinum button groups, toggles and split buttons. On parts joined to their neighbours (folder tabs, the places on the menu bar, a number field's value) Platinum draws its focus ring inside the part, clear of the next one.
- The zoom and shade glyphs stand on the middle of their Platinum title-bar boxes, and every window control is centered on the device pixel grid. A window's title and its glyph stand on the same middle line as the boxes at every pixel ratio.
- A chart's value axis is as wide as its widest value, so the values start at the chart's edge, in line with the words and buttons around it.
- `RetroDesktopFormField` takes `mergeSemantics`, as ui_core's field does. Left null, the field reads what its control brings: one control (a text field, a select, a switch) takes the field's name, help and error; several (radios, a segmented button, chips, a row of boxes, a number field's value and its steps, a password and its Show button) keep their own screen-reader nodes, so a tap with semantics on reaches the control tapped, not the field's first; and the name is said once where the control already says it. A number field's value stands in a node of its own, so a tap through the semantics tree on - or + no longer puts the keys in the value.
- Moving the pointer away from an open menu clears its title and row highlight immediately. The menu stays open for another selection.
- Segmented controls and fields with prefixes or suffixes adapt to their labels at larger text sizes. Document and window titles reflow when a fallback font loads. Amounts due stay visible while invoice columns scroll.
- A time picker names its hour, minute and AM/PM fields, and says AM and PM, in the app's language, from ui_core's `DesignLocalizations` (they were English in every language). `RetroDesktopLocalizations.delegate` takes every locale: a German or Arabic app that installs it no longer has Flutter's unsupported-locale warning, and its dates and numbers follow the app's locale.
- List rows announce their subtitles, window titles are announced once per group, and step counts keep their reading order in right-to-left layouts.
- The Papers example remembers saved contact details, disables document commands for an empty search, and keeps the confirmation actions clear on phones.

## 0.3.0

Needs ui_core 0.3.0. Retro Desktop's parts take more of their behaviour from ui_core now and keep their pixels: the
same windows, bevels and faces, with ui_core's keys, screen-reader words and focus under them. Its motion is still
the period's: everything stands at once unless an app sets a time.

Breaking:

- `RetroDesktopWindowSizeClass` is gone. `RetroDesktopThemeData.window` is ui_core's `DesignWindowSizeClass`, on the
  same Material breakpoints, except that from 1600 wide it is `extraLarge` (Retro's `large` ran from 1200 up).
- `RetroDesktopTabBar` calls `onChanged` only when the tab changes. A press (or Enter) on the open tab, which called
  it again with the same index, does nothing now: ui_core's `DesignTabBar` reports changes only.
- `RetroDesktopNumberField` is a field you type in (ui_core's `DesignNumberField`). Up and Down step it, Page Up and
  Page Down step ten, and a held step button repeats; Left and Right move the caret in the number now, where they
  stepped it before. Its two step buttons are pressed, not tabbed to: the field is the one tab stop, its focus ring
  drawn inside its box so the buttons flush beside it never cover it.
- `RetroDesktopTooltip` is a `StatelessWidget` (ui_core's `DesignTooltip` holds the state).

Changes:

- `RetroDesktopTooltip` is ui_core's `DesignTooltip` in Retro's tooltip face. It still waits for the pointer to rest
  and stands at once. It now stays while the pointer moves onto it, closes on Escape, shows one at a time, and opens
  at once along a toolbar after the first.
- The gallery's menus spell their shortcuts with ui_core's `designShortcutLabel`, in the platform's order and the
  reader's words; in words on a Mac too ("Command+N"), since none of Retro's faces draws ⌘ ⌥ ⇧ ⌃.
- Menus light one row, as before: the row the keys moved to, or the one a moving pointer last crossed, never the row
  that happens to sit under a resting pointer as a menu opens from the keys.
- `RetroDesktopCombobox` takes `search` and `debounceDuration`. While an app's search is on its way the list says
  "Loading"; when it fails it says "Couldn't load results" and offers Try again, which the arrow keys reach and Enter
  runs. `options` may be left out with a `search`. "Loading" and "No results" stand as wide as the list, as its
  options do ("No results" shrank the list to its words before).
- `RetroDesktopRating` is ui_core's `DesignRating` under Retro's pixel stars: one tab stop instead of a button a star,
  the arrows a star at a time, Home none, End all, a digit that many, and a drag that sweeps across; a screen reader
  hears a slider it can step. Its focus ring stands round the stars. A tap on the stars already given still clears
  them, and the pointer resting on them still lights nothing.
- A chart's gridlines stand on ui_core's nice scale (`DesignLinearScale.nice`): round values of 1, 2 or 5 times a
  power of ten that hold the data.
- Dialogs (`showRetroDesktopDialog`) and the router's sheet pages ride ui_core's routes (`DesignDialogRoute`, and
  `DesignBottomSheetRoute` on a phone). A screen reader hears a dialog, Tab stays inside it, and focus returns to what
  opened it. A sheet page on a phone follows a finger that drags it down and goes with a fling, above the keyboard.
  They still stand at once, dim nothing behind them, and Escape still follows `escapeDismissible`.
- `RetroDesktopTabBar` is ui_core's `DesignTabBar` with Retro's folder tabs: one tab stop on the open tab, the arrows
  (mirrored right to left), Home and End, and a screen reader hears "Today 3, Tab 1 of 3". Tabs too wide for their
  room still scroll and show the look's arrows.
- In Platinum, a held or chosen segment at either end of a joined strip (`RetroDesktopToggleGroup`,
  `RetroDesktopButtonGroup`, `RetroDesktopSplitButton`) sinks into a well concentric with the strip's rounded frame:
  it meets the outline at the end as it does above and below, and its corners are the frame's less the outline. It
  was a square well that stopped a pixel short at the end. `retroDesktopHeldGround` takes the frame's `outline` and
  the well's `reach` for this; `retroDesktopBevelStep` paints one step of a bevel round any outline.
- Each gallery page, and `RetroDesktopPreview`, is its own semantics container, so a screen reader hears the gallery's
  side navigation and every section heading around a nested app.
- The review checks come from `ui_core_test`, a dev dependency.

## 0.2.1

Retro Desktop on ui_core 0.2.1.

- **Reduce Motion on iOS.** The look's motion stood still for Android's Remove animations and the web's
  `prefers-reduced-motion`, but not for iOS's Reduce Motion: Flutter reports that one only in dart:ui's accessibility
  features, not in `MediaQuery.disableAnimationsOf`. The look now reads all three through ui_core's
  `designReduceMotionOf`. With any of them on, `RetroDesktopMotion.of` gives every timing as zero, a page set to fade
  changes at once, and the kit composites' motion is still.
- **Focus goes back to what opened a popover.** Through ui_core 0.2.1, a `RetroDesktopPopover` or a
  `RetroDesktopCombobox`'s list gives focus back to the control that opened it as it closes. The combobox's list no
  longer opens again on that returned focus, so Android's back pops the page.
- **Tests in two tiers.** `flutter test --exclude-tags goldens,sweep` runs the everyday tier: every part, page and
  behaviour at representative sizes, by day and by night, right to left and at twice the text size. The exhaustive
  matrices (every width, mode, direction, platform and preset) are tagged `sweep` in `dart_test.yaml`, and
  `--exclude-tags goldens` still runs everything. The behaviour suite now runs in three files, a third of its 3,000
  cases each, so no single test process holds them all.

## 0.2.0

Retro Desktop on ui_core 0.2.0.

- **Fields, sheets and menus no longer crash in apps set to a language other than English; their built-in labels now
  follow the app's language.** In 0.1.0 a text field threw "No MaterialLocalizations found" in an app in German or
  Arabic, even one with `flutter_localizations`, whose words are Flutter's own, not those of `material_ui` and
  `cupertino_ui` that the look is drawn with. The look now loads their translations itself: a field's copy and paste
  menu and its selection handles read "Kopieren" in German and Arabic in Arabic, on Android and iOS, and English in a
  language they don't have.
- **Selecting text with the theme under your home page.** On iOS, a field's selection handles and menu build above
  the page, and threw "No Retro Desktop theme in scope" when `RetroDesktopTheme` sat under the app's `home` rather
  than in its `builder`. `RetroDesktopTheme.of` now gives the look's default (classic, by day) where no theme is
  above, as `Theme.of` does; `RetroDesktopTheme.maybeOf` still gives null there.
- **A tap lands where the control is.** The area a tap or click reaches, the box a screen reader outlines and the
  control's layout are now the same box (ui_core's `DesignTapTarget`): nothing is pressed past a control's edge any
  more, so a press near two controls goes to the one under it. Under a pointer a control is at least 24 wide and 44
  high; under a finger at least 48 by 48. A quiet button's outline is the box a tap reaches, not the face that hangs
  over its column's edge.
- **Calendars fit a phone.** A day is 44 wide under a finger, so a week fits a phone's window: no day hangs past its
  column where a tap couldn't reach it.
- **Night lighting.** By night a raised part is lit from the top left, as by day: its top and left edges were black
  and read as a hole. Pressed, its outline turns in with its bevel, dark above and left and lit below and right; it
  went flat grey all round.
- **Only the front window is active.** Under an alert, a dialog or a sheet, the window behind draws its title bar
  without stripes, its default button quiet (a grey ring round a plain face, in the same place) and its chosen row in
  grey, as any window behind does, so one default button answers Return. Closing the alert gives the front back; a
  menu leaves the window it drops from active. An alert that opens while a menu or a popover is open closes it, the
  focus in the alert, rather than standing over a menu with its row still lit.
- **Alerts and side sheets stand below the menu bar.** At twice the text size on a phone a tall alert covered the
  bar's last row; it now stands below the bar and scrolls if it must, and on a desk it stands where it did. A side
  sheet stood over the bar's end; it now stands 8 below the bar.
- **Pages change in place.** `RetroDesktopPageRoute` pushes a page the look's way: it stands in its place at once and
  pops the same way, where a `MaterialPageRoute` slid in from the side or zoomed, as the platform does (on a Mac, the
  Cupertino slide). For an app's own `MaterialPageRoute`s, `retroDesktopPageTransitions` is the look's page change on
  every platform, one map for Flutter's `ThemeData.pageTransitionsTheme` and material_ui's (the README's setup and
  "Pages change in place"); a Material page route pushed under `RetroDesktopTheme` in a `material_ui` app already
  changes this way.
- **Menus come and go at once.** A menu bar's menu, a split button's menu and a popover faded in over a quarter second and
  lingered as long after their item was chosen (ui_core keeps a closing panel until its presence spring settles); they
  now stand whole in their first frame and are gone in the first frame after a choice, as the period's menus were.
- **An open list shows its choice.** In a select's list, a combobox's list and a menu with a choice (a menu bar's
  checked item), the chosen option stands in the held well, the darker grey with its bevel turned in, and carries its
  check; the row under the pointer or the keyboard takes the highlight bar. In 0.1.0 both were the highlight bar, and
  the chosen row lost its mark as soon as the pointer entered the list.
- **List and menu keys.** A combobox's list keys are ui_core 0.2.0's: the arrows go round, Page Up and Page Down jump,
  Down or Up on a closed list only opens it, an opened list starts on the choice and shows every option until you edit
  the words. A menu bar's menu goes to the item a typed letter starts. And a menu opened from the keyboard as an
  app's first input lights its row: the look followed the keys only once a menu asked, so that first key went unseen.
  In a combobox's list the pointer moves the one lit row and the keys go on from it, as in a select's list and the
  period's pop-up menus; a long list opens with its choice in view and keeps the lit row in view as the keys move it.
- **Enter in a combobox keeps the field.** Enter takes the lit option and the field keeps the focus, so you can type
  the next words at once, in a browser too. In 0.1.0 Enter took the option and the focus with it.
- **One lit row in a menu.** A menu bar's menu, a split button's menu and a `RetroDesktopMenuAnchor`'s menu light one
  row, the keys' or the pointer's, whichever moved last; the pointer moving over a row takes the keys' place, so the
  keys go on from the row it lit. With the pointer resting on one row while the keys moved to another, both were lit;
  and an anchor's menu opened from the keys under a resting pointer lost its keys' row. Opened by a click a menu still
  lights no row until the pointer or the keys move; opened by the keys, its first.
- **The back swipe on iOS.** A page pushed with `RetroDesktopPageRoute`, or a `MaterialPageRoute` under
  `retroDesktopPageTransitions`, pops with the edge swipe again on iOS (ui_core's
  `DesignSwipeBackPageTransitionsBuilder` round the look's change): the page follows the finger while it is held and
  still stands in place otherwise. The look's change in place had dropped the swipe Flutter's Cupertino slide carries.
- **Android's back closes what is open first.** A menu bar's menu, a split button's menu, a popover and a combobox's
  list close on back, the innermost first, and the page stays; the back after pops it. Before, it popped the page
  under them.
- **A phone's title bar has only its close box.** Off the desk a window is the screen, so its zoom and window-shade
  boxes did nothing; they are gone, and the stripes run evenly on both sides of the title.
- **The close box turns in** while it is held, as every pressed part does.
- **Table heads fit their words in every script.** On the web a column head in Hebrew was measured before its font
  arrived and drew cut to an ellipsis; a table now measures again when a font loads.
- **Large text.** A window's information strip keeps its count whole at large text sizes; its other fact moves to the
  next line instead of cutting the count short.
- **A bottom sheet is a window.** Its title and its close box stand in a title bar, striped while it is in front, as a
  side sheet's do, on a phone and on a desk; raised with `showRetroDesktopBottomSheet` and given a title but no
  `onClose`, its close box closes it. In 0.1.0 the title stood in the sheet's body beside a Close button, and a sheet
  given no `onClose` had no way out that showed. An action sheet stays a panel, its Cancel its way out.
- **Short sheets.** A sheet too short for a line of its content and its footer (while it opens, or on a short screen
  with the keyboard up) lets the footer scroll with the content, so its content always shows a line.
- **Desk icon names read whole at large text sizes.** A name broke inside a word ("Docu" over "ments"); an icon's
  name plate now grows with the text (`RetroDesktopDeskIcon.widthOf` gives a rail its width) and a name breaks only
  between words, on two lines at most. One that still can't fit stands on one line cut in its middle, as the Finder
  cut a long name ("Quarterly…ation"), and a screen reader reads it whole.
- **The scroll box keeps one length,** as the period's did (24 under a pointer, 44 under a finger), instead of growing
  and shrinking as a long list builds its rows.
- **One style for every look.** `RetroDesktopStyle` is now ui_core's `DesignStyle` under the look's name, with the
  same slots, and `RetroDesktopStyleOf` reads a part's layers at its states. Code that builds or passes a
  `RetroDesktopStyle` is unchanged.
- **Deprecated:** `RetroDesktopThemeData.copyWith(motion:)`. The look is instant, as the period was: its motion is
  part of the look, not a setting. Leave the argument out (`dart fix --apply` removes it); Reduce Motion is still
  honoured. It goes in 0.3.0.
- **What keeps the look, written down.** The README and the API docs now say which customisations stay Retro Desktop:
  a part's `shape` is the appearance's, drawn on the pixel grid (a stadium or a large radius is drawn smooth and off
  it); the desktop, paper, text and highlight colours are yours, while the machine's greys and the bevel and outline
  colours are steps of one bevel, retuned together or not at all. The README's hover example now gives Balloon Help (a
  tooltip) instead of a hover wash the period never drew.
- **Breaking:** `a.merge(b)` keeps each of `a`'s slots whole, as `ButtonStyle.merge` does. If `a` sets a slot for
  some states only (a fill for pressed, say), `b`'s value no longer shows in the other states: at rest the button
  shows its theme's fill, not `b`'s. To keep 0.1.0's result, where `b` filled in every state `a` left open, write
  `DesignStyle.layered([a, b])` in place of `a.merge(b)`.
- **30 languages.** Add `DesignLocalizations.delegate` to your app's `localizationsDelegates` (and
  `DesignLocalizations.supportedLocales` to its `supportedLocales`) and the parts speak your app's language, with its
  dates, digits and plurals. The Material and Cupertino words the parts' machinery needs come with the look, so an app
  needs nothing more for them.
- **`RetroDesktopSpacing`** names the look's spacing steps on its 2-pixel grid (`px`, `s2` … `s40`), for your own
  layouts to keep its rhythm; the theme declares the grid to ui_core (`DesignSpacingScope`).
- **In the inspector.** Every public widget lists the fields it was built with in Flutter's inspector and in a failing
  test's tree, those left at their defaults hidden.
- **Mistakes show in debug builds.** A value out of its range asserts: a selected index before the first, a text field
  or text of no lines, a negative indent or tree level, a scale of no divisions or no top.
- **Every example in the docs compiles and runs,** in the package's own tests.
- **Plumbing** (`retro_desktop_parts.dart`, outside semver). `RetroDesktopReach` is now a widget that builds ui_core's
  tap target, with `RetroDesktopReach.floor`; `RenderRetroDesktopReach` takes that floor and an alignment.
- **Example.** Papers finds documents as you type, asks before closing a document with unsaved changes, says when an
  order for printed copies fails, and speaks Hebrew right to left. Its windows on a desk are as tall as what they
  hold. On a tablet it tiles the documents list and the window in front side by side; a window alone keeps its desk
  width beside the desk's icons. The gallery runs in each of the 30 languages with
  Flutter's own words beside ui_core's, as an ordinary app does.

## 0.1.0

The first release of Retro Desktop: a pixel-era desktop UI for Flutter.

- **Theme.** `RetroDesktopTheme` and `RetroDesktopThemeData` with five presets (classic, lagoon, berry, marmalade,
  slate), each for day and night, and `RetroDesktopThemeData.from` for a palette from one brand colour. Two
  appearances, `RetroDesktopAppearance.platinum` (the classic Mac, the default) and `RetroDesktopAppearance.chisel`
  (the 95-era PC), each with its own corners, bevels, default button, pressed state, focus mark, title bar, checks,
  select, progress, slider and tabs. Density (`standard`, `comfortable`, `compact`, adapting to the platform when
  unset) and a replaceable typeface. `copyWith`, equality and `lerp`; `AnimatedRetroDesktopTheme`.
- **The era's pictures.** Alerts, banners, snack bars, error states and dialogs given a tone open with the
  period's alert pictures, drawn for this package in whole pixels; the spinner and the loading state show the busy
  pointer, the wristwatch in Platinum and the hourglass in Chisel; skeleton bars are the 50% checkerboard.
- **Styles.** A component theme for each part, set through the theme's `copyWith`, and a `style:` on each widget, both
  `RetroDesktopStyle`: fill, foreground, edge, overlay, side, shape, padding, minimum size, text style and icon size,
  each resolved by widget state.
- **Parts.** One `RetroDesktopButton` (default, destructive and text forms), icon, toggle and split buttons, button
  groups; text field, text area, password, search, number, code and file fields, input group, form field and combobox;
  checkbox, radio, switch, slider, range slider, stepper, segmented control, chips and rating; select, calendar, date
  and time pickers, date range and colour pickers; menu bar, menus, tabs, navigation bar and rail, breadcrumb,
  pagination and steps; lists, tables, data table, tree and reorderable list; cards, media, avatar groups and
  description lists; dialogs, sheets, action sheets, popovers, tooltips and snack bars; progress, banners, empty,
  loading and error states; line, bar, area and pie charts.
- **Built by the look's laws.** A part the period never had is made from its materials, or left out: a reordered row
  is dragged as a dotted outline to an insertion line, and nothing behind a dialog or a sheet is dimmed. Swipe actions,
  pull to refresh, carousels, toasts, hover cards and tag-style multi-select aren't in 0.1.0; the README's "How Retro
  Desktop is built" says what to use instead.
- **The desktop's own.** Windows on a woven desktop, a 12-column tiled desk from 1024 wide and a stack of windows on a
  phone, the menu bar, desktop marks, window shades, pixel art slots, gauges, calendars and figures.
- **Input and accessibility.** Shared keyboard, pointer and semantic activation; visible focus in each appearance;
  48-pixel touch and 44-pixel desktop targets; the user's text scale kept. Changes are instant, as the era's were:
  every timed change takes a `RetroDesktopMotion` duration, all zero by default, and Reduce Motion forces zero.
- **Localizations.** The words every look shares from ui_core's `DesignLocalizations` (translated by extending
  `DefaultDesignLocalizations`); the look's own words, English, from `RetroDesktopLocalizations`; dates and numbers
  through `intl`. Right to left mirrors every part.
- **Fonts.** Jersey 15, Atkinson Hyperlegible Next and Mono and the icon face bundled, loaded with
  `retroDesktopLoadFonts`.
- **Libraries.** `retro_desktop_ui.dart` for apps; `retro_desktop_parts.dart` for a component copied out to change;
  `retro_desktop_host.dart` for an app shell's host layer.
- **Example.** The live gallery: every part, six ordinary applications, the look's own pieces and a Customize panel.

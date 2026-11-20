## 0.2.3

- Stands on ui_core 0.3.4.
- Keyboard focus marks one edge of a control with a solid accent block.
- A disabled checkbox with a validation error keeps a warning square beside it.
- The slider thumb sinks on pointer down and rises after release or cancellation.
- `BrutalSegmentedButton` is one radio group, as Flutter's `RadioGroup` is: Tab stops once, on the chosen cell, and the arrow keys move the choice, wrapping at the ends and moving on with Left in right-to-left text. Home and End still choose the first and last cell. A screen reader hears each cell as a checked or unchecked radio.
- `BrutalRadio`'s documentation shows how to group a set with ui_core's `DesignRadioGroup`, passing the group's node to `focusNode`. The example app's radios are grouped that way.

## 0.2.2

- `BrutalFormField.mergeSemantics` is now `bool?` and defaults to null: ui_core's field decides from the child. A child with one control, such as a switch, a checkbox or a slider, is one node named by the field's label. A child with several controls, such as segments, chips, radios or a stepper's buttons and number, keeps each control's own node, so a screen reader's double tap, or a click on the web with semantics on, reaches the control under it. The label names the group and is read once. Previously the default merged a group into one node, so a tap through the semantics tree reached only its first control and a stepper's tap did nothing. Pass `true` to keep the old merge or `false` to always name the child as a group. Needs ui_core 0.3.2.
- Wheels (the time picker's and `BrutalWheelPicker`'s) keep their rows' size at any text size, as Cupertino's do, so a larger figure no longer cuts its neighbours.
- Tables never break a figure or a word. Each column is at least as wide as its widest number or word at the current text size, so a time reads 19:30 and a price £18.00, and the table scrolls sideways when they don't fit, as Material's data table does.
- Button groups and the calendar grow their words with the system text size up to twice their size, as Material's time picker and calendar do, so a toolbar's 100% and a two-digit day stay inside their cells at larger sizes.
- Chips grow with their words at larger text sizes instead of cutting them, as Material's filter chips do.
- The time picker's wheels are named in the reader's language, from ui_core's `DesignLocalizations` (`timePickerHourLabel` and `timePickerMinuteLabel`), so a screen reader says "Stunde" in German and "ساعة" in Arabic. Previously they were "Hour" and "Minute" in English in every locale.

## 0.2.1

- Calendar popovers scroll when the available height is short. The last day of the month stays reachable at large text sizes.
- Step progress displays the steps in a vertical list when their names would be cut off.
- Line, area and bar charts scale the axis labels with the system text size. Category labels stay within the frame and leave space between neighbouring labels.
- Large app bar titles use the available height above the bottom rule. Equal-width tabs and segments keep their full labels when text is enlarged.
- The stepper's number cell fits its widest value at the current text size, and its step cells match its height. Date fields wrap a long date onto a second line instead of cutting it off.
- In Admit, event dates keep both day digits together, the English event count reads in order in right-to-left layouts, and the purchase footer stacks when its price and button cannot share a line.
- In the selection gallery, tapping a checkbox, radio or switch label activates its control.
- Admit validates checkout details and brings the first field that needs attention into view. The saved card is shown by its last four digits.
- Purchased tickets appear in Upcoming with their quantities, prices and a scannable order code. Cancelling removes the order and its code. Undo restores it.
- Account edits carry through to checkout. Signing out hides the account and its tickets until the demo account is opened again.

## 0.2.0

Built on ui_core 0.3.0. Brutal's tooltip, menus, dialog, sheets, tab bar, places, wheels, stepper, rating and chart
axis now take their behaviour from ui_core (its focus, keys, semantics, gestures and springs) and keep Brutal's paint:
they look as they did, and they do more. The breaks below touch only code that named a stepper's cell labels or took a
part for a `StatefulWidget` or a `StatelessWidget`.

### Breaking

- `BrutalStepper.decreaseLabel` and `increaseLabel` are gone. The minus and plus cells are no longer tab stops or
  screen reader nodes: the number is one adjustable field a screen reader steps and names by `semanticLabel`.
- `BrutalTabBar` is a `StatefulWidget` (it holds ui_core's tab controller) and `BrutalMenuPanel` a `StatelessWidget`;
  their constructors are unchanged.
- `showBrutalDialog` pushes ui_core's `DesignDialogRoute` and `showBrutalSheet`, `showBrutalBottomSheet`, the action
  sheet and `BrutalSheetPage` its `DesignBottomSheetRoute`, no longer a `RawDialogRoute`: code that tells them apart by
  the route's type checks for those.

### Behaviour that changes

- `BrutalTooltip` shows at once when the keys bring the focus to its control, the pointer may move onto it, Escape
  hides it, and running the pointer along a row of controls shows each one's at once.
- A menu a pointer opened lights no row, as before, and its surface holds the keys: Down goes to the first row, Up to
  the last.
- A dialog keeps Tab inside it and gives the focus back to what opened it; it and the sheets move on springs with the
  speeds they had (ζ 1, k 700, about 240 ms). A sheet follows a drag down and closes when let go low or flung, its
  body handing the drag over once scrolled to its top.
- `BrutalTabBar` and the places of `BrutalScaffold` and `BrutalAppShell` are each one stop for Tab, on the chosen
  one; the arrows move round them (mirrored right to left), Home and End go to the ends; a tab chooses as the keys
  reach it, a place on Enter or Space. A screen reader hears tabs, and places, with their place ("Past, Tab 2 of 2";
  "Home, Tab 2 of 5", where a place was a button); a desk's side list is the navigation menu. F6 moves between the
  places and the page. The chosen tab's bar grows on the tabs' spring and follows a swipe. A tab that hugs its words
  keeps the room of its words in bold whether chosen or not, so choosing one no longer moves the rules by a pixel.
- A phone's bar of places springs away under a page pushed over the root (`BrutalScaffold.showNavigation`), where it
  was taken out at once.
- `BrutalWheelPicker` and `BrutalTimePicker` take Page Up and Down, Home and End and a typed name, and Left and Right
  move between the time's two wheels; a key, or a tap on a row, turns a wheel to it on a spring. A drag that starts
  on the rule between the time's wheels turns a wheel, where it scrolled the page, and a mouse drag turns them too.
- `BrutalStepper`'s number takes typing in the reader's digits, read on Enter or as the keyboard leaves, clamped to
  `min` and `max`; Up and Down step it, Page Up and Down by ten, and a held cell repeats.
- `BrutalRating` is one tab stop: the arrows step it, End fills it, Home or 0 clears it, a digit sets that many; a
  drag sweeps along it, and a resting pointer inks the cells up to it; a press on the strip's end rule or shadow
  fills it, where it did nothing. A screen reader hears a slider.
- A chart's value axis stands on whole steps of 1, 2 or 5 × 10ⁿ (an axis to 250 is marked every 50, where it was
  62.5), labelled in the reader's numbers, as is the read-out a screen reader hears.
- Right to left the charts are mirrored: the categories and time run from the right, the value axis and its numbers
  stand on the right, a sparkline runs from the right and a pie's slices go round the other way from the top.
- `BrutalPreview`'s app is a semantics container of its own, so a screen reader still meets what the page paints
  before it (its routes' barriers hid it).
- Right to left every hard shadow falls the same way, down and to the left: the kits' raised and floating shadows
  (they fell to the right) and a reordered row's lift, now up and to the right, against its shadow.

### New

- `BrutalCombobox` and `BrutalTagInput` take a `search` that may take time and fail, with `debounceDuration`: the list
  says "Loading" by a small spinner while it runs, and a failed one says so over a "Try again" row that Down reaches.
  `options` is no longer required.
- `BrutalKbd.shortcut(activator)` prints a keyboard shortcut's keys in the platform's order and the reader's words,
  and `BrutalMenuItem.activator` shows one at a menu row's end (`⌘S` on a Mac, `Ctrl+S` elsewhere).

The package gallery includes six screenshots of the Admit example on desktop and mobile.

## 0.1.1

Needs ui_core 0.2.1.

- Reduce Motion on iOS calms Brutal too. Flutter puts iOS's Reduce Motion in dart:ui's
  `AccessibilityFeatures.reduceMotion`, not in `MediaQuery.disableAnimationsOf`, which was all Brutal read, so on an
  iPhone with Reduce Motion on, Brutal's colour changes, theme changes, arrows, tab and page-dot bars and loops still
  ran. Brutal now reads ui_core's `designReduceMotionOf`, which also covers Android's Remove animations and the web's
  `prefers-reduced-motion`. The spinner, the running progress bar and the skeleton stop looping, and when the setting
  changes while one runs, it stops or starts at once.
- A data table's counts under its pages were English whatever the app's language, with no plural form. Each now
  comes from the localizations with its number: the selection's from ui_core's `DesignLocalizations` ("1 item
  selected", "2 items selected"; was "2 selected"), translated in its 30 languages, and the rows' from the new
  `BrutalLocalizations` ("1 row", "2 rows"), English unless an app gives its own through a
  `LocalizationsDelegate<BrutalLocalizations>`.
- From ui_core 0.2.1: a menu or popover its anchor opened gives the focus back to the anchor as it closes, and Home and
  End in a list keep the row they reach in view.

## 0.1.0

- First release. The theme (light and dark, three densities), the surface (the rule, the hard shadow, the press, the
  focus rule) and the everyday parts: `BrutalButton`, `BrutalIconButton`, `BrutalTextField`, `BrutalSelect`,
  `BrutalCheckbox`, `BrutalRadio`, `BrutalSwitch`, `BrutalSegmentedButton`, `BrutalStepper`, `BrutalListGroup`,
  `BrutalListTile`, `BrutalSectionHeader`, `BrutalBlock`, `BrutalTag`, `BrutalAppBar`, `BrutalTabBar`,
  `BrutalNavigationBar`, `BrutalNavigationRail`, `BrutalSideNavigation`, `BrutalScaffold`, `BrutalDialog`,
  `showBrutalBottomSheet` and `BrutalToaster`.
- The app frame: `BrutalHost` (the theme, the toaster and the paper above the navigator), `BrutalScreen` (a page's
  margins, column, bar, footer and keyboard), `BrutalPage` and `BrutalSheetPage`, `BrutalAppShell` with `BrutalTab`s and
  a `BrutalShellAction`, `BrutalLoadingState`, `BrutalErrorState`, `BrutalInput` and `BrutalPreview`.
- Buttons take their words first, as Flutter's text does: `BrutalButton('Save', onPressed: save)`.

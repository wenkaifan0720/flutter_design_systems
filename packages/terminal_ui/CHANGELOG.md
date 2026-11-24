## 0.5.2

- On a phone a toast stands a line clear of `TermScaffold`'s status line, which stands on the window list: the line is a bar there too, in the shell's bar with the window list, and the toasts stand above both. It stood on the line, over the page's last line (an editor's Save). The window list alone is still the tab bar, and at the widths with a rail or a side pane nothing moves.

## 0.5.1

- After a `TermMeter`'s blocks (and a `TermProgress`'s and a bar chart's), the first dot stands one dot gap from the blocks' end, the gap between two dots, whatever eighth of a cell the blocks end on. The dots follow the blocks at the cells' pitch, one for each cell the blocks leave, as before. On the cells' middles a dot after a part block stood up to a cell and a half from it (about 9 px against 5 between dots), and one after a whole block half a gap.

## 0.5.0

- Requires ui_core 0.6.0, whose `Design*` names are `Raw*` now (`RawTapTargets`, `RawInventoryEntry`, `RawModalDialogRoute` and the rest).
  `dart fix --apply` renames them in an app (ui_core's `lib/fix_data.yaml` holds them); Terminal's code, docs and
  examples use the new names, the README's `RawWidgetsLocalizations` among them.
- A date picker's days are written in the app's digits by ui_core (`RawCalendarDayDetails.label`), as Terminal wrote them.
- A toast stands a line clear of `TermScaffold`'s status line where the line runs the screen's width at its foot (beside a
  rail or a side pane, or with no destinations), as it stands clear of a phone's window list. It stood on the line,
  over the page's last line (a detail pane's Save).
- A `TermTooltip` shows nothing over the `TermMenu` or `TermPopover` its control opened. A press by a screen reader,
  or by the web's semantics, left a resting pointer's tip to show over the open menu.
- A meter's and a progress bar's blocks stand on whole pixels: a fill ending part way into a pixel drew a soft line
  along its end.

## 0.4.0

- Needs ui_core 0.5.1.
- Under the app's shell or a toaster, a heading and the text after it are read as two nodes again, the heading as a header; ui_core
  0.5.0's keyboard shortcuts over the whole app merged them into one.
- While a page covers the shell's window list, a toast stands one line over the screen's foot, and over the list
  again as the page goes.
- Renames `termStroke` to `termStrokeWidth`: it differed from the `TermStroke` enum by case alone.
  `dart fix --apply` moves your code.
- Renames `TermCombobox.errorText` and `TermTagInput.errorText`, the words a failed search shows, to
  `searchFailedText`: a field's `errorText` is its error, as `InputDecoration`'s is. `dart fix --apply` moves your code.
- `TermDialog`, `TermSheet` and `TermConfirmDialog` lay their keys out with ui_core's `RawActionBar`: in one row
  while they fit, else stacked in one column of one width, the confirming key on top.
- A `TermButton` given more width than its words stands them in the middle, between its brackets; given less,
  its words wrap onto more lines and its brackets grow with them, as a Material button's label wraps, so an action
  is never cut short.
- `TermCombobox` and `TermTagInput` say on their input whether their list is expanded.
- `TermTagInput`'s help is read on its words' node, with tags or none, as a text field's is; it was drawn in
  its frame and read nowhere.
- `TermSelect` opens with the focus on its chosen option (none chosen: its first), and `TermDatePicker` and `TermDateRangePicker` on the
  chosen day, from the first frame.
- `TermDatePicker` and `TermDateRangePicker` ask for their whole month (`RawPopoverFit.whole`).
- `TermToaster` keeps one line between its toasts and the screen's foot, as at its top; the app's shell keeps them
  clear of its tab bar.
- A title cut into a pane's or a field's border that runs past its line ends in an ellipsis by its drawn width
  too (a script the face lacks, set in a wider fallback), never cut mid-letter, and is read whole.
- In a right-to-left app `TermDatePicker`'s and `TermDateRangePicker`'s value stands at the field's start, as every
  field's value does; it stood at the end, beside the `▾`.
- `TermAvatarGroup`'s count of the rest is isolated, so a right-to-left app shows `+3`, not `3+`.
- `TermNavigationBar` shares a phone's width in equal cells, as Material's `NavigationBar` does, so its names stand
  evenly along the line whatever their lengths, each still starting on the character grid.
- `TermDataTable` keeps a column as wide as its heading and, if it sorts, its arrow, as Material's `DataTable`
  does, so a sorted column's `↑` or `↓` is never cut off; over numbers the arrow stands before the heading, so its
  words still end over their numbers.
- A field paints its error state from `invalid`, so a field marked invalid with no error words shows it too.
- At twice the text on a phone nothing runs past its line:
  - `TermMeter`'s bar takes the whole cells its line leaves;
  - `TermRating` grows with the text only as far as its width holds;
  - `TermAvatarGroup` shows as many avatars as fit and counts the rest;
  - a `TermTextField`'s `prefixText` and `suffixText`, and `TermNumberField`'s unit, stay whole while they fit
    the line, the words typed having the rest, as Material's `InputDecorator` lays them out; when the add-ons
    alone run past the line, the longer is cut with an ellipsis rather than painted over the other, and keeps its
    first two letters;
  - `TermDataTable` scrolls sideways when its columns don't fit, as `TermTable` does, each column then as wide as
    its widest words, as Material's `DataTable` is; a cell longer than a width you give ends in an ellipsis;
  - `TermNavigationRail` scrolls when its destinations don't fit its height.
- terminal_parts: `TermTypeAhead.initial` goes. Give the row that should hold the keys `autofocus: true`; it takes
  the focus as the list mounts.

## 0.3.1

- Needs ui_core 0.4.1.
- `TermMenuBar` and `TermContextMenu` draw an entry marked `isDestructiveAction` in the danger ink.
- A raised pane (the command palette, a dialog, a sheet, an open list) stands on its ground out to its frame's outer
  line, no longer on a wider slab over the lines and words beside it. Words in its border blank what is under them,
  their cells past the line in the page's ground.
- `TermFramePainter.fill` covers the frame's inside out to its outer line and the cells of its border words; with
  `wordGround`, the words' cells past the line take that ground instead. `shadow` falls from the line.
- An open select or combobox keeps its field's frame or brackets on the list's ground.
- A focused text field's cursor blinks between a solid and a hollow block, so it always shows; under Reduce Motion it
  holds solid.
- `TermConfirmDialog` focuses its no as the default; its yes is an ordinary key, in the danger ink when it destroys.
  The question names its keys once, in `[y/N]`.
- Deprecates `TermLocalizations.confirmKeysHint`, which `TermConfirmDialog` no longer shows.
- A dialog's or a sheet's keys stand in one row when they fit, else one to a line at its end, as Material's
  `AlertDialog` stacks them.
- Adds `TermListTile.action`, a control after the row's end; the chosen row's bar runs under it.
- `TermLineChart`, `TermAreaChart` and `TermSparkline` read from the right in a right-to-left locale.
- `TermDatePicker` and `TermDateRangePicker` open their calendar above a field low on a phone when the month doesn't
  fit below, and scroll it when neither side holds it; it ran off the screen's foot.
- `TermSelect`'s list and the menus open above their field or button when the room under it is short of what they
  want; they kept to a sliver under it, as the look's own height cap hid their full height from the side choice.

## 0.3.0

- Stands on ui_core 0.4.0, on Flutter 3.47 or later as before. The ui_core
  types terminal_ui's API names take their new names: `DesignSplitAction`
  is `RawSplitAction`, `DesignOverlayInfo` is `RawPopoverInfo`,
  `DesignLocalizations` is `RawWidgetsLocalizations`, and so on.
  `dart fix --apply` moves your code.
- Radios of one choice stand in Flutter's `RadioGroup`, with ui_core's
  `RadioGroupKeyboardFix` round them, in place of ui_core's
  `DesignRadioGroup` (deprecated). Tab stops once, on the chosen radio (on
  the first that can be chosen while none is, or while the chosen one is
  turned off), and the arrows move and choose, Left and Right swapped right
  to left. A `TermRadio` in a group takes its `value` and `label`;
  `enabled: false` turns it off. One given `groupValue` or `onChanged`
  holds its choice itself, a Tab stop of its own, as before:

  ```dart
  // Before
  DesignRadioGroup<String>(
    options: const ['staging', 'production'],
    value: environment,
    onChanged: (value) => setState(() => environment = value),
    itemBuilder: (context, value, node, select) => TermRadio<String>(
      value: value,
      groupValue: environment,
      label: value,
      focusNode: node,
      onChanged: select == null ? null : (_) => select(),
    ),
  )

  // After
  RadioGroup<String>(
    groupValue: environment,
    onChanged: (value) => setState(() => environment = value),
    child: RadioGroupKeyboardFix<String>(
      child: Column(
        children: const [
          TermRadio<String>(value: 'staging', label: 'staging'),
          TermRadio<String>(value: 'production', label: 'production'),
        ],
      ),
    ),
  )
  ```
- A one-choice `TermToggleGroup` that can't be emptied (a segmented
  control) stands on `RadioGroup` too; Home and End still choose the first
  and the last segment.
- A radio is Flutter's `RawRadio` underneath, drawn as before. Its cursor
  shows for the keys only, as every other part's does.
- `TermTooltip` stands on Flutter's `RawTooltip`, drawn and moving as
  before: it opens half a second after the pointer arrives, on focus, and
  on a long press. A screen reader hears its message as the control's
  tooltip. Moving from one tooltip straight to the next now waits the half
  second again, as Flutter's `Tooltip` does.
- A `TermIconButton` given `selected`, and a password field's show and
  hide, read to a screen reader as a button that is selected or not, as
  `IconButton(isSelected:)` does, no longer as a switch.

## 0.2.5

- A text field's focus is its caret and its frame's one line, heavy in the
  accent (twice its stroke, as Material's outline goes from 1 to 2 px): the
  line no longer doubles round it. The same for a select, a tag input and a
  one-time code's cells. A doubled line is a pane's, for the pane the keys
  are in.
- A checkbox with an error prints a `✗` in the danger ink after its words,
  and keeps it when disabled (its brackets and words dim), so a locked box
  still says what is wrong with it.
- The pointer has a mark of its own, lighter than the keyboard's cursor and
  in ink alone: under it a button's, a glyph button's, a chip's, a
  checkbox's, a radio's and a switch's brackets take the accent (a filled
  button's, the words' ink), a slider's block takes the accent, and so do a
  tab's words. In a menu, the row the pointer moves to shows its words in
  the accent, and the first key puts the cursor on it.
- Radios of one choice are one Tab stop: Tab lands on the chosen radio (the
  first that can be chosen when none is), the arrows move and choose, round
  the ends and past one turned off, and a second Tab leaves. Group sibling
  `TermRadio`s with ui_core's `DesignRadioGroup` at the owner of their
  choice; each radio keeps the `focusNode` you give it.
- A one-choice `TermToggleGroup` that can't be emptied (a segmented control)
  is a group of radios too: the arrow keys always choose the segment they
  move to, all four of them, and Home and End choose the first and the last.
  `selectFollowsFocus: false` no longer keeps the arrows from choosing
  there. A toggle group whose choice can be emptied, or that takes several,
  works as before.
- Stands on ui_core 0.3.4.

## 0.2.4

- Charts write their figures in the reader's digits and separators, as the
  number field writes its value: a bar's value, a line or area chart's
  scale and readout, the points a screen reader hears, and a sparkline's
  reading (Arabic's `٢٫٥`, German's `2,5`). A figure of 1000 or more is
  grouped as the number field groups it (`1,482`).
- `TermGrid.widthOf` counts Arabic's letter mark (U+061C) as no cell, as it
  counts the other direction marks.

## 0.2.3

- A pressed tab tints its whole cell and leaves its words whole, as a pressed
  segment does, in place of a half fill rising from the foot across them.
- Terminal speaks Arabic and German as well as English. The words its parts
  say and write themselves now come from `TermLocalizations`, and follow
  the app's locale with nothing to set up: the pager, the page dots, the
  path, the steps, a tag's remove button, a table's page box, a file
  field's `browse`, a confirmation's question, its typed word and its keys,
  a sheet's `esc cancel`, the command palette's keys, a password field's
  `show` and `hide`, a refresh's words, a sparkline's reading and the
  colour picker's 16 names. The English defaults of words an app can pass
  (a dialog's `no`, a sheet's `cancel`, a search's `no match`,
  `searching`, `search failed` and `try again`, the command palette's
  title, hint and empty words, a skeleton's `loading`, a one-time code's
  name, a file field's `no file chosen`, a sheet's `esc close`) follow the
  locale too, unless the app gives its own. `TermLocalizations.delegate`, `forLocale` and
  `supportedLocales` are new. An app that implements `TermLocalizations`
  directly, rather than extending `DefaultTermLocalizations` as its docs
  say, implements the new words.

## 0.2.2

- Dates, times and the number field write their figures in the reader's
  digits (Arabic's Arabic-Indic ones), and the time field reads either
  those or ASCII ones. The date fields' hints, the time field's help line
  and the calendar's month arrows take ui_core's words for the reader's
  language; the time field's help and its error show the times it takes,
  `00:00–23:59`, instead of English words.
- The number field is one keyboard stop, as a spin button is: Up and Down
  step it, Home and End take it to its ends, and its `[-]` and `[+]` keys
  are the pointer's. A screen reader hears its name, its value and the
  values a step gives, in place of two keys named in English.
- A toggle group measures its choices' words as they are set before it
  puts them on one line, so words in a face other than the grid's (a
  script JetBrains Mono lacks) wrap instead of running past the line.
- Keyboard focus is now the cursor: an accent block over the focused
  part, its words and edge glyphs cut out of it, as a terminal shows a
  selection. It replaces the doubled brackets and focus rings on buttons,
  chips, toggles, tabs, checkboxes, radios, switches, sliders, ratings,
  rows, menus, links, crumbs, pages, calendar days and colour swatches.
  A chosen or filled part goes hollow, so chosen, pressed and focused
  read apart without colour. A checkbox, radio or switch puts its label
  under the cursor too, and a slider its whole rail. A select or date
  field also puts its value line under the cursor. A colour area takes it
  round its edge, and a line chart on its scale column. Text fields keep
  their doubled frame and caret. Focus shows only for the keyboard; a
  click never leaves it. The cursor glides in, and under Reduce Motion it
  (and a field's or pane's doubled frame) stands at once, with no fade. Against the part at rest, it changes at least a
  2 px line's area at 3:1 on every theme, night and paper, monochrome
  included. Page dots now show focus and a press.
- A calendar's days and weekdays grow with the system text size up to
  twice their size, as Material's calendar's do, so every day reads whole
  at 300%. A one-time code grows up to twice its size or the width it is
  given, whichever is smaller, so all its cells show on a phone. A bar
  chart's names and values grow up to 1.3 times their size, so its values
  stay on screen.

## 0.2.1

- Navigation destinations keep their names at large text sizes. Calendar
  highlights stay within their day columns, and date-range fields show both
  dates even when they need separate lines.
- Phone confirmation sheets start with the warning visible. Disabled
  filled buttons have readable labels on both the night and paper palettes.
- A typed confirmation's field stays whole beside the buttons while a long
  warning scrolls, and a dialog or sheet whose body is cut shows an arrow
  for the hidden part. Buttons stacked on a narrow sheet no longer leave a
  blank line between them.
- Slipway opens the run selected in the overview. At large text sizes the
  desk switches to a list with detail navigation when its panes no longer fit.
  The package title stays on one line on a phone.
- Deployment commands open the requested environment. The form requires a
  branch or commit, confirms production deployments, and discards edits on
  Cancel. Queued runs can be opened from the notification. Canceling an
  active run updates its status, steps, log and history.
- Progress bars leave room for the percentage, and toggle groups wrap
  their choices on narrow screens. Long confirmation titles wrap inside the dialog.
- Deleting a Slipway project removes it from Home, deployment targets and
  the run history, including its active run and logs.
- Requires `ui_core` 0.3.1.

## 0.2.0

Built on `ui_core` 0.3.0. Terminal's dialogs and sheets, tab bar, shell,
tooltip, rating and line and area charts take their behaviour from
`ui_core` (focus, keys, semantics, gestures) and keep Terminal's paint and
motion: they look as they did, and they do more. The constructors are
unchanged; the breaks below touch only code that told a dialog by its
route's type or held a tab bar's state.

### Breaking

- `showTermDialog`, `showTermSheet`, `showTermConfirmDialog` and
  `showTermActionSheet` push `ui_core`'s `DesignDialogRoute`, no longer
  Flutter's `RawDialogRoute`; the side sheet runs on a spring
  (`TermMotion.surface`, which keeps the 120 ms fade), as `ui_core` 0.3.0
  removed `DesignSideSheetRoute.transitionDuration`.
- `TermTabBar` is a `StatefulWidget` (it owns a `DesignTabController`),
  no longer a `StatelessWidget`. Its constructor is unchanged.

### Behaviour that changes

- A dialog or a sheet keeps Tab inside and gives the focus back to what
  opened it; Escape, Android's back and a tap outside close it through any
  `PopScope` in it. The y/N question is an alert to a screen reader.
- `TermTabBar` is one stop for Tab, on the current tab: the arrows move
  and choose (mirrored right to left), Home and End go to the ends, and a
  screen reader hears a tab and its place ("log, Tab 2 of 3").
- `TermScaffold`'s places (the window list, the rail, the side pane) are
  one stop, the arrows moving along them and Enter or Space going there;
  F6 moves between them and the page; a screen reader hears each place as
  a tab and the side pane as the navigation menu.
- `TermTooltip` shows on hover, on keyboard focus and after a long press;
  the pointer may rest on the tip, Escape hides it, one shows at a time.
- `TermRating` takes a drag across the marks and the digits (End all, Home
  none), with a step's haptic; a tap left of the first mark still gives
  none.
- `TermLineChart` and `TermAreaChart` are a stop: a pointer, a finger or
  the arrows pick a point (its column shaded, its value over the plot); a
  screen reader hears the data in a sentence, in the app's language, or
  the point picked, and steps through the points. A change of data springs.
- A key drawn by `TermKey.of` (`^K`) is heard in the reader's words
  ("Ctrl+K").
- A menu the pointer opened keeps the focus on itself (`ui_core` 0.3.0):
  the first Down shows the first row, as before, and Return or Space
  chooses nothing; Return no longer shows the first row.
- In `TermSplitButton`'s, `TermMenuBar`'s and `TermContextMenu`'s menus
  (`ui_core`'s rows) the pointer leaving the menu lights no row, and the
  next Down starts at the first. `TermMenu` keeps the last row the pointer
  was on, as before.

### Fixed

- `TermCombobox`'s list goes over a field with too little room under it
  (less than six lines, and more over it), as `TermSelect`'s does; at the
  foot of a screen it was held to the sliver under the field, its words
  cut off. `TermTagInput`'s still opens under.
- The caret of `TermTextField` (and every field on it) is the look's own
  block, on the cell after the words on every platform, behind the
  character it is on. On iOS and macOS it stood two pixels before its
  cell, over the last character's edge.
- Right to left, the words typed start on the cell the label and the hint
  do; they stood a cell inside (the room Flutter keeps for its caret). A
  line of words now runs to the frame's last cell, the caret past it.
- The keys' block on a chosen tab, window, rail item or menu row is in the
  ground's colour, cut out of the inverse cell; in the accent it was all
  but lost there (1.3:1 by night).
- Right to left, `TermBanner`'s title stands first, by its glyph, when the
  title and the message are in Latin letters.
- `TermNavigationBar`'s names stand on the character grid: the room left
  over is shared in whole cells.
- A double frame's sides are whole pixels, as its top and bottom are (a
  focused field, a dialog, a list's pane): they were astride two, at half
  strength.

### New, from ui_core 0.3.0

- `TermContextMenu`: a menu over a region, opened at the pointer by a
  right click or a long press, at the focus by Shift+F10 or the Menu key;
  its rows are `TermMenuBar`'s.
- `TermCombobox` and `TermTagInput` take `search` (looked up, async) and
  `debounceDuration`; while a search runs the list says `loadingText` by
  the spinner, and when it fails, `errorText` over a `retryText` row.
- `showTermDialog` and `showTermSheet` take `isAlert` and `semanticLabel`.
- `TermMotion.surface`, the spring a dialog, a sheet and a side sheet come
  up on.

The package page links to the live gallery, the API reference and the
source, and includes desktop and phone screenshots of Slipway.

## 0.1.1

- On iOS, Reduce Motion stills the look as Android's Remove animations and a
  browser's reduced motion do: a spring settles without overshoot, the caret
  stands as a steady block, the spinner holds, and a screen, a dialog, a
  sheet, a side sheet and the command palette come up at once. Flutter gives
  iOS's setting apart from `MediaQuery.disableAnimations`, which the look
  read alone; it now reads both, through `ui_core` 0.2.1's
  `designReduceMotionOf`, and follows the setting as it changes.
- What a screen reader hears for an avatar group follows the app's language
  and its plural forms: the words come from
  `TermLocalizations.avatarGroupLabel`, English by default ("1 person: …",
  "2 people: …"), and an app extends `DefaultTermLocalizations`, with a
  delegate, to word every form its language has. It said "1 people".
- The package's tests come in three tiers. `flutter test --exclude-tags
  goldens,sweep` is the one to run on every change: each matrix of widths,
  themes, directions and text sizes runs one case per screen or part in
  turn, so every width, both themes, right to left and twice the text are
  still met. `--tags sweep` runs the rest of those matrices, and
  `--tags goldens` the pictures (recorded on macOS), before a release.

## 0.1.0

- First release: 84 of `ui_core`'s 89 inventory components (actions,
  fields, pickers, choices and ranges, rows and collections, navigation,
  overlays, states and charts), drawn on one character grid, on
  `ui_core`'s behaviours; `termInventory` and `TermInventoryGallery`.
- `style:` on every part over its slot in `TermThemeData` (one a part, one a
  kind of button); a style sets colour and weight, never a size.
- `TermThemeData.from(palette, accentSlot:, accent:)` holds the accent to
  4.5:1 (`termReadable` pulls a colour until it does); `TermFace`,
  `TermStroke`, `AnimatedTermTheme`; the painters and faces public.
- `TermThemeData` with night, paper and monochrome presets, `copyWith`,
  `lerp` and value equality; `TermTheme` as an `InheritedTheme`.
- Tap floors on the lattice: one line under a pointer, two under a finger.
- Open lists by the keys: a select comes up on its chosen item, the arrows
  wrap, Home and End go to the ends, a typed letter jumps to the next item
  it starts, Return chooses and Escape gives the keys back to the field;
  menus walk the same way. The chosen item is the inverse bar; the pointer
  marks an item's words with the accent, and the keys add a block at its
  start (`TermListTile.option`). A combobox's and a tag input's list
  takes `ui_core`'s keys, and `isOptionEnabled` passes an option over.
- An open menu (`TermMenu`, `TermSplitButton`'s, `TermMenuBar`'s) has one
  current row, the keys': the pointer moving onto a row takes it there.
  Opened by the pointer it lights no row until the pointer or a key moves
  (the first Down shows the first row, Return chooses nothing unseen);
  opened by the keys it lights the first.
- A select's open list and a date field's calendar do the same: opened by
  the pointer, only the chosen row's bar or day reads current until a key
  (with nothing chosen, no row; the first Down shows the first). A date
  field's calendar opens with the keys on its chosen day, not on the
  month's arrow. A field's list (a select's, a combobox's, a tag input's)
  stands a cell inside its frame each side, as a menu does, its words a
  cell in from the field's.
- A press on a select or a date field focuses it, as a select does, so
  its list or calendar, closed by Escape or a choice, gives the focus back
  to the field (Return opens it again).
- A long select's or menu's list shows the row with the focus: the chosen
  one as it opens, the keys' row as it moves (past the end and round, or
  by a letter), scrolled no further than it takes.
- Right to left: a glyph button draws its glyph as given (a `>` stays
  `>`); a field whose words run their own way (code, a path) lays its
  prompt out that way too; the title line's steps read in order.
- `TermPageRoute` and `TermPageTransitionsBuilder`: screens change in a cut
  or a 120 ms fade in place; menus, dialogs and toasts come up where they
  stay. `TermTheme` sets it on `material_ui`'s theme;
  `termPageTransitions`, the same map, gives it to Flutter's own
  `MaterialPageRoute` through an app's `ThemeData`. Its iOS entry is
  `ui_core`'s `DesignSwipeBackPageTransitionsBuilder` round Terminal's
  change: a swipe from the screen's leading edge takes a page back.
- Return in a field that keeps the focus (a combobox's, a tag input's, the
  palette's search) keeps its input, so typing goes on in a browser too:
  they take it in `onEditingComplete`, which `TermTextField` now passes
  to Flutter's field, with no `onSubmitted`.
- `TermTimeField` holds a `TermTime` (an hour on a 24-hour clock and a
  minute, `copyWith` and value equality): no Material type in the API.
- Keys are written where a keyboard reaches the app and left out under
  touch (`termKeysShown`, from `DesignTapTargets`' input): a `TermKey`, a
  button's keys, a menu row's, the status line's and the rail's, and the
  keys in a palette's, dialog's, sheet's and toast's bottom line.
- JetBrains Mono and Liberation Mono bundled (SIL OFL 1.1).

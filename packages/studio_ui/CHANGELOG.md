## 0.2.1

- Needs ui_core 0.4.1.
- A field on a route of a navigator in `StudioScaffold`'s body keeps its focus on the web when a list opens over it;
  on a phone a combobox took a second tap.
- By night, glass set into the metal (a display's pane, a field's window) reflects the room under its top lip and
  lights the wall inside its lower lip, so it reads as recessed.
- A disabled key, lit key, icon or transport key, checkbox, radio, segment, stepper key or chip sits flush with the
  panel: its lift and shadow fade with its legend.
- An open list (`StudioSelect`, `StudioCombobox`, a menu, `StudioCommandPalette`, a date picker's calendar) stands
  in a 2 px metal rim; `StudioListBezel` takes 2 px more on each side for it. By night the rim is the caps' lit
  aluminium, at least 3:1 from the glass inside and under it, so a list over a field reads as a plate above it. A
  combobox's or tag input's list stands as clear of its field as a select's, above or below it; it hung flush.
- `StudioCombobox` opened by a pointer marks its value as `StudioSelect` does, and lights a row only after a key or
  a pointer move.
- A calendar's today keeps its lamp lit when it is also the chosen day; it went out.

## 0.2.0

- Needs ui_core 0.4.0 and Flutter 3.47. `studio_ui` re-exports ui_core, whose types now take `Raw` names (`DesignPressable` is `RawButton`). The old names stay through ui_core 0.4 as deprecated typedefs, and `dart fix --apply` renames them.
- `StudioRadioGroup` and `StudioSegmentedButton` are Flutter's `RadioGroup`, each radio a `RawRadio`, with ui_core's `RadioGroupKeyboardFix` inside. They answer Tab, the arrows, Home and End as before. A radio shows its focus as Flutter's `Radio` does.
- `StudioTooltip` is Flutter's `RawTooltip`, with ui_core's `RawTooltipFocusFix` and `RawTooltipPlacement`. It fades on Flutter's tooltip timing, and each tooltip along a row of keys waits its half second.
- The record key reads as a button, selected while it records, as `IconButton(isSelected:)` does. It read as a switch.

## 0.1.5

- Keyboard focus and hover brighten existing lamps, fader marks and tab indicators. Text fields and displays light their inner lip. A menu command lights its legend on focus and depresses while held.
- A focused part whose lamp is already lit shows focus on its edge, since a brighter lamp would barely show: by day a latched key, checked checkbox, chosen radio or selected navigation item brightens its amber rim to full strength, and by day and night a chosen radio, an on switch's cap, a lit key, a playing or recording transport key and a destructive key (its red legend already lit) light their rim the same way. A focused chip lights its rim too, selected or not, and leaves its lamp to show only whether it is selected.
- Stands on ui_core 0.3.4 and uses ui_core_test 0.1.4 for qualification. `StudioRadioGroup` is built on ui_core's `DesignRadioGroup`, over Flutter's `RadioGroup`. Tab enters at the checked option, or at the first option that can be chosen when the checked one is turned off or nothing is chosen. A turned-off option that is chosen still reads as checked. The arrows, Home and End choose as before.
- `StudioSegmentedButton` reads as a group of radios, the latched key checked. Tab reaches the bank once, at its latched key, where each key was a Tab stop before. The arrows latch the next or the previous key and wrap at the ends; Home and End still latch the first and the last.
- A selectable `StudioDataTable` row reads as a checkbox, checked when selected, from ui_core 0.3.4's `DesignDataTable`. It read as a button as well.

## 0.1.4

- Bar, line and area charts draw Arabic day names and axis digits with the bundled Noto Sans Arabic face. The charts measure labels in the reader’s locale and repaint when additional script fonts arrive.
- Requires ui_core 0.3.3 and uses ui_core_test 0.1.3 for qualification.

## 0.1.3

- A time drum reads hours then minutes, left to right, in a right-to-left language too, as a clock does and Material's time picker keeps it: in Arabic the hours stood on the right of the minutes before. Tab reaches the hours first and the arrows follow what is on screen.
- A screen reader names a time drum's drums in the reader's language, from ui_core's words: "Stunde" and "Minute" in German, "ساعة" and "دقيقة" in Arabic, after the picker's own name when it has one. They said "hours" and "minutes" in English in every language before, and an unnamed picker called itself "Time".
- `StudioRadioGroup`: radios and their words, one choice, the whole row a radio's target. Tab reaches the group once, at its choice, and the next Tab leaves it; the arrows choose the next or the previous and wrap (mirrored right to left in a row), Home and End its ends, as Flutter's `RadioGroup` does. A screen reader hears a radio group of radios, in a `StudioFormField` too, whose label names the group while each radio keeps its own node. The gallery's radios are one.
- A radio, a checkbox and a check row read as Flutter's do: a checkable (in a mutually exclusive group, for a radio), not a button as well.
- A `StudioListTile`'s `trailingText` takes its own width, up to under half the row, and the title the rest: before, the value's slot took half the row's room however short it was, so a title wrapped early beside a date. A long value still ends in an ellipsis.
- A chart's scale steps by round figures, on ui_core's scale (1, 2 or 5 times a power of ten, the top rounded up): a five-hour week reads 0, 1, 2, 3, 4, 5, where it read 0, 1.3, 2.5, 3.8, 5 (always four steps to a rounded top).
- A chart's labels thin evenly when they crowd: every other one, or every third..., by their own widths, no two closer than a word's space (a week at 200% keeps Mon, Wed, Fri, Sun, where it kept Mon, Wed, Fri and Sat with Fri and Sat touching). The scale's figures thin the same way, from 0 up. Where there is room for only two, they are the first and the last: Mon and Sun, and the scale's 0 and its top.
- A `StudioFormField` left to choose (`mergeSemantics` null) reads its child by what it brings to the semantics tree, on ui_core 0.3.2's `DesignField`, where it went by the child's type: one control is one node named by the label, and any group keeps each control's own node and tap. A group that names itself, a segmented button named as its field, is read once, where it read the field's label twice.

## 0.1.2

- A stepper's keys stand as tall as its readout at every text size (44 px keys beside a 48 px readout at 200% before), both growing with the figures, and the readout keeps the row's height in a taller box instead of stretching to fill it.
- Every part shows keyboard focus as lit studio gear does: its own edge lights amber, 3 px hugging its outline with no gap, and a soft amber glow spills round it, in place of a ring drawn apart from it. Keys in a bank (a selector, a toolbar, the key bank) light just inside their own edge; a tab lights round its words; the graphite key's light is deepened by day to read over its shadow. `StudioMetrics.focusWidth` is the lit edge's width (3); `focusGap` is deprecated. `paintStudioFocusLight` paints the same light for a part that paints its own face. A text field's window lights the same edge while it has the typing, however it got it, as well as its rim.
- A date field's calendar matches its field's width up to a month's comfortable width (seven days at a key's widest slot, about 390 px); under a wider field it keeps that width from the field's leading edge.
- A select and a combobox show one indicator at their end: Studio's pair of wedges, up and down.
- A select grows with the reader's text size, as a text field does, so its words are never cut at 200%.
- On a wide screen the app's name at the head of the side panel sits on the line of the page title beside it, in a band as tall as the app bar, and the panel's keys start under that band.
- By day a readout is pale glass lit amber from behind, as a backlit LCD is, under dark figures; by night it stays dark glass under glowing figures. `StudioColors.litReadout`, `readoutLit`, `readoutDim` and `readoutGlow` give a custom readout the same light. A brand's figures are kept at 4.5:1 on the glass in both rooms, and its dim trace at 3:1.
- A dialog's actions stand in one row while their labels fit. When they do not, they stack full width at one height, the main action first and a quiet Cancel last, instead of falling into uneven rows at the trailing edge.
- The figures a part sets itself are in the reader's digits and separators (Arabic-Indic in Arabic; a chart's scale reads 1,500 in English), as a calendar's heading is: a calendar's days, a time drum's hours and minutes, a stepper's count, a badge's count, a pager's figures, a file's upload percentage, and a chart's scale and ring total. A stepper's `format` still sets its own words.
- `StudioCheckRow`: a checkbox and its words as one target and one spoken control, with an optional note under the words.
- A form field holding a group of controls (a row, column or wrap of them, a segmented choice, a stepper, a toggle bank, a range fader, a tag input, a time picker's drums) keeps each control's own node and tap, and its label names the group. Before, with semantics on (a screen reader, or a browser that turned them on), a tap on any of them went to the first. `StudioFormField.mergeSemantics` is now null by default and decides by the child; true and false still force it.

## 0.1.1

- Recorder transport and confirmation buttons show the entire destructive action at large text sizes.
- Segmented filters and zoom keys follow the system text size. File-tree rows and date fields grow to show long labels and dates, including the year.
- Count badges reserve space for their digits and surrounding icons. Disabled buttons have stronger daylight contrast.
- Line, bar and area chart axes follow the system text size and skip tick labels that would overlap. The fader light follows the inner curve of its slot.
- Tag chips and banner actions sit evenly inside their curved frames. Selected navigation and filter keys keep an even inset as their legends depress. Use `AnimatedStudioSurface.inBank` for a custom key mounted in a recess.
- Date and date-range fields respond to hover and press. Their calendar opens on the side with room for a whole month and scrolls when neither side has enough, so large text never cuts off its last week.
- A date field's calendar is as wide as the field and lines up with both its edges; under a field narrower than a month it keeps a month's width from the field's leading edge. It sits in one frame, and its days keep a key's proportions when the month spreads wide.
- The chosen day, and a range's first and last days, are lit in their slot: by day a pale amber slot under a dark figure, by night an amber figure in dark glass. Days inside a range keep a legible figure by day.
- A focused checkbox, date field or calendar day lights its own edge in amber with a soft glow, in place of a ring drawn around it.
- Roomtone's overview uses a smooth surface behind its introduction.
- Roomtone exports its full-length reference take as MP3 or stereo WAV, with the selected bitrate and optional chapter markers. Share copies a link that opens the episode.
- Roomtone's player advances at the selected speed. Selecting a chapter seeks to its start, and each episode has its own chapters. Scheduled episodes show their date and time. Signing out hides the listener’s account, drafts and library.
- The example gallery keeps the punctuation of its English descriptions in right-to-left layouts.

## 0.1.0

- First release. The theme (a bright room and low light, three densities, a brand factory for the indicator and the
  finish), the material (`StudioSurface` and its three depths under one light from the top, the cached brushed grain,
  `StudioLamp`, `StudioReadout`, `StudioGroove`, `StudioLegend`) and the everyday parts: `StudioButton` (plain, `.lit`
  and `.text`), `StudioIconButton`, `StudioTransportKey`, `StudioTextField`, `StudioSelect`, `StudioCheckbox`,
  `StudioRadio`, `StudioSwitch`, `StudioSegmentedButton`, `StudioFader`, `StudioKnob`, `StudioMeter`, `StudioListGroup`,
  `StudioListTile`, `StudioSectionHeader`, `StudioPanel`, `StudioDisplay`, `StudioAppBar`, `StudioTabBar`,
  `StudioNavigationBar`, `StudioNavigationRail`, `StudioSideNavigation`, `StudioScaffold`, `StudioDialog`,
  `showStudioBottomSheet` and `StudioToaster`.
- The app frame: `StudioHost` (the theme, the toaster and the chassis above the navigator), `StudioScreen` (a page's
  brushed panel, margins, column, bar, footer and keyboard), `StudioPage` and `StudioSheetPage`, `StudioAppShell` with
  `StudioTab`s and a `StudioShellAction` (the graphite floating key), `StudioLoadingState`, `StudioErrorState`,
  `StudioInput` and `StudioPreview`. `StudioAppBar.autoLeading` gives a pushed page its back key and a sheet its close.
- `studioPageTransitions`: Studio's page change for an app's own `ThemeData`, iOS's swipe back kept round it.
- Buttons take their words first, as Flutter's text does: `StudioButton('Publish', onPressed: publish)`.
- Tokens beside `StudioSpacing`: `StudioIconSizes` (glyph sizes), `StudioMetrics.tablet` and `.desk` (where a phone's
  key bank turns a rail, and a rail the side panel), and `StudioMetrics.lip`, `.lampDrop` and `.smallAvatar` (the
  optical values, each with why).
- Every control a finger reaches is at least 44 by 44 under it (a day in the calendar, a tree's row, a menu bar's
  titles, a tag's cross), as `DesignTapTargets` declares. `StudioFormField(mergeSemantics: false)` names a group (a
  segmented choice, radios) instead of joining one control.
- Counts are plurals: `StudioLocalizations` (with `DefaultStudioLocalizations`, English, and its `delegate`) words a
  table's rows ("1 row", "2 rows"); its chosen rows use ui_core's `selectedRowCountTitle`, and a rating's value its
  `positionLabel`. An app in another language extends it with its plural forms.
- Reading is on glass: `StudioDisplay` pads 16 when given no padding (a pane of rows passes its own), and the banner,
  the file drop and the status view's well are glass.
- By day an unlit lamp is pale smoked glass, never a dark dot beside a lit one; by night its bezel, and an unlit
  star's edge, catch the light at 3:1 on the metal (`StudioColors.lampEdge`), so either still reads as a lamp. An
  unchecked checkbox's cap is blank.
- A side sheet's title and close key stand on its body's keylines, and a `StudioAppBar`'s `bottom` (its tabs) in the
  bar's content column, under the title and the actions.
- `StudioPreview` stands its app in a semantics container of its own, so a screen reader still reaches what the page
  holding it painted first.
- Large text and narrow columns: a segment's or a key bank's legend, and a data table's head, is set smaller rather
  than cut; a table's figure stays on one line at its column's end; a readout's figures run left to right in every
  language.
- A file's row takes a glyph by its kind (audio, image, video, text).
- One light from the top: a recess is shaded under its top lip, and a pane of glass sits deeper than a slot. By day
  a latched key is backlit (`StudioFace.backlitIf`); by night the grain is finer and the lit key's edge catches the
  light.
- `StudioStatusView` is a pane of glass, its glyph lit in a readout window; `StudioTag` is a small backlit legend
  window; a disabled field is unlit glass; `StudioFileDrop(multiple: false)` lets one file take the tray's place.
- The desk's side panel is the rack's key column: its places are keys set in a recess, the chosen one latched in and
  lit. A list row's chosen lamp stands at its end.
- By day a latched cap is backlit with a lit rim; by night the main key is the palest graphite cap on the bar.
- `StudioScrollArea` shows its slot whenever there is more to scroll, and its frame no longer shades the glass (a
  clear face casts nothing). A line chart's plot is inset so its first and last labels clear the scale and the
  glass's edge. A readout's unit stands a thin space from its figure.
- By day a latched cap keeps its tone and shows its light as a lit rim and glow; day glass is its own material, pale with a faint green-grey tint, a shade under the metal. A
  meter's clipping zone shows dark red while unlit; a swiped row slides whole as glass; the avatar's initials are
  sized to the disc; by night a switch's unlit lens is fainter; chart step labels stand clear of the base figure.
- A swipe row's action key stands whole in the metal and is uncovered as the row slides; a disabled field's words are
  in the disabled ink, its hint too.
- Every doc example is compiled and run (test/doc_examples_test.dart, ui_core's template).
- A face set in a well follows the well's inner wall: a swipe row's glass, at rest and as it slides, and the metal it
  uncovers have the corners of the display it stands in (its radius less the recess), so the wall keeps its width
  round the corners, and the key it uncovers stands whole a gap in from the row's edge, either side and right to
  left. A lifted row in a reorderable list and a colour picker's picture are concentric with their wells; a wheel
  or time picker's rows fade into the housing without covering its wall. test/corners_test.dart checks every face,
  fill and clip on every page and screen against the well round it.
- Built on ui_core 0.3.0 (`ui_core: ^0.3.0`): Studio paints, ui_core behaves. `showStudioDialog` runs on its dialog
  route (focus moves in and back, Escape closes it; `isAlert` for a question asked before something is lost: the scrim
  does not close it and a screen reader hears an alert). `showStudioBottomSheet`, `showStudioActionSheet` and
  `StudioSheetPage` run on its sheet route: a drag takes the drawer down with the finger, and the finger slot is a
  handle a press or Down closes. The side sheet runs on Studio's drawer spring. `StudioTabBar`, and `StudioScaffold`'s
  key bank, rail and side panel, are one tab stop each, the arrows moving along them, each place a tab ("Library, Tab
  2 of 3"); F6 moves between the places and the page. The wheel and time pickers (typing jumps to a row), the rating
  (a digit sets it, a drag sweeps across; a press on the last lit lens still takes it back) and the tooltip (on
  keyboard focus at once, on a long press, one at a time) are ui_core's.
- `StudioCombobox` and `StudioTagInput` take `search` (options found as the typing rests, `debounceDuration`) and say
  while they look, and when a search fails, with Try again.
- `StudioKbd.shortcut(SingleActivator(...))` shows a shortcut a cap a key, in the platform's order and the reader's
  words.
- The review checks are ui_core_test's (`ui_core_test: ^0.1.0` in `dev_dependencies`).
- The pub.dev page: the homepage is the live gallery, with the issue tracker, topics and five screenshots, and the
  README opens with Roomtone at 1440 px and 390 px, the links, the install and a quick start that runs.

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

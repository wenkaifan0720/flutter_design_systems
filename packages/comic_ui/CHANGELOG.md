## 0.3.5

- At 300% text a time picker's labels stay whole. Its words grow at most twice with the reader's text, as Material's
  time picker's, and its selects stand in a row only while each label fits its select on one line; else they stack.
  In a desk column "Minute" broke mid-word ("Minut / e").
- A closed select holds its value on one line and ends it with an ellipsis where it outgrows the field, as Material's
  `DropdownMenu`; its name and whole value are still read, and the open menu lists the value whole. At 300% text
  "Thursday" broke mid-word ("Thur / sday"). Where the value used to wrap whole onto a second line (at 200% text on a
  phone, "Standard delivery"), it now ends with an ellipsis, as Material's does.
- A tag input's tag stands on one line and ends with an ellipsis where it outgrows the field, as Material's chips'
  labels. At 300% text in a desk column a long tag overflowed its row.
- The example gallery's side nav grows wider when the reader's text makes a page's name outgrow it, so the names wrap
  only between words. At 300% text "Overview" broke mid-word ("Overvie / w").

## 0.3.4

- At 300% text a date picker's and a calendar's days fit. Their numbers grow at most twice with the reader's text,
  as Material's calendar on a phone: a `ComicDatePicker`'s grid no longer outgrows a phone and scrolls sideways, and
  a `ComicCalendar`'s numbers no longer fill their cells to the rules. The month's name grows at most twice too, as
  Material's calendar header: larger, "November" and "September" broke mid-word between the arrows.
- A wrapped heading's marks no longer cut into the line above. The lettering sets its lines 0.95 of its size apart,
  room enough for its plain capitals, but its accents, rings and Vietnamese tones reach higher. A heading whose
  letters carry them (French, Spanish, Nordic, German, Vietnamese) gets the least leading its own marks need, the
  same between all its lines, in `ComicLetters`, the parts' titles and `ComicLettering`. English keeps its leading.
- `ComicTimePicker` says its hour, minute and half of the day in the app's language: ui_core's
  `DesignLocalizations` words (`timePickerHourLabel`, `timePickerMinuteLabel`, `timeFieldDayPeriodLabel` and the
  AM and PM abbreviations), in its 30 languages. It said them in English in every one. In English the half of the
  day is named "AM/PM". `ComicLocalizations`' `hour`, `minute`, `period`, `am` and `pm` are deprecated, and a
  subclass no longer needs to give them.
- `ComicLocalizations.delegate` supports every locale, as ui_core's does. It supported English alone: a German or
  Arabic app that installed it met Flutter's warning that a delegate leaves out its locale, and the delegate was
  skipped. In another language it loads Comic's English words with the ones ui_core shares (Dismiss, Try again,
  Delete, a rating, the months and weekdays, a time's hour and minute) in that language, and
  `ComicLocalizations.of` does the same where no delegate is installed. `ComicLocalizations.forLocale` gives them.

## 0.3.3

- At large text sizes, three parts keep their words whole. A `ComicWheelPicker` row's words grow with the reader's
  text until their line fills the row (twice their size at the default height), so at 300% the rows no longer
  overlap and the band no longer cuts the chosen value. A `ComicShares` scale's words grow at most 1.3 times, as
  Material's slider label, and wrap only between words. A calendar's weekday initials grow at most twice, as
  Material's calendar, and never touch.

## 0.3.2

- Keyboard focus is Comic's own pop instead of an outline ring: the focused part lifts up and toward the start off a
  hard ink print of its outline, and its words stay on a plain fill. Rows, tabs and segments that stand edge to edge
  show the print inside their outline instead of lifting. A slider's knob grows and lifts off its print. The print's
  ink reaches 3:1 on the ground around it in every preset, by day and by night, and Reduce Motion shows it at once.
  A combobox's or multi-select's list starts on its field as the focus lifts it, its words on the field's.
- `comicEmanataLength`, `comicEmanataWeight`, `comicEmanataGap` and `comicEmanataSpread` are deprecated: Comic no
  longer draws focus emanata.
- `ComicSelectField` takes a `label`, shown above its box in the field-label style, and a `semanticLabel`. A screen
  reader names the select by it and reads the value after the name; the menu still opens from the box.
  `ComicSelect`'s label is its field's spoken name too.

## 0.3.1

- Hover and press give controls a plain ink tint, and a link's words darken under it to stay readable. Disabled
  buttons keep readable lettering on one solid fill.
  Panels, modal backdrops and lettering on illustrated covers keep patterns clear of words.
- Escape clears the inspected chart point even when another control has keyboard focus. Chart figures keep
  English and Arabic counts in reading order. A bar list's figures share one column, so a larger value never
  draws a shorter bar.
- Opening a page with a fixed tab strip keeps its initial scroll position.
- On a phone at twice the text size, the date picker shows all seven weekdays. Segments stack when their
  labels need more room, select values wrap, and bottom navigation leaves space between captions.
- The checkout and delivery examples validate the fields before confirming an order or saving details.
- Gallery buttons that open dialogs and sheets leave room for the keyboard focus outline when they wrap.
- Selected tags and message actions follow the corners of their enclosing field or bar with even spacing.
- Arabic gallery navigation, examples, chart data and dates use Arabic labels. Headings, card and sheet titles,
  menu bar items and action labels use a heavier fallback for Arabic and Hebrew lettering. Carousel cards grow to fit translated text.
- Pressable list tiles include the subtitle in their accessible name. Numeric range captions keep the lower price
  before the upper price in right-to-left layouts.
- In copied components, use `ComicScreened(muteFill: false)` in place of `ComicScreened(dots: false)` to retain
  the original fill colour.

## 0.3.0

Needs ui_core 0.3.0. Comic's parts take their behaviour from ui_core now and keep their print: the same panels, inks
and pops, with ui_core's keys, screen-reader words, focus and springs under them.

Breaking:

- `ComicWindowSizeClass` is gone. `ComicThemeData.window` is ui_core's `DesignWindowSizeClass`, on the same
  Material breakpoints, except that from 1600 wide it is `extraLarge` (Comic's `large` ran from 1200 up).
- `ComicTabBar` calls `onChanged` only when the tab changes. A press on the chosen tab, which called it again with
  the same index, does nothing now: ui_core's `DesignTabBar` reports changes only.

Changes:

- Menus light one row. In a menu bar's or a split button's menu, ui_core 0.3.0 lights the row the pointer moved over
  last or the one the keys moved to, and none in a menu the pointer opened until one of them moves. Comic's own quiet
  menu, which did this before, is gone.
- `ComicTooltip` is ui_core's `DesignTooltip` in Comic's balloon. It still waits 400 ms and stands under its
  control. It now stays while the pointer moves onto it, closes on Escape, shows one at a time, and opens at once along
  a toolbar after the first.
- `ComicKbd.shortcut(activator)` and `ComicKbd.labelOf(context, activator)` take a shortcut's keys from ui_core, in
  the platform's order and the reader's words. Comic spells them in words on a Mac too ("Shift+Command+N"), since its
  typefaces draw none of ⌃ ⌥ ⇧ ⌘.
- `ComicCombobox` takes `search` and `debounceDuration`, and `ComicMultiSelect` takes `debounceDuration`. While an
  app's search is on its way, both say "Loading"; when it fails, they say "Couldn't load results" and offer Try again,
  which the arrow keys reach.
- Dialogs and bottom sheets ride ui_core's routes. They open and close on springs: a dialog still pops in with a
  short bounce, and a sheet stops at its edge. A screen reader hears a dialog, and focus returns where it was. A
  bottom sheet now follows a drag down and a fling puts it away, and a `ComicBottomSheet` hands its scroll over to
  that drag. Under Reduce Motion both still cut, never fade. The router's sheet page on a desktop now pops in as a
  dialog does; before, it faded.
- The command palette keeps its field's focus when Enter runs a command, on the web too.
- A screen reader hears the page around a `ComicPreview`. Its app now stands in a semantics container of its own:
  on material_ui's `MaterialApp`, which puts none round its navigator, the preview's barrier hid what the page
  showed before it.
- `ComicTabBar` is ui_core's `DesignTabBar` in Comic's trough. It has one tab stop, arrows (mirrored right to left),
  Home and End. A screen reader hears "Saved, Tab 2 of 3". The thumb moves on a spring.
- `ComicWheelPicker` is ui_core's `DesignWheelPicker` on Comic's drum. Page Up and Page Down step five, typing jumps
  to a value, a snap springs, and each row that crosses the band ticks.
- `ComicChart` picks, steps and reads its points through ui_core's `DesignChart`. Up and Down move between series,
  Home and End go to the ends, and a screen reader steps point by point.
- The review checks come from `ui_core_test`, a dev dependency.

The pub.dev page opens with a picture of Comic, links to the live gallery, the API reference and the other looks, and a
quick start. The README's Material snippets stand on `material_ui`, Flutter's Material from 3.50, where `ComicTheme`
already gives a pushed `MaterialPageRoute` Comic's cut; the example and the tests import it too.

## 0.2.1

Needs ui_core 0.2.1.

- Reduce Motion on iOS calms Comic too. Flutter puts iOS's Reduce Motion in dart:ui's
  `AccessibilityFeatures.reduceMotion`, not in `MediaQuery.disableAnimationsOf`, which was all Comic read, so on an
  iPhone with Reduce Motion on, Comic's presses, eases and loops still ran. Comic now reads ui_core's
  `designReduceMotionOf`, which also covers Android's Remove animations and the web's `prefers-reduced-motion`.
  `ComicMotion.of` and `ComicMotion.durationOf` give cuts under any of them. The progress burst, the progress bar and
  the skeleton stop looping, and when the setting changes while one runs, it stops or starts at once.
- From ui_core 0.2.1: a menu or popover its anchor opened gives the focus back to the anchor as it closes, and Home
  and End in a menu keep the row they reach in view.
- The tests run in tiers. `flutter test --exclude-tags goldens,sweep` is the everyday run. It keeps a case of every
  matrix: each part, page and setting at least once, on a phone's touch and a desk's pointer. The rest of each
  matrix (every platform, width, mode, corner family and edition) is tagged `sweep`, and `flutter test` runs every
  tier. The behaviour checks are split into three files (the parts as drawn, the parts styled, the example pages), so
  they run side by side.

## 0.2.0

Comic draws its states in its own ink now: nothing on the page is see-through.

- Hovering a part lays Ben-Day dots on it and pressing swells them. A disabled part is screened, not faded: an ink fill
  (a filled or danger button, a ticked box, a chosen chip) becomes a Ben-Day screen of that same ink on the paper, a
  dot every 7 at every size, and its words, icons and lines stay solid in one screened ink that keeps 3:1 against the
  dots by day and by night. A part with no ink fill is screened back toward the paper, opaque.
- Buttons stand on a hard offset print and sink onto it when pressed: the filled and outlined buttons, the danger and
  split buttons, and icon buttons with a rim. Dialogs, snack bars and toasts stand on a plate.
- A dialog's, sheet's or side sheet's backdrop is a dot screen over the page that swells in as it opens. Give your own
  modal routes the same with `ComicScreenedRoute`, or draw it with `ComicScreenScrim`.
- The keyboard's focus ring goes round a part and its print, with emanata ticks at its corners.
- `ComicPageDots` with `onChanged` is one control: press a mark to go to its page, step with the arrow keys, Home and
  End for the ends; a screen reader adjusts it as a slider.
- The split button's menu pops in instead of fading.
- In an open list (a select's, a menu's, a menu bar's, a combobox's) the chosen option is printed in the caption's flat
  yellow beside its check; 0.1.0 gave the yellow to the row the pointer or the keys were on and marked the chosen one
  with the check alone. That row, the one Enter takes, now wears the hover's light dots on the card, so it never reads
  as a second choice or a divider; on the chosen row the dots print in the caption's ink. A combobox checks the option
  it took while its field holds its words, and a tree's picked row keeps the yellow, without a check.
- A select takes the keys as a desktop select does. Down opens it, as Enter and Space do, on the chosen option (the
  first when none is). In the list the arrows wrap, Home and End go to the ends, and a typed letter jumps to the next
  option it starts (letters typed in a run spell the start). Enter chooses and Escape dismisses, and either way the
  focus goes back to the field, after a pointer opened it too. Its field tells a screen reader whether the list is
  open: expanded while it's up, collapsed otherwise.
- A combobox's and a tag input's list (ui_core 0.2.0's own keys): Down or Up on a closed list opens it without moving,
  on a combobox's option taken (else the first), and shows every option until the words are edited, where 0.1.0's
  combobox opened nothing on an empty field; the arrows wrap. A menu bar's menu jumps to a typed letter, as a select's
  list does. `ComicCombobox.isOptionEnabled` and `ComicMultiSelect.isOptionEnabled` mark options that can't be taken:
  in the secondary ink, passed over by the keys, the pointer and Enter. Their list keeps one highlight, the pointer
  moving it and the keys going on from it (ui_core's `highlightFollowsPointer`, on), as a native menu's does: the
  pointer's row and the keys' wear the same dots, and two would read as two current options. A long list opens with
  its value in view, and Android's back closes an open list or popover before it pops the page. `ComicCombobox.maxOptions` caps the matches of
  typed words alone. Enter keeps the focus in a combobox and in a tag input, for the next tag, where Flutter's done
  dropped it (`ComicBareEditor.onEditingComplete` for an editor of your own), and keeps the field's text input, so a
  browser goes on taking the typing after Enter (a field told of a submit restarts its input, and the web's restarted
  input took none: give an editor that keeps its focus `onEditingComplete`, not `onSubmitted`). A menu row's shortcut
  stands with its capitals on the row's middle.
- Every open menu (a select's list, an overflow menu, a menu bar's menu, a split button's) has one current row. The
  pointer moves it: a row the pointer moves over takes the focus, and the keys go on from there, so the pointer's row
  and the keys' never read as two. A menu the pointer opened lights no row until the pointer moves over one or a key
  is pressed: the first Down, Home, Enter or Space lights the first row (a select's, its value) and does nothing
  else, where it moved past it or took it. A menu the keys opened (Enter, Space, Down) lights the first.
- A page change is a cut on every platform: a page pushed or popped stands in its place, whole, in its first frame,
  where Flutter's default slid or zoomed it in from the side. `ComicTheme` gives it to the routes it reaches, Comic's own
  pages among them; give `comicPageTransitions` to your `MaterialApp`'s `PageTransitionsTheme` and the
  `MaterialPageRoute`s you push cut too, as the example does (the README shows the line). comic_ui's own theme is
  material_ui's, which Flutter's `MaterialPageRoute` never reads; the one map fits both Materials. On iOS the edge
  swipe still takes a page back, the page following the finger: the map wraps the cut there in ui_core's
  `DesignSwipeBackPageTransitionsBuilder` (`ComicPageTransitionsBuilder` alone takes no swipe).
- A `ComicTier` lays its panels across from 600 up, a tablet's width as a desk's, in the 16 gutter; 0.1.0 reflowed it as
  on a phone up to 1024, so a tablet showed a phone's stretched column. Its `phone` layout holds under 600 alone, as
  its documentation said, and a column under 130 still reflows.
- Every control stands on the design kit's tap target: the box it takes in a layout, the area a tap reaches and the
  box a screen reader outlines are now the same. Comic's floors stay 48 by 48 for a finger and 44 by 44 for a pointer;
  declare others with a `DesignTapTargetScope` above `ComicTheme`. A bare checkbox, the rating's stars, a month's
  arrows, the back button, a carousel's first arrow and the breadcrumb trail's first step keep their faces on the
  column's keyline, the target growing away from it (`ComicIconButton.targetAlignment` for your own). **Breaking:** an
  icon button or checkbox narrower than the floor now takes the floor's width in a row, where 0.1.0 let its target
  stand outward over its neighbours. Pick touch or pointer floors with `DesignTapTargetScope`, no longer with
  Material's `materialTapTargetSize`.
- `ComicFormField` round a group of choices or radios lets a screen reader reach each choice on its own; it read the
  whole group as one button. `group` says so for a group of your own.
- A tap anywhere in a text field's frame focuses it, beside its words too, and a focus ring inside a panel keeps plain
  corners where the panel's edge would cut its ticks.
- `ComicSpace`, the spacing scale on a 4-point grid. Every part takes its gaps and insets from it; a few moved by a
  point or two to sit on the grid.
- `ComicBrand` and `ComicNavItem` live in their own library, still exported from `comic_ui.dart`, so a bar copied out
  of the package keeps reading them.
- `ComicStyle` and `ComicStyleOf` are now the design kit's `DesignStyle` and `DesignStyleOf` under Comic's names. The
  slots and calls are the same, so your code builds as it was, and a style made for another look on the same kit
  works here too.
- Fields, sheets and menus no longer crash in apps set to a language other than English; their built-in labels
  now follow the app's language.
- The parts' shared words come in 30 languages. Add `DesignLocalizations.delegate` to your app's
  `localizationsDelegates`, and its `supportedLocales` to yours, and they follow the reader's language.
- The command palette's backdrop is the dot screen too; it was a flat dim.
- At large text sizes a button is never narrower than its longest word, and a timed row's time never breaks. On a
  phone, the cover's balloon moves under the burst rather than break a word, and the splash's note wraps before the
  burst. A note box's hint wraps over its lines.
- The example gallery reads in Arabic when it runs right to left, on every everyday screen.
- Comic's lettering falls back to its text face for a script the display face lacks, so Arabic and other scripts show
  instead of empty boxes. A tilted stamp takes the room its corners reach, and the cover's date box stacks under the
  issue and price at large text on a phone.
- On the web, lettering laid out before a fallback font arrived kept its empty boxes; it lays out again when the
  system's fonts change, as Flutter's own text does. Words in a right-to-left script are lettered in the text face,
  the burst's words over and under its number too: the display face's slanted "!" sat over the script's last letter.
- A burst keeps its words off its outline: they fit with a little of the fill between them and the star's edge,
  checked along each line and not only at its corners, where a valley between two spikes could cut in.
- By night the modal screen is printed in the night's cream line (`ComicColors.scrim`): a reverse screen that knocks
  the black ground back, as black dots knock the paper back by day. Black dots on the night's black screened nothing
  but the cream words, and cut those into pieces.
- By night `ComicTextField(onPaper: true)` stands on the night card in cream, as every field does; it stayed on day
  paper with its cream rim lost in its fill.
- A phone's tab bar whose tabs need more than its row (at large text) holds its rim at the row's ends and scrolls the
  tabs inside it, each at its own width, so the next tab shows, cut by the rim; the chosen tab is scrolled into view.
  The rim used to scroll away with the last tab, and nothing showed there was one.
- At large text on a phone, the cover's last box above the date runs to the row's end, where bare art showed through.
- `ComicTheme.of` gives Comic's default theme (Offset, by day) when no `ComicTheme` is above, as `Theme.of` does;
  `ComicTheme.maybeOf` still answers null. Selecting text on iOS no longer throws when your `ComicHost` sits under
  `home` rather than in the app's `builder`.
- Every part describes the values it was built with in Flutter's inspector and in a failing test's widget tree, its
  defaults hidden.
- A value out of its range now asserts in debug builds: a field of no lines, a number field that steps by nothing,
  progress past 1, a review of more than five stars, a badge or count below zero.
- Every example in the API docs is compiled and run by the package's tests.
- `comicInventory`'s calendar, data table, tree view and scroll area specimens dispose the controllers they make; they
  made a new one on every build and never disposed it.
- The internal render boxes `ComicPressFace`, `RenderComicPressFace`, `RenderComicOutward` and `RenderRowReach` left
  `comic_parts.dart`, the copy-out parts library, which may change in any version.
- Customising keeps Comic a comic. Deprecated, each still working until a later version removes it:
  - `ComicShapes.rounded` and `ComicThemeData.copyWith(shapes:)`: Comic is square, with only speech and heads round.
    Give one part its own corner through its style's `shape`.
  - `ComicThemeData.copyWith(motion:)`: Comic's motion is a quick cut and a small pop. Reduce Motion still turns it
    into cuts (`ComicMotion.still`) by itself.
  - `ComicTypeface.scale` and the `scale:` of its constructors and `copyWith`: the platform's text scaling serves
    readers without breaking the lettering. `dart fix --apply` removes the argument.
  - Strokes come in two steps, `ComicStrokes.standard` (the look's own contours, a theme's default) and
    `ComicStrokes.bold`. The `ComicStrokes(...)` constructor with free widths and `ComicStrokes.copyWith` are
    deprecated; `ComicStrokes.look` is now `ComicStrokes.standard`, and `dart fix --apply` renames it.
- A part whose style gives a see-through fill or overlay asserts in debug builds, naming law 1 (flat opaque inks). It is
  an assert, not a clamp: a release build draws the colour as given.
- Flutter's own widgets under Comic (a text field's selection, a Material part an app adds) set their words in the
  theme's text face, so a `ComicTypeface` you give reaches them. 0.1.0 always used Shantell Sans.
- The example gallery's Customize panel no longer offers rounded corners or a type scale.
- The example gallery follows a link the browser pushes after it starts (an address you edit, or Back to the
  opening link) in place; it threw, having no named route for it. At a desk, the splash's cabin stands clear of its
  title.
- The 0.1.0 notes said every part takes a `style:`. The parts that do are buttons, fields, choices, the pickers,
  surfaces, raised surfaces, avatars and badges, and the README lists them. The README no longer promises `Widget`
  slots beside the `String` labels.

## 0.1.0

First release of Comic: a Flutter design system that draws an app as a page of a printed comic.

- Five print editions (offset, reprint, newsstand, pulp, sunday), each with a day and a night issue, and
  `ComicThemeData.from` for an edition in your own colours. `ComicTheme` installs under MaterialApp, CupertinoApp or
  WidgetsApp; `AnimatedComicTheme` moves between themes.
- Everyday parts: `ComicButton` (outlined, `.filled`, `.text`, and `isDestructiveAction` on each), icon and send
  buttons, links, text fields, text areas, search, one-time codes, selects, comboboxes, checkboxes, radios, switches,
  sliders, segmented buttons, chips (`ComicChip.filter`, removable with `onDeleted`), steppers, date and time pickers,
  file upload.
- Pages and navigation: scaffold, app bar, navigation bar, rail and drawer, tabs, breadcrumbs, pagination, carousel.
- Lists and containers: list sections and tiles, switch and check rows, cards, panels in tiers, data tables,
  disclosure groups.
- Raised surfaces: dialogs, bottom sheets, action sheets, menus, popovers, tooltips, snack bars and toasts, each with a
  `showComic...` function that handles focus, dismissal and Escape.
- Status and data: badges, tags, avatars and avatar groups, progress, skeletons, empty, loading and error states,
  ratings; line, area and bar charts (`ComicChartType`), pie charts, sparklines.
- Comic's own: speech and thought balloons, captions, the burst, sound effects, Ben-Day dots, covers and splashes.
- Every change of a part's state animates in Comic's motion (a quick cut, a short pop): presses sink onto their print,
  fills, rims and words move to their new state, the focus ring inks in, and day turns to night. Reduced motion
  switches at once.
- Per-state styles (`ComicStyle`) for every part, above its component theme.
- Flutter's conventions: `value` and `onChanged` on every control (a null callback disables it), an optional
  `focusNode` and `autofocus` on every part with one focus target, an optional `controller` on every field, and
  Flutter's names (`initialValue`, `maxLines`, `firstDate`, `destinations`, `isError`, `waitDuration`).
- Keyboard focus and activation, screen-reader labels, roles and states, 48 by 48 touch targets, text scaling,
  right-to-left layouts and English words through `ComicLocalizations`.
- Bundled Bangers and Shantell Sans; `ComicGlyphs` on Lucide icons.
- `comic_parts.dart`: the tokens, painters and helpers the parts are built from, for copying a part into your app.

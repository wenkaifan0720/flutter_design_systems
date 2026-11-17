# ui_core

Headless behaviours for Flutter design systems. Each one keeps the state, the keyboard, focus and what a screen reader
hears; it hands a builder what to draw, and the design system draws every pixel. No Material, no Cupertino.

The look packages built on it (`comic_ui`, `fluent2_design_ui`, `frosted_ui`, `neumorphism_ui` and the rest) re-export
it, so an app that uses a look rarely imports it directly. Import it to build a look of your own:

```dart
import 'package:ui_core/ui_core.dart';
```

A button of your own, for example: `DesignPressable` keeps the press, the keys, focus, hover and what a screen reader
hears, and its builder draws the button for each set of states.

```dart
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

class InkButton extends StatelessWidget {
  const InkButton({super.key, required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return DesignPressable(
      onPressed: onPressed,
      semanticLabel: label,
      minimumSize: const Size(44, 44),
      builder: (context, states, child) {
        final pressed = states.contains(WidgetState.pressed);
        final focused = states.contains(WidgetState.focused);
        final disabled = states.contains(WidgetState.disabled);
        return DecoratedBox(
          decoration: BoxDecoration(
            color: disabled
                ? const Color(0xFFCBD5E1)
                : pressed
                ? const Color(0xFF1D4ED8)
                : const Color(0xFF2563EB),
            borderRadius: BorderRadius.circular(8),
            border: focused
                ? Border.all(color: const Color(0xFF93C5FD), width: 2)
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFFFFFFFF)),
            ),
          ),
        );
      },
    );
  }
}
```

## The behaviours

| Behaviour | Class | Flutter's nearest |
|---|---|---|
| Anchored overlay (popover, menu surface) | `DesignAnchoredOverlay` | `RawMenuAnchor` |
| Calendar | `DesignCalendar`, `DesignCalendarController` | `CalendarDatePicker` |
| Carousel | `DesignCarousel` | `CarouselView` |
| Colour picker | `DesignColorPicker`, `DesignColorArea`, `DesignColorSlider` | |
| Combobox | `DesignCombobox` | `RawAutocomplete` |
| Command palette | `DesignCommandPalette`, `showDesignCommandPalette` | |
| Data table | `DesignDataTable`, `DesignTableController` | `DataTable` |
| Form field | `DesignField`, `DesignForm`, `DesignFormField` | `InputDecorator`, `Form` |
| Input group | `DesignInputGroup` | |
| Menu bar | `DesignMenuBar` | `MenuBar` |
| One-time code | `DesignOtpField` | |
| Password reveal | `DesignPasswordReveal` | |
| Pull to refresh | `DesignPullToRefresh` | `RefreshIndicator` |
| Range slider | `DesignRangeSlider` | `RangeSlider` |
| Reorderable list | `DesignReorderableList` | `ReorderableListView` |
| Scroll area | `DesignScrollArea` | `RawScrollbar` |
| Side sheet | `DesignSideSheetRoute` | |
| Split button | `DesignSplitButton` | |
| Split view | `DesignSplitView` | |
| Swipe actions | `DesignSwipeActions` | `Dismissible` |
| Tag input | `DesignTagInput` | `InputChip` |
| Toasts | `DesignToaster` | `ScaffoldMessenger` |
| Toggle group | `DesignToggleGroup` | `SegmentedButton` |
| Tree | `DesignTree`, `DesignTreeController` | `TreeSliver` |

They are built from `DesignPressable` (a press, focus, hover and semantics on any widget) and `DesignValueHandle`
(a value dragged or stepped with the keys). Each class's documentation has an example.

## Flutter's conventions

The behaviours take what Flutter's own widgets take, under Flutter's names:
- A controller (`TextEditingController`, `ScrollController`, `MenuController`, or one of this package's
  `ChangeNotifier`s) and a `FocusNode` are optional where a behaviour can keep its own: without one it makes its
  own and disposes it, and it never disposes one it was given. A behaviour whose controller holds its model (a
  calendar's dates, a table's rows, a tree's nodes, a colour shared by an area and its sliders) or shares it with
  your scroll view takes it as required, as `TabBarView` needs one when no `DefaultTabController` is above it.
- A single tab stop takes `focusNode` and `autofocus`. A behaviour of many stops (a toggle group, a menubar, a
  table, a tree) keeps one node per item, as `SegmentedButton` and `MenuBar` do.
- A value comes with `onChanged`, and a null `onPressed` or `onChanged` disables, with no second switch. Two
  keep one, as `ListTile` and `TextField` do: `DesignPressable.enabled` (a busy button keeps its focus and
  reads as enabled while it ignores presses) and `DesignCommand.enabled` (a palette given `onSelected` runs
  commands that carry no `onPressed` of their own).
- What a builder paints (a split button's label and its actions, a menu entry, a command, a toast, a table's column,
  a shell's tab) carries its words as a `String` and its glyph as `IconData`: they are what type-ahead, search and a screen reader read, and your
  builder turns them into widgets. A `Widget` slot may come beside each in a later minor version, the `String`
  then optional, so nothing you write now breaks.

## What each behaviour promises

Every behaviour has a contract test, run on each change, that checks:
- what a screen reader hears of it (its role, label, value and actions);
- that it is disabled, and out of the focus order, when its callback is null (or `enabled` is false, where it
  takes one);
- that an error is announced as it appears;
- its keys, left to right and right to left;
- that nothing overflows at twice the text size, and every tap target is at least 44 by 44;
- that under Reduce Motion, Android's and the web's flag or iOS's alone, it settles within a second and nothing
  runs on.

## Motion

Motion is springs only: a look's motion tokens are (damping ratio, stiffness) pairs, run through `designSpring`,
`DesignMotionPolicy` and `springTo`, and nothing takes a duration or an easing curve. Under Reduce Motion,
`DesignMotionPolicy.of(context)` critically damps every spatial spring (one that moves, resizes or reshapes
something) at its own stiffness, so nothing overshoots or bounces, and turns every effects spring (opacity, colour)
into a short fade: critically damped at a stiffness of at least 3800 (`DesignMotionPolicy.reducedEffectsStiffness`),
settled within 150 ms, so nothing lingers. Neither is cut to an instant change, which reads as a flash.

Whether the reader asked for reduced motion is one read, `designReduceMotionOf(context)`, and every part of
ui_core reads it. The platforms ask differently:

| Platform | The setting | What Flutter sets |
| --- | --- | --- |
| Android | Remove animations | `MediaQuery.disableAnimationsOf` |
| Web | `prefers-reduced-motion` | both |
| iOS | Reduce Motion | only dart:ui's `AccessibilityFeatures.reduceMotion`, which MediaQuery does not carry |

So `MediaQuery.disableAnimationsOf(context)` alone misses an iPhone with Reduce Motion on; read
`designReduceMotionOf(context)` (or `DesignMotionPolicy.of(context)`) instead. A widget that read it builds again
when either setting changes. iOS's change comes as a build, not as `didChangeDependencies`, so read it in `build`
or as you act, not once in `didChangeDependencies`.

### A look's page transitions

An app's `MaterialPageRoute` plays the push its own Material theme names. A look's library stands on material_ui, so a
`PageTransitionsTheme` it installs in the Material theme it builds is material_ui's. An app on Flutter's own
`MaterialApp`, as most apps that take a look are, and every look's example, pushes Flutter's `MaterialPageRoute`,
which never reads it: on a Mac it plays the Cupertino slide. So a look exposes its push as a map of widgets-level
`PageTransitionsBuilder`s, which fits both Materials' `PageTransitionsTheme`:

```dart
const Map<TargetPlatform, PageTransitionsBuilder> comicPageTransitions = {
  TargetPlatform.android: ComicPageTransitionsBuilder(),
  // iOS's swipe back from the screen's edge, round the look's push.
  TargetPlatform.iOS: DesignSwipeBackPageTransitionsBuilder(ComicPageTransitionsBuilder()),
  TargetPlatform.macOS: ComicPageTransitionsBuilder(),
  // ...
};
```

On iOS a page pops with a swipe from the screen's leading edge, and the swipe lives in Cupertino's page transition,
which a look's own push replaces. `DesignSwipeBackPageTransitionsBuilder` keeps it round any builder: while a finger
drives the swipe, the page follows it and the page under it shows, as on every iOS screen; otherwise the look's push
and pop play. `designSwipeBack(map)` wraps a map's iOS entry the same way, for a map built at run time.

Its example and its README put it in the app's `ThemeData`, Flutter's or material_ui's, whichever the app is on:

```dart
MaterialApp(
  theme: ThemeData(
    pageTransitionsTheme: const PageTransitionsTheme(builders: comicPageTransitions),
  ),
  home: const ComicHome(),
);
```

`example/test/page_transitions_test.dart` holds it: under that theme, Flutter's `MaterialPageRoute` plays the look's
push on every platform, and without it a Mac's plays the Cupertino slide; on iOS, a swipe from the left edge past half
way pops the page, and one let go short of it settles back. A look's example copies the test with its own map.

## Styling a part

A look's parts take a `style:` of one shape, `DesignStyle`, as Material's buttons take a `ButtonStyle`: ten slots
(fill, foreground, edge, overlay, side, shape, padding, minimumSize, textStyle, iconSize), each a
`WidgetStateProperty` that resolves for the part's states. A part reads each slot from its `style:`, then its
component theme, then the look's theme-wide knobs, then the look's default; `DesignStyleOf` reads the first two
for a part's states. Each look names it as its own (`ComicStyle`, `FrostedStyle`), so a style is written and read
the same way in every look.

## Words

The words a behaviour says on its own ("Close sheet", "Slide 2 of 5", a sorted column's hint) come from
`DesignLocalizations`, each also a parameter on its behaviour. So do the general words a look shows or says by
itself (Cancel, Close, Today, Next month, "2 of 5", "3 items selected"), under `MaterialLocalizations`' names where
Flutter has the word: a look reads them from `DesignLocalizations.of(context)` rather than writing English. English
is the default, with nothing to set up under `MaterialApp`, `CupertinoApp` or `WidgetsApp`.

ui_core speaks 30 languages (`DesignLocalizations.supportedLocales`): its dates, plurals and digits come from
Unicode CLDR, as Flutter's do, and its words are Material's own translations where Material has the word. Opt in
with its delegate beside Flutter's, from `flutter_localizations` (add `flutter_localizations: sdk: flutter` to your
pubspec, as a look's gallery does):

```dart
import 'package:flutter_localizations/flutter_localizations.dart';

MaterialApp(
  localizationsDelegates: const [
    DesignLocalizations.delegate,
    ...GlobalMaterialLocalizations.delegates,
  ],
  supportedLocales: DesignLocalizations.supportedLocales,
  // ...
)
```

`GlobalMaterialLocalizations.delegates` holds the Material, Cupertino and Widgets delegates for your app's own
Flutter widgets: without the Material one, a Material `TextField` under a language other than English asserts, and
the Widgets one gives Arabic, Hebrew, Persian and Urdu their direction. A look supplies its own Material and
Cupertino words in the app's language: it is drawn with `material_ui` and `cupertino_ui`, whose words are types of
their own, and loads them itself. A locale ui_core does not speak gets English. For a language of your own, or
words of your own, extend `DefaultDesignLocalizations`, override the words you translate, and add a delegate for
your subclass to `localizationsDelegates`; a word added in a later minor version then stays English until you
translate it. `DesignLocalizations` also says the day a week starts on (`firstDayOfWeek`), which a calendar follows unless told
otherwise.

Seventeen words are Material's own translations. The other 38 messages are ui_core's own, translated for 0.2.0, and
in every language but English they await a native speaker's check; a correction is a patch version. They are
`clearButtonTooltip`, `showMoreLabel`, `showLessLabel`, `selectedLabel`, `loadingLabel`, `noResultsLabel`,
`retryButtonLabel`, `doneButtonLabel`, `confirmButtonLabel`, `positionLabel`, `carouselLabel`, `carouselSlideLabel`,
`colorAreaLabel`, the four `colorChannel` names, `commandPaletteLabel`, `commandPaletteBarrierLabel`,
`commandPaletteResultsMessage`, `sortedAscendingHint`, `sortedDescendingHint`, `requiredHint`, `formProblemsMessage`,
`showPasswordLabel`, `hidePasswordLabel`, `menuBarLabel`, `refreshingMessage`, `refreshedMessage`,
`rangeSliderStartLabel`, `rangeSliderEndLabel`, `reorderableListMovedMessage`, `sideSheetBarrierLabel`,
`splitButtonMenuLabel`, `splitViewHandleLabel`, `tagInputDeleteLabel`, `toasterRegionLabel` and `treeLevelHint`.

## Tap targets, density and spacing

A look declares the floors its controls stand at once, as a theme does: `DesignTapTargetScope` holds
`DesignTapTargets` (44 by 44 for a finger, 24 by 24 for a pointer, unless the look says otherwise), and
`DesignTapTarget` lays a control out at the floor, as Material's padded tap target size does: its face keeps its
size, aligned where you say (centred by default), and the room round it takes the taps and is what a screen reader
outlines and Flutter's tap-target guideline measures, so the hit area, the semantics and the layout agree. Whether a finger or a pointer
reaches the controls is `DesignInput`, by platform unless the look decides. `DesignDensity` tightens a control's
face in steps (-4 to 4), never its target: a compact face stands in the same target, with more room round it.

`DesignSpacingScope` declares the grid a look's spacing stands on (`DesignSpacing`, 4 pt by default; a look whose values
sit on 2 pt declares 2), read by `DesignSpacing.of` and by the spacing check below.

## The checks a look is held to

Beside the alignment checks, four read any screen, each from its root (a gallery page, an app screen), and say what
they find in words:
- `DesignTapTargetCheck`: every control's tap target reaches the look's floor for the input (a phone's screen is
  read for a finger, a desk's for a pointer), and its target is where it is drawn; a text field's own keys (a clear
  or reveal key whose node lies in the field's) are part of the field's reach.
- `DesignCursorCheck`: a pointer over a live control shows the click cursor over its whole hit area, or one that
  says more (a text field's text cursor, a handle's grab, a divider's resize), and over an off control nothing of
  its own.
- `DesignShadowClipCheck`: no shadow, glow or rim is cut flat by a clip round it, and none shows square behind a
  round face. A scroll view's edge along its scroll, with more content past it, is scrolling, not a cut; at the end
  of its content, and across its scroll, the cut counts. Given `near:` (a control's rect), it reads only the casts
  that reach it, as a test of one control's press, hover or focus needs.
- `DesignSpacingCheck`: a page's margin, the insets of shapes set in shapes (concentric corners), and gaps on the
  grid; `literals` reads a look's sources for spacing off the grid its `DesignSpacingScope` declares.

`test/moving_states.dart` (beside ui_core's other tests; copy it into your package's `test/`) holds the moments
between a look's states still, so a test can capture and check them: a press held halfway, a hover, a keyboard
focus, a sheet halfway open, a carousel halfway through a swipe. A press that flashes a square ink before its round
face fills, or a focus ring cut by its row, shows only there.

## Templates for a look's package

ui_core holds itself to these; a look's package copies them:
- **Analysis options.** ui_core's `analysis_options.yaml`: the strict modes and Flutter's lints, with
  `public_member_api_docs`, `avoid_dynamic_calls`, `unawaited_futures`, `prefer_const_constructors`,
  `use_named_constants` and `missing_code_block_language_in_doc_comment`. pana and pub.dev read a package's own
  options, never a workspace root's, so each package carries them.
- **Leak tracking.** `test/flutter_test_config.dart` turns on Flutter's leak tracking for every test (with
  `leak_tracker_flutter_testing` among the dev dependencies): what a test or the package makes and never disposes
  fails the test that made it.
- **Compiled doc examples.** `test/doc_examples.dart` holds `testDocExamples`: every example in your lib's docs,
  written out as an entry in your `doc_examples_test.dart`, so an example that stops compiling fails analysis, one
  missing from the file fails a test, and each one is built and run.
- **Renames.** A rename keeps the old name for one minor version, as
  `@Deprecated('Use minimumSize instead. This feature was deprecated after v0.2.0.')`, with a data-driven fix in
  `lib/fix_data.yaml` so `dart fix --apply` moves your callers, and a `test_fixes/` pair (`button.dart` with the old
  name, `button.dart.expect` with the new; `dart fix --compare-to-golden test_fixes`). Its CHANGELOG entry is tagged
  **Breaking**.
- **A theme's `.of`.** A theme's `of(context)` gives the look's default when none is above, as `Theme.of` does, and
  `maybeOf` gives null; only a part's own state (`DesignForm.of`, `DesignToaster.of`) asserts that it is there.
  ui_core's `DesignSpacing.of`, `DesignTapTargets.of` and `DesignLocalizations.of` fall back so.
- **Package-only code.** A file under the look module's `package/lib_overrides/` replaces the exported file at the
  same path under the package's `lib/`: code drip's own apps do not take (a look loading `material_ui`'s and
  `cupertino_ui`'s own words, say). An override whose in-repo file was renamed or removed fails the export.
- **Repeated docs.** A rule many parameters share is written once, in a `{@template}`, and named by `{@macro}` where
  it repeats: ui_core's `design.focusNode` (a focus node given is the caller's), `design.autofocus` and
  `design.nullDisables`.

## Lining controls up

Controls that share a line drift apart in ways no one control's test sees: two controls of "the same size" a few
pixels apart, a label a pixel low, a field that shrinks on desktop. `package:ui_core/alignment.dart` checks a design
system's controls row by row, as Android, iOS and macOS, from their drawn pixels, and draws them four times their
size for review; `DesignTextEntryCheck` checks each text entry the same way. What keeps a line straight:
- one control height per size and density, taken by every control that can share a line;
- content centred in a box of that height, rather than padding added to a line height;
- even leading (`TextLeadingDistribution.even`) on control labels, so a label's line box is centred on its glyphs;
- a row that centres its controls, never one aligned to the bottom or the top;
- a theme under the design system that pins its density: Material's `ThemeData.visualDensity` is compact on
  desktop unless the theme says otherwise, and tests run as Android, so no test sees it;
- a text entry that is a `TextField` (validated by the design system's own `FormField`, never a
  `TextFormField`, which builds a decoration even when given none) inside the design system's own box, its
  decoration null or collapsed with `contentPadding`, `constraints`, `isDense` and `visualDensity` all set, its
  one line centred by alignment, and its icons, counter, help and error the design system's own widgets: a decoration
  field left unset is filled from the platform and the host theme.

`DesignControlBox` is that box for a control, its content centred and its text given even leading.
`DesignTextEntryBox` is the same for a text entry: one line centred, several starting where one stands, the hint on
the typed text's baseline. Both paint nothing.

A label centred by its line box still looks off: the box is the font's ascent and descent, not its capitals, and the
engine puts the baseline on a whole pixel, so the capitals land a pixel or two from the middle, by a different amount
in each typeface and size. `DesignCapCenter` wraps a one-line label, keeps its size, and draws it so that its
capitals' middle, where the engine will draw it, is its box's middle: whatever centres the box (a row, a button's
face, a tab, a title bar) then centres the capitals, within half a device pixel (an engine that hints the font, such
as FreeType, also snaps the capitals' top to the pixel grid, which can add up to half a pixel). It takes the
typeface's cap height as
a fraction of its font size (`capHeightFactor`, the font's OS/2 cap height over its units per em). An icon beside
the label is not moved. Around a one-line `TextField` (or `DesignTextEntryBox`) it does the same for the typed
text and the hint, and the caret, the selection and taps move with them.

What the eye compares in a row is the capitals: a 13 px button label and a 14 px field's text look level when their
capitals' middles are, whatever their baselines. So the alignment matrix holds baselines only among labels of one size
and style, and every label's and text entry's capitals on the row's centre line, as drawn, to half a device pixel; a
design system whose labels and entries are wrapped in `DesignCapCenter` passes.

A card's contents drift the same way across rows: a title at 16, rows' words at 26, a checkbox at 22, a chevron that
stops short of the switches above it. A keyline is the line what starts a row (or ends one) sits on. A design
system's card and section widgets put `DesignKeylineRegion` around their content (it lays out and paints nothing,
and names any nested level the card means, such as words after an avatar); `DesignKeylineCheck` then checks every
such card on a screen: each row's first edge on the leading keyline, its last on the trailing one, and the controls a
row holds one height on one centre line. Words are read by their line boxes, a control by its drawn face (not its
tap box or its shadow), an icon that ends a row by its ink; what lies inside a face or a well (a field's, a table's)
is not an item of the card around it. A look marks a face its pixels cannot show (one the colour of the ground, a
pane of glass) or a picture with things placed on it with `DesignKeylineFace`, which both checks take as it is.
A gallery marks each section's column of examples with `startAligned: true`, and runs the check on each gallery page
too: there every row starts on the leading keyline, so a stepper, a sum or a line of words centred in the column (or
set at its end) is named, where a card may centre an empty state. `DesignKeylineSheet` draws the keylines over a
screen.

`DesignLabelCheck` needs no list of controls: on any screen (each gallery page, each app screen) it reads every control
that draws a face around one line of words or an icon, and checks that the label sits on the middle of the face (words
by their capitals, so descenders do not count; an icon by its ink), giving the offset as laid out and as drawn. A
label beside a text entry of more than one line (a note field) stands on the entry's first line and is held to that
line's capitals instead. A painted mark that starts the row of a control's words (a way back's triangle, drawn by a
custom paint holding no words) is read by its ink, as an icon is. Its `checkDensities` runs a screen under each
density the look ships. Given a `drawnTolerance` (a look that wraps its labels in `DesignCapCenter` gives 0.5), it
holds each label's capitals, as drawn, to the middle of its face in device pixels, and an icon or a painted mark
beside a label to the label's capitals.

A control's box is not always what a person sees as its outline: a glass button whose outer ring barely stands off a
light dialog reads smaller than the filled button beside it, though their boxes match. `DesignRowCheck` reads each
control in a row (a dialog's actions, a split button's halves, a field and its button) by its drawn outline: inside
its face's shape, so a shadow never counts, the outermost pixels whose contrast with the surface reaches
`contrastFloor` (1.25 to 1). It holds one top and one bottom across the row, and equal sides where the row is laid
out with equal sides on its surface, to half a device pixel, and each control's capitals (a label's, or a text
entry's typed text or hint) on the row's centre line, and gives each problem as laid out and as drawn. A control with
no face of its own (an icon button drawn as a bare glyph, a text button, a navigation destination whose indicator
holds only its icon, an icon whose only face is its badge, a tab whose face shows only the line under it) has no
outline to compare and is read by its capitals, or its icon's middle, on that line. Words and icons drawn over a face
are never read as it, whichever control holds them; a card's title over its body is placed, not centred; a text
field's own parts (its entry and the toggle or switch inside its face) are one field, not a row. A row inside a
`DesignKeylineRegion` whose `mixedHeights` says why its controls differ (a gallery's ladder of one control per
size) is not held. The chips of a `Wrap` are read run by run, each run a row; a control a clip partly hides (a
week scrolled in its strip, its weekend past the strip's edge) is not held, as what shows of it is not its outline.
Run on a screen's root, so its bars (an app bar, a gallery's own bar) are read with the rest.

On a wide screen a control stretched across its column reads as a banner: a dropdown's closed face spanning a desktop
page is the common case. From 600 logical pixels wide, `DesignWidthCheck` holds each select, button, stepper and
segmented control to the width its content and its own padding take, or to 320 (a form grid's cell), whichever is
larger, as drawn; a group of choices apart (choice chips, choice cards, icon tiles, by their chosen state) and a tab
bar are held to 320 or the room their items take, each its content and padding and 40 px more, so three words spread
over a 1440 column are named and tabs or chips that keep to their words pass. A button whose words wrap onto two lines
though on one line they would fit 320 is named however wide it is. Free text entries, search, tables and
list rows may span (as may a header: two buttons round a heading marked `Semantics(header: true)`), and a design
system can give a kind of control another limit with its reason. A list's rows are read from Flutter's own semantics (`SemanticsRole.list` and
`listItem`) or from how they stand (a stack of rows as wide as each other, touching or a heading apart, a section's
one row edge to edge, a row
between paragraphs with its words leading and a glyph or value trailing), and a search bar from
`SemanticsInputType.search`. Its `checkList`, run with a list open, holds a list opened from a field to at least the
field's width, on its leading edge, with its words on the field's words, whatever paints the list's surface, a popup
over the field's page (a menu's route, an overlay portal's child) holding one row or only a "no matches" note
included; a combobox's field is the face
round its entry and toggle, and a disabled field has nothing to check. `DesignAnchoredOverlay` lays a
surface above or below its anchor at least as wide as the anchor by default.

Two checks read words and clips. `DesignWordBreakCheck` names a word broken across two lines ("Groce" over
"ries"): a box too narrow for its longest word. `DesignClipCheck` names a control a clip round it cuts (a month's
Saturday cut by the room it is in), giving how much of it shows, and words cut by a clip or by their box (a line past
its end, words past their last line with no ellipsis); what scrolls is read only against the clips inside its
viewport, so the rest of a list is not cut, and a control wholly past a clip is hidden, not cut.

These checks read what is painted, and only that: not an `IndexedStack`'s other children, nor what `Offstage` or
`Visibility` keeps laid out, nor what a transform scales to nothing (an empty checkbox's check), nor a list's rows
laid out past what it shows (its cache extent); the rest of the screen is read without them. Before any of them, a test loads every font family in the package's FontManifest.json and
lets the screen's images decode (each check's documentation shows how); text drawn in the test's own font fails the
label check once, with that reason, and a screen repainted since its last frame stops a check with that reason.

## Who disposes what

A controller or focus node you pass in is yours to dispose: a behaviour never disposes what it is given. Each
parameter's documentation says what the behaviour does given none (most make their own, and dispose it).

## Libraries

- `package:ui_core/ui_core.dart`: the behaviours, motion, the words, a part's style (`DesignStyle`), `DesignCapCenter`, which centres a label
  by its capitals, `DesignKeylineRegion`, which marks a card for the keyline check, and `DesignKeylineFace`,
  which marks a face its pixels cannot show.
- `package:ui_core/host.dart`: the scaffold contract the look packages share. It is not meant for apps and leaves
  the package in a later minor version.
- `package:ui_core/inventory.dart`: the checklist of components an ordinary app expects from a design system, and
  `DesignInventoryGallery`, which lists a design system's answers to it. A design system's own tests and gallery
  use it; an app does not.
- `package:ui_core/alignment.dart`: `DesignAlignmentMatrix`, which checks that a design system's controls line
  up where they share a line, `DesignTextEntryCheck`, which checks its text entries, `DesignAlignmentSheet`,
  which draws them for review, `DesignKeylineCheck` and `DesignKeylineSheet`, which check and draw a screen's
  keylines, `DesignLabelCheck`, which checks that every control's label sits on the middle of its face, and
  `DesignRowCheck`, which checks that controls sharing a row line up as drawn, `DesignWidthCheck`, which
  checks that controls keep to their content's width on a wide screen and that a list opened from a field matches
  it, `DesignWordBreakCheck`, which checks that no word breaks across lines, `DesignClipCheck`, which checks
  that nothing is cut, and the four checks above (`DesignTapTargetCheck`, `DesignCursorCheck`,
  `DesignShadowClipCheck`, `DesignSpacingCheck`). Tests and review pages use it; an app does not.

## Requirements and versions

ui_core needs Flutter 3.47 or later (Dart 3.13), and depends on Flutter alone.

Before 1.0, a minor version (0.1 to 0.2) may change the API, and the CHANGELOG says what changed and how to move; a
patch version (0.1.0 to 0.1.1) never does. A rename keeps its old name, deprecated, for one minor version, with a
`dart fix`.

`host.dart`, `inventory.dart` and `alignment.dart`, and a look's `<look>_parts.dart` and `<look>_host.dart`, are
outside semver: they are tooling for looks, not an app's API, and may change in any version, a patch included (each
says so in its library doc, and the CHANGELOG says how to move). Before 1.0 the review and test tooling (the checks,
the inventory, the preview) is meant to leave `lib/` for a package of its own, so an app never compiles it.

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
- that under Reduce Motion it settles within a second and nothing runs on.

## Words

The words a behaviour says on its own ("Close sheet", "Slide 2 of 5", a sorted column's hint) come from
`DesignLocalizations`, each also a parameter on its behaviour. So do the general words a look shows or says by
itself (Cancel, Close, Today, Next month, "2 of 5", "3 items selected"), under `MaterialLocalizations`' names where
Flutter has the word: a look reads them from `DesignLocalizations.of(context)` rather than writing English. English
is the default, with nothing to set up under `MaterialApp`, `CupertinoApp` or `WidgetsApp`. For another
language, extend `DefaultDesignLocalizations`, override the words you translate, and add a delegate for your
subclass to `localizationsDelegates`; a word added in a later minor version then stays English until you translate
it. It also says the day a week starts on (`firstDayOfWeek`), which a calendar follows unless told otherwise.

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

- `package:ui_core/ui_core.dart`: the behaviours, motion, the words, `DesignCapCenter`, which centres a label
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
  it, `DesignWordBreakCheck`, which checks that no word breaks across lines, and `DesignClipCheck`, which checks
  that nothing is cut. Tests and review pages use it; an app does not.

## Requirements and versions

ui_core needs Flutter 3.47 or later (Dart 3.13), and depends on Flutter alone.

Before 1.0, a minor version (0.1 to 0.2) may change the API, and the CHANGELOG says what changed and how to move; a
patch version (0.1.0 to 0.1.1) never does.

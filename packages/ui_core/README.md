# ui_core

Headless controls for Flutter design systems. The package handles input, keyboard navigation, focus and accessibility.
Your widget builders draw each state using your design system's shapes, colours and typography.

The look packages built on it (`comic_ui`, `fluent2_design_ui`, `frosted_ui`, `neumorphism_ui` and the rest) re-export
it, so an app that uses a look rarely imports it directly. Import it to build a look of your own:

```dart
import 'package:ui_core/ui_core.dart';
```

A button of your own, for example: `RawButton` keeps the press, the keys, focus, hover and what a screen reader
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
    return RawButton(
      onPressed: onPressed,
      semanticLabel: label,
      minimumSize: const Size(40, 40),
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

## Build a look of your own

[Ink proof](example/lib/ink_proof.dart) is a small print studio screen. Turn the strip of printed dots to choose an
ink coverage, change the paper stock, then reset the proof. From `packages/ui_core` in the package repository:

```sh
cd example
flutter pub get
flutter run -d chrome -t lib/ink_proof.dart
```

The proof uses `RawPicker` for dragging, arrow keys, accessibility adjustments and reduced-motion scrolling.
Its item builder paints the tints and its column builder marks the focused row. `RawInputDecorator` labels the paper
selector, and `RawSegmentedButton` keeps each paper choice individually operable. The reset button draws the states
from `RawButton` and reserves a 48-pixel target.

The app supplies its own English and Arabic copy and its light and dark colours. Registering the widgets and
design localization delegates supplies reading direction and localized percentages. Try the screen with your
device set to Arabic or dark appearance.

Run `flutter test test/ink_proof_test.dart` in the example. To check a widget of your own, copy
[the two test helpers](example/test/support) into your app's test directory and adapt the
[`behaviourContract` in the proof's test](example/test/ink_proof_test.dart). Give it your finished widget, its
accessible name, expected actions and keyboard steps. The same test file shows how to operate a compound field
through its accessibility nodes and change appearance with Arabic text at twice its usual size.

## The behaviours

| Behaviour | Class | Flutter's nearest |
|---|---|---|
| Anchored overlay (popover, menu surface) | `RawPopover` | `RawMenuAnchor` |
| Calendar | `RawCalendarDatePicker`, `RawCalendarController` | `CalendarDatePicker` |
| Carousel | `RawCarousel` | `CarouselView` |
| Colour picker | `RawColorPicker`, `RawColorArea`, `RawColorSlider` | |
| Combobox | `RawCombobox` | `RawAutocomplete` |
| Command palette | `RawCommandPalette`, `showRawCommandPalette` | |
| Data table | `RawDataTable`, `RawDataTableController` | `DataTable` |
| Form field | `RawInputDecorator`, `RawForm`, `RawFormField` | `InputDecorator`, `Form` |
| Input group | `RawInputGroup` | |
| Menu bar | `RawMenuBar` | `MenuBar` |
| One-time code | `RawOtpField` | |
| Password reveal | `RawPasswordReveal` | |
| Pull to refresh | `RawRefreshIndicator` | `RefreshIndicator` |
| Range slider | `RawRangeSlider` | `RangeSlider` |
| Reorderable list | `RawReorderableList` | `ReorderableListView` |
| Scroll area | `RawScrollArea` | `RawScrollbar` |
| Side sheet | `RawSideSheetRoute` | |
| Split button | `RawSplitButton` | |
| Split view | `RawSplitView` | |
| Swipe actions | `RawSwipeActions` | `Dismissible` |
| Tag input | `RawTagInput` | `InputChip` |
| Toasts | `RawToaster` | `ScaffoldMessenger` |
| A bar toasts keep clear of | `RawToasterKeepClear` | `Scaffold.bottomNavigationBar` |
| Toggle group | `RawSegmentedButton` | `SegmentedButton` |
| Radio group | `RadioGroupKeyboardFix`, inside Flutter's `RadioGroup`, round its `RawRadio`s | `RadioGroup` |
| Tree | `RawTree`, `RawTreeController` | `TreeSliver` |
| Haptics | `RawHaptics`, `RawHapticsScope` | `HapticFeedback` |
| Overlay padding (a look's chrome a surface keeps clear of) | `RawPopoverPadding` | `MediaQuery.padding` |
| Context menu | `RawContextMenu` | `ContextMenuController` |
| Tooltip | `RawTooltipFocusFix` and `RawTooltipPlacement`, round Flutter's `RawTooltip`, in a `MergeSemantics` | `Tooltip` |
| Shortcut label (a menu row's keys) | `rawShortcutLabel`, `rawShortcutKeys` | `MenuItemButton`'s |
| Bottom sheet | `RawBottomSheetRoute`, `RawBottomSheetController`, `RawBottomSheetDragHandle` | `ModalBottomSheetRoute`, `DraggableScrollableSheet` |
| Full-screen sheet | `RawSheetRoute` | `PageRoute` |
| Dialog and alert | `RawModalDialogRoute`, `RawAlertDialog` | `DialogRoute`, `AlertDialog` |
| Swipe actions, from outside | `RawSwipeActionsController` | |
| Tabs | `RawTabController`, `RawTabBar`, `RawTabBarView`; `RawTabGroup<T>`, `RawTabGroupTab<T>` round tabs the caller lays out | `TabController`, `TabBar`, `TabBarView` |
| A group's arrows (one tab stop) | `RawRovingFocusGroup`, `RawRovingFocusItem`, `RawRovingFocusIntent` | `RadioGroup`'s, `TabBar`'s |
| Semantics-only proxies, by one type | `RenderSemanticsProxy`, a `RenderSemanticsAnnotations` | `RenderSemanticsAnnotations`, `RenderMergeSemantics` |
| Adaptive shell | `RawAdaptiveShell`, `RawWindowSizeClass`, `RawNavigationMode` | `NavigationBar`, `NavigationRail`, `NavigationDrawer` |
| List and detail | `RawListDetail` | |
| Wheel picker | `RawPicker`, `RawPickerColumn` | `CupertinoPicker` |
| Dialog and sheet actions | `RawActionBar` | `OverflowBar` |
| Date and time fields | `RawDateField`, `RawTimeField`, `RawTimeOfDay` | `InputDatePickerFormField`, `TimeOfDay` |
| Number field | `RawNumberField` | `TextField` with `keyboardType: number` |
| Rating | `RawRating` | (none) |
| Charts | `RawChart`, `RawPieChart`, `RawChartTable`; `RawLinearScale`, `RawTimeScale`, `RawBandScale` | (none) |

They are built from `RawButton` (a press, focus, hover and semantics on any widget) and `RawValueHandle`
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
  keep one, as `ListTile` and `TextField` do: `RawButton.enabled` (a busy button keeps its focus and
  reads as enabled while it ignores presses) and `RawCommand.enabled` (a palette given `onSelected` runs
  commands that carry no `onPressed` of their own).
- What a builder paints (a split button's label and its actions, a menu entry, a command, a toast, a table's column,
  a shell's tab) carries its words as a `String` and its glyph as `IconData`: they are what type-ahead, search and a screen reader read, and your
  builder turns them into widgets.

## Accessibility

Controls expose their label, value, role and available actions to assistive technology. Keyboard navigation follows the reading direction. Use a builder’s `WidgetState` values to show focus, press, selection and disabled states. Motion follows the platform’s reduced-motion preference.

## Motion

Motion is springs only: a look's motion tokens are (damping ratio, stiffness) pairs, run through `rawSpring`,
`RawMotionPolicy` and `springTo`, and nothing takes a duration or an easing curve. Under Reduce Motion,
`RawMotionPolicy.of(context)` critically damps every spatial spring (one that moves, resizes or reshapes
something) at its own stiffness, so nothing overshoots or bounces, and turns every effects spring (opacity, colour)
into a short fade: critically damped at a stiffness of at least 3800 (`RawMotionPolicy.reducedEffectsStiffness`),
settled within 150 ms, so nothing lingers. Neither is cut to an instant change, which reads as a flash.

Whether the reader asked for reduced motion is one read, `rawReduceMotionOf(context)`, and every part of
ui_core reads it. The platforms ask differently:

| Platform | The setting | What Flutter sets |
| --- | --- | --- |
| Android | Remove animations | `MediaQuery.disableAnimationsOf` |
| Web | `prefers-reduced-motion` | both |
| iOS | Reduce Motion | only dart:ui's `AccessibilityFeatures.reduceMotion`, which MediaQuery does not carry |

So `MediaQuery.disableAnimationsOf(context)` alone misses an iPhone with Reduce Motion on; read
`rawReduceMotionOf(context)` (or `RawMotionPolicy.of(context)`) instead. A widget that read it builds again
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
  TargetPlatform.iOS: SwipeBackPageTransitionsBuilder(ComicPageTransitionsBuilder()),
  TargetPlatform.macOS: ComicPageTransitionsBuilder(),
  // ...
};
```

On iOS a page pops with a swipe from the screen's leading edge, and the swipe lives in Cupertino's page transition,
which a look's own push replaces. `SwipeBackPageTransitionsBuilder` keeps it round any builder: while a finger
drives the swipe, the page follows it and the page under it shows, as on every iOS screen; otherwise the look's push
and pop play. `rawSwipeBack(map)` wraps a map's iOS entry the same way, for a map built at run time.

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

An app that builds its own routes, or a router's page list, takes `RawPage` (`RawPageRoute` for `Navigator.push`), as a
Material app takes `MaterialPage`: given the look's bare builder, it adds iOS's swipe back once, on iOS only, and fades
under Reduce Motion. `RawBottomSheetPage` puts a `RawBottomSheetRoute` in the same page list. A screen's bar reads
where the screen stands from `RoutePresentation.of(context)`, a root, a pushed page or a sheet, and the words its back
or close control says from `dismissLabel(context)`, in the app's language.

## Haptics

The moments a behaviour marks with a haptic are one table, `RawHaptics`: `selectionChanged` (a wheel's row crossing
its centre, a slider's thumb crossing a division, a rating's step while dragged), `longPress` (a long press that opened
something) and `thresholdCrossed` (a drag passing the point where letting go acts). Each is a callback that defaults
to the platform's own feedback; null plays nothing. A `RawHapticsScope` swaps the table for its subtree:
`RawHaptics.silent()` for none, or your own callbacks. Under flutter_test nothing plays; a test that checks a
haptic gives a scope a table that records.

## Styling a part

A look's parts take a `style:` of one shape, `RawStyle`, as Material's buttons take a `ButtonStyle`: ten slots
(fill, foreground, edge, overlay, side, shape, padding, minimumSize, textStyle, iconSize), each a
`WidgetStateProperty` that resolves for the part's states. A part reads each slot from its `style:`, then its
component theme, then the look's theme-wide knobs, then the look's default; `RawStyleOf` reads the first two
for a part's states. Each look names it as its own (`ComicStyle`, `FrostedStyle`), so a style is written and read
the same way in every look.

## Words

The words a behaviour says on its own ("Close sheet", "Slide 2 of 5", a sorted column's hint) come from
`RawWidgetsLocalizations`, each also a parameter on its behaviour. So do the general words a look shows or says by
itself (Cancel, Close, Today, Next month, "2 of 5", "3 items selected"), under `MaterialLocalizations`' names where
Flutter has the word: a look reads them from `RawWidgetsLocalizations.of(context)` rather than writing English. English
is the default, with nothing to set up under `MaterialApp`, `CupertinoApp` or `WidgetsApp`.

ui_core speaks 30 languages (`RawWidgetsLocalizations.supportedLocales`): its dates, plurals and digits come from
Unicode CLDR, as Flutter's do, and its words are Material's own translations where Material has the word. Opt in
with its delegate beside Flutter's, from `flutter_localizations` (add `flutter_localizations: sdk: flutter` to your
pubspec, as a look's gallery does):

```dart
import 'package:flutter_localizations/flutter_localizations.dart';

MaterialApp(
  localizationsDelegates: const [
    RawWidgetsLocalizations.delegate,
    ...GlobalMaterialLocalizations.delegates,
  ],
  supportedLocales: RawWidgetsLocalizations.supportedLocales,
  // ...
)
```

`GlobalMaterialLocalizations.delegates` holds the Material, Cupertino and Widgets delegates for your app's own
Flutter widgets: without the Material one, a Material `TextField` under a language other than English asserts, and
the Widgets one gives Arabic, Hebrew, Persian and Urdu their direction. A look supplies its own Material and
Cupertino words in the app's language: it is drawn with `material_ui` and `cupertino_ui`, whose words are types of
their own, and loads them itself. A locale ui_core does not speak gets English. For a language of your own, or
words of your own, extend `DefaultRawWidgetsLocalizations`, override the words you translate, and add a delegate for
your subclass to `localizationsDelegates`; a word added in a later minor version then stays English until you
translate it. `RawWidgetsLocalizations` also says the day a week starts on (`firstDayOfWeek`), which a calendar follows unless told
otherwise.

For number and chart labels, use `formatDecimal`, `parseDecimal` and `formatPercent`. Date and time controls use the locale’s calendar order, digits, separators and first day of the week.

## Tap targets, density and spacing

A look declares the floors its controls stand at once, as a theme does: `RawTapTargetScope` holds
`RawTapTargets` (40 by 40 for a finger, 24 by 24 for a pointer, unless the look says otherwise), and
`TapTargetPadding` lays a control out at the floor, as Material's padded tap target size does: its face keeps its
size, aligned where you say (centred by default), and the room round it takes the taps and is what a screen reader
outlines and Flutter's tap-target guideline measures, so the hit area, the semantics and the layout agree. Whether a finger or a pointer
reaches the controls is `RawInput`, by platform unless the look decides. `RawDensity` tightens a control's
face in steps (-4 to 4), never its target: a compact face stands in the same target, with more room round it.
Chips and tags smaller than the floor go in a `RawChipGroup`, which wraps them as `Wrap` does but puts its spacing
between their faces, their targets taking the room between, so a row of small chips does not stand twice as far apart.

`RawSpacingScope` declares the grid a look's spacing stands on (`RawSpacing`, 4 pt by default; a look whose values
sit on 2 pt declares 2), read by `RawSpacing.of` and by ui_core_test's spacing check.

## Testing your design system

Add `ui_core_test` to your test dependencies to check alignment, widths, tap targets and clipping on rendered screens. Use `RawKeylineRegion` to identify a card or section, and `RawKeylineFace` for a visible face that blends into its background. [ui_core_test on pub.dev](https://pub.dev/packages/ui_core_test)

## Lining controls up

Controls that share a line drift apart in ways no one control's test sees: two controls of "the same size" a few
pixels apart, a label a pixel low, a field that shrinks on desktop. ui_core_test's checks find them from the drawn
pixels (its README says how each reads a screen). What keeps a line straight:
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

`RawControlBox` is that box for a control, its content centred and its text given even leading.
`RawTextEntryBox` is the same for a text entry: one line centred, several starting where one stands, the hint on
the typed text's baseline. Both paint nothing.

A label centred by its line box still looks off: the box is the font's ascent and descent, not its capitals, and the
engine puts the baseline on a whole pixel, so the capitals land a pixel or two from the middle, by a different amount
in each typeface and size. `RawCapCenter` wraps a one-line label, keeps its size, and draws it so that its
capitals' middle, where the engine will draw it, is its box's middle: whatever centres the box (a row, a button's
face, a tab, a title bar) then centres the capitals, within half a device pixel (an engine that hints the font, such
as FreeType, also snaps the capitals' top to the pixel grid, which can add up to half a pixel). It takes the
typeface's cap height as
a fraction of its font size (`capHeightFactor`, the font's OS/2 cap height over its units per em). An icon beside
the label is not moved. Around a one-line `TextField` (or `RawTextEntryBox`) it does the same for the typed
text and the hint, and the caret, the selection and taps move with them.

What the eye compares in a row is the capitals: a 13 px button label and a 14 px field's text look level when their
capitals' middles are, whatever their baselines. A design system whose labels and entries are wrapped in
`RawCapCenter` holds them on a row's centre line to half a device pixel.

A card's contents drift the same way across rows: a title at 16, rows' words at 26, a checkbox at 22, a chevron that
stops short of the switches above it. A keyline is the line what starts a row (or ends one) sits on. A design
system's card and section widgets put `RawKeylineRegion` around their content (it lays out and paints nothing,
and names any nested level the card means, such as words after an avatar), so ui_core_test's keyline check can read
every card on a screen; a face its pixels cannot show (one the colour of the ground, a pane of glass), or a picture
with things placed on it, wears `RawKeylineFace`. A gallery marks each section's column of examples with
`startAligned: true`.

## Who disposes what

A controller or focus node you pass in is yours to dispose: a behaviour never disposes what it is given. Each
parameter's documentation says what the behaviour does given none (most make their own, and dispose it).

## Libraries

- `package:ui_core/ui_core.dart`: the behaviours, motion, the words, a part's style (`RawStyle`), `RawCapCenter`, which centres a label
  by its capitals, `RawKeylineRegion`, which marks a card for the keyline check, and `RawKeylineFace`,
  which marks a face its pixels cannot show.
- `package:ui_core/host.dart`: the scaffold contract the look packages share. It is not meant for apps and leaves
  the package in a later minor version.
- `package:ui_core/inventory.dart`: the checklist of components an ordinary app expects from a design system, and
  `RawInventoryGallery`, which lists a design system's answers to it. A design system's own tests and gallery
  use it; an app does not.
- The checks (`package:ui_core/alignment.dart` until 0.2) are `package:ui_core_test/ui_core_test.dart`, a package
  of their own.

## Requirements and versions

ui_core needs Flutter 3.47 or later (Dart 3.13), and depends on Flutter alone.

Consult the CHANGELOG for migration instructions between minor releases. The main library is the supported API for apps. `host.dart` and `inventory.dart` are intended for design-system authors and may change in a patch release.

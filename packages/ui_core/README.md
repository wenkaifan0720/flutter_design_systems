# ui_core

Headless controls for Flutter design systems. The package handles input, keyboard navigation, focus and accessibility.
Your widget builders draw each state using your design system's shapes, colours and typography.

The look packages built on it (`comic_ui`, `fluent2_design_ui`, `frosted_ui`, `neumorphism_ui` and the rest) re-export
it, so an app that uses a look rarely imports it directly. Add it to build a look of your own:

```yaml
dependencies:
  ui_core: ^0.8.8
```

```dart
import 'package:ui_core/ui_core.dart';
```

The [component docs](https://wenkaifan0720.github.io/flutter_design_systems/docs/) show each behaviour drawn by the
looks built on it; the API reference is on pub.dev.

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
| Swipe actions | `RawSwipeActions`; `RawSwipeActionsSemantics` inside a row's own semantics node | `Dismissible` |
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
| Adaptive shell (a bar, a rail, a sidebar or a header) | `RawAdaptiveShell`, `RawWindowSizeClass`, `RawNavigationMode` | `NavigationBar`, `NavigationRail`, `NavigationDrawer` |
| List and detail | `RawListDetail` | |
| Wheel picker | `RawPicker`, `RawPickerColumn` | `CupertinoPicker` |
| Dialog and sheet actions | `RawActionBar` | `OverflowBar` |
| Date and time fields | `RawDateField`, `RawTimeField`, `RawTimeOfDay` | `InputDatePickerFormField`, `TimeOfDay` |
| Number field | `RawNumberField` | `TextField` with `keyboardType: number` |
| Rating | `RawRating` | (none) |
| Charts | `RawChart`, `RawPieChart`, `RawChartTable`; `RawLinearScale`, `RawTimeScale`, `RawBandScale` | (none) |
| Chips and tags under the touch floor | `RawChipGroup` | `Wrap` |
| A look's named palettes, for an app's palette picker | `RawNamedPalette` | (none) |
| A palette's colours (readable tones, a filled control's colour and ink, tinted grounds) | `RawPalette`, `RawAccentRule`, `RawNeutralTones`, `RawHct` | `ColorScheme.fromSeed` |

They are built from `RawButton` (a press, focus, hover and semantics on any widget) and `RawValueHandle`
(a value dragged or stepped with the keys). Each class's documentation has an example.

A press on a handle, or on a look's track that drags it, takes the focus without showing it, so the arrows after it
move that slider, as a browser's range input does; a press on `RawRangeSlider`'s track focuses the thumb it moves.

A slider's value reaches a screen reader as a whole percentage of its range ("23%" for 12 of 52), as Material's
`Slider` says it. Where the number means something of its own, pass `semanticFormatterCallback` (on
`RawValueHandle` and `RawRangeSlider`, as on Material's `Slider`): `(value) => '${value.round()} books'` says
"12 books", and the values Increase and Decrease would reach in the same words. A look's slider passes it through.

## A look's app shell

A look offers one app shell, on `RawAdaptiveShell.branches`, and paints all of its navigation through it at every
width: a bar along the bottom of a phone, a rail or a sidebar at the start of a wider window, or a header across the
top. The shell gives the destinations their keys (one tab stop, the arrows along them, F6 to the page), their
meaning to a screen reader (tabs in a tab bar, or the navigation menu) and their place; the look paints each
destination and lays them out. A phone bar built outside the shell loses all three. Each destination keeps its own
stack of pages; a page pushed on one keeps the rail, sidebar or header beside it while the bar steps away
(`hideBarOnPush`, or keep the bar under it as Cupertino's tab scaffold does), and back pops it. Only a page route
counts: a popup over the page (a menu, a select's list, a date picker, a dialog, a sheet) leaves the bar and the
page's footer where they are. Toasts keep clear of the bar, and centre on the page beside a rail or a sidebar.

```dart
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

class InkAppShell extends StatefulWidget {
  const InkAppShell({
    super.key,
    required this.destinations,
    required this.branches,
  });

  final List<RawNavigationDestination> destinations;

  /// Each destination's first page.
  final List<WidgetBuilder> branches;

  @override
  State<InkAppShell> createState() => _InkAppShellState();
}

class _InkAppShellState extends State<InkAppShell> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    return RawAdaptiveShell.branches(
      destinations: widget.destinations,
      branches: widget.branches,
      selectedIndex: _selected,
      onDestinationSelected: (index) => setState(() => _selected = index),
      // A bar under 600, a rail to 1024, a sidebar from there.
      modeForWidth: (width) =>
          RawNavigationMode.fromWidth(width, sidebar: 1024),
      destinationBuilder: (context, destination, details) {
        final selected = details.states.contains(WidgetState.selected);
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            destination.label,
            style: TextStyle(
              color: selected
                  ? const Color(0xFF2563EB)
                  : const Color(0xFF334155),
            ),
          ),
        );
      },
      navigationBuilder: (context, details) => switch (details.mode) {
        RawNavigationMode.bar || RawNavigationMode.top => SafeArea(
          child: Row(
            children: [
              for (final destination in details.destinations)
                Expanded(child: destination),
            ],
          ),
        ),
        RawNavigationMode.rail || RawNavigationMode.sidebar => SizedBox(
          width: details.mode == RawNavigationMode.rail ? 80 : 240,
          child: SafeArea(child: Column(children: details.destinations)),
        ),
      },
    );
  }
}
```

A page pushes onto its own destination's stack with `Navigator.of(context).push`; a page pushed on the app's root
navigator (`Navigator.of(context, rootNavigator: true)`) covers the whole shell, as a full-screen editor does.

A change of destination switches at once, as Material's `NavigationBar` over an `IndexedStack` does. A look whose
design moves between destinations gives `transitionBuilder` (and `transitionDuration`): it gets each branch's coming
in (`animation`) and going out (`secondaryAnimation`), as a page route's transition does. Both branches are painted
only while it runs, the one going out taking no pointer, focus or screen reader, and reduced motion switches at once.

Toasts come from one `RawToaster` above the app's navigator (in `WidgetsApp.builder`, `MaterialApp.builder`, or the
look's host there), raised with `RawToaster.of(context).show(RawToast(...))` (or the look's `show…Toast`) from
anywhere under it, a destination's page included. Being above every destination's navigator, a toast raised on one
destination stays through a switch to another. The shell keeps its bar, header and rail clear of toasts; a look's
screen keeps its footer clear; an app's own footer wraps it, with its padding, in `RawToasterKeepClear`, and a key
floating on the page's padding takes `edge: RawKeepClearEdge.bottom`. A toast raised into a navigator's overlay
instead lives and dies with that navigator: it goes when its destination is switched away, and it does not know the
bars.

A sheet opened over the shell stands on the shell's bar only. A bottom sheet on the root navigator
(`RawBottomSheetRoute`) ends at the top of the bar and covers a page's footer, one kept clear for toasts on the bar
or one at the screen's foot on a pushed page with the bar gone; a side sheet (`RawSideSheetRoute`) runs down to it;
the bar keeps the bottom inset under them, and their barrier covers it, so a tap on the bar closes the sheet. A
keyboard taller than the bar lifts a bottom sheet over it; a key floating with `edge: RawKeepClearEdge.bottom` does
not. A sheet on a destination's own navigator stands above the bar already. A full-screen sheet (`RawSheetRoute`)
and a dialog cover the bar.

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

A part shows its focus as a browser's `:focus-visible` decides: after a key, not after a press or a click, until the next key. A look's own pressable on a bare `FocusableActionDetector` shows it the same way through `RawFocusShown`, given the detector's `onFocusChange`; Flutter's highlight mode alone, which a mouse leaves traditional, keeps a ring on a row a click focused, and the detector's `onShowFocusHighlight` never comes on a touch platform once a mouse has connected before any input (Flutter reads the mode as the detector is built).

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
/// The look's push: the page fades in over the one under it.
class ComicPageTransitionsBuilder extends PageTransitionsBuilder {
  const ComicPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => FadeTransition(opacity: animation, child: child);
}

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
import 'package:material_ui/material_ui.dart';

Widget comicApp({required Widget home}) => MaterialApp(
  theme: ThemeData(
    pageTransitionsTheme: const PageTransitionsTheme(builders: comicPageTransitions),
  ),
  home: home,
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
itself (Cancel, Close, Today, Next month, Select date, "2 of 5", "3 items selected"), under `MaterialLocalizations`' names where
Flutter has the word: a look reads them from `RawWidgetsLocalizations.of(context)` rather than writing English. English
is the default, with nothing to set up under `MaterialApp`, `CupertinoApp` or `WidgetsApp`.

ui_core speaks 30 languages (`RawWidgetsLocalizations.supportedLocales`): its dates, plurals and digits come from
Unicode CLDR, as Flutter's do, and its words are Material's own translations where Material has the word. Opt in
with its delegate beside Flutter's, from `flutter_localizations` (add `flutter_localizations: sdk: flutter` to your
pubspec):

```dart
import 'package:flutter_localizations/flutter_localizations.dart';

const localizationsDelegates = [
  RawWidgetsLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
];
const supportedLocales = RawWidgetsLocalizations.supportedLocales;
```

Pass them to your app's `localizationsDelegates` and `supportedLocales` (`WidgetsApp`, `CupertinoApp` or
`MaterialApp`). `GlobalWidgetsLocalizations` gives Arabic, Hebrew, Persian and Urdu their direction. A Material app
adds `material_ui`'s `GlobalMaterialLocalizations.delegates` too (the Material, Cupertino and Widgets delegates for
your app's own Flutter widgets), without which a Material `TextField` under a language other than English asserts.
A look supplies its own Material and Cupertino words in the app's language: it is drawn with `material_ui` and
`cupertino_ui`, whose words are types of their own, and loads them itself. A locale ui_core does not speak gets English. For a language of your own, or
words of your own, extend `DefaultRawWidgetsLocalizations`, override the words you translate, and add a delegate for
your subclass to `localizationsDelegates`; a word added in a later version then stays English until you
translate it. A date or time picker's title (`datePickerHelpText`, `timePickerDialHelpText`) is read through
`RawPickerWords` and overridden in the same subclass. `RawWidgetsLocalizations` also says the day a week starts on (`firstDayOfWeek`), which a calendar follows unless told
otherwise.

For number and chart labels, use `formatDecimal`, `parseDecimal` and `formatPercent`. Date and time controls use the locale’s calendar order, digits, separators and first day of the week.

Dates follow the app's locale as `MaterialLocalizations`' do. English writes the month first, as American English
does ("Nov 9, 2026", a date field's M/d/y), with or without the delegate. The English of a region Material speaks
(Australia, Canada, Britain, Ireland, India, New Zealand, Singapore, South Africa) writes its own: British English
"9 Nov 2026" and dd/MM/y, its week from Monday, its time on a 24-hour clock. Flutter resolves a device's locale to one
the app lists, so an app that serves a region lists it:
`[...RawWidgetsLocalizations.supportedLocales, Locale('en', 'GB')]`.

To write dates one way of your own, whatever the locale, extend `DefaultRawWidgetsLocalizations`, override
`formatMediumDate` and `dateFieldPattern` together (a shown day and a typed one in one order), and list your
delegate first in `localizationsDelegates`:

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// The app's English dates: the day first, in every region.
class AppWords extends DefaultRawWidgetsLocalizations {
  const AppWords();

  @override
  String formatMediumDate(DateTime date) =>
      '${date.day} ${formatShortMonth(date)} ${date.year}';

  @override
  String get dateFieldPattern => 'dd/MM/y';
}

/// Loads [AppWords] for English; other languages fall to the next delegate.
class AppWordsDelegate extends LocalizationsDelegate<RawWidgetsLocalizations> {
  const AppWordsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'en';

  @override
  Future<RawWidgetsLocalizations> load(Locale locale) =>
      SynchronousFuture<RawWidgetsLocalizations>(const AppWords());

  @override
  bool shouldReload(AppWordsDelegate old) => false;
}

const appDelegates = [
  AppWordsDelegate(),
  RawWidgetsLocalizations.delegate,
];
```

## A look's palette

People name a palette (navy and white, black and gold, a pastel), and a look's own colour API takes it in its own
words. `RawPalette` gives that API its numbers in HCT, the colour space `ColorScheme.fromSeed` builds its
tones in: `readableTone` walks a colour in its own hue until it reads on every ground it is painted on,
`accentFill` gives a filled control's colour and its label's ink (the ink following the brightness, as Material's
on-primary does, or keeping the named colour as the fill, by `RawAccentRule`), and `RawNeutralTones` gives the tones of a tinted ground, a cream's night
a charcoal, never brown. ui_core_test's `DesignContrastCheck.sweep` reads a screen in each of the palettes people name
most, by day and by night.

```dart
const brand = Color(0xFF1B3A6B);
const page = Color(0xFFFFFFFF);
const panel = Color(0xFFF2F4F8);
final words = RawPalette.readableTone(brand, on: [page, panel]);
final button = RawPalette.accentFill(brand, brightness: Brightness.dark);
```

A look offers its palettes by name as `RawNamedPalette`s: an `id` the app stores, a `label` a picker shows, and a few
swatches by day and by night. An app builds its own picker from them:

```dart
Widget paletteRow(RawNamedPalette palette, Brightness brightness) => Row(
  children: [
    for (final colour in palette.swatchesFor(brightness))
      Padding(
        padding: const EdgeInsetsDirectional.only(end: 4),
        child: SizedBox.square(dimension: 16, child: ColoredBox(color: colour)),
      ),
    const SizedBox(width: 8),
    Text(palette.label),
  ],
);
```

## Shapes a look can open

A look may open its corners, its line weight and its depth to an app, as Material 3 opens its shape scale.
`RawShapeScheme` holds three things:

- a `RawCornerScale`: a radius per step (none, extra small, small, medium, large, extra large and full, with Material
  3's numbers by default) and one `RawCornerStyle` for every corner (round, continuous, bevel, notch, step or
  concave);
- a `stroke`;
- a `depth`.

A null `stroke` or `depth` is "not opened": the look draws its own constant.

`RawCornerBorder` is the `ShapeBorder` a style draws:

- A round corner at rest draws and clips as an `RRect`, Flutter's fast path.
- A `ShapeBorderTween` between two styles morphs the corner. Flutter's borders of two kinds switch halfway instead.
- `inset` gives the face inside a frame with its corners concentric, and `outset` gives a focus ring's outline
  around it.

A look holds every scheme to its design with a `RawShapeLimits`: the styles it allows and a `RawBand` per value, so
an app's "rounder" never breaks the look. In debug, a value held is printed once.

A look puts the scheme on its theme data, holds it to its limits there, and lerps it in its theme's lerp. Its theme's
API stays its own. A sketch:

```dart
class InkThemeData {
  /// Ink's theme, the app's [shapeScheme] held to Ink's limits.
  InkThemeData({RawShapeScheme shapeScheme = const RawShapeScheme()})
    : shapeScheme = shapeLimits.clamp(shapeScheme, look: 'Ink');

  const InkThemeData._(this.shapeScheme);

  /// Ink's design: round or continuous corners, a medium corner from 8 to
  /// 16, a stroke from 1 to 2, no depth.
  static const shapeLimits = RawShapeLimits(
    styles: {RawCornerStyle.round, RawCornerStyle.continuous},
    medium: RawBand(8, 16),
    stroke: RawBand(1, 2),
  );

  final RawShapeScheme shapeScheme;

  /// A card's outline.
  ShapeBorder get card => shapeScheme.corners.border(RawCorner.medium);

  /// Between two held themes, not held again: a spring may pass a band's
  /// end for a moment.
  static InkThemeData lerp(InkThemeData a, InkThemeData b, double t) =>
      InkThemeData._(RawShapeScheme.lerp(a.shapeScheme, b.shapeScheme, t));
}
```

### A part's own corners

An app can give one part its own corners, such as two diagonal corners cut and the other two square, or only the
top start one cut. A style's `corners` names a step per corner (`RawCorners`), and a corner it leaves out keeps the
part's own. The corners are steps of the look's scale, not lengths, so they follow the theme and stay in its bands.
Start and end mirror in a right-to-left app.

A look lets them through as far as its design allows, set by `cornerFreedom` on its `RawShapeLimits`:

- `fixed` (the default): the part keeps its own corners, and debug says the override was ignored.
- `uniform`: one step on every corner.
- `perCorner`: a step for each corner.

`cornerSteps` narrows the steps a corner may take. One corner style still shapes the whole border. A style's
`shape` wins over its `corners`: it takes any border as given, as Material's `ButtonStyle.shape` does, outside the
look's limits.

```dart
// An app: a card with two diagonal corners cut, the others square.
const cut = RawStyle(
  corners: WidgetStatePropertyAll(
    RawCorners(topEnd: RawCorner.none, bottomStart: RawCorner.none),
  ),
);

// A look's card: the corners given, held to the look's limits, drawn in its
// scale. The default card (no override) keeps its medium step.
ShapeBorder cardShape(
  RawShapeScheme scheme,
  RawShapeLimits limits,
  RawStyle? style,
) {
  final look = RawStyleOf([style], const {});
  final corners = limits.clampCorners(
    look.corners,
    base: const RawCorners.all(RawCorner.medium),
    look: 'Ink',
  );
  return look.shape ?? scheme.corners.borderOf(corners);
}
```

A theme's lerp switches `corners` halfway, as `ButtonStyle.lerp` does with what it cannot blend. A part whose design
moves its shapes morphs the border it resolves to (a `ShapeBorderTween`), so the corners move each frame.

## A look's forms

A form is one column of fields, and every field in it takes the column's width: a text entry, a select, a date field,
a segmented choice and a slider's track all reach the column's edges, as Material's form fields do. A select or a date
field hugs its value only on its own, in a toolbar or a filter row. The column keeps a measure (at most 720 wide on a
screen 600 or wider) and one gap between its fields, on the look's spacing grid. Inside each field,
`RawInputDecorator`'s builder places the label, the control and the help or the error under it, so the rhythm is the
field's, not each screen's. `RawForm` and `RawFormField` validate any control as a `TextFormField` does, and
`RawWidgetsLocalizations.formatMediumDate` shows a chosen day ("Mar 3, 2025" in English, "3 Mar 2025" in British
English: with the year, in the locale's order)
wherever a field or a list shows one. An optional date is a picker whose value is `DateTime?` and whose `onChanged`
takes null: its calendar opens with no day struck (`RawCalendarController(selectedDate: null)`), its Done commits
`selectedDate` (null when none was struck, never the keyboard's day), and its Clear calls `controller.clear()` and
`onChanged(null)`; `RawDateField` empties with Backspace and reports null.

```dart
import 'package:flutter/widgets.dart';

/// The column a form's fields stand in, each at the column's width.
class InkFormColumn extends StatelessWidget {
  const InkFormColumn({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.topStart,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 720),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: children,
      ),
    ),
  );
}
```

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
sit on 2 pt declares 2), read by `RawSpacing.of`.

## Testing your design system

Add `ui_core_test` to your test dependencies to check rendered screens for what is wrong in any design: roles and
names, radio groups, tap targets, cursors, labels centred on their faces, clipped words, cut shadows, contrast, and the
room a label keeps from its face's edges. Mark a visible face that blends into its background with `RawKeylineFace`,
so the checks read it as a face. [ui_core_test on pub.dev](https://pub.dev/packages/ui_core_test)

## Lining controls up

Controls that share a line drift apart in ways no one control's test sees: two controls of "the same size" a few
pixels apart, a label a pixel low, a field that shrinks on desktop. ui_core_test's label check finds a label off its
face's centre from the drawn pixels (its README says how it reads a screen). What keeps a line straight:
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
and names any nested level the card means, such as words after an avatar), so a test can read every card's keylines
on a screen; a face its pixels cannot show (one the colour of the ground, a pane of glass), or a picture with things
placed on it, wears `RawKeylineFace`. A page that shows examples in a column marks each section with
`startAligned: true`.

## Who disposes what

A controller or focus node you pass in is yours to dispose: a behaviour never disposes what it is given. Each
parameter's documentation says what the behaviour does given none (most make their own, and dispose it).

## Libraries

- `package:ui_core/ui_core.dart`: the behaviours, motion, the words, a part's style (`RawStyle`), the shapes a look opens (`RawShapeScheme`, `RawCornerBorder`, `RawShapeLimits`), `RawCapCenter`, which centres a label
  by its capitals, `RawKeylineRegion`, which marks a card's keylines, and `RawKeylineFace`,
  which marks a face its pixels cannot show.
- `package:ui_core/host.dart`: the scaffold contract the look packages share, for design-system authors. It is
  not meant for apps.
- `package:ui_core/inventory.dart`: the checklist of components an ordinary app expects from a design system, and
  `RawInventoryGallery`, which lists a design system's answers to it. A design system's own tests and example
  use it; an app does not.
- The checks are `package:ui_core_test/ui_core_test.dart`, a package of their own.

## Requirements and versions

ui_core needs Flutter 3.47 or later (Dart 3.13), and depends on Flutter alone.

Consult the CHANGELOG for migration instructions between minor releases. The main library is the supported API for apps. `host.dart` and `inventory.dart` are intended for design-system authors and may change in a patch release.

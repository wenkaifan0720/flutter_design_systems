# terminal_ui

Terminal widgets for Flutter: an app drawn on a character grid, with box-drawn panes, bracketed buttons, inverse
selection and keys beside every action.

![slipway, the example deploy console: home at a desk by night beside a new deploy on a phone on paper](https://raw.githubusercontent.com/wenkaifan0720/flutter_design_systems/main/packages/terminal_ui/screenshots/hero.png)

**[Docs and demo](https://wenkaifan0720.github.io/flutter_design_systems/docs/looks/terminal/)** ·
[Try it in Stint](https://wenkaifan0720.github.io/flutter_design_systems/docs/stint/?look=terminal) ·
[API reference](https://pub.dev/documentation/terminal_ui/latest/) ·
[All the looks](https://wenkaifan0720.github.io/flutter_design_systems/docs/)

## Getting started

```sh
flutter pub add terminal_ui material_ui
```

Load the bundled monospace fonts before the first frame. Wrap the app in
`TermTheme` to set its palette and grid. This example uses `material_ui`
for the app shell.

```dart
import 'package:material_ui/material_ui.dart';
import 'package:terminal_ui/terminal_ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await termLoadFonts();
  runApp(
    MaterialApp(
      // Your routes change screens as a terminal does (see Page motion).
      theme: ThemeData(
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: termPageTransitions,
        ),
      ),
      builder: (context, child) =>
          TermTheme(data: TermThemeData.dark(), child: child!),
      home: const Deploy(),
    ),
  );
}

class Deploy extends StatelessWidget {
  const Deploy({super.key});

  @override
  Widget build(BuildContext context) => TermPane(
    title: 'new deploy',
    child: TermButton.filled(label: 'deploy', onPressed: () {}),
  );
}
```

### CupertinoApp and WidgetsApp

`TermTheme` goes in the builder of any app widget. With `CupertinoApp`
from `cupertino_ui`:

```dart
CupertinoApp(
  builder: (context, child) =>
      TermTheme(data: TermThemeData.dark(), child: child!),
  home: const Deploy(),
)
```

With Flutter's `WidgetsApp`, give it Terminal's page route:

```dart
WidgetsApp(
  color: const Color(0xFF000000),
  builder: (context, child) =>
      TermTheme(data: TermThemeData.dark(), child: child!),
  pageRouteBuilder: <T>(settings, builder) =>
      TermPageRoute<T>(settings: settings, builder: builder),
  home: const Deploy(),
)
```

### Page motion

Terminal routes open with a brief fade and pop with a cut. Tabs and side
panes switch in place. Set `pageTransitionsTheme` on the app's
`ThemeData`, as in the example above, to give routes pushed by its
navigator the same transition. Alternatively, push a `TermPageRoute`
to use the transition for one route.

The iOS transition supports the swipe from the leading edge. On Android,
Back first dismisses an open menu, list or popover.

## The look

Flutter widgets drawn the way a well-made terminal program draws itself:
every size whole character cells, panes in box-drawing lines with their
titles cut into the top line, buttons in brackets, the chosen row in
inverse video, the keyboard's focus as the cursor, and the key for every
action written beside it. A sixteen
colour palette in a night and a paper preset, a monochrome theme, and
everything you need to reach it by touch, pointer, keyboard and screen
reader.

```
┌─ runs ─────────────────────────────── 3 ─┐
│ ⠹ #1482 atlas-api                    now │
│ ✗ #1481 atlas-api                 3m 02s │
│ ✓ #911  web-console               4m 31s │
└─ ⏎ open ─────────────────────────────────┘
  [ cancel ] esc   [ deploy ] ⏎
```

## Screens

The example app, slipway, is a made-up deploy console built only from these
widgets.

![The runs, the failing run and its log tiled at a desk, paper preset](https://raw.githubusercontent.com/wenkaifan0720/flutter_design_systems/main/packages/terminal_ui/screenshots/runs-1440-paper.png)

![The command palette over the runs, night preset](https://raw.githubusercontent.com/wenkaifan0720/flutter_design_systems/main/packages/terminal_ui/screenshots/palette-1440-night.png)

![A run's change as a side-by-side diff, paper preset](https://raw.githubusercontent.com/wenkaifan0720/flutter_design_systems/main/packages/terminal_ui/screenshots/diff-1440-paper.png)

<p>
  <img src="https://raw.githubusercontent.com/wenkaifan0720/flutter_design_systems/main/packages/terminal_ui/screenshots/run-390-night.png" width="320" alt="One failing run on a phone, night preset">
</p>

## What's inside

Every component an ordinary app expects, each drawn in the grid and each
on `ui_core`'s behaviour where it has one: 84 of the 89 in `ui_core`'s
inventory (`termInventory` lists them; the five it leaves out would move
the structure or leave the grid).

- **Panes** (`TermPane`, `TermPane.list`): the look's card, group and
  window. The line doubles in the accent while focus is inside.
- **Actions**: `TermButton` (and `.filled`), `TermIconButton`,
  `TermButtonGroup`, `TermToggleGroup` (a segmented control too),
  `TermSplitButton`, `TermLink`, `TermKey`.
- **Fields**: `TermTextField` (a text area with `lines:`, add-ons with
  `prefixText`/`suffixText`), `TermPasswordField`, `TermOtpField`,
  `TermNumberField`, `TermSelect`, `TermCombobox`, `TermTagInput`,
  `TermFileField`, `TermDatePicker`, `TermDateRangePicker`,
  `TermTimeField`, `TermCalendar`, `TermColorPicker`.
- **Choices and ranges**: `TermCheckbox`, `TermRadio`, `TermSwitch`,
  `TermChip`, `TermSlider`, `TermRangeSlider`, `TermRating`, `TermMeter`.
- **Rows and collections**: `TermListTile`, `TermSectionHeader`,
  `TermTable`, `TermDataTable`, `TermTree`, `TermDisclosure`,
  `TermReorderableList`, `TermPullToRefresh`, `TermTimeline`,
  `TermDescriptionList`, `TermTag`, `TermBadge`, `TermAvatar`,
  `TermMedia`, `TermDivider`, `TermScrollArea`, `TermSplitView`.
- **Navigation**: `TermScaffold` (a phone's window list, a tablet's rail,
  a desk's side pane), `TermTopBar`, `TermTabBar`, `TermNavigationBar`,
  `TermNavigationRail`, `TermSideBar`, `TermStatusLine`,
  `TermBreadcrumb`, `TermPagination`, `TermPageDots`, `TermSteps`,
  `TermMenuBar` and `TermCommandPalette`.
- **Over the screen**: `TermDialog`, the y/N question
  `showTermConfirmDialog` (with a typed guard for destroying things),
  `showTermSheet`, `showTermSideSheet`, `showTermActionSheet`,
  `TermPopover`, `TermHoverCard`, `TermTooltip`, `TermMenu`,
  `TermContextMenu` (a right click, a long press or Shift+F10), toasts
  through `TermToaster`, `TermBanner`, and screens through
  `TermPageRoute`. A screen change is a cut or a very short fade and a
  menu opens where it stays: nothing travels into place.
- **Working and states**: `TermSpinner` (braille), `TermProgressBar`
  (blocks in eighths of a cell), `TermSkeleton`, `TermStatusView`,
  `TermEmptyState`, `TermCaret`.
- **Charts**: `TermLineChart` and `TermAreaChart` in braille dots,
  `TermBarChart` and `TermSparkline` in blocks.
- **Foundations**: `TermThemeData` (`.dark()`, `.light()`,
  `.monochrome()`, `.preset(id, brightness)`, `.from(palette)`), `TermPalette`, `TermAnsi`,
  `TermGrid`, `TermFace`, and `termKeyLabel` for writing shortcuts.

## Make it yours

Six palettes come with it, each by day and by night: `standard` (Terminal's
own night and paper, a cyan accent), `harbor` (a navy screen, a blue
accent), `dusk` (a plum screen, a magenta accent), and three in one ink, as a
monochrome terminal draws: `mono`, `phosphor` (green) and `amber`.
`TermThemeData.presets` lists them:

```dart
TermTheme(
  data: TermThemeData.preset('amber', MediaQuery.platformBrightnessOf(context)),
  child: child,
)
```

Every part takes a `style:` (a `TermStyle`) over its slot in
`TermThemeData`: one slot a part, and one a kind of button. A style sets
colours (and a weight, on parts with words of their own); sizes stay
whole cells and lines, so a style can't take the look off its grid.

```dart
final base = TermThemeData.dark(
  // Your brand's colour; the theme steps it until it reads at 4.5:1.
  accent: const Color(0xFF0A7D4F),
);

final theme = base.copyWith(
  // Every primary button.
  filledButtonStyle: TermStyle(
    fill: WidgetStatePropertyAll(TermAnsi.magenta.of(base.palette)),
    edge: WidgetStatePropertyAll(TermAnsi.magenta.of(base.palette)),
  ),
);

// One button.
TermButton(
  label: 'roll back',
  onPressed: rollBack,
  style: TermStyle(
    foreground: WidgetStatePropertyAll(theme.warning),
    edge: WidgetStatePropertyAll(theme.warning),
  ),
);
```

A brand colour that reads under 4.5:1 on the background or a surface is
stepped lighter (or darker, on paper) in its own hue until it does.
`TermThemeData` also takes a `face` (a monospace face and
its advance together) and a `stroke` (box drawing's light or heavy line);
`AnimatedTermTheme` animates a change. The painters and faces the parts
are drawn with (`TermFramePainter`, `TermBracketFace`, `TermCellFace`,
`TermMenuRow`, `TermSpring`, …) are public, for a part of your own in the
look.

The pointer over a part changes nothing by default: a terminal has no
hover, and the cursor already says what presses. Only the lit row of an
open menu or select follows it. Every style still sees
`WidgetState.hovered`, so a hover is one line away:

```dart
TermThemeData.dark().copyWith(
  listTileStyle: TermStyle(
    fill: WidgetStateProperty.fromMap({
      WidgetState.hovered: TermAnsi.blue.of(TermPalette.night).withValues(alpha: 0.2),
    }),
  ),
);
```

## The grid

Every width is whole cells and every height whole lines: a 15 px face on a
9 × 24 cell. The text scale grows the grid, so at 200% a cell is twice the
size and the lattice still holds. A control's target is one line under a
pointer and two under a finger.

## Accessibility

Box-drawing, braille and block glyphs are painted, not typed, and a screen
reader hears what they mean (a status's word, a spinner's "loading", a
bar's percentage) instead. Inverse selection is announced as selected. The
spinners and the caret hold still under Reduce Motion. Every tone has a
glyph (`✓ ✗ ! i`), so nothing is said by colour alone; the monochrome theme
proves it.

The keyboard's focus is the cursor: an accent block over the part, its
words and brackets cut out of it, hollow on a part already chosen or
filled, so chosen, pressed and focused read apart by shape in the
monochrome theme too. A text field shows the caret, its frame's one line
heavy in the accent, as Material's outline goes from 1 to 2 px; a doubled
line is a pane's, for the pane the keys are in. Focus shows for the
keyboard only, never after a click, and differs from the part at rest at
3:1 or more over at least a 2 px outline's area on every theme (a text
field's, a 1 px outline's beside its caret).

Tab visits a tab bar or navigation group once. Use the arrow keys to move
between destinations and F6 to switch between navigation and the page.
Tab visits a set of radios once too, on the chosen one, and so a
segmented control: the arrows move and choose (put sibling `TermRadio`s in
Flutter's `RadioGroup`, with ui_core's `RadioGroupKeyboardFix` round them).
Dialogs and sheets keep focus inside and return it to the opener on close.
On line and area charts, the arrows inspect data points. Ratings accept
arrow and number keys. Screen readers announce shortcuts such as `^K` as
“Ctrl+K”.

The navigation bar wraps its labeled destinations when space is tight.
A selected date range uses extra lines when necessary so both dates stay
visible at larger text sizes.

## Languages

Terminal's own words (a pager's "next page", a tag's "remove", a
confirmation's `proceed? [y/N]` and its keys, a file field's `browse`, a
refresh's `pull to refresh`, the palette's colour names) come from
`TermLocalizations`, in English, Arabic and German. Nothing needs setting
up: in an Arabic or German app they follow the app's locale, beside
ui_core's `RawWidgetsLocalizations`, whose words cover 30 languages. Words an
app passes, such as a dialog's `cancelLabel`, are its own; left at their
English defaults, they follow the locale too. For another language, extend
`DefaultTermLocalizations` and add a delegate for it to
`localizationsDelegates`.

In a right-to-left locale the layout mirrors: panes, keys, menus and
charts read from the right, and Hebrew draws in Liberation Mono on the
same grid.

Figures follow the locale as well, through `RawWidgetsLocalizations`: dates,
times, the number field and the charts (a bar's value, a chart's scale and
readout, a sparkline's reading) write the reader's digits and separators,
Arabic-Indic digits in Arabic and `2,5` in German.

## Requirements

Flutter 3.47.0 or later. Terminal runs on Android, iOS, the web, macOS,
Windows and Linux.

## Fonts

JetBrains Mono (SIL Open Font License 1.1) for the words, and Liberation
Mono (SIL Open Font License 1.1) for Hebrew, with the same advance so the
grid holds right to left. Their licences ship in `assets/fonts/LICENSES/`.

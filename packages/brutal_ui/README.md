# brutal_ui

Brutal is a neo-brutalist Flutter component library: square controls on a 4-pixel grid, 2-pixel rules, one flat colour
block a screen and hard shadows under what you can press. It includes adaptive navigation, forms, data displays and
charts. Six palettes, each designed for light and dark.

![Admit, a ticketing app on Brutal, at 1440 px by day beside the same app on a 390 px phone by night](https://raw.githubusercontent.com/wenkaifan0720/flutter_design_systems/main/packages/brutal_ui/screenshots/hero_admit.png)

**[Docs and demo](https://wenkaifan0720.github.io/flutter_design_systems/docs/looks/brutal/)** · [Try it in Stint](https://wenkaifan0720.github.io/flutter_design_systems/docs/stint/?look=brutal) · [API reference](https://pub.dev/documentation/brutal_ui/latest/) · [All the looks](https://wenkaifan0720.github.io/flutter_design_systems/docs/)

## Install

```sh
flutter pub add brutal_ui material_ui lucide_icons_flutter
```

A whole app: Brutal's face loaded, `BrutalHost` over the app, one page and one button.

```dart
import 'package:brutal_ui/brutal_ui.dart';
import 'package:material_ui/material_ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await brutalLoadFonts();
  runApp(MaterialApp(
    builder: (context, child) => BrutalHost(child: child!),
    home: BrutalScreen(body: BrutalButton.filled('Buy tickets', onPressed: () {})),
  ));
}
```

`material_ui` is Flutter's Material as a package, as it is from Flutter 3.50; import it, not
`package:flutter/material.dart`. `brutal_ui.dart` exports none of Flutter's libraries, so a file imports
`material_ui` (or `package:flutter/widgets.dart`) beside it. An app on `CupertinoApp` adds `cupertino_ui`; one on
`WidgetsApp` needs only `brutal_ui`. Brutal's parts draw Lucide's glyphs; `lucide_icons_flutter` gives an app the
rest of them as `LucideIcons`, for any part that takes an `IconData` (an app with glyphs of its own can leave it out).
Brutal bundles its face, Space Grotesk: `brutalLoadFonts` loads it before the first frame, so the web never shows a
fallback.

## Mount BrutalHost

`BrutalHost` is the one mount an app needs, in its app's `builder`, above the navigator: Brutal's theme by day and by
night, the palette, the page's ground and the toasts. Its `brightness` is light, dark, or null for the platform's
setting; its `palette` is one of `BrutalThemeData.palettes`. A new appearance or palette blends: every colour of the
page lerps to it. Dialogs and sheets need no mount of their own: each rises on the navigator's overlay in the theme it
was raised in. Your navigator, routes and localizations stay yours.

```dart
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) => BrutalScreen(
    topBar: const BrutalAppBar(title: 'Tonight'),
    body: BrutalButton.filled('Buy tickets', onPressed: () {}),
  );
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  // Null follows the platform's light or dark setting.
  Brightness? brightness;
  RawNamedPalette palette = BrutalThemeData.palettes.first;

  @override
  Widget build(BuildContext context) => MaterialApp(
    builder: (context, child) => BrutalHost(
      brightness: brightness,
      palette: palette,
      child: child!,
    ),
    home: const HomePage(),
  );
}
```

A pushed page slides 24 px in from the trailing edge. `BrutalHost` (its `BrutalTheme`) gives material_ui's `Theme`
the slide unless your theme chose another, so a `MaterialPageRoute` your app pushes on material_ui's `MaterialApp`
slides already. On Flutter's own `MaterialApp` (`package:flutter/material.dart`, deprecated from Flutter 3.50) a
`MaterialPageRoute` reads Flutter's `Theme`, which Brutal doesn't reach, unless that theme carries
`brutalPageTransitions`: `theme: ThemeData(pageTransitionsTheme: const PageTransitionsTheme(builders:
brutalPageTransitions))`. On iOS a page still pops with a swipe from the screen's leading edge.

With `CupertinoApp`, or with `WidgetsApp` for an app with no Material or Cupertino at all:

```dart
import 'package:cupertino_ui/cupertino_ui.dart';

CupertinoApp(
  builder: (context, child) => BrutalHost(child: child!),
  home: const HomePage(),
);
```

```dart
WidgetsApp(
  color: const Color(0xFF000000),
  builder: (context, _) => const BrutalHost(child: HomePage()),
);
```

`BrutalTheme` alone restyles a part of the tree:
`BrutalTheme(data: BrutalThemeData.preset('zine', Brightness.dark), child: ...)`.

## Build an app

The example, `example/lib/main.dart`, is this app in one file to copy: a shelf of books in three places.

**A list and its page.** A page is a `BrutalScreen`: its top bar, then its body in the page's margins, no wider than
1200, and an optional footer fixed on a rule at its foot. A list is a group of ruled rows; a row pushes its page with
Flutter's own route, and the pushed page's bar has its way back (Escape and the back gesture pop it too). A row's
name reads its tag: "Piranesi, Susanna Clarke, To read".

```dart
class BookPage extends StatelessWidget {
  const BookPage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => BrutalScreen(
    topBar: BrutalAppBar(title: title, leading: BrutalAppBar.autoLeading(context)),
    body: Text('Started ${BrutalFormat.date(DateTime(2026, 10, 2))}'),
  );
}

class BooksPage extends StatelessWidget {
  const BooksPage({super.key});

  @override
  Widget build(BuildContext context) => BrutalScreen(
    topBar: const BrutalAppBar(title: 'Books'),
    body: BrutalListGroup(
      children: [
        for (final title in ['Piranesi', 'Stoner'])
          BrutalListTile(
            title: title,
            trailing: const BrutalTag('To read'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (context) => BookPage(title: title)),
            ),
          ),
      ],
    ),
  );
}
```

**A dialog: pop it with the answer.** A dialog stands on its hard shadow. Its actions pop the route with the answer,
which `showBrutalDialog` returns; Escape, the barrier and the back gesture return null. Focus goes back where it was.
A toast says what happened.

```dart
Future<void> confirmRemove(BuildContext context, String title) async {
  final remove = await showBrutalDialog<bool>(
    context: context,
    builder: (context) => BrutalDialog(
      title: 'Remove $title?',
      content: const Text('It leaves your shelf. You can add it again.'),
      actions: [
        BrutalDialogAction(label: 'Keep', onPressed: () => Navigator.of(context).pop(false)),
        BrutalDialogAction(
          label: 'Remove',
          isDestructiveAction: true,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    ),
  );
  if (remove == true && context.mounted) showBrutalToast(context, 'Removed $title');
}
```

**A form.** `RawForm` (ui_core's, exported with brutal_ui) checks every field's `validator` on submit, as Flutter's
`Form` does with `TextFormField`: each error shows under its field in red, the first wrong field takes the focus and
a screen reader hears how many need attention; after that the errors follow the typing. Every field takes its
column's width, so a form stands on one edge; `BrutalDatePicker` raises the calendar and writes the day as
`BrutalFormat.date` does ("14 Nov 2026").

```dart
class AddBookPage extends StatefulWidget {
  const AddBookPage({super.key});

  @override
  State<AddBookPage> createState() => _AddBookPageState();
}

class _AddBookPageState extends State<AddBookPage> {
  final form = GlobalKey<RawFormState>();
  DateTime? started;

  @override
  Widget build(BuildContext context) => BrutalScreen(
    topBar: const BrutalAppBar(title: 'Add a book'),
    body: RawForm(
      key: form,
      onSubmit: () => showBrutalToast(context, 'Added'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: BrutalSpacing.large,
        children: [
          BrutalTextField(
            labelText: 'Title',
            validator: (value) => (value ?? '').trim().isEmpty ? 'Enter the title' : null,
          ),
          BrutalDatePicker(
            labelText: 'Started',
            hintText: 'Not yet',
            value: started,
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
            onChanged: (day) => setState(() => started = day),
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: BrutalButton.filled('Save', onPressed: () => form.currentState!.submit()),
          ),
        ],
      ),
    ),
  );
}
```

**Settings: the palette picker.** `BrutalThemeData.palettes` are the six palettes as ui_core's `RawNamedPalette`: an
`id` to store, a `label` to show, and `swatchesFor(brightness)`, its colours by day or by night. Show each palette's
swatches beside its name, a row each, and give the chosen one to `BrutalHost(palette: ...)`.

```dart
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.palette, required this.onPalette});

  final RawNamedPalette palette;
  final ValueChanged<RawNamedPalette> onPalette;

  @override
  Widget build(BuildContext context) {
    final brightness = BrutalTheme.of(context).colors.brightness;
    return BrutalScreen(
      topBar: const BrutalAppBar(title: 'Settings'),
      body: BrutalListGroup(
        children: [
          for (final option in BrutalThemeData.palettes)
            BrutalListTile(
              leading: Swatches(option.swatchesFor(brightness)),
              title: option.label,
              selected: option.id == palette.id,
              showChevron: false,
              onTap: () => onPalette(option),
            ),
        ],
      ),
    );
  }
}

/// A palette's colours side by side in one square, ruled in the row's ink.
class Swatches extends StatelessWidget {
  const Swatches(this.colors, {super.key});

  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    final glyph = IconTheme.of(context);
    return SizedBox.square(
      dimension: glyph.size ?? 24,
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(border: Border.all(color: glyph.color!, width: 2)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [for (final color in colors) Expanded(child: ColoredBox(color: color))],
        ),
      ),
    );
  }
}
```

**The places: `BrutalAppShell`.** On a phone the places are the bar at the foot; from 600 wide a rail down the start;
from 1024 wide the side list, with the app's `brand` at its head. `.branches` keeps a stack for each place: a pushed
page keeps the rail or the side list while the bar steps away, and back pops it. An `action` (`BrutalShellAction`)
stands over a root page's bottom end. A screen reader hears the places as tabs.

```dart
import 'package:lucide_icons_flutter/lucide_icons.dart';

class Shelf extends StatefulWidget {
  const Shelf({super.key});

  @override
  State<Shelf> createState() => _ShelfState();
}

class _ShelfState extends State<Shelf> {
  int place = 0;

  @override
  Widget build(BuildContext context) => BrutalAppShell.branches(
    brand: 'Shelf',
    tabs: const [
      BrutalTab(LucideIcons.bookOpen, 'Books'),
      BrutalTab(LucideIcons.plus, 'Add a book'),
    ],
    selectedIndex: place,
    onDestinationSelected: (index) => setState(() => place = index),
    branches: [
      (context) => const BooksPage(),
      (context) => const AddBookPage(),
    ],
  );
}
```

## Building blocks

| For | Brutal's |
| --- | --- |
| The app's mount | `BrutalHost`; `BrutalTheme` for a part of the tree |
| Places | `BrutalAppShell`, `BrutalNavigationBar`, `BrutalNavigationRail`, `BrutalSideNavigation`, `BrutalTabBar`, `BrutalMenuBar` |
| A page | `BrutalScreen`, `BrutalScaffold`, `BrutalAppBar`, `BrutalSplitView`, `BrutalSectionHeader` |
| Buttons | `BrutalButton` (`.filled`, `.text`), `BrutalIconButton`, `BrutalFloatingButton`, `BrutalSplitButton`, `BrutalButtonGroup`, `BrutalLink` |
| Text entry | `BrutalTextField`, `BrutalPasswordField`, `BrutalSearchField`, `BrutalCodeField`, `BrutalInputGroup`, `BrutalCombobox`, `BrutalTagInput` |
| Choices | `BrutalSelect`, `BrutalCheckbox`, `BrutalRadio`, `BrutalSwitch`, `BrutalSegmentedButton`, `BrutalToggleGroup`, `BrutalChip` |
| Amounts | `BrutalSlider`, `BrutalRangeSlider`, `BrutalStepper`, `BrutalRating`, `BrutalWheelPicker` |
| Dates and times | `BrutalDatePicker`, `BrutalDateRangePicker`, `BrutalTimePicker`, `BrutalCalendar` |
| A form | `RawForm`, `BrutalFormField`, `BrutalFieldLabel`, `BrutalFieldMessage` |
| Lists and tables | `BrutalListGroup`, `BrutalListTile`, `BrutalSwipeRow`, `BrutalReorderableList`, `BrutalTable`, `BrutalDataTable`, `BrutalDescriptionList`, `BrutalTree` |
| Surfaces | `BrutalBlock`, `BrutalSurface`, `BrutalDisclosure`, `BrutalRule`, `BrutalMedia` |
| Raised | `showBrutalDialog` with `BrutalDialog`, `showBrutalBottomSheet`, `showBrutalSheet`, `showBrutalSideSheet`, `showBrutalActionSheet`, `BrutalMenu`, `BrutalPopover`, `BrutalTooltip`, `BrutalHoverCard`, `showBrutalCommandPalette` |
| Feedback | `showBrutalToast`, `BrutalNotice`, `BrutalStateView`, `BrutalLoadingState`, `BrutalErrorState`, `BrutalProgressBar`, `BrutalSpinner`, `BrutalSkeleton` |
| Status | `BrutalTag`, `BrutalBadge`, `BrutalMeter`, `BrutalKbd` |
| People | `BrutalAvatar`, `BrutalAvatarGroup` |
| Steps and pages | `BrutalStepProgress`, `BrutalPagination`, `BrutalBreadcrumb`, `BrutalPageDots`, `BrutalCarousel`, `BrutalTimeline` |
| Charts | `BrutalLineChart`, `BrutalBarChart`, `BrutalAreaChart`, `BrutalPieChart`, `BrutalSparkline` |

A button comes in three emphases: `BrutalButton.filled` for the screen's one primary action (the signal colour on its
hard shadow), `BrutalButton` (framed) for any other, `BrutalButton.text` for quiet words. `isDestructiveAction`
draws any of them in the danger red.

A press uses `onPressed` (a row `onTap`), a control `value` and `onChanged`, and a null callback disables it. A
part's `label` is the words it draws; `semanticLabel` is a name only a screen reader hears, and `debugLabel` one only
the layout checks use. A glyph beside words, a tag and a person's monogram grow with the reader's text.

**Density.** `BrutalThemeData.light(density: ...)` (and `.dark`, `.preset`, `.from`) sets how tight the controls
stand: `BrutalDensity.standard` (48 px controls), `.comfortable` (44) or `.compact` (40). Left out, it follows the
platform, as Material's `VisualDensity.adaptivePlatformDensity` does. Whatever the density, every control's tap target
stays at 40 by 40.

## Palettes and colours

Six palettes ship with the look, each designed by day and by night: `raw` (the default), `poster`, `zine`, `riso`,
`blueprint` and `acid`. `BrutalThemeData.palettes` lists them for a picker and `BrutalHost(palette: ...)` takes
one; `BrutalThemeData.preset('zine', Brightness.light)` gives one's theme. A palette recolours the signal and the lead
block; a notice's tones (ink, the look's lime and orange, red) keep their hues in every palette, so a success never
reads as a warning.

Give your own signal colour to `BrutalThemeData.from`; set the rule, the shadow and any part's defaults on the theme,
or one part's with its `style`:

```dart
// The brand: your signal colour (its words picked black or white at 4.5:1),
// a heavier rule (2 to 4 px) and a deeper shadow (2 to 8 px).
final theme = BrutalThemeData.from(signal: const Color(0xFF2F5BFF)).copyWith(
  borderWidth: 3,
  shadowOffset: 6,
  // Every primary button.
  filledButtonStyle: const BrutalStyle(
    padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 28)),
    minimumSize: WidgetStatePropertyAll(Size(0, 56)),
  ),
);

// One button.
final yellow = BrutalButton.filled(
  'Buy tickets',
  onPressed: () {},
  style: const BrutalStyle(fill: WidgetStatePropertyAll(Color(0xFFFFD23F))),
);
```

Every part takes `style:` and reads its slot in the theme (`BrutalThemeData.chipStyle`, `.dialogStyle` and so on);
each part's documentation says which of the style's fields it reads. `typeface:` sets the face for every part and the
Material theme under them; give the family's cap height so words sit centred in their cells.

A pointer over a part changes nothing but the cursor: hover is a desktop's wash, not Brutal's. The hovered state still
reaches every style, and a value left null falls through to the next layer, so a hover takes one line:

```dart
final hover = BrutalStyle(
  fill: WidgetStateProperty.resolveWith(
    (states) => states.contains(WidgetState.hovered) ? const Color(0xFFFFF4C2) : null,
  ),
);
```

The selected state is the ink fill; keyboard focus is a solid block along a control's lower edge. In an open list (a
menu, a select's, the combobox's) the pointer and the keyboard are one place: one row lights with a narrow rule round
it, inside its edges.

## Accessibility and languages

- **Screen readers and keyboards.** Every control reports its role, label, value and state. Tab moves in reading
  order; a tab bar or navigation list is one tab stop, with arrows between its places; F6 moves between the places and
  the page. Tooltips open on focus or hover and close with Escape; dialogs keep focus inside and give it back to their
  opener. Android's back closes the innermost raised part before it leaves the page.
- **Tap targets.** Every control takes at least 40 by 40, for a finger and a pointer alike (ui_core's floor); a
  `RawTapTargetScope` above the theme sets an app's own.
- **Large text.** Parts follow the system's text scaling: words wrap or end with an ellipsis on purpose, controls grow
  taller, date pickers scroll in the room round their field and charts scale their axes.
- **Right to left.** Layouts mirror under a right-to-left `Directionality`: rows, fields, menus, charts and navigation
  turn, the hard shadow falls toward the end, and parameters say start and end.
- **Other scripts.** Space Grotesk covers Latin scripts; other scripts fall back to the platform's fonts.
- **Control labels.** Register `RawWidgetsLocalizations.delegate` in `localizationsDelegates`: ui_core says the
  shared labels (Close, Cancel, Loading) in its 30 languages. Brutal's own words (a table's row count) come from
  `BrutalLocalizations`, which an app subclasses for another language.
- **Motion.** With the platform's reduced motion on, every state change switches at once.

## Copying a component

To customise a component beyond its style, copy its Dart source into your app, rename the widget and import the
shared helpers.

```dart
import 'package:brutal_ui/brutal_parts.dart';
```

Use `brutal_ui.dart` elsewhere in your app. The parts library supports copied components and can change between
releases.

## Example

`example/lib/main.dart` is Shelf, the app [Build an app](#build-an-app) walks through. `flutter run -t lib/gallery.dart`
opens the gallery: Admit, a city's week of tickets, then every part's page, by day and by night. Checkout takes the
saved demo card and any three-digit security code; bookings, cancellations and account edits last for the session.

## Requirements

Flutter 3.47.0 or later (Dart 3.13), on Android, iOS, web, macOS, Windows and Linux. brutal_ui 0.7 stands on ui_core 0.8.

## Licence

BSD-3-Clause. Space Grotesk is under the SIL Open Font License 1.1; Lucide icons under ISC, with Feather contributions
under MIT. See `THIRD_PARTY_NOTICES/`.

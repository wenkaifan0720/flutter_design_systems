# keycap_ui

Keycap is a Flutter widget library that draws an app's controls as keycaps on a mechanical keyboard. Keys are sculpted, with their walls showing round a dished top face, and they travel down when pressed. Choices latch. Lists, cards and fields sit in wells cut into the case. It includes an adaptive app frame, forms, lists, dialogs, sheets, toasts and charts. Six colourways, each by day and by night.

![Jotter's home on a desk at 1440 and on a phone at 390, by day](https://raw.githubusercontent.com/wenkaifan0720/flutter_design_systems/main/packages/keycap_ui/screenshots/hero.webp)

**[Docs and demo](https://wenkaifan0720.github.io/flutter_design_systems/docs/looks/keycap/)** · [Try it in Stint](https://wenkaifan0720.github.io/flutter_design_systems/docs/stint/?look=keycap) · [API reference](https://pub.dev/documentation/keycap_ui/latest/) · [All the looks](https://wenkaifan0720.github.io/flutter_design_systems/docs/)

## Install

```sh
flutter pub add keycap_ui material_ui lucide_icons_flutter
```

A whole app: Keycap's face loaded, `KeycapHost` over the app, one page and one key.

```dart
import 'package:keycap_ui/keycap_ui.dart';
import 'package:material_ui/material_ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await keycapLoadFonts();
  runApp(MaterialApp(
    builder: (context, child) => KeycapHost(child: child!),
    home: KeycapScreen(body: KeycapButton.accent(onPressed: () {}, child: const Text('New note'))),
  ));
}
```

`material_ui` is Flutter's Material as a package, as it is from Flutter 3.50; import it, not
`package:flutter/material.dart`. `keycap_ui.dart` exports none of Flutter's libraries, so a file imports
`material_ui` (or `package:flutter/widgets.dart`) beside it. An app on `CupertinoApp` adds `cupertino_ui`; one on
`WidgetsApp` needs only `keycap_ui`. Keycap's parts draw Lucide's glyphs; `lucide_icons_flutter` gives an app the
rest of them as `LucideIcons`, for any part that takes an `IconData` (an app with glyphs of its own can leave it out).
Keycap bundles its face, Rubik: `keycapLoadFonts` loads it before the first frame, so the web never shows a fallback.

## Mount KeycapHost

`KeycapHost` is the one mount an app needs, in its app's `builder`, above the navigator: Keycap's theme by day and by
night, the colourway and the toasts. Its `brightness` is light, dark, or null for the platform's setting; its
`palette` is one of `KeycapThemeData.palettes`. A new appearance or colourway moves on a calm spring: every colour
lerps to it. Dialogs and sheets need no mount of their own: each rises on the navigator's overlay in the theme it was
raised in. Your navigator, routes and localizations stay yours.

```dart
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) => KeycapScreen(
    topBar: const KeycapAppBar(title: 'Notes'),
    body: KeycapButton.accent(onPressed: () {}, child: const Text('New note')),
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
  RawNamedPalette palette = KeycapThemeData.palettes.first;

  @override
  Widget build(BuildContext context) => MaterialApp(
    builder: (context, child) => KeycapHost(
      brightness: brightness,
      palette: palette,
      child: child!,
    ),
    home: const HomePage(),
  );
}
```

Under `KeycapHost`, material_ui's `Theme` carries Keycap's page change, `keycapPageTransitions`: a pushed page comes a
short way in from the reading end and settles while the page beneath steps back and dims, so a `MaterialPageRoute`
your app pushes on material_ui's `MaterialApp` changes Keycap's way already. On iOS a page still pops with a swipe from
the screen's leading edge. A router or a `Navigator.pages` list takes `KeycapPage`.

With `CupertinoApp`, or with `WidgetsApp` for an app with no Material or Cupertino at all:

```dart
import 'package:cupertino_ui/cupertino_ui.dart';

CupertinoApp(
  builder: (context, child) => KeycapHost(child: child!),
  home: const HomePage(),
);
```

```dart
WidgetsApp(
  color: const Color(0xFF3B5BDB),
  builder: (context, _) => const KeycapHost(child: HomePage()),
);
```

`KeycapTheme` alone restyles a part of the tree:
`KeycapTheme(data: KeycapThemeData.preset('sage', Brightness.dark), child: ...)`.

## Build an app

The example, `example/lib/main.dart`, is this app in one file to copy: a shelf of books in three places.

**A list and its page.** A page is a `KeycapScreen`: its top bar, then its body in the page's margins, as wide as
`maxWidth` at most, and an optional footer of keys fixed at its foot, on the body's column. A list is a group of rows in
a well; a row pushes its page with Flutter's own route, and the pushed page's bar has its way back (Escape and the back
gesture pop it too). A row's name reads its tag: "Piranesi, Susanna Clarke, To read".

```dart
class BookPage extends StatelessWidget {
  const BookPage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => KeycapScreen(
    topBar: KeycapAppBar(title: title, onBack: () => Navigator.of(context).pop()),
    body: Text('Started ${KeycapFormat.date(context, DateTime(2026, 10, 2))}'),
  );
}

class BooksPage extends StatelessWidget {
  const BooksPage({super.key});

  @override
  Widget build(BuildContext context) => KeycapScreen(
    topBar: const KeycapAppBar(title: 'Books'),
    body: KeycapListGroup(
      children: [
        for (final title in ['Piranesi', 'Stoner'])
          KeycapListTile(
            title: title,
            trailing: const KeycapTag('To read'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (context) => BookPage(title: title)),
            ),
          ),
      ],
    ),
  );
}
```

**A dialog: pop it with the answer.** A dialog is a panel over the keyboard, its keys at its foot, the main one last.
Its keys pop the route with the answer, which `showKeycapDialog` returns; Escape, the barrier and the back gesture
return null. Focus goes back where it was. A dialog that confirms a loss ends in the danger key. A toast says what
happened.

```dart
Future<void> confirmRemove(BuildContext context, String title) async {
  final remove = await showKeycapDialog<bool>(
    context: context,
    builder: (context) => KeycapDialog(
      title: 'Remove $title?',
      content: const Text('It leaves your shelf. You can add it again.'),
      actions: [
        KeycapButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Keep')),
        KeycapButton.accent(
          isDestructiveAction: true,
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Remove'),
        ),
      ],
    ),
  );
  if (remove == true && context.mounted) showKeycapToast(context, 'Removed $title');
}
```

**A form.** `RawForm` (ui_core's, exported with keycap_ui) checks every field's `validator` on submit, as Flutter's
`Form` does with `TextFormField`: each error shows under its field, the well's edge turns the danger colour, the first
wrong field takes the focus and a screen reader hears how many need attention; after that the errors follow the
typing. Every field takes its column's width, so a form stands on one edge. `KeycapDatePicker` takes a null day for
"not yet", raises the month and writes the day as `KeycapFormat.date` does ("Nov 14, 2026" in English). A control
with no field of its own (a switch, a segmented row, a stepper) takes its label and its help from `KeycapField`. A
switch, a checkbox and a radio keep their own size there, at the field's start, as Material's do.

```dart
class AddBookPage extends StatefulWidget {
  const AddBookPage({super.key});

  @override
  State<AddBookPage> createState() => _AddBookPageState();
}

class _AddBookPageState extends State<AddBookPage> {
  final form = GlobalKey<RawFormState>();
  DateTime? started;
  bool favourite = false;

  @override
  Widget build(BuildContext context) => KeycapScreen(
    topBar: const KeycapAppBar(title: 'Add a book'),
    footer: KeycapButton.accent(onPressed: () => form.currentState!.submit(), child: const Text('Save')),
    body: RawForm(
      key: form,
      onSubmit: () => showKeycapToast(context, 'Added'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: KeycapSpacing.regular,
        children: [
          KeycapTextField(
            labelText: 'Title',
            validator: (value) => (value ?? '').trim().isEmpty ? 'Enter the title' : null,
          ),
          KeycapDatePicker(
            labelText: 'Started',
            hintText: 'Not yet',
            value: started,
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
            onChanged: (day) => setState(() => started = day),
          ),
          KeycapField(
            labelText: 'Favourite',
            child: KeycapSwitch(value: favourite, onChanged: (on) => setState(() => favourite = on)),
          ),
        ],
      ),
    ),
  );
}
```

**Settings: the colourway picker.** `KeycapThemeData.palettes` are the six colourways as ui_core's `RawNamedPalette`:
an `id` to store, a `label` to show, and `swatchesFor(brightness)`, its keys' colours by day or by night (the accent,
a modifier, an alpha). Show each colourway's swatches beside its name, a row each, and give the chosen one to
`KeycapHost(palette: ...)`.

```dart
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.palette, required this.onPalette});

  final RawNamedPalette palette;
  final ValueChanged<RawNamedPalette> onPalette;

  @override
  Widget build(BuildContext context) {
    final brightness = KeycapTheme.of(context).colors.brightness;
    return KeycapScreen(
      topBar: const KeycapAppBar(title: 'Settings'),
      body: KeycapListGroup(
        header: 'Colourway',
        children: [
          for (final option in KeycapThemeData.palettes)
            KeycapListTile(
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

/// A colourway's keys side by side in one square, ruled in the row's ink.
class Swatches extends StatelessWidget {
  const Swatches(this.colors, {super.key});

  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    final glyph = IconTheme.of(context);
    final corner = BorderRadius.circular((glyph.size ?? 24) / 4);
    return SizedBox.square(
      dimension: glyph.size ?? 24,
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(borderRadius: corner, border: Border.all(color: glyph.color!)),
        child: ClipRRect(
          borderRadius: corner,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [for (final color in colors) Expanded(child: ColoredBox(color: color))],
          ),
        ),
      ),
    );
  }
}
```

**The places: `KeycapScaffold`.** On a phone the places are a row of keys at the foot; from 600 wide a rail down the
start; from 1024 wide the side column, with the app's `header` at its head (`KeycapScaffold.modeFor` says which).
`.branches` keeps a stack for each place: a pushed page keeps the rail or the side column while the phone's row steps
away, and back pops it. Toasts keep clear of the row. A screen reader hears the places as tabs, the current one
selected.

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
  Widget build(BuildContext context) => KeycapScaffold.branches(
    header: const Text('Shelf'),
    destinations: const [
      KeycapDestination(icon: LucideIcons.bookOpen, label: 'Books'),
      KeycapDestination(icon: LucideIcons.plus, label: 'Add a book'),
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

| For | Keycap's |
| --- | --- |
| The app's mount | `KeycapHost`; `KeycapTheme` for a part of the tree |
| Places | `KeycapScaffold` (`.branches`), `KeycapNavigationBar`, `KeycapNavigationRail`, `KeycapSideNavigation`, `KeycapTabBar`, `KeycapMenuBar`, `KeycapToolbar` |
| A page | `KeycapScreen`, `KeycapAppBar`, `KeycapPageTitle`, `KeycapSectionHeader`, `KeycapSplitView`, `KeycapScrollArea`, `KeycapRefresh`, `KeycapPage` |
| Keys | `KeycapButton` (`.modifier`, `.accent`, `.text`), `KeycapIconButton`, `KeycapSplitButton`, `KeycapLink`, `KeycapLegendKey` |
| Text entry | `KeycapTextField`, `KeycapPasswordField`, `KeycapSearchField`, `KeycapOtpField`, `KeycapInputGroup`, `KeycapCombobox`, `KeycapTagInput` |
| Choices | `KeycapSelect`, `KeycapCheckbox`, `KeycapRadioGroup`, `KeycapSwitch`, `KeycapSwitchListTile`, `KeycapSegmentedButton`, `KeycapToggleGroup`, `KeycapChip` |
| Amounts | `KeycapSlider`, `KeycapRangeSlider`, `KeycapStepper`, `KeycapRating`, `KeycapWheelPicker`, `KeycapColorPicker` |
| Dates and times | `KeycapDatePicker`, `KeycapDateRangePicker`, `KeycapTimePicker`, `KeycapCalendar`, `KeycapFormat` |
| A form | `RawForm`, `KeycapField`, `KeycapFieldLabel`, `KeycapFieldMessage`, `KeycapDropZone` |
| Lists and tables | `KeycapListGroup`, `KeycapListTile`, `KeycapSwipeActions`, `KeycapReorderableList`, `KeycapTable`, `KeycapDataTable`, `KeycapDescriptionList`, `KeycapTree` |
| Surfaces | `KeycapCard`, `KeycapWell`, `KeycapPanel`, `KeycapCap`, `KeycapDisclosure`, `KeycapDivider`, `KeycapMedia`, `KeycapCarousel` |
| Over the keyboard | `showKeycapDialog` with `KeycapDialog`, `showKeycapBottomSheet`, `showKeycapSideSheet`, `showKeycapActionSheet`, `KeycapMenu`, `KeycapContextMenu`, `KeycapPopover`, `KeycapHoverCard`, `KeycapTooltip`, `showKeycapCommandPalette` |
| Feedback | `showKeycapToast`, `KeycapBanner`, `KeycapStatusView`, `KeycapEmptyState`, `KeycapProgressBar`, `KeycapSpinner`, `KeycapSkeleton` |
| Status | `KeycapTag`, `KeycapBadge`, `KeycapMeter`, `KeycapKbd` |
| People | `KeycapAvatar`, `KeycapAvatarGroup` |
| Steps and pages | `KeycapStepProgress`, `KeycapPagination`, `KeycapBreadcrumb`, `KeycapPageDots`, `KeycapTimeline` |
| Charts | `KeycapLineChart`, `KeycapBarChart`, `KeycapAreaChart`, `KeycapDonutChart`, `KeycapSparkline` |

## Keys

Each kind of key has its own constructor and its own component theme:

- `KeycapButton`: a light key for a neutral action.
- `KeycapButton.modifier`: a darker key for a secondary action.
- `KeycapButton.accent`: the coloured key for the screen's main action. With `isDestructiveAction: true` it is the danger key a confirming dialog ends with; on a page, a destructive `KeycapButton` keeps its plastic and prints its words in the danger colour.
- `KeycapButton.text`: words printed on the case, with no key under them.
- `KeycapIconButton`: a square key. Give it `selected` and it latches.

A key that does nothing (`onPressed: null`) stands as a level, matte plate faded toward the case: no dish, no rim, no shadow. A coloured key goes neutral first, since its colour says what it does.

A press uses `onPressed` (a row `onTap`), a control `value` and `onChanged`, and a null callback disables it. A
part's `label` or `labelText` is the words it draws; `semanticLabel` is a name only a screen reader hears, and
`debugLabel` one only the layout checks use. A few spoken names keep ui_core's own: a split key's `menuLabel`, a tag
input's `deleteLabel`, a range slider's `startLabel` and `endLabel`. A segmented row or a toggle group has no label of
its own, as Material's `SegmentedButton` has none: `KeycapField(labelText: ...)` draws one over it and names the group
with it. A glyph beside words, a tag and a person's monogram grow with the reader's text.

**Density.** `KeycapThemeData.light(density: ...)` (and `.dark`, `.preset`, `.from`) sets how tight the keys stand:
`RawDensity.standard` (48 px keys), `.comfortable` (44) or `.compact` (40). `KeycapDensity` is the same type under
Keycap's name, so either name works. Left out, it follows the platform, as Material's
`VisualDensity.adaptivePlatformDensity` does. Whatever the density, every control's tap target stays at 40 by 40.

## Colourways and colours

Six colourways ship with the look, each by day and by night: `classic` (cool grey alphas, slate modifiers and a cobalt
key, the default), `retro` (beige alphas, warm grey modifiers, an amber key), `sage`, `rose`, `lilac` and `ocean`. Each
is the classic keyboard's plastics at the same tones in other hues, so every legend reads as it does in classic.
`KeycapThemeData.palettes` lists them for a picker and `KeycapHost(palette: ...)` takes one;
`KeycapThemeData.preset('sage', Brightness.light)` gives one's theme. A status's tones (info, success, warning,
danger) stay apart from one another in every colourway, so a success never reads as a warning. A note's ink (info)
stays apart from the accent's words as well, so a note never reads as a link or a choice: it is the classic's cobalt,
or the ocean's teal where the key itself is cobalt or near it (classic, lilac). Sage's key is green, so there a
success shares the key's hue.

For a brand, `KeycapThemeData.from` moulds the accent key in the brand colour and keeps every legend readable; give it
to `KeycapHost` as `theme` and `darkTheme`:

```dart
final brand = KeycapThemeData.from(
  brightness: Brightness.light,
  accent: const Color(0xFF16807A),
);
final host = KeycapHost(
  theme: brand,
  darkTheme: KeycapThemeData.from(brightness: Brightness.dark, accent: const Color(0xFF16807A)),
  child: const HomePage(),
);
```

Set a part's defaults on the theme (`buttonStyle`, `selectStyle`, `wellStyle` and the rest) or pass a `KeycapStyle`
to one control. A style sets colours, padding and sizes; the cap's sculpt, the wells and the light stay the look's.
A part's corners are fixed (ui_core's `cornerFreedom: fixed`): a style's `corners` leaves them as they are, since a
keycap's profile is the look.
The cap, the well and the panel are public, `KeycapCap`, `KeycapWell` and `KeycapPanel`, for a part of your own in
the look.

![Jotter's settings on a phone by day and by night](https://raw.githubusercontent.com/wenkaifan0720/flutter_design_systems/main/packages/keycap_ui/screenshots/settings.webp)

## Accessibility and languages

- **Contrast.** Words read at WCAG AA on every key, well and panel, by day and by night, in every colourway; a
  calendar's days from the months either side stand quieter, at 3:1, as Cupertino's do.
- **Screen readers and keyboards.** Keyboard focus is the keyboard's own backlight: a band of light round a focused
  key's foot, and a lit band inside a field's well. Tab reaches each control; a radio group, a one-choice segmented
  button and a one-at-a-time toggle group are one Tab stop each, and the arrows choose within them, as Flutter's
  `RadioGroup` does. A screen reader hears a checkbox, a radio and a switch as Flutter's own, with their state, and a
  latching key as a button that is selected, as `IconButton(isSelected:)` is. A row's trailing menu keeps its own
  node. Dialogs and sheets keep the focus inside and give it back to the key that opened them.
- **Tap targets.** Every control takes at least 40 by 40, for a finger and a pointer alike (ui_core's floor).
- **Large text.** Text at 200% grows keys and rows rather than cutting their words.
- **Right to left.** In a right-to-left locale the layout mirrors: keys, menus, charts and the side column read from
  the right.
- **Control labels.** Add `RawWidgetsLocalizations.delegate` to the app's `localizationsDelegates` for the controls'
  own words (a pager's "next page", a tag's "remove", a search's "no results") in 30 languages. Figures follow the
  locale: dates, times, the number fields, the charts' scales and a meter's percentage write the reader's digits,
  Arabic-Indic in Arabic.
- **Motion.** Every key travels on a short, calm spring that settles without a bounce; under Reduce Motion every spring
  is critically damped.

## Copying a component

To customise a component beyond its style, copy its Dart source into your app, rename the widget and import the
shared helpers.

```dart
import 'package:keycap_ui/keycap_parts.dart';
```

Use `keycap_ui.dart` elsewhere in your app. The parts library supports copied components and can change between
releases.

## Example

`example/lib/main.dart` is Shelf, the app [Build an app](#build-an-app) walks through. `flutter run -t lib/gallery.dart`
opens the gallery: Jotter, a notebook built only from Keycap's parts, then every part's page, by day and by night.

## Requirements

Flutter 3.47.0 or later (Dart 3.13), on Android, iOS, web, macOS, Windows and Linux. keycap_ui 0.6 stands on ui_core 0.8.

## Licence

BSD-3-Clause. Rubik is under the SIL Open Font License 1.1; Lucide icons under ISC. See `THIRD_PARTY_NOTICES/`.

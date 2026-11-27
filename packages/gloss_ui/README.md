# gloss_ui

Gloss is a skeuomorphic Flutter component library with glazed buttons, recessed fields, and porcelain panels.
It includes forms, navigation, calendars, charts, dialogs, and six palettes, each with a light and dark appearance.

![Gloss's Today screen on a desk at 1440 and on a phone at 390, by day](https://raw.githubusercontent.com/wenkaifan0720/flutter_design_systems/main/packages/gloss_ui/screenshots/hero.webp)

**[Docs and demo](https://wenkaifan0720.github.io/flutter_design_systems/docs/looks/gloss/)** · [Try it in Stint](https://wenkaifan0720.github.io/flutter_design_systems/docs/stint/?look=gloss) · [API reference](https://pub.dev/documentation/gloss_ui/latest/) · [All the looks](https://wenkaifan0720.github.io/flutter_design_systems/docs/)

## Install

```sh
flutter pub add gloss_ui material_ui lucide_icons_flutter
```

Every snippet on this page compiles after that line: Gloss draws Lucide's glyphs, and the snippets name them
(`LucideIcons.bookOpen`).

Each file imports the look and the Material it is built on:

```dart
import 'package:gloss_ui/gloss_ui.dart';
import 'package:material_ui/material_ui.dart';
```

`gloss_ui.dart` holds every part, `GlossHost` and `GlossAppShell` included, and ui_core's `Raw*` parts. It doesn't
export `package:flutter/widgets.dart`: `material_ui` does, with `MaterialApp`. Import `material_ui` rather than
`package:flutter/material.dart`, which Flutter deprecates for it.

## Mount the host

`GlossHost`, in the app's `builder`, is the one mount: it picks the light or dark theme, holds the toasts and eases a
change of palette or appearance. Load the bundled face before `runApp` so the first frame is set in it, and give the
app's theme `glossPageTransitions`, so a push moves as Gloss's pages do (with the iOS swipe back).

```dart
import 'package:gloss_ui/gloss_ui.dart';
import 'package:material_ui/material_ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await glossLoadFonts();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Simmer',
    theme: ThemeData(
      pageTransitionsTheme: const PageTransitionsTheme(builders: glossPageTransitions),
    ),
    // brightness: null follows the platform; Brightness.light or
    // Brightness.dark pins it. palette: one of the six, jade by default.
    builder: (context, child) => GlossHost(
      palette: GlossThemeData.palettes.first,
      brightness: null,
      child: child!,
    ),
    home: const GlossScreen(
      topBar: GlossTopBar(title: 'Tonight', large: true),
      body: GlossWell(children: [GlossListTile(title: 'Lemon risotto', subtitle: '35 min')]),
    ),
  );
}
```

A `CupertinoApp` (from `cupertino_ui`) or a bare `WidgetsApp` takes the same `builder:`. `GlossHost(theme:,
darkTheme:)` takes themes of your own instead of a palette. To theme one subtree, wrap it in `GlossTheme(data: …)`;
`AnimatedGlossTheme` eases between two.

## Build an app

The example app, `example/lib/main.dart`, is all of this in one file: a reading list with three places and one act,
a list with a pushed page, a form, a dialog and settings. Copy it and grow it.

### The shell

`GlossAppShell` is the app's frame: its places in the grained bottom bar along a phone's foot, in the rail from 600
wide and in the sidebar from 1024. Each place keeps its own stack of pages; a page pushed in a place keeps the rail or
the sidebar beside it while the bar steps away, and back pops it. The app's one act, a `GlossActKey`, is a jade gel
key in the chrome: the bar's last cell, under the name on the rail, a worded key on the sidebar. Toasts keep clear of
the bar.

```dart
import 'package:gloss_ui/gloss_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _place = 0;

  @override
  Widget build(BuildContext context) => GlossAppShell(
    header: const GlossBrand('Simmer'),
    action: GlossActKey(icon: LucideIcons.plus, label: 'Plan a dinner', onPressed: () {}),
    destinations: const [
      RawNavigationDestination(label: 'Today', icon: LucideIcons.house),
      RawNavigationDestination(label: 'Recipes', icon: LucideIcons.chefHat),
      RawNavigationDestination(label: 'Settings', icon: LucideIcons.settings),
    ],
    selectedIndex: _place,
    onDestinationSelected: (index) => setState(() => _place = index),
    branches: [
      (context) => const GlossScreen(topBar: GlossTopBar(title: 'Today'), body: SizedBox()),
      (context) => const GlossScreen(topBar: GlossTopBar(title: 'Recipes'), body: SizedBox()),
      (context) => const GlossScreen(topBar: GlossTopBar(title: 'Settings'), body: SizedBox()),
    ],
  );
}
```

An app on go_router's `StatefulShellRoute`, which keeps each place's navigator itself, frames its
`StatefulNavigationShell` with `GlossAppShell.router(body: shell, selectedIndex: shell.currentIndex, …)`.

### A list, and its page

A page is a `GlossScreen`: its bar, its body on the porcelain in the page's margins, no wider than 1080, and a footer
for its one gel key. Rows stand in a `GlossWell` pressed into the page. A row pushes its record's page in the same
place; the pushed page's bar takes the way back from `GlossTopBar.autoLeading`.

```dart
import 'package:gloss_ui/gloss_ui.dart';
import 'package:material_ui/material_ui.dart';

class Recipe {
  const Recipe(this.name, this.time, {this.quick = false});

  final String name;
  final String time;
  final bool quick;
}

class RecipesPage extends StatelessWidget {
  const RecipesPage({super.key, required this.recipes});

  final List<Recipe> recipes;

  @override
  Widget build(BuildContext context) => GlossScreen(
    topBar: const GlossTopBar(title: 'Recipes', large: true),
    body: GlossWell(
      children: [
        for (final recipe in recipes)
          GlossListTile(
            leading: GlossAvatar(name: recipe.name, size: 24),
            title: recipe.name,
            subtitle: recipe.time,
            trailing: recipe.quick ? const GlossTag('Quick', tone: GlossTagTone.accent) : null,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (context) => RecipePage(recipe: recipe)),
            ),
          ),
      ],
    ),
  );
}

class RecipePage extends StatelessWidget {
  const RecipePage({super.key, required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) => GlossScreen(
    topBar: GlossTopBar(title: recipe.name, leading: GlossTopBar.autoLeading(context)),
    body: GlossWell(
      children: [
        GlossListTile(title: 'Time', trailingText: recipe.time),
        GlossListTile(title: 'Serves', trailingText: '2'),
      ],
    ),
    footer: GlossButton.filled('Start cooking', onPressed: () {}),
  );
}
```

### Forms

`GlossTextFormField` is a Flutter `FormField`: put it in a `Form` (`GlossForm` is the same widget), and
`validate()` shows each field's error under its well in ruby. Every field takes its column's width, at every width.

```dart
import 'package:gloss_ui/gloss_ui.dart';
import 'package:material_ui/material_ui.dart';

class NewRecipePage extends StatefulWidget {
  const NewRecipePage({super.key});

  @override
  State<NewRecipePage> createState() => _NewRecipePageState();
}

class _NewRecipePageState extends State<NewRecipePage> {
  final _form = GlobalKey<FormState>();
  String _name = '';
  DateTime? _on;
  bool _remind = true;

  void _save() {
    if (!_form.currentState!.validate()) return;
    _form.currentState!.save();
    Navigator.of(context).pop(_name);
  }

  @override
  Widget build(BuildContext context) => GlossScreen(
    topBar: GlossTopBar(title: 'New recipe', leading: GlossTopBar.autoLeading(context)),
    body: Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: GlossSpacing.regular,
        children: [
          GlossTextFormField(
            labelText: 'Name',
            hintText: 'What are you cooking?',
            validator: (value) => (value ?? '').trim().isEmpty ? 'Name the recipe' : null,
            onSaved: (value) => _name = value!.trim(),
          ),
          GlossDatePicker(
            labelText: 'Cook on',
            hintText: 'Any day',
            value: _on,
            firstDate: DateTime(2026),
            lastDate: DateTime(2027, 12, 31),
            onChanged: (value) => setState(() => _on = value),
          ),
          GlossWell(
            children: [
              GlossListTile(
                title: 'Remind me',
                trailing: GlossSwitch(value: _remind, onChanged: (value) => setState(() => _remind = value)),
              ),
            ],
          ),
        ],
      ),
    ),
    footer: GlossButton.filled('Save', onPressed: _save),
  );
}
```

A date picker shows its day as "Nov 9, 2026" and opens Gloss's calendar (in a sheet below 600 wide);
`GlossFormat.mediumDate(context, day)` writes the same.

### Dialogs and toasts

`showGlossDialog` raises a dialog over the whole app and completes with what it pops: pop it with the answer.

```dart
import 'package:gloss_ui/gloss_ui.dart';
import 'package:material_ui/material_ui.dart';

Future<void> remove(BuildContext context) async {
  final sure = await showGlossDialog<bool>(
    context: context,
    builder: (context) => GlossDialog(
      title: 'Remove this recipe?',
      content: const Text('It leaves Thursday and your shopping list.'),
      actions: [
        GlossDialogAction(label: 'Keep', onPressed: () => Navigator.of(context).pop(false)),
        GlossDialogAction(
          label: 'Remove',
          isDestructiveAction: true,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    ),
  );
  if (sure != true || !context.mounted) return;
  showGlossToast(context, 'Removed from Thursday', actionLabel: 'Undo', onAction: () {});
}
```

### The palette picker

`GlossThemeData.palettes` are the six gels, each a `RawNamedPalette`: an `id` to store, a `label` to show, and
the swatches to draw beside it (`swatchesFor` the brightness shown). Hand the chosen one to the host.

```dart
import 'package:gloss_ui/gloss_ui.dart';
import 'package:material_ui/material_ui.dart';

class PalettePicker extends StatelessWidget {
  const PalettePicker({super.key, required this.palette, required this.onChanged});

  final RawNamedPalette palette;
  final ValueChanged<RawNamedPalette> onChanged;

  @override
  Widget build(BuildContext context) {
    final brightness = GlossTheme.of(context).colors.brightness;
    return GlossFormField(
      labelText: 'Palette',
      child: GlossRadioGroup<RawNamedPalette>(
        options: GlossThemeData.palettes,
        groupValue: palette,
        labelOf: (p) => p.label,
        // Each palette by its name, its colours right after it.
        trailingOf: (p) => Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 4,
          children: [
            for (final color in p.swatchesFor(brightness))
              DecoratedBox(
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: const SizedBox.square(dimension: 14),
              ),
          ],
        ),
        onChanged: onChanged,
      ),
    );
  }
}
```

`GlossThemeData.preset(id, brightness)` builds a stored id's theme again; an id it doesn't know gives jade.

## Building blocks

| For | Use |
|---|---|
| The app's frame | `GlossHost`, `GlossAppShell`, `GlossBrand`, `GlossActKey`, `GlossScreen`, `GlossPage`, `GlossSheetPage` |
| Getting around | `GlossTopBar`, `GlossTabBar`, `GlossNavigationBar`, `GlossNavigationRail`, `GlossSidebar`, `GlossBreadcrumb`, `GlossPagination`, `GlossPageDots`, `GlossStepProgress`, `GlossMenuBar`, `GlossCommandPalette` |
| Acts | `GlossButton` (`.filled`, `.text`), `GlossIconButton`, `GlossButtonGroup`, `GlossSplitButton`, `GlossToggle`, `GlossToggleGroup`, `GlossLink`, `GlossKbd` |
| Words in | `GlossTextField`, `GlossTextFormField`, `GlossTextArea`, `GlossPasswordField`, `GlossSearchField`, `GlossInputGroup`, `GlossOtpField`, `GlossTagInput`, `GlossFormField`, `GlossForm` |
| Choices | `GlossSelect`, `GlossCombobox`, `GlossRadioGroup`, `GlossRadio`, `GlossCheckbox`, `GlossSwitch`, `GlossSegmentedButton`, `GlossChip`, `GlossSlider`, `GlossRangeSlider`, `GlossStepper`, `GlossRating`, `GlossColorPicker`, `GlossFileDrop` |
| Dates and times | `GlossDatePicker`, `GlossDateRangePicker`, `GlossCalendar`, `GlossTimePicker`, `GlossWheelPicker` |
| Lists and tables | `GlossWell`, `GlossListTile`, `GlossSectionHeader`, `GlossSwipeRow`, `GlossReorderableList`, `GlossTree`, `GlossDescriptionList`, `GlossTable`, `GlossDataTable`, `GlossDisclosure`, `GlossCarousel`, `GlossSplitView`, `GlossScrollArea`, `GlossPullToRefresh` |
| Over the page | `GlossDialog`, `showGlossDialog`, `showGlossSheet`, `showGlossSideSheet`, `showGlossActionSheet`, `GlossMenu`, `GlossPopover`, `GlossHoverCard`, `GlossTooltip`, `showGlossToast` |
| Status | `GlossTag`, `GlossBadge`, `GlossBanner`, `GlossLoadingState`, `GlossErrorState`, `GlossSkeleton`, `GlossSpinner`, `GlossProgressBar`, `GlossMeter`, `GlossTimeline` |
| Cards and marks | `GlossCard`, `GlossAvatar`, `GlossAvatarGroup`, `GlossMedia`, `GlossDivider` |
| Charts | `GlossLineChart`, `GlossAreaChart`, `GlossBarChart`, `GlossPieChart`, `GlossSparkline` |
| Your own parts | `GlossSurface`, `GlossFace`, `GlossStyle`, `glossLetterpress`, `glossToneInk`, `GlossSpacing` |

## Customize the theme

`GlossTheme.of(context)` (or `context.glossTheme`) returns the `GlossThemeData` in scope.

- **Palettes**: `GlossThemeData.palettes`, the six gels on the same porcelain as `RawNamedPalette`s: `jade` (the
  default), `sapphire`, `amethyst`, `amber`, `rose` and `teal`; `GlossThemeData.preset(id, brightness)` builds
  one's theme. A success keeps jade in every palette, so it never reads as the gel.
- **Your own colours**: `GlossThemeData.from(gel: color)` moulds the gel in it, at the nearest tone its white label
  reads on; `finish` tints the porcelain and pearl toward a hue at the look's own tones. Words, links, the focus and
  errors read on every ground they stand on, by day and by night.
- **Corners**: `shapeScheme` holds Gloss's five corner steps, round fillets of 7, 12, 16, 18 and 24 (a checkbox's
  socket, a field, a well of rows, a card, a dialog), which the parts take by size; `GlossThemeData.shapeLimits` holds
  each to a band where it still reads as moulded porcelain (5–9, 8–16, 12–22, 14–24 and 18–32), round only. Keys,
  beads, switches and chips stay pills. A change of corners eases across with the theme.
- **Density and parts**: `GlossDensity.compact` for a desk app (unset, it follows the platform); each part's
  `style` takes a `GlossStyle` over its theme default (`GlossThemeData.buttonStyle`, `.listTileStyle`, …).

```dart
import 'package:gloss_ui/gloss_ui.dart';
import 'package:material_ui/material_ui.dart';

// A coral gel for the one action; its label stays readable. Denser, for a desk.
final theme = GlossThemeData.from(gel: const Color(0xFFE4572E)).copyWith(density: GlossDensity.compact);

// Rounder parts, within Gloss's bands.
final rounder = theme.copyWith(
  shapeScheme: GlossThemeData.defaultShapeScheme.copyWith(
    corners: GlossThemeData.defaultShapeScheme.corners.scaled(1.25),
  ),
);
```

## Labels and icons

A control's `label` is drawn: a button's words, a segment's or a chip's, a field's `labelText`. A name that is only
spoken, for a control that draws no words of its own (a switch alone, a slider), is its `semanticLabel`; an icon
button's is its `tooltip`: `GlossIconButton(icon: const Icon(LucideIcons.ellipsis), tooltip: 'More', onPressed: open)`.
A control inside `GlossFormField` is heard once, by the field's label. A row's name is its words and its status tag;
an avatar at its start, picturing what the title names, stays out of it. A row without a press of its own is one
node with its switch, named by the title, as Flutter's `SwitchListTile` is: leave the switch's `semanticLabel`
out there.

## Accessibility

Use Tab to reach a control and the arrow keys to move within tabs, the places, ratings and wheels; F6 moves between
the places and the page. Keyboard focus sharpens the reflection on a glazed control; a recessed field lights its rim
in the gel's colour. Charts expose values to screen readers and scale axis labels with system text size. Dialogs,
sheets, tabs and toasts respect reduced motion. Controls stand at ui_core's touch floor, 40 by 40, or an app's
`RawTapTargetScope`. Below 600 wide the date pickers open their month in a sheet, as Material's open full width on a
phone.

## Right to left and languages

Controls follow the ambient `Directionality`, the light and its shadows included. Add
`RawWidgetsLocalizations.delegate` to your app for control labels in ui_core's 30 languages. Use `glossPlural` for
phrases that depend on a count, and `GlossFormat.mediumDate` for a day in the reader's language.

## Example

`example/lib/main.dart` is Shelf, one app to copy: the host by day, by night or as the platform is, the shell with
three places and an act, a list with a pushed page, a form that checks itself and takes a date, a dialog answered and
settings with the six palettes. `example/lib/gallery.dart` (`flutter run -t lib/gallery.dart`) is Simmer, a week of
dinners, with every component on its page.

## Requirements

Flutter 3.47.0 or later (Dart 3.13), on Android, iOS, web, macOS, Windows and Linux. The package depends on ui_core
^0.8.4 and re-exports it, so `RawWidgetsLocalizations`, `RawNamedPalette` and the `Raw*` parts come with the one
import.

## Licence

The package uses the BSD 3-Clause License. Plus Jakarta Sans uses the SIL Open Font License 1.1.
Lucide icons use the ISC and MIT licenses. Full notices are in `THIRD_PARTY_NOTICES/`.

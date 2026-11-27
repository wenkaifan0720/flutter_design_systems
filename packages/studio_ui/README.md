# studio_ui

Studio is a Flutter design system for audio and media apps. It includes transport controls, faders, meters, charts, and a full set of navigation and form widgets in coordinated light and dark themes.

![Roomtone, Studio's example podcast app, by day: its home at 1440 px beside the same page on a 390 px phone](https://raw.githubusercontent.com/wenkaifan0720/flutter_design_systems/main/packages/studio_ui/screenshots/hero_home_day.webp)

**[Docs and demo](https://wenkaifan0720.github.io/flutter_design_systems/docs/looks/studio/)** · [Try it in Stint](https://wenkaifan0720.github.io/flutter_design_systems/docs/stint/?look=studio) · [API reference](https://pub.dev/documentation/studio_ui/latest/) · [All the looks](https://wenkaifan0720.github.io/flutter_design_systems/docs/)

## Install

```sh
flutter pub add studio_ui material_ui
```

Every snippet on this page compiles after that line. Each file imports the look and the Material it is built on:

- `package:studio_ui/studio_ui.dart` holds every part, `StudioHost` and the `LucideIcons` glyphs Studio draws with included, and ui_core's `Raw*` parts.
- `package:material_ui/material_ui.dart` brings `MaterialApp` and Flutter's widgets, which `studio_ui.dart` doesn't export. Import it rather than `package:flutter/material.dart`, which Flutter deprecates after 3.47.

A first app:

```dart
import 'package:material_ui/material_ui.dart';
import 'package:studio_ui/studio_ui.dart';

void main() => runApp(
  MaterialApp(
    builder: (context, child) => StudioHost(child: child!),
    home: const StudioScreen(
      topBar: StudioAppBar(title: 'Library'),
      body: StudioDisplay(child: Text('Rooms that sound right, 38 min.')),
    ),
  ),
);
```

## Mount the host

`StudioHost`, in the app's `builder`, is the one mount: it builds the palette's day and night themes, follows the platform's appearance unless you pin one, eases a change of palette or appearance, holds the toasts and lays the chassis under every page. Load the bundled faces before `runApp` so the first frame is drawn in them.

```dart
import 'package:material_ui/material_ui.dart';
import 'package:studio_ui/studio_ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await studioLoadFonts(); // the bundled faces, before the first frame
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Takes',
    // Studio's push and pop for the pages the app pushes, the iOS back gesture included.
    theme: ThemeData(pageTransitionsTheme: const PageTransitionsTheme(builders: studioPageTransitions)),
    // brightness: null follows the platform; Brightness.light or Brightness.dark pins it.
    // palette: one of the six, anodised by default.
    builder: (context, child) => StudioHost(
      palette: StudioThemeData.palettes.first,
      brightness: null,
      child: child!,
    ),
    home: const StudioScreen(
      topBar: StudioAppBar(title: 'Episodes'),
      body: StudioStatusView(icon: Icon(LucideIcons.mic), title: 'Nothing here yet'),
    ),
  );
}
```

A `CupertinoApp` (from `cupertino_ui`) takes the same `builder:`. Flutter's `WidgetsApp`, which has no page route of its own, needs one:

```dart
WidgetsApp(
  color: const Color(0xFF2B2D30),
  builder: (context, child) => StudioHost(child: child!),
  pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
    settings: settings,
    pageBuilder: (context, _, _) => builder(context),
  ),
  home: const StudioScreen(body: StudioDisplay(child: Text('Rooms that sound right'))),
)
```

With a router (go_router, say), return a `StudioPage` from a route's `pageBuilder` for Studio's transition. `StudioHost(theme:, darkTheme:)` takes themes of your own instead of a palette. To theme one subtree, wrap it in `StudioTheme(data: …)`.

Your own text reads the theme's tokens, so it follows the palette and the room:

```dart
Text(
  'Recorded in one take.',
  style: context.studioTheme.textTheme.body.copyWith(color: context.studioTheme.colors.legend),
)
```

`colors.legend` is words on the metal, `colors.onDisplay` words on a display's glass, `colors.litLegend` a lit word; `textTheme` holds `display`, `headline`, `title`, `body`, `secondary`, `label`, `caption`, and `legend` and `readout` for words printed on the metal and on a readout.

## Build an app

The example app, `example/lib/main.dart`, is all of this in one file: a podcast recorder's episodes in three places, a list with a pushed page, a form, a dialog and settings. Copy it and grow it.

### The shell

`StudioAppShell` is the app's frame: its places in a key bank along a phone's foot, in a rail from 600 wide and in a side panel from 1024. With `branches`, each place keeps its own stack of pages: a page pushed in a place keeps the rail or the panel beside it while a phone's key bank steps away, back pops it, and choosing the place again returns to its first page. Toasts keep clear of the key bank. A `StudioShellAction` is the app's one act, a lit key over each place's first page.

```dart
import 'package:material_ui/material_ui.dart';
import 'package:studio_ui/studio_ui.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _place = 0;

  @override
  Widget build(BuildContext context) => StudioAppShell.branches(
    brand: 'Takes',
    tabs: const [
      StudioTab(LucideIcons.listMusic, 'Episodes'),
      StudioTab(LucideIcons.audioWaveform, 'Editing'),
      StudioTab(LucideIcons.settings, 'Settings'),
    ],
    selectedIndex: _place,
    onSelected: (index) => setState(() => _place = index),
    action: StudioShellAction(
      icon: LucideIcons.mic,
      label: 'Record',
      onPressed: (context) {},
    ),
    branches: [
      (context) => const StudioScreen(topBar: StudioAppBar(title: 'Episodes'), body: SizedBox()),
      (context) => const StudioScreen(topBar: StudioAppBar(title: 'Editing'), body: SizedBox()),
      (context) => const StudioScreen(topBar: StudioAppBar(title: 'Settings'), body: SizedBox()),
    ],
  );
}
```

### A list, and its page

A page is a `StudioScreen`: its bar, its body and a footer for its acts; on a wide window the bar's title and actions, the body and the footer's act share one centred column, `maxWidth` wide (1200 by default). A row pushes its record's page in the same place. A row's status is a `StudioTag`, read as part of the row's name.

```dart
import 'package:material_ui/material_ui.dart';
import 'package:studio_ui/studio_ui.dart';

class Episode {
  const Episode(this.title, this.show, {this.editing = false});

  final String title;
  final String show;
  final bool editing;
}

class EpisodesPage extends StatelessWidget {
  const EpisodesPage({super.key, required this.episodes});

  final List<Episode> episodes;

  @override
  Widget build(BuildContext context) => StudioScreen(
    topBar: const StudioAppBar(title: 'Episodes'),
    body: StudioListGroup(
      children: [
        for (final episode in episodes)
          StudioListTile(
            title: episode.title,
            subtitle: episode.show,
            trailing: episode.editing ? const StudioTag('Editing', tone: StudioTagTone.lit) : null,
            showChevron: true,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (context) => EpisodePage(episode: episode)),
            ),
          ),
      ],
    ),
  );
}

class EpisodePage extends StatelessWidget {
  const EpisodePage({super.key, required this.episode});

  final Episode episode;

  @override
  Widget build(BuildContext context) => StudioScreen(
    topBar: StudioAppBar(title: episode.title),
    body: StudioDescriptionList(
      entries: [
        StudioDescription('Show', episode.show),
        StudioDescription('Status', episode.editing ? 'Editing' : 'Draft'),
      ],
    ),
    footer: StudioButton.lit('Publish', onPressed: () {}),
  );
}
```

### Forms

`StudioForm` is the form: `StudioTextFormField`s in it validate, and `StudioForm.submit(context)` checks every field, shows each error in its field's help line beside a lit lamp and moves focus to the first, or saves each field and calls `onSubmit`. In a form's column every field takes the column's width. A part's everyday controls take `value` and `onChanged`; a null `onChanged` or `onPressed` turns it off. Wrap a control that brings no label of its own in a `StudioFormField`.

```dart
import 'package:material_ui/material_ui.dart';
import 'package:studio_ui/studio_ui.dart';

class NewEpisodePage extends StatefulWidget {
  const NewEpisodePage({super.key});

  @override
  State<NewEpisodePage> createState() => _NewEpisodePageState();
}

class _NewEpisodePageState extends State<NewEpisodePage> {
  String _title = '';
  String _quality = 'high';
  DateTime? _recorded;
  bool _explicit = false;

  @override
  Widget build(BuildContext context) => StudioForm(
    // Called once every field is fine, after each field's onSaved.
    onSubmit: () => Navigator.of(context).pop(_title),
    child: StudioScreen(
      maxWidth: 600, // the form's measure: Save stands under the fields' end
      topBar: const StudioAppBar(title: 'New episode'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: StudioSpacing.regular,
        children: [
          StudioTextFormField(
            labelText: 'Title',
            validator: (value) => (value ?? '').trim().isEmpty ? 'Enter the title' : null,
            onSaved: (value) => _title = value!.trim(),
          ),
          StudioSelect<String>(
            labelText: 'Quality',
            value: _quality,
            items: const [
              StudioSelectItem(value: 'high', label: 'High'),
              StudioSelectItem(value: 'standard', label: 'Standard'),
            ],
            onChanged: (value) => setState(() => _quality = value),
          ),
          StudioDatePicker(
            labelText: 'Recorded',
            hintText: 'Not yet',
            value: _recorded,
            firstDate: DateTime(2020),
            lastDate: DateTime.now(),
            onChanged: (value) => setState(() => _recorded = value),
          ),
          StudioCheckRow(
            label: 'Explicit',
            value: _explicit,
            onChanged: (value) => setState(() => _explicit = value),
          ),
        ],
      ),
      // Under the form, so submit finds it.
      footer: Builder(
        builder: (context) => StudioButton.lit('Save', onPressed: () => StudioForm.submit(context)),
      ),
    ),
  );
}
```

A date field with no value shows its hint; one with a day shows a medium date with its year ("Nov 9, 2026"), as ui_core's `RawWidgetsLocalizations.formatMediumDate` writes it in the app's language.

### Dialogs and toasts

`showStudioDialog` raises a dialog over the whole app and completes with what the dialog pops with, null when dismissed. Pass `isAlert: true` for a question that must be answered, and mark the act that destroys with `isDestructiveAction`: its legend glows in the danger colour.

```dart
import 'package:material_ui/material_ui.dart';
import 'package:studio_ui/studio_ui.dart';

Future<void> discardTake(BuildContext context) async {
  final sure = await showStudioDialog<bool>(
    context: context,
    isAlert: true,
    builder: (context) => StudioDialog(
      title: 'Discard this take?',
      content: const Text('The 4 minutes you recorded will be gone.'),
      actions: [
        StudioButton('Keep', onPressed: () => Navigator.of(context).pop(false)),
        StudioButton.lit(
          'Discard',
          isDestructiveAction: true,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    ),
  );
  if (sure != true || !context.mounted) return;
  showStudioToast(context, 'Take discarded');
}
```

### The palette picker

`StudioThemeData.palettes` are the six palettes, each a `RawNamedPalette`: an `id` to store, a `label` to show, and the swatches to draw it by. Hand the chosen one to the host.

```dart
import 'package:material_ui/material_ui.dart';
import 'package:studio_ui/studio_ui.dart';

class PalettePicker extends StatelessWidget {
  const PalettePicker({super.key, required this.palette, required this.onChanged});

  final RawNamedPalette palette;
  final ValueChanged<RawNamedPalette> onChanged;

  @override
  Widget build(BuildContext context) => StudioFormField(
    labelText: 'Palette',
    child: StudioRadioGroup<RawNamedPalette>(
      options: StudioThemeData.palettes,
      labelOf: (palette) => palette.label,
      secondaryOf: _Swatches.new,
      value: palette,
      onChanged: onChanged,
    ),
  );
}

// Each palette's colours in the brightness on screen, beside its name.
class _Swatches extends StatelessWidget {
  const _Swatches(this.palette);

  final RawNamedPalette palette;

  @override
  Widget build(BuildContext context) {
    final theme = StudioTheme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final color in palette.swatchesFor(theme.colors.brightness))
          Container(
            width: 14,
            height: 14,
            margin: const EdgeInsetsDirectional.only(start: 4),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: theme.colors.groove),
            ),
          ),
      ],
    );
  }
}
```

`StudioThemeData.preset(id, brightness)` builds a stored id's theme again.

## Building blocks

| For | Use |
|---|---|
| The app's frame | `StudioHost`, `StudioAppShell`, `StudioShellAction`, `StudioScaffold`, `StudioNavigationBar`, `StudioNavigationRail`, `StudioSideNavigation` |
| A page | `StudioScreen`, `StudioAppBar`, `StudioTabBar`, `StudioBreadcrumb`, `StudioPagination`, `StudioSectionHeader`, `StudioSplitView` |
| Keys | `StudioButton`, `StudioIconButton`, `StudioTransportKey`, `StudioSplitKey`, `StudioFloatingKey`, `StudioToggleBank`, `StudioKeyRow`, `StudioLink` |
| Words in | `StudioTextField`, `StudioTextFormField`, `StudioPasswordField`, `StudioSearchField`, `StudioCodeField`, `StudioInputGroup`, `StudioTagInput`, `StudioTypeAhead` |
| Choices | `StudioSelect`, `StudioCombobox`, `StudioRadioGroup`, `StudioCheckbox`, `StudioCheckRow`, `StudioSwitch`, `StudioSegmentedButton`, `StudioChip`, `StudioRating`, `StudioColorPicker` |
| Faders and meters | `StudioFader`, `StudioRangeFader`, `StudioKnob`, `StudioStepper`, `StudioMeter`, `StudioReadout`, `StudioLamp` |
| Dates and times | `StudioDatePicker`, `StudioDateRangePicker`, `StudioTimePicker`, `StudioCalendar`, `StudioWheelPicker` |
| Forms | `StudioForm`, `StudioFormField`, `StudioFieldLabel`, `StudioFileDrop` |
| Lists and tables | `StudioListGroup`, `StudioListTile`, `StudioSwipeRow`, `StudioReorderableList`, `StudioDescriptionList`, `StudioTable`, `StudioDataTable`, `StudioTree`, `StudioTimeline` |
| Over the page | `StudioDialog`, `showStudioDialog`, `showStudioBottomSheet`, `showStudioSideSheet`, `showStudioActionSheet`, `StudioMenu`, `StudioMenuBar`, `StudioPopover`, `StudioHoverCard`, `StudioTooltip`, `showStudioCommandPalette`, `showStudioToast` |
| Status | `StudioTag`, `StudioBadge`, `StudioBanner`, `StudioStatusView`, `StudioErrorState`, `StudioLoadingState`, `StudioSkeleton`, `StudioProgressBar`, `StudioSpinner`, `StudioStepProgress` |
| Glass, media and people | `StudioDisplay`, `StudioMedia`, `StudioCarousel`, `StudioAvatar`, `StudioAvatarGroup`, `StudioKbd` |
| Charts | `StudioLineChart`, `StudioAreaChart`, `StudioBarChart`, `StudioPieChart`, `StudioSparkline` |
| Materials of your own | `StudioSurface`, `StudioFace`, `StudioGroove`, `StudioPanel` |

## Customizing Studio

Choose from six palettes, each with a day and a night: `anodised` (Studio's own silver and graphite under an amber light), `cobalt`, `teal`, `moss`, `violet` and `graphite` (neutral steel under a cool white light, the one with no hue). `StudioThemeData.palettes` lists them as ui_core's `RawNamedPalette` (an `id` to store, a `label` to show, swatches to draw it by). Hand one to the host, or build its themes yourself:

```dart
MaterialApp(
  builder: (context, child) => StudioHost(
    theme: StudioThemeData.preset('cobalt', Brightness.light),
    darkTheme: StudioThemeData.preset('cobalt', Brightness.dark),
    child: child!,
  ),
)
```

Or set your own indicator and panel finish with `StudioThemeData.from`, a theme for each brightness. Its legends, lit legends, glass words and focus ring keep their contrast on the metal, the keys and the glass whatever the colours:

```dart
MaterialApp(
  builder: (context, child) => StudioHost(
    theme: StudioThemeData.from(indicator: const Color(0xFF4FD1C5)),
    darkTheme: StudioThemeData.from(
      indicator: const Color(0xFF4FD1C5),
      brightness: Brightness.dark,
    ),
    child: child!,
  ),
)
```

The light from the top and the depths of the metal stay Studio's. The corners are the theme's `shapeScheme`, Studio's milled radii by default, held to bands that still read as milled hardware (a key from 4 to 10, round only):

```dart
final rounder = StudioThemeData.light().copyWith(
  shapeScheme: StudioThemeData.defaultShapeScheme.copyWith(
    corners: StudioThemeData.defaultShapeScheme.corners.scaled(1.5),
  ),
);
```

A part takes its own corners from its style, a step per corner, start and end as it reads, so they turn right to left:

```dart
final record = StudioButton.lit(
  'Record',
  style: const StudioStyle(
    corners: WidgetStatePropertyAll(
      RawCorners(topStart: RawCorner.large, bottomEnd: RawCorner.large),
    ),
  ),
  onPressed: () {},
);
```

Each corner holds to Studio's steps, extra small to extra large: a milled corner is never sharp and a key is never a pill. A key row, a toggle bank, a segmented button and a split key take them on their outer corners, their end keys following; a style's `shape` wins as given. Lamps, knobs, switches, faders and tabs keep their own forms.

Set a component style such as `buttonStyle` or `textFieldStyle` on the theme to apply it throughout an app, or pass a `StudioStyle` to an individual widget. Its state properties can change with focus, selection or a press.

`textureStrength` controls the grain on metal surfaces. High-contrast mode removes the grain. Build custom controls with the same materials using `StudioSurface`, `StudioFace`, `StudioLamp` and `StudioReadout`.

## Accessibility

Every part reads to a screen reader with its role and name; an icon key takes a `tooltip` for its name. Every target is at least ui_core's tap floor, `RawTapTargets.of(context).floorOn()`: 40 × 40 for a finger, 24 × 24 for a pointer. The keyboard's focus lights the part's lamp or edge and shows for the keyboard only. Tab visits a key bank, a tab bar or a set of radios once, and the arrows move within it. A dialog keeps focus inside and returns it to its opener. Text scales to 200%: labels wrap and keys grow. Motion runs on springs through ui_core's `RawMotionPolicy`, which honours Reduce Motion, and high-contrast mode takes the grain off the metal.

## Languages and right to left

Labels the parts say themselves (Cancel, Search, a picker's months) come from ui_core's `RawWidgetsLocalizations`, in 30 languages, and follow the app's locale with nothing to set up. Studio's own counts come from `StudioLocalizations`, in English; for another language, extend `DefaultStudioLocalizations` and add a delegate for it to `localizationsDelegates`. In a right-to-left locale every layout mirrors, and the charts write Arabic-Indic digits in Arabic.

## Example

`example/lib/main.dart` is one app to copy: the host by day, by night or as the platform is, the shell with three places, a list with a pushed page, a form that checks itself and takes a date, a dialog answered and settings with the six palettes. `example/lib/gallery.dart` (`flutter run -t lib/gallery.dart`) sets every component on its page, in each palette, by day and by night, beside Roomtone, a sample podcast app.

## Requirements

Flutter 3.47.0 or later (Dart 3.13), on Android, iOS, the web, macOS, Windows and Linux. The package depends on ui_core ^0.8.1 and re-exports it, so `RawWidgetsLocalizations`, `RawNamedPalette` and the `Raw*` parts come with the one import.

## Fonts

Studio bundles Barlow and Noto Sans Arabic under the SIL Open Font License 1.1. Chart labels use Noto Sans Arabic for Arabic letters and digits that Barlow lacks. Both licenses are included in `assets/fonts/LICENSES/`.

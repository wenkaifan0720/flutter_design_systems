# clay_ui

Clay is a claymorphic Flutter component library: soft, inflated controls of matte clay that float a little above a
pale ground, lit from the top and shaded below, with one coral accent and six pastels. It includes forms, navigation,
lists, dialogs, sheets and toasts, with matching light and dark themes.

![Steady's Today screen on a desk at 1440 and on a phone at 390, by day](https://raw.githubusercontent.com/wenkaifan0720/flutter_design_systems/main/packages/clay_ui/screenshots/hero.webp)

**[Docs and demo](https://wenkaifan0720.github.io/flutter_design_systems/docs/looks/clay/)** · [Try it in Stint](https://wenkaifan0720.github.io/flutter_design_systems/docs/stint/?look=clay) · [API reference](https://pub.dev/documentation/clay_ui/latest/) · [All the looks](https://wenkaifan0720.github.io/flutter_design_systems/docs/)

## Install

```sh
flutter pub add clay_ui material_ui lucide_icons_flutter
```

`material_ui` is Flutter's Material as a package (from Flutter 3.50 it leaves the SDK): your app's `MaterialApp`.
Import `package:clay_ui/clay_ui.dart` and `package:material_ui/material_ui.dart` (it brings Flutter's widgets); Clay's
library doesn't export `flutter/widgets.dart`. It re-exports ui_core, so `RawWidgetsLocalizations` and the `Raw*`
parts come with it. Clay's own parts draw their glyphs from Lucide; the snippets below use `LucideIcons` from
`lucide_icons_flutter` for the app's own icons.

A whole app: Clay over a `MaterialApp`, one page and one key.

```dart
import 'package:clay_ui/clay_ui.dart';
import 'package:material_ui/material_ui.dart';

void main() => runApp(
  MaterialApp(
    builder: (context, child) => ClayHost(child: child!),
    home: ClayScreen(
      topBar: const ClayTopBar(title: 'Shelf'),
      body: ClayButton.filled('Add a book', onPressed: () {}),
    ),
  ),
);
```

## Mount Clay

`ClayHost` is the one mount. Put it in your app's `builder:`, above the Navigator, so every page, dialog and sheet
stands inside it. It gives the theme for the brightness in force (by day, by night, or as the device is; `theme` and
`darkTheme`, or a `palette`'s), holds the layer toasts show in (`showClayToast` needs it) and lays the ground. A
change of appearance or palette moves across, as a Material app's theme change does. Load the bundled face before the
first frame, and give the app Clay's page transitions:

```dart
import 'package:clay_ui/clay_ui.dart';
import 'package:material_ui/material_ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await clayLoadFonts(); // the first frame is set in Rubik
  runApp(const App(appearance: null));
}

class App extends StatelessWidget {
  const App({super.key, required this.appearance});

  /// Light or dark, pinned by the reader; null follows the device.
  final Brightness? appearance;

  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: ThemeData(
      pageTransitionsTheme: const PageTransitionsTheme(builders: clayPageTransitions),
    ),
    // Clay's own words in 30 languages, and Material's (from material_ui).
    localizationsDelegates: const [
      RawWidgetsLocalizations.delegate,
      ...GlobalMaterialLocalizations.delegates,
    ],
    supportedLocales: RawWidgetsLocalizations.supportedLocales,
    builder: (context, child) => ClayHost(brightness: appearance, child: child!),
    home: const ClayScreen(
      topBar: ClayTopBar(title: 'Shelf'),
      body: Text('Your reading list'),
    ),
  );
}
```

`clayPageTransitions` gives each platform its page transition, the iOS swipe back included. Under a `CupertinoApp`
(from `cupertino_ui`) or a bare `WidgetsApp` the host goes in the same place; a field is Flutter's Material text
field underneath, so list the same delegates there too. `ClayHost` takes a `density` beside its `palette` and
`brightness`, which stands over the theme by day and by night: `ClayHost(density: ClayDensity.compact, child: child!)`.
A `theme` or `darkTheme` you give is used as it is, and the one you leave out is the palette's in that brightness. The
window's width changes neither: the parts follow the width themselves.

## Build an app

The example app, [example/lib/main.dart](example/lib/main.dart), is a whole reading list to copy: these are its parts.
The gallery, every component on a page of its own, is `example/lib/gallery.dart` (`flutter run -t lib/gallery.dart`).

### The shell and its places

`ClayScaffold.branches` holds the app's places: the floating dock along a phone's foot, the rail from 600 wide and
the sidebar from 1024. Each place keeps its own pages; a page pushed on one stands beside the rail or the sidebar (a
phone's dock steps away for it), back pops it, and choosing the place again goes back to its first page. The arrow
keys move between the places. An `action`, the app's one key, stands at the dock's end and under the `brand` on a
rail or a sidebar. The `brand`, the app's mark, keeps its own size: at the start of a sidebar's head and in the
middle of a rail's. A rail is 96 wide and a sidebar 264, so the snippet shows the mark alone on a rail and the app's
name beside it on a sidebar.

```dart
import 'package:clay_ui/clay_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

class ShelfShell extends StatefulWidget {
  const ShelfShell({super.key});

  @override
  State<ShelfShell> createState() => _ShelfShellState();
}

class _ShelfShellState extends State<ShelfShell> {
  int _place = 0;

  @override
  Widget build(BuildContext context) => ClayScaffold.branches(
    destinations: const [
      ClayDestination(icon: LucideIcons.bookOpen, label: 'Books'),
      ClayDestination(icon: LucideIcons.plus, label: 'Add'),
      ClayDestination(icon: LucideIcons.settings, label: 'Settings'),
    ],
    selectedIndex: _place,
    onDestinationSelected: (place) => setState(() => _place = place),
    brand: LayoutBuilder(
      builder: (context, room) {
        const mark = ClayIconTile(child: Icon(LucideIcons.bookOpen));
        return room.maxWidth < 160
            ? mark
            : const Row(mainAxisSize: MainAxisSize.min, spacing: 12, children: [mark, Text('Shelf')]);
      },
    ),
    branches: [
      (context) => const ClayScreen(topBar: ClayTopBar(title: 'Books'), body: Text('Your reading list')),
      (context) => const ClayScreen(topBar: ClayTopBar(title: 'Add a book'), body: Text('Title')),
      (context) => const ClayScreen(topBar: ClayTopBar(title: 'Settings'), body: Text('Appearance')),
    ],
  );
}
```

### A list and its pages

A `ClayGroup` of `ClayListTile`s on one slab of clay, each pushing its own page. A pushed page's top bar takes its
way back from `ClayTopBar.autoLeading`: a back ball on a page, a close ball on a sheet. A tile's `trailing` holds a
tag, or a control of its own that keeps its own tap. For swipe actions, put a `ClaySwipeRow` round the tile in the
same group, as in the snippet: the slab clips the open row at its round outline.

```dart
import 'package:clay_ui/clay_ui.dart';
import 'package:material_ui/material_ui.dart';

class BooksPage extends StatelessWidget {
  const BooksPage({super.key, required this.titles, required this.onDelete});

  final List<String> titles;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) => ClayScreen(
    topBar: const ClayTopBar(title: 'Books'),
    body: ClayGroup(
      header: '${titles.length} books',
      children: [
        for (final title in titles)
          ClaySwipeRow(
            endActions: [
              ClaySwipeAction(label: 'Delete', isDestructiveAction: true, onPressed: () => onDelete(title)),
            ],
            child: ClayListTile(
              title: title,
              subtitle: 'George Eliot',
              trailing: const ClayTag('Reading', tone: ClayTagTone.accent),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => ClayScreen(
                    topBar: ClayTopBar(title: title, leading: ClayTopBar.autoLeading(context)),
                    body: ClayDescriptionList(entries: [ClayDescription('Title', title)]),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
```

### Forms

Stand the fields in a `Column` with `ClaySpacing.large` between them, in a column of a readable width (the example
holds its pages to 640 from the start edge). Every field takes the column's width. A control that is not a field (a
segmented button, a slider) takes its label and help from `ClayFormField`, so its words start where a field's do. A
switch in a form stands in a `ClayFormField` too, its label above it like a field's. A
slider says its value as a percentage of its range, as Material's does; give it `semanticFormatterCallback` to say
a count instead: `semanticFormatterCallback: (goal) => '${goal.round()} books'`.
Check the answers when the reader saves: give each problem to its field's `errorText`, in words, and move the focus
to the first one. A `ClayDatePicker` with a null `value` is an optional date; a chosen day prints in the app's locale,
as Material's dates do: Oct 2, 2026 in English, 2 Oct 2026 in British English (`Locale('en', 'GB')` in
`supportedLocales`). That is `MaterialLocalizations.of(context).formatMediumDate(day)`; write a day the same way
elsewhere on the page with it. The page's one coral key stands in `ClayScreen`'s `footer`: on a phone across the
foot, in the thumb's reach; from 600 wide, beside a rail or a sidebar, at the start of the page's column, under the
form's fields.

```dart
import 'package:clay_ui/clay_ui.dart';
import 'package:material_ui/material_ui.dart';

class AddBookForm extends StatefulWidget {
  const AddBookForm({super.key, required this.onSaved});

  final void Function(String title, String format, DateTime? started) onSaved;

  @override
  State<AddBookForm> createState() => _AddBookFormState();
}

class _AddBookFormState extends State<AddBookForm> {
  final _title = TextEditingController();
  final _titleFocus = FocusNode();
  String _format = 'paperback';
  String _status = 'toRead';
  DateTime? _started;
  String? _titleError;

  @override
  void dispose() {
    _title.dispose();
    _titleFocus.dispose();
    super.dispose();
  }

  // The form's check: the field's error in words, or null.
  String? _checkTitle(String title) => title.trim().isEmpty ? 'Enter the book’s title' : null;

  void _save() {
    setState(() => _titleError = _checkTitle(_title.text));
    if (_titleError != null) return _titleFocus.requestFocus();
    widget.onSaved(_title.text.trim(), _format, _started);
  }

  @override
  Widget build(BuildContext context) => ClayScreen(
    topBar: const ClayTopBar(title: 'Add a book'),
    footer: ClayButton.filled('Save book', onPressed: _save),
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: ClaySpacing.large,
      children: [
        ClayTextField(
          labelText: 'Title',
          controller: _title,
          focusNode: _titleFocus,
          errorText: _titleError,
        ),
        ClaySelect<String>(
          labelText: 'Format',
          value: _format,
          items: const [
            ClaySelectItem(value: 'paperback', label: 'Paperback'),
            ClaySelectItem(value: 'ebook', label: 'Ebook'),
          ],
          onChanged: (format) => setState(() => _format = format),
        ),
        ClayFormField(
          labelText: 'Status',
          child: ClaySegmentedButton<String>(
            segments: const [
              ClaySegment(value: 'toRead', label: 'To read'),
              ClaySegment(value: 'reading', label: 'Reading'),
              ClaySegment(value: 'done', label: 'Done'),
            ],
            selected: _status,
            onChanged: (status) => setState(() => _status = status),
          ),
        ),
        ClayDatePicker(
          labelText: 'Date started',
          helperText: 'Optional',
          value: _started,
          firstDate: DateTime(1900),
          lastDate: DateTime(2100),
          onChanged: (day) => setState(() => _started = day),
        ),
      ],
    ),
  );
}
```

To clear the form after a save and stay on the page for the next book, empty the controllers and set the other
answers back: `_title.clear(); setState(() { _format = 'paperback'; _status = 'toRead'; _started = null; });`.

A form can also check itself, as Material's `Form` does. Put each field in a `RawFormField` under a `ClayForm`; on a
submit that fails, the form shows every error, moves the focus to the first and checks each field again as the reader
puts it right (Material's `autovalidateMode: AutovalidateMode.onUserInteraction`; give a `RawFormField` that
`autovalidateMode` to check it from the first keystroke). With a controller, a form field's initial value is its
`initialValue`: `reset()` takes the errors away and restores that value, and leaves the controller's text as it is.
To empty the form, call `reset()` and then clear the controllers:

```dart
import 'package:clay_ui/clay_ui.dart';
import 'package:material_ui/material_ui.dart';

class QuickAdd extends StatefulWidget {
  const QuickAdd({super.key, required this.onAdd});

  final ValueChanged<String> onAdd;

  @override
  State<QuickAdd> createState() => _QuickAddState();
}

class _QuickAddState extends State<QuickAdd> {
  final _form = GlobalKey<RawFormState>();
  final _title = TextEditingController();
  final _titleFocus = FocusNode();

  @override
  void dispose() {
    _title.dispose();
    _titleFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ClayForm(
    key: _form,
    onSubmit: () {
      widget.onAdd(_title.text.trim());
      // Clear the form after a save: reset() takes the errors away, then the
      // controller empties the field.
      _form.currentState!.reset();
      _title.clear();
    },
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: ClaySpacing.large,
      children: [
        RawFormField<String>(
          focusNode: _titleFocus,
          validator: (_) => _title.text.trim().isEmpty ? 'Enter the book’s title' : null,
          builder: (field) => ClayTextField(
            labelText: 'Title',
            controller: _title,
            focusNode: _titleFocus,
            errorText: field.errorText,
            onChanged: field.didChange,
          ),
        ),
        Builder(
          builder: (context) => ClayButton.filled(
            'Add',
            onPressed: () => RawForm.of(context).submit(),
          ),
        ),
      ],
    ),
  );
}
```

### Dialogs and toasts

`showClayDialog` returns what the dialog is popped with: pop it with the answer from each `ClayDialogAction`, and
Escape, a tap beside it or system back give `null`. A destructive action takes the danger red
(`isDestructiveAction`). `showClayToast` says what happened, with a way back where there is one.

```dart
import 'package:clay_ui/clay_ui.dart';
import 'package:material_ui/material_ui.dart';

Future<void> confirmDelete(BuildContext context, String title, {required VoidCallback delete, required VoidCallback undo}) async {
  final sure = await showClayDialog<bool>(
    context: context,
    builder: (context) => ClayDialog(
      title: 'Delete “$title”?',
      content: const Text('It comes off your list.'),
      actions: [
        ClayDialogAction(label: 'Keep it', onPressed: () => Navigator.of(context).pop(false)),
        ClayDialogAction(
          label: 'Delete book',
          isDefaultAction: true,
          isDestructiveAction: true,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    ),
  );
  if (sure != true || !context.mounted) return;
  delete();
  showClayToast(context, 'Deleted “$title”', actionLabel: 'Undo', onAction: undo);
}
```

### Let the reader choose a palette

`ClayThemeData.palettes` are the six, each with an id to store, a label to show and the swatches it gives by day and
by night (its accent first). Show each by its colour as it shows now (`swatchesFor` the theme's brightness), a ball of
clay beside its name; the row in force is `selected`. Hand the chosen one to the host.

```dart
import 'package:clay_ui/clay_ui.dart';
import 'package:material_ui/material_ui.dart';

class PalettePicker extends StatelessWidget {
  const PalettePicker({super.key, required this.palette, required this.onChanged});

  final RawNamedPalette palette;
  final ValueChanged<RawNamedPalette> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = ClayTheme.of(context).colors;
    return ClayGroup(
      header: 'Colour',
      children: [
        for (final p in ClayThemeData.palettes)
          ClayListTile(
            // Its accent as it shows now, beside its name.
            leading: SizedBox.square(
              dimension: 24,
              child: ClaySurface(
                face: ClayFace.raised(colors, color: p.swatchesFor(colors.brightness).first, radius: 12),
              ),
            ),
            title: p.label,
            selected: p.id == palette.id,
            showChevron: false,
            onTap: () => onChanged(p),
          ),
      ],
    );
  }
}

// Over the app: ClayHost(palette: palette, brightness: appearance, child: child!)
```

## Building blocks

| For | Use |
| --- | --- |
| The app and its pages | `ClayHost`, `ClayScaffold`, `ClayScreen`, `ClayTopBar`, `ClayDestination`, `ClayNavigationBar`, `ClayNavigationRail`, `ClaySidebar`, `ClayTabBar`, `ClaySplitView` |
| Lists | `ClayGroup`, `ClayListTile`, `ClaySectionHeader`, `ClayGroove`, `ClayCard`, `ClayIconTile`, `ClayDescriptionList`, `ClayDisclosure`, `ClayDisclosureGroup`, `ClaySwipeRow`, `ClayReorderableList`, `ClayPullToRefresh`, `ClayTree`, `ClayTimeline`, `ClayCarousel` |
| Actions | `ClayButton` (`.filled`), `ClayIconButton`, `ClayButtonGroup`, `ClayToggle`, `ClayToggleGroup`, `ClaySplitButton`, `ClayLink`, `ClayKbd` |
| Form fields | `ClayTextField`, `ClayTextArea`, `ClayPasswordField`, `ClaySearchField`, `ClayNumberField`, `ClayOtpField`, `ClayInputGroup`, `ClaySelect`, `ClayCombobox`, `ClayTagInput`, `ClayForm`, `ClayFormField`, `ClayFileDrop` |
| Choices | `ClayCheckbox`, `ClayRadio`, `ClayRadioGroup`, `ClaySwitch`, `ClaySegmentedButton`, `ClayChip`, `ClaySlider`, `ClayRangeSlider`, `ClayRating`, `ClayColorPicker` |
| Dates and times | `ClayDatePicker`, `ClayDateRangePicker`, `ClayCalendar`, `ClayTimePicker`, `ClayTimeField`, `ClayWheelPicker` |
| Figures and charts | `ClayMeter`, `ClayDataTable`, `ClayTable`, `ClayLineChart`, `ClayAreaChart`, `ClayBarChart`, `ClayPieChart`, `ClaySparkline` |
| Marks | `ClayTag`, `ClayBadge`, `ClayAvatar`, `ClayAvatarGroup`, `ClaySkeleton`, `ClayMedia` |
| Progress and messages | `ClayProgressBar`, `ClayProgressRing`, `ClaySpinner`, `ClayStepProgress`, `showClayToast`, `ClayBanner`, `ClayStateView`, `ClayTooltip` |
| Over the page | `showClayDialog` and `ClayDialog`, `showClayBottomSheet`, `showClaySideSheet`, `showClayActionSheet`, `ClaySheetPage`, `ClayMenu`, `ClayContextMenu`, `ClayPopover`, `ClayHoverCard`, `ClayMenuBar`, `showClayCommandPalette` |
| Wayfinding | `ClayBreadcrumb`, `ClayPagination`, `ClayPageDots`, `ClayScrollArea` |
| Your own parts | `ClaySurface`, `ClayFace`, `ClayWell`, `AnimatedClaySurface`, `ClaySpacing`, `ClayMetrics` |

## Make it yours

`ClayTheme.of(context)` returns the `ClayThemeData` in scope. Clay comes in six palettes, each designed by day and
by night: `clay` (the default), `mint`, `sky`, `butter`, `peach` and `lavender` (`ClayThemeData.palettes`, or
`ClayThemeData.preset('mint', Brightness.light)`). `ClayThemeData.from(accent: color)` takes a brand colour: it picks
the accent's readable words and keeps the text and focus colours at AA contrast. Every part takes a `style:` over its
part theme in `ClayThemeData`, and `ClaySurface` with `ClayFace` draws your own parts in the same clay.

### Shapes

`ClayThemeData.shapeScheme` is the one source of Clay's corners and relief. Each part takes a step of it: bars and
chart fills the extra-small, a checkbox and a tag the small, controls the medium, groups, cards and menus the large,
dialogs and sheets the extra-large; balls, pills and the dock's places stay round. `depth` scales the relief: how far
a part stands above the ground and how far a press sinks it. A theme opens only what keeps clay clay; a value past its
band is held at the band's end (a debug build says so), and a corner style other than the continuous curve, or a
stroke, is set aside.

| Part | Default | Band |
| --- | --- | --- |
| Corner style | continuous | fixed |
| `extraSmall` | 6 | 4–8 |
| `small` | 9 | 6–12 |
| `medium` | 16 | 12–20 |
| `large` | 24 | 18–30 |
| `extraLarge` | 32 | 24–40 |
| `full` | stadium | fixed |
| Stroke | none | none |
| `depth` | 1 | 0.75–1.5 |
| A part's own corners | its step | one step on every corner, never square |

```dart
import 'package:clay_ui/clay_ui.dart';
import 'package:material_ui/material_ui.dart';

// A firmer clay: tighter corners, shallower relief.
ClayThemeData firm(Brightness brightness) {
  final theme = ClayThemeData.clay(brightness);
  final shapes = theme.shapeScheme;
  return theme.copyWith(
    shapeScheme: shapes.copyWith(
      corners: shapes.corners.copyWith(small: 7, medium: 12, large: 18, extraLarge: 24),
      depth: 0.75,
    ),
  );
}

Widget host(BuildContext context, Widget? child) =>
    ClayHost(theme: firm(Brightness.light), darkTheme: firm(Brightness.dark), child: child!);
```

A part can take its own corners from its style: a step of the theme's scale on every corner. Clay rounds evenly, so
corners that differ (two diagonal cuts, one corner alone) are set aside, and a square step goes to the extra-small one;
a debug build says so. A style's `shape` wins and is drawn as given.

```dart
import 'package:clay_ui/clay_ui.dart';
import 'package:flutter/widgets.dart';

// A card a step rounder than its own, holding a pill key.
Widget done(VoidCallback onDone) => ClayCard(
  style: const ClayStyle(corners: WidgetStatePropertyAll(RawCorners.all(RawCorner.extraLarge))),
  child: ClayButton(
    'Done',
    onPressed: onDone,
    style: const ClayStyle(corners: WidgetStatePropertyAll(RawCorners.all(RawCorner.full))),
  ),
);
```

## Testing your app

Pump the app with `ClayHost` in its `builder:`, as the app has it, and `await clayLoadFonts()` in `setUpAll` so the
words measure as on a device. Icon-only keys are found by their tooltip (`find.byTooltip('Back')`). A place in the
dock, the rail or the sidebar is a tab with its place in the set: `find.bySemanticsLabel('Books\nTab 1 of 3')`.

## Hosting one page

`package:clay_ui/clay_host.dart` holds `ClayAppShell`, `ClayTab` and `ClayShellAction`: a host's frame round one
page that something else chooses, a router's or a preview's. An app that keeps its own places builds on
`ClayScaffold.branches`.

## Performance

Clay's soft shading is drawn from small masks blurred once and cached, then painted as nine-slices: scrolling and
pressing never blur anything anew.

## Platforms

Clay supports Android, iOS, web, macOS, Windows and Linux.

## Accessibility

Text meets WCAG AA contrast on every surface by day and by night. Touch targets are at least 40 dp, ui_core's touch
floor, for a finger and a pointer alike. Keyboard focus brings a 2 px rim of the focus colour up inside a part's own
edge. Tab reaches each control; the arrow keys move within tabs, the navigation's places and open lists. A radio group,
a segmented button and a one-choice toggle group are Flutter's `RadioGroup`, each choice a `RawRadio`: one Tab stop,
on the choice, whose arrows choose as they move. A screen reader hears each checkbox, radio and switch as one, with its
state, and never as a button; a toggle button (a selected icon button, a filter chip) is a button that is selected, as
Flutter's `IconButton(isSelected:)` is. A tooltip shows on the keys' focus as on a pointer's rest. Text scales with
the platform setting. Dialogs, sheets, tabs, toasts and the navigation respect reduced motion.

## Right to left and languages

Controls follow the ambient `Directionality`, and the light falls from the top-leading corner in either direction.
The controls' own words (a field's Clear, a dialog's Cancel, how many fields need attention) come in 30 languages from
`RawWidgetsLocalizations.delegate`; `DefaultRawWidgetsLocalizations.delegate` is English alone. Give the app this
whole list, as the Mount snippet does:

```dart
MaterialApp(
  localizationsDelegates: const [
    RawWidgetsLocalizations.delegate, // Clay's own words
    ...GlobalMaterialLocalizations.delegates, // Material's, Cupertino's and the widgets'
  ],
  supportedLocales: RawWidgetsLocalizations.supportedLocales,
  builder: (context, child) => ClayHost(child: child!),
)
```

`GlobalMaterialLocalizations` comes from `material_ui`, which brings Flutter's translations with it: an app on
material_ui needs no `flutter_localizations` dependency. The example lists the same delegates. Use `clayPlural` for
phrases that depend on a count. Figures follow the locale: dates, times, the number field, the
charts' scales, readouts and shares, and a meter's percentage write the reader's digits, Arabic-Indic in Arabic.

## Requirements

Flutter 3.47 or later (Dart 3.13). The package depends on ui_core ^0.8.8 and re-exports it.

## Licence

The package uses the BSD 3-Clause License. Rubik uses the SIL Open Font License 1.1. Lucide icons use the ISC and MIT
licenses. Full notices are in `THIRD_PARTY_NOTICES/`.

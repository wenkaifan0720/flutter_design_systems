# material_expressive_ui

Material 3 Expressive components for Flutter. The package includes spring-animated buttons, form fields, pickers, charts and adaptive navigation. Its shapes, colour schemes and motion follow the AndroidX Compose implementation.

![Material Expressive gallery and Trip planner](https://raw.githubusercontent.com/wenkaifan0720/flutter_design_systems/main/packages/material_expressive_ui/screenshots/hero.png)

**[Docs and demo](https://wenkaifan0720.github.io/flutter_design_systems/docs/looks/material_expressive/)** · [Try it in Stint](https://wenkaifan0720.github.io/flutter_design_systems/docs/stint/?look=material_expressive) · [API reference](https://pub.dev/documentation/material_expressive_ui/latest/) · [All the looks](https://wenkaifan0720.github.io/flutter_design_systems/docs/)

## Install

```sh
flutter pub add material_expressive_ui material_ui
```

`material_ui` is Flutter's Material as a package (from Flutter 3.50 it leaves the SDK): your app's `MaterialApp`. Import
`package:material_expressive_ui/material_expressive_ui.dart` and `package:material_ui/material_ui.dart` (it brings
Flutter's widgets); the look's library doesn't export `flutter/widgets.dart`. It re-exports ui_core, so
`RawWidgetsLocalizations` and the `Raw*` parts come with it. The snippets draw their glyphs from `ExpressiveSymbols`,
the Material Symbols (Rounded) the package bundles: a subset, the glyphs its parts and common app screens use.

A whole app: Expressive over a `MaterialApp`, one page and one button.

```dart
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_ui/material_ui.dart';

void main() => runApp(
  MaterialApp(
    builder: (context, child) => ExpressiveHost(child: child!),
    home: ExpressiveScaffold(
      topBar: const ExpressiveAppBar(title: 'Shelf'),
      body: ExpressiveFilledButton('Add a book', onPressed: () {}),
    ),
  ),
);
```

## Mount Expressive

`ExpressiveHost` is the one mount. Put it in your app's `builder:`, above the Navigator, so every page, dialog and menu
stands inside it. It gives the theme for the brightness in force (by day, by night, or as the device is; `theme` and
`darkTheme`, or a `palette`'s), lays a Material theme to match under the Flutter parts Expressive builds on (text
editing, ink, page transitions), and holds the layer snackbars show in: `showExpressiveSnackBar` throws without it. A
change of appearance or palette moves across on the theme's motion. Load the bundled faces before the first frame:

```dart
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_ui/material_ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await expressiveLoadFonts(); // the first frame is set in Roboto Flex
  runApp(const App(appearance: null));
}

class App extends StatelessWidget {
  const App({super.key, required this.appearance});

  /// Light or dark, pinned by the reader; null follows the device.
  final Brightness? appearance;

  @override
  Widget build(BuildContext context) => MaterialApp(
    localizationsDelegates: const [
      RawWidgetsLocalizations.delegate,
      ExpressiveLocalizations.delegate,
      ...GlobalMaterialLocalizations.delegates,
    ],
    supportedLocales: RawWidgetsLocalizations.supportedLocales,
    builder: (context, child) => ExpressiveHost(brightness: appearance, child: child!),
    home: const ExpressiveScaffold(
      topBar: ExpressiveAppBar(title: 'Shelf'),
      body: Text('Your reading list'),
    ),
  );
}
```

These are the delegates an app lists: `RawWidgetsLocalizations.delegate` (ui_core's words for shared actions, in 30
languages), `ExpressiveLocalizations.delegate` (Expressive's own, English for every locale until the app gives its own)
and material_ui's `GlobalMaterialLocalizations.delegates` (the pickers' titles, modes and field labels, in each of
Material's languages). An app on material_ui needs no `flutter_localizations`: `GlobalMaterialLocalizations` comes
from material_ui. Under a `CupertinoApp` (from `cupertino_ui`) or a bare `WidgetsApp` the host goes in the same
place, with the same delegates: a field is Flutter's Material text field underneath.

## Build an app

The example app, [example/lib/main.dart](example/lib/main.dart), is a whole reading list to copy: these are its parts.
The gallery, every component on a page of its own, is `example/lib/gallery.dart` (`flutter run -t lib/gallery.dart`).

### The shell and its places

`ExpressiveAppShell.branches` holds the app's places: the navigation bar along a phone's foot, the rail from 600 wide
and the expanded rail from 1200. Each place keeps its own pages; a page pushed on one stands beside the rail (a phone's
bar steps away for it), back pops it, and choosing the place again goes back to its first page. The arrow keys move
between the places. An `action` (a FAB) floats over a phone's pages and heads the rail. A modal bottom sheet
(`showExpressiveBottomSheet`) covers the navigation bar, as Material's does.

```dart
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_ui/material_ui.dart';

class ShelfShell extends StatefulWidget {
  const ShelfShell({super.key});

  @override
  State<ShelfShell> createState() => _ShelfShellState();
}

class _ShelfShellState extends State<ShelfShell> {
  int _place = 0;

  @override
  Widget build(BuildContext context) => ExpressiveAppShell.branches(
    destinations: const [
      ExpressiveNavItem(ExpressiveSymbols.book, 'Books'),
      ExpressiveNavItem(ExpressiveSymbols.add, 'Add'),
      ExpressiveNavItem(ExpressiveSymbols.settings, 'Settings'),
    ],
    selectedIndex: _place,
    onDestinationSelected: (place) => setState(() => _place = place),
    branches: [
      (context) => const ExpressiveScaffold(topBar: ExpressiveAppBar(title: 'Books'), body: Text('Your reading list')),
      (context) => const ExpressiveScaffold(topBar: ExpressiveAppBar(title: 'Add a book'), body: Text('Title')),
      (context) => const ExpressiveScaffold(topBar: ExpressiveAppBar(title: 'Settings'), body: Text('Appearance')),
    ],
  );
}
```

### A list and its pages

An `ExpressiveListSection` of `ExpressiveListTile`s, each pushing its own page. A pushed page's `ExpressiveAppBar`
shows the back arrow by itself. A tile's `trailing` holds a tag or a control of its own, reachable apart from the row.

```dart
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_ui/material_ui.dart';

class BooksPage extends StatelessWidget {
  const BooksPage({super.key, required this.titles});

  final List<String> titles;

  @override
  Widget build(BuildContext context) => ExpressiveScaffold(
    topBar: const ExpressiveAppBar(title: 'Books'),
    body: ExpressiveListSection(
      header: '${titles.length} books',
      children: [
        for (final title in titles)
          ExpressiveListTile(
            title: Text(title),
            subtitle: const Text('Reading'),
            trailing: const ExpressiveTag('Reading', tone: ExpressiveTone.primary),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => ExpressiveScaffold(
                  topBar: ExpressiveAppBar(title: title),
                  body: ExpressiveDescriptionList(
                    items: [ExpressiveDescriptionItem('Title', title)],
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

Stand the fields in a `Column` with `ExpressiveSpacing.s24` between them, in a column of a readable width (the example
holds its pages to 640 from the start edge). Every field takes the column's width, as Material's do: a text field, a
select, a date. Check the answers when the reader saves: give each problem to its field's `errorText`, in words, and
move the focus to the first one. An `ExpressiveDockedDatePicker` with a null `value` is an optional date; a chosen
day prints as 3 Oct 2026. Rows of choices (`ExpressiveRadioGroup`, `ExpressiveSwitchRow`) take
`contentPadding: EdgeInsets.zero` to put their marks on the column's edges.

Expressive's fields are not `FormField`s, so a form needs no `Form`, no `validator` and no `autovalidateMode`:
check on save, as below, and clear an answer's error as the reader puts it right if you like (`onChanged`). A
`Form`'s `reset()` passes the fields by; to empty the form after a save, clear the controllers and the values, as
`_save` does. On a desk the footer of an `ExpressiveScaffold` stands at the column's start, as wide as its keys.

```dart
import 'package:material_expressive_ui/material_expressive_ui.dart';
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
    // Saved: the form is empty again for the next book.
    _title.clear();
    setState(() {
      _format = 'paperback';
      _started = null;
    });
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: ExpressiveSpacing.s24,
    children: [
      ExpressiveTextField(
        labelText: 'Title',
        controller: _title,
        focusNode: _titleFocus,
        errorText: _titleError,
      ),
      ExpressiveSelect<String>(
        labelText: 'Format',
        value: _format,
        options: const [
          ExpressiveSelectOption('paperback', 'Paperback'),
          ExpressiveSelectOption('ebook', 'Ebook'),
        ],
        onChanged: (format) => setState(() => _format = format),
      ),
      ExpressiveDockedDatePicker(
        label: 'Date started',
        value: _started,
        onChanged: (day) => setState(() => _started = day),
      ),
      ExpressiveFilledButton('Save book', expand: true, onPressed: _save),
    ],
  );
}
```

### Dialogs and snackbars

`showExpressiveDialog` returns what the dialog is popped with: each `ExpressiveDialogAction`'s `value`, or `null`
when it is dismissed (Escape, the scrim, system back). A destructive action takes the `error` role
(`isDestructiveAction`). On a page, give a destructive button the error container
(`ExpressiveFilledButton.styleFrom`), apart from the primary act. `showExpressiveSnackBar` says what happened.

```dart
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_ui/material_ui.dart';

Future<bool> confirmDelete(BuildContext context, String title) async {
  final delete = await showExpressiveDialog<bool>(
    context: context,
    builder: (context) => ExpressiveDialog(
      title: 'Delete “$title”?',
      text: 'It comes off your list. You cannot undo this.',
      actions: const [
        ExpressiveDialogAction('Keep it', value: false),
        ExpressiveDialogAction('Delete book', value: true, isDestructiveAction: true),
      ],
    ),
  );
  if (delete != true || !context.mounted) return false;
  showExpressiveSnackBar(context, 'Deleted “$title”');
  return true;
}
```

### Let the reader choose a palette

`ExpressiveThemeData.palettes` are the six, each with an id to store, a label to show and the swatches it gives by day
and by night (its primary and its surface). Show each by its colour as it shows now (`swatchesFor` the theme's
brightness) beside its name, as a radio option's `leading`, and hand the chosen one to the host.

```dart
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_ui/material_ui.dart';

class PalettePicker extends StatelessWidget {
  const PalettePicker({super.key, required this.palette, required this.onChanged});

  final RawNamedPalette palette;
  final ValueChanged<RawNamedPalette> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = context.expressiveTheme;
    return ExpressiveRadioGroup<String>(
      semanticLabel: 'Colour',
      value: palette.id,
      options: [
        for (final p in ExpressiveThemeData.palettes)
          ExpressiveRadioOption(
            value: p.id,
            label: p.label,
            // Its primary as it shows now, beside its name.
            leading: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: p.swatchesFor(theme.brightness).first,
                shape: BoxShape.circle,
                border: Border.all(color: theme.colors.outlineVariant),
              ),
            ),
          ),
      ],
      onChanged: (id) => onChanged(ExpressiveThemeData.palettes.firstWhere((p) => p.id == id)),
    );
  }
}

// Over the app: ExpressiveHost(palette: palette, brightness: appearance, child: child!)
```

## Building blocks

| For | Use |
| --- | --- |
| The app and its pages | `ExpressiveHost`, `ExpressiveAppShell`, `ExpressiveScaffold`, `ExpressiveAppBar`, `ExpressiveNavigationBar`, `ExpressiveNavigationRail`, `ExpressiveNavigationDrawer`, `ExpressiveTabBar` |
| Lists | `ExpressiveListSection`, `ExpressiveListTile`, `ExpressiveSectionHeader`, `ExpressiveDescriptionList`, `ExpressiveSwipeActions`, `ExpressiveSwipeToDismiss`, `ExpressiveReorderableListView`, `ExpressiveDisclosure`, `ExpressiveDivider`, `ExpressiveGrid`, `ExpressiveCard` |
| Actions | `ExpressiveFilledButton` (`.tonal`), `ExpressiveOutlinedButton`, `ExpressiveElevatedButton`, `ExpressiveTextButton`, `ExpressiveIconButton`, `ExpressiveToggleButton`, `ExpressiveButtonGroup`, `ExpressiveSplitButton`, `ExpressiveFloatingActionButton`, `ExpressiveFabMenu`, `ExpressiveFloatingToolbar`, `ExpressiveLink` |
| Form fields | `ExpressiveTextField`, `ExpressiveTextArea`, `ExpressivePasswordField`, `ExpressiveSearchField`, `ExpressiveNumberField`, `ExpressiveInputOtp`, `ExpressiveInputGroup`, `ExpressiveFormField`, `ExpressiveSelect`, `ExpressiveCombobox`, `ExpressiveMultiSelect`, `ExpressiveFileUpload` |
| Choices | `ExpressiveRadioGroup`, `ExpressiveRadioRow`, `ExpressiveCheckboxRow`, `ExpressiveSwitchRow`, `ExpressiveCheckbox`, `ExpressiveRadio`, `ExpressiveSwitch`, `ExpressiveSegmentedButton`, `ExpressiveChoiceGroup`, `ExpressiveChip`, `ExpressiveChipRow`, `ExpressiveSlider`, `ExpressiveRangeSlider`, `ExpressiveRating`, `ExpressiveColorPicker` |
| Dates and times | `ExpressiveDockedDatePicker`, `ExpressiveDatePicker`, `ExpressiveDateRangePicker`, `ExpressiveCalendar`, `ExpressiveTimePicker`, `ExpressiveTimeInput`, `showExpressiveDatePicker`, `showExpressiveTimePicker`, `ExpressiveFormat` |
| Figures and charts | `ExpressiveStat`, `ExpressiveAmount`, `ExpressiveCounter`, `ExpressiveMeter`, `ExpressiveDataTable`, `ExpressiveTable`, `ExpressiveLineChart`, `ExpressiveAreaChart`, `ExpressiveBarChart`, `ExpressivePieChart`, `ExpressiveSparkline` |
| Marks | `ExpressiveTag`, `ExpressiveBadge`, `ExpressiveAvatar`, `ExpressiveAvatarGroup`, `ExpressiveSkeleton`, `ExpressiveImagePlaceholder` |
| Progress and messages | `ExpressiveLinearProgressIndicator`, `ExpressiveCircularProgressIndicator`, `ExpressiveLoadingIndicator`, `ExpressiveStepProgress`, `showExpressiveSnackBar`, `ExpressiveBanner`, `ExpressiveEmptyState`, `ExpressiveStatusView`, `ExpressiveTooltip`, `ExpressiveMessageBubble` |
| Over the page | `showExpressiveDialog` and `ExpressiveDialog`, `showExpressiveBottomSheet`, `ExpressiveSheet`, `showExpressiveMenu`, `ExpressiveMenu`, `ExpressiveMenuBar`, `showExpressivePopover`, `ExpressiveCoachMark` |
| Layout | `ExpressiveCarouselView`, `ExpressivePageDots`, `ExpressiveTimeline`, `ExpressivePagination`, `ExpressiveBreadcrumb`, `ExpressiveScrollArea`, `ExpressiveResizable`, `ExpressiveRefreshIndicator`, `ExpressiveSpacing` |

## Make it yours

`context.expressiveTheme` returns the `ExpressiveThemeData` in scope. Choose one of six palettes
(`ExpressiveThemeData.palettes`, or `ExpressiveThemeData.preset(id, brightness)`) or derive a scheme from a brand colour
(`ExpressiveThemeData.from(seed: brand, brightness: brightness)`); each preset has light, dark and high-contrast colours
(`contrastLevel: 1`).

| Preset | Seed | Variant | Motion |
|---|---|---|---|
| `baseline` | #6750A4 | tonal spot | expressive |
| `slate` | #52667A | neutral | standard |
| `bloom` | #B5487A | vibrant | expressive |
| `grove` | #2E7D5B | tonal spot | expressive |
| `ember` | #C25A1F | vibrant | expressive |
| `tide` | #3D7EA0 | tonal spot | expressive |

A variant is how the seed spreads over the colour roles: tonal spot keeps every role in the seed's family, soft;
vibrant keeps them there, fuller; neutral is nearly grey. The secondary roles (the navigation indicator, a slider's
inactive track) stay in the seed's family in every preset.

Use `copyWith` to set density, typography, the shape scheme, motion or a component theme. An individual widget's `style` overrides the component theme for that widget, and a
`WidgetStateProperty` can vary a colour or shape for focus, selection and other states. The colour roles, shapes and
motion stay Material's: a theme changes their values, not what each role is for.

### Your corners

The theme's corners are M3's five steps, 4, 8, 12, 16 and 28, in `ExpressiveThemeData.shapeScheme`. An app can give its
own, and each step is held to Expressive's band for it (`ExpressiveThemeData.shapeLimits`), so the scale keeps its
order and extra large stays well above large:

```dart
final theme = ExpressiveThemeData.baseline().copyWith(
  shapeScheme: ExpressiveThemeData.defaultShapeScheme.copyWith(
    corners: ExpressiveThemeData.defaultShapeScheme.corners.copyWith(medium: 16),
  ),
);
```

One part's corners go on its style, each corner a step of the theme's scale; start and end follow the reading
direction, and a press still morphs the part on its spring. Here the key rounds its top corners and keeps its bottom
ones square, as a tab's are: one step along the top, another along the bottom:

```dart
ExpressiveFilledButton(
  'Send',
  style: const ExpressiveComponentThemeData(
    corners: WidgetStatePropertyAll(
      RawCorners(
        topStart: RawCorner.large,
        topEnd: RawCorner.large,
        bottomStart: RawCorner.none,
        bottomEnd: RawCorner.none,
      ),
    ),
  ),
  onPressed: send,
)
```

A joined part (a segmented button, a split button, a menu's group) takes them at its outer corners only.

## Accessibility and languages

- Every control is reachable with Tab and works with Enter or Space. Selects, comboboxes and menus take the arrow keys, Home and End, and Escape closes them and gives the focus back to what opened them. A radio group or a one-choice segmented button is one Tab stop.
- Touch targets are at least 40 dp, ui_core's touch floor, for a finger and a pointer alike; a `RawTapTargetScope` under the theme raises the floor for an app's pages. Groups of chips and tags stand 8 dp apart, their targets meeting in the room between them. Text scales with the platform setting, and the parts Material caps (a date picker's month label at 2×) are capped the same way.
- The layout follows `Directionality`, so a right-to-left app mirrors its rows, menus and navigation.
- Roboto Flex draws Latin, Greek and Cyrillic; other scripts fall back to the platform's fonts (on the web, Flutter fetches them). An app that ships its own faces for them, Noto Sans JP or Noto Sans Arabic say, names them in `ExpressiveTextTheme.fontFamilyFallback` (`theme.copyWith(type: theme.type.copyWith(fontFamilyFallback: ['NotoSansJP', 'NotoSansArabic']))`): every text style takes the list, and so does the Material theme `ExpressiveHost` lays under the parts.
- List the delegates under "Mount Expressive": `RawWidgetsLocalizations` speaks ui_core's shared actions (a time picker's words among them) in 30 languages, `ExpressiveLocalizations` gives Expressive's component text, English for every locale until the app supplies its own, and the pickers' titles, modes and field labels come from the app's `MaterialLocalizations`, as Material's own pickers' do: in each of Material's languages, from `GlobalMaterialLocalizations.delegates` or, when the app lists no Material localizations, from the host.
- Give icon-only controls a `semanticLabel`, and give a rating a name such as “Rate this trip”, so a screen reader announces it in context.

## Custom components

To adapt a component, copy its source into your app and import `package:material_expressive_ui/material_expressive_parts.dart` for its drawing and animation helpers. Check copied components when updating the package because these helpers may change between releases.

## Requirements

Flutter 3.47 or later (Dart 3.13). The package depends on ui_core ^0.8.2 and re-exports it.

## Licences

The package is BSD-3-Clause. Roboto Flex and Jost use the SIL Open Font License 1.1. Material Symbols Rounded and the AndroidX graphics-shapes port use Apache 2.0. The `material_new_shapes` port uses the MIT licence. Notices ship in `LICENSE` and `THIRD_PARTY_NOTICES/`.

This is an independent implementation of Material 3 Expressive.

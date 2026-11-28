# civic_ui

A Flutter design system for public services: one thing per page, large type, a heavy yellow focus, errors said in
words, answers checked before they are sent.

![Civic's start page at desktop and phone width, by day](https://raw.githubusercontent.com/wenkaifan0720/flutter_design_systems/main/packages/civic_ui/screenshots/hero.png)

**[Docs and demo](https://wenkaifan0720.github.io/flutter_design_systems/docs/looks/civic/)** · [Try it in Stint](https://wenkaifan0720.github.io/flutter_design_systems/docs/stint/?look=civic) · [API reference](https://pub.dev/documentation/civic_ui/latest/) · [All the looks](https://wenkaifan0720.github.io/flutter_design_systems/docs/)

## Install

```sh
flutter pub add civic_ui material_ui lucide_icons_flutter
```

`material_ui` is Flutter's Material as a package (from Flutter 3.50 it leaves the SDK): your app's `MaterialApp`.
`lucide_icons_flutter` holds the glyphs the snippets here use; Civic's own are Lucide's too. Import
`package:civic_ui/civic_ui.dart` and `package:material_ui/material_ui.dart` (it brings Flutter's widgets); Civic's
library doesn't export `flutter/widgets.dart`.

A whole app: Civic over a `MaterialApp`, one page and one button.

```dart
import 'package:civic_ui/civic_ui.dart';
import 'package:material_ui/material_ui.dart';

void main() => runApp(
  MaterialApp(
    builder: (context, child) => CivicHost(child: child!),
    home: CivicScreen(
      topBar: const CivicTopBar(title: 'Shelf'),
      body: CivicButton(onPressed: () {}, child: const Text('Add a book')),
    ),
  ),
);
```

## Mount Civic

`CivicHost` is the one mount. Put it in your app's `builder:`, above the Navigator, so every page, dialog and menu
stands inside it. It gives the theme for the brightness in force (by day, by night, or as the device is), the page's
ground and words, Civic's page change for every route a `MaterialApp` pushes, and the toaster `CivicToast.show`
needs. A change of appearance or palette blends over 200 ms. Load Civic's faces before the first frame:

```dart
import 'package:civic_ui/civic_ui.dart';
import 'package:material_ui/material_ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await civicLoadFonts(); // the first frame is set in Civic's faces
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
      ...GlobalMaterialLocalizations.delegates,
    ],
    supportedLocales: RawWidgetsLocalizations.supportedLocales,
    builder: (context, child) => CivicHost(brightness: appearance, child: child!),
    home: const CivicScreen(
      topBar: CivicTopBar(title: 'Shelf'),
      body: Text('Your reading list'),
    ),
  );
}
```

Under a `CupertinoApp` (from `cupertino_ui`) or a bare `WidgetsApp` the host goes in the same place.

## Build an app

The example app, [example/lib/main.dart](example/lib/main.dart), is a whole reading list to copy: these are its parts.

### The shell and its places

`CivicAppShell.branches` holds the app's places: along a phone's foot, as a rail from 600 wide and as the side
navigation from 1024. Each place keeps its own pages; a page pushed on one stands beside the rail or the side
navigation (a phone's bar steps away for it), back pops it, and choosing the place again goes back to its first page.

```dart
import 'package:civic_ui/civic_ui.dart';
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
  Widget build(BuildContext context) => CivicAppShell.branches(
    brand: 'Shelf',
    destinations: const [
      CivicNavItem(LucideIcons.libraryBig, 'Books'),
      CivicNavItem(LucideIcons.plus, 'Add'),
      CivicNavItem(LucideIcons.settings, 'Settings'),
    ],
    selectedIndex: _place,
    onDestinationSelected: (place) => setState(() => _place = place),
    branches: [
      (context) => const CivicScreen(topBar: CivicTopBar(title: 'Books'), body: Text('Your reading list')),
      (context) => const CivicScreen(topBar: CivicTopBar(title: 'Add'), body: Text('Add a book')),
      (context) => const CivicScreen(topBar: CivicTopBar(title: 'Settings'), body: Text('Appearance')),
    ],
  );
}
```

### A list and its pages

A list of rows, each pushing its own page. The pushed page's `CivicTopBar.autoLeading` is its way back (from 1024 wide it
hangs in the gutter, so the title keeps the column's line). The bar names the page's place ("Book"); the page says
what it is in a `CivicPageHeading`, which a screen reader hears as the page's heading. On a phone a row's tag stands
on a line of its own under its title, so a long title never squeezes it; from 600 wide it stands at the row's end.

```dart
import 'package:civic_ui/civic_ui.dart';
import 'package:material_ui/material_ui.dart';

class BooksPage extends StatelessWidget {
  const BooksPage({super.key, required this.titles});

  final List<String> titles;

  @override
  Widget build(BuildContext context) => CivicScreen(
    topBar: const CivicTopBar(title: 'Books'),
    body: CivicListGroup(
      title: CivicFormat.plural(titles.length, 'book'),
      children: [
        for (final title in titles)
          CivicListRow(
            title: Text(title),
            trailing: const CivicTag(label: 'Reading', tone: CivicTone.info),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => CivicScreen(
                  topBar: CivicTopBar(title: 'Book', leading: CivicTopBar.autoLeading(context)),
                  body: CivicPageHeading(title),
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

Check the answers when the reader saves. Say each problem twice: in a `CivicErrorSummary` at the top of the form
(it takes the focus and scrolls into view with the page's heading over it, and each line moves the focus to its
field) and at the field (`errorText`). Fields take their column's width; put them in a `Column` with
`CivicSpacing.s24` between them and `s32` before the action.

Civic's fields are no `FormField`s: the page holds the answers (a controller, a value) and checks them on save, as a
public service does, never as the reader types, so there is no `autovalidateMode` to set. Once a field's problem is
shown, check again on the next save; the summary takes the focus each time. A place of the app's shell keeps its
first page, so clear the form after a save: clear the controllers and set the other answers back, as `_save` does
below.

A date field shows a day in the order of the app's locale (11/14/2026 under a default `MaterialApp`, which is
American English), and `CivicFormat.dateOf` writes it in the same order with its month in words ("November 14,
2026"), so a page never writes a day two ways. For day-first English, give the app `locale: Locale('en', 'GB')` and
list it in `supportedLocales` (`[Locale('en', 'GB'), ...RawWidgetsLocalizations.supportedLocales]`): the field
shows 14/11/2026 and `dateOf` writes "14 November 2026".

```dart
import 'package:civic_ui/civic_ui.dart';
import 'package:material_ui/material_ui.dart';

class BookForm extends StatefulWidget {
  const BookForm({super.key, required this.onSaved});

  final void Function(String title, DateTime? started) onSaved;

  @override
  State<BookForm> createState() => _BookFormState();
}

class _BookFormState extends State<BookForm> {
  final _title = TextEditingController();
  final _titleFocus = FocusNode();
  DateTime? _started;
  String? _titleError;

  @override
  void dispose() {
    _title.dispose();
    _titleFocus.dispose();
    super.dispose();
  }

  void _save() {
    setState(() => _titleError = _title.text.trim().isEmpty ? 'Enter the book’s title' : null);
    if (_titleError != null) return;
    widget.onSaved(_title.text.trim(), _started);
    // Clear the form after a save: the place keeps this page.
    _title.clear();
    setState(() => _started = null);
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: CivicSpacing.s24,
    children: [
      if (_titleError case final error?)
        CivicErrorSummary(
          title: 'There is a problem',
          errors: [CivicErrorSummaryItem(text: error, onPressed: _titleFocus.requestFocus)],
        ),
      CivicTextField(
        labelText: 'Title',
        controller: _title,
        focusNode: _titleFocus,
        errorText: _titleError,
      ),
      CivicDatePicker(
        labelText: 'Date started',
        helperText: 'Optional. For example, ${CivicDatePicker.exampleOf(context, DateTime(2026, 3, 27))}',
        value: _started,
        firstDate: DateTime(1900),
        lastDate: DateTime(2100),
        onChanged: (day) => setState(() => _started = day),
      ),
      const SizedBox(height: CivicSpacing.s8), // s32 before the action
      CivicButton(onPressed: _save, child: const Text('Save book')),
    ],
  );
}
```

### Dialogs

`showCivicDialog` returns what the dialog is popped with: pop it with the answer.

```dart
import 'package:civic_ui/civic_ui.dart';
import 'package:material_ui/material_ui.dart';

Future<bool> confirmDelete(BuildContext context, String title) async {
  final delete = await showCivicDialog<bool>(
    context: context,
    builder: (context) => CivicDialog(
      title: 'Delete “$title”?',
      content: const Text('It comes off your list. You cannot undo this.'),
      actions: [
        CivicButton(
          isDestructiveAction: true,
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Delete book'),
        ),
        CivicButton.secondary(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Keep it'),
        ),
      ],
    ),
  );
  if (delete != true || !context.mounted) return false;
  CivicToast.show(context, 'Deleted “$title”');
  return true;
}
```

### Let the reader choose a palette

`CivicThemeData.palettes` are Civic's six, each with an id to store, a label to show and the swatch it gives by day
and by night. Show each by its colour as it shows now (`swatchesFor` the theme's brightness) beside its name, as a radio's
`leading`, and hand the chosen one to the host.

```dart
import 'package:civic_ui/civic_ui.dart';
import 'package:material_ui/material_ui.dart';

class PalettePicker extends StatelessWidget {
  const PalettePicker({super.key, required this.palette, required this.onChanged});

  final RawNamedPalette palette;
  final ValueChanged<RawNamedPalette> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = context.civicTheme;
    return CivicRadioGroup<String>(
      labelText: 'Colour',
      helperText: 'The colour of buttons, links and marks.',
      groupValue: palette.id,
      onChanged: (id) => onChanged(CivicThemeData.palettes.firstWhere((p) => p.id == id)),
      children: [
        for (final p in CivicThemeData.palettes)
          CivicRadio(
            value: p.id,
            labelText: p.label,
            // The colour as it shows now, beside its name.
            leading: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: p.swatchesFor(theme.brightness).first,
                shape: BoxShape.circle,
                border: Border.all(color: theme.border),
              ),
            ),
          ),
      ],
    );
  }
}

// Over the app: CivicHost(palette: palette, brightness: appearance, child: child!)
```

## Building blocks

| For | Use |
| --- | --- |
| The app and its pages | `CivicHost`, `CivicAppShell`, `CivicScreen`, `CivicTopBar`, `CivicNavigationBar`, `CivicSideNavigation`, `CivicScaffold` and `CivicPageBody` (a service's question pages), `CivicPageRoute` |
| Actions | `CivicButton`, `CivicIconButton`, `CivicButtonGroup`, `CivicSplitButton`, `CivicLink`, `CivicBackLink`, `CivicActionBar` |
| Questions | `CivicTextField`, `CivicTextArea`, `CivicNumberField`, `CivicPasswordField`, `CivicSearchField`, `CivicCodeField`, `CivicAmount`, `CivicSelect`, `CivicCombobox`, `CivicMultiSelect`, `CivicRadioGroup`, `CivicCheckbox`, `CivicSwitch`, `CivicSegmentedControl`, `CivicToggleGroup`, `CivicSlider`, `CivicRangeSlider`, `CivicRating`, `CivicColorPicker`, `CivicFileUpload`, `CivicFieldset` |
| Dates and times | `CivicDatePicker`, `CivicDateRangePicker`, `CivicDateInput`, `CivicTimeInput`, `CivicCalendar`, `CivicWheelPicker` |
| Errors and messages | `CivicErrorSummary`, `CivicNotificationBanner`, `CivicConfirmationPanel`, `CivicInset`, `CivicWarning`, `CivicToast`, `CivicEmptyState` |
| Lists and data | `CivicListGroup` and `CivicListRow`, `CivicSwipeActions`, `CivicReorderableList`, `CivicSummaryList`, `CivicSummaryCard`, `CivicTable`, `CivicTree`, `CivicTimeline`, `CivicPagination`, `CivicKeyFigure` |
| Charts | `CivicBarChart`, `CivicLineChart`, `CivicAreaChart`, `CivicPieChart`, `CivicSparkline` |
| Status | `CivicTag`, `CivicBadge`, `CivicAvatar`, `CivicMeter`, `CivicProgressBar`, `CivicSpinner`, `CivicSkeleton`, `CivicStepIndicator`, `CivicPageDots` |
| Over the page | `showCivicDialog` and `CivicDialog`, `showCivicBottomSheet`, `showCivicSideSheet`, `showCivicActionSheet`, `showCivicCommandPalette`, `CivicMenu`, `CivicPopover`, `CivicTooltip` |
| Layout | `CivicCard`, `CivicGrid`, `CivicSplitView`, `CivicAccordion`, `CivicDetails`, `CivicTabBar`, `CivicBreadcrumbs`, `CivicPageHeading`, `CivicSectionHeader`, `CivicSectionBreak`, `CivicScrollArea`, `CivicCarousel`, `CivicImage`, `CivicChip`, `CivicKbd`, `CivicPullToRefresh` |

Atkinson Hyperlegible Next is the default typeface. One colour marks actions (blue, or one of six palettes), red marks
errors, and a yellow focus with a dark ink bar shows which control the keyboard will move, by day and by night.

## Make it yours

Civic keeps what makes it trustworthy: the yellow focus over a thick ink bar, the fields' 2 pt ink edges, large type, and tap
targets of at least 40 for a finger and 24 for a pointer (ui_core's floors). Inside that, your service's colours, face and
spacing are yours.

Six palettes, each an action colour Civic's words, errors and focus stand beside: civic (blue, the default), harbour,
indigo, heather, plum and slate, in `CivicThemeData.palettes`. Give one to the host (see
[Let the reader choose a palette](#let-the-reader-choose-a-palette)), or make its themes yourself; an app that stores the
id finds the palette by it again:

```dart
CivicThemeData.preset('harbour', Brightness.light)
```

Your brand. Each colour is held to 7:1 against the page, darkened by day and lightened by night, its hue kept
(#0A7D4F becomes about #086640 by day and #0FB673 by night):

```dart
MaterialApp(
  builder: (context, child) => CivicHost(
    theme: CivicThemeData.from(
      brightness: Brightness.light,
      action: const Color(0xFF0A7D4F),
      fontFamily: 'Inter', // reaches every part and Flutter's own widgets
      fontFamilyFallback: const ['NotoSansJP'], // for a script the face lacks
    ),
    darkTheme: CivicThemeData.from(
      brightness: Brightness.dark,
      action: const Color(0xFF0A7D4F),
      fontFamily: 'Inter',
      fontFamilyFallback: const ['NotoSansJP'],
    ),
    child: child!,
  ),
)
```

Every primary button, through its slot in the theme (each part has one, and each kind of button its own):

```dart
CivicThemeData.light().copyWith(
  primaryButtonStyle: const CivicStyle(
    padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 40)),
  ),
)
```

One button, through its `style:`, which wins over the theme:

```dart
CivicButton.secondary(
  style: CivicStyle(fill: WidgetStatePropertyAll(context.civicTheme.surface)),
  onPressed: () {},
  child: const Text('Save and come back later'),
)
```

Your corners. Civic's steps are 2, 4, 8, 12 and 16, round; each moves within a band where Civic still reads as plain and
public (`CivicThemeData.shapeLimits`), and a field, a select, a row, a table's cell and a notice (a panel, a banner, an inset, an error summary) stay square:

| Step | Civic's | Band | On |
| --- | --- | --- | --- |
| extraSmall | 2 | 1–3 | a bar, a badge, a sheet's handle |
| small | 4 | 2–6 | a button, a tag, a chip, a tooltip, a menu |
| medium | 8 | 4–12 | a card, a dialog, a sheet, an image, a list's card |
| large | 12 | 8–16 | a part's own corners |
| extraLarge | 16 | 12–20 | a part's own corners |

```dart
CivicThemeData.light().copyWith(
  shapeScheme: const RawShapeScheme(
    corners: RawCornerScale(
      extraSmall: 2,
      small: 6,
      medium: 12,
      large: 16,
      extraLarge: 20,
    ),
  ),
)
```

One part's own corners, a step at each, start and end as the text reads: here rounded along the top and square along
the bottom, as a file's tab is. A full corner is held to extra large:

```dart
CivicCard(
  title: 'Your permit',
  style: const CivicStyle(
    corners: WidgetStatePropertyAll(
      RawCorners(
        topStart: RawCorner.large,
        topEnd: RawCorner.large,
        bottomStart: RawCorner.none,
        bottomEnd: RawCorner.none,
      ),
    ),
  ),
  child: const Text('Zone B, until 2 November'),
)
```

A part's documentation says which slots it reads. Your own part can wear the look with `CivicFace` (a button's face
on its solid edge) and `CivicWell` (a field's box), which bring the focus with them.

## Accessibility

Every part works at 200% text, right to left, with a screen reader and with the keyboard alone. Errors are said in
words twice: in a summary at the top of the page, which takes the focus and links to each field, and at the field,
which stands on the error rule. Targets are 40 points for a finger and 24 for a
pointer at the least. Under Reduce Motion, on any platform that asks for it (iOS's setting included), a colour or
opacity change is a short fade and a dialog is up within 150 ms; Civic's moves are critically damped, so nothing
bounces.

## Languages and right to left

Civic's parts take their own words (Back, Close), and a date field and `CivicFormat`'s dates their order, month
words and digits, from ui_core's localizations, in 30 languages. Give a `MaterialApp` one list of delegates, as the
mount above does:

```dart
MaterialApp(
  localizationsDelegates: const [
    RawWidgetsLocalizations.delegate, // Civic's own words, in 30 languages
    ...GlobalMaterialLocalizations.delegates, // material_ui's, Cupertino's and the widgets'
  ],
  supportedLocales: RawWidgetsLocalizations.supportedLocales,
  home: const Text('Your reading list'),
)
```

`GlobalMaterialLocalizations` comes from material_ui, so an app on material_ui needs no `flutter_localizations`. An
app that serves a region lists it too (`Locale('en', 'GB')` writes the day first). The words of your service
(Continue, There is a problem, Step 1 of 3, Change) are yours to give, in your reader's language.

A page in Arabic reads right to left in Noto Sans Arabic, and the example service says its counts in the form each
number takes. For another script, load a face for it and name it in `CivicThemeData.from(fontFamilyFallback:)`:
every step of the type falls back on it.

## Keyboard navigation

Use the arrow keys to select a tab. In an application shell, F6 moves focus between navigation and page content.
Type in a combobox to filter the options, then press Enter to choose one. A dialog keeps focus inside while open
and restores it on dismissal. Civic uses [ui_core](https://pub.dev/packages/ui_core) for these interactions.

## Requirements

Flutter 3.47.0 or later (Dart 3.13), on Android, iOS, web, macOS, Windows and Linux.

## Licences

Civic's code is under the BSD 3-Clause License. Its faces are under the SIL Open Font License 1.1: Atkinson Hyperlegible Next and Mono (Braille
Institute of America) and Noto Sans Arabic (the Noto Project Authors); see `THIRD_PARTY_NOTICES/`. Its glyphs are
Lucide's (ISC). The patterns of public-service design it follows are widely shared; no code, tokens or assets of any
design system were taken.

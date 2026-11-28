# ledger_ui

A Flutter design system kept in ink on warm paper, with ruled tables, tabular amounts, accessible form controls and responsive navigation. Six colour presets, each designed for light and dark.

![Home at 1440 by day beside a phone by night](https://raw.githubusercontent.com/wenkaifan0720/flutter_design_systems/main/packages/ledger_ui/screenshots/hero.webp)

**[Docs and demo](https://wenkaifan0720.github.io/flutter_design_systems/docs/looks/ledger/)** · [Try it in Stint](https://wenkaifan0720.github.io/flutter_design_systems/docs/stint/?look=ledger) · [API reference](https://pub.dev/documentation/ledger_ui/latest/) · [All the looks](https://wenkaifan0720.github.io/flutter_design_systems/docs/)

## Install

```sh
flutter pub add ledger_ui material_ui lucide_icons_flutter
```

`material_ui` is Flutter's Material as a package (from Flutter 3.50 it leaves the SDK): your app's `MaterialApp`.
`lucide_icons_flutter` holds the glyphs the snippets here use; Ledger's own are Lucide's too. Import
`package:ledger_ui/ledger_ui.dart` and `package:material_ui/material_ui.dart` (it brings Flutter's widgets); Ledger's
library doesn't export `flutter/widgets.dart`. It re-exports ui_core, so `RawWidgetsLocalizations` and the `Raw*`
parts come with it.

A whole app: Ledger over a `MaterialApp`, one page and one button.

```dart
import 'package:ledger_ui/ledger_ui.dart';
import 'package:material_ui/material_ui.dart';

void main() => runApp(
  MaterialApp(
    builder: (context, child) => LedgerHost(child: child!),
    home: LedgerScreen(
      topBar: const LedgerTopBar(title: 'Shelf'),
      body: LedgerButton.filled('Add a book', onPressed: () {}),
    ),
  ),
);
```

## Mount Ledger

`LedgerHost` is the one mount. Put it in your app's `builder:`, above the Navigator, so every page, dialog and menu
stands inside it. It gives the theme for the brightness in force (by day, by night, or as the device is; `theme` and
`darkTheme`, or a `palette`'s), the paper behind the app and the body type, Ledger's page motion for every route a
`MaterialApp` pushes, and the toaster `LedgerToast.show` needs. A change of appearance or palette fades across the
paper and the ink. Load Ledger's faces before the first frame:

```dart
import 'package:ledger_ui/ledger_ui.dart';
import 'package:material_ui/material_ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ledgerLoadFonts(); // the first frame is set in Ledger's faces
  runApp(const App(appearance: null));
}

class App extends StatelessWidget {
  const App({super.key, required this.appearance});

  /// Light or dark, pinned by the reader; null follows the device.
  final Brightness? appearance;

  @override
  Widget build(BuildContext context) => MaterialApp(
    localizationsDelegates: const [
      RawWidgetsLocalizations.delegate, // Ledger's own words, in 30 languages
      ...GlobalMaterialLocalizations.delegates, // material_ui's, Cupertino's and the widgets'
    ],
    supportedLocales: RawWidgetsLocalizations.supportedLocales,
    builder: (context, child) => LedgerHost(brightness: appearance, child: child!),
    home: const LedgerScreen(
      topBar: LedgerTopBar(title: 'Shelf'),
      body: Text('Your reading list'),
    ),
  );
}
```

That is the whole delegate list. `GlobalMaterialLocalizations` comes from material_ui, so an app on material_ui needs no
`flutter_localizations` dependency; the example lists the same delegates. Under a `CupertinoApp` (from `cupertino_ui`)
or a bare `WidgetsApp` the host and the delegates go in the same places. A bare `LedgerTheme` gives a subtree the theme
alone: no toasts, no paper, no fade.

`LedgerHost` takes a `density` beside its `palette` and `brightness`, which stands over the theme by day and by night:
`LedgerHost(density: LedgerDensity.compact, child: child!)`. A `theme` or `darkTheme` you give is used as it is, and the
one you leave out is the palette's in that brightness. The window's width changes none of them: the parts follow the
width themselves.

## Build an app

The example app, [example/lib/main.dart](example/lib/main.dart), is a whole reading list to copy: these are its parts.

### The shell and its places

`LedgerAppShell.branches` holds the app's places: a tab bar along a phone's foot, a rail from 600 wide and the side bar
from 1024. Each place keeps its own pages; a page pushed on one stands beside the rail or the side bar (a phone's bar
steps away for it), back pops it, and choosing the place again goes back to its first page. Arrow keys move between the
places and F6 moves the focus between them and the page.

```dart
import 'package:ledger_ui/ledger_ui.dart';
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
  Widget build(BuildContext context) => LedgerAppShell.branches(
    brand: 'Shelf',
    destinations: const [
      LedgerNavItem(LucideIcons.libraryBig, 'Books'),
      LedgerNavItem(LucideIcons.plus, 'Add'),
      LedgerNavItem(LucideIcons.settings, 'Settings'),
    ],
    selectedIndex: _place,
    onDestinationSelected: (place) => setState(() => _place = place),
    branches: [
      (context) => const LedgerScreen(topBar: LedgerTopBar(title: 'Books'), body: Text('Your reading list')),
      (context) => const LedgerScreen(topBar: LedgerTopBar(title: 'Add a book'), body: Text('Title')),
      (context) => const LedgerScreen(topBar: LedgerTopBar(title: 'Settings'), body: Text('Appearance')),
    ],
  );
}
```

### A list and its pages

A section of rows under a head, each pushing its own page. A pushed page's `LedgerTopBar.backLabel` names the way back
(a chevron on a phone, a crumb over the title beside the rail and the side bar). A record's page stands on
`LedgerScreen.form`'s column, as a form does, so a desktop never sets a name and its value a window apart.

```dart
import 'package:ledger_ui/ledger_ui.dart';
import 'package:material_ui/material_ui.dart';

class BooksPage extends StatelessWidget {
  const BooksPage({super.key, required this.titles});

  final List<String> titles;

  @override
  Widget build(BuildContext context) => LedgerScreen(
    topBar: const LedgerTopBar(title: 'Books'),
    body: LedgerSection(
      head: LedgerHead(LedgerFormat.plural(titles.length, 'book')),
      child: LedgerRows(
        children: [
          for (final title in titles)
            LedgerRow(
              title: title,
              subtitle: 'Reading',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => LedgerScreen.form(
                    topBar: LedgerTopBar(title: title, backLabel: 'Books'),
                    body: LedgerRows(children: [LedgerKeyValue('Title', title)]),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
```

### Forms

Put a form on a `LedgerScreen.form`: its column spans the page up to `LedgerLayout.formMeasure` (640), and every field
in it (a text field, a select, a sum, a date) takes the column's width. Stand the fields in a `Column` with
`LedgerSpacing.s24` between them. Check the answers when the reader saves: give each problem to its field's
`errorText`, in words, and move the focus to the first one. A `LedgerDatePicker` with a null `value` is an optional
date: its line asks for one until it is chosen.

```dart
import 'package:ledger_ui/ledger_ui.dart';
import 'package:material_ui/material_ui.dart';

class AddBookPage extends StatefulWidget {
  const AddBookPage({super.key, required this.onSaved});

  final void Function(String title, String format, DateTime? started) onSaved;

  @override
  State<AddBookPage> createState() => _AddBookPageState();
}

class _AddBookPageState extends State<AddBookPage> {
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
  }

  @override
  Widget build(BuildContext context) => LedgerScreen.form(
    topBar: const LedgerTopBar(title: 'Add a book'),
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: LedgerSpacing.s24,
      children: [
        LedgerTextField(
          labelText: 'Title',
          controller: _title,
          focusNode: _titleFocus,
          errorText: _titleError,
          isRequired: true,
        ),
        LedgerSelect<String>(
          labelText: 'Format',
          value: _format,
          items: const [
            LedgerSelectItem(value: 'paperback', label: 'Paperback'),
            LedgerSelectItem(value: 'ebook', label: 'Ebook'),
          ],
          onChanged: (format) => setState(() => _format = format),
        ),
        LedgerDatePicker(
          labelText: 'Date started',
          value: _started,
          onChanged: (day) => setState(() => _started = day),
        ),
        LedgerButton.filled('Save book', expand: true, onPressed: _save),
      ],
    ),
  );
}
```

A field that only shows a value, or wraps a control that has no label of its own (a toggle group, a slider), is a
`LedgerField`: its `labelText` over the control, read with it.

To clear the form after a save and stay on the page for the next book, empty the controller and set the other answers
back at the end of `_save`: `_title.clear(); setState(() { _format = 'paperback'; _started = null; });`.

A form can also check itself. Put each field in a `RawFormField` under a `RawForm`; on a submit that fails, the form
shows every error, moves the focus to the first and checks each field again as the reader puts it right (Material's
`autovalidateMode: AutovalidateMode.onUserInteraction`; give a `RawFormField` that `autovalidateMode` to check it from
the first keystroke). A `LedgerTextField` is not a form field itself: a Material `Form` passes it by. In a
`RawFormField`, `reset()` takes the error away and leaves the controller's text as it is. To empty the form, call
`reset()` and then clear the controllers:

```dart
import 'package:ledger_ui/ledger_ui.dart';
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
  Widget build(BuildContext context) => RawForm(
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
      spacing: LedgerSpacing.s24,
      children: [
        RawFormField<String>(
          focusNode: _titleFocus,
          validator: (_) => _title.text.trim().isEmpty ? 'Enter the book’s title' : null,
          builder: (field) => LedgerTextField(
            labelText: 'Title',
            controller: _title,
            focusNode: _titleFocus,
            errorText: field.errorText,
            onChanged: field.didChange,
          ),
        ),
        Builder(
          builder: (context) => LedgerButton.filled(
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

`LedgerDialog.show` returns the reader's answer: `true` for the confirm, `false` for Cancel, `null` when it is
dismissed (Escape, the scrim, system back). A destructive one first focuses Cancel. `LedgerToast.show` says what
happened.

```dart
import 'package:ledger_ui/ledger_ui.dart';
import 'package:material_ui/material_ui.dart';

Future<bool> confirmDelete(BuildContext context, String title) async {
  final delete = await LedgerDialog.show(
    context,
    title: 'Delete “$title”?',
    body: 'It comes off your list. You cannot undo this.',
    type: LedgerDialogType.destructive,
    confirmLabel: 'Delete book',
    cancelLabel: 'Keep it',
  );
  if (delete != true || !context.mounted) return false;
  LedgerToast.show(context, 'Deleted “$title”');
  return true;
}
```

### Let the reader choose a palette

`LedgerThemeData.palettes` are Ledger's six, each with an id to store, a label to show and the swatches it gives by
day and by night (its seal and its paper). Show each by its colour as it shows now (`swatchesFor` the theme's
brightness) beside its name, as a radio's `leading`, and hand the chosen one to the host.

```dart
import 'package:ledger_ui/ledger_ui.dart';
import 'package:material_ui/material_ui.dart';

class PalettePicker extends StatelessWidget {
  const PalettePicker({super.key, required this.palette, required this.onChanged});

  final RawNamedPalette palette;
  final ValueChanged<RawNamedPalette> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    return LedgerSection(
      head: const LedgerHead('Colour'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final p in LedgerThemeData.palettes)
            LedgerRadio<String>(
              value: p.id,
              groupValue: palette.id,
              label: p.label,
              // Its seal as it shows now, beside its name.
              leading: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: p.swatchesFor(t.brightness).first,
                  shape: BoxShape.circle,
                  border: Border.all(color: t.border),
                ),
              ),
              onChanged: (id) => onChanged(LedgerThemeData.palettes.firstWhere((p) => p.id == id)),
            ),
        ],
      ),
    );
  }
}

// Over the app: LedgerHost(palette: palette, brightness: appearance, child: child!)
```

## Building blocks

| For | Use |
| --- | --- |
| The app and its pages | `LedgerHost`, `LedgerAppShell`, `LedgerScreen` (`.form` for a form's column), `LedgerTopBar`, `LedgerNavBar`, `LedgerSideBar`, `LedgerShellAction`, `LedgerPageTransitions` |
| Sections and rows | `LedgerSection` and `LedgerHead`, `LedgerRows` and `LedgerRow`, `LedgerKeyValue`, `LedgerSettingRow`, `LedgerToggleRow`, `LedgerSwipeActions`, `LedgerReorderableList`, `LedgerDisclosure`, `LedgerDivider`, `LedgerFactColumns` |
| Actions | `LedgerButton` (`.filled`, `.ink`, `.text`), `LedgerButtonRow`, `LedgerIconButton`, `LedgerSplitButton`, `LedgerActionBar`, `LedgerQuickActions`, `LedgerMenu` |
| Form fields | `LedgerTextField`, `LedgerTextArea`, `LedgerPasswordField`, `LedgerSearchField`, `LedgerCodeField`, `LedgerInputGroup`, `LedgerField`, `LedgerSelect`, `LedgerCombobox`, `LedgerMultiSelect`, `LedgerStepper`, `LedgerFileUpload` |
| Choices | `LedgerRadio`, `LedgerCheckbox`, `LedgerSwitch`, `LedgerSegmentedControl`, `LedgerToggleGroup`, `LedgerChipRow`, `LedgerFilters`, `LedgerSlider`, `LedgerRangeSlider`, `LedgerIconPicker` |
| Dates | `LedgerDatePicker`, `LedgerDateRangePicker`, `LedgerWeekStrip`, `LedgerFormat` (dates, money, counts) |
| Money and figures | `LedgerAmount`, `LedgerFigure`, `LedgerDelta`, `LedgerGauge`, `LedgerProgressBar`, `LedgerProgressRing`, `LedgerTransactionRow`, `LedgerRegister`, `LedgerDataTable`, `LedgerReceipt` |
| Charts | `LedgerPieChart`, `LedgerSparkline`, `LedgerMonthBars`, `LedgerDayBars`, `LedgerCumulativeChart`, `LedgerNetWorthChart`, `LedgerGoalChart`, `LedgerChartKey` |
| Marks | `LedgerTag`, `LedgerPill`, `LedgerBadge`, `LedgerAvatar`, `LedgerMonogram`, `LedgerGlyph`, `LedgerSeal`, `LedgerSkeleton` |
| Messages | `LedgerToast`, `LedgerBanner`, `LedgerEmptyState`, `LedgerTooltip` |
| Over the page | `LedgerDialog`, `LedgerSheet`, `LedgerSideSheet`, `LedgerActionSheet`, `LedgerPopover`, `showLedgerCommandPalette` |
| Layout | `LedgerTabs`, `LedgerCarousel`, `LedgerTimeline`, `LedgerPagination`, `LedgerPageDots`, `LedgerScrollArea`, `LedgerPullToRefresh`, `LedgerLayout`, `LedgerSpacing`, `LedgerGap` |

## Make it yours

`LedgerTheme.of(context)` (or `context.ledgerTheme`) returns the `LedgerThemeData` in scope: its colours, its type
(the serif for heads and figures, the sans for words, the mono for amounts), its density and its corner steps. Restyle a part
of the tree with a nested `LedgerTheme`; `AnimatedLedgerTheme` animates between two.

```dart
// A preset by its id: quire (the default), terracotta, indigo, verdigris, carbon or prussian.
LedgerThemeData.preset('verdigris', Brightness.dark);

// Your own paper, ink and accent; the rest is derived from them, words held to 4.5:1 on every ground. Asked for
// the night, a day book turns: a dark paper in its paper's hue, its cream for the ink, the accent lifted to read.
LedgerThemeData.from(
  paper: const Color(0xFFF4EFE6),
  ink: const Color(0xFF1F2A2E),
  accent: const Color(0xFF2F6B4F),
  brightness: Brightness.dark,
);

// Density: standard is the touch size (a 48 button, a 52 row), comfortable 4 off each, compact 8; the default is
// compact under a pointer and standard on touch. A tap target stays on the 40 floor at every density.
LedgerThemeData.light().copyWith(density: LedgerDensity.compact);
```

`LedgerThemeData.from` derives a coordinated palette from your accent, by day and by night; `nightPaper`, `nightInk`
and `nightAccent` set the night's own. Use `copyWith` for single overrides. The money colours are `moneyIn` for
income, `over` for spending past a limit and `move` for transfers.

Most controls take `value` and `onChanged`; a null callback disables the control. `LedgerThemeData.components` holds
app-wide component defaults, and a widget's own `style:` (a `LedgerStyle`) wins over them. Buttons, fields, chips,
switches, banners and dialogs take styles; selects, sliders, navigation and sheets follow the theme.

```dart
// The accent on one button while it is enabled.
final green = context.ledgerTheme.accentText;
final inGreen = WidgetStateProperty.resolveWith(
  (states) => states.contains(WidgetState.disabled) ? null : green,
);
LedgerButton('Export', onPressed: () {}, style: LedgerStyle(edge: inGreen, foreground: inGreen));
```

Labels and glyphs are a `String` and an `IconData` where Flutter would take a `Widget`, as in
`LedgerButton.filled('Save', icon: LucideIcons.check)`. A control without words of its own takes a `semanticLabel`.

Your corners. Ledger's steps are 3, 6, 6, 6 and 12, and what the hand holds (a button, a chip, a field, a search) is
round at any height. Each step moves within a band where Ledger still reads as paper (`LedgerThemeData.shapeLimits`); a
value past its band is held to the band's end, with a note in debug builds. Its rules are ink and its paper lies flat,
so Ledger opens no stroke and no depth.

| Step | Ledger's | Band | On |
| --- | --- | --- | --- |
| extraSmall | 3 | 2–5 | a bar's ends |
| small | 6 | 2–10 | a date tab, a tooltip, a popover, a key cap |
| medium | 6 | 2–12 | a slip, a card, a menu, a toast, a banner |
| large | 6 | 4–16 | a sheet, a dialog |
| extraLarge | 12 | 8–16 | a part's own corners |
| full | round | any cap | a button, a chip, a field, a search |

```dart
LedgerThemeData.light(
  shapeScheme: const RawShapeScheme(
    corners: RawCornerScale(
      extraSmall: 3,
      small: 8,
      medium: 10,
      large: 12,
      extraLarge: 16,
      fullMaxRadius: 12, // buttons and fields with soft corners, not round ends
    ),
  ),
)
```

One part's own corners, a step at each, start and end as the text reads; here a tab's, the top round and the foot
square. A full corner beside corners of other steps is 20, or the scale's `fullMaxRadius`:

```dart
LedgerButton(
  'Print the receipt',
  onPressed: () {},
  style: const LedgerStyle(
    corners: WidgetStatePropertyAll(
      RawCorners(bottomStart: RawCorner.none, bottomEnd: RawCorner.none),
    ),
  ),
)
```

A style's `shape` still wins over `corners`, drawn as given.

## Change one component

Copy a component's file from `lib/src/ledger/` into your app, rename its class, and replace its `src/` imports with
one import of `package:ledger_ui/ledger_parts.dart`, which exports everything the components are drawn with (the
pressable, the rules, the leader, the engraving and the other helpers). The rest of your app stays on the package.

## Accessibility and localization

- Use Tab to move between controls, Enter or Space to activate them, and Escape to close overlays. A set of radios, a segmented control or a one-choice toggle group is one Tab stop, on the chosen option, and the arrow keys move and choose. Selects support arrow keys, Home, End and type-ahead. Sliders respond to arrow keys. Keyboard focus is shown with a double underline.
- Control hit targets stay at least 40 logical pixels (ui_core's tap floor) across densities. Labels and form rows wrap at large text sizes. Calendar days and weekday names scale within the seven-column grid. Chart legends and rulers scale separately from labels inside the plot.
- The layout follows `Directionality`. Money, masked account numbers and step counts preserve their numeric order in right-to-left layouts. Charts retain their left-to-right time axis.
- List the delegates as [Mount Ledger](#mount-ledger) does (`RawWidgetsLocalizations.delegate` and `GlobalMaterialLocalizations.delegates`, with `RawWidgetsLocalizations.supportedLocales`) to localize shared control labels; on material_ui no `flutter_localizations` is needed. Supply translated application labels, chart names and prompts yourself. The bundled fonts cover Latin scripts. Other scripts use platform fallback fonts.
- `LedgerFormat` prints dates and times in English and currency amounts in US dollars. Use `RawWidgetsLocalizations.of(context).formatTimeOfDay` for a clock time in the reader's language and hours, and `LedgerStepper.format` to display a different unit in a stepper.

## Example app

[example/lib/main.dart](example/lib/main.dart) is Shelf, the reading list above, whole: the shell, the list and its
pages, the form, the dialog and the settings with the six palettes. Ledger's gallery, Quill (a household ledger with
every part on a page of its own), is `flutter run -t lib/gallery.dart` in `example/`.

## Requirements

Flutter 3.47.0 or later (Dart 3.13), on Android, iOS, web, macOS, Windows and Linux. The package depends on ui_core
^0.8.0 and re-exports it.

## Licences

The package is BSD-3-Clause. It bundles Instrument Serif, Inter Tight and IBM Plex Mono under the SIL Open Font
License 1.1, and depends on `lucide_icons_flutter` (Lucide, ISC; Feather, MIT). The notices are in `LICENSE` and
`THIRD_PARTY_NOTICES/`.

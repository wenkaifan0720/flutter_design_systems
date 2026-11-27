// Shelf: a small reading list on Gloss, the whole app in one file. The host
// over the navigator (light, dark or the platform's, the palette, and the
// toasts), the app shell with three places and its one act, a list with a
// pushed detail, a form with validation and a date, a dialog popped with its
// answer, and settings with the six palettes. Copy it, rename it, and grow
// it.

import 'package:material_ui/material_ui.dart';
import 'package:gloss_ui/gloss_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await glossLoadFonts(); // the bundled face, before the first frame
  runApp(ShelfApp());
}

// The data

enum Status {
  wanted('Want to read', GlossTagTone.neutral),
  reading('Reading', GlossTagTone.accent),
  finished('Finished', GlossTagTone.neutral);

  const Status(this.label, this.tone);

  final String label;
  final GlossTagTone tone;
}

class Book {
  Book({
    required this.title,
    required this.author,
    this.status = Status.wanted,
    this.started,
    this.favourite = false,
  });

  String title;
  String author;
  Status status;
  DateTime? started;
  bool favourite;
}

/// The books, and the app's appearance: what every page reads and changes.
class Library extends ChangeNotifier {
  final List<Book> books = [
    Book(
      title: 'Stoner',
      author: 'John Williams',
      status: Status.finished,
      started: DateTime(2026, 9, 2),
      favourite: true,
    ),
    Book(
      title: 'The Remains of the Day',
      author: 'Kazuo Ishiguro',
      status: Status.reading,
      started: DateTime(2026, 11, 18),
    ),
    Book(title: 'Middlemarch', author: 'George Eliot'),
    Book(
      title: 'Pachinko',
      author: 'Min Jin Lee',
      status: Status.reading,
      started: DateTime(2026, 11, 3),
    ),
  ];

  /// The palette, one of [GlossThemeData.palettes].
  RawNamedPalette palette = GlossThemeData.palettes.first;

  /// Light or dark; null follows the platform.
  Brightness? brightness;

  void save(Book book) {
    if (!books.contains(book)) books.add(book);
    notifyListeners();
  }

  void delete(Book book) {
    books.remove(book);
    notifyListeners();
  }

  void setAppearance({
    RawNamedPalette? palette,
    Brightness? brightness,
    bool system = false,
  }) {
    this.palette = palette ?? this.palette;
    this.brightness = system ? null : brightness ?? this.brightness;
    notifyListeners();
  }
}

// The app

class ShelfApp extends StatelessWidget {
  ShelfApp({super.key});

  final Library library = Library();

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: library,
    builder: (context, _) => MaterialApp(
      title: 'Shelf',
      debugShowCheckedModeBanner: false,
      // A push moves as Gloss's pages do.
      theme: ThemeData(
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: glossPageTransitions,
        ),
      ),
      // The one mount: the palette by day and by night (easing between
      // them) and the toasts.
      builder: (context, child) => GlossHost(
        palette: library.palette,
        brightness: library.brightness,
        child: child!,
      ),
      home: Shell(library: library),
    ),
  );
}

class Shell extends StatefulWidget {
  const Shell({super.key, required this.library});

  final Library library;

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _place = 0;

  // Each place's navigator, so the act can open the form in Books.
  final _navigators = [for (var i = 0; i < 3; i++) GlobalKey<NavigatorState>()];

  void _add() {
    setState(() => _place = 0);
    _navigators.first.currentState?.push(
      MaterialPageRoute<void>(
        builder: (context) => BookForm(library: widget.library),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => GlossAppShell(
    header: const GlossBrand('Shelf'),
    // The app's one act: a gel key in the bar, under the name on the rail,
    // a worded key in the sidebar.
    action: GlossActKey(
      icon: LucideIcons.plus,
      label: 'Add a book',
      onPressed: _add,
    ),
    destinations: const [
      RawNavigationDestination(label: 'Books', icon: LucideIcons.libraryBig),
      RawNavigationDestination(label: 'Reading', icon: LucideIcons.bookOpen),
      RawNavigationDestination(label: 'Settings', icon: LucideIcons.settings),
    ],
    selectedIndex: _place,
    onDestinationSelected: (index) => setState(() => _place = index),
    navigatorKeys: _navigators,
    // Each place keeps its own pages: a book opened in Books stays open
    // while you look at Settings.
    branches: [
      (context) => BooksPage(library: widget.library),
      (context) => BooksPage(library: widget.library, only: Status.reading),
      (context) => SettingsPage(library: widget.library),
    ],
  );
}

// A list, and its pushed detail

class BooksPage extends StatelessWidget {
  const BooksPage({super.key, required this.library, this.only});

  final Library library;
  final Status? only;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: library,
    builder: (context, _) {
      final books = [
        for (final book in library.books)
          if (only == null || book.status == only) book,
      ];
      final theme = GlossTheme.of(context);
      return GlossScreen(
        topBar: GlossTopBar(title: only?.label ?? 'Books', large: true),
        body: books.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: GlossSpacing.huge,
                ),
                child: Text(
                  'Nothing here yet. Books you add show up here.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.secondary,
                ),
              )
            : GlossWell(
                header: glossPlural(
                  context,
                  books.length,
                  one: '1 book',
                  other: '${books.length} books',
                ),
                children: [
                  for (final book in books)
                    GlossListTile(
                      leading: GlossAvatar(name: book.title, size: 24),
                      title: book.title,
                      subtitle: book.author,
                      trailing: GlossTag(
                        book.status.label,
                        tone: book.status.tone,
                      ),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) =>
                              BookPage(library: library, book: book),
                        ),
                      ),
                    ),
                ],
              ),
      );
    },
  );
}

class BookPage extends StatelessWidget {
  const BookPage({super.key, required this.library, required this.book});

  final Library library;
  final Book book;

  Future<void> _delete(BuildContext context) async {
    // The dialog pops with the answer: true to delete, false or null to keep.
    final sure = await showGlossDialog<bool>(
      context: context,
      builder: (context) => GlossDialog(
        title: 'Delete "${book.title}"?',
        content: const Text('It leaves your shelf. This cannot be undone.'),
        actions: [
          GlossDialogAction(
            label: 'Keep',
            onPressed: () => Navigator.of(context).pop(false),
          ),
          GlossDialogAction(
            label: 'Delete',
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    if (sure != true || !context.mounted) return;
    library.delete(book);
    Navigator.of(context).pop();
    showGlossToast(context, 'Deleted "${book.title}"');
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: library,
    builder: (context, _) {
      final started = book.started;
      return GlossScreen(
        topBar: GlossTopBar(
          title: book.title,
          leading: GlossTopBar.autoLeading(context),
          actions: [
            GlossIconButton(
              icon: const Icon(LucideIcons.pencil),
              tooltip: 'Edit',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => BookForm(library: library, book: book),
                ),
              ),
            ),
          ],
        ),
        body: GlossWell(
          children: [
            GlossListTile(title: 'Author', trailingText: book.author),
            GlossListTile(
              title: 'Status',
              trailing: GlossTag(book.status.label, tone: book.status.tone),
            ),
            GlossListTile(
              title: 'Started',
              trailingText: started == null
                  ? 'Not yet'
                  : GlossFormat.mediumDate(context, started),
            ),
            GlossListTile(
              title: 'Favourite',
              trailingText: book.favourite ? 'Yes' : 'No',
            ),
          ],
        ),
        footer: GlossButton(
          'Delete',
          isDestructiveAction: true,
          onPressed: () => _delete(context),
        ),
      );
    },
  );
}

// A form

class BookForm extends StatefulWidget {
  const BookForm({super.key, required this.library, this.book});

  final Library library;

  /// The book to edit; null adds one.
  final Book? book;

  @override
  State<BookForm> createState() => _BookFormState();
}

class _BookFormState extends State<BookForm> {
  final _form = GlobalKey<FormState>();
  late final Book _draft = Book(
    title: widget.book?.title ?? '',
    author: widget.book?.author ?? '',
    status: widget.book?.status ?? Status.wanted,
    started: widget.book?.started,
    favourite: widget.book?.favourite ?? false,
  );

  void _save() {
    // validate() shows each field's error under it; save() runs onSaved.
    final form = _form.currentState!;
    if (!form.validate()) return;
    form.save();
    final book = widget.book ?? Book(title: '', author: '');
    book
      ..title = _draft.title
      ..author = _draft.author
      ..status = _draft.status
      ..started = _draft.started
      ..favourite = _draft.favourite;
    widget.library.save(book);
    Navigator.of(context).pop();
    showGlossToast(context, 'Saved "${book.title}"');
  }

  @override
  Widget build(BuildContext context) => GlossScreen(
    topBar: GlossTopBar(
      title: widget.book == null ? 'New book' : 'Edit',
      leading: GlossTopBar.autoLeading(context),
    ),
    body: Form(
      key: _form,
      // Every field at the column's width, 16 apart.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: GlossSpacing.regular,
        children: [
          GlossTextFormField(
            labelText: 'Title',
            initialValue: _draft.title,
            textInputAction: TextInputAction.next,
            validator: (value) =>
                (value ?? '').trim().isEmpty ? 'Enter the title' : null,
            onSaved: (value) => _draft.title = value!.trim(),
          ),
          GlossTextFormField(
            labelText: 'Author',
            initialValue: _draft.author,
            onSaved: (value) => _draft.author = value!.trim(),
          ),
          GlossSelect<Status>(
            labelText: 'Status',
            value: _draft.status,
            items: [
              for (final status in Status.values)
                GlossSelectItem(value: status, label: status.label),
            ],
            onChanged: (value) => setState(() => _draft.status = value),
          ),
          GlossDatePicker(
            labelText: 'Started',
            hintText: 'Not yet',
            value: _draft.started,
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
            onChanged: (value) => setState(() => _draft.started = value),
          ),
          GlossWell(
            children: [
              // The row names its switch: one control, as SwitchListTile is.
              GlossListTile(
                title: 'Favourite',
                trailing: GlossSwitch(
                  value: _draft.favourite,
                  onChanged: (value) =>
                      setState(() => _draft.favourite = value),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
    footer: GlossButton.filled('Save', onPressed: _save),
  );
}

// Settings

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.library});

  final Library library;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: library,
    builder: (context, _) => GlossScreen(
      topBar: const GlossTopBar(title: 'Settings', large: true),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: GlossSpacing.large,
        children: [
          GlossFormField(
            labelText: 'Appearance',
            child: GlossSegmentedButton<String>(
              // On a phone the segments share the column; wider, each takes
              // its words' width.
              expanded:
                  MediaQuery.sizeOf(context).width <
                  GlossMetrics.railBreakpoint,
              segments: const [
                GlossSegment(value: 'system', label: 'System'),
                GlossSegment(value: 'light', label: 'Light'),
                GlossSegment(value: 'dark', label: 'Dark'),
              ],
              selected: library.brightness?.name ?? 'system',
              onChanged: (value) => value == 'system'
                  ? library.setAppearance(system: true)
                  : library.setAppearance(
                      brightness: Brightness.values.byName(value),
                    ),
            ),
          ),
          GlossFormField(
            labelText: 'Palette',
            child: GlossRadioGroup<RawNamedPalette>(
              options: GlossThemeData.palettes,
              groupValue: library.palette,
              labelOf: (palette) => palette.label,
              // Each palette by its name and its colours, as they show by day
              // or by night.
              trailingOf: (palette) => Swatches(
                palette.swatchesFor(GlossTheme.of(context).colors.brightness),
              ),
              onChanged: (palette) => library.setAppearance(palette: palette),
            ),
          ),
        ],
      ),
    ),
  );
}

/// A palette's colour as a picker shows it: its first swatch (the gel, the
/// most telling) as a disc, in a hairline so a pale colour reads on a pale
/// page and a dark one on a dark page.
class Swatches extends StatelessWidget {
  const Swatches(this.colors, {super.key});

  final List<Color> colors;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 20,
    child: DecoratedBox(
      decoration: ShapeDecoration(
        color: colors.first,
        shape: CircleBorder(
          side: BorderSide(color: GlossTheme.of(context).colors.inkSecondary),
        ),
      ),
    ),
  );
}

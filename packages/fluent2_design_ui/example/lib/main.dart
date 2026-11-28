// Shelf: a small reading list on Fluent 2, the whole app in one file. The
// host over the navigator (light, dark or the platform's, and the toasts),
// the shell with three places, a list with a pushed detail, a form with
// validation and a date, a dialog popped with its answer, and settings with
// the six palettes. Copy it, rename it, and grow it.
import 'package:material_ui/material_ui.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await fluent2LoadFonts(); // the bundled faces, before the first frame
  runApp(ShelfApp());
}

// ── The data ────────────────────────────────────────────────────────────────

enum Status {
  wanted('Want to read', Fluent2BadgeColor.informative),
  reading('Reading', Fluent2BadgeColor.brand),
  finished('Finished', Fluent2BadgeColor.success);

  const Status(this.label, this.color);

  final String label;
  final Fluent2BadgeColor color;
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

  /// The palette, one of [Fluent2ThemeData.palettes]; an app would store its
  /// id and find it again in the list.
  RawNamedPalette palette = Fluent2ThemeData.palettes.first;

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

// ── The app ─────────────────────────────────────────────────────────────────

class ShelfApp extends StatelessWidget {
  ShelfApp({super.key});

  final Library library = Library();

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: library,
    builder: (context, _) => MaterialApp(
      title: 'Shelf',
      debugShowCheckedModeBanner: false,
      // Every part's words: the shared labels in 30 languages, Fluent's
      // own, and Material's, Cupertino's and the widgets' (material_ui
      // carries these, so no flutter_localizations dependency).
      localizationsDelegates: const [
        RawWidgetsLocalizations.delegate,
        Fluent2Localizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: RawWidgetsLocalizations.supportedLocales,
      // Fluent's push and pop for the pages the app pushes.
      theme: ThemeData(
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: fluent2PageTransitions,
        ),
      ),
      // The one mount: the theme by day and by night (animating between
      // them and between palettes), and the toasts.
      builder: (context, child) => Fluent2Host(
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

  @override
  Widget build(BuildContext context) => Fluent2AppShell.branches(
    header: Text('Shelf', style: context.fluent2Theme.subtitle2),
    destinations: const [
      Fluent2NavItem(Fluent2Icons.book, 'Books'),
      Fluent2NavItem(Fluent2Icons.bookmark, 'Reading'),
      Fluent2NavItem(Fluent2Icons.settings, 'Settings'),
    ],
    selectedIndex: _place,
    onDestinationSelected: (index) => setState(() => _place = index),
    // Each place keeps its own pages: a book opened in Books stays open
    // while you look at Settings.
    branches: [
      (context) => BooksPage(library: widget.library),
      (context) => BooksPage(library: widget.library, only: Status.reading),
      (context) => SettingsPage(library: widget.library),
    ],
  );
}

// ── A list, and its pushed detail ───────────────────────────────────────────

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
      final title = only?.label ?? 'Books';
      return Fluent2Scaffold(
        topBar: Fluent2AppBar(
          title: title,
          caption: Fluent2Format.plural(books.length, 'book'),
          actions: [
            Fluent2IconButton(
              Fluent2Icons.add,
              semanticLabel: 'Add a book',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) =>
                      BookForm(library: library, parent: title),
                ),
              ),
            ),
          ],
        ),
        body: books.isEmpty
            ? const Fluent2EmptyState(
                icon: Fluent2Icons.book,
                title: 'Nothing here yet',
                body: 'Books you add show up here.',
              )
            : Fluent2ListGroup(
                children: [
                  for (final book in books)
                    Fluent2ListItem(
                      title: book.title,
                      subtitle: book.author,
                      trailing: Fluent2LabelBadge(
                        label: book.status.label,
                        appearance: Fluent2BadgeAppearance.tint,
                        color: book.status.color,
                      ),
                      chevron: true,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) => BookPage(
                            library: library,
                            book: book,
                            parent: title,
                          ),
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
  const BookPage({
    super.key,
    required this.library,
    required this.book,
    required this.parent,
  });

  final Library library;
  final Book book;
  final String parent;

  Future<void> _delete(BuildContext context) async {
    // The dialog pops with the answer: true to delete, false or null to keep.
    final sure = await showFluent2Dialog<bool>(
      context,
      builder: (context) => Fluent2Dialog(
        title: 'Delete "${book.title}"?',
        message: 'It leaves your shelf. This cannot be undone.',
        actions: [
          Fluent2Button(
            'Keep',
            onPressed: () => Navigator.of(context).pop(false),
          ),
          Fluent2Button(
            'Delete',
            appearance: Fluent2ButtonAppearance.primary,
            danger: true,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    if (sure != true || !context.mounted) return;
    library.delete(book);
    Navigator.of(context).pop();
    showFluent2Toast(context, 'Deleted "${book.title}"');
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: library,
    builder: (context, _) {
      final started = book.started;
      return Fluent2Scaffold(
        topBar: Fluent2AppBar(
          title: book.title,
          backLabel: parent,
          actions: [
            Fluent2IconButton(
              Fluent2Icons.edit,
              semanticLabel: 'Edit',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => BookForm(
                    library: library,
                    book: book,
                    parent: book.title,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Fluent2DescriptionList(
          properties: [
            Fluent2DescriptionItem(
              'Author',
              book.author,
              icon: Fluent2Icons.person,
            ),
            Fluent2DescriptionItem(
              'Status',
              book.status.label,
              icon: Fluent2Icons.flag,
              child: Fluent2LabelBadge(
                label: book.status.label,
                appearance: Fluent2BadgeAppearance.tint,
                color: book.status.color,
              ),
            ),
            Fluent2DescriptionItem(
              'Started',
              started == null
                  ? 'Not yet'
                  : Fluent2Format.date(started, year: true),
              icon: Fluent2Icons.calendarLtr,
            ),
            Fluent2DescriptionItem(
              'Favourite',
              book.favourite ? 'Yes' : 'No',
              icon: Fluent2Icons.heart,
            ),
          ],
        ),
        footer: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Fluent2Button(
              'Delete',
              danger: true,
              onPressed: () => _delete(context),
            ),
          ],
        ),
      );
    },
  );
}

// ── A form ──────────────────────────────────────────────────────────────────

class BookForm extends StatefulWidget {
  const BookForm({
    super.key,
    required this.library,
    this.book,
    required this.parent,
  });

  final Library library;

  /// The book to edit; null adds one.
  final Book? book;
  final String parent;

  @override
  State<BookForm> createState() => _BookFormState();
}

class _BookFormState extends State<BookForm> {
  late final Book _draft = Book(
    title: widget.book?.title ?? '',
    author: widget.book?.author ?? '',
    status: widget.book?.status ?? Status.wanted,
    started: widget.book?.started,
    favourite: widget.book?.favourite ?? false,
  );

  void _save() {
    final book = widget.book ?? Book(title: '', author: '');
    book
      ..title = _draft.title
      ..author = _draft.author
      ..status = _draft.status
      ..started = _draft.started
      ..favourite = _draft.favourite;
    widget.library.save(book);
    Navigator.of(context).pop();
    showFluent2Toast(context, 'Saved "${book.title}"');
  }

  @override
  Widget build(BuildContext context) => Fluent2Form(
    // Called once every field is fine, after each field's onSaved.
    onSubmit: _save,
    child: Fluent2Scaffold(
      topBar: Fluent2AppBar(
        title: widget.book == null ? 'New book' : 'Edit',
        backLabel: widget.parent,
      ),
      // The form's column: every field at its width, 16 apart, on a 560
      // measure.
      body: Fluent2FormSection(
        children: [
          Fluent2TextFormField(
            labelText: 'Title',
            required: true,
            initialValue: _draft.title,
            validator: (value) =>
                (value ?? '').trim().isEmpty ? 'Enter the title' : null,
            onSaved: (value) => _draft.title = value!.trim(),
          ),
          Fluent2TextFormField(
            labelText: 'Author',
            initialValue: _draft.author,
            onSaved: (value) => _draft.author = value!.trim(),
          ),
          Fluent2FormField(
            labelText: 'Status',
            child: Fluent2Select<Status>(
              value: _draft.status,
              options: [
                for (final status in Status.values)
                  Fluent2Option(status, status.label),
              ],
              onChanged: (value) => setState(() => _draft.status = value),
            ),
          ),
          Fluent2FormField(
            labelText: 'Started',
            child: Fluent2DatePicker(
              value: _draft.started,
              hintText: 'Not yet',
              lastDate: DateTime.now(),
              onChanged: (value) => setState(() => _draft.started = value),
            ),
          ),
          Fluent2Switch(
            label: 'Favourite',
            value: _draft.favourite,
            onChanged: (value) => setState(() => _draft.favourite = value),
          ),
        ],
      ),
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Under the form: submit checks every field, shows what is wrong
          // and moves focus to the first, or saves.
          Builder(
            builder: (context) => Fluent2Button(
              'Save',
              appearance: Fluent2ButtonAppearance.primary,
              onPressed: () => Fluent2Form.submit(context),
            ),
          ),
        ],
      ),
    ),
  );
}

// ── Settings ────────────────────────────────────────────────────────────────

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.library});

  final Library library;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: library,
    builder: (context, _) => Fluent2Scaffold(
      topBar: const Fluent2AppBar(title: 'Settings'),
      body: Fluent2FormSection(
        children: [
          Fluent2RadioGroup<String>(
            label: 'Appearance',
            layout: Fluent2RadioLayout.horizontal,
            value: library.brightness?.name ?? 'system',
            onChanged: (value) => value == 'system'
                ? library.setAppearance(system: true)
                : library.setAppearance(
                    brightness: Brightness.values.byName(value),
                  ),
            options: const [
              Fluent2Radio('system', 'System'),
              Fluent2Radio('light', 'Light'),
              Fluent2Radio('dark', 'Dark'),
            ],
          ),
          Fluent2RadioGroup<RawNamedPalette>(
            label: 'Palette',
            value: library.palette,
            onChanged: (value) => library.setAppearance(palette: value),
            options: [
              for (final palette in Fluent2ThemeData.palettes)
                Fluent2Radio(
                  palette,
                  palette.label,
                  secondary: PaletteSwatches(palette),
                ),
            ],
          ),
        ],
      ),
    ),
  );
}

/// [palette]'s colours in the brightness on screen, beside its name in the
/// picker: its accent on a tile of its ground.
class PaletteSwatches extends StatelessWidget {
  /// [palette]'s swatches.
  const PaletteSwatches(this.palette, {super.key});

  /// The palette they show.
  final RawNamedPalette palette;

  @override
  Widget build(BuildContext context) {
    final theme = context.fluent2Theme;
    final swatches = palette.swatchesFor(theme.brightness);
    // The last swatch is the palette's ground: a small tile of it, ringed in
    // the hairline, with the others as dots on it, so a ground as pale as
    // the page reads as a page and not as an empty ring.
    final ground = swatches.length > 1 ? swatches.last : null;
    final dots = ground == null
        ? swatches
        : swatches.sublist(0, swatches.length - 1);
    return Container(
      margin: const EdgeInsetsDirectional.only(start: 4),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
        color: ground,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: theme.colors.neutralStroke1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 3,
        children: [
          for (final color in dots)
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
        ],
      ),
    );
  }
}

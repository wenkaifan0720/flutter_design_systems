// Shelf: a small reading list on Appliance, the whole app in one file. The
// host over the navigator (light, dark or the platform's, and the toasts),
// the frame with three places, a list with a pushed detail, a form that
// checks itself, a dialog popped with its answer, and settings with the six
// palettes. Copy it, rename it, and grow it.
import 'package:material_ui/material_ui.dart';
import 'package:appliance_ui/appliance_ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await applianceLoadFonts(); // the bundled faces, before the first frame
  runApp(ShelfApp());
}

// ── The data ────────────────────────────────────────────────────────────────

enum Status {
  wanted('Want to read', ApplianceTagTone.neutral),
  reading('Reading', ApplianceTagTone.signal),
  finished('Finished', ApplianceTagTone.ready);

  const Status(this.label, this.tone);

  final String label;
  final ApplianceTagTone tone;
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

  /// The palette, one of [ApplianceThemeData.palettes]; an app would store
  /// its id and find it again in the list.
  RawNamedPalette palette = ApplianceThemeData.palettes.first;

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
      // Appliance's push and pop for the pages the app pushes.
      theme: ThemeData(
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: appliancePageTransitions,
        ),
      ),
      // The one mount: the theme by day and by night (easing between them
      // and between palettes), and the toasts.
      builder: (context, child) => ApplianceHost(
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
  Widget build(BuildContext context) => ApplianceScaffold.branches(
    header: Text('Shelf', style: ApplianceTheme.of(context).textTheme.heading),
    destinations: const [
      ApplianceDestination(icon: LucideIcons.libraryBig, label: 'Books'),
      ApplianceDestination(icon: LucideIcons.bookOpen, label: 'Reading'),
      ApplianceDestination(icon: LucideIcons.settings, label: 'Settings'),
    ],
    selectedIndex: _place,
    onSelected: (index) => setState(() => _place = index),
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
      return ApplianceScreen(
        topBar: ApplianceAppBar(
          title: title,
          actions: [
            ApplianceIconButton(
              icon: const Icon(LucideIcons.plus),
              semanticLabel: 'Add a book',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => BookForm(library: library),
                ),
              ),
            ),
          ],
        ),
        body: books.isEmpty
            ? const ApplianceEmptyState(
                title: 'Nothing here yet',
                message: 'Books you add stand here.',
              )
            : ApplianceListGroup(
                children: [
                  for (final book in books)
                    ApplianceListTile(
                      title: book.title,
                      subtitle: book.author,
                      // A tag at the end is part of the row's name.
                      trailing: ApplianceTag(
                        book.status.label,
                        tone: book.status.tone,
                      ),
                      showChevron: true,
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
    // An alert: a screen reader hears it ask, and a stray tap on the scrim
    // answers nothing.
    final sure = await showApplianceDialog<bool>(
      context: context,
      isAlert: true,
      builder: (context) => ApplianceDialog(
        title: 'Delete "${book.title}"?',
        content: const Text('It leaves your shelf. This cannot be undone.'),
        actions: [
          ApplianceButton(
            'Keep',
            onPressed: () => Navigator.of(context).pop(false),
          ),
          ApplianceButton.filled(
            'Delete',
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    if (sure != true || !context.mounted) return;
    library.delete(book);
    Navigator.of(context).pop();
    showApplianceToast(context, 'Deleted "${book.title}"');
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: library,
    builder: (context, _) {
      final started = book.started;
      return ApplianceScreen(
        topBar: ApplianceAppBar(
          title: book.title,
          leading: ApplianceAppBar.autoLeading(context),
          actions: [
            ApplianceIconButton(
              icon: const Icon(LucideIcons.pencil),
              semanticLabel: 'Edit',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => BookForm(library: library, book: book),
                ),
              ),
            ),
          ],
        ),
        body: ApplianceDescriptionList(
          items: [
            ('Author', book.author),
            ('Status', book.status.label),
            // One date format: the date field's own.
            (
              'Started',
              started == null
                  ? 'Not yet'
                  : ApplianceFormat.date(context, started),
            ),
            ('Favourite', book.favourite ? 'Yes' : 'No'),
          ],
        ),
        footer: ApplianceButton.filled(
          'Delete',
          isDestructiveAction: true,
          onPressed: () => _delete(context),
        ),
      );
    },
  );
}

// ── A form ──────────────────────────────────────────────────────────────────

class BookForm extends StatefulWidget {
  const BookForm({super.key, required this.library, this.book});

  final Library library;

  /// The book to edit; null adds one.
  final Book? book;

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
    showApplianceToast(context, 'Saved "${book.title}"');
  }

  @override
  Widget build(BuildContext context) => ApplianceForm(
    // Called once every field is fine, after each field's onSaved.
    onSubmit: _save,
    child: ApplianceScreen(
      topBar: ApplianceAppBar(
        title: widget.book == null ? 'New book' : 'Edit',
        leading: ApplianceAppBar.autoLeading(context),
      ),
      // The form column: every field at the column's width, 16 apart.
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          ApplianceTextFormField(
            labelText: 'Title',
            initialValue: _draft.title,
            textCapitalization: TextCapitalization.words,
            validator: (value) =>
                (value ?? '').trim().isEmpty ? 'Enter the title' : null,
            onSaved: (value) => _draft.title = value!.trim(),
          ),
          ApplianceTextFormField(
            labelText: 'Author',
            initialValue: _draft.author,
            textCapitalization: TextCapitalization.words,
            onSaved: (value) => _draft.author = value!.trim(),
          ),
          ApplianceSelect<Status>(
            labelText: 'Status',
            value: _draft.status,
            items: [
              for (final status in Status.values)
                ApplianceSelectItem(value: status, label: status.label),
            ],
            onChanged: (value) => setState(() => _draft.status = value),
          ),
          ApplianceDatePicker(
            labelText: 'Started',
            value: _draft.started,
            hintText: 'Not yet',
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
            onChanged: (value) => setState(() => _draft.started = value),
          ),
          ApplianceField(
            labelText: 'Favourite',
            child: ApplianceSwitch(
              value: _draft.favourite,
              onChanged: (value) => setState(() => _draft.favourite = value),
            ),
          ),
        ],
      ),
      // Under the form: submit checks every field, shows what is wrong and
      // moves focus to the first, or saves.
      footer: Builder(
        builder: (context) => ApplianceButton.filled(
          'Save',
          onPressed: () => ApplianceForm.submit(context),
        ),
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
    builder: (context, _) => ApplianceScreen(
      topBar: const ApplianceAppBar(title: 'Settings'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 24,
        children: [
          ApplianceField(
            labelText: 'Appearance',
            child: ApplianceSegmentedButton<String>(
              segments: const [
                ApplianceSegment(value: 'system', label: 'System'),
                ApplianceSegment(value: 'light', label: 'Light'),
                ApplianceSegment(value: 'dark', label: 'Dark'),
              ],
              value: library.brightness?.name ?? 'system',
              onChanged: (value) => value == 'system'
                  ? library.setAppearance(system: true)
                  : library.setAppearance(
                      brightness: Brightness.values.byName(value),
                    ),
            ),
          ),
          ApplianceField(
            labelText: 'Palette',
            mergeSemantics: false,
            child: ApplianceRadioGroup<RawNamedPalette>(
              options: ApplianceThemeData.palettes,
              value: library.palette,
              labelOf: (palette) => palette.label,
              // Each palette's colours right beside its name.
              secondaryOf: PaletteSwatches.new,
              onChanged: (value) => library.setAppearance(palette: value),
            ),
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
    final theme = ApplianceTheme.of(context);
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
        border: Border.all(color: theme.colors.hairline),
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

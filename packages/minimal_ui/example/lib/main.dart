// Shelf: a small reading list on Minimal, the whole app in one file. The host
// over the navigator (light, dark or the platform's, and the toasts), the
// shell with three places, a list with a pushed detail, a form with
// validation and a date, a dialog popped with its answer, and settings with
// the six palettes. Copy it, rename it, and grow it.
import 'package:material_ui/material_ui.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await minimalLoadFonts(); // the bundled Geist faces, before the first frame
  runApp(ShelfApp());
}

// ── The data ────────────────────────────────────────────────────────────────

enum Status {
  wanted('Want to read', MinimalTone.neutral),
  reading('Reading', MinimalTone.primary),
  finished('Finished', MinimalTone.success);

  const Status(this.label, this.tone);

  final String label;
  final MinimalTone tone;
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

  /// The palette, one of [MinimalThemeData.palettes]; an app would store
  /// its id and find it again in the list.
  RawNamedPalette palette = MinimalThemeData.palettes.first;

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
      // Minimal's push and pop for the pages the app pushes.
      theme: ThemeData(
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: minimalPageTransitions,
        ),
      ),
      // The one mount: the theme by day and by night (animating between
      // them and between palettes), and the toasts.
      builder: (context, child) => MinimalHost(
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
  Widget build(BuildContext context) => MinimalAppShell.branches(
    header: Text('Shelf', style: context.minimalTheme.h3),
    destinations: const [
      MinimalNavItem(LucideIcons.libraryBig, 'Books'),
      MinimalNavItem(LucideIcons.bookOpen, 'Reading'),
      MinimalNavItem(LucideIcons.settings, 'Settings'),
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
      return MinimalScaffold(
        maxWidth: MinimalLayout.contentWidth(context),
        padding: EdgeInsets.zero,
        topBar: MinimalAppBar(
          title: title,
          subtitle: '${books.length}',
          actions: [
            MinimalIconButton(
              LucideIcons.plus,
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
            ? const MinimalEmptyState(
                icon: LucideIcons.bookOpen,
                title: 'Nothing here yet',
                body: 'Books you add show up here.',
              )
            : MinimalListSection(
                children: [
                  for (final book in books)
                    MinimalListTile(
                      title: book.title,
                      subtitle: book.author,
                      trailing: MinimalTag(
                        book.status.label,
                        tone: book.status.tone,
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
    // An alert: a screen reader hears it ask, and a stray tap on the scrim
    // answers nothing.
    final sure = await showMinimalDialog<bool>(
      context,
      isAlert: true,
      builder: (context) => MinimalDialog(
        title: 'Delete "${book.title}"?',
        message: 'It leaves your shelf. This cannot be undone.',
        confirmLabel: 'Delete',
        cancelLabel: 'Keep',
        destructive: true,
      ),
    );
    if (sure != true || !context.mounted) return;
    library.delete(book);
    Navigator.of(context).pop();
    showMinimalSnackBar(context, 'Deleted "${book.title}"');
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: library,
    builder: (context, _) {
      final started = book.started;
      return MinimalScaffold(
        maxWidth: MinimalLayout.contentWidth(context),
        topBar: MinimalAppBar(
          title: book.title,
          parent: parent,
          actions: [
            MinimalIconButton(
              LucideIcons.pencil,
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
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MinimalProperty(
              icon: LucideIcons.user,
              label: 'Author',
              value: book.author,
            ),
            MinimalProperty(
              icon: LucideIcons.circleDot,
              label: 'Status',
              value: book.status.label,
              tone: book.status.tone,
            ),
            MinimalProperty(
              icon: LucideIcons.calendar,
              label: 'Started',
              value: started == null
                  ? null
                  : RawWidgetsLocalizations.of(context)
                        .formatMediumDate(started),
              placeholder: 'Not yet',
            ),
            MinimalProperty(
              icon: LucideIcons.heart,
              label: 'Favourite',
              value: book.favourite ? 'Yes' : 'No',
            ),
          ],
        ),
        footer: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            MinimalButton(
              'Delete',
              variant: MinimalButtonVariant.destructive,
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
    showMinimalSnackBar(context, 'Saved "${book.title}"');
  }

  @override
  Widget build(BuildContext context) => MinimalForm(
    // Called once every field is fine, after each field's onSaved.
    onSubmit: _save,
    child: MinimalScaffold(
      maxWidth: MinimalLayout.contentWidth(context),
      topBar: MinimalAppBar(
        title: widget.book == null ? 'New book' : 'Edit',
        parent: widget.parent,
      ),
      // The form column: every field at the column's width, 16 px apart.
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: MinimalSpacing.s16,
        children: [
          MinimalTextFormField(
            labelText: 'Title',
            required: true,
            initialValue: _draft.title,
            textCapitalization: TextCapitalization.words,
            validator: (value) =>
                (value ?? '').trim().isEmpty ? 'Enter the title' : null,
            onSaved: (value) => _draft.title = value!.trim(),
          ),
          MinimalTextFormField(
            labelText: 'Author',
            initialValue: _draft.author,
            textCapitalization: TextCapitalization.words,
            onSaved: (value) => _draft.author = value!.trim(),
          ),
          // Hairline rows stand together, rule to rule, so each row's words
          // stand midway between its rules.
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MinimalSelect(
                labelText: 'Status',
                value: _draft.status.name,
                options: [
                  for (final status in Status.values)
                    MinimalSelectOption(status.name, status.label),
                ],
                onChanged: (value) =>
                    setState(() => _draft.status = Status.values.byName(value)),
              ),
              MinimalDatePicker(
                labelText: 'Started',
                mode: MinimalDatePickerMode.date,
                value: _draft.started,
                hintText: 'Not yet',
                lastDate: DateTime.now(),
                onChanged: (value) => setState(() => _draft.started = value),
              ),
            ],
          ),
          MinimalSwitch(
            label: 'Favourite',
            showLabel: true,
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
            builder: (context) => MinimalButton(
              'Save',
              onPressed: () => MinimalForm.submit(context),
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
    builder: (context, _) => MinimalScaffold(
      maxWidth: MinimalLayout.contentWidth(context),
      topBar: const MinimalAppBar(title: 'Settings'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: MinimalSpacing.s24,
        children: [
          MinimalFormField(
            labelText: 'Appearance',
            child: MinimalSegmentedButton<String>(
              segments: const [
                MinimalButtonSegment('system', 'System'),
                MinimalButtonSegment('light', 'Light'),
                MinimalButtonSegment('dark', 'Dark'),
              ],
              value: library.brightness?.name ?? 'system',
              onChanged: (value) => value == 'system'
                  ? library.setAppearance(system: true)
                  : library.setAppearance(
                      brightness: Brightness.values.byName(value),
                    ),
            ),
          ),
          MinimalFormField(
            labelText: 'Palette',
            group: true,
            child: MinimalRadioGroup<RawNamedPalette>(
              value: library.palette,
              onChanged: (value) => library.setAppearance(palette: value),
              options: [
                for (final palette in MinimalThemeData.palettes)
                  MinimalRadioOption(
                    value: palette,
                    label: palette.label,
                    secondary: PaletteSwatches(palette),
                  ),
              ],
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
    final theme = context.minimalTheme;
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
        border: Border.all(color: theme.border),
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

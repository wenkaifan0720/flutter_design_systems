// Shelf: a small reading list on Frosted, the whole app in one file. The host
// over the navigator (light, dark or the platform's, the palette, and the
// toasts), the shell with three places, a list with a pushed detail, a form
// with validation and a date, a dialog popped with its answer, and settings
// with the six palettes. Copy it, rename it, and grow it.
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:material_ui/material_ui.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await frostedLoadFonts(); // the bundled faces, before the first frame
  runApp(ShelfApp());
}

// The data

enum Status {
  wanted('Want to read', FrostedTone.quiet),
  reading('Reading', FrostedTone.info),
  finished('Finished', FrostedTone.success);

  const Status(this.label, this.tone);

  final String label;
  final FrostedTone tone;
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

  /// The palette, one of [FrostedThemeData.palettes].
  RawNamedPalette palette = FrostedThemeData.palettes.first;

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

/// How wide a page's column grows on a wide window.
const double _measure = 760;

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
      // The one mount: the palette by day and by night (easing between
      // them), Frosted's page motion, and the toasts.
      builder: (context, child) => FrostedHost(
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
  Widget build(BuildContext context) => FrostedAppShell(
    header: const FrostedWordmark('Shelf'),
    destinations: const [
      RawNavigationDestination(label: 'Books', icon: LucideIcons.libraryBig),
      RawNavigationDestination(label: 'Reading', icon: LucideIcons.bookOpen),
      RawNavigationDestination(label: 'Settings', icon: LucideIcons.settings),
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
      final title = only?.label ?? 'Books';
      return FrostedScaffold(
        maxWidth: _measure,
        topBar: FrostedAppBar(
          title: title,
          caption: FrostedFormat.plural(books.length, 'book'),
          actions: [
            FrostedIconButton(
              FrostedGlyphs.add,
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
            ? const FrostedEmptyState(
                title: 'Nothing here yet',
                body: 'Books you add show up here.',
              )
            : FrostedRowGroup(
                hairlines: true,
                children: [
                  for (final book in books)
                    FrostedListTile(
                      leading: FrostedMonogram(book.title),
                      title: book.title,
                      meta: book.author,
                      trailing: FrostedTag(
                        book.status.label,
                        tone: book.status.tone,
                      ),
                      onPressed: () => Navigator.of(context).push(
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
    final sure = await FrostedDialog.show(
      context,
      title: 'Delete "${book.title}"?',
      message: 'It leaves your shelf. This cannot be undone.',
      confirmLabel: 'Delete',
      cancelLabel: 'Keep',
      isDestructiveAction: true,
    );
    if (sure != true || !context.mounted) return;
    library.delete(book);
    Navigator.of(context).pop();
    FrostedToast.show(context, 'Deleted "${book.title}"');
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: library,
    builder: (context, _) {
      final started = book.started;
      return FrostedScaffold(
        maxWidth: _measure,
        topBar: FrostedAppBar(
          title: book.title,
          backLabel: parent,
          actions: [
            FrostedIconButton(
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
        body: FrostedDescriptionList(
          children: [
            FrostedKeyValue(label: 'Author', value: book.author),
            FrostedKeyValue(
              label: 'Status',
              valueWidget: FrostedTag(
                book.status.label,
                tone: book.status.tone,
              ),
            ),
            FrostedKeyValue(
              label: 'Started',
              value: started == null
                  ? 'Not yet'
                  : FrostedFormat.date(started, year: true),
            ),
            FrostedKeyValue(
              label: 'Favourite',
              value: book.favourite ? 'Yes' : 'No',
            ),
          ],
        ),
        footer: FrostedButtonRow(
          children: [
            FrostedButton.destructive(
              'Delete',
              onPressed: () => _delete(context),
            ),
          ],
        ),
      );
    },
  );
}

// A form

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
    FrostedToast.show(context, 'Saved "${book.title}"');
  }

  @override
  Widget build(BuildContext context) => FrostedScaffold(
    maxWidth: _measure,
    topBar: FrostedAppBar(
      title: widget.book == null ? 'New book' : 'Edit',
      backLabel: widget.parent,
    ),
    body: Form(
      key: _form,
      // Every field at the column's width, 16 apart.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: FrostedSpacing.s16,
        children: [
          FrostedTextFormField(
            labelText: 'Title',
            initialValue: _draft.title,
            textInputAction: TextInputAction.next,
            validator: (value) =>
                (value ?? '').trim().isEmpty ? 'Enter the title' : null,
            onSaved: (value) => _draft.title = value!.trim(),
          ),
          FrostedTextFormField(
            labelText: 'Author',
            initialValue: _draft.author,
            onSaved: (value) => _draft.author = value!.trim(),
          ),
          FrostedSelect<Status>(
            labelText: 'Status',
            value: _draft.status,
            options: [
              for (final status in Status.values)
                FrostedSelectOption(status, status.label),
            ],
            onChanged: (value) => setState(() => _draft.status = value),
          ),
          FrostedDateField(
            labelText: 'Started',
            value: _draft.started,
            hintText: 'Not yet',
            lastDate: DateTime.now(),
            onChanged: (value) => setState(() => _draft.started = value),
          ),
          FrostedSwitchRow(
            label: 'Favourite',
            value: _draft.favourite,
            onChanged: (value) => setState(() => _draft.favourite = value),
          ),
        ],
      ),
    ),
    footer: FrostedButtonRow(
      children: [FrostedButton('Save', onPressed: _save)],
    ),
  );
}

// Settings

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.library});

  final Library library;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: library,
    builder: (context, _) => FrostedScaffold(
      maxWidth: _measure,
      topBar: const FrostedAppBar(title: 'Settings'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: FrostedSpacing.s24,
        children: [
          FrostedFormField(
            labelText: 'Appearance',
            child: FrostedSegmentedButton<String>(
              label: 'Appearance',
              fill: true,
              segments: const [
                FrostedButtonSegment('system', 'System'),
                FrostedButtonSegment('light', 'Light'),
                FrostedButtonSegment('dark', 'Dark'),
              ],
              value: library.brightness?.name ?? 'system',
              onChanged: (value) => value == 'system'
                  ? library.setAppearance(system: true)
                  : library.setAppearance(
                      brightness: Brightness.values.byName(value),
                    ),
            ),
          ),
          FrostedRadioGroup<String>(
            labelText: 'Palette',
            value: library.palette.id,
            onChanged: (id) => library.setAppearance(
              palette: FrostedThemeData.palettes.firstWhere((p) => p.id == id),
            ),
            // Each palette by its name and its colours, as they show by day
            // or by night.
            options: [
              for (final palette in FrostedThemeData.palettes)
                FrostedRadio(
                  palette.id,
                  palette.label,
                  suffix: Swatches(
                    palette.swatchesFor(FrostedTheme.of(context).brightness),
                  ),
                ),
            ],
          ),
        ],
      ),
    ),
  );
}

/// A palette's colours as a picker shows them, as Material's palette
/// pickers do: one disc split between them, the most telling on top, in a
/// hairline so a pale colour reads on a pale page and a dark one on a dark
/// page.
class Swatches extends StatelessWidget {
  const Swatches(this.colors, {super.key});

  final List<Color> colors;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 24,
    child: CustomPaint(
      painter: _SplitDisc(
        colors,
        FrostedTheme.of(context).colorScheme.textSecondary,
      ),
    ),
  );
}

class _SplitDisc extends CustomPainter {
  _SplitDisc(this.colors, this.ring);

  final List<Color> colors;
  final Color ring;

  @override
  void paint(Canvas canvas, Size size) {
    final disc = Offset.zero & size;
    final share = 2 * math.pi / colors.length;
    for (final (i, color) in colors.indexed) {
      canvas.drawArc(
        disc,
        -3 * math.pi / 4 + share * i,
        share,
        true,
        Paint()..color = color,
      );
    }
    canvas.drawCircle(
      disc.center,
      size.shortestSide / 2 - .5,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = ring,
    );
  }

  @override
  bool shouldRepaint(_SplitDisc old) =>
      !listEquals(old.colors, colors) || old.ring != ring;
}

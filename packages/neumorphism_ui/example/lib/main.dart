// Shelf: a small reading list on Neumorphism, the whole app in one file. The host
// over the navigator (light, dark or the platform's, the palette, and the
// toasts), the shell with three places, a list with a pushed detail, a form
// with validation and a date, a dialog popped with its answer, and settings
// with the six palettes. Copy it, rename it, and grow it.
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:material_ui/material_ui.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await neumorphicLoadFonts(); // the bundled faces, before the first frame
  runApp(ShelfApp());
}

// The data

enum Status {
  wanted('Want to read'),
  reading('Reading'),
  finished('Finished');

  const Status(this.label);

  final String label;
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

  /// The first letters of the title's first two words, for its monogram.
  String get initials => title
      .split(' ')
      .where((word) => word.isNotEmpty)
      .take(2)
      .map((word) => word[0].toUpperCase())
      .join();
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

  /// The palette, one of [NeumorphicThemeData.palettes].
  RawNamedPalette palette = NeumorphicThemeData.palettes.first;

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
      // The parts' own words in 30 languages, and Material's: material_ui
      // brings Flutter's translations, so no flutter_localizations.
      localizationsDelegates: const [
        RawWidgetsLocalizations.delegate,
        NeumorphicLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: RawWidgetsLocalizations.supportedLocales,
      // The one mount: the palette by day and by night (easing between
      // them), Neumorphism's page motion, and the toasts.
      builder: (context, child) => NeumorphicHost(
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
  Widget build(BuildContext context) => NeumorphicAppShell(
    header: const NeumorphicBrandRow('Shelf'),
    destinations: const [
      RawNavigationDestination(label: 'Books', icon: NeumorphicGlyphs.layers),
      RawNavigationDestination(
        label: 'Reading',
        icon: NeumorphicGlyphs.bookOpen,
      ),
      RawNavigationDestination(
        label: 'Settings',
        icon: NeumorphicGlyphs.settings,
      ),
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
      return NeumorphicScaffold(
        maxWidth: _measure,
        topBar: NeumorphicAppBar(
          title: title,
          subtitle: books.length == 1 ? '1 book' : '${books.length} books',
          actions: [
            NeumorphicIconButton(
              NeumorphicGlyphs.plus,
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
            ? const NeumorphicEmptyState(
                title: 'Nothing here yet',
                body: 'Books you add show up here.',
              )
            : NeumorphicListSection(
                children: [
                  for (final book in books)
                    NeumorphicListTile(
                      leading: NeumorphicMonogram(book.initials),
                      title: book.title,
                      subtitle: book.author,
                      trailing: NeumorphicTag(book.status.label),
                      onPressed: () => Navigator.of(context).push(
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
    final sure = await showNeumorphicDialog<bool>(
      context,
      builder: (context) => NeumorphicDialog(
        title: 'Delete "${book.title}"?',
        message: 'It leaves your shelf. This cannot be undone.',
        actions: [
          NeumorphicButton(
            'Keep',
            onPressed: () => Navigator.of(context).pop(false),
          ),
          NeumorphicButton.filled(
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
    showNeumorphicToast(context, message: 'Deleted "${book.title}"');
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: library,
    builder: (context, _) {
      final started = book.started;
      return NeumorphicScaffold(
        maxWidth: _measure,
        topBar: NeumorphicAppBar(
          title: book.title,
          actions: [
            NeumorphicIconButton(
              NeumorphicGlyphs.pencil,
              semanticLabel: 'Edit',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => BookForm(library: library, book: book),
                ),
              ),
            ),
          ],
        ),
        body: NeumorphicDescriptionList([
          NeumorphicDescription('Author', book.author),
          // What you are reading now is live: it takes the pigment.
          NeumorphicDescription(
            'Status',
            book.status.label,
            live: book.status == Status.reading,
          ),
          NeumorphicDescription(
            'Started',
            started == null
                ? 'Not yet'
                : NeumorphicFormat.mediumDate(context, started),
          ),
          NeumorphicDescription('Favourite', book.favourite ? 'Yes' : 'No'),
        ]),
        footer: NeumorphicButton(
          'Delete',
          isDestructiveAction: true,
          wide: true,
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
    showNeumorphicToast(context, message: 'Saved "${book.title}"');
  }

  @override
  Widget build(BuildContext context) => NeumorphicScaffold(
    maxWidth: _measure,
    topBar: NeumorphicAppBar(title: widget.book == null ? 'New book' : 'Edit'),
    body: Form(
      key: _form,
      // Every field at the column's width, 20 apart.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 20,
        children: [
          NeumorphicTextFormField(
            labelText: 'Title',
            initialValue: _draft.title,
            textInputAction: TextInputAction.next,
            validator: (value) =>
                (value ?? '').trim().isEmpty ? 'Enter the title' : null,
            onSaved: (value) => _draft.title = value!.trim(),
          ),
          NeumorphicTextFormField(
            labelText: 'Author',
            initialValue: _draft.author,
            onSaved: (value) => _draft.author = value!.trim(),
          ),
          NeumorphicSelect<Status>(
            labelText: 'Status',
            value: _draft.status,
            options: [
              for (final status in Status.values)
                NeumorphicMenuItem(status, status.label),
            ],
            onChanged: (value) => setState(() => _draft.status = value),
          ),
          NeumorphicDateField(
            labelText: 'Started',
            value: _draft.started,
            hintText: 'Not yet',
            lastDate: DateTime.now(),
            onChanged: (value) => setState(() => _draft.started = value),
          ),
          NeumorphicSwitchRow(
            label: 'Favourite',
            value: _draft.favourite,
            onChanged: (value) => setState(() => _draft.favourite = value),
          ),
        ],
      ),
    ),
    footer: NeumorphicButton.filled('Save', wide: true, onPressed: _save),
  );
}

// Settings

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.library});

  final Library library;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: library,
    builder: (context, _) {
      final brightness = NeumorphicTheme.of(context).dark
          ? Brightness.dark
          : Brightness.light;
      return NeumorphicScaffold(
        maxWidth: _measure,
        topBar: const NeumorphicAppBar(title: 'Settings'),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 28,
          children: [
            NeumorphicFormField(
              labelText: 'Appearance',
              child: NeumorphicSegmentedButton<String>(
                semanticLabel: 'Appearance',
                segments: const [
                  NeumorphicButtonSegment('system', 'System'),
                  NeumorphicButtonSegment('light', 'Light'),
                  NeumorphicButtonSegment('dark', 'Dark'),
                ],
                value: library.brightness?.name ?? 'system',
                onChanged: (value) => value == 'system'
                    ? library.setAppearance(system: true)
                    : library.setAppearance(
                        brightness: Brightness.values.byName(value),
                      ),
              ),
            ),
            NeumorphicFormField(
              labelText: 'Palette',
              child: NeumorphicRadioGroup<String>(
                semanticLabel: 'Palette',
                value: library.palette.id,
                onChanged: (id) => library.setAppearance(
                  palette: NeumorphicThemeData.palettes.firstWhere(
                    (p) => p.id == id,
                  ),
                ),
                // Each palette by its name and its colours, as they show by
                // day or by night.
                options: [
                  for (final palette in NeumorphicThemeData.palettes)
                    NeumorphicRadio(
                      palette.id,
                      palette.label,
                      suffix: Swatches(palette.swatchesFor(brightness)),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// A palette's colours as a picker shows them, as Material's palette
/// pickers do: one disc split between them, the most telling on top, in a
/// hairline so a pale colour reads on a pale wall and a dark one on a dark
/// wall.
class Swatches extends StatelessWidget {
  const Swatches(this.colors, {super.key});

  final List<Color> colors;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 24,
    child: CustomPaint(
      painter: _SplitDisc(
        colors,
        NeumorphicTheme.of(context).colors.inkSecondary,
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

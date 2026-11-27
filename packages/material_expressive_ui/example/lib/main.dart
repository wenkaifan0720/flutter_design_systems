// Shelf, a reading list built on Material Expressive: one app you can copy.
// ExpressiveHost over MaterialApp (by day, by night or as the device is, in
// any of the six palettes), ExpressiveAppShell with three places (the
// navigation bar along a phone's foot, the rail from 600 wide and the
// expanded rail from 1200), each keeping its own pages; the list of books
// with a pushed page for each, a form that checks its answers, a dialog
// popped with its answer, and the settings. The gallery, every component on
// a page of its own, is lib/gallery.dart: `flutter run -t lib/gallery.dart`.
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_ui/material_ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await expressiveLoadFonts();
  runApp(ShelfApp(shelf: Shelf.sample()));
}

/// The app: Expressive over the whole of it, in the reader's appearance and
/// palette.
class ShelfApp extends StatelessWidget {
  const ShelfApp({super.key, required this.shelf});

  final Shelf shelf;

  @override
  Widget build(BuildContext context) => ShelfScope(
    shelf: shelf,
    child: ListenableBuilder(
      listenable: shelf,
      builder: (context, _) => MaterialApp(
        title: 'Shelf',
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          DefaultRawWidgetsLocalizations.delegate,
          ExpressiveLocalizations.delegate,
          DefaultMaterialLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
        builder: (context, child) => ExpressiveHost(
          brightness: shelf.appearance.brightness,
          palette: shelf.palette,
          child: child!,
        ),
        home: const ShelfShell(),
      ),
    ),
  );
}

/// The app's three places. Each keeps its own pages: a book opened from
/// Books stands beside the rail, and back closes it.
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
      (context) => const BooksPage(),
      (context) => AddBookPage(onAdded: () => setState(() => _place = 0)),
      (context) => const SettingsPage(),
    ],
  );
}

/// A page's column: the width a list or a form reads at, from the page's
/// start, where the app bar's title stands.
class ShelfColumn extends StatelessWidget {
  const ShelfColumn({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.topStart,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 640),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: ExpressiveSpacing.s24,
        children: children,
      ),
    ),
  );
}

/// A part's name over it, in the title type.
class ShelfHeading extends StatelessWidget {
  const ShelfHeading(this.text, {super.key, this.note});

  final String text;

  /// A line under the name.
  final String? note;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: ExpressiveSpacing.s4,
      children: [
        Semantics(
          header: true,
          child: Text(
            text,
            style: t.type.titleMedium.copyWith(color: t.colors.onSurface),
          ),
        ),
        if (note case final note?)
          Text(
            note,
            style: t.type.bodyMedium.copyWith(color: t.colors.onSurfaceVariant),
          ),
      ],
    );
  }
}

/// The reading list: the year's goal, then every book, each opening its
/// own page.
class BooksPage extends StatelessWidget {
  const BooksPage({super.key});

  @override
  Widget build(BuildContext context) {
    final shelf = ShelfScope.of(context);
    final books = shelf.books;
    return ExpressiveScaffold(
      topBar: const ExpressiveAppBar(title: 'Books'),
      body: ShelfColumn(
        children: [
          ShelfHeading(
            'Reading goal for 2026',
            note: '${shelf.finished} of ${shelf.goal} finished',
          ),
          ExpressiveLinearProgressIndicator(
            value: (shelf.finished / shelf.goal).clamp(0.0, 1.0),
            expand: true,
            semanticLabel: 'Reading goal',
          ),
          if (books.isEmpty)
            const ExpressiveEmptyState(
              icon: ExpressiveSymbols.book,
              title: 'No books yet',
              body: 'Books you add show here.',
            )
          else
            ExpressiveListSection(
              header: books.length == 1 ? '1 book' : '${books.length} books',
              children: [
                for (final book in books)
                  ExpressiveListTile(
                    key: ValueKey(book.id),
                    title: Text(book.title),
                    subtitle: Text(book.byline),
                    trailing: book.status.tag,
                    // A page pushed on the Books place: the rail stays
                    // beside it.
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => BookPage(id: book.id),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

/// One book: what the reader said about it, and the ways to change it or
/// delete it.
class BookPage extends StatelessWidget {
  const BookPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    final book = ShelfScope.of(context).byId(id);
    if (book == null) return const SizedBox.shrink();
    final colors = context.expressiveTheme.colors;
    void edit() => Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ExpressiveScaffold(
          topBar: const ExpressiveAppBar(title: 'Change book'),
          body: ShelfColumn(
            children: [
              BookForm(
                saveLabel: 'Save changes',
                initial: book,
                onSaved: (changed) {
                  ShelfScope.read(context).put(changed);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
    return ExpressiveScaffold(
      topBar: ExpressiveAppBar(title: book.title),
      body: ShelfColumn(
        children: [
          ExpressiveDescriptionList(
            items: [
              ExpressiveDescriptionItem(
                'Author',
                book.author.isEmpty ? 'Not given' : book.author,
              ),
              ExpressiveDescriptionItem('Format', book.format.label),
              ExpressiveDescriptionItem('Status', book.status.label),
              ExpressiveDescriptionItem(
                'Favourite',
                book.favourite ? 'Yes' : 'No',
              ),
              ExpressiveDescriptionItem(
                'Date started',
                book.started == null
                    ? 'Not given'
                    : ExpressiveFormat.date(book.started!),
              ),
            ],
          ),
          Wrap(
            spacing: ExpressiveSpacing.s12,
            runSpacing: ExpressiveSpacing.s12,
            children: [
              ExpressiveFilledButton(
                'Change book',
                icon: ExpressiveSymbols.edit,
                onPressed: edit,
              ),
              // A destructive act in the error container (Material's
              // guidance), apart from the primary act beside it.
              ExpressiveFilledButton.tonal(
                'Delete book',
                icon: ExpressiveSymbols.delete,
                style: ExpressiveFilledButton.styleFrom(
                  backgroundColor: colors.errorContainer,
                  foregroundColor: colors.onErrorContainer,
                ),
                onPressed: () async {
                  if (await deleteBook(context, book) && context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Asks before deleting [book]: the dialog is popped with the answer. Says
/// so in a snackbar once it is gone; returns whether it went.
Future<bool> deleteBook(BuildContext context, Book book) async {
  final shelf = ShelfScope.read(context);
  final delete = await showExpressiveDialog<bool>(
    context: context,
    builder: (context) => ExpressiveDialog(
      title: 'Delete “${book.title}”?',
      text: 'It comes off your list. You cannot undo this.',
      actions: const [
        ExpressiveDialogAction('Keep it', value: false),
        ExpressiveDialogAction(
          'Delete book',
          value: true,
          isDestructiveAction: true,
        ),
      ],
    ),
  );
  if (delete != true) return false;
  shelf.remove(book.id);
  if (context.mounted) {
    showExpressiveSnackBar(context, 'Deleted “${book.title}”');
  }
  return true;
}

/// The Add place: a new book's answers.
class AddBookPage extends StatelessWidget {
  const AddBookPage({super.key, required this.onAdded});

  /// Called once the book is on the list.
  final VoidCallback onAdded;

  @override
  Widget build(BuildContext context) => ExpressiveScaffold(
    topBar: const ExpressiveAppBar(title: 'Add a book'),
    body: ShelfColumn(
      children: [
        BookForm(
          saveLabel: 'Save book',
          onSaved: (book) {
            ShelfScope.read(context).put(book);
            showExpressiveSnackBar(context, 'Added “${book.title}”');
            onAdded();
          },
        ),
      ],
    ),
  );
}

/// The answers about a book. Saving checks them: a missing title is said
/// at the field, and the focus goes to it.
class BookForm extends StatefulWidget {
  const BookForm({
    super.key,
    required this.saveLabel,
    required this.onSaved,
    this.initial,
  });

  final String saveLabel;
  final ValueChanged<Book> onSaved;

  /// The book being changed; null adds one.
  final Book? initial;

  @override
  State<BookForm> createState() => _BookFormState();
}

class _BookFormState extends State<BookForm> {
  late final _title = TextEditingController(text: widget.initial?.title);
  late final _author = TextEditingController(text: widget.initial?.author);
  final _titleFocus = FocusNode();
  late BookFormat _format = widget.initial?.format ?? BookFormat.paperback;
  late BookStatus _status = widget.initial?.status ?? BookStatus.toRead;
  late bool _favourite = widget.initial?.favourite ?? false;
  late DateTime? _started = widget.initial?.started;
  String? _titleError;

  @override
  void dispose() {
    _title.dispose();
    _author.dispose();
    _titleFocus.dispose();
    super.dispose();
  }

  // The form's check: each field's error in words, or null.
  String? _checkTitle(String title) =>
      title.trim().isEmpty ? 'Enter the book’s title' : null;

  void _save() {
    setState(() => _titleError = _checkTitle(_title.text));
    if (_titleError != null) {
      _titleFocus.requestFocus();
      return;
    }
    widget.onSaved(
      Book(
        id: widget.initial?.id ?? '${DateTime.now().microsecondsSinceEpoch}',
        title: _title.text.trim(),
        author: _author.text.trim(),
        format: _format,
        status: _status,
        favourite: _favourite,
        started: _started,
      ),
    );
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
        textInputAction: TextInputAction.next,
        onChanged: (_) {
          if (_titleError != null) setState(() => _titleError = null);
        },
      ),
      ExpressiveTextField(
        labelText: 'Author',
        helperText: 'Optional',
        controller: _author,
      ),
      ExpressiveSelect<BookFormat>(
        labelText: 'Format',
        value: _format,
        options: [
          for (final format in BookFormat.values)
            ExpressiveSelectOption(format, format.label),
        ],
        onChanged: (format) => setState(() => _format = format),
      ),
      ShelfPart(
        heading: const ShelfHeading('Status'),
        child: ExpressiveRadioGroup<BookStatus>(
          semanticLabel: 'Status',
          contentPadding: EdgeInsets.zero,
          value: _status,
          options: [
            for (final status in BookStatus.values)
              ExpressiveRadioOption(value: status, label: status.label),
          ],
          onChanged: (status) => setState(() => _status = status),
        ),
      ),
      ExpressiveSwitchRow(
        label: 'Favourite',
        supportingText: 'Favourites are marked in your list.',
        contentPadding: EdgeInsets.zero,
        value: _favourite,
        onChanged: (on) => setState(() => _favourite = on),
      ),
      ExpressiveDockedDatePicker(
        label: 'Date started',
        value: _started,
        firstDate: DateTime(1900),
        lastDate: DateTime(2100),
        onChanged: (day) => setState(() => _started = day),
      ),
      ExpressiveFilledButton(widget.saveLabel, expand: true, onPressed: _save),
    ],
  );
}

/// The appearance, the palette and the year's goal.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final shelf = ShelfScope.of(context);
    return ExpressiveScaffold(
      topBar: const ExpressiveAppBar(title: 'Settings'),
      body: ShelfColumn(
        children: [
          // Each heading stands with its control, the parts 24 apart.
          ShelfPart(
            heading: const ShelfHeading(
              'Appearance',
              note: 'System follows your device.',
            ),
            child: ExpressiveSegmentedButton<Appearance>(
              segments: [
                for (final appearance in Appearance.values)
                  ExpressiveButtonSegment(appearance, appearance.label),
              ],
              value: shelf.appearance,
              onChanged: (appearance) => shelf.appearance = appearance,
            ),
          ),
          // The six palettes, each by its colour as it shows now and its
          // name; an app stores the id.
          ShelfPart(
            heading: const ShelfHeading('Colour'),
            child: ExpressiveRadioGroup<String>(
              semanticLabel: 'Colour',
              contentPadding: EdgeInsets.zero,
              value: shelf.palette.id,
              options: [
                for (final palette in ExpressiveThemeData.palettes)
                  ExpressiveRadioOption(
                    value: palette.id,
                    label: palette.label,
                    leading: PaletteSwatch(palette: palette),
                  ),
              ],
              onChanged: (id) => shelf.palette = ExpressiveThemeData.palettes
                  .firstWhere((palette) => palette.id == id),
            ),
          ),
          ShelfPart(
            heading: ShelfHeading(
              'Books to finish this year',
              note: '${shelf.goal} books',
            ),
            child: ExpressiveSlider(
              value: shelf.goal.toDouble(),
              min: 4,
              max: 52,
              semanticLabel: 'Books to finish this year',
              onChanged: (goal) => shelf.goal = goal.round(),
            ),
          ),
        ],
      ),
    );
  }
}

/// A palette's primary as it shows now (by day or by night), beside its
/// name: what the name stands for, seen. A filled disc, apart from the
/// radio's ring.
class PaletteSwatch extends StatelessWidget {
  const PaletteSwatch({super.key, required this.palette});

  final RawNamedPalette palette;

  @override
  Widget build(BuildContext context) {
    final theme = context.expressiveTheme;
    final [primary, ...] = palette.swatchesFor(theme.brightness);
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: primary,
        shape: BoxShape.circle,
        border: Border.all(color: theme.colors.outlineVariant),
      ),
    );
  }
}

/// A heading over its control, 8 apart.
class ShelfPart extends StatelessWidget {
  const ShelfPart({super.key, required this.heading, required this.child});

  final Widget heading;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: ExpressiveSpacing.s8,
    children: [heading, child],
  );
}

// The app's state: the books, and how the reader likes the app.

enum BookStatus {
  toRead('To read'),
  reading('Reading'),
  done('Done');

  const BookStatus(this.label);

  final String label;

  /// Its tag in the list: the palette's own while it is read; outlined while
  /// it waits and once it is done, statuses at rest.
  Widget get tag => switch (this) {
    reading => ExpressiveTag(label, tone: ExpressiveTone.primary),
    toRead || done => ExpressiveTag(label),
  };
}

enum BookFormat {
  paperback('Paperback'),
  hardback('Hardback'),
  ebook('Ebook'),
  audiobook('Audiobook');

  const BookFormat(this.label);

  final String label;
}

enum Appearance {
  light('Light', Brightness.light),
  dark('Dark', Brightness.dark),
  system('System', null);

  const Appearance(this.label, this.brightness);

  final String label;

  /// What the host pins; null follows the device.
  final Brightness? brightness;
}

@immutable
class Book {
  const Book({
    required this.id,
    required this.title,
    this.author = '',
    this.format = BookFormat.paperback,
    this.status = BookStatus.toRead,
    this.favourite = false,
    this.started,
  });

  final String id;
  final String title;
  final String author;
  final BookFormat format;
  final BookStatus status;
  final bool favourite;
  final DateTime? started;

  /// The line under the title in the list.
  String get byline => [
    if (author.isEmpty) 'Author not given' else author,
    if (favourite) 'Favourite',
  ].join(' · ');
}

/// The reading list and the reader's settings, kept while the app runs.
class Shelf extends ChangeNotifier {
  Shelf(this._books);

  Shelf.sample()
    : this([
        Book(
          id: '1',
          title: 'Middlemarch',
          author: 'George Eliot',
          status: BookStatus.reading,
          started: DateTime(2026, 10, 2),
        ),
        const Book(
          id: '2',
          title: 'The Left Hand of Darkness',
          author: 'Ursula K. Le Guin',
          status: BookStatus.done,
          favourite: true,
        ),
        const Book(
          id: '3',
          title: 'Pride and Prejudice',
          author: 'Jane Austen',
          format: BookFormat.hardback,
          status: BookStatus.done,
        ),
        const Book(id: '4', title: 'Beloved', author: 'Toni Morrison'),
        const Book(
          id: '5',
          title: 'Things Fall Apart',
          author: 'Chinua Achebe',
          format: BookFormat.audiobook,
        ),
      ]);

  final List<Book> _books;

  List<Book> get books => List.unmodifiable(_books);

  int get finished => _books.where((b) => b.status == BookStatus.done).length;

  Book? byId(String id) => _books.where((b) => b.id == id).firstOrNull;

  /// Adds [book], or puts it in place of the book with its id.
  void put(Book book) {
    final at = _books.indexWhere((b) => b.id == book.id);
    if (at < 0) {
      _books.insert(0, book);
    } else {
      _books[at] = book;
    }
    notifyListeners();
  }

  void remove(String id) {
    _books.removeWhere((b) => b.id == id);
    notifyListeners();
  }

  int get goal => _goal;
  int _goal = 12;
  set goal(int value) {
    _goal = value;
    notifyListeners();
  }

  Appearance get appearance => _appearance;
  Appearance _appearance = Appearance.system;
  set appearance(Appearance value) {
    _appearance = value;
    notifyListeners();
  }

  RawNamedPalette get palette => _palette;
  RawNamedPalette _palette = ExpressiveThemeData.palettes.first;
  set palette(RawNamedPalette value) {
    _palette = value;
    notifyListeners();
  }
}

/// Puts the [Shelf] within reach of every page.
class ShelfScope extends InheritedNotifier<Shelf> {
  const ShelfScope({super.key, required Shelf shelf, required super.child})
    : super(notifier: shelf);

  /// The shelf, rebuilding [context] as it changes.
  static Shelf of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShelfScope>()!.notifier!;

  /// The shelf, to change it from a callback.
  static Shelf read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<ShelfScope>()!.notifier!;
}

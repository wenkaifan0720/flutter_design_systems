// Shelf, a reading list built on Terminal: one app you can copy. TermHost
// over MaterialApp (by day, by night or as the device is, in any of
// Terminal's six palettes), TermScaffold.branches with three places (a
// window list along a phone's foot, a rail from 600 wide, the side pane from
// 1100), each keeping its own screens; the list of books with a pushed
// screen for each, a form that checks its answers, a question popped with
// its answer, and the settings. Terminal's gallery, every part on a page of
// its own, is lib/gallery.dart: `flutter run -t lib/gallery.dart`.
import 'package:material_ui/material_ui.dart';
import 'package:terminal_ui/terminal_ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The faces before the first frame: the grid never starts in a fallback.
  await termLoadFonts();
  runApp(ShelfApp(shelf: Shelf.sample()));
}

/// The app: Terminal over the whole of it, in the reader's appearance and
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
        builder: (context, child) => TermHost(
          brightness: shelf.appearance.brightness,
          palette: shelf.palette,
          child: child!,
        ),
        home: const ShelfShell(),
      ),
    ),
  );
}

/// The app's three places. Each keeps its own screens: a book opened from
/// books stands beside the rail or the side pane, and back closes it.
class ShelfShell extends StatefulWidget {
  const ShelfShell({super.key});

  @override
  State<ShelfShell> createState() => _ShelfShellState();
}

class _ShelfShellState extends State<ShelfShell> {
  int _place = 0;

  @override
  Widget build(BuildContext context) {
    final shelf = ShelfScope.of(context);
    return TermScaffold.branches(
      title: 'shelf',
      destinations: const [
        TermNavigationDestination(label: 'books', glyph: '≡'),
        TermNavigationDestination(label: 'add', glyph: '+'),
        TermNavigationDestination(label: 'settings', glyph: '~'),
      ],
      selectedIndex: _place,
      onDestinationSelected: (place) => setState(() => _place = place),
      statusLine: TermStatusLine(
        mode: 'SHELF',
        segments: [
          TermStatusSegment('${shelf.books.length} books'),
          TermStatusSegment('${shelf.finished} done'),
        ],
      ),
      branches: [
        (context) => const BooksScreen(),
        (context) => AddBookScreen(onAdded: () => setState(() => _place = 0)),
        (context) => const SettingsScreen(),
      ],
    );
  }
}

/// The reading list: the year's goal, then every book, each opening its
/// own screen.
class BooksScreen extends StatelessWidget {
  const BooksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final shelf = ShelfScope.of(context);
    final books = shelf.books;
    final grid = context.termGrid;
    return TermScreen(
      maxCols: TermScreen.formCols,
      title: 'books',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: grid.lineHeight,
        children: [
          TermPane(
            title: 'reading goal',
            child: TermMeter(
              label: '2026',
              value: (shelf.finished / shelf.goal).clamp(0.0, 1.0),
              reading: '${shelf.finished} of ${shelf.goal} done',
              high: 2,
              full: 2,
            ),
          ),
          if (books.isEmpty)
            const TermEmptyState(
              title: 'no books',
              message: 'books you add show here',
            )
          else
            TermPane.list(
              title: 'books',
              trailing: '${books.length}',
              children: [
                for (final book in books)
                  TermListTile(
                    key: ValueKey(book.id),
                    leading: Text(book.status.glyph),
                    title: Text(book.title),
                    subtitle: Text(book.byline),
                    trailing: Text(book.status.label),
                    // A screen pushed on the books place: the rail or the
                    // side pane stays beside it.
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => BookScreen(id: book.id),
                      ),
                    ),
                    action: TermIconButton(
                      glyph: '×',
                      semanticLabel: 'delete ${book.title}',
                      onPressed: () => deleteBook(context, book),
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
class BookScreen extends StatelessWidget {
  const BookScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    final book = ShelfScope.of(context).byId(id);
    if (book == null) return const SizedBox.shrink();
    final grid = context.termGrid;
    void edit() => Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => TermScreen(
          maxCols: TermScreen.formCols,
          title: 'edit book',
          subtitle: 'books › ${book.title}',
          body: BookForm(
            saveLabel: 'save',
            initial: book,
            onSaved: (changed) {
              ShelfScope.read(context).put(changed);
              Navigator.of(context).pop();
            },
          ),
        ),
      ),
    );
    return TermScreen(
      maxCols: TermScreen.formCols,
      title: book.title,
      subtitle: 'books',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: grid.lineHeight,
        children: [
          TermPane(
            title: 'details',
            child: TermDescriptionList(
              items: [
                ('author', book.author.isEmpty ? 'not given' : book.author),
                ('format', book.format.label),
                ('status', book.status.label),
                ('favourite', book.favourite ? 'yes' : 'no'),
                (
                  'started',
                  book.started == null ? 'not given' : termDate(book.started!),
                ),
              ],
            ),
          ),
          TermButtonGroup(
            children: [
              TermButton.filled(label: 'edit', onPressed: edit),
              TermButton(
                label: 'delete',
                isDestructiveAction: true,
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

/// Asks before deleting [book]: the question is popped with the answer.
/// Says so in a toast once it is gone; returns whether it went.
Future<bool> deleteBook(BuildContext context, Book book) async {
  final shelf = ShelfScope.read(context);
  final delete = await showTermConfirmDialog(
    context: context,
    title: 'delete book',
    message: '“${book.title}” comes off your list. this can’t be undone.',
    confirmLabel: 'delete',
    cancelLabel: 'keep',
    isDestructiveAction: true,
  );
  if (delete != true) return false;
  shelf.remove(book.id);
  if (context.mounted) {
    TermToaster.show(context, message: 'deleted “${book.title}”');
  }
  return true;
}

/// The add place: a new book's answers.
class AddBookScreen extends StatelessWidget {
  const AddBookScreen({super.key, required this.onAdded});

  /// Called once the book is on the list.
  final VoidCallback onAdded;

  @override
  Widget build(BuildContext context) => TermScreen(
    maxCols: TermScreen.formCols,
    title: 'add a book',
    body: BookForm(
      saveLabel: 'save book',
      onSaved: (book) {
        ShelfScope.read(context).put(book);
        TermToaster.show(
          context,
          message: 'added “${book.title}”',
          tone: TermTone.success,
        );
        onAdded();
      },
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

  /// Called with the book once its answers are fine.
  final ValueChanged<Book> onSaved;

  /// The book being changed; null for a new one.
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
      title.trim().isEmpty ? 'enter the book’s title' : null;

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
  Widget build(BuildContext context) {
    final grid = context.termGrid;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: grid.lineHeight,
      children: [
        TermTextField(
          labelText: 'title',
          controller: _title,
          focusNode: _titleFocus,
          errorText: _titleError,
          textInputAction: TextInputAction.next,
          onChanged: (_) {
            if (_titleError != null) setState(() => _titleError = null);
          },
        ),
        TermTextField(
          labelText: 'author',
          helperText: 'optional',
          controller: _author,
        ),
        TermSelect<BookFormat>(
          labelText: 'format',
          value: _format,
          items: [
            for (final format in BookFormat.values)
              TermSelectItem(value: format, label: format.label),
          ],
          onChanged: (format) => setState(() => _format = format),
        ),
        TermPane(
          title: 'status',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final status in BookStatus.values)
                TermRadio<BookStatus>(
                  value: status,
                  groupValue: _status,
                  label: status.label,
                  onChanged: (status) =>
                      setState(() => _status = status ?? _status),
                ),
            ],
          ),
        ),
        TermSwitch(
          label: 'favourite',
          value: _favourite,
          onChanged: (on) => setState(() => _favourite = on),
        ),
        TermDatePicker(
          labelText: 'started',
          helperText: 'optional',
          value: _started,
          firstDate: DateTime(1900),
          lastDate: DateTime(2100),
          onChanged: (day) => setState(() => _started = day),
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TermButton.filled(label: widget.saveLabel, onPressed: _save),
        ),
      ],
    );
  }
}

/// The appearance, the palette and the year's goal.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final shelf = ShelfScope.of(context);
    final grid = context.termGrid;
    return TermScreen(
      maxCols: TermScreen.formCols,
      title: 'settings',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: grid.lineHeight,
        children: [
          TermPane(
            title: 'appearance',
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: TermToggleGroup<Appearance>(
                semanticLabel: 'appearance',
                options: Appearance.values,
                selected: {shelf.appearance},
                labelOf: (appearance) => appearance.label,
                onSelectionChanged: (chosen) => shelf.appearance = chosen.first,
              ),
            ),
          ),
          // Terminal's six palettes, each by its name and its ink as it
          // shows now; an app stores the id.
          TermPane(
            title: 'palette',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final palette in TermThemeData.palettes)
                  TermRadio<String>(
                    value: palette.id,
                    groupValue: shelf.palette.id,
                    label: palette.label,
                    trailing: PaletteSwatch(palette: palette),
                    onChanged: (id) => shelf.palette = TermThemeData.palettes
                        .firstWhere((palette) => palette.id == id),
                  ),
              ],
            ),
          ),
          TermPane(
            title: 'books to finish this year',
            trailing: '${shelf.goal}',
            child: TermSlider(
              semanticLabel: 'books to finish this year',
              value: shelf.goal.toDouble(),
              min: 4,
              max: 52,
              divisions: 48,
              semanticFormatterCallback: (goal) => '${goal.round()} books',
              onChanged: (goal) => shelf.goal = goal.round(),
            ),
          ),
        ],
      ),
    );
  }
}

/// A palette's ink as it shows now (by day or by night), two cells after
/// its name: what the name stands for, seen.
class PaletteSwatch extends StatelessWidget {
  const PaletteSwatch({super.key, required this.palette});

  final RawNamedPalette palette;

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    return Text(
      '██',
      style: theme.textStyle.copyWith(
        color: palette.swatchesFor(theme.brightness).first,
      ),
    );
  }
}

// The app's state: the books, and how the reader likes the app.

enum BookStatus {
  toRead('to read', '·'),
  reading('reading', '›'),
  done('done', '✓');

  const BookStatus(this.label, this.glyph);

  final String label;

  /// Its mark at the start of its row.
  final String glyph;
}

enum BookFormat {
  paperback('paperback'),
  hardback('hardback'),
  ebook('ebook'),
  audiobook('audiobook');

  const BookFormat(this.label);

  final String label;
}

enum Appearance {
  light('light', Brightness.light),
  dark('dark', Brightness.dark),
  system('system', null);

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
    if (author.isEmpty) 'author not given' else author,
    if (favourite) 'favourite',
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
  RawNamedPalette _palette = TermThemeData.palettes.first;
  set palette(RawNamedPalette value) {
    _palette = value;
    notifyListeners();
  }
}

/// Puts the [Shelf] within reach of every screen.
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

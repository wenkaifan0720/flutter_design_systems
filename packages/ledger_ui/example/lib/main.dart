// Shelf, a reading list built on Ledger: one app you can copy. LedgerHost
// over MaterialApp (by day, by night or as the device is, in any of Ledger's
// six palettes), LedgerAppShell with three places (a tab bar along a
// phone's foot, a rail from 600 wide, the side bar from 1024), each keeping
// its own pages; the list of books with a pushed page for each, a form that
// checks its answers, a dialog popped with its answer, and the settings.
// Ledger's gallery, every part on a page of its own, is lib/gallery.dart:
// `flutter run -t lib/gallery.dart`.
import 'package:ledger_ui/ledger_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ledgerLoadFonts();
  runApp(ShelfApp(shelf: Shelf.sample()));
}

/// The app: Ledger over the whole of it, in the reader's appearance and
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
        localizationsDelegates: const [RawWidgetsLocalizations.delegate],
        builder: (context, child) => LedgerHost(
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
/// Books stands beside the rail or the side bar, and back closes it.
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
      (context) => const BooksPage(),
      (context) => AddBookPage(onAdded: () => setState(() => _place = 0)),
      (context) => const SettingsPage(),
    ],
  );
}

/// The reading list: the year's goal, then every book, each opening its
/// own page.
class BooksPage extends StatelessWidget {
  const BooksPage({super.key});

  @override
  Widget build(BuildContext context) {
    final shelf = ShelfScope.of(context);
    final books = shelf.books;
    return LedgerScreen(
      topBar: const LedgerTopBar(title: 'Books'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: LedgerSpacing.s32,
        children: [
          LedgerSection(
            head: LedgerHead(
              'Reading goal for 2026',
              note: '${shelf.finished} of ${shelf.goal} finished',
            ),
            child: LedgerGauge(
              ratio: (shelf.finished / shelf.goal).clamp(0.0, 1.0),
              tick: false,
              startLabel: LedgerFormat.plural(0, 'book'),
              endLabel: LedgerFormat.plural(shelf.goal, 'book'),
              semanticLabel: 'Reading goal',
            ),
          ),
          if (books.isEmpty)
            const LedgerEmptyState(
              title: 'No books yet',
              body: 'Books you add show here.',
            )
          else
            LedgerSection(
              head: LedgerHead(LedgerFormat.plural(books.length, 'book')),
              child: LedgerRows(
                children: [
                  for (final book in books)
                    LedgerSwipeActions(
                      key: ValueKey(book.id),
                      trailing: [
                        LedgerSwipeAction(
                          'Delete',
                          icon: LucideIcons.trash2,
                          tone: LedgerSwipeTone.destructive,
                          onPressed: () => deleteBook(context, book),
                        ),
                      ],
                      child: LedgerRow(
                        title: book.title,
                        subtitle: book.byline,
                        tag: book.status.mark,
                        // A page pushed on the Books place: the rail or the
                        // side bar stays beside it.
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (context) => BookPage(id: book.id),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
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
    void edit() => Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => LedgerScreen.form(
          topBar: const LedgerTopBar(title: 'Change book', backLabel: 'Book'),
          body: BookForm(
            saveLabel: 'Save changes',
            initial: book,
            onSaved: (changed) {
              ShelfScope.read(context).put(changed);
              Navigator.of(context).pop();
            },
          ),
        ),
      ),
    );
    // A record's page stands on the form's column, as its form does.
    return LedgerScreen.form(
      topBar: LedgerTopBar(title: book.title, backLabel: 'Books'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: LedgerSpacing.s32,
        children: [
          LedgerSection(
            head: const LedgerHead('Details'),
            child: LedgerRows(
              children: [
                LedgerKeyValue(
                  'Author',
                  book.author.isEmpty ? 'Not given' : book.author,
                ),
                LedgerKeyValue('Format', book.format.label),
                LedgerKeyValue('Status', book.status.label),
                LedgerKeyValue('Favourite', book.favourite ? 'Yes' : 'No'),
                LedgerKeyValue(
                  'Date started',
                  book.started == null
                      ? 'Not given'
                      : LedgerFormat.date(book.started!, showYear: true),
                ),
              ],
            ),
          ),
          LedgerButtonRow(
            children: [
              LedgerButton.filled(
                'Change book',
                icon: LucideIcons.pencil,
                expand: true,
                onPressed: edit,
              ),
              LedgerButton(
                'Delete book',
                icon: LucideIcons.trash2,
                expand: true,
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

/// Asks before deleting [book]: the dialog is popped with the answer. Says
/// so in a toast once it is gone; returns whether it went.
Future<bool> deleteBook(BuildContext context, Book book) async {
  final shelf = ShelfScope.read(context);
  final delete = await LedgerDialog.show(
    context,
    title: 'Delete “${book.title}”?',
    body: 'It comes off your list. You cannot undo this.',
    type: LedgerDialogType.destructive,
    confirmLabel: 'Delete book',
    cancelLabel: 'Keep it',
  );
  if (delete != true) return false;
  shelf.remove(book.id);
  if (context.mounted) LedgerToast.show(context, 'Deleted “${book.title}”');
  return true;
}

/// The Add place: a new book's answers.
class AddBookPage extends StatelessWidget {
  const AddBookPage({super.key, required this.onAdded});

  /// Called once the book is on the list.
  final VoidCallback onAdded;

  @override
  Widget build(BuildContext context) => LedgerScreen.form(
    topBar: const LedgerTopBar(title: 'Add a book'),
    body: BookForm(
      saveLabel: 'Save book',
      onSaved: (book) {
        ShelfScope.read(context).put(book);
        LedgerToast.show(context, 'Added “${book.title}”');
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
    spacing: LedgerSpacing.s24,
    children: [
      LedgerTextField(
        labelText: 'Title',
        controller: _title,
        focusNode: _titleFocus,
        errorText: _titleError,
        isRequired: true,
        textInputAction: TextInputAction.next,
        onChanged: (_) {
          if (_titleError != null) setState(() => _titleError = null);
        },
      ),
      LedgerTextField(
        labelText: 'Author',
        helperText: 'Optional',
        controller: _author,
      ),
      LedgerSelect<BookFormat>(
        labelText: 'Format',
        value: _format,
        items: [
          for (final format in BookFormat.values)
            LedgerSelectItem(value: format, label: format.label),
        ],
        onChanged: (format) => setState(() => _format = format),
      ),
      // Labelled as the fields are: a section's rule here would stand under
      // the select's line as a second one.
      LedgerField(
        labelText: 'Status',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final status in BookStatus.values)
              LedgerRadio<BookStatus>(
                value: status,
                groupValue: _status,
                label: status.label,
                onChanged: (status) =>
                    setState(() => _status = status ?? _status),
              ),
          ],
        ),
      ),
      LedgerToggleRow(
        title: 'Favourite',
        subtitle: 'Favourites are marked in your list.',
        value: _favourite,
        onChanged: (on) => setState(() => _favourite = on),
      ),
      LedgerDatePicker(
        labelText: 'Date started',
        value: _started,
        firstDate: DateTime(1900),
        lastDate: DateTime(2100),
        onChanged: (day) => setState(() => _started = day),
      ),
      LedgerButton.filled(widget.saveLabel, expand: true, onPressed: _save),
    ],
  );
}

/// The appearance, the palette and the year's goal.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final shelf = ShelfScope.of(context);
    return LedgerScreen.form(
      topBar: const LedgerTopBar(title: 'Settings'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: LedgerSpacing.s32,
        children: [
          LedgerField(
            labelText: 'Appearance',
            note: 'System follows your device.',
            child: LedgerToggleGroup<Appearance>(
              semanticLabel: 'Appearance',
              options: Appearance.values,
              selected: {shelf.appearance},
              labelOf: (appearance) => appearance.label,
              onSelectionChanged: (chosen) => shelf.appearance = chosen.first,
            ),
          ),
          // Ledger's six palettes, each by its colours as they show now and
          // its name; an app stores the id.
          LedgerSection(
            head: const LedgerHead('Colour', note: 'Seal and paper'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final palette in LedgerThemeData.palettes)
                  LedgerRadio<String>(
                    value: palette.id,
                    groupValue: shelf.palette.id,
                    label: palette.label,
                    leading: PaletteSwatch(palette: palette),
                    onChanged: (id) => shelf.palette = LedgerThemeData.palettes
                        .firstWhere((palette) => palette.id == id),
                  ),
              ],
            ),
          ),
          LedgerSlider(
            label: 'Books to finish this year',
            value: shelf.goal.toDouble(),
            min: 4,
            max: 52,
            divisions: 48,
            // The figure in the amount face, its word after it (the goal is
            // never one book).
            format: (goal) => LedgerFormat.count(goal.round()),
            unit: 'books',
            onChanged: (goal) => shelf.goal = goal.round(),
          ),
        ],
      ),
    );
  }
}

/// A palette's seal on its paper, as they show now (by day or by night),
/// beside its name: what the name stands for, seen.
class PaletteSwatch extends StatelessWidget {
  const PaletteSwatch({super.key, required this.palette});

  final RawNamedPalette palette;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final [seal, paper, ...] = palette.swatchesFor(t.brightness);
    return Container(
      width: 28,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: paper,
        borderRadius: BorderRadius.circular(t.shapeScheme.corners.small),
        border: Border.all(color: t.border),
      ),
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(color: seal, shape: BoxShape.circle),
      ),
    );
  }
}

// The app's state: the books, and how the reader likes the app.

enum BookStatus {
  toRead('To read'),
  reading('Reading'),
  done('Done');

  const BookStatus(this.label);

  final String label;

  /// Its mark in the list, a ringed word: in the green while it is read,
  /// in the faint ink while it waits and once it is done.
  Widget get mark => switch (this) {
    toRead => LedgerTag(label),
    reading => LedgerTag(label, tone: LedgerTagTone.unread),
    done => LedgerTag(label),
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
  RawNamedPalette _palette = LedgerThemeData.palettes.first;
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

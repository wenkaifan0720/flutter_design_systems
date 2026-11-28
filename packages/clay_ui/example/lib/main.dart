// Shelf, a reading list built on Clay: one app you can copy. ClayHost over
// MaterialApp (by day, by night or as the device is, in any of the six
// palettes, at the reader's text size), ClayScaffold.branches with three
// places (the dock along a phone's foot, the rail from 600 wide and the
// sidebar from 1024), each keeping its own pages; the list of books with a
// pushed page for each, a form that checks its answers, a dialog that asks
// before a book goes and a toast that brings it back, and the settings. The
// gallery, every component on a page of its own, is lib/gallery.dart:
// `flutter run -t lib/gallery.dart`.
import 'package:clay_ui/clay_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The face before the first frame, so the words never flash in another.
  await clayLoadFonts();
  runApp(ShelfApp(shelf: Shelf.sample()));
}

/// The app: Clay over the whole of it, in the reader's appearance, palette
/// and text size.
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
        theme: ThemeData(
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: clayPageTransitions,
          ),
        ),
        // Clay's own words in 30 languages, and Material's: material_ui
        // brings Flutter's translations, so no flutter_localizations.
        localizationsDelegates: const [
          RawWidgetsLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: RawWidgetsLocalizations.supportedLocales,
        builder: (context, child) {
          final media = MediaQuery.of(context);
          return MediaQuery(
            data: media.copyWith(
              textScaler: shelf.textSize.scale(media.textScaler),
            ),
            child: ClayHost(
              brightness: shelf.appearance.brightness,
              palette: shelf.palette,
              child: child!,
            ),
          );
        },
        home: const ShelfShell(),
      ),
    ),
  );
}

/// The app's three places. Each keeps its own pages: a book opened from
/// Books stands beside the rail or the sidebar, and back closes it.
class ShelfShell extends StatefulWidget {
  const ShelfShell({super.key});

  @override
  State<ShelfShell> createState() => _ShelfShellState();
}

class _ShelfShellState extends State<ShelfShell> {
  int _place = 0;

  @override
  Widget build(BuildContext context) => ClayScaffold.branches(
    destinations: const [
      ClayDestination(icon: LucideIcons.bookOpen, label: 'Books'),
      ClayDestination(icon: LucideIcons.plus, label: 'Add'),
      ClayDestination(icon: LucideIcons.settings, label: 'Settings'),
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

/// A page's column of parts, a list or a form, 24 apart: at most 640
/// wide, from the page's start, a line a reader can follow.
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
        spacing: ClaySpacing.large,
        children: children,
      ),
    ),
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
    return ClayScreen(
      topBar: const ClayTopBar(title: 'Books'),
      body: ShelfColumn(
        children: [
          ClayMeter(
            label: 'Reading goal for 2026',
            value: shelf.finished.clamp(0, shelf.goal).toDouble(),
            max: shelf.goal.toDouble(),
            valueText: '${shelf.finished} of ${shelf.goal} finished',
          ),
          if (books.isEmpty)
            const ClayStateView(
              state: ClayState.empty,
              icon: LucideIcons.bookOpen,
              title: 'No books yet',
              message: 'Books you add show here.',
            )
          else
            ClayGroup(
              header: books.length == 1 ? '1 book' : '${books.length} books',
              children: [
                for (final book in books)
                  ClayListTile(
                    key: ValueKey(book.id),
                    title: book.title,
                    subtitle: book.byline,
                    trailing: book.status.tag,
                    // A page pushed on the Books place: the rail or the
                    // sidebar stays beside it.
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
    final words = RawWidgetsLocalizations.of(context);
    void edit() => Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => BookFormPage(
          title: 'Change book',
          saveLabel: 'Save changes',
          initial: book,
          onSaved: (changed) {
            ShelfScope.read(context).put(changed);
            Navigator.of(context).pop();
          },
        ),
      ),
    );
    final keys = [
      ClayButton.filled(
        'Change book',
        icon: const Icon(LucideIcons.pencil),
        onPressed: edit,
      ),
      ClayButton(
        'Delete book',
        icon: const Icon(LucideIcons.trash2),
        isDestructiveAction: true,
        onPressed: () => deleteBook(context, book),
      ),
    ];
    return ClayScreen(
      topBar: ClayTopBar(
        title: book.title,
        leading: ClayTopBar.autoLeading(context),
      ),
      body: ShelfColumn(
        children: [
          ClayDescriptionList(
            entries: [
              ClayDescription(
                'Author',
                book.author.isEmpty ? 'Not given' : book.author,
              ),
              ClayDescription('Format', book.format.label),
              ClayDescription('Status', book.status.label),
              ClayDescription('Favourite', book.favourite ? 'Yes' : 'No'),
              ClayDescription(
                'Date started',
                book.started == null
                    ? 'Not given'
                    : words.formatMediumDate(book.started!),
              ),
            ],
          ),
          // On a phone the keys stand one over the other, each across the
          // column; wider, side by side.
          if (MediaQuery.sizeOf(context).width < ClayMetrics.railBreakpoint)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: ClaySpacing.medium,
              children: keys,
            )
          else
            Wrap(
              spacing: ClaySpacing.medium,
              runSpacing: ClaySpacing.medium,
              children: keys,
            ),
        ],
      ),
    );
  }
}

/// Asks before deleting [book]; once it is gone, closes its page and says
/// so in a toast whose Undo puts it back where it was.
Future<void> deleteBook(BuildContext context, Book book) async {
  final shelf = ShelfScope.read(context);
  final delete = await showClayDialog<bool>(
    context: context,
    builder: (context) => ClayDialog(
      title: 'Delete “${book.title}”?',
      content: const Text('It comes off your list.'),
      actions: [
        ClayDialogAction(
          label: 'Keep it',
          onPressed: () => Navigator.of(context).pop(false),
        ),
        ClayDialogAction(
          label: 'Delete book',
          isDefaultAction: true,
          isDestructiveAction: true,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    ),
  );
  if (delete != true || !context.mounted) return;
  final at = shelf.remove(book.id);
  showClayToast(
    context,
    'Deleted “${book.title}”',
    actionLabel: 'Undo',
    onAction: () => shelf.insert(at, book),
  );
  Navigator.of(context).pop();
}

/// The Add place: a new book's answers.
class AddBookPage extends StatelessWidget {
  const AddBookPage({super.key, required this.onAdded});

  /// Called once the book is on the list.
  final VoidCallback onAdded;

  @override
  Widget build(BuildContext context) => BookFormPage(
    title: 'Add a book',
    saveLabel: 'Save book',
    onSaved: (book) {
      ShelfScope.read(context).put(book);
      showClayToast(context, 'Added “${book.title}”');
      onAdded();
    },
  );
}

/// The answers about a book, on a page of their own, the save key at its
/// foot. Saving checks them: a missing title is said at the field, and the
/// focus goes to it.
class BookFormPage extends StatefulWidget {
  const BookFormPage({
    super.key,
    required this.title,
    required this.saveLabel,
    required this.onSaved,
    this.initial,
  });

  final String title;
  final String saveLabel;
  final ValueChanged<Book> onSaved;

  /// The book being changed; null adds one.
  final Book? initial;

  @override
  State<BookFormPage> createState() => _BookFormPageState();
}

class _BookFormPageState extends State<BookFormPage> {
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
    if (widget.initial == null) {
      _title.clear();
      _author.clear();
      setState(() {
        _format = BookFormat.paperback;
        _status = BookStatus.toRead;
        _favourite = false;
        _started = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final save = ClayButton.filled(widget.saveLabel, onPressed: _save);
    // On a phone the key stands fixed at the page's foot, in the thumb's
    // reach; from 600 wide it stands at the form's own foot, where the
    // form's column ends.
    final phone = MediaQuery.sizeOf(context).width < ClayMetrics.railBreakpoint;
    return ClayScreen(
      topBar: ClayTopBar(
        title: widget.title,
        leading: ClayTopBar.autoLeading(context),
      ),
      footer: phone ? save : null,
      body: ShelfColumn(
        children: [
          ClayTextField(
            labelText: 'Title',
            controller: _title,
            focusNode: _titleFocus,
            errorText: _titleError,
            textInputAction: TextInputAction.next,
            onChanged: (_) {
              if (_titleError != null) setState(() => _titleError = null);
            },
          ),
          ClayTextField(
            labelText: 'Author',
            helperText: 'Optional',
            controller: _author,
          ),
          ClaySelect<BookFormat>(
            labelText: 'Format',
            value: _format,
            items: [
              for (final format in BookFormat.values)
                ClaySelectItem(value: format, label: format.label),
            ],
            onChanged: (format) => setState(() => _format = format),
          ),
          ClayFormField(
            labelText: 'Status',
            child: ClaySegmentedButton<BookStatus>(
              expanded: true,
              segments: [
                for (final status in BookStatus.values)
                  ClaySegment(value: status, label: status.label),
              ],
              selected: _status,
              onChanged: (status) => setState(() => _status = status),
            ),
          ),
          ClayGroup(
            children: [
              ClayListTile(
                title: 'Favourite',
                subtitle: 'Favourites are marked in your list.',
                toggled: _favourite,
                trailing: ClaySwitch(
                  value: _favourite,
                  onChanged: (on) => setState(() => _favourite = on),
                ),
                onTap: () => setState(() => _favourite = !_favourite),
              ),
            ],
          ),
          ClayDatePicker(
            labelText: 'Date started',
            helperText: 'Optional',
            value: _started,
            firstDate: DateTime(1900),
            lastDate: DateTime(2100),
            onChanged: (day) => setState(() => _started = day),
          ),
          if (!phone)
            Align(alignment: AlignmentDirectional.centerEnd, child: save),
        ],
      ),
    );
  }
}

/// The appearance, the palette, the text size and the year's goal.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final shelf = ShelfScope.of(context);
    return ClayScreen(
      topBar: const ClayTopBar(title: 'Settings'),
      body: ShelfColumn(
        children: [
          ClayFormField(
            labelText: 'Appearance',
            helperText: 'System follows your device.',
            child: ClaySegmentedButton<Appearance>(
              expanded: true,
              segments: [
                for (final appearance in Appearance.values)
                  ClaySegment(value: appearance, label: appearance.label),
              ],
              selected: shelf.appearance,
              onChanged: (appearance) => shelf.appearance = appearance,
            ),
          ),
          // The six palettes, each by its colour as it shows now and its
          // name; an app stores the id. The label names the group.
          ClayFormField(
            labelText: 'Colour',
            mergeSemantics: false,
            child: ClayGroup(
              children: [
                for (final palette in ClayThemeData.palettes)
                  ClayListTile(
                    leading: PaletteSwatch(palette: palette),
                    title: palette.label,
                    selected: palette.id == shelf.palette.id,
                    showChevron: false,
                    onTap: () => shelf.palette = palette,
                  ),
              ],
            ),
          ),
          ClayFormField(
            labelText: 'Text size',
            helperText: 'On top of your device’s own.',
            child: ClaySegmentedButton<TextSize>(
              expanded: true,
              segments: [
                for (final size in TextSize.values)
                  ClaySegment(value: size, label: size.label),
              ],
              selected: shelf.textSize,
              onChanged: (size) => shelf.textSize = size,
            ),
          ),
          ClayFormField(
            labelText: 'Books to finish this year',
            helperText: '${shelf.goal} books',
            child: ClaySlider(
              value: shelf.goal.toDouble(),
              min: 4,
              max: 52,
              divisions: 48,
              // Said as a count, where a slider says a percentage by default.
              semanticFormatterCallback: (goal) => '${goal.round()} books',
              onChanged: (goal) => shelf.goal = goal.round(),
            ),
          ),
        ],
      ),
    );
  }
}

/// A palette's key colour as it shows now (by day or by night), beside its
/// name: what the name stands for, seen.
class PaletteSwatch extends StatelessWidget {
  const PaletteSwatch({super.key, required this.palette});

  final RawNamedPalette palette;

  @override
  Widget build(BuildContext context) {
    final colors = ClayTheme.of(context).colors;
    final [accent, ...] = palette.swatchesFor(colors.brightness);
    return SizedBox.square(
      dimension: 24,
      child: ClaySurface(
        face: ClayFace.raised(colors, color: accent, radius: 12),
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

  /// Its tag in the list: the accent's while it is read; plain while it
  /// waits and once it is done.
  Widget get tag => switch (this) {
    reading => ClayTag(label, tone: ClayTagTone.accent),
    toRead || done => ClayTag(label),
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

enum TextSize {
  standard('Standard', 1),
  large('Large', 1.25),
  larger('Larger', 1.5);

  const TextSize(this.label, this.factor);

  final String label;

  /// How much larger than the device's own size.
  final double factor;

  /// [device], the device's text scaling, made [factor] times larger.
  TextScaler scale(TextScaler device) =>
      factor == 1 ? device : TextScaler.linear(device.scale(16) / 16 * factor);
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

  /// Adds [book] at the top, or puts it in place of the book with its id.
  void put(Book book) {
    final at = _books.indexWhere((b) => b.id == book.id);
    if (at < 0) {
      _books.insert(0, book);
    } else {
      _books[at] = book;
    }
    notifyListeners();
  }

  /// Puts [book] back at [index], where it stood.
  void insert(int index, Book book) {
    _books.insert(index.clamp(0, _books.length), book);
    notifyListeners();
  }

  /// Takes the book with [id] off the list; returns where it stood.
  int remove(String id) {
    final at = _books.indexWhere((b) => b.id == id);
    if (at >= 0) _books.removeAt(at);
    notifyListeners();
    return at;
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
  RawNamedPalette _palette = ClayThemeData.palettes.first;
  set palette(RawNamedPalette value) {
    _palette = value;
    notifyListeners();
  }

  TextSize get textSize => _textSize;
  TextSize _textSize = TextSize.standard;
  set textSize(TextSize value) {
    _textSize = value;
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

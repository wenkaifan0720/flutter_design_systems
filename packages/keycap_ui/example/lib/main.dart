// Shelf: a reading list in Keycap, one file to copy as the start of an app. KeycapHost stands above the navigator
// (light, dark or the platform's, in one of the six colourways); KeycapScaffold.branches holds three places; the list
// pushes a book's page, which asks before it removes it; the form checks its fields and takes a date; settings choose
// the appearance and the colourway. Run the gallery of every part with `flutter run -t lib/gallery.dart`.
import 'package:keycap_ui/keycap_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The faces before the first frame, so the words never show in a fallback face.
  await keycapLoadFonts();
  runApp(const ShelfApp());
}

/// A book on the shelf.
@immutable
class Book {
  /// A book called [title], by [author], begun on [started] (null: not yet).
  const Book(this.title, this.author, {this.started, this.finished = false});

  /// Its title.
  final String title;

  /// Who wrote it.
  final String author;

  /// When reading began; null while it waits.
  final DateTime? started;

  /// Whether it has been read to the end.
  final bool finished;
}

/// The app: its appearance, its colourway and the shelf, above the three places.
class ShelfApp extends StatefulWidget {
  /// Creates the app.
  const ShelfApp({super.key});

  @override
  State<ShelfApp> createState() => _ShelfAppState();
}

class _ShelfAppState extends State<ShelfApp> {
  ThemeMode mode = ThemeMode.system;
  RawNamedPalette palette = KeycapThemeData.palettes.first;
  int place = 0;
  final books = <Book>[
    Book(
      'Piranesi',
      'Susanna Clarke',
      started: DateTime(2026, 10, 2),
      finished: true,
    ),
    Book(
      'The Left Hand of Darkness',
      'Ursula K. Le Guin',
      started: DateTime(2026, 11, 9),
    ),
    const Book('Stoner', 'John Williams'),
  ];

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Shelf',
    debugShowCheckedModeBanner: false,
    // ui_core's 30 languages: a device in one of them hears the parts' shared words (Cancel, Close, Today) in it, and
    // in Arabic or Hebrew the app reads right to left. material_ui gives Material's own words.
    supportedLocales: RawWidgetsLocalizations.supportedLocales,
    localizationsDelegates: const [
      RawWidgetsLocalizations.delegate,
      ...GlobalMaterialLocalizations.delegates,
    ],
    // One mount for the whole app: the theme by day and by night in the colourway, and the toasts.
    builder: (context, child) => KeycapHost(
      palette: palette,
      brightness: switch (mode) {
        ThemeMode.light => Brightness.light,
        ThemeMode.dark => Brightness.dark,
        ThemeMode.system => null,
      },
      child: child!,
    ),
    home: KeycapScaffold.branches(
      header: const ShelfName(),
      destinations: const [
        KeycapDestination(icon: LucideIcons.bookOpen, label: 'Books'),
        KeycapDestination(icon: LucideIcons.plus, label: 'Add a book'),
        KeycapDestination(icon: LucideIcons.settings, label: 'Settings'),
      ],
      selectedIndex: place,
      onDestinationSelected: (index) => setState(() => place = index),
      branches: [
        (context) => BooksPage(
          books: books,
          onRemove: (book) => setState(() => books.remove(book)),
        ),
        (context) =>
            AddBookPage(onAdd: (book) => setState(() => books.add(book))),
        (context) => SettingsPage(
          mode: mode,
          palette: palette,
          onMode: (next) => setState(() => mode = next),
          onPalette: (next) => setState(() => palette = next),
        ),
      ],
    ),
  );
}

/// The app's name at the head of the side column on a desk.
class ShelfName extends StatelessWidget {
  /// The name.
  const ShelfName({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    return Semantics(
      header: true,
      child: Text(
        'Shelf',
        style: theme.textTheme.title.copyWith(color: theme.colors.ink),
      ),
    );
  }
}

/// The widest a page's content stands here: on a desk a list, a book's page or a form reads in one column at the
/// page's start (a form's measure) rather than across the window; on a phone it is the page's width.
const double pageColumn = 720;

/// The shelf: a row a book, each opening its page.
class BooksPage extends StatelessWidget {
  /// The shelf of [books]; [onRemove] takes one off.
  const BooksPage({super.key, required this.books, required this.onRemove});

  /// The books, in order.
  final List<Book> books;

  /// Takes a book off the shelf.
  final ValueChanged<Book> onRemove;

  @override
  Widget build(BuildContext context) => KeycapScreen(
    topBar: const KeycapAppBar(title: 'Books'),
    maxWidth: pageColumn,
    body: KeycapListGroup(
      children: [
        for (final book in books)
          KeycapListTile(
            title: book.title,
            subtitle: book.author,
            // A row's name reads its tag: "Piranesi, Susanna Clarke, Read".
            trailing: StatusTag(book),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => BookPage(book: book, onRemove: onRemove),
              ),
            ),
          ),
      ],
    ),
  );
}

/// One book's page, pushed over the shelf: the way back is in its bar.
class BookPage extends StatelessWidget {
  /// The page of [book]; [onRemove] takes it off the shelf.
  const BookPage({super.key, required this.book, required this.onRemove});

  /// The book shown.
  final Book book;

  /// Takes the book off the shelf.
  final ValueChanged<Book> onRemove;

  Future<void> _remove(BuildContext context) async {
    // A dialog pops with the answer: true to remove, false or null (dismissed) to keep.
    final remove = await showKeycapDialog<bool>(
      context: context,
      builder: (context) => KeycapDialog(
        title: 'Remove ${book.title}?',
        content: const Text('It leaves your shelf. You can add it again.'),
        actions: [
          KeycapButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep'),
          ),
          KeycapButton.accent(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (remove != true || !context.mounted) return;
    onRemove(book);
    Navigator.of(context).pop();
    showKeycapToast(context, 'Removed ${book.title}');
  }

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final started = book.started;
    return KeycapScreen(
      topBar: KeycapAppBar(
        title: book.title,
        onBack: () => Navigator.of(context).pop(),
      ),
      maxWidth: pageColumn,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: KeycapSpacing.large,
        children: [
          KeycapCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: KeycapSpacing.small,
              children: [
                Text(book.author, style: theme.textTheme.heading),
                Text(
                  started == null
                      ? 'Not started yet'
                      : 'Started ${KeycapFormat.date(context, started)}',
                  style: theme.textTheme.body,
                ),
                StatusTag(book),
              ],
            ),
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: KeycapButton(
              isDestructiveAction: true,
              icon: const Icon(LucideIcons.trash2),
              onPressed: () => _remove(context),
              child: const Text('Remove from the shelf'),
            ),
          ),
        ],
      ),
    );
  }
}

/// A form for a new book: its fields checked on Save, the first wrong one focused; a saved book clears it for the next.
class AddBookPage extends StatefulWidget {
  /// The form; [onAdd] takes the new book.
  const AddBookPage({super.key, required this.onAdd});

  /// Takes the new book.
  final ValueChanged<Book> onAdd;

  @override
  State<AddBookPage> createState() => _AddBookPageState();
}

class _AddBookPageState extends State<AddBookPage> {
  final form = GlobalKey<RawFormState>();
  final title = TextEditingController(), author = TextEditingController();
  DateTime? started;

  @override
  void dispose() {
    title.dispose();
    author.dispose();
    super.dispose();
  }

  void _save() {
    widget.onAdd(Book(title.text.trim(), author.text.trim(), started: started));
    showKeycapToast(context, 'Added ${title.text.trim()}');
    form.currentState!.reset();
    title.clear();
    author.clear();
    setState(() => started = null);
  }

  @override
  Widget build(BuildContext context) => KeycapScreen(
    topBar: const KeycapAppBar(title: 'Add a book'),
    maxWidth: pageColumn,
    // The foot's key stands on the form's column, at its end on a desk.
    footer: KeycapButton.accent(
      onPressed: () => form.currentState!.submit(),
      child: const Text('Save'),
    ),
    body: RawForm(
      key: form,
      onSubmit: _save,
      // Each field brings its label and its help or error: they stack in one column.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: KeycapSpacing.regular,
        children: [
          KeycapTextField(
            labelText: 'Title',
            controller: title,
            textInputAction: TextInputAction.next,
            validator: (value) =>
                (value ?? '').trim().isEmpty ? 'Enter the title' : null,
          ),
          KeycapTextField(
            labelText: 'Author',
            controller: author,
            validator: (value) =>
                (value ?? '').trim().isEmpty ? 'Enter who wrote it' : null,
          ),
          KeycapDatePicker(
            labelText: 'Started',
            hintText: 'Not yet',
            value: started,
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
            onChanged: (day) => setState(() => started = day),
          ),
        ],
      ),
    ),
  );
}

/// Settings: the appearance (the platform's, light or dark) and the colourway, one of Keycap's six.
class SettingsPage extends StatelessWidget {
  /// The settings as they stand, and what changes them.
  const SettingsPage({
    super.key,
    required this.mode,
    required this.palette,
    required this.onMode,
    required this.onPalette,
  });

  /// The appearance chosen.
  final ThemeMode mode;

  /// The colourway chosen.
  final RawNamedPalette palette;

  /// Chooses an appearance.
  final ValueChanged<ThemeMode> onMode;

  /// Chooses a colourway.
  final ValueChanged<RawNamedPalette> onPalette;

  @override
  Widget build(BuildContext context) => KeycapScreen(
    topBar: const KeycapAppBar(title: 'Settings'),
    maxWidth: pageColumn,
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: KeycapSpacing.large,
      children: [
        // A row of keys has no label of its own: KeycapField gives it one, read as the group's name.
        KeycapField(
          labelText: 'Appearance',
          child: KeycapSegmentedButton<ThemeMode>(
            expand: true,
            segments: const [
              KeycapSegment(value: ThemeMode.system, label: 'System'),
              KeycapSegment(value: ThemeMode.light, label: 'Light'),
              KeycapSegment(value: ThemeMode.dark, label: 'Dark'),
            ],
            selected: {mode},
            onSelectionChanged: (chosen) => onMode(chosen.first),
          ),
        ),
        // A row a colourway: its keys' colours, by day or by night, beside its name; the chosen one latched.
        KeycapListGroup(
          header: 'Colourway',
          children: [
            for (final option in KeycapThemeData.palettes)
              KeycapListTile(
                leading: Swatches(
                  option.swatchesFor(KeycapTheme.of(context).colors.brightness),
                ),
                title: option.label,
                selected: option.id == palette.id,
                showChevron: false,
                onTap: () => onPalette(option),
              ),
          ],
        ),
      ],
    ),
  );
}

/// Where a book stands: read, being read, or waiting.
class StatusTag extends StatelessWidget {
  /// The tag for [book].
  const StatusTag(this.book, {super.key});

  /// The book.
  final Book book;

  @override
  Widget build(BuildContext context) => book.finished
      ? const KeycapTag('Read', tone: KeycapTone.success)
      : book.started != null
      ? const KeycapTag('Reading', tone: KeycapTone.info)
      : const KeycapTag('To read');
}

/// A colourway's keys side by side in one square: its accent, a modifier and an alpha, ruled in the row's ink.
class Swatches extends StatelessWidget {
  /// A square of [colors].
  const Swatches(this.colors, {super.key});

  /// The colourway's swatches, the accent first.
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    final glyph = IconTheme.of(context);
    final side = glyph.size ?? 24;
    final corner = BorderRadius.circular(side / 4);
    // A glyph's square: the row's leading slot centres what it holds.
    return SizedBox.square(
      dimension: side,
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: corner,
          border: Border.all(
            color: glyph.color ?? KeycapTheme.of(context).colors.ink,
          ),
        ),
        child: ClipRRect(
          borderRadius: corner,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final color in colors)
                Expanded(child: ColoredBox(color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

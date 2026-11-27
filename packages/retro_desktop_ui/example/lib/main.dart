// Shelf: a reading list in Retro Desktop, one file to copy as the start of an app. RetroDesktopHost stands above the
// navigator (light, dark or the platform's, in one of the six palettes); RetroDesktopAppShell.branches holds three
// places, a strip at a phone's foot and the menu bar on a desk; the list pushes a book's page, which asks before it
// removes it; the form checks its fields and takes a date; settings choose the appearance and the palette. Run the
// gallery of every part with `flutter run -t lib/gallery.dart`.
import 'package:material_ui/material_ui.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The faces before the first frame, so the words never show in a fallback face.
  await retroDesktopLoadFonts();
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

/// The app: its appearance, its palette and the shelf, above the three places.
class ShelfApp extends StatefulWidget {
  /// Creates the app.
  const ShelfApp({super.key});

  @override
  State<ShelfApp> createState() => _ShelfAppState();
}

class _ShelfAppState extends State<ShelfApp> {
  ThemeMode mode = ThemeMode.system;
  RawNamedPalette palette = RetroDesktopThemeData.palettes.first;
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
    // One mount for the whole app: the theme by day and by night in the palette, and the notices.
    builder: (context, child) => RetroDesktopHost(
      palette: palette,
      brightness: switch (mode) {
        ThemeMode.light => Brightness.light,
        ThemeMode.dark => Brightness.dark,
        ThemeMode.system => null,
      },
      child: child!,
    ),
    home: RetroDesktopAppShell.branches(
      brand: 'Shelf',
      destinations: const [
        RetroDesktopNavItem(
          label: 'Books',
          short: 'Books',
          icon: RetroDesktopGlyphs.book,
        ),
        RetroDesktopNavItem(
          label: 'Add a book',
          short: 'Add',
          icon: RetroDesktopGlyphs.add,
        ),
        RetroDesktopNavItem(
          label: 'Settings',
          short: 'Settings',
          icon: RetroDesktopGlyphs.settings,
        ),
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

/// The shelf: a row a book, each opening its page.
class BooksPage extends StatelessWidget {
  /// The shelf of [books]; [onRemove] takes one off.
  const BooksPage({super.key, required this.books, required this.onRemove});

  /// The books, in order.
  final List<Book> books;

  /// Takes a book off the shelf.
  final ValueChanged<Book> onRemove;

  @override
  Widget build(BuildContext context) => RetroDesktopScaffold(
    appBar: const RetroDesktopAppBar(title: 'Books'),
    body: RetroDesktopListSection(
      children: [
        for (final (index, book) in books.indexed)
          RetroDesktopListTile(
            isFirst: index == 0,
            title: book.title,
            subtitle: book.author,
            // A row's name reads its tag: "Piranesi, Susanna Clarke, Read".
            trailing: statusTag(book),
            onPressed: () => Navigator.of(context).push(
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
    final remove = await showRetroDesktopDialog<bool>(
      context,
      builder: (context) => RetroDesktopDialog(
        title: 'Remove ${book.title}?',
        message: 'It leaves your shelf. You can add it again.',
        actions: const [
          RetroDesktopDialogAction('Keep', value: false),
          RetroDesktopDialogAction(
            'Remove',
            value: true,
            isDestructiveAction: true,
          ),
        ],
      ),
    );
    if (remove != true || !context.mounted) return;
    onRemove(book);
    Navigator.of(context).pop();
    showRetroDesktopSnackBar(context, 'Removed ${book.title}');
  }

  @override
  Widget build(BuildContext context) {
    final started = book.started;
    return RetroDesktopScaffold(
      appBar: RetroDesktopAppBar(title: book.title),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: RetroDesktopSpacing.s16,
        children: [
          RetroDesktopCard(
            title: book.author,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: RetroDesktopSpacing.s8,
              children: [
                Text(
                  started == null
                      ? 'Not started yet'
                      : 'Started ${RetroDesktopFormat.mediumDate(context, started)}',
                ),
                statusTag(book),
              ],
            ),
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: RetroDesktopButton(
              'Remove book',
              icon: RetroDesktopGlyphs.delete,
              isDestructiveAction: true,
              onPressed: () => _remove(context),
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
    showRetroDesktopSnackBar(
      context,
      'Added ${title.text.trim()}',
      tone: RetroDesktopTone.success,
    );
    form.currentState!.reset();
    title.clear();
    author.clear();
    setState(() => started = null);
  }

  @override
  Widget build(BuildContext context) => RetroDesktopScaffold(
    appBar: const RetroDesktopAppBar(title: 'Add a book'),
    // The foot's default button ends where the page's column ends.
    footer: RetroDesktopButton(
      'Save',
      isDefaultAction: true,
      onPressed: () => form.currentState!.submit(),
    ),
    body: RawForm(
      key: form,
      onSubmit: _save,
      // Each field brings its label and its help or error: they stack in one column.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: RetroDesktopSpacing.s16,
        children: [
          RetroDesktopTextField(
            labelText: 'Title',
            controller: title,
            textInputAction: TextInputAction.next,
            validator: (value) =>
                (value ?? '').trim().isEmpty ? 'Enter the title' : null,
          ),
          RetroDesktopTextField(
            labelText: 'Author',
            controller: author,
            validator: (value) =>
                (value ?? '').trim().isEmpty ? 'Enter who wrote it' : null,
          ),
          RetroDesktopDateField(
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

/// Settings: the appearance (the platform's, light or dark) and the palette, one of Retro Desktop's six.
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

  /// The palette chosen.
  final RawNamedPalette palette;

  /// Chooses an appearance.
  final ValueChanged<ThemeMode> onMode;

  /// Chooses a palette.
  final ValueChanged<RawNamedPalette> onPalette;

  @override
  Widget build(BuildContext context) => RetroDesktopScaffold(
    appBar: const RetroDesktopAppBar(title: 'Settings'),
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: RetroDesktopSpacing.s24,
      children: [
        RetroDesktopSegmentedButton<ThemeMode>(
          label: 'Appearance',
          segments: const [
            RetroDesktopButtonSegment(ThemeMode.system, 'System'),
            RetroDesktopButtonSegment(ThemeMode.light, 'Light'),
            RetroDesktopButtonSegment(ThemeMode.dark, 'Dark'),
          ],
          value: mode,
          onChanged: onMode,
        ),
        // A row a palette: its colours, by day or by night, beside its name; the chosen one selected.
        RetroDesktopListSection(
          title: 'Palette',
          children: [
            for (final (index, option)
                in RetroDesktopThemeData.palettes.indexed)
              RetroDesktopListTile(
                isFirst: index == 0,
                leading: Swatches(
                  option.swatchesFor(
                    RetroDesktopTheme.of(context).colors.brightness,
                  ),
                ),
                title: option.label,
                selected: option.id == palette.id,
                onPressed: () => onPalette(option),
              ),
          ],
        ),
      ],
    ),
  );
}

/// Where a book stands: read, being read, or waiting, its glyph saying it as well as its words. A `RetroDesktopTag`
/// itself, not a widget around one, so a row takes it for a tag and reads its words in the row's name.
RetroDesktopTag statusTag(Book book) => book.finished
    ? const RetroDesktopTag('Read', icon: RetroDesktopGlyphs.check)
    : book.started != null
    ? const RetroDesktopTag('Reading', icon: RetroDesktopGlyphs.book)
    : const RetroDesktopTag('To read', icon: RetroDesktopGlyphs.clock);

/// A palette's colours side by side in one square, ruled in the row's ink.
class Swatches extends StatelessWidget {
  /// A square of [colors].
  const Swatches(this.colors, {super.key});

  /// The palette's swatches, the most telling first.
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    final glyph = IconTheme.of(context);
    final side = glyph.size ?? 16;
    return SizedBox.square(
      dimension: side,
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          border: Border.all(
            color: glyph.color ?? RetroDesktopTheme.of(context).colors.text,
          ),
        ),
        // Colours have no reading direction: the stripes stand in one order in every language.
        child: Row(
          textDirection: TextDirection.ltr,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final color in colors)
              Expanded(child: ColoredBox(color: color)),
          ],
        ),
      ),
    );
  }
}

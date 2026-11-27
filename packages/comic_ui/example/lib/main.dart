// Shelf: a reading list in Comic, one file to copy as the start of an app. ComicHost stands above the navigator
// (light, dark or the platform's, in one of the six palettes); ComicAppShell holds three places; the list pushes a
// book's page, which asks before it removes it; the form checks its fields and takes a date; settings choose the
// appearance and the palette. Run the gallery of every part with `flutter run -t lib/gallery.dart`.
import 'package:material_ui/material_ui.dart';
import 'package:comic_ui/comic_ui.dart';

void main() => runApp(const ShelfApp());

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
  RawNamedPalette palette = ComicThemeData.palettes.first;
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
    // in Arabic or Hebrew the app reads right to left. flutter_localizations gives Material's own words.
    supportedLocales: RawWidgetsLocalizations.supportedLocales,
    localizationsDelegates: const [
      RawWidgetsLocalizations.delegate,
      ComicLocalizations.delegate,
      ...GlobalMaterialLocalizations.delegates,
    ],
    // One mount for the whole app: the theme by day and by night, the palette, the page's ground and the toasts.
    builder: (context, child) => ComicHost(
      palette: palette,
      brightness: switch (mode) {
        ThemeMode.light => Brightness.light,
        ThemeMode.dark => Brightness.dark,
        ThemeMode.system => null,
      },
      child: child!,
    ),
    home: ComicAppShell.branches(
      brand: 'Shelf',
      destinations: const [
        ComicNavItem(label: 'Books', short: 'Books', icon: ComicGlyphs.book),
        ComicNavItem(label: 'Add a book', short: 'Add', icon: ComicGlyphs.add),
        ComicNavItem(
          label: 'Settings',
          short: 'Settings',
          icon: ComicGlyphs.settings,
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
  Widget build(BuildContext context) => ComicScaffold(
    topBar: const ComicAppBar(title: 'Books'),
    body: PageColumn(
      child: ComicListSection(
        children: [
          for (final (index, book) in books.indexed)
            ComicListTile(
              isFirst: index == 0,
              title: book.title,
              subtitle: book.author,
              // A row's name reads its tag: "Piranesi, Susanna Clarke, Read".
              trailing: statusTag(book),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) =>
                      BookPage(book: book, onRemove: onRemove),
                ),
              ),
            ),
        ],
      ),
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
    final remove = await showComicDialog<bool>(
      context,
      builder: (context) => ComicDialog(
        title: 'Remove ${book.title}?',
        message: 'It leaves your shelf. You can add it again.',
        actions: [
          ComicButton(
            'Keep',
            onPressed: () => Navigator.of(context).pop(false),
          ),
          ComicButton.filled(
            'Remove',
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    if (remove != true || !context.mounted) return;
    onRemove(book);
    Navigator.of(context).pop();
    showComicToast(context, 'Removed ${book.title}');
  }

  @override
  Widget build(BuildContext context) {
    final started = book.started;
    return ComicScaffold(
      topBar: ComicAppBar(title: book.title),
      body: PageColumn(
        child: ComicColumn(
          gap: ComicSpace.wide,
          children: [
            ComicPanel(
              caption: book.author,
              // The status stands at the line's end, as it does in the book's row.
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      started == null
                          ? 'Not started yet'
                          : 'Started ${ComicFormat.date(started)}',
                    ),
                  ),
                  const SizedBox(width: ComicSpace.close),
                  statusTag(book),
                ],
              ),
            ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: ComicButton(
                'Remove from the shelf',
                icon: ComicGlyphs.delete,
                isDestructiveAction: true,
                onPressed: () => _remove(context),
              ),
            ),
          ],
        ),
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

  @override
  Widget build(BuildContext context) => ComicScaffold(
    topBar: const ComicAppBar(title: 'Add a book'),
    body: PageColumn(
      child: RawForm(
        key: form,
        onSubmit: () {
          widget.onAdd(
            Book(title.text.trim(), author.text.trim(), started: started),
          );
          showComicToast(
            context,
            'Added ${title.text.trim()}',
            tone: ComicTone.success,
          );
          form.currentState!.reset();
          title.clear();
          author.clear();
          setState(() => started = null);
        },
        // Fields down a form keep one rhythm: ComicSpace.wide between them.
        child: ComicColumn(
          gap: ComicSpace.wide,
          children: [
            ComicTextField(
              labelText: 'Title',
              controller: title,
              textInputAction: TextInputAction.next,
              validator: (value) =>
                  (value ?? '').trim().isEmpty ? 'Enter the title' : null,
            ),
            ComicTextField(
              labelText: 'Author',
              controller: author,
              validator: (value) =>
                  (value ?? '').trim().isEmpty ? 'Enter who wrote it' : null,
            ),
            ComicDateField(
              labelText: 'Started',
              hintText: 'Not yet',
              value: started,
              lastDate: DateTime.now(),
              onChanged: (day) => setState(() => started = day),
            ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: ComicButton.filled(
                'Save',
                onPressed: () => form.currentState!.submit(),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Settings: the appearance (the platform's, light or dark) and the palette, one of Comic's six print runs.
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
  Widget build(BuildContext context) => ComicScaffold(
    topBar: const ComicAppBar(title: 'Settings'),
    body: ComicColumn(
      gap: ComicSpace.wide,
      children: [
        ComicFormField(
          'Appearance',
          child: ComicSegmentedButton<ThemeMode>(
            segments: const [
              ComicButtonSegment(ThemeMode.system, 'System'),
              ComicButtonSegment(ThemeMode.light, 'Light'),
              ComicButtonSegment(ThemeMode.dark, 'Dark'),
            ],
            value: mode,
            onChanged: onMode,
          ),
        ),
        ComicRadioGroup<RawNamedPalette>(
          labelText: 'Palette',
          options: [
            // Each palette's colours, by day or by night, beside its name.
            for (final option in ComicThemeData.palettes)
              ComicRadio(
                option,
                option.label,
                leading: Swatches(
                  option.swatchesFor(ComicTheme.of(context).brightness),
                ),
              ),
          ],
          groupValue: palette,
          onChanged: onPalette,
        ),
      ],
    ),
  );
}

/// A palette's colours side by side in one square, ruled in the words' ink.
class Swatches extends StatelessWidget {
  /// A square of [colors].
  const Swatches(this.colors, {super.key});

  /// The palette's swatches, the most telling first.
  final List<Color> colors;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 24,
    child: DecoratedBox(
      position: DecorationPosition.foreground,
      // Square, inked like the panels around it.
      decoration: BoxDecoration(
        border: Border.all(color: ComicTheme.of(context).colors.text, width: 2),
      ),
      // Colours have no reading direction: a palette's stripes stand in one order in every language.
      child: Row(
        textDirection: TextDirection.ltr,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final color in colors) Expanded(child: ColoredBox(color: color)),
        ],
      ),
    ),
  );
}

/// Where a book stands: read, being read, or waiting. A `ComicTag` itself, not a widget around one, so a row takes it
/// for a tag and reads its word in the row's name.
ComicTag statusTag(Book book) => book.finished
    ? const ComicTag('Read', tone: ComicSpeaker.fact)
    : book.started != null
    ? const ComicTag('Reading', tone: ComicSpeaker.currentUser)
    : const ComicTag('To read');

/// A page's column: on a desk a list, a book's page or a form reads in one column at the page's start, at most 720 wide
/// (a form's measure), rather than across the window; on a phone it is the page's width.
class PageColumn extends StatelessWidget {
  /// Holds [child] to the column.
  const PageColumn({super.key, required this.child});

  /// The page's content.
  final Widget child;

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.topStart,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 720),
      child: child,
    ),
  );
}

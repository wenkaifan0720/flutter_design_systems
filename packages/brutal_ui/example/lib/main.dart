// Shelf: a reading list in Brutal, one file to copy as the start of an app. BrutalHost stands above the navigator
// (light, dark or the platform's, in one of the six palettes); BrutalAppShell holds three places; the list pushes a
// book's page, which asks before it removes it; the form checks its fields and takes a date; settings choose the
// appearance and the palette. Run the gallery of every part with `flutter run -t lib/gallery.dart`.
import 'package:brutal_ui/brutal_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Space Grotesk before the first frame, so the words never show in a fallback face.
  await brutalLoadFonts();
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
  RawNamedPalette palette = BrutalThemeData.palettes.first;
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
    // One mount for the whole app: the theme by day and by night, the palette, the page's ground and the toasts.
    builder: (context, child) => BrutalHost(
      palette: palette,
      brightness: switch (mode) {
        ThemeMode.light => Brightness.light,
        ThemeMode.dark => Brightness.dark,
        ThemeMode.system => null,
      },
      child: child!,
    ),
    home: BrutalAppShell.branches(
      brand: 'Shelf',
      tabs: const [
        BrutalTab(LucideIcons.bookOpen, 'Books'),
        BrutalTab(LucideIcons.plus, 'Add a book'),
        BrutalTab(LucideIcons.settings, 'Settings'),
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
  Widget build(BuildContext context) => BrutalScreen(
    topBar: const BrutalAppBar(title: 'Books'),
    body: PageColumn(
      child: BrutalListGroup(
        children: [
          for (final book in books)
            BrutalListTile(
              title: book.title,
              subtitle: book.author,
              // A row's name reads its tag: "Piranesi, Susanna Clarke, Read".
              trailing: StatusTag(book),
              onTap: () => Navigator.of(context).push(
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
    final remove = await showBrutalDialog<bool>(
      context: context,
      builder: (context) => BrutalDialog(
        title: 'Remove ${book.title}?',
        content: const Text('It leaves your shelf. You can add it again.'),
        actions: [
          BrutalDialogAction(
            label: 'Keep',
            onPressed: () => Navigator.of(context).pop(false),
          ),
          BrutalDialogAction(
            label: 'Remove',
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    if (remove != true || !context.mounted) return;
    onRemove(book);
    Navigator.of(context).pop();
    showBrutalToast(context, 'Removed ${book.title}');
  }

  @override
  Widget build(BuildContext context) {
    final started = book.started;
    return BrutalScreen(
      topBar: BrutalAppBar(
        title: book.title,
        leading: BrutalAppBar.autoLeading(context),
      ),
      body: PageColumn(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: BrutalSpacing.large,
          children: [
            BrutalBlock(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: BrutalSpacing.small,
                children: [
                  Text(
                    book.author,
                    style: BrutalTheme.of(context).textTheme.title,
                  ),
                  Text(
                    started == null
                        ? 'Not started yet'
                        : 'Started ${RawWidgetsLocalizations.of(context).formatMediumDate(started)}',
                  ),
                  StatusTag(book),
                ],
              ),
            ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: BrutalButton(
                'Remove from the shelf',
                icon: const Icon(LucideIcons.trash2),
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
  Widget build(BuildContext context) => BrutalScreen(
    topBar: const BrutalAppBar(title: 'Add a book'),
    body: PageColumn(
      child: RawForm(
        key: form,
        onSubmit: () {
          widget.onAdd(
            Book(title.text.trim(), author.text.trim(), started: started),
          );
          showBrutalToast(context, 'Added ${title.text.trim()}');
          form.currentState!.reset();
          title.clear();
          author.clear();
          setState(() => started = null);
        },
        // Fields down a form keep one rhythm: BrutalSpacing.large between them.
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: BrutalSpacing.large,
          children: [
            BrutalTextField(
              labelText: 'Title',
              controller: title,
              textInputAction: TextInputAction.next,
              validator: (value) =>
                  (value ?? '').trim().isEmpty ? 'Enter the title' : null,
            ),
            BrutalTextField(
              labelText: 'Author',
              controller: author,
              validator: (value) =>
                  (value ?? '').trim().isEmpty ? 'Enter who wrote it' : null,
            ),
            BrutalDatePicker(
              labelText: 'Started',
              hintText: 'Not yet',
              value: started,
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
              onChanged: (day) => setState(() => started = day),
            ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: BrutalButton.filled(
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

/// Settings: the appearance (the platform's, light or dark) and the palette, one of Brutal's six.
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
  Widget build(BuildContext context) => BrutalScreen(
    topBar: const BrutalAppBar(title: 'Settings'),
    body: PageColumn(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: BrutalSpacing.large,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const BrutalFieldLabel('Appearance'),
              // It spans the column, as the select under it does.
              BrutalSegmentedButton<ThemeMode>(
                semanticLabel: 'Appearance',
                expand: true,
                segments: const [
                  BrutalSegment(value: ThemeMode.system, label: 'System'),
                  BrutalSegment(value: ThemeMode.light, label: 'Light'),
                  BrutalSegment(value: ThemeMode.dark, label: 'Dark'),
                ],
                value: mode,
                onChanged: onMode,
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const BrutalFieldLabel('Palette'),
              // A row a palette: its colours, by day or by night, beside its name; the chosen one inked.
              BrutalListGroup(
                children: [
                  for (final option in BrutalThemeData.palettes)
                    BrutalListTile(
                      leading: Swatches(
                        option.swatchesFor(
                          BrutalTheme.of(context).colors.brightness,
                        ),
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
        ],
      ),
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
      ? const BrutalTag('Read', tone: BrutalTagTone.strong)
      : book.started != null
      ? const BrutalTag('Reading', tone: BrutalTagTone.signal)
      : const BrutalTag('To read');
}

/// A palette's colours side by side in one square, ruled in the row's ink (paper on the chosen, inked row).
class Swatches extends StatelessWidget {
  /// A square of [colors].
  const Swatches(this.colors, {super.key});

  /// The palette's swatches, the most telling first.
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    final glyph = IconTheme.of(context);
    // A glyph's square: the row's leading slot centres what it holds.
    return SizedBox.square(
      dimension: glyph.size ?? 24,
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          border: Border.all(color: glyph.color!, width: 2),
        ),
        child: Row(
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

// Takes: a small podcast recorder's episode list on Studio, the whole app in
// one file. The host over the navigator (light, dark or the platform's, and
// the toasts), the shell with three places, a list with a pushed detail, a
// form with validation and a date, a dialog popped with its answer, and
// settings with the six palettes. Copy it, rename it, and grow it.
import 'package:material_ui/material_ui.dart';
import 'package:studio_ui/studio_ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await studioLoadFonts(); // the bundled faces, before the first frame
  runApp(TakesApp());
}

/// Every screen's measure: on a wide window each page (the list, an episode,
/// the form, settings) stands in the same centred column, so moving between
/// them keeps the bar's back button and the content where they were.
const double pageMeasure = 720;

// ── The data ────────────────────────────────────────────────────────────────

enum Status {
  draft('Draft', StudioTagTone.plain),
  editing('Editing', StudioTagTone.lit),
  published('Published', StudioTagTone.plain);

  const Status(this.label, this.tone);

  final String label;
  final StudioTagTone tone;
}

class Episode {
  Episode({
    required this.title,
    required this.show,
    this.status = Status.draft,
    this.recorded,
    this.explicit = false,
  });

  String title;
  String show;
  Status status;
  DateTime? recorded;
  bool explicit;
}

/// The episodes, and the app's appearance: what every page reads and changes.
class Library extends ChangeNotifier {
  final List<Episode> episodes = [
    Episode(
      title: 'Rooms that sound right',
      show: 'Roomtone',
      status: Status.published,
      recorded: DateTime(2026, 10, 14),
    ),
    Episode(
      title: 'The quiet booth',
      show: 'Roomtone',
      status: Status.editing,
      recorded: DateTime(2026, 11, 18),
    ),
    Episode(title: 'Tape, again', show: 'Side B'),
    Episode(
      title: 'One take',
      show: 'Side B',
      status: Status.editing,
      recorded: DateTime(2026, 11, 3),
      explicit: true,
    ),
  ];

  /// The palette, one of [StudioThemeData.palettes]; an app would store its
  /// id and find it again in the list.
  RawNamedPalette palette = StudioThemeData.palettes.first;

  /// Light or dark; null follows the platform.
  Brightness? brightness;

  void save(Episode episode) {
    if (!episodes.contains(episode)) episodes.add(episode);
    notifyListeners();
  }

  void delete(Episode episode) {
    episodes.remove(episode);
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

// ── The app ─────────────────────────────────────────────────────────────────

class TakesApp extends StatelessWidget {
  TakesApp({super.key});

  final Library library = Library();

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: library,
    builder: (context, _) => MaterialApp(
      title: 'Takes',
      debugShowCheckedModeBanner: false,
      // Every part's words: the shared labels in 30 languages, Studio's
      // own, and Material's, Cupertino's and the widgets' (material_ui
      // carries these, so no flutter_localizations dependency).
      localizationsDelegates: const [
        RawWidgetsLocalizations.delegate,
        StudioLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: RawWidgetsLocalizations.supportedLocales,
      // Studio's push and pop for the pages the app pushes.
      theme: ThemeData(
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: studioPageTransitions,
        ),
      ),
      // The one mount: the theme by day and by night (moving smoothly
      // between them and between palettes), the toasts and the chassis.
      builder: (context, child) => StudioHost(
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
  Widget build(BuildContext context) => StudioAppShell.branches(
    brand: 'Takes',
    tabs: const [
      StudioTab(LucideIcons.listMusic, 'Episodes'),
      StudioTab(LucideIcons.audioWaveform, 'Editing'),
      StudioTab(LucideIcons.settings, 'Settings'),
    ],
    selectedIndex: _place,
    onSelected: (index) => setState(() => _place = index),
    // Each place keeps its own pages: an episode opened in Episodes stays
    // open while you look at Settings.
    branches: [
      (context) => EpisodesPage(library: widget.library),
      (context) => EpisodesPage(library: widget.library, only: Status.editing),
      (context) => SettingsPage(library: widget.library),
    ],
  );
}

// ── A list, and its pushed detail ───────────────────────────────────────────

class EpisodesPage extends StatelessWidget {
  const EpisodesPage({super.key, required this.library, this.only});

  final Library library;
  final Status? only;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: library,
    builder: (context, _) {
      final episodes = [
        for (final episode in library.episodes)
          if (only == null || episode.status == only) episode,
      ];
      return StudioScreen(
        maxWidth: pageMeasure,
        topBar: StudioAppBar(
          title: only?.label ?? 'Episodes',
          actions: [
            StudioIconButton(
              icon: const Icon(LucideIcons.plus),
              tooltip: 'New episode',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => EpisodeForm(library: library),
                ),
              ),
            ),
          ],
        ),
        body: episodes.isEmpty
            ? const StudioStatusView(
                icon: Icon(LucideIcons.mic),
                title: 'Nothing here yet',
                message: 'Episodes you record show up here.',
              )
            : StudioListGroup(
                children: [
                  for (final episode in episodes)
                    StudioListTile(
                      title: episode.title,
                      subtitle: episode.show,
                      trailing: StudioTag(
                        episode.status.label,
                        tone: episode.status.tone,
                      ),
                      showChevron: true,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) =>
                              EpisodePage(library: library, episode: episode),
                        ),
                      ),
                    ),
                ],
              ),
      );
    },
  );
}

class EpisodePage extends StatelessWidget {
  const EpisodePage({super.key, required this.library, required this.episode});

  final Library library;
  final Episode episode;

  Future<void> _delete(BuildContext context) async {
    // The dialog pops with the answer: true to delete, false or null to keep.
    final sure = await showStudioDialog<bool>(
      context: context,
      isAlert: true,
      builder: (context) => StudioDialog(
        title: 'Delete "${episode.title}"?',
        content: const Text('Its takes go with it. This cannot be undone.'),
        actions: [
          StudioButton(
            'Keep',
            onPressed: () => Navigator.of(context).pop(false),
          ),
          StudioButton.lit(
            'Delete',
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    if (sure != true || !context.mounted) return;
    library.delete(episode);
    Navigator.of(context).pop();
    showStudioToast(context, 'Deleted "${episode.title}"');
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: library,
    builder: (context, _) {
      final recorded = episode.recorded;
      return StudioScreen(
        maxWidth: pageMeasure,
        topBar: StudioAppBar(
          title: episode.title,
          actions: [
            StudioIconButton(
              icon: const Icon(LucideIcons.pencil),
              tooltip: 'Edit',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) =>
                      EpisodeForm(library: library, episode: episode),
                ),
              ),
            ),
          ],
        ),
        body: StudioDescriptionList(
          entries: [
            StudioDescription('Show', episode.show),
            StudioDescription('Status', episode.status.label),
            StudioDescription(
              'Recorded',
              recorded == null
                  ? 'Not yet'
                  : RawWidgetsLocalizations.of(context)
                        .formatMediumDate(recorded),
            ),
            StudioDescription('Explicit', episode.explicit ? 'Yes' : 'No'),
          ],
        ),
        footer: StudioButton(
          'Delete',
          isDestructiveAction: true,
          onPressed: () => _delete(context),
        ),
      );
    },
  );
}

// ── A form ──────────────────────────────────────────────────────────────────

class EpisodeForm extends StatefulWidget {
  const EpisodeForm({super.key, required this.library, this.episode});

  final Library library;

  /// The episode to edit; null adds one.
  final Episode? episode;

  @override
  State<EpisodeForm> createState() => _EpisodeFormState();
}

class _EpisodeFormState extends State<EpisodeForm> {
  late final Episode _draft = Episode(
    title: widget.episode?.title ?? '',
    show: widget.episode?.show ?? '',
    status: widget.episode?.status ?? Status.draft,
    recorded: widget.episode?.recorded,
    explicit: widget.episode?.explicit ?? false,
  );

  void _save() {
    final episode = widget.episode ?? Episode(title: '', show: '');
    episode
      ..title = _draft.title
      ..show = _draft.show
      ..status = _draft.status
      ..recorded = _draft.recorded
      ..explicit = _draft.explicit;
    widget.library.save(episode);
    Navigator.of(context).pop();
    showStudioToast(context, 'Saved "${episode.title}"');
  }

  @override
  Widget build(BuildContext context) => StudioForm(
    // Called once every field is fine, after each field's onSaved.
    onSubmit: _save,
    child: StudioScreen(
      maxWidth: pageMeasure,
      topBar: StudioAppBar(
        title: widget.episode == null ? 'New episode' : 'Edit',
      ),
      // The form's column: every field the column's width, 16 apart.
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: StudioSpacing.regular,
        children: [
          StudioTextFormField(
            labelText: 'Title',
            initialValue: _draft.title,
            validator: (value) =>
                (value ?? '').trim().isEmpty ? 'Enter the title' : null,
            onSaved: (value) => _draft.title = value!.trim(),
          ),
          StudioTextFormField(
            labelText: 'Show',
            initialValue: _draft.show,
            onSaved: (value) => _draft.show = value!.trim(),
          ),
          StudioSelect<Status>(
            labelText: 'Status',
            value: _draft.status,
            items: [
              for (final status in Status.values)
                StudioSelectItem(value: status, label: status.label),
            ],
            onChanged: (value) => setState(() => _draft.status = value),
          ),
          StudioDatePicker(
            labelText: 'Recorded',
            hintText: 'Not yet',
            value: _draft.recorded,
            firstDate: DateTime(2020),
            lastDate: DateTime.now(),
            onChanged: (value) => setState(() => _draft.recorded = value),
          ),
          StudioCheckRow(
            label: 'Explicit',
            value: _draft.explicit,
            onChanged: (value) => setState(() => _draft.explicit = value),
          ),
        ],
      ),
      // Under the form: submit checks every field, shows what is wrong and
      // moves focus to the first, or saves.
      footer: Builder(
        builder: (context) => StudioButton.lit(
          'Save',
          onPressed: () => StudioForm.submit(context),
        ),
      ),
    ),
  );
}

// ── Settings ────────────────────────────────────────────────────────────────

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.library});

  final Library library;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: library,
    builder: (context, _) => StudioScreen(
      maxWidth: pageMeasure,
      topBar: const StudioAppBar(title: 'Settings'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: StudioSpacing.large,
        children: [
          StudioFormField(
            labelText: 'Appearance',
            child: StudioRadioGroup<String>(
              direction: Axis.horizontal,
              options: const ['system', 'light', 'dark'],
              labelOf: (value) => switch (value) {
                'light' => 'Light',
                'dark' => 'Dark',
                _ => 'System',
              },
              value: library.brightness?.name ?? 'system',
              onChanged: (value) => value == 'system'
                  ? library.setAppearance(system: true)
                  : library.setAppearance(
                      brightness: Brightness.values.byName(value),
                    ),
            ),
          ),
          StudioFormField(
            labelText: 'Palette',
            child: StudioRadioGroup<RawNamedPalette>(
              options: StudioThemeData.palettes,
              labelOf: (palette) => palette.label,
              secondaryOf: PaletteSwatches.new,
              value: library.palette,
              onChanged: (value) => library.setAppearance(palette: value),
            ),
          ),
        ],
      ),
    ),
  );
}

/// [palette]'s colours in the brightness on screen, beside its name in the
/// picker: its accent on a tile of its ground.
class PaletteSwatches extends StatelessWidget {
  /// [palette]'s swatches.
  const PaletteSwatches(this.palette, {super.key});

  /// The palette they show.
  final RawNamedPalette palette;

  @override
  Widget build(BuildContext context) {
    final theme = StudioTheme.of(context);
    final swatches = palette.swatchesFor(theme.colors.brightness);
    // The last swatch is the palette's ground: a small tile of it, ringed in
    // the hairline, with the others as dots on it, so a ground as pale as
    // the page reads as a page and not as an empty ring.
    final ground = swatches.length > 1 ? swatches.last : null;
    final dots = ground == null
        ? swatches
        : swatches.sublist(0, swatches.length - 1);
    return Container(
      margin: const EdgeInsetsDirectional.only(start: 4),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
        color: ground,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: theme.colors.groove),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 3,
        children: [
          for (final color in dots)
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
        ],
      ),
    );
  }
}

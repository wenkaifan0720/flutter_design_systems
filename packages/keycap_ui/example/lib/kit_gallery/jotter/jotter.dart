/// Jotter, a notebook set in Keycap: the look's Overview, then Home, Notes,
/// Folders and Settings, moved between by the look's own navigation (the
/// row of places at a phone's foot, the rail from 600, the side column from
/// 1024), the note editor, its dialog and its sheet, Share and export,
/// Search, and the notebook when sync fails or a filter finds nothing.
library;

import 'package:material_ui/material_ui.dart';
import 'package:keycap_ui/keycap_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';
import 'data.dart';
import 'editor.dart';
import 'folders.dart';
import 'home.dart';
import 'notes.dart';
import 'overview.dart';
import 'search.dart';
import 'settings.dart';
import 'share.dart';

/// Jotter's places, in its navigation's order.
enum JotterPlace {
  /// Home: the pinned draft, the folders, the recent notes.
  home,

  /// Every note, by folder and filter.
  notes,

  /// The folders and tags.
  folders,

  /// Settings.
  settings,

  /// The look's pitch and its parts' index (About, the last place).
  overview,
}

/// A moment inside a place, a link can open.
enum JotterScene {
  /// The pinned draft open in the editor.
  editor,

  /// The editor asking whether to delete its note.
  delete,

  /// The sheet moving a note to another folder.
  move,

  /// Share and export for the pinned draft.
  share,

  /// Search, with notes that match.
  search,

  /// Search, with none that does.
  searchNone,

  /// Home when sync has failed.
  syncError,

  /// Notes with a filter that keeps none.
  empty,
}

/// Day, night, or the system's.
enum JotterAppearance {
  /// Day.
  light,

  /// Night.
  dark,

  /// The system's.
  system,
}

/// The writer's preferences.
class JotterPrefs extends ChangeNotifier {
  /// Preferences.
  JotterPrefs({
    this.appearance = JotterAppearance.light,
    this.direction = TextDirection.ltr,
    this.density,
  });

  /// Day, night, or the system's.
  JotterAppearance appearance;

  /// The reading direction.
  TextDirection direction;

  /// The controls' density; the platform's when null.
  KeycapDensity? density;

  /// Whether spelling is checked as you type.
  bool spellcheck = true;

  /// Whether quotes and dashes curl as you type.
  bool smartPunctuation = false;

  /// Whether the word count shows under a note.
  bool wordCount = true;

  /// The editor's text size.
  String textSize = 'Medium';

  /// Where a new note goes.
  String defaultFolder = 'inbox';

  /// How often a draft is saved while it is written.
  String autosave = 'Every minute';

  /// Changes the preferences and tells the app.
  void update(void Function(JotterPrefs prefs) change) {
    change(this);
    notifyListeners();
  }

  /// The preferences above [context].
  static JotterPrefs of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_JotterScope>()!.notifier!;
}

class _JotterScope extends InheritedNotifier<JotterPrefs> {
  const _JotterScope({required JotterPrefs prefs, required super.child})
    : super(notifier: prefs);
}

class _JotterFrameScope extends InheritedWidget {
  const _JotterFrameScope({required this.frame, required super.child});

  final GlobalKey<JotterFrameState> frame;

  @override
  bool updateShouldNotify(_JotterFrameScope old) => old.frame != frame;
}

/// A part's gallery page: its title and how to build it.
typedef JotterPart = ({String title, Widget Function(Brightness) build});

/// The Jotter app.
class JotterApp extends StatefulWidget {
  /// Jotter, opened on [initialPlace] (and [initialScene]).
  const JotterApp({
    super.key,
    this.initialPlace = JotterPlace.overview,
    this.initialScene,
    this.initialAppearance = JotterAppearance.light,
    this.initialDirection = TextDirection.ltr,
    this.initialDensity,
    this.textScale,
    this.parts = const [],
    this.initialPart,
  });

  /// The place it opens on.
  final JotterPlace initialPlace;

  /// The moment it opens on.
  final JotterScene? initialScene;

  /// Day or night at first.
  final JotterAppearance initialAppearance;

  /// The reading direction at first.
  final TextDirection initialDirection;

  /// The density at first.
  final KeycapDensity? initialDensity;

  /// The words' scale.
  final double? textScale;

  /// The gallery's part pages.
  final List<JotterPart> parts;

  /// A part page to open over the Overview.
  final int? initialPart;

  @override
  State<JotterApp> createState() => _JotterAppState();
}

class _JotterAppState extends State<JotterApp> {
  late final JotterPrefs _prefs = JotterPrefs(
    appearance: widget.initialAppearance,
    direction: widget.initialDirection,
    density: widget.initialDensity,
  );
  final _frame = GlobalKey<JotterFrameState>();

  @override
  void dispose() {
    _prefs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _prefs,
    builder: (context, _) {
      final frame = JotterFrame(
        key: _frame,
        initialPlace: widget.initialPlace,
        initialScene: widget.initialScene,
        parts: widget.parts,
        initialPart: widget.initialPart,
      );
      return Semantics(
        container: true,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Jotter',
          // Jotter's routes are Material's, which read their page change
          // from Material's theme: Keycap's, given here.
          theme: ThemeData(
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: keycapPageTransitions,
            ),
          ),
          localizationsDelegates: const [
            DesignLocalizations.delegate,
            DefaultMaterialLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
          ],
          supportedLocales: DesignLocalizations.supportedLocales,
          onGenerateInitialRoutes: (_) => [
            MaterialPageRoute<void>(builder: (_) => frame),
          ],
          onGenerateRoute: (_) =>
              MaterialPageRoute<void>(builder: (_) => frame),
          builder: (context, child) {
            final platform = MediaQuery.platformBrightnessOf(context);
            final brightness = switch (_prefs.appearance) {
              JotterAppearance.light => Brightness.light,
              JotterAppearance.dark => Brightness.dark,
              JotterAppearance.system => platform,
            };
            Widget app = AnimatedKeycapTheme(
              data: KeycapThemeData.of(brightness, density: _prefs.density),
              child: KitGalleryScope(
                child: KeycapToaster(child: child ?? const SizedBox.shrink()),
              ),
            );
            final scale = widget.textScale;
            if (scale != null) {
              app = MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: app,
              );
            }
            return _JotterScope(
              prefs: _prefs,
              child: _JotterFrameScope(
                frame: _frame,
                child: Directionality(
                  textDirection: _prefs.direction,
                  child: app,
                ),
              ),
            );
          },
        ),
      );
    },
  );
}

/// Jotter's frame: its places, its notebook, and the page open in it.
class JotterFrame extends StatefulWidget {
  /// The frame.
  const JotterFrame({
    super.key,
    this.initialPlace = JotterPlace.overview,
    this.initialScene,
    this.parts = const [],
    this.initialPart,
  });

  /// The place it opens on.
  final JotterPlace initialPlace;

  /// The moment it opens on.
  final JotterScene? initialScene;

  /// The gallery's part pages.
  final List<JotterPart> parts;

  /// A part page to open at first.
  final int? initialPart;

  /// The frame above [context] (or the app's, from a pushed page).
  static JotterFrameState of(BuildContext context) =>
      context.findAncestorStateOfType<JotterFrameState>() ??
      context
          .getInheritedWidgetOfExactType<_JotterFrameScope>()!
          .frame
          .currentState!;

  @override
  State<JotterFrame> createState() => JotterFrameState();
}

/// The frame's state: the place, the notebook, and the ways to change them.
class JotterFrameState extends State<JotterFrame> {
  late JotterPlace _place = widget.initialPlace;
  final _desk = GlobalKey<NavigatorState>();

  /// The notebook.
  final List<JotterNote> notes = [...jotterNotes];

  /// The note open beside the list on a desktop.
  String openNote = jotterNotes.first.id;

  /// Whether the window is wide enough for a rail or a side column.
  bool get wide => MediaQuery.sizeOf(context).width >= 600;

  /// Whether the notes list and the editor stand side by side.
  bool get split => MediaQuery.sizeOf(context).width >= 1024;

  /// The note [id].
  JotterNote note(String id) => notes.firstWhere((n) => n.id == id);

  @override
  void initState() {
    super.initState();
    final scene = widget.initialScene;
    switch (scene) {
      case JotterScene.syncError:
        _place = JotterPlace.home;
        syncFailed = true;
      case JotterScene.empty:
        _place = JotterPlace.notes;
        folder = 'kitchen';
        filter = 'pinned';
      case JotterScene.search || JotterScene.searchNone:
        _place = JotterPlace.notes;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          push(
            JotterSearchPage(
              initialQuery: scene == JotterScene.search ? 'seed' : 'tomatoes',
            ),
          );
        });
      case null:
        break;
      case JotterScene.editor ||
          JotterScene.delete ||
          JotterScene.move ||
          JotterScene.share:
        _openScene(scene);
    }
    final part = widget.initialPart;
    if (part != null && part >= 0 && part < widget.parts.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          push(widget.parts[part].build(context.keycapTheme.brightness));
        }
      });
    }
  }

  /// Opens the pinned draft, then [scene] over it.
  void _openScene(JotterScene scene) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final draft = notes.first;
      if (split) {
        setState(() {
          _place = JotterPlace.notes;
          openNote = draft.id;
        });
      } else {
        push(JotterEditorPage(noteId: draft.id));
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final at = _desk.currentContext ?? context;
        switch (scene) {
          case JotterScene.editor:
            break;
          case JotterScene.delete:
            askDelete(at, draft.id);
          case JotterScene.move:
            askMove(at, draft.id);
          case JotterScene.share:
            showJotterShare(at, draft.id);
          case _:
            break;
        }
      });
    });
  }

  /// Whether the last sync failed.
  bool syncFailed = false;

  /// Whether a sync is under way.
  bool syncing = false;

  /// Tries the sync again.
  Future<void> retrySync() async {
    setState(() => syncing = true);
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    setState(() {
      syncing = false;
      syncFailed = false;
    });
    showKeycapToast(context, 'Synced 3 changes');
  }

  /// Opens Search over the place.
  void search() => push(const JotterSearchPage());

  /// Opens Search on [query] (a tag's row searches for its tag).
  void searchFor(String query) => push(JotterSearchPage(initialQuery: query));

  /// Pushes [page] over the place (inside the desk beside the places from
  /// 600).
  void push(Widget page) {
    final route = MaterialPageRoute<void>(builder: (_) => page);
    final desk = _desk.currentState;
    if (desk != null) {
      desk.push(route);
    } else {
      Navigator.of(context).push(route);
    }
  }

  /// The folder the notes list shows; null for every folder.
  String? folder;

  /// Which notes the list shows: `all`, `drafts` or `pinned`.
  String filter = 'all';

  /// Goes to [place].
  void go(JotterPlace place) => setState(() => _place = place);

  /// Shows the notes in folder [id] (every folder when null).
  void showFolder(String? id) => setState(() {
    folder = id;
    _place = JotterPlace.notes;
  });

  /// The notes the list shows: in [folder] (every folder when null), kept
  /// by [filter].
  List<JotterNote> get shownNotes => [
    for (final n in notes)
      if ((folder == null || n.folder == folder) &&
          switch (filter) {
            'drafts' => n.draft,
            'pinned' => n.pinned,
            _ => true,
          })
        n,
  ];

  /// Shows the notes [filter] keeps.
  void showFilter(String filter) => setState(() => this.filter = filter);

  /// Opens note [id]: beside the list on a desktop, pushed elsewhere.
  void open(String id) {
    if (split) {
      setState(() {
        openNote = id;
        _place = JotterPlace.notes;
      });
    } else {
      push(JotterEditorPage(noteId: id));
    }
  }

  int _made = 0;

  /// Starts a note in the default folder and opens it.
  void newNote() {
    final id = 'new-${++_made}';
    setState(
      () => notes.insert(
        0,
        JotterNote(
          id: id,
          title: '',
          body: '',
          folder: JotterPrefs.of(context).defaultFolder,
          edited: 'Just now',
          editedShort: 'Now',
          draft: true,
        ),
      ),
    );
    open(id);
  }

  /// Saves new words in note [id].
  void rewrite(String id, {String? title, String? body}) {
    final at = notes.indexWhere((n) => n.id == id);
    if (at < 0) return;
    setState(() => notes[at] = notes[at].rewritten(title: title, body: body));
  }

  /// Asks whether to delete note [id], and deletes it if so.
  Future<void> askDelete(BuildContext context, String id) async {
    final doomed = note(id);
    final sure = await showKeycapDialog<bool>(
      context: context,
      isAlert: true,
      builder: (context) => KeycapDialog(
        title: 'Delete “${doomed.title}”?',
        content: const Text(
          'It moves to Recently deleted, where it stays for 30 days.',
        ),
        actions: [
          KeycapButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep note'),
          ),
          KeycapButton.accent(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (sure != true || !mounted) return;
    final at = notes.indexWhere((n) => n.id == id);
    if (!split && context.mounted) Navigator.of(context).maybePop();
    setState(() {
      notes.removeAt(at);
      if (openNote == id && notes.isNotEmpty) openNote = notes.first.id;
    });
    if (!mounted) return;
    showKeycapToast(
      this.context,
      'Note deleted',
      actionLabel: 'Undo',
      onAction: () => setState(() => notes.insert(at, doomed)),
    );
  }

  /// Offers the folders to move note [id] to, and moves it.
  Future<void> askMove(BuildContext context, String id) async {
    final moving = note(id);
    // A sheet from a phone's foot; from 600 a dialog over the window.
    final to = MediaQuery.sizeOf(context).width < 600
        ? await showKeycapBottomSheet<String>(
            context: context,
            title: 'Move to folder',
            builder: (context) => JotterFolderChoice(
              notes: notes,
              initial: moving.folder,
              onChosen: (f) => Navigator.of(context).pop(f),
            ),
          )
        : await showKeycapDialog<String>(
            context: context,
            builder: (context) =>
                JotterMoveDialog(notes: notes, initial: moving.folder),
          );
    if (to == null || to == moving.folder || !mounted) return;
    final at = notes.indexWhere((n) => n.id == id);
    setState(() => notes[at] = moving.movedTo(to));
    showKeycapToast(
      this.context,
      'Moved to ${jotterFolder(to).name}',
      actionLabel: 'Undo',
      onAction: () => setState(() => notes[at] = moving),
    );
  }

  @override
  Widget build(BuildContext context) {
    final places = [
      const KeycapDestination(icon: LucideIcons.house, label: 'Home'),
      const KeycapDestination(icon: LucideIcons.notebookText, label: 'Notes'),
      const KeycapDestination(icon: LucideIcons.folder, label: 'Folders'),
      const KeycapDestination(icon: LucideIcons.settings, label: 'Settings'),
      const KeycapDestination(icon: LucideIcons.info, label: 'About'),
    ];
    final page = switch (_place) {
      JotterPlace.overview => JotterOverview(parts: widget.parts),
      JotterPlace.home => const JotterHome(),
      JotterPlace.notes => const JotterNotes(),
      JotterPlace.folders => const JotterFolders(),
      JotterPlace.settings => const JotterSettings(),
    };
    final index = _place.index;
    return KeycapScaffold(
      destinations: places,
      selectedIndex: index,
      onSelected: (i) => go(JotterPlace.values[i]),
      header: const JotterBrand(large: true),
      action: KeycapIconButton(
        icon: const Icon(LucideIcons.squarePen),
        semanticLabel: 'New note',
        onPressed: newNote,
      ),
      wideAction: KeycapButton(
        icon: const Icon(LucideIcons.squarePen),
        onPressed: newNote,
        child: const Text('New note'),
      ),
      sideFooter: Text(
        syncFailed
            ? '${notes.length} notes · 3 changes not synced'
            : '${notes.length} notes · synced just now',
        style: context.keycapTheme.textTheme.secondary,
      ),
      body: wide
          ? Semantics(
              container: true,
              child: Navigator(
                key: _desk,
                pages: [_PlacePage(key: ValueKey(_place), child: page)],
                onDidRemovePage: (_) {},
              ),
            )
          : KeyedSubtree(key: ValueKey(_place), child: page),
    );
  }
}

/// Jotter's mark: a small modifier key printed with a J, and its name.
class JotterBrand extends StatelessWidget {
  /// The mark, with the name when [large].
  const JotterBrand({super.key, this.large = false});

  /// Whether the name stands beside the mark.
  final bool large;

  @override
  Widget build(BuildContext context) {
    final theme = context.keycapTheme;
    final mark = SizedBox.square(
      dimension: 32,
      child: KeycapCap(
        face: keycapKeyFace(
          theme,
          KeycapKind.modifier,
          const {},
        ).copyWith(radius: 7),
        walls: KeycapMetrics.walls(32),
        child: Center(
          child: Text(
            'J',
            textScaler: TextScaler.noScaling,
            style: theme.textTheme.label.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colors.modifier.legend,
            ),
          ),
        ),
      ),
    );
    if (!large) return Semantics(label: 'Jotter', child: mark);
    return Semantics(
      label: 'Jotter',
      excludeSemantics: true,
      child: Row(
        children: [
          mark,
          const SizedBox(width: KeycapSpacing.medium),
          Text('Jotter', style: theme.textTheme.title.copyWith(fontSize: 20)),
        ],
      ),
    );
  }
}

/// A Jotter page: its top bar (a back key when it was pushed), its content
/// in a column at most [maxWidth] wide on the page's start edge.
class JotterPage extends StatelessWidget {
  /// A page.
  const JotterPage({
    super.key,
    required this.title,
    required this.children,
    this.actions = const [],
    this.footer,
    this.maxWidth = KeycapScreen.pageWidth,
  });

  /// Its title.
  final String title;

  /// Its content.
  final List<Widget> children;

  /// Keys at the top bar's end.
  final List<Widget> actions;

  /// Keys at its foot.
  final Widget? footer;

  /// The widest its content stands.
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final route = ModalRoute.of(context);
    final canPop = route?.canPop ?? false;
    // The bar stands over the content's column: its keys end where the
    // content does.
    return KeycapScreen(
      maxWidth: maxWidth,
      topBar: KeycapAppBar(
        title: title,
        onBack: canPop ? () => Navigator.of(context).maybePop() : null,
        actions: actions,
      ),
      footer: footer,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

/// The space between groups on a page.
const jotterGroupGap = SizedBox(height: KeycapSpacing.extraLarge);

class _PlacePage extends Page<void> {
  const _PlacePage({super.key, required this.child});

  final Widget child;

  @override
  Route<void> createRoute(BuildContext context) => PageRouteBuilder<void>(
    settings: this,
    transitionDuration: Duration.zero,
    reverseTransitionDuration: Duration.zero,
    pageBuilder: (context, _, _) => child,
  );
}

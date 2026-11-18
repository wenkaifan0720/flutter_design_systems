/// Roomtone: the example's product, a podcast player and recorder set in
/// Studio. Five places (the look's Overview, Home, Library, Record and
/// Settings) moved between by the look's own navigation: the key bank on a
/// phone, the rail on a tablet, the side panel from 1024.
///
/// Settings drives the app: its appearance, reading direction and density,
/// so every screen shows them as they are set.
library;

import 'package:material_ui/material_ui.dart';
import 'package:studio_ui/studio_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';
import 'data.dart';
import 'episode.dart';
import 'home.dart';
import 'library.dart';
import 'overview.dart';
import 'publish.dart';
import 'recorder.dart';
import 'search.dart';
import 'settings.dart';
import 'words.dart';

/// Where the app opens.
enum RoomtonePlace { overview, home, library, record, settings }

/// A state of a place Roomtone can open straight onto, as a link or the
/// sweep of its everyday screens does.
enum RoomtoneScene {
  /// An episode's page with its player, over the Library.
  episode,

  /// The Library's search, with results.
  search,

  /// The Library's search, with nothing found.
  searchEmpty,

  /// The Library's downloads, with none left.
  downloadsEmpty,

  /// The publish form, over the recorder.
  publish,

  /// The publish form after an upload failed.
  uploadFailed,

  /// The recorder asking whether to discard the take.
  discard,

  /// The recorder's export sheet.
  export,
}

/// How the app is lit.
enum RoomtoneAppearance { light, dark, system }

/// What Settings sets for the whole app.
class RoomtonePrefs extends ChangeNotifier {
  /// Prefs as given.
  RoomtonePrefs({
    this.appearance = RoomtoneAppearance.light,
    this.direction = TextDirection.ltr,
    this.density = StudioDensity.standard,
  });

  /// Light, dark or the system's.
  RoomtoneAppearance appearance;

  /// Which way the pages read.
  TextDirection direction;

  /// How tightly the controls are set.
  StudioDensity density;

  /// How episodes are downloaded.
  String quality = 'high';

  /// Whether downloads may use mobile data.
  bool cellular = false;

  /// New episodes of followed shows.
  bool newEpisodes = true;

  /// A weekly digest by email.
  bool digest = false;

  /// Remove played episodes from the device.
  bool autoDelete = true;

  /// Whether every download has been removed from the device.
  bool downloadsRemoved = false;

  /// Changes the prefs and tells the app.
  void update(void Function(RoomtonePrefs prefs) change) {
    change(this);
    notifyListeners();
  }

  /// The prefs above [context].
  static RoomtonePrefs of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_RoomtoneScope>()!.notifier!;
}

class _RoomtoneScope extends InheritedNotifier<RoomtonePrefs> {
  const _RoomtoneScope({required RoomtonePrefs prefs, required super.child})
    : super(notifier: prefs);
}

class _RoomtoneFrameScope extends InheritedWidget {
  const _RoomtoneFrameScope({required this.frame, required super.child});

  final GlobalKey<RoomtoneFrameState> frame;

  @override
  bool updateShouldNotify(_RoomtoneFrameScope old) => old.frame != frame;
}

/// One entry of the Overview's index of parts.
typedef RoomtonePart = ({String title, Widget Function(Brightness) build});

/// The app, themed by [RoomtonePrefs], opening on [initialPlace].
class RoomtoneApp extends StatefulWidget {
  /// The app.
  const RoomtoneApp({
    super.key,
    this.initialPlace = RoomtonePlace.overview,
    this.initialScene,
    this.initialAppearance = RoomtoneAppearance.light,
    this.initialDirection = TextDirection.ltr,
    this.initialDensity,
    this.textScale,
    this.parts = const [],
    this.initialPart,
  });

  /// The place it opens on.
  final RoomtonePlace initialPlace;

  /// The state of [initialPlace] it opens on; null: as it first stands.
  final RoomtoneScene? initialScene;

  /// How it is lit at first. Settings changes it after.
  final RoomtoneAppearance initialAppearance;

  /// The direction it reads at first.
  final TextDirection initialDirection;

  /// The density it opens at; null: standard.
  final StudioDensity? initialDensity;

  /// A text scale over the platform's; null keeps the platform's.
  final double? textScale;

  /// The package's parts, for the Overview's index.
  final List<RoomtonePart> parts;

  /// The index in [parts] of a part whose page opens after the first frame.
  final int? initialPart;

  @override
  State<RoomtoneApp> createState() => _RoomtoneAppState();
}

class _RoomtoneAppState extends State<RoomtoneApp> {
  late final RoomtonePrefs _prefs = RoomtonePrefs(
    appearance: widget.initialAppearance,
    direction: widget.initialDirection,
    density: widget.initialDensity ?? StudioDensity.standard,
  )..downloadsRemoved = widget.initialScene == RoomtoneScene.downloadsEmpty;
  final _frame = GlobalKey<RoomtoneFrameState>();

  @override
  void dispose() {
    _prefs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _prefs,
    builder: (context, _) {
      final frame = RoomtoneFrame(
        key: _frame,
        initialPlace: widget.initialPlace,
        initialScene: widget.initialScene,
        parts: widget.parts,
        initialPart: widget.initialPart,
      );
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Roomtone',
        // Roomtone is written on Flutter's own material library, whose
        // routes read their page change from its own theme: Studio's, given
        // here.
        theme: ThemeData(
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: studioPageTransitions,
          ),
        ),
        localizationsDelegates: const [
          StudioLocalizations.delegate,
          RoomtoneWords.delegate,
          DesignLocalizations.delegate,
          DefaultMaterialLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
        supportedLocales: DesignLocalizations.supportedLocales,
        onGenerateInitialRoutes: (_) => [
          MaterialPageRoute<void>(builder: (_) => frame),
        ],
        onGenerateRoute: (_) => MaterialPageRoute<void>(builder: (_) => frame),
        builder: (context, child) {
          final platform = MediaQuery.platformBrightnessOf(context);
          final brightness = switch (_prefs.appearance) {
            RoomtoneAppearance.light => Brightness.light,
            RoomtoneAppearance.dark => Brightness.dark,
            RoomtoneAppearance.system => platform,
          };
          Widget app = AnimatedStudioTheme(
            data: StudioThemeData.anodised(brightness, density: _prefs.density),
            child: KitGalleryScope(
              child: StudioToaster(child: child ?? const SizedBox.shrink()),
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
          return _RoomtoneScope(
            prefs: _prefs,
            child: _RoomtoneFrameScope(
              frame: _frame,
              child: Directionality(
                textDirection: _prefs.direction,
                child: app,
              ),
            ),
          );
        },
      );
    },
  );
}

/// The app's frame: the current place under the look's navigation. From the
/// rail's width (600) a pushed page opens in the frame, beside the rail or
/// the side panel; on a phone it covers the key bank.
class RoomtoneFrame extends StatefulWidget {
  /// The frame.
  const RoomtoneFrame({
    super.key,
    this.initialPlace = RoomtonePlace.overview,
    this.initialScene,
    this.parts = const [],
    this.initialPart,
  });

  /// As [RoomtoneApp.initialPlace].
  final RoomtonePlace initialPlace;

  /// As [RoomtoneApp.initialScene].
  final RoomtoneScene? initialScene;

  /// As [RoomtoneApp.parts].
  final List<RoomtonePart> parts;

  /// As [RoomtoneApp.initialPart].
  final int? initialPart;

  /// The frame above [context].
  static RoomtoneFrameState of(BuildContext context) =>
      context.findAncestorStateOfType<RoomtoneFrameState>() ??
      context
          .getInheritedWidgetOfExactType<_RoomtoneFrameScope>()!
          .frame
          .currentState!;

  @override
  State<RoomtoneFrame> createState() => RoomtoneFrameState();
}

/// [RoomtoneFrame]'s state: where a page opens, and the way between places.
class RoomtoneFrameState extends State<RoomtoneFrame> {
  late RoomtonePlace _place = widget.initialPlace;
  late RoomtoneScene? _scene = widget.initialScene;
  final _desk = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    final scene = _scene;
    if (scene != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        switch (scene) {
          // On a desk the Library stands beside its player; below it the
          // episode's page opens over the list.
          case RoomtoneScene.episode:
            if (!desk) push(RoomtoneEpisodePage(episode: roomtoneNowPlaying));
          case RoomtoneScene.search:
            push(const RoomtoneSearchPage(initialQuery: 'film'));
          case RoomtoneScene.searchEmpty:
            push(const RoomtoneSearchPage(initialQuery: 'zither'));
          case RoomtoneScene.publish:
            push(const RoomtonePublishPage());
          case RoomtoneScene.uploadFailed:
            push(const RoomtonePublishPage(failed: true));
          // The Library and the recorder open these themselves.
          case RoomtoneScene.downloadsEmpty ||
              RoomtoneScene.discard ||
              RoomtoneScene.export:
            break;
        }
      });
    }
    final part = widget.initialPart;
    if (part != null && part >= 0 && part < widget.parts.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          push(widget.parts[part].build(context.studioTheme.colors.brightness));
        }
      });
    }
  }

  /// Whether the frame stands beside a rail or a side panel.
  bool get wide => MediaQuery.sizeOf(context).width >= 600;

  /// Whether the Library stands beside its player.
  bool get desk => MediaQuery.sizeOf(context).width >= roomtoneDeskWidth;

  /// Opens [page] over the current place: in the frame from 600, over the
  /// whole app on a phone.
  void push(Widget page) {
    final route = MaterialPageRoute<void>(builder: (_) => page);
    final desk = _desk.currentState;
    if (desk != null) {
      desk.push(route);
    } else {
      Navigator.of(context).push(route);
    }
  }

  /// Goes to [place], leaving what was pushed on the last one.
  void go(RoomtonePlace place) => setState(() {
    _place = place;
    _scene = null;
  });

  static const _places = [
    StudioDestination(icon: Icon(LucideIcons.audioLines), label: 'Studio'),
    StudioDestination(icon: Icon(LucideIcons.house), label: 'Home'),
    StudioDestination(icon: Icon(LucideIcons.libraryBig), label: 'Library'),
    StudioDestination(icon: Icon(LucideIcons.mic), label: 'Record'),
    StudioDestination(
      icon: Icon(LucideIcons.slidersHorizontal),
      label: 'Settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = context.studioTheme;
    final page = switch (_place) {
      RoomtonePlace.overview => RoomtoneOverview(parts: widget.parts),
      RoomtonePlace.home => const RoomtoneHome(),
      RoomtonePlace.library => RoomtoneLibrary(
        open: _scene == RoomtoneScene.episode ? roomtoneNowPlaying : null,
        downloadedOnly: _scene == RoomtoneScene.downloadsEmpty,
      ),
      RoomtonePlace.record => RoomtoneRecorder(
        asking: switch (_scene) {
          RoomtoneScene.discard => RoomtoneRecorderAsk.discard,
          RoomtoneScene.export => RoomtoneRecorderAsk.export,
          _ => null,
        },
      ),
      RoomtonePlace.settings => const RoomtoneSettings(),
    };
    final width = MediaQuery.sizeOf(context).width;
    return StudioScaffold(
      destinations: _places,
      selectedIndex: _place.index,
      onDestinationSelected: (i) => go(RoomtonePlace.values[i]),
      header: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const StudioLamp(on: true),
          const SizedBox(width: StudioSpacing.small),
          Flexible(
            child: Text(
              width >= 1024 ? 'Roomtone' : 'RT',
              style: theme.textTheme.title.copyWith(color: theme.colors.legend),
            ),
          ),
        ],
      ),
      navigationFooter: StudioListTile(
        title: roomtoneListener.name,
        subtitle: roomtoneBreakable(roomtoneListener.email),
        leading: StudioAvatar(name: roomtoneListener.name, size: 32),
        onTap: () => go(RoomtonePlace.settings),
        showChevron: false,
      ),
      body: wide
          ? Navigator(
              key: _desk,
              // A place is swapped in place: no page change.
              pages: [_PlacePage(key: ValueKey(_place), child: page)],
              onDidRemovePage: (_) {},
            )
          : KeyedSubtree(key: ValueKey(_place), child: page),
    );
  }
}

/// One of Roomtone's pages: its faceplate bar, then its content down one
/// column that starts on the page's edge and stands at most [maxWidth] wide;
/// [bottom] pinned under it.
class RoomtonePage extends StatelessWidget {
  /// A page titled [title].
  const RoomtonePage({
    super.key,
    required this.title,
    required this.children,
    this.actions = const [],
    this.bottom,
    this.maxWidth = StudioMetrics.readingWidth,
  });

  /// The page's name.
  final String title;

  /// What it holds, top to bottom.
  final List<Widget> children;

  /// Keys in its bar.
  final List<Widget> actions;

  /// What stands pinned at its foot: the main action.
  final Widget? bottom;

  /// The widest its column stands.
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final theme = context.studioTheme;
    final c = theme.colors;
    final margin = StudioSpacing.pageMargin(MediaQuery.sizeOf(context).width);
    final pad = MediaQuery.paddingOf(context);
    return StudioSurface(
      face: StudioFace(
        fill: c.panel,
        fillLow: c.panelLow,
        depth: StudioDepth.level,
        radius: 0,
        brushed: true,
        foreground: c.legend,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StudioAppBar(title: title, actions: actions),
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  margin,
                  StudioSpacing.large,
                  margin,
                  StudioSpacing.huge + (bottom == null ? pad.bottom : 0),
                ),
                children: [
                  Align(
                    alignment: AlignmentDirectional.topStart,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxWidth),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: children,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (bottom != null)
            StudioSurface(
              face: StudioFace(
                fill: c.bar,
                fillLow: c.barLow,
                depth: StudioDepth.level,
                radius: 0,
                brushed: true,
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  margin,
                  StudioSpacing.medium,
                  margin,
                  StudioSpacing.medium + pad.bottom,
                ),
                // The width of the page on a phone, as StudioScreen's
                // footer; wider, at the end of the page's column, where a
                // desk's main key stands.
                child: MediaQuery.sizeOf(context).width < StudioMetrics.tablet
                    ? bottom
                    : Align(
                        alignment: AlignmentDirectional.topStart,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxWidth),
                          child: Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: bottom,
                          ),
                        ),
                      ),
              ),
            ),
        ],
      ),
    );
  }
}

/// From this window width the Library stands beside its player.
const double roomtoneDeskWidth = 1024;

/// A gap between groups on a page.
const roomtoneGroupGap = SizedBox(height: StudioSpacing.extraLarge);

/// Whether the window is a desk's: groups stand side by side.
bool roomtoneDesk(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= StudioMetrics.desk;

/// The column a page of groups takes: a reading width, or on a desk room
/// for two columns side by side.
double roomtonePageWidth(BuildContext context) =>
    roomtoneDesk(context) ? 1080 : StudioMetrics.readingWidth;

/// Two columns of groups side by side on a desk ([start] and [end]); below
/// it they stack, a group gap between them (guidance rule 11).
List<Widget> roomtoneColumns(
  BuildContext context,
  List<Widget> start,
  List<Widget> end,
) {
  if (!roomtoneDesk(context)) return [...start, roomtoneGroupGap, ...end];
  Widget column(List<Widget> children) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    ),
  );
  return [
    Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        column(start),
        const SizedBox(width: StudioSpacing.extraLarge),
        column(end),
      ],
    ),
  ];
}

/// One of the app's places at the root of the frame's navigator: swapped in
/// place when the navigation changes it, never slid in.
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

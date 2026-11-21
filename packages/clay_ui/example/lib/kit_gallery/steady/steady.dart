/// Steady, a habits and wellbeing app set in Clay: the look's Overview, then
/// Today, Habits and Settings, moved between by the look's own navigation
/// (the dock on a phone, the rail from 600, the sidebar from 1024).
library;

import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:clay_ui/clay_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';
import 'data.dart';
import 'editor.dart';
import 'habits.dart';
import 'log.dart';
import 'overview.dart';
import 'settings.dart';
import 'today.dart';

/// Steady's places, in the navigation's order.
enum SteadyPlace {
  /// The look's pitch.
  overview,

  /// Today's habits.
  today,

  /// Every habit, with filters.
  habits,

  /// The person's settings.
  settings,
}

/// A screen opened over a place, for a link or a test.
enum SteadyScene {
  /// A habit's page.
  habit,

  /// A new habit.
  newHabit,

  /// A habit being edited.
  editHabit,

  /// The editor, asking to delete the habit.
  deleteHabit,

  /// The editor, choosing the reminder's time.
  reminder,

  /// The check-in: mood, energy, water and a note.
  checkIn,

  /// The habit list searched, with results.
  search,

  /// The habit list searched, with none.
  searchEmpty,

  /// Today, its last sync failed.
  syncFailed,

  /// Today with no habits yet.
  empty;

  /// The place it opens over.
  SteadyPlace get place => switch (this) {
    habit ||
    editHabit ||
    deleteHabit ||
    reminder ||
    search ||
    searchEmpty => SteadyPlace.habits,
    newHabit || checkIn || syncFailed || empty => SteadyPlace.today,
  };

  /// What the habit list is searched for when it opens.
  String get query => switch (this) {
    search => 'wa',
    searchEmpty => 'yoga',
    _ => '',
  };
}

/// From this window width the habits and the chosen one stand side by side.
const steadySplitWidth = 1200.0;

/// Where the habits stand with the cloud.
enum SteadySync {
  /// Every tick saved.
  synced,

  /// The last sync failed; the ticks wait on the phone.
  failed,

  /// Trying again.
  syncing,
}

/// Light, dark, or the system's.
enum SteadyAppearance {
  /// By day.
  light,

  /// By night.
  dark,

  /// As the system is.
  system,
}

/// What a person sets in Settings.
class SteadyPrefs extends ChangeNotifier {
  /// Settings at [appearance], in [direction], at [density].
  SteadyPrefs({
    this.appearance = SteadyAppearance.light,
    this.direction = TextDirection.ltr,
    this.density = ClayDensity.standard,
  });

  /// Light, dark or the system's.
  SteadyAppearance appearance;

  /// The words' direction.
  TextDirection direction;

  /// How tight the controls stand.
  ClayDensity density;

  /// A check-in every morning.
  bool checkIn = true;

  /// A note when a streak is at risk.
  bool streakAtRisk = true;

  /// A summary every Sunday.
  bool weekly = false;

  /// Sounds on a tick.
  bool sounds = true;

  /// The day a week starts on.
  String weekStart = 'mon';

  /// How water is counted: 'glasses', 'ml' or 'oz'.
  String water = 'glasses';

  /// How distance is measured: 'km' or 'mi'.
  String distance = 'km';

  /// Changes the settings and tells the app.
  void update(void Function(SteadyPrefs prefs) change) {
    change(this);
    notifyListeners();
  }

  /// The settings above [context].
  static SteadyPrefs of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SteadyScope>()!.notifier!;
}

class _SteadyScope extends InheritedNotifier<SteadyPrefs> {
  const _SteadyScope({required SteadyPrefs prefs, required super.child})
    : super(notifier: prefs);
}

class _SteadyFrameScope extends InheritedWidget {
  const _SteadyFrameScope({required this.frame, required super.child});

  final GlobalKey<SteadyFrameState> frame;

  @override
  bool updateShouldNotify(_SteadyFrameScope old) => old.frame != frame;
}

/// One page of the gallery: its title and how to build it.
typedef SteadyPart = ({String title, Widget Function(Brightness) build});

/// Steady, opened on [initialPlace].
class SteadyApp extends StatefulWidget {
  /// The app.
  const SteadyApp({
    super.key,
    this.initialPlace = SteadyPlace.overview,
    this.initialScene,
    this.initialAppearance = SteadyAppearance.light,
    this.initialDirection = TextDirection.ltr,
    this.initialDensity,
    this.textScale,
    this.parts = const [],
    this.initialPart,
  });

  /// The place it opens on.
  final SteadyPlace initialPlace;

  /// A screen it opens over that place.
  final SteadyScene? initialScene;

  /// Light, dark or the system's, to start.
  final SteadyAppearance initialAppearance;

  /// The words' direction, to start.
  final TextDirection initialDirection;

  /// The density, to start; standard when null.
  final ClayDensity? initialDensity;

  /// The words' scale, as a factor; the system's when null.
  final double? textScale;

  /// The gallery's pages, listed on the Overview.
  final List<SteadyPart> parts;

  /// A gallery page it opens on.
  final int? initialPart;

  @override
  State<SteadyApp> createState() => _SteadyAppState();
}

class _SteadyAppState extends State<SteadyApp> {
  late final SteadyPrefs _prefs = SteadyPrefs(
    appearance: widget.initialAppearance,
    direction: widget.initialDirection,
    density: widget.initialDensity ?? ClayDensity.standard,
  );
  final _frame = GlobalKey<SteadyFrameState>();

  @override
  void dispose() {
    _prefs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _prefs,
    builder: (context, _) {
      final frame = SteadyFrame(
        key: _frame,
        initialPlace: widget.initialPlace,
        initialScene: widget.initialScene,
        parts: widget.parts,
        initialPart: widget.initialPart,
      );
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Steady',
        theme: ThemeData(
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: clayPageTransitions,
          ),
        ),
        localizationsDelegates: const [
          RawWidgetsLocalizations.delegate,
          DefaultMaterialLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
        supportedLocales: RawWidgetsLocalizations.supportedLocales,
        onGenerateInitialRoutes: (_) => [
          MaterialPageRoute<void>(builder: (_) => frame),
        ],
        onGenerateRoute: (_) => MaterialPageRoute<void>(builder: (_) => frame),
        builder: (context, child) {
          final platform = MediaQuery.platformBrightnessOf(context);
          final brightness = switch (_prefs.appearance) {
            SteadyAppearance.light => Brightness.light,
            SteadyAppearance.dark => Brightness.dark,
            SteadyAppearance.system => platform,
          };
          Widget app = AnimatedClayTheme(
            data: ClayThemeData.clay(brightness, density: _prefs.density),
            child: KitGalleryScope(
              child: ClayToaster(child: child ?? const SizedBox.shrink()),
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
          return _SteadyScope(
            prefs: _prefs,
            child: _SteadyFrameScope(
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

/// Steady's frame: the place shown and the navigation round it.
class SteadyFrame extends StatefulWidget {
  /// The frame, on [initialPlace].
  const SteadyFrame({
    super.key,
    this.initialPlace = SteadyPlace.overview,
    this.initialScene,
    this.parts = const [],
    this.initialPart,
  });

  /// The place it opens on.
  final SteadyPlace initialPlace;

  /// A screen it opens over that place.
  final SteadyScene? initialScene;

  /// The gallery's pages.
  final List<SteadyPart> parts;

  /// A gallery page it opens on.
  final int? initialPart;

  /// The frame above [context].
  static SteadyFrameState of(BuildContext context) =>
      context.findAncestorStateOfType<SteadyFrameState>() ??
      context
          .getInheritedWidgetOfExactType<_SteadyFrameScope>()!
          .frame
          .currentState!;

  @override
  State<SteadyFrame> createState() => SteadyFrameState();
}

/// The frame's state: where it is, the habits, and how to go elsewhere.
class SteadyFrameState extends State<SteadyFrame> {
  late SteadyPlace _place = widget.initialPlace;
  late SteadyScene? _scene = widget.initialScene;
  final _desk = GlobalKey<NavigatorState>();

  /// The habits every screen shows.
  late final List<SteadyHabit> habits = widget.initialScene == SteadyScene.empty
      ? <SteadyHabit>[]
      : steadyHabits();

  /// Where the habits stand with the cloud.
  late SteadySync sync = widget.initialScene == SteadyScene.syncFailed
      ? SteadySync.failed
      : SteadySync.synced;

  Timer? _syncing;

  /// Tries the sync again: a moment's work, then the habits are saved.
  void retrySync() {
    setState(() => sync = SteadySync.syncing);
    _syncing?.cancel();
    _syncing = Timer(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      setState(() => sync = SteadySync.synced);
      showClayToast(context, 'Synced. Every tick is saved.');
    });
  }

  @override
  void dispose() {
    _syncing?.cancel();
    super.dispose();
  }

  /// Sets how much of counted [h] is done today.
  void log(SteadyHabit h, int amount) =>
      setState(() => h.progress = amount.clamp(0, 99));

  /// The habit chosen on the habit list (a desk shows it beside the list).
  String chosen = 'water';

  /// The habit named [id].
  SteadyHabit habit(String id) => habits.firstWhere((h) => h.id == id);

  /// Ticks a yes-or-no habit, or adds one to a counted one; again past its
  /// goal clears it.
  void tick(SteadyHabit h) => setState(() {
    if (h.done) {
      h.progress = 0;
      h.streak = (h.streak - 1).clamp(0, 9999);
    } else {
      h.progress = h.goal == 1 ? 1 : h.progress + 1;
      if (h.done) h.streak++;
    }
  });

  /// Saves [h] (new or changed).
  void save(SteadyHabit h) => setState(() {
    if (!habits.contains(h)) habits.add(h);
  });

  /// Deletes [h].
  void delete(SteadyHabit h) => setState(() {
    habits.remove(h);
    if (chosen == h.id && habits.isNotEmpty) chosen = habits.first.id;
  });

  /// Chooses [id] on the habit list.
  void choose(String id) => setState(() => chosen = id);

  @override
  void initState() {
    super.initState();
    final scene = _scene;
    if (scene != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final beside =
            scene == SteadyScene.habit &&
            MediaQuery.sizeOf(context).width >= steadySplitWidth;
        if (beside) return;
        final page = switch (scene) {
          SteadyScene.habit => SteadyHabitPage(habit: habit(chosen)),
          SteadyScene.newHabit => const SteadyEditor(),
          SteadyScene.editHabit => SteadyEditor(habit: habit('walk')),
          SteadyScene.deleteHabit => SteadyEditor(
            habit: habit('walk'),
            opening: SteadyEditorOpening.delete,
          ),
          SteadyScene.reminder => SteadyEditor(
            habit: habit('walk'),
            opening: SteadyEditorOpening.reminder,
          ),
          SteadyScene.checkIn => const SteadyLog(),
          SteadyScene.search ||
          SteadyScene.searchEmpty ||
          SteadyScene.syncFailed ||
          SteadyScene.empty => null,
        };
        if (page != null) push(page);
      });
    }
    final part = widget.initialPart;
    if (part != null && part >= 0 && part < widget.parts.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        push(widget.parts[part].build(context.clayTheme.brightness));
      });
    }
  }

  /// Whether the window is a tablet's or wider.
  bool get wide => MediaQuery.sizeOf(context).width >= 600;

  /// Opens [page] over the current place: in the place's own pane when
  /// wide, over everything on a phone.
  void push(Widget page) {
    final route = MaterialPageRoute<void>(builder: (_) => page);
    final desk = _desk.currentState;
    if (desk != null) {
      desk.push(route);
    } else {
      Navigator.of(context).push(route);
    }
  }

  /// Goes to [place].
  void go(SteadyPlace place) => setState(() {
    _place = place;
    _scene = null;
  });

  static const _places = [
    ClayDestination(icon: LucideIcons.sparkles, label: 'Clay'),
    ClayDestination(icon: LucideIcons.sun, label: 'Today'),
    ClayDestination(icon: LucideIcons.listChecks, label: 'Habits'),
    ClayDestination(icon: LucideIcons.settings, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = context.clayTheme;
    final width = MediaQuery.sizeOf(context).width;
    final page = switch (_place) {
      SteadyPlace.overview => SteadyOverview(parts: widget.parts),
      SteadyPlace.today => const SteadyToday(),
      SteadyPlace.habits => SteadyHabits(initialQuery: _scene?.query ?? ''),
      SteadyPlace.settings => const SteadySettings(),
    };
    final add = ClayIconButton.filled(
      onPressed: () => push(const SteadyEditor()),
      icon: const Icon(LucideIcons.plus),
      tooltip: 'New habit',
    );
    return ClayScaffold(
      destinations: _places,
      selectedIndex: _place.index,
      onSelected: (i) => go(SteadyPlace.values[i]),
      brand: width >= ClayMetrics.sidebarBreakpoint
          ? const SteadyMark(withName: true)
          : const SteadyMark(),
      action: width >= ClayMetrics.sidebarBreakpoint
          ? ClayButton.filled(
              'New habit',
              icon: const Icon(LucideIcons.plus),
              onPressed: () => push(const SteadyEditor()),
            )
          : add,
      sideFooter: ClayGroup(
        children: [
          ClayListTile(
            leading: const SteadyAvatar(size: 36),
            title: steadyOwner.name,
            subtitle: clayPlural(
              context,
              habits.where((h) => !h.paused).length,
              one: '1 habit',
              other: '${habits.where((h) => !h.paused).length} habits',
            ),
            showChevron: false,
            semanticLabel: 'Account, ${steadyOwner.name}',
            onTap: () => go(SteadyPlace.settings),
          ),
        ],
      ),
      body: wide
          ? Navigator(
              key: _desk,
              pages: [MaterialPage<void>(key: ValueKey(_place), child: page)],
              onDidRemovePage: (_) {},
            )
          : ClayPlaceSwitch(
              place: _place,
              child: ColoredBox(color: theme.colors.ground, child: page),
            ),
    );
  }
}

/// Steady's mark: a small coral ball, its name beside it on a desk.
class SteadyMark extends StatelessWidget {
  /// The mark, with its name when [withName].
  const SteadyMark({super.key, this.withName = false});

  /// Whether the name stands beside it.
  final bool withName;

  @override
  Widget build(BuildContext context) {
    final theme = context.clayTheme;
    final ball = SizedBox.square(
      dimension: 32,
      child: ClaySurface(
        face: ClayFace.raised(
          theme.colors,
          color: theme.colors.accent,
          radius: 16,
        ),
        child: Center(
          child: Icon(
            LucideIcons.sprout,
            size: 18,
            color: theme.colors.onAccent,
          ),
        ),
      ),
    );
    if (!withName) return Semantics(label: 'Steady', child: ball);
    return Row(
      children: [
        ball,
        const SizedBox(width: ClaySpacing.medium),
        Text(
          'Steady',
          style: theme.textTheme.title.copyWith(color: theme.colors.ink),
        ),
      ],
    );
  }
}

/// A page of Steady: its top bar, then [children] in a column up to
/// [maxWidth], then a bar of [bottom] keys when given.
class SteadyPage extends StatelessWidget {
  /// A page titled [title].
  const SteadyPage({
    super.key,
    required this.title,
    required this.children,
    this.actions = const [],
    this.bottom,
    this.barBottom,
    this.large = false,
    this.maxWidth = ClayMetrics.readingWidth,
  });

  /// The page's name.
  final String title;

  /// What it holds.
  final List<Widget> children;

  /// Balls at the top bar's end.
  final List<Widget> actions;

  /// Keys along the page's foot.
  final Widget? bottom;

  /// Something under the title on the bar (a search field).
  final Widget? barBottom;

  /// Whether the title stands large.
  final bool large;

  /// The widest its column stands.
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final margin = ClaySpacing.pageMargin(width);
    final keys = width >= ClayMetrics.sidebarBreakpoint ? null : bottom;
    final route = ModalRoute.of(context);
    final canPop = route?.canPop ?? false;
    final pad = MediaQuery.paddingOf(context);
    final theme = context.clayTheme;
    return ColoredBox(
      color: theme.colors.ground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The bar stands over the column, so its keys end where the
          // column does.
          Align(
            alignment: AlignmentDirectional.topStart,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth + 2 * margin),
              child: ClayTopBar(
                title: title,
                large: large && !canPop,
                onBack: canPop ? () => Navigator.of(context).maybePop() : null,
                actions: [
                  ...actions,
                  if (bottom != null && keys == null) ...[
                    const SizedBox(width: ClaySpacing.small),
                    ClayTheme(
                      data: theme.copyWith(density: ClayDensity.compact),
                      child: bottom!,
                    ),
                  ],
                ],
                bottom: barBottom,
              ),
            ),
          ),
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: ListView(
                // Room above the first volume for its shadow, which the
                // scroll's edge would cut.
                padding: EdgeInsets.fromLTRB(
                  margin,
                  ClaySpacing.regular,
                  margin,
                  ClaySpacing.huge + (keys == null ? pad.bottom : 0),
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
          if (keys != null)
            Padding(
              padding: EdgeInsets.fromLTRB(
                margin,
                ClaySpacing.medium,
                margin,
                ClaySpacing.medium + pad.bottom,
              ),
              child: Align(
                alignment: AlignmentDirectional.topStart,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: keys,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The room between groups on a Steady page.
const steadyGroupGap = SizedBox(height: ClaySpacing.large);

/// A page's keys in its foot: on a phone the coral key fills the row, in
/// reach of a thumb, with [secondary] beside it; from 600 they take their own
/// widths at the row's end, the coral key last.
class SteadyKeys extends StatelessWidget {
  /// [primary], the page's one coral key, and [secondary] beside it.
  const SteadyKeys({super.key, required this.primary, this.secondary});

  /// The page's one coral key.
  final Widget primary;

  /// A quieter key beside it.
  final Widget? secondary;

  @override
  Widget build(BuildContext context) {
    final extra = secondary;
    final width = MediaQuery.sizeOf(context).width;
    if (width < 600) {
      if (extra != null && MediaQuery.textScalerOf(context).scale(1) >= 1.5) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            extra,
            const SizedBox(height: ClaySpacing.small),
            primary,
          ],
        );
      }
      return Row(
        children: [
          if (extra != null) ...[
            extra,
            const SizedBox(width: ClaySpacing.medium),
          ],
          Expanded(child: primary),
        ],
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: width >= ClayMetrics.sidebarBreakpoint
          ? MainAxisSize.min
          : MainAxisSize.max,
      children: [
        if (extra != null) ...[
          extra,
          const SizedBox(width: ClaySpacing.medium),
        ],
        primary,
      ],
    );
  }
}

/// The person's initials on a lilac ball.
class SteadyAvatar extends StatelessWidget {
  /// An avatar [size] across.
  const SteadyAvatar({super.key, this.size = 44});

  /// Its diameter.
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = context.clayTheme;
    final fill = theme.colors.tint(ClayTint.lilac);
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: ClaySurface(
          face: ClayFace.raised(theme.colors, color: fill, radius: size / 2),
          child: Center(
            child: Text(
              steadyOwner.name.split(' ').map((w) => w[0]).join(),
              textScaler: TextScaler.noScaling,
              style: theme.textTheme.label.copyWith(
                fontSize: size * 0.36,
                color: theme.colors.onColor(fill),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A habit's row that a checkbox ends: the whole row ticks it, and a screen
/// reader hears one checkbox named by the row.
class SteadyHabitRow extends StatelessWidget {
  /// A row for [habit].
  const SteadyHabitRow({
    super.key,
    required this.habit,
    required this.onTick,
    this.onOpen,
  });

  /// The habit.
  final SteadyHabit habit;

  /// Called to tick it.
  final VoidCallback onTick;

  /// Called to open its page.
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = context.clayTheme;
    // A counted habit (eight glasses) is no yes or no: each tap logs one,
    // and its ring fills toward the day's goal.
    final counted = habit.goal > 1;
    return MergeSemantics(
      child: ClayListTile(
        onTap: onTick,
        leading: ClayIconTile(tint: habit.tint, child: Icon(habit.icon)),
        title: habit.name,
        subtitle: habit.today,
        // A yes-or-no habit's row is its checkbox; a counted one's logs one.
        checked: counted ? null : habit.done,
        semanticLabel: counted && !habit.done
            ? '${habit.name}, ${habit.today}, log one'
            : null,
        showChevron: false,
        trailing: counted
            ? ExcludeSemantics(
                child: SizedBox.square(
                  dimension: 48,
                  child: Center(
                    child: ClayProgressRing(
                      // Big and thick enough to read at a glance, by day
                      // and by night: the row's main control.
                      value: habit.progress / habit.goal,
                      size: 40,
                      thickness: 5,
                      child: Icon(
                        habit.done ? LucideIcons.check : LucideIcons.plus,
                        size: 16,
                        color: theme.colors.ink,
                      ),
                    ),
                  ),
                ),
              )
            : ExcludeFocus(
                child: ClayCheckbox(
                  value: habit.done,
                  onChanged: (_) => onTick(),
                ),
              ),
      ),
    );
  }
}

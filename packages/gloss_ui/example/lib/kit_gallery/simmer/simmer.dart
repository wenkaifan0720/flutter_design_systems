/// Simmer, a week of dinners set in Gloss: the look's Overview, then Today,
/// Recipes, the shopping List and Settings, moved between by the look's own
/// navigation (the bottom bar on a phone, the rail from 600, the sidebar
/// from 1024).
library;

import 'package:material_ui/material_ui.dart';
import 'package:gloss_ui/gloss_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';
import 'data.dart';
import 'home.dart';
import 'overview.dart';
import 'planner.dart';
import 'recipes.dart';
import 'search.dart';
import 'settings.dart';
import 'shopping.dart';

/// Simmer's places, in the navigation's order.
enum SimmerPlace {
  /// The look's pitch.
  overview,

  /// Tonight and the week.
  home,

  /// Every recipe, with filters.
  recipes,

  /// The shopping list.
  shopping,

  /// The person's settings.
  settings,
}

/// A screen opened over a place, for a link or a test.
enum SimmerScene {
  /// A recipe's page.
  recipe,

  /// The recipes' filter sheet.
  filter,

  /// The week planner.
  planner,

  /// The week planner, asking to clear the week.
  deletePlan,

  /// Search, with results.
  search,

  /// Search that finds nothing.
  searchNone,

  /// The shopping list after a failed sync.
  syncFailed,

  /// The shopping list with nothing planned.
  emptyList;

  /// The place it opens over.
  SimmerPlace get place => switch (this) {
    recipe || filter => SimmerPlace.recipes,
    planner || deletePlan || search || searchNone => SimmerPlace.home,
    syncFailed || emptyList => SimmerPlace.shopping,
  };
}

/// From this window width the recipes and the chosen one stand side by
/// side.
const simmerSplitWidth = 1280.0;

/// Light, dark, or the system's.
enum SimmerAppearance {
  /// By day.
  light,

  /// By night.
  dark,

  /// As the system is.
  system,
}

/// What a person sets in Settings.
class SimmerPrefs extends ChangeNotifier {
  /// Settings at [appearance], in [direction], at [density].
  SimmerPrefs({
    this.appearance = SimmerAppearance.light,
    this.direction = TextDirection.ltr,
    this.density = GlossDensity.standard,
  });

  /// Light, dark or the system's.
  SimmerAppearance appearance;

  /// The words' direction.
  TextDirection direction;

  /// How tight the controls stand.
  GlossDensity density;

  /// The diets recipes are filtered to.
  final Set<String> diets = {'Vegetarian'};

  /// Units for amounts.
  String units = 'metric';

  /// How many the week's dinners are cooked for.
  int household = 2;

  /// Reminders before cooking.
  bool reminders = true;

  /// A note when the list is ready.
  bool listReady = true;

  /// New recipes each week.
  bool newRecipes = false;

  /// Changes the settings and tells the app.
  void update(void Function(SimmerPrefs prefs) change) {
    change(this);
    notifyListeners();
  }

  /// The settings above [context].
  static SimmerPrefs of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SimmerScope>()!.notifier!;
}

class _SimmerScope extends InheritedNotifier<SimmerPrefs> {
  const _SimmerScope({required SimmerPrefs prefs, required super.child})
    : super(notifier: prefs);
}

class _SimmerFrameScope extends InheritedWidget {
  const _SimmerFrameScope({required this.frame, required super.child});

  final GlobalKey<SimmerFrameState> frame;

  @override
  bool updateShouldNotify(_SimmerFrameScope old) => old.frame != frame;
}

/// One page of the gallery: its title and how to build it.
typedef SimmerPart = ({String title, Widget Function(Brightness) build});

/// Simmer, opened on [initialPlace].
class SimmerApp extends StatefulWidget {
  /// The app.
  const SimmerApp({
    super.key,
    this.initialPlace = SimmerPlace.overview,
    this.initialScene,
    this.initialAppearance = SimmerAppearance.light,
    this.initialDirection = TextDirection.ltr,
    this.initialDensity,
    this.textScale,
    this.parts = const [],
    this.initialPart,
  });

  /// The place it opens on.
  final SimmerPlace initialPlace;

  /// A screen it opens over that place.
  final SimmerScene? initialScene;

  /// Light, dark or the system's, to start.
  final SimmerAppearance initialAppearance;

  /// The words' direction, to start.
  final TextDirection initialDirection;

  /// The density, to start; standard when null.
  final GlossDensity? initialDensity;

  /// The words' scale, as a factor; the system's when null.
  final double? textScale;

  /// The gallery's pages, listed on the Overview.
  final List<SimmerPart> parts;

  /// A gallery page it opens on.
  final int? initialPart;

  @override
  State<SimmerApp> createState() => _SimmerAppState();
}

class _SimmerAppState extends State<SimmerApp> {
  late final SimmerPrefs _prefs = SimmerPrefs(
    appearance: widget.initialAppearance,
    direction: widget.initialDirection,
    density: widget.initialDensity ?? GlossDensity.standard,
  );
  final _frame = GlobalKey<SimmerFrameState>();

  @override
  void dispose() {
    _prefs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _prefs,
    builder: (context, _) {
      final frame = SimmerFrame(
        key: _frame,
        initialPlace: widget.initialPlace,
        initialScene: widget.initialScene,
        parts: widget.parts,
        initialPart: widget.initialPart,
      );
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Simmer',
        theme: ThemeData(
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: glossPageTransitions,
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
        onGenerateRoute: (_) => MaterialPageRoute<void>(builder: (_) => frame),
        builder: (context, child) {
          final platform = MediaQuery.platformBrightnessOf(context);
          final brightness = switch (_prefs.appearance) {
            SimmerAppearance.light => Brightness.light,
            SimmerAppearance.dark => Brightness.dark,
            SimmerAppearance.system => platform,
          };
          Widget app = AnimatedGlossTheme(
            data: GlossThemeData.jade(brightness, density: _prefs.density),
            child: KitGalleryScope(
              child: GlossToaster(child: child ?? const SizedBox.shrink()),
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
          return _SimmerScope(
            prefs: _prefs,
            child: _SimmerFrameScope(
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

/// Simmer's frame: the place shown and the navigation round it.
class SimmerFrame extends StatefulWidget {
  /// The frame, on [initialPlace].
  const SimmerFrame({
    super.key,
    this.initialPlace = SimmerPlace.overview,
    this.initialScene,
    this.parts = const [],
    this.initialPart,
  });

  /// The place it opens on.
  final SimmerPlace initialPlace;

  /// A screen it opens over that place.
  final SimmerScene? initialScene;

  /// The gallery's pages.
  final List<SimmerPart> parts;

  /// A gallery page it opens on.
  final int? initialPart;

  /// The frame above [context].
  static SimmerFrameState of(BuildContext context) =>
      context.findAncestorStateOfType<SimmerFrameState>() ??
      context
          .getInheritedWidgetOfExactType<_SimmerFrameScope>()!
          .frame
          .currentState!;

  @override
  State<SimmerFrame> createState() => SimmerFrameState();
}

/// The frame's state: where it is, and how to go elsewhere.
class SimmerFrameState extends State<SimmerFrame> {
  late SimmerPlace _place = widget.initialPlace;
  late SimmerScene? _scene = widget.initialScene;
  final _desk = GlobalKey<NavigatorState>();

  /// Planned recipe IDs, one per day. A null entry is a night off.
  final List<String?> week = [...simmerWeek];

  /// Groceries shared by Today, the planner and the shopping list.
  late List<SimmerItem> shoppingItems =
      widget.initialScene == SimmerScene.emptyList ? [] : simmerShopping();

  /// Changes one dinner in the week.
  void planDinner(int day, String? recipe) =>
      setState(() => week[day] = recipe);

  /// Replaces all seven dinners, including nights off.
  void replaceWeek(List<String?> dinners) =>
      setState(() => week.setAll(0, dinners));

  /// Opens the shopping list made from the current week.
  void makeShoppingList(int servings) {
    shoppingItems = simmerShoppingFor(week, servings, shoppingItems);
    go(SimmerPlace.shopping);
  }

  @override
  void initState() {
    super.initState();
    final Widget? opened = switch (_scene) {
      SimmerScene.recipe => SimmerRecipePage(
        recipe: simmerRecipe('miso-aubergine'),
      ),
      SimmerScene.planner => const SimmerPlanner(),
      SimmerScene.deletePlan => const SimmerPlanner(confirmClear: true),
      SimmerScene.search => const SimmerSearch(initialQuery: 'lemon'),
      SimmerScene.searchNone => const SimmerSearch(initialQuery: 'quince'),
      _ => null,
    };
    if (opened != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        // On a desk the recipes list shows the recipe beside it instead.
        final beside =
            _scene == SimmerScene.recipe &&
            _place == SimmerPlace.recipes &&
            MediaQuery.sizeOf(context).width >= simmerSplitWidth;
        if (!beside) push(opened);
      });
    }
    final part = widget.initialPart;
    if (part != null && part >= 0 && part < widget.parts.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          push(widget.parts[part].build(context.glossTheme.brightness));
        }
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
  void go(SimmerPlace place) => setState(() {
    _place = place;
    _scene = null;
  });

  static const _places = [
    GlossDestination(icon: LucideIcons.sparkles, label: 'Gloss'),
    GlossDestination(icon: LucideIcons.house, label: 'Today'),
    GlossDestination(icon: LucideIcons.bookOpen, label: 'Recipes'),
    GlossDestination(icon: LucideIcons.shoppingBasket, label: 'List'),
    GlossDestination(icon: LucideIcons.settings, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = context.glossTheme;
    final width = MediaQuery.sizeOf(context).width;
    final page = switch (_place) {
      SimmerPlace.overview => SimmerOverview(parts: widget.parts),
      SimmerPlace.home => const SimmerHome(),
      SimmerPlace.recipes => SimmerRecipes(
        showFilter: _scene == SimmerScene.filter,
        selected: _scene == SimmerScene.recipe ? 'miso-aubergine' : null,
      ),
      SimmerPlace.shopping => SimmerShopping(
        initialState: switch (_scene) {
          SimmerScene.syncFailed => SimmerListState.failed,
          SimmerScene.emptyList => SimmerListState.empty,
          _ => SimmerListState.ready,
        },
      ),
      SimmerPlace.settings => const SimmerSettings(),
    };
    return GlossScaffold(
      destinations: _places,
      selectedIndex: _place.index,
      onSelected: (i) => go(SimmerPlace.values[i]),
      brand: width >= 1024
          ? const Text('Simmer')
          : Text(
              'S',
              style: glossLetterpress(theme.textTheme.headline, theme.colors),
            ),
      // The account is a row in a well at the sidebar's foot: pressable,
      // but not a raised plate, which is the current place's alone.
      sideFooter: GlossWell(
        children: [
          GlossListTile(
            leading: const SimmerAvatar(size: 32),
            title: simmerOwner.name,
            subtitle: glossPlural(
              context,
              week.whereType<String>().length,
              one: 'This week: 1 dinner',
              other: 'This week: ${week.whereType<String>().length} dinners',
            ),
            showChevron: false,
            semanticLabel: 'Account, ${simmerOwner.name}',
            onTap: () => go(SimmerPlace.settings),
          ),
        ],
      ),
      body: wide
          ? Navigator(
              key: _desk,
              pages: [MaterialPage<void>(key: ValueKey(_place), child: page)],
              onDidRemovePage: (_) {},
            )
          : GlossPlaceSwitch(place: _place, child: page),
    );
  }
}

/// A page of Simmer: its top bar, then [children] in a column up to
/// [maxWidth], then a [bottom] bar of keys when given.
class SimmerPage extends StatelessWidget {
  /// A page titled [title].
  const SimmerPage({
    super.key,
    required this.title,
    required this.children,
    this.actions = const [],
    this.bottom,
    this.barBottom,
    this.large = false,
    this.maxWidth = GlossMetrics.readingWidth,
  });

  /// The page's name.
  final String title;

  /// What it holds.
  final List<Widget> children;

  /// Glyphs at the top bar's end.
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
    final margin = GlossSpacing.pageMargin(width);
    // On a desk the page's keys stand in its title strip, the gel key at
    // its end; on a phone and a tablet they are a bar at the foot.
    final keys = width >= GlossMetrics.sidebarBreakpoint ? null : bottom;
    final route = ModalRoute.of(context);
    final canPop = route?.canPop ?? false;
    final pad = MediaQuery.paddingOf(context);
    return ColoredBox(
      color: context.glossTheme.colors.page,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlossTopBar(
            title: title,
            large: large && !canPop,
            onBack: canPop ? () => Navigator.of(context).maybePop() : null,
            actions: [
              ...actions,
              if (bottom != null && keys == null) ...[
                const SizedBox(width: GlossSpacing.small),
                // In the strip the keys are a desk's: compact, standing
                // inside the strip's height with room round them.
                GlossTheme(
                  data: context.glossTheme.copyWith(
                    density: GlossDensity.compact,
                  ),
                  child: bottom!,
                ),
              ],
            ],
            bottom: barBottom,
          ),
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  margin,
                  GlossSpacing.large,
                  margin,
                  GlossSpacing.huge + (keys == null ? pad.bottom : 0),
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
            GlossBar(
              edge: AxisDirection.up,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  margin,
                  GlossSpacing.medium,
                  margin,
                  GlossSpacing.medium + pad.bottom,
                ),
                child: Align(
                  alignment: AlignmentDirectional.topStart,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: keys,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The room between groups on a Simmer page.
const simmerGroupGap = SizedBox(height: GlossSpacing.extraLarge);

/// A page's keys in its bottom bar: on a phone the gel key fills the bar,
/// in reach of a thumb, with [secondary] beside it; from 600 they take their
/// own widths at the bar's end, the gel key last.
class SimmerKeys extends StatelessWidget {
  /// [primary], the page's one gel key, and [secondary] beside it.
  const SimmerKeys({super.key, required this.primary, this.secondary});

  /// The page's one gel key.
  final Widget primary;

  /// A quieter key beside it.
  final Widget? secondary;

  @override
  Widget build(BuildContext context) {
    final extra = secondary;
    final width = MediaQuery.sizeOf(context).width;
    if (width < 600) {
      // Large words: the gel key keeps the bar's whole width, the quieter
      // key a row of its own above it.
      if (extra != null && MediaQuery.textScalerOf(context).scale(1) >= 1.5) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            extra,
            const SizedBox(height: GlossSpacing.small),
            primary,
          ],
        );
      }
      return Row(
        children: [
          Expanded(child: primary),
          if (extra != null) ...[
            const SizedBox(width: GlossSpacing.small),
            extra,
          ],
        ],
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      // On a desk the keys stand in the title strip, as wide as they are.
      mainAxisSize: width >= GlossMetrics.sidebarBreakpoint
          ? MainAxisSize.min
          : MainAxisSize.max,
      children: [
        if (extra != null) ...[
          extra,
          const SizedBox(width: GlossSpacing.small),
        ],
        primary,
      ],
    );
  }
}

/// The person's initials on a pearl bead.
class SimmerAvatar extends StatelessWidget {
  /// An avatar [size] across.
  const SimmerAvatar({super.key, this.size = 44});

  /// Its diameter.
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = context.glossTheme;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: GlossSurface(
          face: GlossFace.pearl(theme.colors),
          child: Center(
            child: Text(
              // The owner's initials.
              simmerOwner.name.split(' ').map((w) => w[0]).join(),
              textScaler: TextScaler.noScaling,
              style: theme.textTheme.label.copyWith(
                fontSize: size * 0.36,
                color: theme.colors.jadeInk,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Minutes as a cook says them: `35 min`, `1 h 10 min`.
String simmerMinutes(int minutes) => minutes < 60
    ? '$minutes min'
    : minutes % 60 == 0
    ? '${minutes ~/ 60} h'
    : '${minutes ~/ 60} h ${minutes % 60} min';

/// The duration and cuisine of a recipe in Simmer's English-language catalog.
String simmerRecipeSummary(BuildContext context, SimmerRecipe recipe) {
  final duration = simmerMinutes(recipe.minutes);
  if (Directionality.of(context) == TextDirection.rtl) {
    return '\u2066${duration.replaceAll(' ', '\u00a0')} · ${recipe.cuisine}\u2069';
  }
  return '$duration · ${recipe.cuisine}';
}

/// A row a checkbox leads: the whole row ticks it, as a finger expects, and a
/// screen reader hears one checkbox named by the row.
class SimmerCheckRow extends StatelessWidget {
  /// A row ticked at [value].
  const SimmerCheckRow({
    super.key,
    required this.value,
    required this.onChanged,
    required this.title,
    this.trailingText,
    this.style,
  });

  /// Whether it is ticked.
  final bool value;

  /// Called with the new value when the row is tapped.
  final ValueChanged<bool> onChanged;

  /// The row's words.
  final String title;

  /// A quantity at the row's end.
  final String? trailingText;

  /// The row's style.
  final GlossStyle? style;

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: GlossListTile(
      onTap: () => onChanged(!value),
      leading: ExcludeFocus(
        child: GlossCheckbox(
          value: value,
          onChanged: (v) => onChanged(v ?? false),
        ),
      ),
      title: title,
      trailingText: trailingText,
      showChevron: false,
      style: style,
    ),
  );
}

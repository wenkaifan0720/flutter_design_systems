/// The trip planner: the example's small app, built from the look's parts
/// the way a team would build its own. Home (the next trip), Plan (the
/// trip's details), Shared with you (what the group shares), Kit (the hike
/// kit's checkout) and Preferences; the navigation bar on a phone, the rail
/// from 600dp (expanded from 1200dp), and a list beside its detail, a form
/// beside its summary and a basket beside its total where the window has
/// room.
library;

import 'package:material_ui/material_ui.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';

import 'trip_words.dart';

export 'trip_words.dart' show TripWords, tripArabicDelegates;

/// The trip planner's screens, by the example's page ids.
abstract final class TripScreens {
  /// Home: the next trip.
  static const String home = 'everyday-home';

  /// Plan: the trip's details, a form.
  static const String plan = 'everyday-form';

  /// Shared with you: what the group shares, a list.
  static const String shared = 'everyday-list';

  /// Kit: the hike kit's checkout.
  static const String kit = 'everyday-checkout';

  /// Preferences: the settings.
  static const String preferences = 'everyday-settings';

  /// Every screen, Home first.
  static const List<String> all = [home, plan, shared, kit, preferences];

  /// A screen's visible title, in English.
  static String title(String id) => titleIn(const TripWords(), id);

  /// A screen's visible title in [words].
  static String titleIn(TripWords words, String id) => switch (id) {
    plan => words.planTitle,
    shared => words.sharedTitle,
    kit => words.kitTitle,
    preferences => words.preferencesTitle,
    _ => words.homeTitle,
  };
}

/// The way back to the gallery the trip planner carries in its bar's menu,
/// with the gallery's light and dark and Customize, so a preset can be
/// tried on the app.
typedef TripGalleryLinks = ({
  VoidCallback exit,
  VoidCallback toggleBrightness,
  VoidCallback customize,
  bool dark,
});

/// The day the example's trip is planned from, fixed so the figures (31
/// days to go, the delivery dates) agree in every capture.
final DateTime tripToday = DateTime(2026, 11, 10);

/// The trip planner, opened on [screen] (one of [TripScreens.all]). It
/// tells [onScreenChanged] each screen it moves to, so a host can keep a
/// linkable route; [gallery] adds the way back to the gallery.
class TripApp extends StatefulWidget {
  /// The trip planner on [screen].
  const TripApp({
    this.screen = TripScreens.home,
    this.onScreenChanged,
    this.gallery,
    super.key,
  });

  /// The screen on show.
  final String screen;

  /// Told the screen the app moved to.
  final ValueChanged<String>? onScreenChanged;

  /// The way back to the gallery; none when the app stands alone.
  final TripGalleryLinks? gallery;

  @override
  State<TripApp> createState() => _TripAppState();
}

const List<String> _tabScreens = [
  TripScreens.home,
  TripScreens.shared,
  TripScreens.kit,
  TripScreens.preferences,
];

List<NavTab> _tabs(TripWords w) => [
  NavTab(
    icon: ExpressiveSymbols.home,
    label: w.tabHome,
    location: '/home',
    key: const ValueKey('trip-tab-home'),
  ),
  NavTab(
    icon: ExpressiveSymbols.group,
    label: w.tabShared,
    location: '/shared',
    key: const ValueKey('trip-tab-shared'),
  ),
  NavTab(
    icon: ExpressiveSymbols.hiking,
    label: w.tabKit,
    location: '/kit',
    key: const ValueKey('trip-tab-kit'),
  ),
  NavTab(
    icon: ExpressiveSymbols.settings,
    label: w.tabPreferences,
    location: '/preferences',
    key: const ValueKey('trip-tab-preferences'),
  ),
];

class _TripAppState extends State<TripApp> {
  final _trip = _Trip();
  late String _screen = widget.screen;
  String? _open;

  @override
  void initState() {
    super.initState();
    _trip.addListener(_tripChanged);
  }

  /// An item opening or closing on one pane moves the shell's bar.
  void _tripChanged() {
    if (_trip.openItem != _open) setState(() => _open = _trip.openItem);
  }

  @override
  void didUpdateWidget(TripApp old) {
    super.didUpdateWidget(old);
    if (widget.screen != old.screen && widget.screen != _screen) {
      _screen = widget.screen;
    }
  }

  @override
  void dispose() {
    _trip.dispose();
    super.dispose();
  }

  void _go(String screen) {
    if (screen == _screen) return;
    setState(() => _screen = screen);
    widget.onScreenChanged?.call(screen);
  }

  int get _tab {
    final i = _tabScreens.indexOf(_screen);
    // Plan opens from Home and stands under its tab.
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context) {
    final w = TripWords.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final rail = width >= ExpressiveChromeMetrics.railMinWindowWidth;
    final shared = _trip.openItem;
    // A pushed page (the form; a shared item's detail on one pane) yields
    // the phone's bar, as a page pushed over a branch root does.
    final pushed =
        _screen == TripScreens.plan ||
        (_screen == TripScreens.shared && shared != null && width < _twoPanes);
    return _TripScope(
      trip: _trip,
      go: _go,
      gallery: widget.gallery,
      child: ExpressiveShellScaffold(
        tabs: _tabs(w),
        selectedIndex: _tab,
        onDestinationSelected: (i) => _go(_tabScreens[i]),
        barVisible: !pushed,
        // From 600dp "add to this trip" stands in the rail's header, the
        // one FAB of every screen; on a phone Home holds it, as its FAB
        // menu, and Shared with you its own.
        action: rail
            ? ExpressiveShellAction(
                icon: ExpressiveSymbols.add,
                semanticLabel: w.addToTrip,
                onPressed: (context) => _addMenu(context, _trip, _go),
              )
            : null,
        accessory: !rail && _screen == TripScreens.kit
            ? const _CheckoutBar()
            : null,
        body: KeyedSubtree(
          key: ValueKey('trip/$_screen'),
          child: switch (_screen) {
            TripScreens.plan => const _PlanScreen(),
            TripScreens.shared => const _SharedScreen(),
            TripScreens.kit => const _KitScreen(),
            TripScreens.preferences => const _PreferencesScreen(),
            _ => const _HomeScreen(),
          },
        ),
      ),
    );
  }
}

/// The body width from which a list stands beside its detail, a form
/// beside its summary and a basket beside its total.
const double _twoPanes = 840;

// ---------------------------------------------------------------------------
// The trip, shared by every screen.

/// One thing the group shares: its id, group, name, line, glyph and facts.
typedef _Item = ({
  String id,
  String group,
  String name,
  String line,
  IconData icon,
  List<(String, String)> facts,
});

class _Trip extends ChangeNotifier {
  /// The trip's name as the group gave it; none keeps the planner's own
  /// ([TripWords.tripName]), in the reader's language.
  String? name;
  DateTime leave = DateTime(2026, 12, 11);
  DateTime back = DateTime(2026, 12, 13);
  String stay = 'kirk-creek';
  bool remind = true;

  /// The packing list: eight of twelve packed; three of the four left are
  /// what the hike kit buys.
  final packing = <String, bool>{
    'Tent': true,
    'Sleeping bags': true,
    'Camp stove': true,
    'Water filter': true,
    'Rain jackets': true,
    'First-aid kit': true,
    'Trail snacks': true,
    'Sunscreen': true,
    'Trail map': false,
    'Water bottles': false,
    'Headlamps': false,
    'Firewood': false,
  };

  final quantities = <String, int>{'map': 1, 'bottle': 2, 'headlamp': 1};
  String delivery = 'standard';
  bool promo = false;
  ({String last4, String expiry}) card = (last4: '4242', expiry: '08/28');
  bool ordered = false;

  bool reminders = true;
  bool digest = true;
  String frequency = 'weekly';
  String density = 'comfortable';
  bool sounds = true;
  double volume = .6;

  final added = <_Item>[];
  String? openItem;

  void update(VoidCallback change) {
    change();
    notifyListeners();
  }

  int get packed => packing.values.where((v) => v).length;

  int get daysToGo => DateTime.utc(leave.year, leave.month, leave.day)
      .difference(DateTime.utc(tripToday.year, tripToday.month, tripToday.day))
      .inDays;

  int get nights => DateTime.utc(
    back.year,
    back.month,
    back.day,
  ).difference(DateTime.utc(leave.year, leave.month, leave.day)).inDays;

  String nameIn(TripWords w) => name ?? w.tripName;

  String datesIn(TripWords w) => w.range(leave, back);

  int get subtotal =>
      _products.fold(0, (sum, p) => sum + p.price * (quantities[p.id] ?? 0));
  int get things => quantities.values.fold(0, (a, b) => a + b);
  int get shipping => delivery == 'express' ? 900 : 0;
  int get saving => promo ? (subtotal / 10).round() : 0;
  int get total => subtotal + shipping - saving;

  List<_Item> itemsIn(TripWords w) => [..._shared(this, w), ...added];
}

/// The places to stay, by id; [TripWords.stay] names them.
const _stays = ['kirk-creek', 'treebones', 'lodge'];

/// The groups, by id; [TripWords.group] names them.
const _groups = ['Bookings', 'Lists', 'Guides'];

List<_Item> _shared(_Trip trip, TripWords w) => [
  for (final (id, group, icon) in const [
    ('car', 'Bookings', ExpressiveSymbols.directionsCar),
    ('camp', 'Bookings', ExpressiveSymbols.bed),
    ('packing', 'Lists', ExpressiveSymbols.checklist),
    ('eat', 'Lists', ExpressiveSymbols.restaurant),
    ('guide', 'Guides', ExpressiveSymbols.map),
    ('trails', 'Guides', ExpressiveSymbols.hiking),
  ])
    _sharedItem(id, group, icon, trip, w),
];

_Item _sharedItem(
  String id,
  String group,
  IconData icon,
  _Trip trip,
  TripWords w,
) {
  final words = w.item(
    id,
    leave: trip.leave,
    back: trip.back,
    nights: trip.nights,
    packed: trip.packed,
    all: trip.packing.length,
  );
  return (
    id: id,
    group: group,
    name: words.name,
    line: words.line,
    icon: icon,
    facts: words.facts,
  );
}

/// A product of the hike kit; [TripWords.product] names it.
typedef _Product = ({String id, IconData icon, int price});

const List<_Product> _products = [
  (id: 'map', icon: ExpressiveSymbols.map, price: 1200),
  (id: 'bottle', icon: ExpressiveSymbols.waterDrop, price: 1800),
  (id: 'headlamp', icon: ExpressiveSymbols.bolt, price: 3400),
];

class _TripScope extends InheritedNotifier<_Trip> {
  const _TripScope({
    required _Trip trip,
    required this.go,
    required this.gallery,
    required super.child,
  }) : super(notifier: trip);

  final ValueChanged<String> go;
  final TripGalleryLinks? gallery;

  static _TripScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_TripScope>()!;

  static _Trip trip(BuildContext context) => of(context).notifier!;

  /// The trip, without listening: for a state's first values.
  static _Trip read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_TripScope>()!.notifier!;
}

// ---------------------------------------------------------------------------
// The parts every screen shares.

/// A thing's mark (a booking, a list, a product): its glyph in a tonal
/// container of the shape scale's medium corner, the same for every kind
/// of thing across the app; people keep the avatar's circle.
Widget _thing(BuildContext context, String name, IconData icon, String group) {
  final t = context.expressiveTheme;
  return ExcludeSemantics(
    child: ExpressiveAvatar(
      name: name,
      icon: icon,
      tone: switch (group) {
        'Bookings' => ExpressiveMediaTone.tertiary,
        'Guides' => ExpressiveMediaTone.primary,
        _ => ExpressiveMediaTone.secondary,
      },
      style: ExpressiveComponentThemeData(
        shape: WidgetStatePropertyAll(t.shapes.medium),
      ),
    ),
  );
}

/// The screen's side margin: 16dp on a phone, 24dp from 600dp.
double _margin(double width) => width >= 600 ? 24 : 16;

/// A screen of the app: its bar (with the way back to the gallery in its
/// menu) over [body], which stands in a column [measure] wide at most. Every
/// screen keeps one frame: the bar's title and the column start on the
/// screen's margin (beside the rail from 600dp), so going between
/// destinations moves neither; a narrower column ends sooner.
class _Screen extends StatelessWidget {
  const _Screen({
    required this.title,
    required this.body,
    this.subtitle,
    this.leading,
    this.actions = const [],
    this.floating,
    this.measure,
    this.scroll = true,
  });

  final String title;

  /// A line under the title: what the screen is about, said once in the
  /// bar rather than as a sentence at the top of the page.
  final String? subtitle;
  final Widget body;
  final Widget? leading;
  final List<Widget> actions;
  final Widget? floating;
  final double? measure;
  final bool scroll;

  /// The screen's content column, for a test to measure.
  static const Key column = ValueKey('trip-column');

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    // The body's width, not the window's: beside a rail the screen is
    // narrower than the window.
    builder: (context, constraints) => _build(context, constraints.maxWidth),
  );

  Widget _build(BuildContext context, double width) {
    final scope = _TripScope.of(context);
    final w = TripWords.of(context);
    final media = MediaQuery.of(context);
    final margin = _margin(width);
    final gallery = scope.gallery;
    final measure = this.measure;
    // The bar's title starts on the margin, as the column does (less the
    // 16dp the title already stands in).
    final inset = leading == null ? margin - 16 : 0.0;
    final bar = ExpressiveAppBar(
      title: title,
      subtitle: subtitle,
      leading: leading,
      actions: actions,
      overflow: [
        if (gallery != null) ...[
          ExpressiveMenuItem(
            w.backToGallery,
            icon: ExpressiveSymbols.apps,
            onPressed: gallery.exit,
          ),
          ExpressiveMenuItem(
            gallery.dark ? w.lightTheme : w.darkTheme,
            icon: gallery.dark
                ? ExpressiveSymbols.lightMode
                : ExpressiveSymbols.darkMode,
            onPressed: gallery.toggleBrightness,
          ),
          ExpressiveMenuItem(
            w.customize,
            icon: ExpressiveSymbols.tune,
            onPressed: gallery.customize,
          ),
        ],
      ],
    );
    // A page that scrolls takes its margins from the scaffold; one whose
    // panes scroll for themselves stands in them here.
    final content = measure == null
        ? Padding(
            padding: scroll
                ? EdgeInsets.zero
                : EdgeInsets.fromLTRB(margin, 8, margin, 0),
            child: KeyedSubtree(key: column, child: body),
          )
        : Align(
            alignment: AlignmentDirectional.topStart,
            child: ConstrainedBox(
              key: column,
              constraints: BoxConstraints(maxWidth: measure),
              child: body,
            ),
          );
    // A branch root leaves the bottom edge to the shell, so a FAB there
    // stands over the page, above the bar, and the page scrolls clear of it.
    final shell = ExpressiveShellInsets.of(context);
    final floating = this.floating;
    final overShell = floating != null && shell > 0;
    final page = ExpressiveScaffold(
      title: title,
      topBar: inset <= 0
          ? bar
          : MediaQuery(
              data: media.copyWith(
                padding: media.padding.copyWith(
                  left: media.padding.left + inset,
                  right: media.padding.right + inset,
                ),
              ),
              child: bar,
            ),
      floating: overShell ? null : floating,
      scroll: scroll,
      padding: EdgeInsets.fromLTRB(
        margin,
        8,
        margin,
        overShell ? 32 + ExpressiveChromeMetrics.fabClearance : 32,
      ),
      body: content,
    );
    if (!overShell) return page;
    return Stack(
      children: [
        Positioned.fill(child: page),
        PositionedDirectional(
          end: ExpressiveChromeMetrics.fabMargin + media.padding.right,
          bottom: shell + ExpressiveChromeMetrics.fabMargin,
          child: floating,
        ),
      ],
    );
  }
}

/// A section's title over [child], 8dp above it, for content that is not a
/// list section (which carries its own).
class _Headed extends StatelessWidget {
  const _Headed(this.title, {required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [ExpressiveSectionHeader(title), child],
  );
}

/// A line of a summary: [label] at the start, [value] at the end.
class _Line extends StatelessWidget {
  const _Line(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: t.type.bodyLarge.copyWith(color: t.colors.onSurfaceVariant),
          ),
        ),
        Text(
          value,
          style: t.type.bodyLarge.copyWith(
            color: t.colors.onSurface,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

/// The "add to this trip" choices: a booking, a list or a guide, each
/// named in a dialog and added to Shared with you ([TripWords.kind] names
/// them).
List<({String group, IconData icon})> get _addKinds => const [
  (group: 'Bookings', icon: ExpressiveSymbols.event),
  (group: 'Lists', icon: ExpressiveSymbols.checklist),
  (group: 'Guides', icon: ExpressiveSymbols.map),
];

Future<void> _add(
  BuildContext context,
  _Trip trip,
  ValueChanged<String> go,
  String group,
  IconData icon,
) async {
  final w = TripWords.read(context);
  final name = TextEditingController();
  final added = await showExpressiveDialog<bool>(
    context: context,
    builder: (context) => ExpressiveDialog(
      title: w.newKind(group),
      content: ExpressiveTextField(
        key: const ValueKey('trip-add-name'),
        controller: name,
        label: w.name,
        autofocus: true,
      ),
      actions: [
        ExpressiveDialogAction(w.cancel, value: false),
        ExpressiveDialogAction(w.add, value: true, filled: true),
      ],
    ),
  );
  final text = name.text.trim();
  name.dispose();
  if (added != true || text.isEmpty || !context.mounted) return;
  final id = 'added-${trip.added.length}';
  trip.update(
    () => trip.added.add((
      id: id,
      group: group,
      name: text,
      line: w.addedNow,
      icon: icon,
      facts: [(w.addedBy, w.you), (w.sharedWith, w.mayaAndSam)],
    )),
  );
  showExpressiveSnackBar(
    context,
    w.added(text),
    actionLabel: w.open,
    onAction: () {
      trip.update(() => trip.openItem = id);
      go(TripScreens.shared);
    },
  );
}

/// The rail's FAB: the same choices as the phone's FAB menu, as a menu at
/// the pointer's size (a FAB menu never stands beside a rail).
Future<void> _addMenu(
  BuildContext context,
  _Trip trip,
  ValueChanged<String> go,
) => showExpressiveMenu(
  context,
  label: TripWords.read(context).addToTrip,
  entries: [
    for (final k in _addKinds)
      ExpressiveMenuItem(
        TripWords.read(context).kind(k.group),
        icon: k.icon,
        onPressed: () => _add(context, trip, go, k.group, k.icon),
      ),
  ],
);

// ---------------------------------------------------------------------------
// Home: the next trip.

class _HomeScreen extends StatelessWidget {
  const _HomeScreen();

  @override
  Widget build(BuildContext context) {
    final scope = _TripScope.of(context);
    final trip = _TripScope.trip(context);
    final w = TripWords.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final phone = width < ExpressiveChromeMetrics.railMinWindowWidth;
    // The one hero moment of the app: the trip's figure, its packing
    // progress and, on a phone, the FAB menu that adds to it.
    return ExpressiveHeroMoment(
      label: 'next trip',
      child: _Screen(
        title: TripScreens.titleIn(w, TripScreens.home),
        actions: [
          ExpressiveAppBarAction(
            ExpressiveSymbols.edit,
            label: w.planTitle,
            onPressed: () => scope.go(TripScreens.plan),
          ),
        ],
        floating: phone
            ? ExpressiveFabMenu(
                icon: ExpressiveSymbols.add,
                semanticLabel: w.addToTrip,
                // The screen's floating slot already stands it 16dp in,
                // where the other screens' FAB stands.
                padded: false,
                items: [
                  for (final k in _addKinds)
                    ExpressiveFabMenuItem(
                      icon: k.icon,
                      label: w.kind(k.group),
                      onPressed: (context) =>
                          _add(context, trip, scope.go, k.group, k.icon),
                    ),
                ],
              )
            : null,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= _twoPanes;
            final card = _TripCard(trip: trip);
            final todo = _StillToDo(trip: trip, go: scope.go);
            final lately = _Lately(trip: trip, go: scope.go);
            if (!wide) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 24,
                children: [card, todo, lately],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 24,
              children: [
                Expanded(flex: 5, child: card),
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 24,
                    children: [todo, lately],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// The next trip: where and when, who goes, the days to go (the figure the
/// person came for) and how much is packed.
class _TripCard extends StatelessWidget {
  const _TripCard({required this.trip});

  final _Trip trip;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final c = t.colors;
    final w = TripWords.of(context);
    final packed = trip.packed;
    final all = trip.packing.length;
    // A card of its own: its lines share its keylines, not the page's.
    return DesignKeylineRegion(
      label: 'Next trip',
      child: ExpressiveSurface(
        key: const ValueKey('trip-card'),
        shape: t.shapes.extraLarge,
        color: c.primaryContainer,
        contentColor: c.onPrimaryContainer,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  w.nextTrip,
                  style: t.type.labelLarge.copyWith(
                    color: c.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  trip.nameIn(w),
                  style: t.type.headlineSmall.copyWith(
                    color: c.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  w.datesWithEveryone(trip.datesIn(w)),
                  style: t.type.bodyLarge.copyWith(color: c.onPrimaryContainer),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: MergeSemantics(
                key: const ValueKey('trip-days'),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  spacing: 12,
                  children: [
                    Text(
                      '${trip.daysToGo}',
                      style: t.type.displayLargeEmphasized.copyWith(
                        color: c.onPrimaryContainer,
                      ),
                    ),
                    Text(
                      w.daysToGo(trip.daysToGo),
                      style: t.type.titleLarge.copyWith(
                        color: c.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        w.packing,
                        style: t.type.titleSmall.copyWith(
                          color: c.onPrimaryContainer,
                        ),
                      ),
                    ),
                    Text(
                      w.packedOf(packed, all),
                      style: t.type.bodyMedium.copyWith(
                        color: c.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ExpressiveLinearProgressIndicator(
                  value: packed / all,
                  wavy: true,
                  expand: true,
                  // The track's secondaryContainer all but vanishes on the
                  // card's primaryContainer, and the page's surface was a
                  // groove at night: the card's content colour, faint.
                  trackColor: c.onPrimaryContainer.withValues(alpha: .2),
                  semanticLabel: w.packingProgress(packed, all),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StillToDo extends StatelessWidget {
  const _StillToDo({required this.trip, required this.go});

  final _Trip trip;
  final ValueChanged<String> go;

  @override
  Widget build(BuildContext context) {
    final w = TripWords.of(context);
    final left = trip.packing.length - trip.packed;
    return ExpressiveListSection(
      key: const ValueKey('trip-todo'),
      header: w.stillToDo,
      children: [
        ExpressiveListTile(
          key: const ValueKey('trip-todo-kit'),
          leading: _thing(
            context,
            w.hikeKit,
            ExpressiveSymbols.shoppingBag,
            'Lists',
          ),
          title: Text(trip.ordered ? w.hikeKitOrdered : w.buyHikeKit),
          subtitle: Text(
            trip.ordered
                ? w.kitArrives(w.day(_arrival(trip)))
                : '${w.things(trip.things)} · '
                      '${ExpressiveFormat.money(trip.total)}',
          ),
          onTap: () => go(TripScreens.kit),
        ),
        ExpressiveListTile(
          key: const ValueKey('trip-todo-packing'),
          leading: _thing(
            context,
            w.packingList,
            ExpressiveSymbols.checklist,
            'Lists',
          ),
          title: Text(w.finishPacking),
          subtitle: Text(w.leftToPack(left)),
          onTap: () {
            trip.update(() => trip.openItem = 'packing');
            go(TripScreens.shared);
          },
        ),
        ExpressiveListTile(
          key: const ValueKey('trip-todo-stay'),
          leading: _thing(
            context,
            w.stayThing,
            ExpressiveSymbols.bed,
            'Bookings',
          ),
          title: Text(w.checkStay),
          subtitle: Text('${w.stay(trip.stay)} · ${w.nights(trip.nights)}'),
          onTap: () => go(TripScreens.plan),
        ),
      ],
    );
  }
}

class _Lately extends StatelessWidget {
  const _Lately({required this.trip, required this.go});

  final _Trip trip;
  final ValueChanged<String> go;

  @override
  Widget build(BuildContext context) {
    final w = TripWords.of(context);
    final items = trip.itemsIn(w).where((i) => i.group != 'Lists').take(2);
    return ExpressiveListSection(
      header: w.sharedLately,
      children: [
        for (final item in items)
          ExpressiveListTile(
            leading: _thing(context, item.name, item.icon, item.group),
            title: Text(item.name),
            subtitle: Text(item.line),
            onTap: () {
              trip.update(() => trip.openItem = item.id);
              go(TripScreens.shared);
            },
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Plan: the trip's details.

class _PlanScreen extends StatefulWidget {
  const _PlanScreen();

  @override
  State<_PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<_PlanScreen> {
  late final _Trip _trip = _TripScope.read(context);
  late final _name = TextEditingController(
    text: _trip.nameIn(TripWords.read(context)),
  );
  late DateTime _leave = _trip.leave;
  late DateTime _back = _trip.back;
  late String _stay = _trip.stay;
  late bool _remind = _trip.remind;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _close() => _TripScope.of(context).go(TripScreens.home);

  void _save() {
    final w = TripWords.of(context);
    final name = _name.text.trim();
    _trip.update(() {
      // The planner's own name stays its own, in either language.
      if (name.isNotEmpty && name != _trip.nameIn(w)) _trip.name = name;
      _trip.leave = _leave;
      _trip.back = _back;
      _trip.stay = _stay;
      _trip.remind = _remind;
    });
    showExpressiveSnackBar(context, w.tripSaved);
    _close();
  }

  @override
  Widget build(BuildContext context) {
    final w = TripWords.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final phone = width < ExpressiveChromeMetrics.railMinWindowWidth;
    final nights = DateTime.utc(
      _back.year,
      _back.month,
      _back.day,
    ).difference(DateTime.utc(_leave.year, _leave.month, _leave.day)).inDays;
    final form = Column(
      key: const ValueKey('plan-form'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 24,
      children: [
        ExpressiveTextField(
          key: const ValueKey('plan-name'),
          controller: _name,
          label: w.tripNameLabel,
          textCapitalization: TextCapitalization.words,
        ),
        // Leaving and coming back are entered together: side by side at
        // every width, one above the other at large text (where two halves
        // of a phone's column cut their dates short).
        Flex(
          direction: _largeText(context) ? Axis.vertical : Axis.horizontal,
          crossAxisAlignment: _largeText(context)
              ? CrossAxisAlignment.stretch
              : CrossAxisAlignment.start,
          spacing: 16,
          children: [
            _Half(
              child: ExpressiveDockedDatePicker(
                key: const ValueKey('plan-leave'),
                label: w.leave,
                value: _leave,
                currentDate: tripToday,
                firstDate: tripToday,
                format: w.fieldDay,
                onChanged: (d) => setState(() {
                  _leave = d;
                  if (!_back.isAfter(d)) _back = d.add(const Duration(days: 1));
                }),
              ),
            ),
            _Half(
              child: ExpressiveDockedDatePicker(
                key: const ValueKey('plan-back'),
                label: w.returnDate,
                value: _back,
                currentDate: tripToday,
                firstDate: _leave.add(const Duration(days: 1)),
                format: w.fieldDay,
                onChanged: (d) => setState(() => _back = d),
              ),
            ),
          ],
        ),
        // A choice, not an entry: from 600dp as wide as its longest stay
        // needs (at least a field's 280dp, at most 320dp; the look's), at the
        // form's start, wider than a cell of the dates' grid when a stay's
        // name needs it; on a phone, the form's width.
        Row(
          children: [
            Flexible(
              fit: phone ? FlexFit.tight : FlexFit.loose,
              child: ExpressiveSelect<String>(
                key: const ValueKey('plan-stay'),
                label: w.whereYouStay,
                value: _stay,
                options: [
                  for (final id in _stays)
                    ExpressiveSelectOption(id, w.stay(id)),
                ],
                onChanged: (v) => setState(() => _stay = v),
              ),
            ),
          ],
        ),
        ExpressiveCheckboxRow(
          key: const ValueKey('plan-remind'),
          contentPadding: EdgeInsets.zero,
          label: w.remindEveryone,
          supportingText: w.remindLine(
            w.day(_leave.subtract(const Duration(days: 7))),
          ),
          value: _remind,
          onChanged: (v) => setState(() => _remind = v),
        ),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: ExpressiveFilledButton(
            w.saveTrip,
            key: const ValueKey('plan-save'),
            size: ExpressiveButtonSize.medium,
            expand: phone,
            onPressed: _save,
          ),
        ),
      ],
    );
    return _Screen(
      title: TripScreens.titleIn(w, TripScreens.plan),
      subtitle: _trip.nameIn(w),
      leading: ExpressiveIconButton(
        ExpressiveSymbols.close,
        semanticLabel: w.discard,
        onPressed: _close,
      ),
      measure: 960,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < _twoPanes) {
            return Align(
              alignment: AlignmentDirectional.topStart,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: form,
              ),
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 32,
            children: [
              // Two panes, each with keylines of its own: the form's end is
              // its own, not the summary's (a card, a region already).
              Expanded(
                flex: 3,
                child: DesignKeylineRegion(label: 'Trip form', child: form),
              ),
              Expanded(
                flex: 2,
                child: _PlanSummary(
                  name: _name.text.trim().isEmpty
                      ? _trip.nameIn(w)
                      : _name.text.trim(),
                  dates: w.range(_leave, _back),
                  nights: nights,
                  stay: w.stay(_stay),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// The trip as the form now has it, beside the form on a wide window.
class _PlanSummary extends StatelessWidget {
  const _PlanSummary({
    required this.name,
    required this.dates,
    required this.nights,
    required this.stay,
  });

  final String name;
  final String dates;
  final int nights;
  final String stay;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final w = TripWords.of(context);
    return ExpressiveCard.outlined(
      key: const ValueKey('plan-summary'),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          Text(
            name,
            style: t.type.titleLarge.copyWith(color: t.colors.onSurface),
          ),
          _Line(w.dates, dates),
          _Line(w.nightsLabel, '$nights'),
          _Line(w.stayThing, stay),
          Row(
            spacing: 8,
            children: [
              for (final who in [w.mayaFull, w.samFull, w.you])
                ExpressiveAvatar(name: who, size: ExpressiveAvatarSize.small),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  w.everyone,
                  style: t.type.bodyMedium.copyWith(
                    color: t.colors.onSurfaceVariant,
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

// ---------------------------------------------------------------------------
// Shared with you: the group's bookings, lists and guides.

class _SharedScreen extends StatelessWidget {
  const _SharedScreen();

  @override
  Widget build(BuildContext context) {
    final scope = _TripScope.of(context);
    final trip = _TripScope.trip(context);
    final w = TripWords.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final phone = width < ExpressiveChromeMetrics.railMinWindowWidth;
    final open = trip.openItem;
    final items = trip.itemsIn(w);
    final item = open == null
        ? null
        : items.where((i) => i.id == open).firstOrNull;
    void select(String id) => trip.update(() => trip.openItem = id);
    return LayoutBuilder(
      builder: (context, constraints) {
        final panes = constraints.maxWidth >= _twoPanes;
        if (!panes && item != null) {
          return _ItemScreen(
            item: item,
            trip: trip,
            back: () => trip.update(() => trip.openItem = null),
          );
        }
        final list = _SharedList(
          trip: trip,
          selected: panes ? item?.id : null,
          onOpen: select,
        );
        if (!panes) {
          return _Screen(
            title: TripScreens.titleIn(w, TripScreens.shared),
            subtitle: w.everyone,
            floating: phone
                ? Builder(
                    builder: (fab) => ExpressiveFloatingActionButton(
                      icon: ExpressiveSymbols.add,
                      semanticLabel: w.addToTrip,
                      onPressed: () => _addMenu(fab, trip, scope.go),
                    ),
                  )
                : null,
            body: list,
          );
        }
        // A list beside its detail: the first item opens with the screen.
        final shown = item ?? items.first;
        return _Screen(
          title: TripScreens.titleIn(w, TripScreens.shared),
          subtitle: w.everyone,
          scroll: false,
          body: ExpressiveResizable(
            initialFraction: .4,
            minFirst: 320,
            minSecond: 400,
            first: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 32),
              child: _SharedList(
                trip: trip,
                selected: shown.id,
                onOpen: select,
              ),
            ),
            second: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 32),
              child: _ItemDetail(item: shown, trip: trip),
            ),
          ),
        );
      },
    );
  }
}

class _SharedList extends StatefulWidget {
  const _SharedList({
    required this.trip,
    required this.selected,
    required this.onOpen,
  });

  final _Trip trip;
  final String? selected;
  final ValueChanged<String> onOpen;

  @override
  State<_SharedList> createState() => _SharedListState();
}

class _SharedListState extends State<_SharedList> {
  final _search = GlobalKey<ExpressiveSearchBarState>();

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    final w = TripWords.of(context);
    final selected = widget.selected;
    final onOpen = widget.onOpen;
    final items = trip.itemsIn(w);
    Widget row(_Item item, {VoidCallback? after}) {
      final leading = _thing(context, item.name, item.icon, item.group);
      final headline = Text(item.name);
      final supporting = Text(item.line);
      void open() {
        after?.call();
        onOpen(item.id);
      }

      return selected == null
          ? ExpressiveListTile(
              key: ValueKey('shared-${item.id}'),
              leading: leading,
              title: headline,
              subtitle: supporting,
              onTap: open,
            )
          : ExpressiveListTile.selectable(
              key: ValueKey('shared-${item.id}'),
              selected: item.id == selected,
              leading: leading,
              title: headline,
              subtitle: supporting,
              onTap: open,
            );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: [
        ExpressiveSearchBar(
          key: _search,
          hintText: w.searchShared,
          results: (context, query) {
            final q = query.trim().toLowerCase();
            final found = [
              for (final i in items)
                if (q.isNotEmpty && i.name.toLowerCase().contains(q)) i,
            ];
            return ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                for (final i in found)
                  row(i, after: () => _search.currentState?.close()),
              ],
            );
          },
        ),
        for (final group in _groups)
          if (items.any((i) => i.group == group))
            ExpressiveListSection(
              key: ValueKey('shared-group-$group'),
              header: w.group(group),
              children: [
                for (final i in items)
                  if (i.group == group) row(i),
              ],
            ),
      ],
    );
  }
}

/// A shared item on a phone: its own page, the bar's back arrow returning
/// to the list.
class _ItemScreen extends StatelessWidget {
  const _ItemScreen({
    required this.item,
    required this.trip,
    required this.back,
  });

  final _Item item;
  final _Trip trip;
  final VoidCallback back;

  @override
  Widget build(BuildContext context) => _Screen(
    title: item.name,
    leading: ExpressiveIconButton(
      ExpressiveSymbols.arrowBack,
      semanticLabel: TripWords.of(context).backToShared,
      onPressed: back,
    ),
    body: _ItemDetail(item: item, trip: trip, titled: false),
  );
}

class _ItemDetail extends StatelessWidget {
  const _ItemDetail({
    required this.item,
    required this.trip,
    this.titled = true,
  });

  final _Item item;
  final _Trip trip;
  final bool titled;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final c = t.colors;
    final w = TripWords.of(context);
    return Column(
      key: ValueKey('shared-detail-${item.id}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 24,
      children: [
        Row(
          spacing: 16,
          children: [
            _thing(context, item.name, item.icon, item.group),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (titled)
                    Text(
                      item.name,
                      style: t.type.headlineSmall.copyWith(color: c.onSurface),
                    ),
                  Text(
                    item.line,
                    style: t.type.bodyLarge.copyWith(color: c.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (item.id == 'packing')
          ExpressiveListSection(
            header: w.packing,
            children: [
              for (final MapEntry(key: thing, value: packed)
                  in trip.packing.entries)
                ExpressiveListTile(
                  key: ValueKey('packing-$thing'),
                  leading: ExpressiveCheckbox.mark(value: packed),
                  title: Text(w.packingThing(thing)),
                  semanticLabel: w.packedState(w.packingThing(thing), packed),
                  onTap: () => trip.update(() => trip.packing[thing] = !packed),
                ),
            ],
          )
        else
          ExpressiveListSection(
            header: w.details,
            children: [
              for (final (label, value) in item.facts)
                ExpressiveListTile(overline: Text(label), title: Text(value)),
            ],
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Kit: the hike kit's checkout.

DateTime _arrival(_Trip trip) =>
    tripToday.add(Duration(days: trip.delivery == 'express' ? 1 : 9));

class _KitScreen extends StatelessWidget {
  const _KitScreen();

  @override
  Widget build(BuildContext context) {
    final trip = _TripScope.trip(context);
    final phone =
        MediaQuery.sizeOf(context).width <
        ExpressiveChromeMetrics.railMinWindowWidth;
    return _Screen(
      title: TripScreens.titleIn(TripWords.of(context), TripScreens.kit),
      measure: 1120,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final basket = _Basket(trip: trip);
          if (constraints.maxWidth < _twoPanes) {
            // On a phone the total and the order stand in the bar over the
            // navigation (the shell's accessory); beside a rail, at the
            // end of the basket.
            if (phone) return basket;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 32,
              children: [
                basket,
                _Summary(trip: trip),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 32,
            children: [
              Expanded(flex: 3, child: basket),
              Expanded(flex: 2, child: _Summary(trip: trip)),
            ],
          );
        },
      ),
    );
  }
}

class _Basket extends StatefulWidget {
  const _Basket({required this.trip});

  final _Trip trip;

  @override
  State<_Basket> createState() => _BasketState();
}

class _BasketState extends State<_Basket> {
  final _promo = TextEditingController();
  String? _promoError;

  @override
  void dispose() {
    _promo.dispose();
    super.dispose();
  }

  void _apply() {
    final valid = _promo.text.trim().toUpperCase() == 'TRAIL10';
    widget.trip.update(() => widget.trip.promo = valid);
    setState(
      () => _promoError = valid ? null : TripWords.of(context).codeInvalid,
    );
  }

  Future<void> _changeCard() async {
    final trip = widget.trip;
    final w = TripWords.of(context);
    final number = TextEditingController();
    final expiry = TextEditingController();
    final code = TextEditingController();
    final saved = await showExpressiveDialog<bool>(
      context: context,
      builder: (context) => ExpressiveDialog(
        title: w.changeCard,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 16,
          children: [
            ExpressiveTextField(
              key: const ValueKey('card-number'),
              controller: number,
              label: w.cardNumber,
              keyboardType: TextInputType.number,
              autofillHints: const [AutofillHints.creditCardNumber],
            ),
            // Expiry and security code are entered together, side by side.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 16,
              children: [
                Expanded(
                  child: ExpressiveTextField(
                    key: const ValueKey('card-expiry'),
                    controller: expiry,
                    label: w.expiry,
                    hintText: w.expiryHint,
                    keyboardType: TextInputType.datetime,
                  ),
                ),
                Expanded(
                  child: ExpressiveTextField(
                    key: const ValueKey('card-code'),
                    controller: code,
                    label: w.securityCode,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          ExpressiveDialogAction(w.cancel, value: false),
          ExpressiveDialogAction(w.useCard, value: true, filled: true),
        ],
      ),
    );
    final digits = number.text.replaceAll(RegExp(r'\D'), '');
    final until = expiry.text.trim();
    number.dispose();
    expiry.dispose();
    code.dispose();
    if (saved == true && digits.length >= 12 && mounted) {
      trip.update(
        () => trip.card = (
          last4: digits.substring(digits.length - 4),
          expiry: until.isEmpty ? trip.card.expiry : until,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    final w = TripWords.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 24,
      children: [
        ExpressiveListSection(
          header: w.basket,
          children: [for (final p in _products) _basketRow(context, trip, p)],
        ),
        ExpressiveListSection(
          header: w.delivery,
          children: [
            for (final (id, name, line, price) in [
              (
                'standard',
                w.standard,
                w.arrives(w.day(tripToday.add(const Duration(days: 9)))),
                0,
              ),
              (
                'express',
                w.express,
                w.arrivesTomorrow(
                  w.day(tripToday.add(const Duration(days: 1))),
                ),
                900,
              ),
            ])
              ExpressiveListTile.selectable(
                key: ValueKey('checkout-$id'),
                selected: trip.delivery == id,
                // The things' tile, unseen, gives the slot its exact box at
                // every density, so every row's words in the column start on
                // one x; the radio at its start, on the keyline the header
                // and the tiles stand on.
                leading: Stack(
                  alignment: AlignmentDirectional.centerStart,
                  children: [
                    Visibility(
                      visible: false,
                      maintainSize: true,
                      maintainAnimation: true,
                      maintainState: true,
                      child: _thing(
                        context,
                        name,
                        ExpressiveSymbols.check,
                        'Lists',
                      ),
                    ),
                    ExpressiveRadio.mark(selected: trip.delivery == id),
                  ],
                ),
                title: Text(name),
                subtitle: Text(line),
                trailing: Text(
                  price == 0 ? w.free : ExpressiveFormat.money(price),
                  style: context.expressiveTheme.type.bodyMedium,
                ),
                onTap: () => trip.update(() => trip.delivery = id),
              ),
          ],
        ),
        ExpressiveListSection(
          header: w.payment,
          children: [
            ExpressiveListTile(
              key: const ValueKey('checkout-card'),
              leading: _thing(
                context,
                w.card,
                ExpressiveSymbols.creditCard,
                'Bookings',
              ),
              title: Text(w.visaEnding(trip.card.last4)),
              subtitle: Text(w.expires(trip.card.expiry)),
              // The whole row is the target; a button in a list slot
              // would draw under 48dp.
              onTap: _changeCard,
              trailing: Text(
                w.change,
                key: const ValueKey('checkout-change-card'),
                style: context.expressiveTheme.type.labelLarge.copyWith(
                  color: context.expressiveTheme.colors.primary,
                ),
              ),
            ),
          ],
        ),
        _Headed(
          w.promoCode,
          // As wide as a code needs: across a phone's column, at most
          // 440dp with a pointer's room.
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Row(
                // One height, one centre: the field and its button are both
                // 56dp, their tops on one line; an error grows under the field.
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 12,
                children: [
                  Expanded(
                    child: ExpressiveTextField(
                      key: const ValueKey('checkout-promo'),
                      controller: _promo,
                      label: w.code,
                      textCapitalization: TextCapitalization.characters,
                      errorText: _promoError,
                      helperText: trip.promo ? w.promoApplied : null,
                      onSubmitted: (_) => _apply(),
                    ),
                  ),
                  ExpressiveFilledButton.tonal(
                    w.apply,
                    key: const ValueKey('checkout-apply'),
                    size: ExpressiveButtonSize.medium,
                    onPressed: _apply,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

Future<void> _placeOrder(BuildContext context, _Trip trip) async {
  final w = TripWords.read(context);
  final arrives = w.day(_arrival(trip));
  final total = ExpressiveFormat.money(trip.total);
  trip.update(() => trip.ordered = true);
  await showExpressiveDialog<void>(
    context: context,
    builder: (context) => ExpressiveDialog(
      icon: ExpressiveSymbols.checkCircle,
      title: w.orderPlaced,
      text: w.orderText(total, trip.card.last4, arrives, trip.nameIn(w)),
      actions: [ExpressiveDialogAction(w.done, filled: true)],
    ),
  );
}

/// The order's lines and total beside the basket, with the order button
/// under them: it stays in view while the basket scrolls.
class _Summary extends StatelessWidget {
  const _Summary({required this.trip});

  final _Trip trip;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final w = TripWords.of(context);
    return ExpressiveCard.outlined(
      key: const ValueKey('checkout-summary'),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            w.total,
            style: t.type.titleMedium.copyWith(color: t.colors.onSurface),
          ),
          const SizedBox(height: 4),
          Text(
            ExpressiveFormat.money(trip.total),
            key: const ValueKey('checkout-total'),
            style: t.type.displaySmall.copyWith(
              color: t.colors.onSurface,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 24),
          _Line(w.basket, ExpressiveFormat.money(trip.subtotal)),
          const SizedBox(height: 8),
          _Line(
            w.delivery,
            trip.shipping == 0 ? w.free : ExpressiveFormat.money(trip.shipping),
          ),
          if (trip.promo) ...[
            const SizedBox(height: 8),
            _Line(w.promoLine, ExpressiveFormat.money(-trip.saving)),
          ],
          const SizedBox(height: 24),
          // Beside a rail the order is its label's width, at the card's end
          // (the phone's stands in the bar).
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: ExpressiveFilledButton(
              trip.ordered ? w.ordered : w.placeOrder,
              key: const ValueKey('checkout-place'),
              size: ExpressiveButtonSize.medium,
              onPressed: trip.subtotal == 0 || trip.ordered
                  ? null
                  : () => _placeOrder(context, trip),
            ),
          ),
        ],
      ),
    );
  }
}

/// Whether the reader's text is large (1.5× and up): where two things that
/// share a phone's row at the default size stand one above the other.
/// A basket row: the thing, its price and its stepper. The row takes no
/// tap: its stepper's buttons stand on their own and keep their 48dp
/// targets. At large text the stepper stands under the price, so the name
/// has the row's width and never breaks inside a word.
Widget _basketRow(BuildContext context, _Trip trip, _Product p) {
  final w = TripWords.of(context);
  final name = w.product(p.id);
  final stepper = ExpressiveShrinkTapTargets.restore(
    child: ExpressiveNumberField(
      label: name,
      value: trip.quantities[p.id]!,
      min: 0,
      max: 9,
      onChanged: (v) => trip.update(() => trip.quantities[p.id] = v),
    ),
  );
  final price = Text(w.each(ExpressiveFormat.money(p.price)));
  final large = _largeText(context);
  return ExpressiveListTile(
    key: ValueKey('checkout-${p.id}'),
    leading: _thing(context, name, p.icon, 'Lists'),
    title: Text(name),
    subtitle: large
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [price, stepper],
          )
        : price,
    trailing: large ? null : stepper,
  );
}

bool _largeText(BuildContext context) =>
    MediaQuery.textScalerOf(context).scale(14) >= 14 * 1.5;

/// One of two things sharing a row: what the row leaves it, or the whole
/// width when the [Flex] around it stands them one above the other (at
/// large text).
class _Half extends StatelessWidget {
  const _Half({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      _largeText(context) ? child : Expanded(child: child);
}

/// The phone's checkout bar, docked over the navigation: the total (what
/// the person came for) and the order button; at large text the button
/// stands under the total, across the bar.
class _CheckoutBar extends StatelessWidget {
  const _CheckoutBar();

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final trip = _TripScope.trip(context);
    final w = TripWords.of(context);
    final large = _largeText(context);
    return ExpressiveSurface(
      key: const ValueKey('checkout-bar'),
      shape: t.shapes.none,
      // A step above the navigation's container tone, so the two bars read
      // as two rather than one slab.
      color: t.colors.surfaceContainerHigh,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Flex(
        direction: large ? Axis.vertical : Axis.horizontal,
        crossAxisAlignment: large
            ? CrossAxisAlignment.stretch
            : CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        spacing: large ? 12 : 16,
        children: [
          _Half(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  trip.shipping == 0 ? w.totalFreeDelivery : w.total,
                  style: t.type.labelLarge.copyWith(
                    color: t.colors.onSurfaceVariant,
                  ),
                ),
                Text(
                  ExpressiveFormat.money(trip.total),
                  key: const ValueKey('checkout-total'),
                  style: t.type.headlineSmall.copyWith(
                    color: t.colors.onSurface,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          ExpressiveFilledButton(
            trip.ordered ? w.ordered : w.placeOrder,
            key: const ValueKey('checkout-place'),
            size: ExpressiveButtonSize.medium,
            expand: large,
            onPressed: trip.subtotal == 0 || trip.ordered
                ? null
                : () => _placeOrder(context, trip),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Preferences.

class _PreferencesScreen extends StatelessWidget {
  const _PreferencesScreen();

  Future<void> _reset(BuildContext context, _Trip trip) async {
    final w = TripWords.read(context);
    final reset = await showExpressiveDialog<bool>(
      context: context,
      builder: (context) => ExpressiveDialog(
        title: w.resetTitle,
        text: w.resetText,
        actions: [
          ExpressiveDialogAction(w.cancel, value: false),
          ExpressiveDialogAction(w.reset, value: true, filled: true),
        ],
      ),
    );
    if (reset != true) return;
    trip.update(() {
      trip.reminders = true;
      trip.digest = true;
      trip.frequency = 'weekly';
      trip.density = 'comfortable';
      trip.sounds = true;
      trip.volume = .6;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final trip = _TripScope.trip(context);
    final w = TripWords.of(context);
    final detail = trip.density == 'comfortable';
    // A choice of two spans its row on a phone; with a pointer's room it
    // takes its own width.
    final phone =
        MediaQuery.sizeOf(context).width <
        ExpressiveChromeMetrics.railMinWindowWidth;
    Widget toggle(
      String key,
      String label,
      String? line,
      bool value,
      void Function(bool) set,
    ) => ExpressiveListTile.toggleable(
      key: ValueKey(key),
      title: Text(label),
      subtitle: line == null || !detail ? null : Text(line),
      trailing: ExpressiveSwitch.mark(value: value),
      value: value,
      onChanged: (v) => trip.update(() => set(v)),
    );
    // A control under its row's name: the row is static, the control
    // takes the taps.
    Widget control(String label, Widget child) => ExpressiveListTile(
      title: Text(label),
      subtitle: Padding(padding: const EdgeInsets.only(top: 8), child: child),
    );
    // A short choice: across the row on a phone; with a pointer's room on
    // the row's own line, at the edge the switches stand on. Tonal: the
    // filled group's unchosen segment is surfaceContainer, the row's own
    // colour, and vanished into it.
    Widget choice(String label, Widget child) => phone
        ? control(label, child)
        : ExpressiveListTile(
            title: Row(
              children: [
                Expanded(child: Text(label)),
                child,
              ],
            ),
          );
    return _Screen(
      title: TripScreens.titleIn(w, TripScreens.preferences),
      measure: 720,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 24,
        children: [
          ExpressiveListSection(
            header: w.notifications,
            children: [
              toggle(
                'prefs-reminders',
                w.tripReminders,
                w.tripRemindersLine,
                trip.reminders,
                (v) => trip.reminders = v,
              ),
              toggle(
                'prefs-digest',
                w.tripDigest,
                w.tripDigestLine,
                trip.digest,
                (v) => trip.digest = v,
              ),
              if (trip.digest)
                choice(
                  w.sendDigest,
                  ExpressiveSegmentedButton<String>(
                    key: const ValueKey('prefs-frequency'),
                    kind: ExpressiveToggleButtonKind.tonal,
                    expand: phone,
                    segments: [
                      ExpressiveButtonSegment('daily', w.daily),
                      ExpressiveButtonSegment('weekly', w.weekly),
                    ],
                    value: trip.frequency,
                    onChanged: (v) => trip.update(() => trip.frequency = v),
                  ),
                ),
            ],
          ),
          ExpressiveListSection(
            header: w.display,
            children: [
              choice(
                w.rowDetail,
                ExpressiveSegmentedButton<String>(
                  key: const ValueKey('prefs-density'),
                  kind: ExpressiveToggleButtonKind.tonal,
                  expand: phone,
                  segments: [
                    ExpressiveButtonSegment('compact', w.compact),
                    ExpressiveButtonSegment('comfortable', w.comfortable),
                  ],
                  value: trip.density,
                  onChanged: (v) => trip.update(() => trip.density = v),
                ),
              ),
            ],
          ),
          ExpressiveListSection(
            header: w.sound,
            children: [
              toggle(
                'prefs-sounds',
                w.notificationSounds,
                null,
                trip.sounds,
                (v) => trip.sounds = v,
              ),
              control(
                w.volumeLine((trip.volume * 100).round()),
                ExpressiveSlider(
                  key: const ValueKey('prefs-volume'),
                  value: trip.volume,
                  semanticLabel: w.volume,
                  onChanged: trip.sounds
                      ? (v) => trip.update(() => trip.volume = v)
                      : null,
                ),
              ),
            ],
          ),
          // Quiet, a row of its own at the end, on the list's keyline: its
          // dialog carries the filled button.
          ExpressiveListSection(
            children: [
              ExpressiveListTile(
                key: const ValueKey('prefs-reset'),
                title: Text(
                  w.resetPreferences,
                  style: TextStyle(color: t.colors.error),
                ),
                onTap: () => _reset(context, trip),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

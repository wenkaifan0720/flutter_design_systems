/// Larder: the example's product, a small kitchen and home goods shop, set
/// in Appliance. Its places (the look's Overview, Home, Shop, Basket,
/// Orders and Settings) are moved between by the look's own navigation: the key strip
/// on a phone, the rail on a tablet, the moulded side panel from 1024.
///
/// Settings drives the app: its appearance, reading direction and density,
/// so every screen shows them as they are set.
library;

import 'package:material_ui/material_ui.dart';
import 'package:appliance_ui/appliance_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';
import 'basket.dart';
import 'data.dart';
import 'home.dart';
import 'orders.dart';
import 'overview.dart';
import 'search.dart';
import 'settings.dart';
import 'shop.dart';
import 'words.dart';

/// Where the app opens.
enum LarderPlace { home, shop, basket, orders, settings, overview }

/// A state of a place Larder can open straight onto, as a link or the sweep
/// of its everyday screens does.
enum LarderScene {
  /// A product's page over Shop.
  product,

  /// The filter sheet over Shop.
  filter,

  /// The checkout over Basket.
  checkout,

  /// The question before an item leaves the basket.
  remove,

  /// The newest order's page, its tracking, over Orders (beside the list
  /// on a desk).
  order,

  /// Search over Home, with what it found.
  search,

  /// Search over Home, having found nothing.
  searchEmpty,

  /// The declined payment over the checkout, over Basket.
  paymentFailed,

  /// Basket with nothing in it.
  emptyBasket,
}

/// How the app is lit.
enum LarderAppearance { light, dark, system }

/// What Settings sets for the whole app.
class LarderPrefs extends ChangeNotifier {
  /// Prefs as given.
  LarderPrefs({
    this.appearance = LarderAppearance.light,
    this.direction = TextDirection.ltr,
    this.density = ApplianceDensity.standard,
  });

  /// Light, dark or the system's.
  LarderAppearance appearance;

  /// Which way the pages read.
  TextDirection direction;

  /// How tightly the controls are set.
  ApplianceDensity density;

  /// Word when an order ships and arrives.
  bool orderUpdates = true;

  /// The new season's goods, by email, once a month.
  bool newsletter = false;

  /// A quiet click as a key goes down.
  bool keySounds = false;

  /// Prices shown with tax.
  bool withTax = true;

  LarderDetails _savedDetails = larderShopper;
  bool _signedIn = true;

  /// The active demo account, or null after signing out.
  LarderDetails? get account => _signedIn ? _savedDetails : null;

  /// Messages kept in this example for the current session.
  final messages = <String>[];

  void saveAccount(LarderDetails details) {
    if (_signedIn) update((p) => p._savedDetails = details);
  }

  void signIn() => update((p) => p._signedIn = true);

  void signOut() => update((p) {
    p._signedIn = false;
    p.messages.clear();
  });

  /// Catalog prices include tax by default, also for a standalone product card.
  static bool pricesWithTax(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<_LarderScope>()
          ?.notifier
          ?.withTax ??
      true;

  static String price(BuildContext context, int gross) =>
      larderPrice(pricesWithTax(context) ? gross : larderNetPence(gross));

  /// Changes the prefs and tells the app.
  void update(void Function(LarderPrefs prefs) change) {
    change(this);
    notifyListeners();
  }

  /// The prefs above [context].
  static LarderPrefs of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_LarderScope>()!.notifier!;
}

class _LarderScope extends InheritedNotifier<LarderPrefs> {
  const _LarderScope({required LarderPrefs prefs, required super.child})
    : super(notifier: prefs);
}

class _LarderFrameScope extends InheritedWidget {
  const _LarderFrameScope({required this.frame, required super.child});

  final GlobalKey<LarderFrameState> frame;

  @override
  bool updateShouldNotify(_LarderFrameScope old) => old.frame != frame;
}

/// One entry of the Overview's index of parts.
typedef LarderPart = ({String title, Widget Function(Brightness) build});

/// The app, themed by [LarderPrefs], opening on [initialPlace].
class LarderApp extends StatefulWidget {
  /// The app.
  const LarderApp({
    super.key,
    this.initialPlace = LarderPlace.overview,
    this.initialScene,
    this.initialAppearance = LarderAppearance.light,
    this.initialDirection = TextDirection.ltr,
    this.initialDensity,
    this.textScale,
    this.parts = const [],
    this.initialPart,
  });

  /// The place it opens on.
  final LarderPlace initialPlace;

  /// The state of [initialPlace] it opens on; null: as it first stands.
  final LarderScene? initialScene;

  /// How it is lit at first. Settings changes it after.
  final LarderAppearance initialAppearance;

  /// The direction it reads at first.
  final TextDirection initialDirection;

  /// The density it opens at; null: standard.
  final ApplianceDensity? initialDensity;

  /// A text scale over the platform's; null keeps the platform's.
  final double? textScale;

  /// The package's parts, for the Overview's index.
  final List<LarderPart> parts;

  /// The index in [parts] of a part whose page opens after the first frame.
  final int? initialPart;

  @override
  State<LarderApp> createState() => _LarderAppState();
}

class _LarderAppState extends State<LarderApp> {
  late final LarderPrefs _prefs = LarderPrefs(
    appearance: widget.initialAppearance,
    direction: widget.initialDirection,
    density: widget.initialDensity ?? ApplianceDensity.standard,
  );
  final _frame = GlobalKey<LarderFrameState>();

  @override
  void dispose() {
    _prefs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _prefs,
    builder: (context, _) {
      final frame = LarderFrame(
        key: _frame,
        initialPlace: widget.initialPlace,
        initialScene: widget.initialScene,
        parts: widget.parts,
        initialPart: widget.initialPart,
      );
      // In a semantics container of its own, so that inside a host's preview
      // its first page's barrier hides nothing of the host's.
      return Semantics(
        container: true,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Larder',
          // Larder is written on Flutter's own material library, whose routes
          // read their page change from its own theme: Appliance's, given here.
          theme: ThemeData(
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: appliancePageTransitions,
            ),
          ),
          localizationsDelegates: const [
            DesignLocalizations.delegate,
            LarderWords.delegate,
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
              LarderAppearance.light => Brightness.light,
              LarderAppearance.dark => Brightness.dark,
              LarderAppearance.system => platform,
            };
            Widget app = AnimatedApplianceTheme(
              data: ApplianceThemeData.of(brightness, density: _prefs.density),
              child: KitGalleryScope(
                child: ApplianceToaster(
                  child: child ?? const SizedBox.shrink(),
                ),
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
            return _LarderScope(
              prefs: _prefs,
              child: _LarderFrameScope(
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

/// The app's frame: the current place under the look's navigation. From the
/// rail's width (600) a pushed page opens in the frame, beside the rail or
/// the side panel; on a phone it covers the key strip.
class LarderFrame extends StatefulWidget {
  /// The frame.
  const LarderFrame({
    super.key,
    this.initialPlace = LarderPlace.overview,
    this.initialScene,
    this.parts = const [],
    this.initialPart,
  });

  /// As [LarderApp.initialPlace].
  final LarderPlace initialPlace;

  /// As [LarderApp.initialScene].
  final LarderScene? initialScene;

  /// As [LarderApp.parts].
  final List<LarderPart> parts;

  /// As [LarderApp.initialPart].
  final int? initialPart;

  /// The frame above [context].
  static LarderFrameState of(BuildContext context) =>
      context.findAncestorStateOfType<LarderFrameState>() ??
      context
          .getInheritedWidgetOfExactType<_LarderFrameScope>()!
          .frame
          .currentState!;

  @override
  State<LarderFrame> createState() => LarderFrameState();
}

/// [LarderFrame]'s state: where a page opens, the way between places, and
/// the basket.
class LarderFrameState extends State<LarderFrame> {
  late LarderPlace _place = widget.initialPlace;
  late LarderScene? _scene = widget.initialScene;
  final _desk = GlobalKey<NavigatorState>();

  /// The basket's lines.
  final List<LarderLine> basket = [...larderBasket];

  /// Ticks whenever the basket changes, for a page that shows it.
  final ValueNotifier<int> basketChanges = ValueNotifier(0);

  /// The shopper's orders, newest first.
  List<LarderOrder> get orders =>
      LarderPrefs.of(context).account == null ? const [] : _orders;
  final List<LarderOrder> _orders = [...larderOrders];

  /// Payments tried so far.
  int _tries = 0;

  @override
  void dispose() {
    basketChanges.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final scene = _scene;
    if (scene == LarderScene.emptyBasket) basket.clear();
    // Opened on the declined payment, the next try goes through.
    if (scene == LarderScene.paymentFailed) _tries = 1;
    if (scene != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        switch (scene) {
          case LarderScene.product:
            push(LarderProductPage(product: larderProduct('pour-over')));
          case LarderScene.checkout:
            push(const LarderCheckoutPage());
          case LarderScene.search:
            push(const LarderSearchPage(initialQuery: 'tea'));
          case LarderScene.searchEmpty:
            push(const LarderSearchPage(initialQuery: 'toaster'));
          case LarderScene.paymentFailed:
            push(const LarderCheckoutPage());
            final subtotal = basket.fold(0, (n, l) => n + l.pence);
            push(LarderPaymentFailedPage(delivery: larderDelivery(subtotal)));
          case LarderScene.filter:
          case LarderScene.remove:
          case LarderScene.order:
          case LarderScene.emptyBasket:
            break;
        }
      });
    }
    final part = widget.initialPart;
    if (part != null && part >= 0 && part < widget.parts.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          push(widget.parts[part].build(context.applianceTheme.brightness));
        }
      });
    }
  }

  /// Whether the frame stands beside a rail or a side panel.
  bool get wide => MediaQuery.sizeOf(context).width >= 600;

  /// How many things are in the basket.
  int get basketCount => basket.fold(0, (n, l) => n + l.count);

  /// The subtotal before tax, using the price shown for each unit.
  int get basketNetPence => basket.fold(0, (sum, line) => sum + line.netPence);

  /// Changes the basket and redraws the frame (its count).
  void changeBasket(void Function(List<LarderLine> lines) change) =>
      setState(() {
        change(basket);
        basketChanges.value++;
      });

  /// Puts one of [product] in the basket.
  void add(LarderProduct product, {String? finish, int count = 1}) =>
      changeBasket((lines) {
        final at = lines.indexWhere(
          (l) => l.product.id == product.id && l.finish == finish,
        );
        if (at < 0) {
          lines.add(
            LarderLine(product, count, finish: finish ?? product.finishes[0]),
          );
        } else {
          lines[at] = LarderLine(
            product,
            lines[at].count + count,
            finish: lines[at].finish,
          );
        }
      });

  /// Whether the bank takes a payment. In the example it declines the
  /// first, so the failed payment and its retry are on the way to an order.
  bool tryPayment() => ++_tries > 1;

  /// Turns the basket into a new order with [delivery] by [method]: closes
  /// what was open over the place, empties the basket and opens Orders.
  void placeOrder({
    required int delivery,
    required String method,
    required LarderDetails details,
    required bool gift,
  }) {
    if (LarderPrefs.of(context).account == null || basket.isEmpty) return;
    final next = method == 'Next day';
    final order = LarderOrder(
      number: orders.first.number + 1,
      placed: 'Mon 16 Nov',
      due: next ? 'Tue 17 Nov' : 'Fri 20 Nov',
      stage: LarderOrderStage.ordered,
      lines: [...basket],
      delivery: delivery,
      method: method,
      details: details,
      gift: gift,
      tracking: const [(what: 'Ordered', where: null, when: 'Just now')],
    );
    (_desk.currentState ?? Navigator.of(context)).popUntil((r) => r.isFirst);
    setState(() {
      _orders.insert(0, order);
      basket.clear();
      basketChanges.value++;
      _place = LarderPlace.orders;
      _scene = null;
    });
    showApplianceToast(context, 'Order ${order.number} placed. Thank you.');
  }

  /// Ends the demo session and removes the shopper's basket and open detail pages.
  void signOut() {
    final prefs = LarderPrefs.of(context);
    (_desk.currentState ?? Navigator.of(context)).popUntil((r) => r.isFirst);
    changeBasket((lines) => lines.clear());
    _tries = 0;
    prefs.signOut();
    showApplianceToast(context, 'Signed out');
  }

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
  void go(LarderPlace place) => setState(() {
    _place = place;
    _scene = null;
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.applianceTheme;
    final count = basketCount;
    final prefs = LarderPrefs.of(context);
    // About stands last; on a phone it leaves the key strip (five keys, not
    // six) and Settings' Help opens it.
    final places = [
      const ApplianceDestination(icon: LucideIcons.house, label: 'Home'),
      const ApplianceDestination(icon: LucideIcons.layoutGrid, label: 'Shop'),
      ApplianceDestination(
        icon: LucideIcons.shoppingBasket,
        label: 'Basket',
        badge: count == 0 ? null : '$count',
      ),
      const ApplianceDestination(icon: LucideIcons.package, label: 'Orders'),
      const ApplianceDestination(icon: LucideIcons.settings, label: 'Settings'),
      if (wide)
        const ApplianceDestination(icon: LucideIcons.info, label: 'About'),
    ];
    final page = switch (_place) {
      LarderPlace.overview => LarderOverview(parts: widget.parts),
      LarderPlace.home => const LarderHome(),
      LarderPlace.shop => LarderShop(showFilter: _scene == LarderScene.filter),
      LarderPlace.basket => LarderBasket(
        askRemove: _scene == LarderScene.remove,
      ),
      LarderPlace.orders => LarderOrders(
        openFirst: _scene == LarderScene.order,
      ),
      LarderPlace.settings => const LarderSettings(),
    };
    return ApplianceScaffold(
      destinations: places,
      selectedIndex: _place.index,
      onSelected: (i) => go(LarderPlace.values[i]),
      header: LarderBrand(large: true, colors: theme.colors),
      railLeading: LarderBrand(colors: theme.colors),
      sideFooter: ApplianceListGroup(
        children: [
          ApplianceListTile(
            leading: const Icon(LucideIcons.user),
            title: prefs.account?.name ?? 'Guest',
            subtitle: prefs.account == null ? 'Signed out' : 'Account',
            onTap: () => go(LarderPlace.settings),
          ),
        ],
      ),
      // The desk's own navigator stands in a semantics container: its page's
      // modal barrier would otherwise hide the side panel, painted before it,
      // from a screen reader.
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

/// Larder's mark: a small moulded badge with a lamp, and its name.
class LarderBrand extends StatelessWidget {
  /// The mark; [large] with its name.
  const LarderBrand({super.key, required this.colors, this.large = false});

  /// The theme's colours.
  final ApplianceColors colors;

  /// Whether the name stands beside the mark.
  final bool large;

  @override
  Widget build(BuildContext context) {
    final theme = context.applianceTheme;
    final mark = SizedBox.square(
      dimension: 36,
      child: ApplianceSurface(
        face: ApplianceFace.key(colors, radius: 9),
        child: const Center(child: ApplianceLamp(lit: true, size: 9)),
      ),
    );
    if (!large) return Semantics(label: 'Larder', child: mark);
    return Semantics(
      label: 'Larder',
      excludeSemantics: true,
      child: Row(
        children: [
          mark,
          const SizedBox(width: ApplianceSpacing.medium),
          Text('Larder', style: theme.textTheme.title.copyWith(fontSize: 20)),
        ],
      ),
    );
  }
}

/// One of Larder's pages: its top bar, then its content down one column
/// that starts on the page's edge and stands at most [maxWidth] wide;
/// [bottom] fixed under it.
class LarderPage extends StatelessWidget {
  /// A page titled [title].
  const LarderPage({
    super.key,
    required this.title,
    required this.children,
    this.actions = const [],
    this.barBottom,
    this.bottom,
    this.maxWidth = ApplianceMetrics.readingWidth,
  });

  /// The page's name.
  final String title;

  /// What it holds, top to bottom.
  final List<Widget> children;

  /// Keys in its bar.
  final List<Widget> actions;

  /// What stands under the bar's title row.
  final Widget? barBottom;

  /// What stands fixed at its foot: the main action.
  final Widget? bottom;

  /// The widest its column stands.
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final route = ModalRoute.of(context);
    final canPop = route?.canPop ?? false;
    return ApplianceScreen(
      topBar: ApplianceAppBar(
        title: title,
        onBack: canPop ? () => Navigator.of(context).maybePop() : null,
        actions: actions,
        bottom: barBottom,
      ),
      footer: bottom,
      body: Align(
        alignment: AlignmentDirectional.topStart,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }
}

/// The widest a desk page in two columns stands.
const double larderDeskWidth = 1080;

/// A gap between groups on a page.
const larderGroupGap = SizedBox(height: ApplianceSpacing.extraLarge);

/// A product's picture: the product's glyph pressed into a sunken plate,
/// as a maker's mark is moulded in.
class LarderPicture extends StatelessWidget {
  /// [product]'s picture.
  const LarderPicture({super.key, required this.product, this.height = 120});

  /// Whose.
  final LarderProduct product;

  /// How tall.
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.applianceTheme.colors;
    return ExcludeSemantics(
      child: SizedBox(
        height: height,
        child: ApplianceSurface(
          face: ApplianceFace.well(c, fill: c.trough),
          child: Center(
            child: Icon(product.icon, size: height * 0.38, color: c.printMuted),
          ),
        ),
      ),
    );
  }
}

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

/// Admit: the example's product, a city's tickets for the week, set in
/// Brutal. Five places (the look's Overview, Home, Events, Tickets and
/// Settings) moved between by the look's own navigation: the bottom bar on a
/// phone, the rail on a tablet, the side list from 1024.
///
/// Settings drives the app: its appearance, reading direction and density,
/// so every screen shows them as they are set.
library;

import 'package:material_ui/material_ui.dart';
import 'package:brutal_ui/brutal_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';
import 'data.dart';
import 'events.dart';
import 'home.dart';
import 'overview.dart';
import 'search.dart';
import 'settings.dart';
import 'tickets.dart';

/// Where the app opens.
enum AdmitPlace { overview, home, events, tickets, settings }

/// A state of a place Admit can open straight onto, as a link or the sweep
/// of its everyday screens does.
enum AdmitScene {
  /// An event's page over Events.
  event,

  /// The checkout for two standing tickets to Low Tide.
  checkout,

  /// A ticket's page with its code over Tickets.
  ticket,

  /// The cancel question over a ticket.
  cancel,

  /// The filter sheet over Events.
  filter,

  /// Search with results for "hall".
  search,

  /// Search finding nothing for "jazz".
  searchNone,

  /// The checkout after the bank declined the card.
  paymentFailed,
}

/// How the app is lit.
enum AdmitAppearance { light, dark, system }

/// Appearance, account details and ticket orders for this demo session.
class AdmitPrefs extends ChangeNotifier {
  /// Prefs as given.
  AdmitPrefs({
    this.appearance = AdmitAppearance.light,
    this.direction = TextDirection.ltr,
    this.density = BrutalDensity.standard,
  });

  /// Light, dark or the system's.
  AdmitAppearance appearance;

  /// Which way the pages read.
  TextDirection direction;

  /// How tightly the controls are set.
  BrutalDensity density;

  /// Reminders a day before each event.
  bool reminders = true;

  /// The weekly listings by email.
  bool listings = false;

  /// Sounds on the door scanner's beep, in the app.
  bool sounds = false;

  /// Account details and orders for this demo session.
  String name = admitOwner.name;
  String email = admitOwner.email;
  String cardEnding = admitOwner.card;
  String expiry = '08/28';
  bool signedIn = true;
  final upcoming = [...admitSampleOrders];
  int _nextOrder = 2319;

  void book(
    AdmitEvent event,
    Map<String, int> counts, {
    required String cardEnding,
    required String recipient,
  }) {
    final order = AdmitHeld(
      order: 'A-${_nextOrder++}',
      eventId: event.id,
      counts: Map.unmodifiable(
        Map.fromEntries(counts.entries.where((line) => line.value > 0)),
      ),
      cardEnding: cardEnding,
      recipient: recipient,
    );
    upcoming.insert(0, order);
    notifyListeners();
  }

  void cancel(AdmitHeld order) {
    if (upcoming.remove(order)) notifyListeners();
  }

  void restore(AdmitHeld order, int index) {
    if (!signedIn || upcoming.contains(order)) return;
    upcoming.insert(index.clamp(0, upcoming.length), order);
    notifyListeners();
  }

  /// Reads initial values for a form without subscribing during initState.
  static AdmitPrefs read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_AdmitScope>()!.notifier!;

  /// Changes the prefs and tells the app.
  void update(void Function(AdmitPrefs prefs) change) {
    change(this);
    notifyListeners();
  }

  /// The prefs above [context].
  static AdmitPrefs of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_AdmitScope>()!.notifier!;
}

class _AdmitScope extends InheritedNotifier<AdmitPrefs> {
  const _AdmitScope({required AdmitPrefs prefs, required super.child})
    : super(notifier: prefs);
}

/// The frame's key, above the app's navigator: a page pushed over the whole
/// app (on a phone) reaches the frame through it.
class _AdmitFrameScope extends InheritedWidget {
  const _AdmitFrameScope({required this.frame, required super.child});

  final GlobalKey<AdmitFrameState> frame;

  @override
  bool updateShouldNotify(_AdmitFrameScope old) => old.frame != frame;
}

/// One entry of the Overview's index of parts.
typedef AdmitPart = ({String title, Widget Function(Brightness) build});

/// The app, themed by [AdmitPrefs], opening on [initialPlace].
class AdmitApp extends StatefulWidget {
  /// The app.
  const AdmitApp({
    super.key,
    this.initialPlace = AdmitPlace.overview,
    this.initialScene,
    this.initialAppearance = AdmitAppearance.light,
    this.initialDirection = TextDirection.ltr,
    this.initialDensity,
    this.textScale,
    this.parts = const [],
    this.initialPart,
  });

  /// The place it opens on.
  final AdmitPlace initialPlace;

  /// The state of [initialPlace] it opens on; null: as it first stands.
  final AdmitScene? initialScene;

  /// How it is lit at first. Settings changes it after.
  final AdmitAppearance initialAppearance;

  /// The direction it reads at first.
  final TextDirection initialDirection;

  /// The density it opens at; null: standard.
  final BrutalDensity? initialDensity;

  /// A text scale over the platform's; null keeps the platform's.
  final double? textScale;

  /// The package's parts, for the Overview's index.
  final List<AdmitPart> parts;

  /// The index in [parts] of a part whose page opens after the first frame.
  final int? initialPart;

  @override
  State<AdmitApp> createState() => _AdmitAppState();
}

class _AdmitAppState extends State<AdmitApp> {
  late final AdmitPrefs _prefs = AdmitPrefs(
    appearance: widget.initialAppearance,
    direction: widget.initialDirection,
    density: widget.initialDensity ?? BrutalDensity.standard,
  );
  final _frame = GlobalKey<AdmitFrameState>();

  @override
  void dispose() {
    _prefs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _prefs,
    builder: (context, _) {
      final frame = AdmitFrame(
        key: _frame,
        initialPlace: widget.initialPlace,
        initialScene: widget.initialScene,
        parts: widget.parts,
        initialPart: widget.initialPart,
      );
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Admit',
        // Admit is written on Flutter's own material library, whose routes
        // read their page change from its own theme: Brutal's, given here.
        theme: ThemeData(
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: brutalPageTransitions,
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
            AdmitAppearance.light => Brightness.light,
            AdmitAppearance.dark => Brightness.dark,
            AdmitAppearance.system => platform,
          };
          Widget app = BrutalTheme(
            data: BrutalThemeData.raw(brightness, density: _prefs.density),
            child: KitGalleryScope(
              child: BrutalToaster(child: child ?? const SizedBox.shrink()),
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
          return _AdmitScope(
            prefs: _prefs,
            child: _AdmitFrameScope(
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
/// the side list; on a phone it covers the bottom bar.
class AdmitFrame extends StatefulWidget {
  /// The frame.
  const AdmitFrame({
    super.key,
    this.initialPlace = AdmitPlace.overview,
    this.initialScene,
    this.parts = const [],
    this.initialPart,
  });

  /// As [AdmitApp.initialPlace].
  final AdmitPlace initialPlace;

  /// As [AdmitApp.initialScene].
  final AdmitScene? initialScene;

  /// As [AdmitApp.parts].
  final List<AdmitPart> parts;

  /// As [AdmitApp.initialPart].
  final int? initialPart;

  /// The frame above [context].
  static AdmitFrameState of(BuildContext context) =>
      context.findAncestorStateOfType<AdmitFrameState>() ??
      context
          .getInheritedWidgetOfExactType<_AdmitFrameScope>()!
          .frame
          .currentState!;

  @override
  State<AdmitFrame> createState() => AdmitFrameState();
}

/// [AdmitFrame]'s state: where a page opens, and the way between places.
class AdmitFrameState extends State<AdmitFrame> {
  late AdmitPlace _place = widget.initialPlace;
  late AdmitScene? _scene = widget.initialScene;
  final _desk = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    final scene = _scene;
    if (scene != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        switch (scene) {
          // On a desk Events and Tickets stand beside the open one (from
          // [AdmitHome.deskWidth], as they split); below it the page opens
          // over the list, a rail's frame or a phone's.
          case AdmitScene.event:
            if (!desk) push(AdmitEventPage(event: admitEvent('low-tide')));
          case AdmitScene.checkout:
            push(
              AdmitCheckoutPage(
                event: admitEvent('low-tide'),
                counts: const {'Standing': 2},
              ),
            );
          case AdmitScene.ticket:
            if (!desk) push(AdmitTicketPage(held: admitSampleOrders.last));
          case AdmitScene.cancel:
            push(
              AdmitTicketPage(held: admitSampleOrders.last, askCancel: true),
            );
          case AdmitScene.filter:
            break;
          case AdmitScene.search:
            push(const AdmitSearchPage(initialQuery: 'hall'));
          case AdmitScene.searchNone:
            push(const AdmitSearchPage(initialQuery: 'jazz'));
          case AdmitScene.paymentFailed:
            push(
              AdmitCheckoutPage(
                event: admitEvent('low-tide'),
                counts: const {'Standing': 2},
                declined: true,
              ),
            );
        }
      });
    }
    final part = widget.initialPart;
    if (part != null && part >= 0 && part < widget.parts.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          push(widget.parts[part].build(context.brutalTheme.brightness));
        }
      });
    }
  }

  /// Whether the frame stands beside a rail or a side list.
  bool get wide => MediaQuery.sizeOf(context).width >= 600;

  /// Whether Events and Tickets stand beside their open one.
  bool get desk => MediaQuery.sizeOf(context).width >= AdmitHome.deskWidth;

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
  void go(AdmitPlace place) => setState(() {
    _place = place;
    _scene = null;
  });

  /// Ends the session and closes any open account or ticket detail.
  void signOut() {
    Navigator.of(context).popUntil((r) => r.isFirst);
    _desk.currentState?.popUntil((r) => r.isFirst);
    AdmitPrefs.of(context).update((p) => p.signedIn = false);
    go(AdmitPlace.settings);
  }

  static const _places = [
    BrutalDestination(icon: LucideIcons.square, label: 'Brutal'),
    BrutalDestination(icon: LucideIcons.house, label: 'Home'),
    BrutalDestination(icon: LucideIcons.calendarDays, label: 'Events'),
    BrutalDestination(icon: LucideIcons.ticket, label: 'Tickets'),
    BrutalDestination(icon: LucideIcons.settings, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = context.brutalTheme;
    final prefs = AdmitPrefs.of(context);
    final page = switch (_place) {
      AdmitPlace.overview => AdmitOverview(parts: widget.parts),
      AdmitPlace.home => const AdmitHome(),
      AdmitPlace.events => AdmitEvents(
        showFilter: _scene == AdmitScene.filter,
        openFirst: _scene == AdmitScene.event,
      ),
      AdmitPlace.tickets => AdmitTickets(
        open: _scene == AdmitScene.ticket ? admitSampleOrders.last : null,
      ),
      AdmitPlace.settings => const AdmitSettings(),
    };
    return BrutalScaffold(
      destinations: _places,
      selectedIndex: _place.index,
      onSelected: (i) => go(AdmitPlace.values[i]),
      brand: Text(
        MediaQuery.sizeOf(context).width >= 1024 ? 'ADMIT' : 'A',
        style: theme.textTheme.title,
      ),
      sideFooter: BrutalListTile(
        title: prefs.signedIn ? prefs.name : 'Sign in',
        subtitle: prefs.signedIn ? prefs.email : null,
        onTap: () => go(AdmitPlace.settings),
      ),
      body: wide
          // A semantics container of its own: its route's barrier would hide
          // from a screen reader what the shell paints before it (the top
          // bar, the side list), as material_ui's app adds none round it.
          ? Semantics(
              container: true,
              child: Navigator(
                key: _desk,
                // A place is swapped in place: no page change.
                pages: [_PlacePage(key: ValueKey(_place), child: page)],
                onDidRemovePage: (_) {},
              ),
            )
          : KeyedSubtree(key: ValueKey(_place), child: page),
    );
  }
}

/// Opens the example account after an explicit sign-in.
class AdmitSignIn extends StatelessWidget {
  const AdmitSignIn({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => AdmitPage(
    title: title,
    children: [
      Text(
        'Sign in to the Admit demo account to see your tickets and account details.',
        style: context.brutalTheme.textTheme.body,
      ),
      const SizedBox(height: BrutalSpacing.large),
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: BrutalButton.filled(
          'Sign in',
          onPressed: () =>
              AdmitPrefs.of(context).update((p) => p.signedIn = true),
        ),
      ),
    ],
  );
}

/// One of Admit's pages: its top bar, then its content down one column that
/// starts on the page's edge (the same edge on every place) and stands at
/// most [maxWidth] wide; [bottom] pinned under it, on a rule.
class AdmitPage extends StatelessWidget {
  /// A page titled [title].
  const AdmitPage({
    super.key,
    required this.title,
    required this.children,
    this.actions = const [],
    this.bottom,
    this.maxWidth = BrutalMetrics.readingWidth,
  });

  /// The page's name.
  final String title;

  /// What it holds, top to bottom.
  final List<Widget> children;

  /// Action cells in its bar.
  final List<Widget> actions;

  /// What stands pinned at its foot: the main action.
  final Widget? bottom;

  /// The widest its column stands.
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final margin = BrutalSpacing.pageMargin(MediaQuery.sizeOf(context).width);
    final route = ModalRoute.of(context);
    final canPop = route?.canPop ?? false;
    final pad = MediaQuery.paddingOf(context);
    return ColoredBox(
      color: context.brutalTheme.colors.paper,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BrutalAppBar(
            title: title,
            onBack: canPop ? () => Navigator.of(context).maybePop() : null,
            actions: actions,
          ),
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  margin,
                  BrutalSpacing.large,
                  margin,
                  BrutalSpacing.huge + (bottom == null ? pad.bottom : 0),
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
          if (bottom != null) ...[
            const BrutalRule(),
            Padding(
              padding: EdgeInsets.fromLTRB(
                margin,
                BrutalSpacing.regular,
                margin,
                BrutalSpacing.regular + pad.bottom,
              ),
              child: Align(
                alignment: AlignmentDirectional.topStart,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: bottom,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The widest a desk page in two columns stands.
const double admitDeskWidth = 1120;

/// A gap between groups on a page.
const admitGroupGap = SizedBox(height: BrutalSpacing.extraLarge);

/// One of the app's places at the root of the frame's navigator: swapped in
/// place when the side bar or the bar below changes it, never slid in.
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

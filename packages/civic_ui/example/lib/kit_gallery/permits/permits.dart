/// Brindlemere parking permits: a public service of an invented city, built
/// on Civic. The look's Overview, then the service: its start page, the
/// application's task list, its question pages (one thing per page), the
/// answers checked before sending, the confirmation, the reader's
/// applications and each one's record, the search for a permit zone, and
/// the reader's settings. English left to right, Arabic right to left.
library;

import 'package:material_ui/material_ui.dart';
import 'package:civic_ui/civic_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../gallery_words.dart';
import '../kit.dart';
import 'account.dart';
import 'flow.dart';
import 'overview.dart';
import 'words.dart';
import 'zones.dart';

export 'words.dart';

/// The service's pages.
enum PermitsPage {
  /// The look's Overview.
  overview,

  /// The start page.
  start,

  /// The application's task list.
  tasks,

  /// The question: what kind of vehicle.
  vehicle,

  /// The reader's details: name, address, date of birth, proof.
  details,

  /// The answers, checked before sending.
  check,

  /// The confirmation.
  sent,

  /// The reader's applications.
  applications,

  /// One application's record.
  application,

  /// The search for a permit zone.
  zones,

  /// The reader's settings.
  settings,
}

/// What the service's lists find as a page opens.
enum PermitsCondition {
  /// What there is.
  usual,

  /// Nothing: no applications yet, no streets that match.
  empty,

  /// The service cannot be reached.
  unavailable,
}

/// The pages of the service that stand under its navigation; the rest are
/// the flow, which shows none.
const _shellPages = [
  PermitsPage.overview,
  PermitsPage.start,
  PermitsPage.applications,
  PermitsPage.settings,
];

/// Where each inner page goes back to: in an app the top bar's back
/// control, on the site the page's back link.
const _backOf = {
  PermitsPage.tasks: PermitsPage.start,
  PermitsPage.vehicle: PermitsPage.tasks,
  PermitsPage.details: PermitsPage.vehicle,
  PermitsPage.check: PermitsPage.details,
  PermitsPage.application: PermitsPage.applications,
  PermitsPage.zones: PermitsPage.start,
};

/// The place an inner page stands in: an app's top bar says it, over the
/// page's own large heading.
String _placeOf(PermitsPage page) => switch (page) {
  PermitsPage.tasks ||
  PermitsPage.vehicle ||
  PermitsPage.details ||
  PermitsPage.check ||
  PermitsPage.sent => 'Apply for a permit',
  PermitsPage.application => 'Your applications',
  PermitsPage.zones => 'Find your permit zone',
  _ => 'Brindlemere parking permits',
};

/// The site's back link on an inner page; none in an app, whose top bar
/// holds the way back.
extension PermitsBackLink on BuildContext {
  /// The back link to the page before (which [to] names, for the reader of
  /// the code), or null in an app.
  Widget? backLinkTo(PermitsPage to) =>
      CivicLayout.isApp(MediaQuery.sizeOf(this).width)
      ? null
      : CivicBackLink(onPressed: permits.back);
}

/// The place [page] stands under and the inner pages over it, as a link
/// that opens on [page] stacks them: its way back runs to that place.
(PermitsPage, List<PermitsPage>) _stackTo(PermitsPage page) {
  final over = <PermitsPage>[];
  var at = page;
  while (!_shellPages.contains(at)) {
    over.insert(0, at);
    at = _backOf[at] ?? PermitsPage.start;
  }
  return (at, over);
}

/// How the app looks.
enum PermitsAppearance {
  /// By day.
  light,

  /// By night.
  dark,

  /// As the device is set.
  system,
}

/// One entry of the Overview's index of parts.
typedef PermitsPart = ({String title, Widget Function(Brightness) build});

/// The reader's settings, the answers of the application under way and
/// where the reader is: a place (one of the navigation's, shown in place in
/// the app's first page) and the inner pages pushed over it, each a
/// [CivicPageRoute], so the platform's back (Android's, a back-swipe) and
/// the bar's back control pop them.
class PermitsState extends ChangeNotifier {
  /// The state as the app opens, on [page].
  PermitsState({
    required PermitsAppearance initialAppearance,
    required bool initialArabic,
    required PermitsPage page,
    this.showErrors = false,
    this.condition = PermitsCondition.usual,
    bool filled = false,
    bool started = false,
  }) : _appearance = initialAppearance,
       _arabic = initialArabic,
       place = _stackTo(page).$1,
       initialOver = _stackTo(page).$2 {
    if (filled) _fill();
    if (started) {
      vehicle = 'car';
      name.text = 'Amara Okafor';
    }
    if (condition == PermitsCondition.empty) query = 'Quillon';
  }

  PermitsAppearance _appearance;
  bool _arabic;
  bool _largerText = false;

  /// The navigator the service's pages stand in.
  final GlobalKey<NavigatorState> navigator = GlobalKey();

  /// Keeps [_pages] in step with the navigator.
  late final NavigatorObserver observer = _PermitsObserver(this);

  /// The place the app's first page shows.
  PermitsPage place;

  /// The inner pages the app opens with over [place].
  final List<PermitsPage> initialOver;

  /// The inner pages' routes over the first page, bottom to top.
  final List<Route<void>> _pages = [];

  /// The page on top.
  PermitsPage get page =>
      _pages.isEmpty ? place : _pages.last.settings.arguments! as PermitsPage;

  /// Whether the details page shows its problems (it was sent with them).
  bool showErrors;

  /// What the lists find.
  PermitsCondition condition;

  /// The reference of the application whose record is open.
  String? application;

  /// The street searched for.
  String query = '';

  /// The zones the search keeps to; none keeps to none.
  final Set<String> zones = {};

  /// The page of results shown, from 0.
  int resultsPage = 0;

  /// The answers.
  String? vehicle;

  /// The reader's name.
  final TextEditingController name = TextEditingController();

  /// The first line of the address.
  final TextEditingController line1 = TextEditingController();

  /// The town.
  final TextEditingController town = TextEditingController();

  /// The postcode.
  final TextEditingController postcode = TextEditingController();

  /// The date of birth's day.
  final TextEditingController day = TextEditingController();

  /// Its month.
  final TextEditingController month = TextEditingController();

  /// Its year.
  final TextEditingController year = TextEditingController();

  /// The proof of address's file name.
  String? proof;

  /// How the reader likes to be contacted.
  final Set<String> contact = {'email'};

  /// Whether reminders are on.
  bool reminders = true;

  /// The application filter's statuses.
  final Set<String> statuses = {};

  /// Whether an app's filters are open.
  bool filtersOpen = false;

  void _fill() {
    vehicle = 'car';
    name.text = 'Amara Okafor';
    line1.text = '14 Ropewalk Row';
    town.text = 'Brindlemere';
    postcode.text = 'BR4 7QX';
    day.text = '27';
    month.text = '3';
    year.text = '1987';
    proof = 'tenancy-agreement.pdf';
  }

  /// How the app looks.
  PermitsAppearance get appearance => _appearance;
  set appearance(PermitsAppearance value) {
    _appearance = value;
    notifyListeners();
  }

  /// Whether it speaks Arabic, right to left.
  bool get arabic => _arabic;
  set arabic(bool value) {
    _arabic = value;
    notifyListeners();
  }

  /// Whether the words are larger.
  bool get largerText => _largerText;
  set largerText(bool value) {
    _largerText = value;
    notifyListeners();
  }

  /// The route of the inner page [to].
  Route<void> routeTo(PermitsPage to) => CivicPageRoute<void>(
    settings: RouteSettings(name: to.name, arguments: to),
    builder: (_) => _PermitsFrame(page: to),
  );

  /// Goes to [to]: a place of the navigation shows in the first page, in
  /// place, the inner pages over it closed; the confirmation stands over the
  /// first page alone (an application sent is not gone back into); any other
  /// page is pushed over the one shown.
  void go(PermitsPage to) {
    final nav = navigator.currentState;
    if (_shellPages.contains(to)) {
      place = to;
      if (_pages.isNotEmpty) nav?.popUntil((route) => route.isFirst);
      notifyListeners();
      return;
    }
    if (nav == null) return;
    if (to == PermitsPage.sent) {
      nav.pushAndRemoveUntil(routeTo(to), (route) => route.isFirst);
      return;
    }
    nav.push(routeTo(to));
  }

  /// A question's way on: back to the answers being checked when the reader
  /// came to change one, else to [to].
  void next(PermitsPage to) {
    final checking = _pages.where(
      (route) => route.settings.arguments == PermitsPage.check,
    );
    if (checking.isEmpty) return go(to);
    final check = checking.last;
    navigator.currentState?.popUntil((route) => route == check);
  }

  /// Back to the page before, as the platform's back goes.
  void back() => navigator.currentState?.maybePop();

  /// Tells the pages that an answer changed.
  void changed() => notifyListeners();

  /// Opens the record of the application [reference] over the list.
  void openApplication(String reference) {
    application = reference;
    go(PermitsPage.application);
  }

  /// Shows the record of [reference] beside the list (a tablet's).
  void showApplication(String reference) {
    application = reference;
    notifyListeners();
  }

  @override
  void dispose() {
    for (final c in [name, line1, town, postcode, day, month, year]) {
      c.dispose();
    }
    super.dispose();
  }
}

class _PermitsObserver extends NavigatorObserver {
  _PermitsObserver(this.state);

  final PermitsState state;

  bool _ours(Route<dynamic> route) => route.settings.arguments is PermitsPage;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (_ours(route)) state._pages.add(route as Route<void>);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    state._pages.remove(route);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    state._pages.remove(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final at = state._pages.indexOf(oldRoute as Route<void>? ?? _none);
    if (at < 0) return;
    if (newRoute != null && _ours(newRoute)) {
      state._pages[at] = newRoute as Route<void>;
    } else {
      state._pages.removeAt(at);
    }
  }

  static final Route<void> _none = PageRouteBuilder<void>(
    pageBuilder: (_, _, _) => const SizedBox.shrink(),
  );
}

class _PermitsScope extends InheritedNotifier<PermitsState> {
  const _PermitsScope({required PermitsState state, required super.child})
    : super(notifier: state);
}

/// The app's state, from anywhere under it.
extension PermitsStateOf on BuildContext {
  /// The app's state.
  PermitsState get permits =>
      dependOnInheritedWidgetOfExactType<_PermitsScope>()!.notifier!;
}

/// The service, opened on [initialPage].
class PermitsApp extends StatefulWidget {
  /// The app.
  const PermitsApp({
    super.key,
    this.initialPage = PermitsPage.overview,
    this.initialAppearance = PermitsAppearance.light,
    this.initialDirection = TextDirection.ltr,
    this.textScale,
    this.showErrors = false,
    this.filled = false,
    this.condition = PermitsCondition.usual,
    this.parts = const [],
    this.initialPart,
  });

  /// The page it opens on.
  final PermitsPage initialPage;

  /// How it looks as it opens.
  final PermitsAppearance initialAppearance;

  /// Its reading direction as it opens: right to left speaks Arabic.
  final TextDirection initialDirection;

  /// The text scale, over the device's.
  final double? textScale;

  /// Whether the details page opens showing its problems.
  final bool showErrors;

  /// Whether the application opens with its answers given.
  final bool filled;

  /// What the lists find as it opens.
  final PermitsCondition condition;

  /// The parts' pages, for the Overview's index.
  final List<PermitsPart> parts;

  /// A part's page to open on.
  final int? initialPart;

  @override
  State<PermitsApp> createState() => _PermitsAppState();
}

class _PermitsAppState extends State<PermitsApp> {
  late final PermitsState _state = PermitsState(
    initialAppearance: widget.initialAppearance,
    initialArabic: widget.initialDirection == TextDirection.rtl,
    page: widget.initialPage,
    showErrors: widget.showErrors,
    condition: widget.condition,
    filled:
        widget.filled ||
        const [
          PermitsPage.check,
          PermitsPage.sent,
        ].contains(widget.initialPage),
    // The task list opens part way through: the vehicle chosen, the
    // details begun.
    started: widget.initialPage == PermitsPage.tasks,
  );

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _state,
    builder: (context, _) {
      final platform = MediaQuery.maybePlatformBrightnessOf(context);
      final brightness = switch (_state.appearance) {
        PermitsAppearance.light => Brightness.light,
        PermitsAppearance.dark => Brightness.dark,
        PermitsAppearance.system => platform ?? Brightness.light,
      };
      final rtl = _state.arabic;
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        // Civic's page change for every route the app pushes, a plain
        // MaterialPageRoute too, on every platform.
        theme: ThemeData(
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: civicPageTransitions,
          ),
        ),
        title: rtl
            ? permitsArabic['Brindlemere parking permits']!
            : 'Brindlemere parking permits',
        locale: rtl ? const Locale('ar') : const Locale('en'),
        localizationsDelegates: galleryDelegates,
        supportedLocales: RawWidgetsLocalizations.supportedLocales,
        color: kitTheme(brightness).action,
        navigatorKey: _state.navigator,
        navigatorObservers: [_state.observer],
        onGenerateInitialRoutes: (_) => [
          CivicPageRoute<void>(
            builder: (_) => _PermitsFrame(
              parts: widget.parts,
              initialPart: widget.initialPart,
            ),
          ),
          for (final page in _state.initialOver) _state.routeTo(page),
        ],
        onGenerateRoute: (_) => CivicPageRoute<void>(
          builder: (_) => _PermitsFrame(parts: widget.parts),
        ),
        builder: (context, child) {
          final device = MediaQuery.textScalerOf(context);
          final scale = widget.textScale ?? (_state.largerText ? 1.5 : null);
          return _PermitsScope(
            state: _state,
            child: Directionality(
              textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: scale == null ? device : TextScaler.linear(scale),
                ),
                child: AnimatedCivicTheme(
                  data: kitTheme(brightness),
                  child: CivicToaster(child: child ?? const SizedBox.shrink()),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

/// The service's frame: its top bar, its navigation on the pages that have
/// it, and the page: the inner [page] of a route over the first, or (null)
/// the first page's place, switched in place.
class _PermitsFrame extends StatefulWidget {
  const _PermitsFrame({this.page, this.parts = const [], this.initialPart});

  final PermitsPage? page;
  final List<PermitsPart> parts;
  final int? initialPart;

  @override
  State<_PermitsFrame> createState() => _PermitsFrameState();
}

class _PermitsFrameState extends State<_PermitsFrame> {
  @override
  void initState() {
    super.initState();
    final part = widget.initialPart;
    if (part != null && part < widget.parts.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) openPermitsPart(context, widget.parts[part]);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.permits;
    final page = widget.page ?? state.place;
    // An application's record stands under Applications.
    final place = page == PermitsPage.application
        ? PermitsPage.applications
        : page;
    final shell = _shellPages.contains(place);
    final destinations = [
      CivicNavigationDestination(
        icon: LucideIcons.layoutGrid,
        label: context.say('Overview'),
      ),
      CivicNavigationDestination(
        icon: LucideIcons.squarePen,
        label: context.say('Apply'),
      ),
      CivicNavigationDestination(
        icon: LucideIcons.fileText,
        label: context.say('Applications'),
      ),
      CivicNavigationDestination(
        icon: LucideIcons.settings,
        label: context.say('Settings'),
      ),
    ];
    final index = _shellPages.indexOf(place);
    void select(int i) => state.go(_shellPages[i]);
    final app = CivicLayout.isApp(MediaQuery.sizeOf(context).width);
    // A tablet's record stands beside the list it opens from: no way back.
    final back = page == PermitsPage.application && permitsPanes(context)
        ? null
        : _backOf[page];
    return CivicScaffold(
      skipLinkLabel: context.say('Skip to main content'),
      // An app's inner page: the way back and the page's place in the bar;
      // the site's masthead (and an app's places) say whose service it is.
      topBar: app && (!shell || back != null)
          ? CivicTopBar(
              title: context.say(_placeOf(page)),
              leading: back == null
                  ? null
                  : CivicTopBar.backButton(context, onPressed: state.back),
            )
          : CivicTopBar(
              title: context.say('Brindlemere parking permits'),
              emblem: const KitEmblem(),
              onTitlePressed: () => state.go(PermitsPage.start),
            ),
      navigationBar: shell
          ? CivicNavigationBar(
              destinations: destinations,
              selectedIndex: index,
              onDestinationSelected: select,
            )
          : null,
      sideNavigation: shell
          ? CivicSideNavigation(
              destinations: destinations,
              selectedIndex: index,
              onDestinationSelected: select,
            )
          : null,
      body: KeyedSubtree(
        key: ValueKey(page),
        child: switch (page) {
          PermitsPage.overview => PermitsOverview(parts: widget.parts),
          PermitsPage.start => const PermitsStartPage(),
          PermitsPage.tasks => const PermitsTasksPage(),
          PermitsPage.vehicle => const PermitsVehiclePage(),
          PermitsPage.details => const PermitsDetailsPage(),
          PermitsPage.check => const PermitsCheckPage(),
          PermitsPage.sent => const PermitsSentPage(),
          PermitsPage.applications => const PermitsApplicationsPage(),
          PermitsPage.application => const PermitsApplicationPage(),
          PermitsPage.zones => const PermitsZonesPage(),
          PermitsPage.settings => const PermitsSettingsPage(),
        },
      ),
    );
  }
}

/// Opens [part]'s page over the app, in the app's brightness.
void openPermitsPart(BuildContext context, PermitsPart part) {
  final brightness = context.civicTheme.brightness;
  Navigator.of(context)
      .push(CivicPageRoute<void>(builder: (_) => part.build(brightness)));
}

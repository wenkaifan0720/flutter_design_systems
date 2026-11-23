/// Quill: the example's product, a household ledger set in Ledger. Four
/// destinations (the look's Overview, Home, the Register and Settings) and
/// one act (a new entry), moved between by the look's own navigation: the
/// tab bar on a phone, the rail on a tablet, the side bar from 1024.
///
/// Settings drives the app: the appearance (light, dark or the system's),
/// the reading direction and the density, so every screen shows them as
/// they are set.
library;

import 'package:material_ui/material_ui.dart';
import 'package:ledger_ui/ledger_ui.dart';
import 'package:ledger_ui/ledger_host.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../gallery_words.dart';
import '../kit.dart';
import 'entry.dart';
import 'home.dart';
import 'overview.dart';
import 'register.dart';
import 'settings.dart';
import 'words.dart';

/// Where the app opens.
enum QuillPage { overview, home, register, settings }

/// A state of a destination Quill can open straight onto, as a link or a
/// sweep of its everyday screens does: the Register searching or finding
/// nothing, an entry's receipt, a new entry, the Sign out question over
/// Settings, or an account's sheet over Home.
enum QuillScene { searching, nothingFound, receipt, newEntry, signOut, account }

/// How the app is lit.
enum QuillAppearance { light, dark, system }

/// What the app keeps while it runs: what Settings sets for the whole app,
/// the owner's profile and session, and the entries saved to the register.
class QuillPrefs extends ChangeNotifier {
  QuillPrefs({
    this.appearance = QuillAppearance.light,
    this.direction = TextDirection.ltr,
    LedgerDensity? density,
  }) : density = density ?? LedgerDensity.standard;

  QuillAppearance appearance;
  LedgerDensity density;

  /// Which way the pages read: right to left mirrors them, as for Arabic
  /// or Hebrew.
  TextDirection direction;

  /// The alerts, by name: on or off.
  final Map<String, bool> alerts = {for (final a in kitAlerts) a.label: a.on};

  String weekStart = 'monday';

  /// Whether the owner is signed in. Signed out, Quill keeps this device's
  /// settings and asks for a sign-in before it shows an account or an entry.
  bool signedIn = true;

  /// The owner's name once changed in Settings; null: the sample owner's.
  String? name;
  String email = 'maren.holt@example.com';
  String phone = '(415) 555-0119';

  /// The entries saved in this session, newest first.
  final List<KitTx> saved = [];

  void update(void Function(QuillPrefs prefs) change) {
    change(this);
    notifyListeners();
  }

  /// Adds [entry] to the register.
  void save(KitTx entry) => update((p) => p.saved.insert(0, entry));

  /// The register's days, each with the entries saved to it in this
  /// session, newest first, and its net with them.
  List<KitDay> get days {
    final days = [...kitDays];
    for (final entry in saved.reversed) {
      final i = days.indexWhere((d) => d.label == entry.day);
      final day = i < 0 ? KitDay(entry.day, null, 0, const []) : days[i];
      final rows = [...day.rows, entry]..sort((a, b) => b.at.compareTo(a.at));
      final next = KitDay(day.label, day.note, day.net + entry.amount, rows);
      if (i < 0) {
        days.insert(0, next);
      } else {
        days[i] = next;
      }
    }
    return days;
  }

  /// The [QuillPrefs] above [context].
  static QuillPrefs of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_QuillScope>()!.notifier!;

  /// The [QuillPrefs] above [context], or null outside a [QuillApp].
  static QuillPrefs? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_QuillScope>()?.notifier;
}

/// The register's days as the app holds them: [QuillPrefs.days], or the
/// sample's outside a [QuillApp].
List<KitDay> quillDays(BuildContext context) =>
    QuillPrefs.maybeOf(context)?.days ?? kitDays;

/// Whether the owner is signed in above [context] (outside a [QuillApp],
/// always).
bool quillSignedIn(BuildContext context) =>
    QuillPrefs.maybeOf(context)?.signedIn ?? true;

/// The owner's name as the app shows it: the one set in Settings, else the
/// sample owner's, in Quill's language.
String quillOwnerName(BuildContext context) =>
    QuillPrefs.maybeOf(context)?.name ?? context.say(kitMaren.name);

/// What a page shows in place of the account while the owner is signed out:
/// why, and Sign in, which brings the account back.
class QuillSignedOut extends StatelessWidget {
  const QuillSignedOut({super.key});

  @override
  Widget build(BuildContext context) => LedgerEmptyState(
    title: context.say('You are signed out'),
    body: context.say('Sign in to see your accounts and entries.'),
    actionLabel: context.say('Sign in'),
    onActionPressed: () =>
        QuillPrefs.of(context).update((p) => p.signedIn = true),
  );
}

/// A page titled [title] holding [QuillSignedOut].
class QuillSignedOutPage extends StatelessWidget {
  const QuillSignedOutPage({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) => LedgerScreen(
    topBar: LedgerTopBar(title: title),
    body: const QuillSignedOut(),
  );
}

class _QuillScope extends InheritedNotifier<QuillPrefs> {
  const _QuillScope({required QuillPrefs prefs, required super.child})
    : super(notifier: prefs);
}

/// The app: themed by [QuillPrefs], the owner's account above its
/// navigator, opening on [initialPage].
class QuillApp extends StatefulWidget {
  const QuillApp({
    this.initialPage = QuillPage.overview,
    this.initialAppearance = QuillAppearance.light,
    this.parts = const [],
    this.initialDensity,
    this.initialDirection = TextDirection.ltr,
    this.textScale,
    this.initialPart,
    this.registerOffline = false,
    this.initialScene,
    super.key,
  });

  final QuillPage initialPage;
  final QuillAppearance initialAppearance;

  /// The state of [initialPage] it opens on; null: the page as it first
  /// stands.
  final QuillScene? initialScene;

  /// Whether the Register opens unable to load (its error state).
  final bool registerOffline;

  /// The direction it opens in. Settings changes it after.
  final TextDirection initialDirection;

  /// A text scale over the platform's, to see the app at a larger size;
  /// null keeps the platform's.
  final double? textScale;

  /// The index in [parts] of a part whose page opens over [initialPage]
  /// after the first frame, as the Overview's index opens it; null: none.
  final int? initialPart;

  /// The density it opens at; null: standard. Settings changes it after.
  final LedgerDensity? initialDensity;

  /// The package's parts, for the Overview's index: each part's name and
  /// its page, by day or by night.
  final List<QuillPart> parts;

  @override
  State<QuillApp> createState() => _QuillAppState();
}

/// One entry of the Overview's index of parts.
typedef QuillPart = ({String title, Widget Function(Brightness) build});

class _QuillAppState extends State<QuillApp> {
  late final QuillPrefs _prefs = QuillPrefs(
    appearance: widget.initialAppearance,
    direction: widget.initialDirection,
    density: widget.initialDensity,
  );

  @override
  void dispose() {
    _prefs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _prefs,
    builder: (context, _) {
      final density = _prefs.density;
      final frame = QuillFrame(
        initialPage: widget.initialPage,
        parts: widget.parts,
        initialPart: widget.initialPart,
        registerOffline: widget.registerOffline,
        initialScene: widget.initialScene,
      );
      // A semantics container of its own, so an app this one stands inside
      // keeps what it painted before it (a route's barrier hides that).
      return Semantics(
        container: true,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          // A pushed page laid down in Ledger's motion (Flutter's routes read
          // the app's theme, not the host's).
          theme: kitAppTheme,
          // Hebrew while it reads right to left, else English: ui_core's words
          // (Cancel, Close, Search, Today...) in either, from its 30.
          locale: _prefs.direction == TextDirection.rtl
              ? const Locale('he')
              : const Locale('en'),
          localizationsDelegates: galleryDelegates,
          supportedLocales: RawWidgetsLocalizations.supportedLocales,
          // The phone bar's wordmark reads it: Quill's name in its language.
          title: _prefs.direction == TextDirection.rtl
              ? quillHebrewWords['Quill']!
              : 'Quill',
          // The window's link (`/#/inputs?theme=dark`) chose the page already:
          // the app opens on its frame, never on a route named by the link.
          // (onGenerateRoute is what gives the app its Navigator at all.)
          onGenerateInitialRoutes: (_) => [
            MaterialPageRoute<void>(builder: (_) => frame),
          ],
          onGenerateRoute: (_) =>
              MaterialPageRoute<void>(builder: (_) => frame),
          builder: (context, child) => _QuillScope(
            prefs: _prefs,
            // The whole app reads as Settings sets it, its routes included.
            child: Directionality(
              textDirection: _prefs.direction,
              child: _scaled(
                context,
                LedgerHost(
                  theme: LedgerThemeData.light(density: density),
                  darkTheme: LedgerThemeData.dark(density: density),
                  brightness: switch (_prefs.appearance) {
                    QuillAppearance.light => Brightness.light,
                    QuillAppearance.dark => Brightness.dark,
                    QuillAppearance.system => null,
                  },
                  // The owner in the app's language (Hebrew right to left),
                  // under the name set in Settings; none while signed out.
                  child: Builder(
                    builder: (context) {
                      final page = child ?? const SizedBox.shrink();
                      if (!_prefs.signedIn) return page;
                      return LedgerAccountScope(
                        account: _owner(context),
                        child: page,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );

  LedgerAccount _owner(BuildContext context) {
    final owner = context.sayOwner;
    final name = _prefs.name;
    if (name == null) return owner;
    return LedgerAccount(
      name: name,
      initials: quillInitials(name),
      meta: owner.meta,
      unread: owner.unread,
      onProfilePressed: owner.onProfilePressed,
      onNotificationsPressed: owner.onNotificationsPressed,
      profileLocation: owner.profileLocation,
      notificationsLocation: owner.notificationsLocation,
      searchHint: owner.searchHint,
      onSearchPressed: owner.onSearchPressed,
    );
  }

  Widget _scaled(BuildContext context, Widget child) {
    final scale = widget.textScale;
    if (scale == null) return child;
    return MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(scale)),
      child: child,
    );
  }
}

/// The app's frame: the current destination under the look's navigation,
/// the new-entry act beside the destinations. From the rail's width (600) a
/// pushed page (an entry, a receipt) opens in the frame, beside the rail or
/// the side bar, as the sample bank's desktop detail does; on a phone it covers
/// the tab bar.
class QuillFrame extends StatefulWidget {
  const QuillFrame({
    this.initialPage = QuillPage.overview,
    this.parts = const [],
    this.initialPart,
    this.registerOffline = false,
    this.initialScene,
    super.key,
  });

  final QuillPage initialPage;
  final List<QuillPart> parts;

  /// As [QuillApp.initialScene].
  final QuillScene? initialScene;

  /// As [QuillApp.registerOffline].
  final bool registerOffline;

  /// As [QuillApp.initialPart].
  final int? initialPart;

  @override
  State<QuillFrame> createState() => QuillFrameState();
}

/// [QuillFrame]'s state: where a pushed page opens.
class QuillFrameState extends State<QuillFrame> {
  late QuillPage _page = widget.initialPage;

  /// The scene the first destination opens on, gone once another is chosen.
  late QuillScene? _scene = widget.initialScene;

  /// The frame's own navigator from the rail's width; none on a phone.
  final _desk = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    // A scene pushed over the destination, after the first frame, where a
    // tap opens it; the Register's and Settings' own open in them.
    final scene = _scene;
    if (scene != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        switch (scene) {
          case QuillScene.receipt:
            push(QuillReceiptPage(tx: kitDays.first.rows.first));
          case QuillScene.newEntry:
            _newEntry();
          case QuillScene.account:
            showQuillAccount(context, kitAccounts.first);
          case QuillScene.searching ||
              QuillScene.nothingFound ||
              QuillScene.signOut:
            break;
        }
      });
    }
    final part = widget.initialPart;
    if (part == null || part < 0 || part >= widget.parts.length) return;
    // After the first frame, where the index's tap opens it: the frame's
    // navigator from 600, the app's on a phone.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        push(widget.parts[part].build(context.ledgerTheme.brightness));
      }
    });
  }

  /// Opens [page] over the current destination: in the frame from 600,
  /// over the whole app on a phone.
  void push(Widget page) {
    final route = MaterialPageRoute<void>(builder: (_) => page);
    final desk = _desk.currentState;
    if (desk != null) {
      desk.push(route);
    } else {
      Navigator.of(context).push(route);
    }
  }

  static List<LedgerNavItem> _destinations(BuildContext context) => [
    LedgerNavItem(
      LucideIcons.bookOpen,
      context.say('Ledger'),
      const ValueKey('tab-overview'),
    ),
    LedgerNavItem(
      LucideIcons.house,
      context.say('Home'),
      const ValueKey('tab-home'),
    ),
    LedgerNavItem(
      LucideIcons.scrollText,
      context.say('Register'),
      const ValueKey('tab-register'),
    ),
    LedgerNavItem(
      LucideIcons.settings,
      context.say('Settings'),
      const ValueKey('tab-settings'),
    ),
  ];

  void _go(QuillPage page) => setState(() {
    _page = page;
    _scene = null;
  });

  /// Ends the session: closes what was pushed (a receipt, an entry, a part's
  /// page) and leaves the owner on Settings, signed out.
  void signOut() {
    Navigator.of(context).popUntil((r) => r.isFirst);
    _desk.currentState?.popUntil((r) => r.isFirst);
    QuillPrefs.of(context).update((p) => p.signedIn = false);
    _go(QuillPage.settings);
  }

  void _newEntry() => push(const QuillEntryPage());

  @override
  Widget build(BuildContext context) {
    final page = switch (_page) {
      QuillPage.overview => QuillOverview(
        onOpen: _go,
        onNewEntry: _newEntry,
        parts: widget.parts,
      ),
      QuillPage.home => QuillHome(onOpen: _go),
      QuillPage.register => QuillRegister(
        offline: widget.registerOffline,
        initialQuery: switch (_scene) {
          QuillScene.searching => 'Blue Fern',
          QuillScene.nothingFound => 'Zanzibar',
          _ => null,
        },
      ),
      QuillPage.settings => QuillSettings(
        askSignOut: _scene == QuillScene.signOut,
      ),
    };
    // A destination's own pushes (a register row's receipt) reach the
    // nearest navigator: the frame's from 600. Choosing another
    // destination replaces its page in place, and what was pushed on it
    // goes too; only a push is laid down in Ledger's page motion.
    final framed =
        MediaQuery.sizeOf(context).width >= LedgerNavigationFrame.railFrom;
    return LedgerNavigationFrame(
      destinations: _destinations(context),
      selectedIndex: _page.index,
      onDestinationSelected: (i) => _go(QuillPage.values[i]),
      brand: context.say('Quill'),
      action: ShellAction(
        icon: LucideIcons.plus,
        label: context.say('New entry'),
        onPressed: (_) => _newEntry(),
      ),
      body: framed
          // A semantics container of its own: a route's barrier hides from a
          // screen reader what was painted before it in its container, and
          // the side bar and the top bar are painted before the body.
          ? Semantics(
              container: true,
              child: Navigator(
                key: _desk,
                pages: [_InPlace(key: ValueKey(_page), child: page)],
                onDidRemovePage: (_) {},
              ),
            )
          : KeyedSubtree(key: ValueKey(_page), child: page),
    );
  }
}

/// A destination's page in the frame's navigator: chosen from the side bar
/// or the rail, it changes in place, as the tab bar's does on a phone. What
/// is pushed over it is laid down in Ledger's page motion.
class _InPlace extends Page<void> {
  const _InPlace({required this.child, super.key});

  final Widget child;

  @override
  Route<void> createRoute(BuildContext context) => _InPlaceRoute(this);
}

class _InPlaceRoute extends PageRoute<void> {
  _InPlaceRoute(_InPlace page) : super(settings: page);

  @override
  Duration get transitionDuration => Duration.zero;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => (settings as _InPlace).child;
}

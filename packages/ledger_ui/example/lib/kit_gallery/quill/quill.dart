/// Quill: the example's product, a household ledger set in Ledger. Four
/// destinations (the look's Overview, Home, the Register and Settings) and
/// one act (a new entry), moved between by the look's own navigation: the
/// tab bar on a phone, the rail on a tablet, the side bar from 1024.
///
/// Settings drives the app: the appearance (light, dark or the system's),
/// the reading direction and the density, so every screen shows them as
/// they are set.
library;

import 'package:flutter/material.dart';
import 'package:ledger_ui/ledger_ui.dart';
import 'package:ledger_ui/ledger_host.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';
import 'entry.dart';
import 'home.dart';
import 'overview.dart';
import 'register.dart';
import 'settings.dart';

/// Where the app opens.
enum QuillPage { overview, home, register, settings }

/// How the app is lit.
enum QuillAppearance { light, dark, system }

/// What Settings sets for the whole app.
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

  String currency = 'USD';
  String weekStart = 'monday';

  void update(void Function(QuillPrefs prefs) change) {
    change(this);
    notifyListeners();
  }

  /// The [QuillPrefs] above [context].
  static QuillPrefs of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_QuillScope>()!.notifier!;
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
    super.key,
  });

  final QuillPage initialPage;
  final QuillAppearance initialAppearance;

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
      );
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Quill',
        // The window's link (`/#/inputs?theme=dark`) chose the page already:
        // the app opens on its frame, never on a route named by the link.
        // (onGenerateRoute is what gives the app its Navigator at all.)
        onGenerateInitialRoutes: (_) => [
          MaterialPageRoute<void>(builder: (_) => frame),
        ],
        onGenerateRoute: (_) => MaterialPageRoute<void>(builder: (_) => frame),
        builder: (context, child) => _QuillScope(
          prefs: _prefs,
          // The whole app reads as Settings sets it, its routes included.
          child: Directionality(
            textDirection: _prefs.direction,
            child: _scaled(
              context,
              LedgerHost(
                light: LedgerThemeData.light(density: density),
                dark: LedgerThemeData.dark(density: density),
                brightness: switch (_prefs.appearance) {
                  QuillAppearance.light => Brightness.light,
                  QuillAppearance.dark => Brightness.dark,
                  QuillAppearance.system => null,
                },
                child: LedgerAccountScope(
                  account: kitMaren,
                  child: child ?? const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );

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
/// the side bar, as the pilot's desktop detail does; on a phone it covers
/// the tab bar.
class QuillFrame extends StatefulWidget {
  const QuillFrame({
    this.initialPage = QuillPage.overview,
    this.parts = const [],
    this.initialPart,
    super.key,
  });

  final QuillPage initialPage;
  final List<QuillPart> parts;

  /// As [QuillApp.initialPart].
  final int? initialPart;

  @override
  State<QuillFrame> createState() => QuillFrameState();
}

/// [QuillFrame]'s state: where a pushed page opens.
class QuillFrameState extends State<QuillFrame> {
  late QuillPage _page = widget.initialPage;

  /// The frame's own navigator from the rail's width; none on a phone.
  final _desk = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
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

  static const _destinations = [
    LedgerNavItem(LucideIcons.bookOpen, 'Ledger', ValueKey('tab-overview')),
    LedgerNavItem(LucideIcons.house, 'Home', ValueKey('tab-home')),
    LedgerNavItem(LucideIcons.scrollText, 'Register', ValueKey('tab-register')),
    LedgerNavItem(LucideIcons.settings, 'Settings', ValueKey('tab-settings')),
  ];

  void _go(QuillPage page) => setState(() => _page = page);

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
      QuillPage.register => const QuillRegister(),
      QuillPage.settings => const QuillSettings(),
    };
    // A destination's own pushes (a register row's receipt) reach the
    // nearest navigator: the frame's from 600. Choosing another
    // destination replaces its page, and what was pushed on it goes too.
    final framed =
        MediaQuery.sizeOf(context).width >= LedgerNavigationFrame.railFrom;
    return LedgerNavigationFrame(
      destinations: _destinations,
      selectedIndex: _page.index,
      onDestinationSelected: (i) => _go(QuillPage.values[i]),
      brand: 'Quill',
      action: ShellAction(
        icon: LucideIcons.plus,
        label: 'New entry',
        onPressed: (_) => _newEntry(),
      ),
      body: framed
          ? Navigator(
              key: _desk,
              pages: [MaterialPage<void>(key: ValueKey(_page), child: page)],
              onDidRemovePage: (_) {},
            )
          : KeyedSubtree(key: ValueKey(_page), child: page),
    );
  }
}

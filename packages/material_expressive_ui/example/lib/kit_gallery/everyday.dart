/// Ordinary app compositions for trying the components in context: the
/// trip planner ([TripApp]) and three pages of its world.
library;

import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';

import 'kit.dart';
import 'trip.dart';

/// The trip planner's five screens (its own app, [TripApp]), then three
/// ordinary pages for trying the components in context.
const everydayGalleryPages =
    <({String id, String title, Widget Function(Brightness) build})>[
      (id: 'everyday-home', title: 'Trip planner', build: everydayHome),
      (id: 'everyday-form', title: 'Edit trip', build: everydayForm),
      (id: 'everyday-list', title: 'Shared with you', build: everydayList),
      (id: 'everyday-checkout', title: 'Hike kit', build: everydayCheckout),
      (id: 'everyday-settings', title: 'Preferences', build: everydaySettings),
      (id: 'everyday-dialog', title: 'Everyday dialog', build: everydayDialog),
      (id: 'everyday-tabs', title: 'Everyday tabs', build: everydayTabs),
      (id: 'everyday-cards', title: 'Everyday card grid', build: everydayCards),
    ];

/// The trip planner on its Home.
Widget everydayHome(Brightness brightness) =>
    _EverydayHost(brightness: brightness, child: const TripApp());

/// The trip planner's form: the trip's details.
Widget everydayForm(Brightness brightness) => _EverydayHost(
  brightness: brightness,
  child: const TripApp(screen: TripScreens.plan),
);

/// A reversible decision raised as a real modal dialog.
Widget everydayDialog(Brightness brightness) =>
    _EverydayHost(brightness: brightness, child: const _Dialog());

/// The trip planner's list: what the group shares.
Widget everydayList(Brightness brightness) => _EverydayHost(
  brightness: brightness,
  child: const TripApp(screen: TripScreens.shared),
);

/// Tabs whose selected content changes with the indicator.
Widget everydayTabs(Brightness brightness) =>
    _EverydayHost(brightness: brightness, child: const _Tabs());

/// A responsive grid of useful, clickable cards.
Widget everydayCards(Brightness brightness) =>
    _EverydayHost(brightness: brightness, child: const _Cards());

/// The trip planner's settings.
Widget everydaySettings(Brightness brightness) => _EverydayHost(
  brightness: brightness,
  child: const TripApp(screen: TripScreens.preferences),
);

/// The trip planner's checkout: the hike kit.
Widget everydayCheckout(Brightness brightness) => _EverydayHost(
  brightness: brightness,
  child: const TripApp(screen: TripScreens.kit),
);

class _EverydayHost extends StatelessWidget {
  const _EverydayHost({required this.brightness, required this.child});

  final Brightness brightness;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Its own screen to assistive technology: its first route's barrier hides
    // only what it paints, never the gallery around it.
    return Semantics(
      container: true,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: kitAppTheme,
        localizationsDelegates: const [
          RawWidgetsLocalizations.delegate,
          DefaultMaterialLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
        // The trip planner reads in the page's direction (its own app's
        // English locale would turn a right-to-left page left to right).
        builder: (inner, _) => Directionality(
          textDirection:
              Directionality.maybeOf(context) ?? Directionality.of(inner),
          child: ExpressiveHost(
            theme: kitTheme(Brightness.light),
            darkTheme: kitTheme(Brightness.dark),
            brightness: brightness,
            // Its own navigator, not its app's: on the web an app's navigator
            // lets Tab leave the window at the page's last control, and the
            // gallery's bars and rail around it were never reached.
            child: Navigator(
              clipBehavior: Clip.none,
              routeTraversalEdgeBehavior: TraversalEdgeBehavior.parentScope,
              // The page stands in its route without a transition: a pushed
              // route's Cupertino slide (iOS) keeps its edge shadow
              // painted beside the page, a grey band over the gallery's rail.
              onGenerateRoute: (settings) => PageRouteBuilder<void>(
                settings: settings,
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
                pageBuilder: (_, _, _) => child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Frame extends StatelessWidget {
  const _Frame({
    required this.title,
    required this.subtitle,
    required this.child,
    this.maxWidth = 960,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final double maxWidth;

  /// The page's side margin.
  static const double _margin = 24;

  /// Where a small top app bar's title starts (Material's title inset).
  static const double _barTitleStart = 16;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    // The bar's title starts on the content column's edge: the bar keeps
    // its row clear of the window's side insets, so the column's margin
    // (less the 16dp the title already stands in) joins them. The bar's
    // ground still runs the full width.
    final media = MediaQuery.of(context);
    final window = media.size.width;
    final column = math.min(maxWidth, math.max(0.0, window - 2 * _margin));
    final columnStart = (window - column) / 2;
    final barInset = math.max(0.0, columnStart - _barTitleStart);
    // In the live example the example's own app bar stands over the screen,
    // and the column starts where its title and tabs do: the compact
    // margin, on the start edge.
    if (KitLiveViewport.of(context)) {
      return ExpressiveScaffold(
        title: 'Trip planner',
        topBar: ExpressiveAppBar.none,
        padding: const EdgeInsets.fromLTRB(
          ExpressiveChromeMetrics.margin,
          24,
          ExpressiveChromeMetrics.margin,
          40,
        ),
        body: _column(context, t, AlignmentDirectional.topStart),
      );
    }
    return ExpressiveScaffold(
      title: 'Trip planner',
      topBar: MediaQuery(
        data: media.copyWith(
          padding: media.padding.copyWith(
            left: media.padding.left + barInset,
            right: media.padding.right + barInset,
          ),
        ),
        child: const ExpressiveAppBar(title: 'Trip planner'),
      ),
      padding: const EdgeInsets.fromLTRB(_margin, 24, _margin, 40),
      body: _column(context, t, Alignment.topCenter),
    );
  }

  Widget _column(
    BuildContext context,
    ExpressiveThemeData t,
    AlignmentGeometry alignment,
  ) => Align(
    alignment: alignment,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: t.type.headlineMedium.copyWith(color: t.colors.onSurface),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: t.type.bodyMedium.copyWith(color: t.colors.onSurfaceVariant),
          ),
          const SizedBox(height: 32),
          child,
        ],
      ),
    ),
  );
}

class _Dialog extends StatefulWidget {
  const _Dialog();

  @override
  State<_Dialog> createState() => _DialogState();
}

class _DialogState extends State<_Dialog> {
  String? _result;

  Future<void> _archive() async {
    final w = TripWords.read(context);
    final archived = await showExpressiveDialog<bool>(
      context: context,
      builder: (context) => ExpressiveDialog(
        title: w.archiveTitle,
        text: w.archiveText,
        actions: [
          ExpressiveDialogAction(w.keepTrip, value: false),
          ExpressiveDialogAction(w.archive, value: true, filled: true),
        ],
      ),
    );
    if (mounted && archived != null) {
      setState(() => _result = archived ? w.tripArchived : w.tripKept);
    }
  }

  @override
  Widget build(BuildContext context) => _dialogFrame(TripWords.of(context));

  // Right to left, its words are Arabic (TripWords), as the trip
  // planner's are.
  Widget _dialogFrame(TripWords w) => _Frame(
    title: w.pastTrips,
    subtitle: w.pastTripsLine,
    maxWidth: 680,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 24,
      children: [
        // A static row in the column: its icon on the column's edge, under
        // the heading, not 16dp in (the list item's inset is for rows that
        // run edge to edge).
        ExpressiveListTile(
          title: Text(w.portoInMay),
          subtitle: Text(w.portoLine),
          leading: const Icon(ExpressiveSymbols.flight),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
        ExpressiveOutlinedButton(
          w.archiveTrip,
          key: const ValueKey('everyday-open-dialog'),
          onPressed: _archive,
        ),
        if (_result != null) Semantics(liveRegion: true, child: Text(_result!)),
      ],
    ),
  );
}

class _Tabs extends StatefulWidget {
  const _Tabs();

  @override
  State<_Tabs> createState() => _TabsState();
}

class _TabsState extends State<_Tabs> {
  var _selected = 0;

  @override
  Widget build(BuildContext context) => _tabsFrame(TripWords.of(context));

  Widget _tabsFrame(TripWords w) => _Frame(
    title: w.myTrips,
    subtitle: w.myTripsLine,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 32,
      children: [
        ExpressiveTabBar(
          variant: ExpressiveTabBarVariant.secondary,
          tabs: [
            ExpressiveTab(
              label: w.upcoming,
              key: const ValueKey('everyday-tab-upcoming'),
            ),
            ExpressiveTab(
              label: w.saved,
              key: const ValueKey('everyday-tab-saved'),
            ),
            ExpressiveTab(
              label: w.past,
              key: const ValueKey('everyday-tab-past'),
            ),
          ],
          selectedIndex: _selected,
          onChanged: (index) => setState(() => _selected = index),
        ),
        ExpressiveListTile(
          key: ValueKey('everyday-trip-$_selected'),
          title: Text(w.myTripRows[_selected].$1),
          subtitle: Text(w.myTripRows[_selected].$2),
          leading: const Icon(ExpressiveSymbols.flight),
        ),
      ],
    ),
  );
}

class _Cards extends StatefulWidget {
  const _Cards();

  @override
  State<_Cards> createState() => _CardsState();
}

class _CardsState extends State<_Cards> {
  /// The chosen place's index in [TripWords.places].
  int? _selected;

  /// Each card's key, in English whatever the words' language.
  static const _ids = [
    'Lisbon',
    'Porto',
    'Kyoto',
    'Copenhagen',
    'Oslo',
    'Marrakesh',
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final w = TripWords.of(context);
    final places = w.places;
    final selected = _selected;
    return _Frame(
      title: w.savedPlaces,
      subtitle: selected == null
          ? w.savedPlacesLine
          : w.placeChosen(places[selected].$1),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Base the column count on the available text width so city names
          // can wrap at larger text sizes.
          final room =
              constraints.maxWidth / MediaQuery.textScalerOf(context).scale(1);
          final columns = room >= 800
              ? 3
              : room >= 280
              ? 2
              : 1;
          Widget card(int index) {
            final (name, detail) = places[index];
            return ExpressiveCard.filled(
              key: ValueKey('everyday-card-${_ids[index]}'),
              onPressed: () => setState(() => _selected = index),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    ExpressiveSymbols.locationOn,
                    size: 32,
                    color: t.colors.primary,
                  ),
                  const SizedBox(height: 20),
                  Text(name, style: t.type.titleMedium),
                  const SizedBox(height: 8),
                  Text(detail, style: t.type.bodyMedium),
                ],
              ),
            );
          }

          // Rows of cards, each row's cards as tall as its tallest.
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 16,
            children: [
              for (var row = 0; row < places.length; row += columns)
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 16,
                    children: [
                      for (var i = row; i < row + columns; i++)
                        Expanded(
                          child: i < places.length
                              ? card(i)
                              : const SizedBox.shrink(),
                        ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

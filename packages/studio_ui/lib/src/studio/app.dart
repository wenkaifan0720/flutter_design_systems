/// Studio's app frame: what an app's pages stand in. [StudioHost] once over
/// the navigator; [StudioScreen] round each page, a panel of brushed metal;
/// [StudioPage] the route a push slides one in on (a sheet's is
/// `StudioSheetPage`); [StudioPreview] one page alone, as the app stands
/// it; [StudioLoadingState] and [StudioErrorState] a page whose data is on
/// its way or lost; [StudioInput] the plain one-line field; [StudioTab] and
/// [StudioShellAction] an app shell's places and its one act.
library;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart'
    show DefaultMaterialLocalizations, MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:ui_core/host.dart';
import 'package:ui_core/ui_core.dart';

import 'actions.dart';
import 'feedback.dart';
import 'internal/page_measure.dart';
import 'navigation.dart';
import 'overlays.dart';
import 'surface.dart';
import 'text_field.dart';
import 'theme.dart';
import 'transitions.dart';

/// The app's host, mounted once over its navigator (`WidgetsApp.builder`):
/// Studio's theme for the brightness asked for, its toasts and the chassis
/// under every page.
///
/// It builds [palette]'s theme by day and by night (or takes [theme] and
/// [darkTheme] as given), follows the platform's brightness unless
/// [brightness] pins one, and moves to a new brightness or palette smoothly,
/// every colour at once ([AnimatedStudioTheme]; at once under Reduce
/// Motion).
///
/// ```dart
/// MaterialApp(builder: (context, child) => StudioHost(palette: StudioThemeData.palettes[1], child: child!))
/// ```
class StudioHost extends StatelessWidget {
  /// Hosts [child] in [theme] or [darkTheme], as [brightness] (or the platform)
  /// asks; either left out is [palette]'s in that brightness.
  const StudioHost({
    super.key,
    this.palette,
    this.theme,
    this.darkTheme,
    this.brightness,
    required this.child,
  });

  /// The palette both brightnesses are built from, one of
  /// [StudioThemeData.palettes]; null takes the first, `anodised`.
  final RawNamedPalette? palette;

  /// The theme by day; null builds [palette]'s.
  final StudioThemeData? theme;

  /// The theme by night; null builds [palette]'s.
  final StudioThemeData? darkTheme;

  /// The brightness to draw in; null follows the preview's or the
  /// platform's.
  final Brightness? brightness;

  /// The app.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final wanted =
        brightness ??
        PreviewFrame.maybeOf(context)?.brightness ??
        MediaQuery.platformBrightnessOf(context);
    final data =
        (wanted == Brightness.dark ? darkTheme : theme) ??
        StudioThemeData.preset(
          (palette ?? StudioThemeData.palettes.first).id,
          wanted,
        );
    return AnimatedStudioTheme(
      data: data,
      child: StudioToaster(
        child: Builder(
          builder: (context) => ColoredBox(
            color: context.studioTheme.colors.chassis,
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<RawNamedPalette>(
          'palette',
          palette,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<StudioThemeData>(
          'light',
          theme,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<StudioThemeData>(
          'dark',
          darkTheme,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<Brightness>(
          'brightness',
          brightness,
          defaultValue: null,
        ),
      );
  }
}

/// A page: a panel of brushed metal with its [topBar] (a pushed page's way
/// back stands in it), its [body] in the page's margins on the 4 px grid, no
/// wider than [maxWidth], and its [footer] fixed at its foot on the bar's
/// metal. On a wide window the bar's title and actions, the body and the
/// footer's action share that one centred column. In a sheet it is as tall
/// as its content allows and stands on the sheet's own panel.
///
/// ```dart
/// StudioScreen(topBar: const StudioAppBar(title: 'Episode'), body: const Text('Recorded in one take.'))
/// ```
class StudioScreen extends StatelessWidget {
  /// A page of [body].
  const StudioScreen({
    super.key,
    required this.body,
    this.topBar,
    this.footer,
    this.scroll = true,
    this.fullBleed = false,
    this.scrollController,
    this.maxWidth = 1200,
  });

  /// The page's content.
  final Widget body;

  /// The bar over it, usually a [StudioAppBar]; null on a root that opens
  /// on its own head.
  final Widget? topBar;

  /// What stands fixed at the foot: the page's one action.
  final Widget? footer;

  /// Whether the page scrolls; false gives [body] the height left, to
  /// scroll itself.
  final bool scroll;

  /// Whether [body] takes the whole width with no margins of the page's.
  final bool fullBleed;

  /// The page's scroll controller.
  final ScrollController? scrollController;

  /// The page's measure: the widest its column stands on a wide window, the
  /// bar's title and actions, the body and the footer's action on it. A
  /// form's page might take 600.
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final theme = StudioTheme.of(context);
    final c = theme.colors;
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final margin = StudioSpacing.pageMargin(width);
    final sheet = RoutePresentation.of(context) == RoutePresentation.sheet;
    final bar = topBar;
    final foot = footer;
    // What the page keeps clear: the status bar with no bar over it, the
    // shell's act over a root, the home indicator with no footer under it.
    final top = bar == null && !sheet ? media.padding.top : 0.0;
    final bottom = foot == null ? media.padding.bottom : 0.0;
    final Widget page = fullBleed
        ? body
        : Padding(
            padding: EdgeInsets.fromLTRB(
              margin,
              StudioSpacing.large + top,
              margin,
              StudioSpacing.huge + ShellInsets.of(context) + bottom,
            ),
            child: body,
          );
    final Widget column = fullBleed
        ? page
        : Align(
            alignment: Alignment.topCenter,
            heightFactor: scroll ? 1 : null,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth + 2 * margin),
              child: page,
            ),
          );
    final Widget content = scroll
        ? SingleChildScrollView(
            controller: scrollController,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: column,
          )
        : column;
    final framed = width >= StudioMetrics.tablet && !sheet;
    // A drawer sheet hugs its content; a tall sheet, a whole-page one and a
    // page fill their room, the footer at the foot.
    Widget stack(bool hug) => Column(
      mainAxisSize: hug ? MainAxisSize.min : MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (bar != null) PageMeasure(maxWidth: maxWidth, child: bar),
        if (hug) Flexible(child: content) else Expanded(child: content),
        if (foot != null)
          // The foot: a strip of the bar's metal, its action at the end
          // on a desk, the width of the page on a phone. A toast stands
          // above it, as a Scaffold keeps a snackbar above its persistent
          // footer buttons.
          RawToasterKeepClear(
            child: StudioSurface(
              face: StudioFace(
                fill: c.bar,
                fillLow: c.barLow,
                depth: StudioDepth.level,
                radius: 0,
                brushed: !sheet,
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  margin,
                  StudioSpacing.medium,
                  margin,
                  StudioSpacing.medium + media.padding.bottom,
                ),
                child: framed
                    // At the end of the page's column, under the body's end.
                    ? Center(
                        heightFactor: 1,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxWidth),
                          child: Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 360),
                              child: foot,
                            ),
                          ),
                        ),
                      )
                    : foot,
              ),
            ),
          ),
      ],
    );
    final Widget frame = Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: sheet
          ? LayoutBuilder(
              builder: (context, constraints) =>
                  stack(!constraints.hasTightHeight),
            )
          : stack(false),
    );
    if (sheet) return frame;
    return StudioSurface(
      face: StudioFace(
        fill: c.panel,
        fillLow: c.panelLow,
        depth: StudioDepth.level,
        radius: 0,
        brushed: true,
        foreground: c.legend,
      ),
      child: frame,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(FlagProperty('scroll', value: scroll, ifTrue: 'scroll'))
      ..add(FlagProperty('fullBleed', value: fullBleed, ifTrue: 'fullBleed'))
      ..add(DoubleProperty('maxWidth', maxWidth, defaultValue: 1200))
      ..add(
        DiagnosticsProperty<ScrollController>(
          'scrollController',
          scrollController,
          defaultValue: null,
        ),
      );
  }
}

/// The router's page for a route pushed over a root: its screen slid in on
/// its rails in Studio's way ([StudioPageTransitionsBuilder]), the page it
/// covers dimming; going back is the reverse. On iOS it pops with iOS's
/// swipe back from the leading edge too. A go_router route's `pageBuilder`
/// returns it with the route's `state.pageKey`.
///
/// ```dart
/// StudioPage<void>(key: state.pageKey, child: const EpisodePage())
/// ```
class StudioPage<T> extends Page<T> {
  /// A page of [child].
  const StudioPage({
    required this.child,
    this.fullscreenDialog = false,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  /// The page's screen, usually a [StudioScreen].
  final Widget child;

  /// Whether it is raised as a whole-screen dialog (rising from below),
  /// closed rather than gone back from.
  final bool fullscreenDialog;

  @override
  Route<T> createRoute(BuildContext context) {
    Widget current(BuildContext context) {
      // The page as it stands now: a router that updates it in place hands
      // the route the new one.
      final page = ModalRoute.of(context)?.settings;
      return ColoredBox(
        color: StudioTheme.of(context).colors.panel,
        child: page is StudioPage ? page.child : child,
      );
    }

    return _StudioPageRoute<T>(
      settings: this,
      fullscreenDialog: fullscreenDialog,
      builder: current,
    );
  }
}

/// A [StudioPage]'s route: an opaque page, changed by
/// [StudioPageTransitionsBuilder] whatever the app's Material theme says.
class _StudioPageRoute<T> extends PageRoute<T> {
  _StudioPageRoute({
    required this.builder,
    super.settings,
    super.fullscreenDialog,
  });

  final WidgetBuilder builder;

  static const _change = StudioPageTransitionsBuilder();

  // On iOS, the swipe back from the leading edge round it.
  static const _swipe = SwipeBackPageTransitionsBuilder(_change);

  @override
  Duration get transitionDuration => _change.transitionDuration;

  @override
  Duration get reverseTransitionDuration => _change.reverseTransitionDuration;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) =>
      nextRoute is PageRoute && !nextRoute.fullscreenDialog;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => Semantics(
    scopesRoute: true,
    explicitChildNodes: true,
    child: builder(context),
  );

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => (defaultTargetPlatform == TargetPlatform.iOS ? _swipe : _change)
      .buildTransitions<T>(this, context, animation, secondaryAnimation, child);
}

/// How a page stands in a [StudioPreview].
enum StudioPresentation {
  /// A root, over the app's places.
  root,

  /// Pushed over a root.
  pushed,

  /// Raised as a sheet.
  sheet,
}

/// One page alone, as the app stands it: the same host, the same places
/// and act on a root, the same route on a pushed page or a sheet, with no
/// router.
///
/// ```dart
/// StudioPreview(presentation: StudioPresentation.pushed, child: StudioScreen(body: const Text('Recorded in one take.')))
/// ```
class StudioPreview extends StatelessWidget {
  /// A preview of [child].
  const StudioPreview({
    super.key,
    required this.child,
    this.theme,
    this.darkTheme,
    this.brightness = Brightness.light,
    this.presentation = StudioPresentation.root,
    this.tabs = const [],
    this.selectedIndex = 0,
    this.action,
    this.brand,
    this.drawer = false,
    this.platform = PreviewPlatform.android,
  });

  /// The page.
  final Widget child;

  /// The theme by day.
  final StudioThemeData? theme;

  /// The theme by night.
  final StudioThemeData? darkTheme;

  /// The brightness to draw in.
  final Brightness brightness;

  /// How the page stands.
  final StudioPresentation presentation;

  /// The app's places, on a root.
  final List<StudioTab> tabs;

  /// The place the page is.
  final int selectedIndex;

  /// The app's one act, on a root.
  final StudioShellAction? action;

  /// The app's name, at the head of its places on a tablet or a desk.
  final String? brand;

  /// Whether a sheet stands as tall as its content.
  final bool drawer;

  /// The platform previewed.
  final PreviewPlatform platform;

  @override
  Widget build(BuildContext context) {
    Widget rooted(Widget page) => tabs.isEmpty && action == null
        ? page
        : StudioAppShell(
            tabs: tabs,
            selectedIndex: selectedIndex,
            onSelected: (_) {},
            action: action,
            brand: brand,
            child: page,
          );
    return PreviewFrame(
      platform: platform,
      brightness: brightness,
      // An app of its own: its own semantics container, so its routes'
      // barriers hide nothing painted before the preview in the page
      // that holds it.
      child: Semantics(
        container: true,
        child: MaterialApp(
          key: ValueKey<Object>((presentation, drawer)),
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const [
            RawWidgetsLocalizations.delegate,
            DefaultMaterialLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
          ],
          builder: (context, app) => StudioHost(
            theme: theme,
            darkTheme: darkTheme,
            brightness: brightness,
            child: app ?? const SizedBox.shrink(),
          ),
          home: switch (presentation) {
            StudioPresentation.root => rooted(child),
            StudioPresentation.pushed => PreviewStage(
              route: (context, page) => StudioPage<void>(
                key: const ValueKey<String>('studio-preview'),
                child: page,
              ).createRoute(context),
              child: child,
            ),
            StudioPresentation.sheet => PreviewStage(
              route: (context, page) => StudioSheetPage<void>(
                key: const ValueKey<String>('studio-preview'),
                drawer: drawer,
                child: page,
              ).createRoute(context),
              child: child,
            ),
          },
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<StudioThemeData>(
          'light',
          theme,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<StudioThemeData>(
          'dark',
          darkTheme,
          defaultValue: null,
        ),
      )
      ..add(DiagnosticsProperty<Brightness>('brightness', brightness))
      ..add(
        DiagnosticsProperty<StudioPresentation>('presentation', presentation),
      )
      ..add(IterableProperty<StudioTab>('tabs', tabs))
      ..add(IntProperty('activeIndex', selectedIndex))
      ..add(
        DiagnosticsProperty<StudioShellAction>(
          'action',
          action,
          defaultValue: null,
        ),
      )
      ..add(StringProperty('brand', brand, defaultValue: null))
      ..add(FlagProperty('drawer', value: drawer, ifTrue: 'drawer'))
      ..add(DiagnosticsProperty<PreviewPlatform>('platform', platform));
  }
}

/// The app's places and its one act round its pages: [StudioScaffold]'s
/// key bank on a phone, its rail on a tablet, its side panel on a desk, and
/// the act a [StudioFloatingKey] over a root page's bottom end, which the
/// page's [StudioScreen] keeps clear.
///
/// [StudioAppShell.branches] gives each place a navigator of its own: a page
/// pushed on one keeps the rail or the side panel while the phone's key bank
/// steps away for it, and back pops it before it leaves the place. The plain
/// constructor stands [child], the app's own page or navigator, beside the
/// places.
///
/// ```dart
/// StudioAppShell(tabs: const [StudioTab(LucideIcons.house, 'Home'), StudioTab(LucideIcons.mic, 'Record')], selectedIndex: 0, onSelected: (i) {}, child: const HomePage())
/// ```
class StudioAppShell extends StatelessWidget {
  /// [child] with the app's [tabs].
  const StudioAppShell({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onSelected,
    required Widget this.child,
    this.action,
    this.brand,
    this.showPlaces = true,
  }) : branches = null,
       navigatorKeys = null,
       backBehavior = RawBranchBackBehavior.firstDestination;

  /// A shell whose places each keep a navigator of their own, starting on
  /// its [branches] page; the act stands over each place's first page.
  ///
  /// ```dart
  /// StudioAppShell.branches(tabs: const [StudioTab(LucideIcons.house, 'Home'), StudioTab(LucideIcons.mic, 'Record')], selectedIndex: 0, onSelected: (i) {}, branches: [(context) => const HomePage(), (context) => const RecordPage()])
  /// ```
  const StudioAppShell.branches({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onSelected,
    required List<WidgetBuilder> this.branches,
    this.navigatorKeys,
    this.backBehavior = RawBranchBackBehavior.firstDestination,
    this.action,
    this.brand,
  }) : child = null,
       showPlaces = true;

  /// The app's places.
  final List<StudioTab> tabs;

  /// The place shown.
  final int selectedIndex;

  /// Called with the place chosen.
  final ValueChanged<int> onSelected;

  /// The page, or the app's own navigator; null with [branches].
  final Widget? child;

  /// Each place's first page; null with [child].
  final List<WidgetBuilder>? branches;

  /// The places' navigators' keys, to push onto a place from outside it;
  /// null keeps the shell's own.
  final List<GlobalKey<NavigatorState>>? navigatorKeys;

  /// Where back goes from a place's first page.
  final RawBranchBackBehavior backBehavior;

  /// The app's one act.
  final StudioShellAction? action;

  /// The app's name, at the head of the rail or the side panel.
  final String? brand;

  /// Whether a phone's key bank stands: false while a page pushed over the
  /// root covers it (a rail or a side panel stays). The branches form steps
  /// it away itself.
  final bool showPlaces;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final phone = width < StudioMetrics.tablet;
    final places = showPlaces || !phone;
    final name = brand;
    final head = name == null || name.isEmpty ? null : _Brand(name);
    final destinations = [
      for (final tab in tabs)
        StudioDestination(icon: Icon(tab.icon), label: tab.label, key: tab.key),
    ];
    final branches = this.branches;
    if (branches != null) {
      return StudioScaffold.branches(
        destinations: destinations,
        selectedIndex: selectedIndex,
        onDestinationSelected: onSelected,
        header: head,
        navigatorKeys: navigatorKeys,
        backBehavior: backBehavior,
        branches: [
          for (final first in branches)
            (context) => _ActOverRoot(action: action, child: first(context)),
        ],
      );
    }
    return StudioScaffold(
      destinations: places ? destinations : const [],
      selectedIndex: selectedIndex,
      onDestinationSelected: places ? onSelected : null,
      header: head,
      body: _ActOverRoot(action: places ? action : null, child: child!),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<StudioTab>('tabs', tabs))
      ..add(IntProperty('selectedIndex', selectedIndex))
      ..add(ObjectFlagProperty<ValueChanged<int>>.has('onSelected', onSelected))
      ..add(
        DiagnosticsProperty<StudioShellAction>(
          'action',
          action,
          defaultValue: null,
        ),
      )
      ..add(StringProperty('brand', brand, defaultValue: null))
      ..add(FlagProperty('showPlaces', value: showPlaces, ifTrue: 'showPlaces'))
      ..add(
        FlagProperty('branches', value: branches != null, ifTrue: 'branches'),
      );
  }
}

/// The app's name at the head of its places: engraved in the title type on
/// a side panel, its first letter where a rail is too narrow for it.
class _Brand extends StatelessWidget {
  const _Brand(this.name);

  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = StudioTheme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 120;
        return Semantics(
          header: true,
          label: name,
          child: ExcludeSemantics(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: StudioSpacing.small,
              ),
              // At a rail's width the whole name, set as a legend and made
              // smaller still if it must, to fit the rail's head.
              child: narrow
                  ? FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        name,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.label.copyWith(
                          color: theme.colors.legend,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.title.copyWith(
                        color: theme.colors.legend,
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }
}

/// A root page with the shell's act over its bottom end, the page keeping
/// clear of it.
class _ActOverRoot extends StatelessWidget {
  const _ActOverRoot({required this.action, required this.child});

  final StudioShellAction? action;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final act = action;
    final margin = StudioSpacing.pageMargin(MediaQuery.sizeOf(context).width);
    return Stack(
      children: [
        Positioned.fill(
          child: ShellInsets(
            bottomInset: act == null ? 0 : _ActKey.side + StudioSpacing.regular,
            child: child,
          ),
        ),
        if (act != null)
          PositionedDirectional(
            end: margin,
            bottom: StudioSpacing.regular,
            child: _ActKey(act),
          ),
      ],
    );
  }
}

/// The shell's act: the graphite floating key, its glyph and lamp lit, when
/// it is the app's standing invitation ([StudioShellAction.accent]); an
/// aluminium one, unlit, when not.
class _ActKey extends StatelessWidget {
  const _ActKey(this.action);

  final StudioShellAction action;

  /// The key's side.
  static const double side = 56;

  @override
  Widget build(BuildContext context) {
    final c = StudioTheme.of(context).colors;
    return KeyedSubtree(
      key: action.key,
      child: StudioFloatingKey(
        icon: Icon(action.icon),
        tooltip: action.label ?? 'New',
        onPressed: () => action.onPressed(context),
        style: action.accent
            ? null
            : StudioStyle(
                fill: WidgetStatePropertyAll(c.key),
                foreground: WidgetStatePropertyAll(c.onKey),
              ),
      ),
    );
  }
}

/// One of an app shell's places as an app declares it: its glyph, its name
/// and the key on its bank key.
///
/// ```dart
/// StudioTab(LucideIcons.house, 'Home', ValueKey('open-home'))
/// ```
@immutable
class StudioTab {
  /// A place called [label], shown by [icon].
  const StudioTab(this.icon, this.label, [this.key]);

  /// Its glyph.
  final IconData icon;

  /// Its name.
  final String label;

  /// The key on its bank key, rail key or side row.
  final Key? key;
}

/// The app's one act beside its places (record, write, add): the graphite
/// floating key over a root page's bottom end, lit when [accent], an
/// aluminium one when not.
///
/// ```dart
/// StudioShellAction(icon: LucideIcons.mic, accent: true, onPressed: (context) => startRecording(context))
/// ```
@immutable
class StudioShellAction with Diagnosticable {
  /// An act wearing [icon].
  const StudioShellAction({
    required this.icon,
    required this.onPressed,
    this.label,
    this.accent = true,
    this.key,
  });

  /// The glyph it wears.
  final IconData icon;

  /// What it does, run with a context under the app's navigator.
  final void Function(BuildContext context) onPressed;

  /// Its words, its tooltip and its spoken name; null says "New".
  final String? label;

  /// Whether it is the app's standing invitation: the graphite key, lit.
  final bool accent;

  /// The key on its floating key.
  final Key? key;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<IconData>('icon', icon))
      ..add(StringProperty('label', label, defaultValue: null))
      ..add(FlagProperty('accent', value: accent, ifFalse: 'not accent'));
  }
}

/// While a page's data is on its way: the chasing lamps over their word,
/// centred.
///
/// ```dart
/// const StudioLoadingState()
/// ```
class StudioLoadingState extends StatelessWidget {
  /// The page waiting.
  const StudioLoadingState({super.key, this.label});

  /// The word under the lamps, which a screen reader says too; null takes the
  /// design kit's ("Loading").
  final String? label;

  @override
  Widget build(BuildContext context) {
    final theme = StudioTheme.of(context);
    final words = label ?? RawWidgetsLocalizations.of(context).loadingLabel;
    return Center(
      child: Semantics(
        liveRegion: true,
        label: words,
        child: ExcludeSemantics(
          child: Padding(
            padding: const EdgeInsets.all(StudioSpacing.huge),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const StudioSpinner(size: 32),
                const SizedBox(height: StudioSpacing.regular),
                Text(
                  words,
                  style: theme.textTheme.caption.copyWith(
                    color: theme.colors.legendMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('label', label, defaultValue: null));
  }
}

/// When a page's data could not load: what happened, and one way forward
/// ([onRetry]'s key, or an [action] of the app's), in a [StudioStatusView]'s
/// dish with its red lamp.
///
/// ```dart
/// StudioErrorState(title: 'Could not load', message: 'Check your connection.', onRetry: reload)
/// ```
class StudioErrorState extends StatelessWidget {
  /// The page that failed.
  const StudioErrorState({
    super.key,
    required this.title,
    this.message,
    this.onRetry,
    this.retryLabel,
    this.action,
  });

  /// What happened, in a few words.
  final String title;

  /// What to do about it.
  final String? message;

  /// Tries again; null draws no retry.
  final VoidCallback? onRetry;

  /// The retry's words; null takes the design kit's ("Try again").
  final String? retryLabel;

  /// An action of the app's in place of the retry.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final retry = onRetry;
    final own = action;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: StudioMetrics.readingWidth),
        child: Padding(
          padding: const EdgeInsets.all(StudioSpacing.large),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StudioStatusView.error(
                title: title,
                message: message,
                actionLabel: own == null && retry != null
                    ? retryLabel ??
                          RawWidgetsLocalizations.of(context).retryButtonLabel
                    : null,
                onAction: own == null ? retry : null,
              ),
              if (own != null) ...[
                const SizedBox(height: StudioSpacing.regular),
                Center(child: own),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title))
      ..add(StringProperty('message', message, defaultValue: null))
      ..add(ObjectFlagProperty<VoidCallback>.has('onRetry', onRetry))
      ..add(StringProperty('retryLabel', retryLabel, defaultValue: null));
  }
}

/// The plain one-line field: a [StudioTextField] with a hint, or a label,
/// its error and its text hidden for a password. On a page you write, use
/// [StudioTextField], which takes the rest.
///
/// ```dart
/// StudioInput(hintText: 'Search episodes', onSubmitted: search)
/// ```
class StudioInput extends StatelessWidget {
  /// A field hinting [hintText].
  const StudioInput({
    super.key,
    this.hintText,
    this.labelText,
    this.errorText,
    this.obscureText = false,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
  });

  /// What it is for, until something is typed.
  final String? hintText;

  /// Its name, over the well.
  final String? labelText;

  /// What is wrong with what was typed; null when nothing is.
  final String? errorText;

  /// Whether what is typed is hidden (a password).
  final bool obscureText;

  /// Its text's controller.
  final TextEditingController? controller;

  /// Called with its text as it changes.
  final ValueChanged<String>? onChanged;

  /// Called with its text when it is submitted.
  final ValueChanged<String>? onSubmitted;

  /// Whether it takes typing.
  final bool enabled;

  @override
  Widget build(BuildContext context) => StudioTextField(
    controller: controller,
    labelText: labelText,
    hintText: hintText,
    errorText: errorText,
    obscureText: obscureText,
    semanticLabel: labelText == null ? hintText : null,
    onChanged: onChanged,
    onSubmitted: onSubmitted,
    enabled: enabled,
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('hint', hintText, defaultValue: null))
      ..add(StringProperty('label', labelText, defaultValue: null))
      ..add(StringProperty('error', errorText, defaultValue: null))
      ..add(FlagProperty('obscure', value: obscureText, ifTrue: 'obscure'))
      ..add(
        DiagnosticsProperty<TextEditingController>(
          'controller',
          controller,
          defaultValue: null,
        ),
      )
      ..add(
        ObjectFlagProperty<ValueChanged<String>>.has('onChanged', onChanged),
      )
      ..add(
        ObjectFlagProperty<ValueChanged<String>>.has(
          'onSubmitted',
          onSubmitted,
        ),
      )
      ..add(FlagProperty('enabled', value: enabled, ifTrue: 'enabled'));
  }
}

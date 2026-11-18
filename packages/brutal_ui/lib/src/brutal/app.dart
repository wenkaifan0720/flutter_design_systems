/// Brutal's app frame: what an app's pages stand in. [BrutalHost] once over
/// the navigator; [BrutalScreen] round each page; [BrutalPage] the route a
/// push raises one in (a sheet's is `BrutalSheetPage`); [BrutalPreview] one
/// page alone, as the app stands it; [BrutalLoadingState] and
/// [BrutalErrorState] a page whose data is on its way or lost; [BrutalInput]
/// the plain one-line field; [BrutalTab] and [BrutalShellAction] an app
/// shell's places and its one act.
library;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ui_core/host.dart';
import 'package:ui_core/ui_core.dart';

import 'button.dart';
import 'feedback.dart';
import 'lists.dart';
import 'navigation.dart';
import 'overlays.dart';
import 'text_field.dart';
import 'theme.dart';

/// The widest a page's content stands, inside its margins.
const double _pageWidth = 1200;

/// The app's host, mounted once over its navigator (`WidgetsApp.builder`):
/// Brutal's theme for the brightness asked for, its toasts and its white
/// page.
///
/// ```dart
/// MaterialApp(builder: (context, child) => BrutalHost(child: child!))
/// ```
class BrutalHost extends StatelessWidget {
  /// Hosts [child] in [light] or [dark], as [brightness] (or the platform)
  /// asks; either left out is the default preset in that brightness.
  const BrutalHost({
    super.key,
    this.light,
    this.dark,
    this.brightness,
    required this.child,
  });

  /// The theme by day.
  final BrutalThemeData? light;

  /// The theme by night.
  final BrutalThemeData? dark;

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
        (wanted == Brightness.dark ? dark : light) ??
        BrutalThemeData.preset(BrutalThemeData.presets.first, wanted);
    return BrutalTheme(
      data: data,
      child: BrutalToaster(
        child: ColoredBox(color: data.colors.paper, child: child),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<BrutalThemeData>(
          'light',
          light,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<BrutalThemeData>('dark', dark, defaultValue: null),
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

/// A page: its [topBar] (a pushed page's way back stands in it), its [body]
/// in the page's margins on the 4 px grid, no wider than 1200 px, and its
/// [footer] fixed at its foot on a rule. In a sheet it is as tall as its
/// content allows and stands on the sheet's face.
///
/// ```dart
/// BrutalScreen(topBar: BrutalAppBar(title: 'Event', leading: BrutalAppBar.autoLeading(context)), body: const Text('Doors at eight.'))
/// ```
class BrutalScreen extends StatelessWidget {
  /// A page of [body].
  const BrutalScreen({
    super.key,
    required this.body,
    this.topBar,
    this.footer,
    this.scroll = true,
    this.fullBleed = false,
    this.scrollController,
  });

  /// The page's content.
  final Widget body;

  /// The bar over it, usually a [BrutalAppBar]; null on a root that opens
  /// on its own head.
  final Widget? topBar;

  /// What stands fixed at the foot, on a rule: the page's one action.
  final Widget? footer;

  /// Whether the page scrolls; false gives [body] the height left, to
  /// scroll itself.
  final bool scroll;

  /// Whether [body] takes the whole width with no margins of the page's.
  final bool fullBleed;

  /// The page's scroll controller.
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    final c = theme.colors;
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final margin = BrutalSpacing.pageMargin(width);
    final sheet = RoutePresentation.of(context) == RoutePresentation.sheet;
    final bar = topBar;
    final foot = footer;
    // What the page keeps clear: the status bar with no bar over it, the
    // shell's act over a root, the home indicator with no footer under it.
    final top = bar == null ? media.padding.top : 0.0;
    final bottom = foot == null ? media.padding.bottom : 0.0;
    final Widget page = fullBleed
        ? body
        : Padding(
            padding: EdgeInsets.fromLTRB(
              margin,
              BrutalSpacing.large + top,
              margin,
              BrutalSpacing.huge + ShellInsets.of(context) + bottom,
            ),
            child: body,
          );
    final Widget column = fullBleed
        ? page
        : Align(
            alignment: Alignment.topCenter,
            heightFactor: scroll ? 1 : null,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: _pageWidth + 2 * margin),
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
    final framed = width >= 600 && !sheet;
    return ColoredBox(
      color: sheet ? c.surface : c.paper,
      child: Padding(
        padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
        child: Column(
          mainAxisSize: sheet ? MainAxisSize.min : MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ?bar,
            if (sheet) Flexible(child: content) else Expanded(child: content),
            if (foot != null) ...[
              const BrutalRule(),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  margin,
                  BrutalSpacing.regular,
                  margin,
                  BrutalSpacing.regular + media.padding.bottom,
                ),
                child: framed
                    ? Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 360),
                          child: foot,
                        ),
                      )
                    : foot,
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(FlagProperty('scroll', value: scroll, ifTrue: 'scroll'))
      ..add(FlagProperty('fullBleed', value: fullBleed, ifTrue: 'fullBleed'))
      ..add(
        DiagnosticsProperty<ScrollController>(
          'scrollController',
          scrollController,
          defaultValue: null,
        ),
      );
  }
}

/// The router's page for a route pushed over a root: its screen on the
/// white page, changed in Brutal's way ([BrutalPageTransitionsBuilder]): it
/// slides a short way in from the end side over the page it covers, which
/// stays where it is; going back is the reverse. On iOS it pops with iOS's
/// swipe back from the leading edge too. A go_router route's
/// `pageBuilder` returns it with the route's `state.pageKey`.
///
/// ```dart
/// BrutalPage<void>(key: state.pageKey, child: const EventPage())
/// ```
class BrutalPage<T> extends Page<T> {
  /// A page of [child].
  const BrutalPage({
    required this.child,
    this.fullscreenDialog = false,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  /// The page's screen, usually a [BrutalScreen].
  final Widget child;

  /// Whether it is raised as a whole-screen dialog, closed rather than
  /// gone back from.
  final bool fullscreenDialog;

  @override
  Route<T> createRoute(BuildContext context) {
    Widget current(BuildContext context) {
      // The page as it stands now: a router that updates it in place hands
      // the route the new one.
      final page = ModalRoute.of(context)?.settings;
      return ColoredBox(
        color: BrutalTheme.of(context).colors.paper,
        child: page is BrutalPage ? page.child : child,
      );
    }

    return _BrutalPageRoute<T>(
      settings: this,
      fullscreenDialog: fullscreenDialog,
      builder: current,
    );
  }
}

/// Brutal's page change, for a page pushed over another and its way back.
/// The new page slides [travel] in from the end side (a whole-screen dialog
/// rises it from below) over the page it covers, which stays where it is;
/// it is solid within the first part of its move, so the page beneath never
/// shows through it for long, and it stops dead. Going back is the reverse.
/// With Reduce Motion it cuts. A switch between an app's places (its tabs,
/// its side bar) is no page change: the shell swaps them in place.
///
/// [BrutalPage] changes this way on every platform, on iOS with iOS's swipe
/// back from the leading edge round it, and so does a `MaterialPageRoute`
/// under a [BrutalTheme] in the app's `builder:`, from the material library
/// Brutal is built on. An app's own theme gives it [brutalPageTransitions].
///
/// ```dart
/// ThemeData(pageTransitionsTheme: const PageTransitionsTheme(builders: brutalPageTransitions))
/// ```
class BrutalPageTransitionsBuilder extends PageTransitionsBuilder {
  /// Brutal's page change.
  const BrutalPageTransitionsBuilder();

  /// How far a page moves: a short way, never across the screen.
  static const double travel = 24;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 240);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 200);

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => _PageArrive(
    animation: animation,
    rises: route.fullscreenDialog,
    child: child,
  );
}

/// Brutal's page change on every platform, with iOS's swipe back from the
/// screen's leading edge round it there (ui_core's
/// [DesignSwipeBackPageTransitionsBuilder]): the builders for a `PageTransitionsTheme`, Flutter's material library's or
/// the one Brutal is built on (they are widgets-level builders, so one map
/// fits both). [BrutalTheme] puts them in the Material theme it lays; an app
/// on Flutter's own `MaterialApp`, whose `MaterialPageRoute` reads only the
/// app's own theme, gives them to its `ThemeData`.
///
/// ```dart
/// MaterialApp(theme: ThemeData(pageTransitionsTheme: const PageTransitionsTheme(builders: brutalPageTransitions)), home: const Home())
/// ```
const Map<TargetPlatform, PageTransitionsBuilder> brutalPageTransitions = {
  TargetPlatform.android: BrutalPageTransitionsBuilder(),
  TargetPlatform.fuchsia: BrutalPageTransitionsBuilder(),
  // iOS's swipe back from the screen's edge, round Brutal's push.
  TargetPlatform.iOS: DesignSwipeBackPageTransitionsBuilder(
    BrutalPageTransitionsBuilder(),
  ),
  TargetPlatform.linux: BrutalPageTransitionsBuilder(),
  TargetPlatform.macOS: BrutalPageTransitionsBuilder(),
  TargetPlatform.windows: BrutalPageTransitionsBuilder(),
};

/// A [BrutalPage]'s route: an opaque page, changed by
/// [BrutalPageTransitionsBuilder] whatever the app's Material theme says.
class _BrutalPageRoute<T> extends PageRoute<T> {
  _BrutalPageRoute({
    required this.builder,
    super.settings,
    super.fullscreenDialog,
  });

  final WidgetBuilder builder;

  static const _change = BrutalPageTransitionsBuilder();

  // On iOS, the swipe back from the leading edge round it.
  static const _swipe = DesignSwipeBackPageTransitionsBuilder(_change);

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

/// A page arriving (and, reversed, leaving): [BrutalPageTransitionsBuilder.travel]
/// from the end side, or from below when it [rises], solid within the first
/// part of its move.
class _PageArrive extends StatefulWidget {
  const _PageArrive({
    required this.animation,
    required this.rises,
    required this.child,
  });

  final Animation<double> animation;
  final bool rises;
  final Widget child;

  @override
  State<_PageArrive> createState() => _PageArriveState();
}

class _PageArriveState extends State<_PageArrive> {
  late CurvedAnimation _move = _curve();
  late CurvedAnimation _solid = _solidCurve();

  CurvedAnimation _curve() => CurvedAnimation(
    parent: widget.animation,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );

  CurvedAnimation _solidCurve() =>
      CurvedAnimation(parent: widget.animation, curve: const Interval(0, 0.3));

  @override
  void didUpdateWidget(_PageArrive old) {
    super.didUpdateWidget(old);
    if (old.animation != widget.animation) {
      _move.dispose();
      _solid.dispose();
      _move = _curve();
      _solid = _solidCurve();
    }
  }

  @override
  void dispose() {
    _move.dispose();
    _solid.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (designReduceMotionOf(context)) {
      return widget.child;
    }
    final end = Directionality.of(context) == TextDirection.rtl ? -1.0 : 1.0;
    const travel = BrutalPageTransitionsBuilder.travel;
    return FadeTransition(
      opacity: _solid,
      child: AnimatedBuilder(
        animation: _move,
        builder: (context, child) {
          final left = travel * (1 - _move.value);
          return Transform.translate(
            offset: widget.rises ? Offset(0, left) : Offset(end * left, 0),
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

/// How a page stands in a [BrutalPreview].
enum BrutalPresentation {
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
/// BrutalPreview(presentation: BrutalPresentation.pushed, child: BrutalScreen(body: const Text('Doors at eight.')))
/// ```
class BrutalPreview extends StatelessWidget {
  /// A preview of [child].
  const BrutalPreview({
    super.key,
    required this.child,
    this.light,
    this.dark,
    this.brightness = Brightness.light,
    this.presentation = BrutalPresentation.root,
    this.tabs = const [],
    this.activeIndex = 0,
    this.action,
    this.brand,
    this.drawer = false,
    this.platform = PreviewPlatform.android,
  });

  /// The page.
  final Widget child;

  /// The theme by day.
  final BrutalThemeData? light;

  /// The theme by night.
  final BrutalThemeData? dark;

  /// The brightness to draw in.
  final Brightness brightness;

  /// How the page stands.
  final BrutalPresentation presentation;

  /// The app's places, on a root.
  final List<BrutalTab> tabs;

  /// The place the page is.
  final int activeIndex;

  /// The app's one act, on a root.
  final ShellAction? action;

  /// The app's name, at the head of its places on a tablet or a desktop.
  final String? brand;

  /// Whether a sheet stands as tall as its content.
  final bool drawer;

  /// The platform previewed.
  final PreviewPlatform platform;

  @override
  Widget build(BuildContext context) {
    Widget rooted(Widget page) => tabs.isEmpty && action == null
        ? page
        : BrutalAppShell(
            tabs: tabs,
            selectedIndex: activeIndex,
            onSelected: (_) {},
            action: action,
            brand: brand,
            child: page,
          );
    return PreviewFrame(
      platform: platform,
      brightness: brightness,
      // The app inside, a semantics container of its own: its routes'
      // barriers would hide from a screen reader what the page around it
      // paints before it.
      child: Semantics(
        container: true,
        child: MaterialApp(
          key: ValueKey<Object>((presentation, drawer)),
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const [
            DesignLocalizations.delegate,
            DefaultMaterialLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
          ],
          builder: (context, app) => BrutalHost(
            light: light,
            dark: dark,
            brightness: brightness,
            child: app ?? const SizedBox.shrink(),
          ),
          home: switch (presentation) {
            BrutalPresentation.root => rooted(child),
            BrutalPresentation.pushed => PreviewStage(
              route: (context, page) => BrutalPage<void>(
                key: const ValueKey<String>('brutal-preview'),
                child: page,
              ).createRoute(context),
              child: child,
            ),
            BrutalPresentation.sheet => PreviewStage(
              route: (context, page) => BrutalSheetPage<void>(
                key: const ValueKey<String>('brutal-preview'),
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
        DiagnosticsProperty<BrutalThemeData>(
          'light',
          light,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<BrutalThemeData>('dark', dark, defaultValue: null),
      )
      ..add(DiagnosticsProperty<Brightness>('brightness', brightness))
      ..add(
        DiagnosticsProperty<BrutalPresentation>('presentation', presentation),
      )
      ..add(IterableProperty<BrutalTab>('tabs', tabs))
      ..add(IntProperty('activeIndex', activeIndex))
      ..add(
        DiagnosticsProperty<ShellAction>('action', action, defaultValue: null),
      )
      ..add(StringProperty('brand', brand, defaultValue: null))
      ..add(FlagProperty('drawer', value: drawer, ifTrue: 'drawer'))
      ..add(DiagnosticsProperty<PreviewPlatform>('platform', platform));
  }
}

/// The app's places and its one act round a root page: [BrutalScaffold]'s
/// bar on a phone, its rail on a tablet, its side list on a desktop, and
/// the act a [BrutalFloatingButton] over the page's bottom end, which the
/// page's [BrutalScreen] keeps clear. An app on a router mounts it through
/// `BrutalShell`; a preview mounts it directly.
///
/// ```dart
/// BrutalAppShell(tabs: const [BrutalTab(LucideIcons.house, 'Home'), BrutalTab(LucideIcons.ticket, 'Tickets')], selectedIndex: 0, onSelected: (i) {}, child: const HomePage())
/// ```
class BrutalAppShell extends StatelessWidget {
  /// [child] with the app's [tabs].
  const BrutalAppShell({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onSelected,
    required this.child,
    this.action,
    this.brand,
    this.showPlaces = true,
  });

  /// The app's places.
  final List<BrutalTab> tabs;

  /// The place shown.
  final int selectedIndex;

  /// Called with the place chosen.
  final ValueChanged<int> onSelected;

  /// The page.
  final Widget child;

  /// The app's one act.
  final ShellAction? action;

  /// The app's name, at the head of the rail or the side list.
  final String? brand;

  /// Whether a phone's bar stands: false while a page pushed over the root
  /// covers it (a rail or a side list stays).
  final bool showPlaces;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final phone = width < 600;
    final places = showPlaces || !phone;
    final act = places ? action : null;
    final name = brand;
    return BrutalScaffold(
      destinations: [
        for (final tab in tabs)
          BrutalDestination(icon: tab.icon, label: tab.label, key: tab.key),
      ],
      // A phone's bar springs away under a page pushed over the root.
      showNavigation: showPlaces,
      selectedIndex: selectedIndex,
      onSelected: onSelected,
      brand: name == null || name.isEmpty ? null : _Brand(name),
      floatingButton: act == null ? null : _ActButton(act),
      body: ShellInsets(
        bottomInset: act == null
            ? 0
            : _ActButton.side + BrutalSpacing.pageMargin(width),
        child: child,
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<BrutalTab>('tabs', tabs))
      ..add(IntProperty('selectedIndex', selectedIndex))
      ..add(ObjectFlagProperty<ValueChanged<int>>.has('onSelected', onSelected))
      ..add(
        DiagnosticsProperty<ShellAction>('action', action, defaultValue: null),
      )
      ..add(StringProperty('brand', brand, defaultValue: null))
      ..add(
        FlagProperty('showPlaces', value: showPlaces, ifTrue: 'showPlaces'),
      );
  }
}

/// The app's name at the head of its places: in the title type where it
/// fits, its first letter in a square where it does not.
class _Brand extends StatelessWidget {
  const _Brand(this.name);

  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 120;
        return Semantics(
          header: true,
          label: name,
          child: ExcludeSemantics(
            child: Padding(
              padding: const EdgeInsets.all(BrutalSpacing.regular),
              child: Text(
                narrow ? name.characters.first.toUpperCase() : name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: narrow ? TextAlign.center : TextAlign.start,
                style: theme.textTheme.title.copyWith(color: theme.colors.ink),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The shell's act: the signal square when it is the app's standing
/// invitation ([ShellAction.accent]), else a white one.
class _ActButton extends StatelessWidget {
  const _ActButton(this.action);

  final ShellAction action;

  /// The square's side.
  static const double side = 64;

  @override
  Widget build(BuildContext context) {
    final c = BrutalTheme.of(context).colors;
    return KeyedSubtree(
      key: action.key,
      child: BrutalFloatingButton(
        icon: Icon(action.icon),
        tooltip: action.label ?? 'New',
        onPressed: () => action.onPressed(context),
        style: action.accent
            ? null
            : BrutalStyle(
                fill: WidgetStatePropertyAll(c.surface),
                foreground: WidgetStatePropertyAll(c.ink),
              ),
      ),
    );
  }
}

/// One of an app shell's places as an app declares it: its glyph, its
/// name and the key on its cell.
///
/// ```dart
/// BrutalTab(LucideIcons.house, 'Home', ValueKey('open-home'))
/// ```
@immutable
class BrutalTab {
  /// A place called [label], shown by [icon].
  const BrutalTab(this.icon, this.label, [this.key]);

  /// Its glyph.
  final IconData icon;

  /// Its name.
  final String label;

  /// The key on its cell.
  final Key? key;
}

/// The app's one act beside its places (add, write, capture): the signal
/// square over a root page's bottom end when [accent], a white one when
/// not.
///
/// ```dart
/// BrutalShellAction(icon: LucideIcons.plus, accent: true, onPressed: (context) => openNewEvent(context))
/// ```
class BrutalShellAction extends ShellAction {
  /// An act wearing [icon].
  const BrutalShellAction({
    required super.icon,
    required super.onPressed,
    super.label,
    super.accent = true,
    super.key,
  });
}

/// While a page's data is on its way: the spinner over its word, centred.
///
/// ```dart
/// const BrutalLoadingState()
/// ```
class BrutalLoadingState extends StatelessWidget {
  /// The page waiting.
  const BrutalLoadingState({super.key, this.label});

  /// What a screen reader says; null takes the design kit's ("Loading").
  final String? label;

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    final words = label ?? DesignLocalizations.of(context).loadingLabel;
    return Center(
      child: Semantics(
        liveRegion: true,
        label: words,
        child: ExcludeSemantics(
          child: Padding(
            padding: const EdgeInsets.all(BrutalSpacing.huge),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const BrutalSpinner(size: 32),
                const SizedBox(height: BrutalSpacing.regular),
                Text(
                  words.toUpperCase(),
                  style: theme.textTheme.caption.copyWith(
                    color: theme.colors.inkMuted,
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
/// ([onRetry]'s button, or an [action] of the app's).
///
/// ```dart
/// BrutalErrorState(title: 'Could not load', message: 'Check your connection.', onRetry: reload)
/// ```
class BrutalErrorState extends StatelessWidget {
  /// The page that failed.
  const BrutalErrorState({
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
    final act =
        action ??
        (retry == null
            ? null
            : BrutalButton(
                retryLabel ?? DesignLocalizations.of(context).retryButtonLabel,
                onPressed: retry,
              ));
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: BrutalMetrics.readingWidth),
        child: Padding(
          padding: const EdgeInsets.all(BrutalSpacing.large),
          child: BrutalStateView(
            state: BrutalState.error,
            title: title,
            message: message,
            actions: [?act],
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

/// The plain one-line field: a [BrutalTextField] with only a hint. On a
/// page you write, use [BrutalTextField], which names itself.
///
/// ```dart
/// BrutalInput(hint: 'Search events', onSubmitted: search)
/// ```
class BrutalInput extends StatelessWidget {
  /// A field hinting [hint].
  const BrutalInput({
    super.key,
    this.hint,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
  });

  /// What it is for, until something is typed.
  final String? hint;

  /// Its text's controller.
  final TextEditingController? controller;

  /// Called with its text as it changes.
  final ValueChanged<String>? onChanged;

  /// Called with its text when it is submitted.
  final ValueChanged<String>? onSubmitted;

  /// Whether it takes typing.
  final bool enabled;

  @override
  Widget build(BuildContext context) => BrutalTextField(
    controller: controller,
    hint: hint,
    semanticLabel: hint,
    onChanged: onChanged,
    onSubmitted: onSubmitted,
    enabled: enabled,
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('hint', hint, defaultValue: null))
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

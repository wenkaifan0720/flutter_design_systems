/// Brutal's app frame: what an app's pages stand in. [BrutalHost] once over
/// the navigator; [BrutalScreen] round each page; [BrutalPage] the route a
/// push raises one in (a sheet's is `BrutalSheetPage`); [BrutalLoadingState]
/// and [BrutalErrorState] a page whose data is on its way or lost;
/// [BrutalInput] the plain one-line field. The app's places are
/// [BrutalAppShell]'s.
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
/// Brutal's theme for the brightness asked for, its toasts and the page
/// colour of its palette. A new brightness or palette moves: every colour
/// of the page lerps to it (at once under Reduce Motion).
///
/// ```dart
/// MaterialApp(builder: (context, child) => BrutalHost(palette: BrutalThemeData.palettes[1], child: child!))
/// ```
class BrutalHost extends StatelessWidget {
  /// Hosts [child] in [theme] or [darkTheme], as [brightness] (or the platform)
  /// asks; either left out is [palette]'s preset in that brightness.
  const BrutalHost({
    super.key,
    this.palette,
    this.theme,
    this.darkTheme,
    this.brightness,
    required this.child,
  });

  /// The preset both brightnesses are built from, one of
  /// [BrutalThemeData.palettes]; null: the first, raw.
  final RawNamedPalette? palette;

  /// The theme by day.
  final BrutalThemeData? theme;

  /// The theme by night.
  final BrutalThemeData? darkTheme;

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
        BrutalThemeData.preset(
          palette?.id ?? BrutalThemeData.presets.first,
          wanted,
        );
    return AnimatedBrutalTheme(
      data: data,
      child: BrutalToaster(
        child: Builder(
          builder: (context) => ColoredBox(
            color: BrutalTheme.of(context).colors.paper,
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
        DiagnosticsProperty<BrutalThemeData>(
          'theme',
          theme,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<BrutalThemeData>(
          'darkTheme',
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
            // The foot, on its rule. A toast stands above it, as a Scaffold
            // keeps a snackbar above its persistent footer buttons.
            if (foot != null)
              RawToasterKeepClear(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const BrutalRule(),
                    // Its action ends on the page column's end edge: past
                    // the column's widest the page centres it.
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final side =
                            margin +
                            (constraints.maxWidth - (_pageWidth + 2 * margin))
                                    .clamp(0.0, double.infinity) /
                                2;
                        return Padding(
                          padding: EdgeInsets.fromLTRB(
                            side,
                            BrutalSpacing.regular,
                            side,
                            BrutalSpacing.regular + media.padding.bottom,
                          ),
                          child: framed
                              ? Align(
                                  alignment: AlignmentDirectional.centerEnd,
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 360,
                                    ),
                                    child: foot,
                                  ),
                                )
                              : foot,
                        );
                      },
                    ),
                  ],
                ),
              ),
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
/// [SwipeBackPageTransitionsBuilder]): the builders for a `PageTransitionsTheme`, Flutter's material library's or
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
  TargetPlatform.iOS: SwipeBackPageTransitionsBuilder(
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
    if (rawReduceMotionOf(context)) {
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

/// While a page's data is on its way: the spinner over its word, centred.
///
/// ```dart
/// const BrutalLoadingState()
/// ```
class BrutalLoadingState extends StatelessWidget {
  /// The page waiting.
  const BrutalLoadingState({super.key, this.label});

  /// Its word, drawn under the spinner and said by a screen reader; null
  /// takes the design kit's ("Loading").
  final String? label;

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    final words = label ?? RawWidgetsLocalizations.of(context).loadingLabel;
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
                retryLabel ??
                    RawWidgetsLocalizations.of(context).retryButtonLabel,
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
/// BrutalInput(hintText: 'Search events', onSubmitted: search)
/// ```
class BrutalInput extends StatelessWidget {
  /// A field hinting [hintText].
  const BrutalInput({
    super.key,
    this.hintText,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
  });

  /// What it is for, until something is typed.
  final String? hintText;

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
    hintText: hintText,
    semanticLabel: hintText,
    onChanged: onChanged,
    onSubmitted: onSubmitted,
    enabled: enabled,
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('hintText', hintText, defaultValue: null))
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

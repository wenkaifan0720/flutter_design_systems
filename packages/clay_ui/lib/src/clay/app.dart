/// Clay's app frame: what an app's pages stand in. [ClayHost] once over the
/// navigator; [ClayScreen] round each page; [ClayPage] the route a push
/// raises one in (a sheet's is `ClaySheetPage`); [ClayPreview] one page
/// alone, as the app stands it; [ClayLoadingState] and [ClayErrorState] a
/// page whose data is on its way or lost; [ClayInput] the plain one-line
/// field; [ClayTab] and [ClayShellAction] an app shell's places and its one
/// act.
library;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ui_core/host.dart';
import 'package:ui_core/ui_core.dart';

import 'button.dart';
import 'display.dart';
import 'navigation.dart';
import 'overlays.dart';
import 'page_transitions.dart';
import 'text_field.dart';
import 'theme.dart';

/// The widest a page's content stands, inside its margins: a calm desktop
/// reads in one column of this width, centred.
const double _pageWidth = 1080;

/// The app's host, mounted once over its navigator (`WidgetsApp.builder`):
/// Clay's theme for the brightness asked for, its toasts and its ground.
///
/// ```dart
/// MaterialApp(builder: (context, child) => ClayHost(child: child!))
/// ```
class ClayHost extends StatelessWidget {
  /// Hosts [child] in [theme] or [darkTheme], as [brightness] (or the platform)
  /// asks; either left out is the clay preset in that brightness.
  const ClayHost({
    super.key,
    this.theme,
    this.darkTheme,
    this.brightness,
    required this.child,
  });

  /// The theme by day.
  final ClayThemeData? theme;

  /// The theme by night.
  final ClayThemeData? darkTheme;

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
        ClayThemeData.preset(ClayThemeData.presets.first, wanted);
    return ClayTheme(
      data: data,
      child: ClayToaster(
        child: ColoredBox(color: data.colors.ground, child: child),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<ClayThemeData>('theme', theme, defaultValue: null),
      )
      ..add(
        DiagnosticsProperty<ClayThemeData>(
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
/// on the ground in the page's margins, no wider than 1080 px, and its
/// [footer] fixed at its foot, the page fading into the ground above it:
/// the page's one coral key in reach. A toast stands above the footer, as a
/// Scaffold keeps a snackbar above its persistent footer buttons. In a sheet
/// it is as tall as its content allows and stands on the sheet's clay.
///
/// ```dart
/// ClayScreen(topBar: ClayTopBar(title: 'Drink water', leading: ClayTopBar.autoLeading(context)), body: const Text('Eight glasses a day.'))
/// ```
class ClayScreen extends StatelessWidget {
  /// A page of [body].
  const ClayScreen({
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

  /// The bar over it, usually a [ClayTopBar]; null on a root that opens on
  /// its own head.
  final Widget? topBar;

  /// What stands fixed at the foot: the page's one action, a coral key.
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
    final theme = ClayTheme.of(context);
    final ground = theme.colors.ground;
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final margin = ClaySpacing.pageMargin(width);
    final sheet = RoutePresentation.of(context) == RoutePresentation.sheet;
    final bar = topBar;
    final foot = footer;
    // What the page keeps clear: the status bar with no bar over it, the
    // home indicator with no footer under it.
    final top = bar == null ? media.padding.top : 0.0;
    final bottom = foot == null ? media.padding.bottom : 0.0;
    final Widget page = fullBleed
        ? body
        : Padding(
            padding: EdgeInsets.fromLTRB(
              margin,
              ClaySpacing.large + top,
              margin,
              ClaySpacing.extraLarge + ShellInsets.of(context) + bottom,
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
    final framed = width >= ClayMetrics.railBreakpoint && !sheet;
    // Over a footer the page fades into the ground rather than stopping at
    // a line, as it does above the dock.
    final Widget above = foot == null || sheet
        ? content
        : Stack(
            children: [
              Positioned.fill(child: content),
              PositionedDirectional(
                start: 0,
                end: 0,
                bottom: 0,
                height: ClaySpacing.large,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [ground.withValues(alpha: 0), ground],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
    final Widget laid = Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: Column(
        mainAxisSize: sheet ? MainAxisSize.min : MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ?bar,
          if (sheet) Flexible(child: above) else Expanded(child: above),
          if (foot != null)
            // Toasts stand above the foot, as above the dock.
            RawToasterKeepClear(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  margin,
                  ClaySpacing.medium,
                  margin,
                  ClaySpacing.medium + media.padding.bottom,
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
            ),
        ],
      ),
    );
    // A sheet's clay is its route's; a page stands on the ground.
    return sheet ? laid : ColoredBox(color: ground, child: laid);
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
/// ground, changed in Clay's way ([ClayPageTransitionsBuilder]). On iOS it
/// pops with iOS's swipe back from the leading edge too. A go_router
/// route's `pageBuilder` returns it with the route's `state.pageKey`.
///
/// ```dart
/// ClayPage<void>(key: state.pageKey, child: const HabitPage())
/// ```
class ClayPage<T> extends Page<T> {
  /// A page of [child].
  const ClayPage({
    required this.child,
    this.fullscreenDialog = false,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  /// The page's screen, usually a [ClayScreen].
  final Widget child;

  /// Whether it is raised as a whole-screen dialog, closed rather than gone
  /// back from.
  final bool fullscreenDialog;

  @override
  Route<T> createRoute(BuildContext context) {
    Widget current(BuildContext context) {
      // The page as it stands now: a router that updates it in place hands
      // the route the new one.
      final page = ModalRoute.of(context)?.settings;
      return ColoredBox(
        color: ClayTheme.of(context).colors.ground,
        child: page is ClayPage ? page.child : child,
      );
    }

    return _ClayPageRoute<T>(
      settings: this,
      fullscreenDialog: fullscreenDialog,
      builder: current,
    );
  }
}

/// A [ClayPage]'s route: an opaque page, changed by
/// [ClayPageTransitionsBuilder] whatever the app's Material theme says.
class _ClayPageRoute<T> extends PageRoute<T> {
  _ClayPageRoute({
    required this.builder,
    super.settings,
    super.fullscreenDialog,
  });

  final WidgetBuilder builder;

  static const _change = ClayPageTransitionsBuilder();

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

/// How a page stands in a [ClayPreview].
enum ClayPresentation {
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
/// ClayPreview(presentation: ClayPresentation.pushed, child: ClayScreen(body: const Text('Eight glasses a day.')))
/// ```
class ClayPreview extends StatelessWidget {
  /// A preview of [child].
  const ClayPreview({
    super.key,
    required this.child,
    this.theme,
    this.darkTheme,
    this.brightness = Brightness.light,
    this.presentation = ClayPresentation.root,
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
  final ClayThemeData? theme;

  /// The theme by night.
  final ClayThemeData? darkTheme;

  /// The brightness to draw in.
  final Brightness brightness;

  /// How the page stands.
  final ClayPresentation presentation;

  /// The app's places, on a root.
  final List<ClayTab> tabs;

  /// The place the page is.
  final int selectedIndex;

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
        : ClayAppShell(
            tabs: tabs,
            selectedIndex: selectedIndex,
            onDestinationSelected: (_) {},
            action: action,
            brand: brand,
            child: page,
          );
    return PreviewFrame(
      platform: platform,
      brightness: brightness,
      // A semantics node of its own: the app's routes block only what is
      // under them in it, never the page the preview stands on.
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
          builder: (context, app) => ClayHost(
            theme: theme,
            darkTheme: darkTheme,
            brightness: brightness,
            child: app ?? const SizedBox.shrink(),
          ),
          home: switch (presentation) {
            ClayPresentation.root => rooted(child),
            ClayPresentation.pushed => PreviewStage(
              route: (context, page) => ClayPage<void>(
                key: const ValueKey<String>('clay-preview'),
                child: page,
              ).createRoute(context),
              child: child,
            ),
            ClayPresentation.sheet => PreviewStage(
              route: (context, page) => ClaySheetPage<void>(
                key: const ValueKey<String>('clay-preview'),
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
        DiagnosticsProperty<ClayThemeData>('theme', theme, defaultValue: null),
      )
      ..add(
        DiagnosticsProperty<ClayThemeData>(
          'darkTheme',
          darkTheme,
          defaultValue: null,
        ),
      )
      ..add(DiagnosticsProperty<Brightness>('brightness', brightness))
      ..add(DiagnosticsProperty<ClayPresentation>('presentation', presentation))
      ..add(IterableProperty<ClayTab>('tabs', tabs))
      ..add(IntProperty('selectedIndex', selectedIndex))
      ..add(
        DiagnosticsProperty<ShellAction>('action', action, defaultValue: null),
      )
      ..add(StringProperty('brand', brand, defaultValue: null))
      ..add(FlagProperty('drawer', value: drawer, ifTrue: 'drawer'))
      ..add(DiagnosticsProperty<PreviewPlatform>('platform', platform));
  }
}

/// The app's places and its one act round a root page: [ClayScaffold]'s
/// dock on a phone, its rail on a tablet, its sidebar on a desktop. The act
/// is coral clay in the chrome, never floating over the page: a ball at the
/// dock's end on a phone, under the app's name at the head of the rail, a
/// worded key under it on the sidebar. An app on a router mounts it
/// through `ClayShell`; a preview mounts it directly.
///
/// ```dart
/// ClayAppShell(tabs: const [ClayTab(LucideIcons.sun, 'Today'), ClayTab(LucideIcons.listChecks, 'Habits')], selectedIndex: 0, onDestinationSelected: (i) {}, child: const TodayPage())
/// ```
class ClayAppShell extends StatelessWidget {
  /// [child] with the app's [tabs].
  const ClayAppShell({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.child,
    this.action,
    this.brand,
    this.showPlaces = true,
  });

  /// The app's places.
  final List<ClayTab> tabs;

  /// The place shown.
  final int selectedIndex;

  /// Called with the place chosen.
  final ValueChanged<int> onDestinationSelected;

  /// The page.
  final Widget child;

  /// The app's one act.
  final ShellAction? action;

  /// The app's name, at the head of the rail or the sidebar.
  final String? brand;

  /// Whether a phone's dock stands: false while a page pushed over the root
  /// covers it (a rail or a sidebar stays).
  final bool showPlaces;

  @override
  Widget build(BuildContext context) {
    final act = action;
    final name = brand;
    return ClayScaffold(
      destinations: [
        for (final tab in tabs)
          ClayDestination(icon: tab.icon, label: tab.label, key: tab.key),
      ],
      selectedIndex: selectedIndex,
      onDestinationSelected: tabs.isNotEmpty ? onDestinationSelected : null,
      showNavigation: showPlaces,
      brand: name == null || name.isEmpty ? null : _Brand(name),
      action: act == null ? null : _ActKey(act),
      body: child,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<ClayTab>('tabs', tabs))
      ..add(IntProperty('selectedIndex', selectedIndex))
      ..add(
        ObjectFlagProperty<ValueChanged<int>>.has(
          'onDestinationSelected',
          onDestinationSelected,
        ),
      )
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
/// fits, its first letter where it does not (a rail).
class _Brand extends StatelessWidget {
  const _Brand(this.name);

  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 120;
        return Semantics(
          header: true,
          label: name,
          child: ExcludeSemantics(
            child: Text(
              narrow ? name.characters.first.toUpperCase() : name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: narrow ? TextAlign.center : TextAlign.start,
              style: theme.textTheme.title.copyWith(color: theme.colors.ink),
            ),
          ),
        );
      },
    );
  }
}

/// The shell's act: coral clay when it is the app's standing invitation
/// ([ShellAction.accent]), else plain clay. The sidebar has room for its
/// words: a key with its glyph; elsewhere a ball.
class _ActKey extends StatelessWidget {
  const _ActKey(this.action);

  final ShellAction action;

  @override
  Widget build(BuildContext context) {
    final words = action.label ?? 'New';
    void press() => action.onPressed(context);
    final wide =
        MediaQuery.sizeOf(context).width >= ClayMetrics.sidebarBreakpoint;
    if (wide) {
      final glyph = Icon(action.icon);
      return KeyedSubtree(
        key: action.key,
        child: action.accent
            ? ClayButton.filled(words, onPressed: press, icon: glyph)
            : ClayButton(words, onPressed: press, icon: glyph),
      );
    }
    return KeyedSubtree(
      key: action.key,
      child: action.accent
          ? ClayIconButton.filled(
              onPressed: press,
              tooltip: words,
              icon: Icon(action.icon),
            )
          : ClayIconButton(
              onPressed: press,
              tooltip: words,
              icon: Icon(action.icon),
            ),
    );
  }
}

/// One of an app shell's places as an app declares it: its glyph, its name
/// and the key on its cell.
///
/// ```dart
/// ClayTab(LucideIcons.sun, 'Today', ValueKey('open-today'))
/// ```
@immutable
class ClayTab {
  /// A place called [label], shown by [icon].
  const ClayTab(this.icon, this.label, [this.key]);

  /// Its glyph.
  final IconData icon;

  /// Its name.
  final String label;

  /// The key on its cell.
  final Key? key;
}

/// The app's one act beside its places (add, log, capture): coral clay in
/// the chrome when [accent], plain clay when not.
///
/// ```dart
/// ClayShellAction(icon: LucideIcons.plus, accent: true, onPressed: (context) => openNewHabit(context))
/// ```
class ClayShellAction extends ShellAction {
  /// An act wearing [icon].
  const ClayShellAction({
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
/// const ClayLoadingState()
/// ```
class ClayLoadingState extends StatelessWidget {
  /// The page waiting.
  const ClayLoadingState({super.key, this.label});

  /// What a screen reader says; null takes the design kit's ("Loading").
  final String? label;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(ClaySpacing.extraLarge),
      child: ClayStateView(
        state: ClayState.loading,
        title: label ?? RawWidgetsLocalizations.of(context).loadingLabel,
      ),
    ),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('label', label, defaultValue: null));
  }
}

/// When a page's data could not load: what happened, and one way forward
/// ([onRetry]'s key, or an [action] of the app's).
///
/// ```dart
/// ClayErrorState(title: 'Could not load', message: 'Check your connection.', onRetry: reload)
/// ```
class ClayErrorState extends StatelessWidget {
  /// The page that failed.
  const ClayErrorState({
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
            : ClayButton(
                retryLabel ??
                    RawWidgetsLocalizations.of(context).retryButtonLabel,
                onPressed: retry,
              ));
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: ClayMetrics.readingWidth),
        child: Padding(
          padding: const EdgeInsets.all(ClaySpacing.large),
          child: ClayStateView(
            state: ClayState.error,
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

/// The plain one-line field: a [ClayTextField] with a hint or a label. On a
/// page you write, use [ClayTextField], which says more.
///
/// ```dart
/// ClayInput(hintText: 'Search habits', onSubmitted: search)
/// ```
class ClayInput extends StatelessWidget {
  /// A field hinting [hintText], or named [labelText].
  const ClayInput({
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

  /// Its name, over it.
  final String? labelText;

  /// What is wrong with what was typed; null when nothing is.
  final String? errorText;

  /// Whether its words are hidden (a password).
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
  Widget build(BuildContext context) => ClayTextField(
    controller: controller,
    labelText: labelText,
    hintText: hintText,
    errorText: errorText,
    obscureText: obscureText,
    semanticLabel: labelText ?? hintText,
    onChanged: onChanged,
    onSubmitted: onSubmitted,
    enabled: enabled,
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('hintText', hintText, defaultValue: null))
      ..add(StringProperty('labelText', labelText, defaultValue: null))
      ..add(StringProperty('errorText', errorText, defaultValue: null))
      ..add(FlagProperty('obscureText', value: obscureText, ifTrue: 'obscure'))
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

/// Gloss's app frame: what an app's pages stand in. [GlossHost] once over
/// the navigator; [GlossScreen] round each page; [GlossPage] the route a
/// push raises one in (a sheet's is `GlossSheetPage`); [GlossPreview] one
/// page alone, as the app stands it; [GlossLoadingState] and
/// [GlossErrorState] a page whose data is on its way or lost; [GlossInput]
/// the plain one-line field; [GlossTab] and [GlossShellAction] an app
/// shell's places and its one act.
library;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ui_core/host.dart';
import 'package:ui_core/ui_core.dart';

import 'button.dart';
import 'display.dart';
import 'feedback.dart';
import 'navigation.dart';
import 'overlays.dart';
import 'page_transitions.dart';
import 'surface.dart';
import 'text_field.dart';
import 'theme.dart';

/// The widest a page's content stands, inside its margins: a calm desktop
/// reads in one column of this width, centred.
const double _pageWidth = 1080;

/// The app's host, mounted once over its navigator (`WidgetsApp.builder`):
/// Gloss's theme for the brightness asked for, its toasts and its porcelain
/// page.
///
/// ```dart
/// MaterialApp(builder: (context, child) => GlossHost(child: child!))
/// ```
class GlossHost extends StatelessWidget {
  /// Hosts [child] in [theme] or [darkTheme], as [brightness] (or the platform)
  /// asks; either left out is the jade preset in that brightness.
  const GlossHost({
    super.key,
    this.theme,
    this.darkTheme,
    this.brightness,
    required this.child,
  });

  /// The theme by day.
  final GlossThemeData? theme;

  /// The theme by night.
  final GlossThemeData? darkTheme;

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
        GlossThemeData.preset(GlossThemeData.presets.first, wanted);
    return GlossTheme(
      data: data,
      child: GlossToaster(
        child: ColoredBox(color: data.colors.page, child: child),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<GlossThemeData>('theme', theme, defaultValue: null),
      )
      ..add(
        DiagnosticsProperty<GlossThemeData>(
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
/// on the porcelain in the page's margins, no wider than 1080 px, and its
/// [footer] fixed at its foot under a hairline: the page's one gel key in
/// reach. In a sheet it is as tall as its content allows and stands on the
/// sheet's glaze.
///
/// ```dart
/// GlossScreen(topBar: GlossTopBar(title: 'Recipe', leading: GlossTopBar.autoLeading(context)), body: const Text('Serves two.'))
/// ```
class GlossScreen extends StatelessWidget {
  /// A page of [body].
  const GlossScreen({
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

  /// The bar over it, usually a [GlossTopBar]; null on a root that opens on
  /// its own head.
  final Widget? topBar;

  /// What stands fixed at the foot: the page's one action, a gel key.
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
    final theme = GlossTheme.of(context);
    final c = theme.colors;
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final margin = GlossSpacing.pageMargin(width);
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
              GlossSpacing.large + top,
              margin,
              GlossSpacing.extraLarge + ShellInsets.of(context) + bottom,
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
    final framed = width >= GlossMetrics.railBreakpoint && !sheet;
    final Widget laid = Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: Column(
        mainAxisSize: sheet ? MainAxisSize.min : MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ?bar,
          if (sheet) Flexible(child: content) else Expanded(child: content),
          if (foot != null) ...[
            const GlossDivider(),
            Padding(
              padding: EdgeInsets.fromLTRB(
                margin,
                GlossSpacing.medium,
                margin,
                GlossSpacing.medium + media.padding.bottom,
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
    );
    // A sheet's glaze is its route's; a page stands on the porcelain.
    return sheet ? laid : ColoredBox(color: c.page, child: laid);
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
/// porcelain, changed in Gloss's way ([GlossPageTransitionsBuilder]): it
/// rises a short way into place on a settling spring while the page under
/// it sinks back and dims; going back is the reverse. On iOS it pops with
/// iOS's swipe back from the leading edge too. A go_router route's
/// `pageBuilder` returns it with the route's `state.pageKey`.
///
/// ```dart
/// GlossPage<void>(key: state.pageKey, child: const RecipePage())
/// ```
class GlossPage<T> extends Page<T> {
  /// A page of [child].
  const GlossPage({
    required this.child,
    this.fullscreenDialog = false,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  /// The page's screen, usually a [GlossScreen].
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
        color: GlossTheme.of(context).colors.page,
        child: page is GlossPage ? page.child : child,
      );
    }

    return _GlossPageRoute<T>(
      settings: this,
      fullscreenDialog: fullscreenDialog,
      builder: current,
    );
  }
}

/// A [GlossPage]'s route: an opaque page, changed by
/// [GlossPageTransitionsBuilder] whatever the app's Material theme says.
class _GlossPageRoute<T> extends PageRoute<T> {
  _GlossPageRoute({
    required this.builder,
    super.settings,
    super.fullscreenDialog,
  });

  final WidgetBuilder builder;

  static const _change = GlossPageTransitionsBuilder();

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

/// How a page stands in a [GlossPreview].
enum GlossPresentation {
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
/// GlossPreview(presentation: GlossPresentation.pushed, child: GlossScreen(body: const Text('Serves two.')))
/// ```
class GlossPreview extends StatelessWidget {
  /// A preview of [child].
  const GlossPreview({
    super.key,
    required this.child,
    this.theme,
    this.darkTheme,
    this.brightness = Brightness.light,
    this.presentation = GlossPresentation.root,
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
  final GlossThemeData? theme;

  /// The theme by night.
  final GlossThemeData? darkTheme;

  /// The brightness to draw in.
  final Brightness brightness;

  /// How the page stands.
  final GlossPresentation presentation;

  /// The app's places, on a root.
  final List<GlossTab> tabs;

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
        : GlossAppShell(
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
          builder: (context, app) => GlossHost(
            theme: theme,
            darkTheme: darkTheme,
            brightness: brightness,
            child: app ?? const SizedBox.shrink(),
          ),
          home: switch (presentation) {
            GlossPresentation.root => rooted(child),
            GlossPresentation.pushed => PreviewStage(
              route: (context, page) => GlossPage<void>(
                key: const ValueKey<String>('gloss-preview'),
                child: page,
              ).createRoute(context),
              child: child,
            ),
            GlossPresentation.sheet => PreviewStage(
              route: (context, page) => GlossSheetPage<void>(
                key: const ValueKey<String>('gloss-preview'),
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
        DiagnosticsProperty<GlossThemeData>('theme', theme, defaultValue: null),
      )
      ..add(
        DiagnosticsProperty<GlossThemeData>(
          'darkTheme',
          darkTheme,
          defaultValue: null,
        ),
      )
      ..add(DiagnosticsProperty<Brightness>('brightness', brightness))
      ..add(
        DiagnosticsProperty<GlossPresentation>('presentation', presentation),
      )
      ..add(IterableProperty<GlossTab>('tabs', tabs))
      ..add(IntProperty('selectedIndex', selectedIndex))
      ..add(
        DiagnosticsProperty<ShellAction>('action', action, defaultValue: null),
      )
      ..add(StringProperty('brand', brand, defaultValue: null))
      ..add(FlagProperty('drawer', value: drawer, ifTrue: 'drawer'))
      ..add(DiagnosticsProperty<PreviewPlatform>('platform', platform));
  }
}

/// The app's places and its one act round a root page: [GlossScaffold]'s
/// bottom bar on a phone, its rail on a tablet, its sidebar on a desktop.
/// The act is a jade gel key in the chrome, never floating over the page:
/// the bottom bar's last cell on a phone, under the app's name at the head
/// of the rail or the sidebar. An app on a router mounts it through
/// `GlossShell`; a preview mounts it directly.
///
/// ```dart
/// GlossAppShell(tabs: const [GlossTab(LucideIcons.house, 'Today'), GlossTab(LucideIcons.bookOpen, 'Recipes')], selectedIndex: 0, onDestinationSelected: (i) {}, child: const TodayPage())
/// ```
class GlossAppShell extends StatelessWidget {
  /// [child] with the app's [tabs].
  const GlossAppShell({
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
  final List<GlossTab> tabs;

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

  /// Whether a phone's bar stands: false while a page pushed over the root
  /// covers it, and it springs away with the act in it (a rail or a sidebar
  /// stays).
  final bool showPlaces;

  @override
  Widget build(BuildContext context) {
    final act = action;
    final name = brand;
    return GlossScaffold(
      destinations: [
        for (final tab in tabs)
          GlossDestination(icon: tab.icon, label: tab.label, key: tab.key),
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
      ..add(IterableProperty<GlossTab>('tabs', tabs))
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

/// The app's name at the head of its places, letterpressed: in the title
/// type where it fits, its first letter where it does not (a rail).
class _Brand extends StatelessWidget {
  const _Brand(this.name);

  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 120;
        return Semantics(
          header: true,
          label: name,
          child: ExcludeSemantics(
            child: Padding(
              padding: const EdgeInsets.all(GlossSpacing.regular),
              child: Text(
                narrow ? name.characters.first.toUpperCase() : name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: narrow ? TextAlign.center : TextAlign.start,
                style: glossLetterpress(theme.textTheme.title, theme.colors),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The shell's act: a jade gel bead when it is the app's standing
/// invitation ([ShellAction.accent]), else a pearl one.
class _ActKey extends StatelessWidget {
  const _ActKey(this.action);

  final ShellAction action;

  @override
  Widget build(BuildContext context) {
    final words = action.label ?? 'New';
    void press() => action.onPressed(context);
    // The sidebar has room for the act's words: a key with its glyph.
    final wide =
        MediaQuery.sizeOf(context).width >= GlossMetrics.sidebarBreakpoint;
    if (wide) {
      final glyph = Icon(action.icon, size: 18);
      return KeyedSubtree(
        key: action.key,
        child: action.accent
            ? GlossButton.filled(words, onPressed: press, icon: glyph)
            : GlossButton(words, onPressed: press, icon: glyph),
      );
    }
    return KeyedSubtree(
      key: action.key,
      child: action.accent
          ? GlossIconButton.filled(
              onPressed: press,
              tooltip: words,
              icon: Icon(action.icon),
            )
          : GlossIconButton(
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
/// GlossTab(LucideIcons.house, 'Today', ValueKey('open-today'))
/// ```
@immutable
class GlossTab {
  /// A place called [label], shown by [icon].
  const GlossTab(this.icon, this.label, [this.key]);

  /// Its glyph.
  final IconData icon;

  /// Its name.
  final String label;

  /// The key on its cell.
  final Key? key;
}

/// The app's one act beside its places (add, plan, capture): a jade gel
/// bead in the chrome when [accent], a pearl one when not.
///
/// ```dart
/// GlossShellAction(icon: LucideIcons.plus, accent: true, onPressed: (context) => openNewRecipe(context))
/// ```
class GlossShellAction extends ShellAction {
  /// An act wearing [icon].
  const GlossShellAction({
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
/// const GlossLoadingState()
/// ```
class GlossLoadingState extends StatelessWidget {
  /// The page waiting.
  const GlossLoadingState({super.key, this.label});

  /// What a screen reader says; null takes the design kit's ("Loading").
  final String? label;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(GlossSpacing.extraLarge),
      child: GlossStateView(
        state: GlossState.loading,
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
/// GlossErrorState(title: 'Could not load', message: 'Check your connection.', onRetry: reload)
/// ```
class GlossErrorState extends StatelessWidget {
  /// The page that failed.
  const GlossErrorState({
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
            : GlossButton(
                retryLabel ??
                    RawWidgetsLocalizations.of(context).retryButtonLabel,
                onPressed: retry,
              ));
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: GlossMetrics.readingWidth),
        child: Padding(
          padding: const EdgeInsets.all(GlossSpacing.large),
          child: GlossStateView(
            state: GlossState.error,
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

/// The plain one-line field: a [GlossTextField] with a hint or a label. On
/// a page you write, use [GlossTextField], which says more.
///
/// ```dart
/// GlossInput(hintText: 'Search recipes', onSubmitted: search)
/// ```
class GlossInput extends StatelessWidget {
  /// A field hinting [hintText], or named [labelText].
  const GlossInput({
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
  Widget build(BuildContext context) => GlossTextField(
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

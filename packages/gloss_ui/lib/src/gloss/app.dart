/// Gloss's app frame: what an app's pages stand in. [GlossHost] once over
/// the navigator; [GlossAppShell] round the app's places; [GlossScreen]
/// round each page; [GlossPage] the route a push raises one in (a sheet's
/// is `GlossSheetPage`); [GlossLoadingState] and [GlossErrorState] a page
/// whose data is on its way or lost; [GlossInput] the plain one-line field.
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
import 'text_field.dart';
import 'theme.dart';

/// The app's host, mounted once over its navigator (`WidgetsApp.builder`):
/// Gloss's theme for the brightness asked for, its toasts and its porcelain
/// page.
///
/// ```dart
/// MaterialApp(builder: (context, child) => GlossHost(child: child!))
/// ```
class GlossHost extends StatelessWidget {
  /// Hosts [child] in [theme] or [darkTheme], as [brightness] (or the platform)
  /// asks; either left out is [palette]'s in that brightness.
  const GlossHost({
    super.key,
    this.palette,
    this.theme,
    this.darkTheme,
    this.brightness,
    required this.child,
  });

  /// The palette both brightnesses are built from, one of
  /// [GlossThemeData.palettes] (the app's stored choice, say); null is the
  /// first, jade. A change of palette eases from the old colours to the new.
  final RawNamedPalette? palette;

  /// The theme by day; null is [palette]'s.
  final GlossThemeData? theme;

  /// The theme by night; null is [palette]'s.
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
        GlossThemeData.preset(
          (palette ?? GlossThemeData.palettes.first).id,
          wanted,
        );
    // Day to night, one palette to another: the app moves to the new theme
    // (at once under Reduce Motion), as MaterialApp's theme does.
    return AnimatedGlossTheme(
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
        DiagnosticsProperty<RawNamedPalette>(
          'palette',
          palette,
          defaultValue: null,
        ),
      )
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
              constraints: BoxConstraints(
                maxWidth: GlossSpacing.pageMeasure + 2 * margin,
              ),
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
          // The foot, under its hairline. A toast stands above it, as a
          // Scaffold keeps a snackbar above its persistent footer buttons.
          if (foot != null)
            RawToasterKeepClear(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const GlossDivider(),
                  // Its keys keep to the page's column: on a wide screen
                  // they end where the page's words do.
                  LayoutBuilder(
                    builder: (context, box) {
                      final inset = GlossSpacing.pageInset(width, box.maxWidth);
                      return Padding(
                        padding: EdgeInsets.fromLTRB(
                          inset,
                          GlossSpacing.medium,
                          inset,
                          GlossSpacing.medium + media.padding.bottom,
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

/// While a page's data is on its way: the spinner over its word, centred.
///
/// ```dart
/// const GlossLoadingState()
/// ```
class GlossLoadingState extends StatelessWidget {
  /// The page waiting.
  const GlossLoadingState({super.key, this.label});

  /// Its word under the spinner; null takes the design kit's ("Loading").
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

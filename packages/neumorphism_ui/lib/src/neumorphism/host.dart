// Neumorphism's part of the app host: what the host app mounts around its router (the theme, the ground, the shell's
// act and scope, its pages and the preview frame). The package exports it from neumorphism_host.dart, beside the
// main library, not in it: an app built on the package draws its screens without it.
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ui_core/ui_core.dart';
import 'package:ui_core/host.dart';

import 'chrome_metrics.dart';

import 'localizations.dart';
import 'overlays.dart';
import 'theme.dart';
import 'chrome.dart';
import 'chrome_items.dart';
import 'internal/veil.dart';
import 'internal/page_motion.dart';

/// The app-level act beside the tabs: a small round key in the tab bar's middle on a phone, the pilaster's wide act on a desktop.
/// A plain moulded key when [accent] is off.
class NeumorphicShellAction extends ShellAction {
  /// Creates a [NeumorphicShellAction]. Not const: [ShellAction] is not.
  // ignore: prefer_const_constructors_in_immutables
  NeumorphicShellAction({
    required super.icon,
    required super.onPressed,
    super.label,
    super.accent,
    super.key,
  });
}

/// What every page under the shell reads: the app's name and its places.
///
/// ```dart
/// NeumorphicChromeScope(brand: NeumorphicBrand(name: 'Home'), nav: const [], active: 0, child: Text('Page content'))
/// ```
class NeumorphicChromeScope extends InheritedWidget {
  /// Creates a [NeumorphicChromeScope].
  const NeumorphicChromeScope({
    super.key,
    required this.brand,
    required this.nav,
    required this.active,
    this.action,
    required super.child,
  });

  /// The brand displayed by the surrounding chrome.
  final NeumorphicBrand brand;

  /// The navigation destinations available to descendants.
  final List<NeumorphicNavItem> nav;

  /// The zero-based index of the current destination.
  final int active;

  /// The primary action available to the surrounding chrome.
  final ShellAction? action;

  /// The nearest chrome configuration, or null outside a chrome scope.
  static NeumorphicChromeScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<NeumorphicChromeScope>();
  @override
  bool updateShouldNotify(NeumorphicChromeScope old) =>
      old.active != active ||
      old.brand != brand ||
      old.nav != nav ||
      old.action != action;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<NeumorphicBrand>('brand', brand))
      ..add(IterableProperty<NeumorphicNavItem>('nav', nav))
      ..add(IntProperty('active', active))
      ..add(
        DiagnosticsProperty<ShellAction>('action', action, defaultValue: null),
      );
  }
}

/// The app's host, mounted once around the router's navigator: Neumorphism's theme, ground and text defaults.
///
/// ```dart
/// NeumorphicHost(child: Text('Themed content'))
/// ```
class NeumorphicHost extends StatelessWidget {
  /// Creates a [NeumorphicHost].
  const NeumorphicHost({
    super.key,
    this.light,
    this.darkData,
    this.brightness,
    required this.child,
  });

  /// The theme used in the light appearance, or the default when null.
  final NeumorphicThemeData? light;

  /// The theme used in the dark appearance, or the default when null.
  final NeumorphicThemeData? darkData;

  /// An appearance override; null follows the surrounding media query.
  final Brightness? brightness;

  /// The content placed inside this component.
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final wanted =
        brightness ??
        PreviewFrame.maybeOf(context)?.brightness ??
        MediaQuery.platformBrightnessOf(context);
    final theme =
        (wanted == Brightness.dark ? darkData : light) ??
        NeumorphicThemeData.preset(NeumorphicThemeData.presets.first, wanted);
    // Neumorphism's tap floors: a finger's 48 (Android's), a pointer's 24 (WCAG 2.2). Each control lays out at the
    // finger's 48 on every platform (NeumorphicChromeMetrics.targetSize), so a row stands the same wherever it runs.
    return DesignTapTargetScope(
      targets: const DesignTapTargets(
        touch: Size.square(NeumorphicChromeMetrics.touchTarget),
      ),
      child: NeumorphicTheme(
        data: theme,
        child: Builder(
          builder: (context) {
            final t = NeumorphicTheme.of(context);
            return ColoredBox(
              color: t.colors.ground,
              child: DefaultTextStyle(
                style: t.textTheme.body,
                child: IconTheme(
                  data: IconThemeData(color: t.colors.ink, size: 22),
                  child: NeumorphicToaster(child: child),
                ),
              ),
            );
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
        DiagnosticsProperty<NeumorphicThemeData>(
          'light',
          light,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<NeumorphicThemeData>(
          'darkData',
          darkData,
          defaultValue: null,
        ),
      )
      ..add(
        EnumProperty<Brightness>('brightness', brightness, defaultValue: null),
      );
  }
}

/// The router's page for a route pushed off a root, on the theme's ground.
class NeumorphicPage<T> extends Page<T> {
  /// Creates a [NeumorphicPage].
  const NeumorphicPage({required this.child, super.key, super.name});

  /// The content placed inside this component.
  final Widget child;
  @override
  Route<T> createRoute(BuildContext context) {
    final motion = NeumorphicMotion.of(context);
    return _NeumorphicPageRoute<T>(
      settings: this,
      // The look's page change, as a MaterialPageRoute the app pushes under the theme takes it.
      transitionDuration: motion.travel,
      reverseTransitionDuration: motion.leave,
      pageBuilder: (context, _, _) {
        final settings = ModalRoute.of(context)?.settings;
        return ColoredBox(
          color: NeumorphicTheme.of(context).colors.ground,
          child: settings is NeumorphicPage<T> ? settings.child : child,
        );
      },
      // On iOS the swipe back from the screen's edge stands round it.
      transitions: neumorphicPageMotionHere(motion),
    );
  }
}

// A router page's route: its page on the ground, changing as the look's routes do, with the route itself handed to
// the change (iOS's swipe back reads it).
class _NeumorphicPageRoute<T> extends PageRouteBuilder<T> {
  _NeumorphicPageRoute({
    required super.settings,
    required super.transitionDuration,
    required super.reverseTransitionDuration,
    required super.pageBuilder,
    required this.transitions,
  });

  final PageTransitionsBuilder transitions;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => transitions.buildTransitions<T>(
    this,
    context,
    animation,
    secondaryAnimation,
    child,
  );
}

/// The router's page for a sheet, raised on the root navigator over the shell: from a phone's foot, as a slab in the middle of a desktop.
/// [drawer] stands it as tall as its content. The screen inside derives its close.
/// Its routes are ui_core's, on springs as long as the theme's move: on a phone a [DesignBottomSheetRoute] (a finger
/// drags it down and away, the screen's scroll view handing the drag over at its top), on a desktop a
/// [DesignDialogRoute]; both close on Escape and back, and give the focus back as they close.
class NeumorphicSheetPage<T> extends Page<T> {
  /// Creates a [NeumorphicSheetPage].
  const NeumorphicSheetPage({
    required this.child,
    this.drawer = false,
    this.fullScreen = false,
    super.key,
    super.name,
  });

  /// The content placed inside this component.
  final Widget child;

  /// Whether to present the page as a side drawer.
  final bool drawer;

  /// Whether the sheet occupies the full available height.
  final bool fullScreen;
  @override
  Route<T> createRoute(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final motion = NeumorphicMotion.of(context);
    // Read as it builds: a window that grows takes the sheet with it.
    double most(BuildContext sheetContext) =>
        MediaQuery.sizeOf(sheetContext).height * .9;
    Widget current(BuildContext sheetContext) {
      final page = ModalRoute.of(sheetContext)?.settings;
      return page is NeumorphicSheetPage ? page.child : child;
    }

    // A sheet on a desktop is a phone-wide panel, so its parts lay out as they do on a phone: one column, phone type.
    Widget card(BuildContext sheetContext, {required bool desk}) {
      final media = MediaQuery.of(sheetContext);
      return MediaQuery(
        data: media.copyWith(
          size: Size(
            media.size.width < 560 ? media.size.width : 560,
            media.size.height,
          ),
        ),
        child: NeumorphicTheme(
          data: t,
          child: RoutePresentationScope(
            presentation: RoutePresentation.sheet,
            child: ClipRRect(
              borderRadius: desk
                  ? BorderRadius.circular(t.shapes.corner(24).radius)
                  : BorderRadius.vertical(
                      top: Radius.circular(t.shapes.corner(24).radius),
                    ),
              child: ColoredBox(
                color: t.colors.ground,
                child: Material(
                  type: MaterialType.transparency,
                  child: current(sheetContext),
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (fullScreen) {
      return PageRouteBuilder<T>(
        settings: this,
        fullscreenDialog: true,
        transitionDuration: motion.move,
        reverseTransitionDuration: motion.leave,
        transitionsBuilder: (context, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
        pageBuilder: (sheetContext, _, _) => RoutePresentationScope(
          presentation: RoutePresentation.sheet,
          child: ColoredBox(
            color: t.colors.ground,
            child: current(sheetContext),
          ),
        ),
      );
    }
    final barrier = neumorphicVeil(t.colors);
    final stiffness = neumorphicRouteStiffness(t.motion.move);
    final close = NeumorphicLocalizations.of(context).close;
    if (t.desk) {
      return DesignDialogRoute<T>(
        settings: this,
        stiffness: stiffness,
        barrierDismissible: true,
        barrierLabel: close,
        barrierColor: barrier,
        builder: (sheetContext, details) => FadeTransition(
          opacity: details.animation,
          child: Center(
            child: SizedBox(
              width: 560,
              height: drawer ? null : most(sheetContext),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: most(sheetContext)),
                child: card(sheetContext, desk: true),
              ),
            ),
          ),
        ),
      );
    }
    return DesignBottomSheetRoute<T>(
      settings: this,
      stiffness: stiffness,
      barrierColor: barrier,
      barrierLabel: close,
      builder: (sheetContext, details) => PrimaryScrollController(
        controller: details.scrollController,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: most(sheetContext)),
          child: SizedBox(
            height: drawer ? null : most(sheetContext),
            child: card(sheetContext, desk: false),
          ),
        ),
      ),
    );
  }
}

/// How a page stands in its preview.
/// The route framing demonstrated by a preview.
enum NeumorphicPresentation {
  /// A top-level screen with navigation chrome.
  root,

  /// A screen reached by forward navigation.
  pushed,

  /// Content presented as a sheet or drawer.
  sheet,
}

/// One page's isolated preview: the same host, tab bar, route and sheet the app gives it live, without the router.
///
/// ```dart
/// NeumorphicPreview(child: NeumorphicScaffold(body: Text('A preview')))
/// ```
class NeumorphicPreview extends StatelessWidget {
  /// Creates a [NeumorphicPreview].
  const NeumorphicPreview({
    super.key,
    required this.child,
    this.light,
    this.darkData,
    this.presentation = NeumorphicPresentation.root,
    this.tabs = const [],
    this.activeIndex = 0,
    this.action,
    this.brand,
    this.drawer = false,
    this.platform = PreviewPlatform.android,
    this.brightness = Brightness.light,
  });

  /// The content placed inside this component.
  final Widget child;

  /// The theme used in the light appearance, or the default when null.
  final NeumorphicThemeData? light;

  /// The theme used in the dark appearance, or the default when null.
  final NeumorphicThemeData? darkData;

  /// The route presentation demonstrated by this preview.
  final NeumorphicPresentation presentation;

  /// The navigation destinations shown by the preview.
  final List<NeumorphicTab> tabs;

  /// The zero-based index of the active preview destination.
  final int activeIndex;

  /// An optional primary preview action.
  final ShellAction? action;

  /// An optional name displayed in the preview chrome.
  final String? brand;

  /// Whether the sheet presentation uses a side drawer.
  final bool drawer;

  /// The platform whose adaptive layout is demonstrated.
  final PreviewPlatform platform;

  /// The appearance used to resolve the theme.
  final Brightness brightness;
  @override
  Widget build(BuildContext context) {
    final nav = [
      for (final tab in tabs)
        NeumorphicNavItem(
          label: tab.label,
          icon: tab.icon,
          key: tab.key,
          onPressed: () {},
        ),
    ];
    Widget scoped(Widget page) => tabs.isEmpty
        ? page
        : NeumorphicChromeScope(
            brand: NeumorphicBrand(name: brand ?? ''),
            nav: nav,
            active: activeIndex,
            action: action,
            child: page,
          );
    return PreviewFrame(
      platform: platform,
      brightness: brightness,
      // The preview's app in a semantics container of its own: its first route's modal barrier hides from a screen
      // reader whatever was painted before it in the same container, so a preview on a page took the page above it
      // (material_ui's MaterialApp has none of the containers Flutter's own MaterialApp had).
      child: Semantics(
        container: true,
        child: MaterialApp(
          key: ValueKey<Object>((presentation, drawer)),
          debugShowCheckedModeBanner: false,
          builder: (context, app) => NeumorphicHost(
            light: light,
            darkData: darkData,
            brightness: brightness,
            child: app ?? const SizedBox.shrink(),
          ),
          home: switch (presentation) {
            NeumorphicPresentation.root => Builder(
              builder: (context) => tabs.isEmpty
                  ? child
                  : Column(
                      children: [
                        Expanded(child: scoped(child)),
                        if (!NeumorphicTheme.of(context).desk)
                          NeumorphicNavigationBar(
                            items: nav,
                            selectedIndex: activeIndex,
                            action: action,
                          ),
                      ],
                    ),
            ),
            NeumorphicPresentation.pushed => PreviewStage(
              route: (context, page) => NeumorphicPage<void>(
                key: const ValueKey<String>('neumorphism-preview'),
                child: page,
              ).createRoute(context),
              child: scoped(child),
            ),
            NeumorphicPresentation.sheet => PreviewStage(
              route: (context, page) => NeumorphicSheetPage<void>(
                key: const ValueKey<String>('neumorphism-preview'),
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
        DiagnosticsProperty<NeumorphicThemeData>(
          'light',
          light,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<NeumorphicThemeData>(
          'darkData',
          darkData,
          defaultValue: null,
        ),
      )
      ..add(
        EnumProperty<NeumorphicPresentation>(
          'presentation',
          presentation,
          defaultValue: NeumorphicPresentation.root,
        ),
      )
      ..add(
        IterableProperty<NeumorphicTab>(
          'tabs',
          tabs,
          defaultValue: const <NeumorphicTab>[],
        ),
      )
      ..add(IntProperty('activeIndex', activeIndex, defaultValue: 0))
      ..add(
        DiagnosticsProperty<ShellAction>('action', action, defaultValue: null),
      )
      ..add(StringProperty('brand', brand, defaultValue: null))
      ..add(DiagnosticsProperty<bool>('drawer', drawer, defaultValue: false))
      ..add(
        EnumProperty<PreviewPlatform>(
          'platform',
          platform,
          defaultValue: PreviewPlatform.android,
        ),
      )
      ..add(
        EnumProperty<Brightness>(
          'brightness',
          brightness,
          defaultValue: Brightness.light,
        ),
      );
  }
}

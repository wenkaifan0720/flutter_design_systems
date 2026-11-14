// The host layer: what an app's router and shell draw a look's pages with (the host, its pages and sheets, the
// preview a gallery shows a page in, the shell's action and the chrome its pages read). The package exports it
// from its host library, not its main one.

import 'package:material_ui/material_ui.dart';

import 'internal/face.dart';

import 'package:ui_core/host.dart';
import 'package:ui_core/ui_core.dart';

import 'theme.dart';
import 'behavior.dart';
import 'chrome.dart';

/// A small fact at the menu bar's end: synced, an hour. On a phone an item with an icon shows only the icon. [highlighted] gives the
/// icon the highlight.
///
/// ```dart
/// RetroDesktopUtility('Synced 09:18', icon: RetroDesktopGlyphs.cloudCheck, highlighted: true)
/// ```
class RetroDesktopUtility {
  /// Creates a [RetroDesktopUtility].
  const RetroDesktopUtility(this.text, {this.icon, this.highlighted = false});

  /// The text displayed by this part.
  final String text;

  /// The glyph shown with the content.
  final IconData? icon;

  /// Whether this item receives the active highlight.
  final bool highlighted;
}

/// The app-level act beside the tabs: a square in the middle of a phone's strip, an icon in the menu bar on a desktop. Lit
/// when [accent] is on.
class RetroDesktopShellAction extends ShellAction {
  /// Creates a [RetroDesktopShellAction].
  // ignore: prefer_const_constructors_in_immutables, not every build of ShellAction has a const constructor.
  RetroDesktopShellAction({
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
/// RetroDesktopChromeScope(brand: 'Workspace', nav: const [RetroDesktopNavItem(label: 'Files', short: 'Files', icon: RetroDesktopGlyphs.folder)], active: 0, child: const Text('Files'))
/// ```
class RetroDesktopChromeScope extends InheritedWidget {
  /// Creates a [RetroDesktopChromeScope].
  const RetroDesktopChromeScope({
    super.key,
    required this.brand,
    required this.nav,
    required this.active,
    this.action,
    required super.child,
  });

  /// The brand content shown in the desktop chrome.
  final String brand;

  /// The navigation content for this shell.
  final List<RetroDesktopNavItem> nav;

  /// The index of the active place in [nav].
  final int active;

  /// An optional action shown beside the content.
  final ShellAction? action;

  /// Returns the nearest matching scope, or null when none is installed.
  static RetroDesktopChromeScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<RetroDesktopChromeScope>();
  @override
  bool updateShouldNotify(RetroDesktopChromeScope old) =>
      old.active != active ||
      old.brand != brand ||
      old.nav != nav ||
      old.action != action;
}

/// The app's host, mounted once around the router's navigator: Retro Desktop's theme, desk and text defaults.
///
/// ```dart
/// RetroDesktopHost(child: const Text('Workspace'))
/// ```
class RetroDesktopHost extends StatelessWidget {
  /// Creates a [RetroDesktopHost].
  const RetroDesktopHost({
    super.key,
    this.light,
    this.dark,
    this.brightness,
    required this.child,
  });

  /// The light appearance.
  final RetroDesktopThemeData? light;

  /// The dark appearance.
  final RetroDesktopThemeData? dark;

  /// The requested light or dark appearance.
  final Brightness? brightness;

  /// The widget displayed inside this part.
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final wanted =
        brightness ??
        PreviewFrame.maybeOf(context)?.brightness ??
        MediaQuery.platformBrightnessOf(context);
    final theme =
        (wanted == Brightness.dark ? dark : light) ??
        RetroDesktopThemeData.preset(
          RetroDesktopThemeData.presets.first,
          wanted,
        );
    return Theme(
      data: Theme.of(context)
          .copyWith(platform: PreviewFrame.targetPlatformOf(context)),
      child: RetroDesktopTheme(
        data: theme,
        child: Builder(
          builder: (context) => ColoredBox(
            color: RetroDesktopTheme.of(context).colors.desktop,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// The router's page for a route pushed off a root, on the desk.
class RetroDesktopPage<T> extends Page<T> {
  /// A page with neutral Flutter navigation data.
  const RetroDesktopPage({super.key, super.name, required this.child});

  /// The page content.
  final Widget child;
  @override
  Route<T> createRoute(BuildContext context) => _RetroDesktopPageRoute<T>(
    settings: this,
    motion: RetroDesktopMotion.of(context),
    pageBuilder: (context, animation, secondaryAnimation) {
      final page = ModalRoute.of(context)?.settings;
      return ColoredBox(
        color: RetroDesktopTheme.of(context).colors.desktop,
        child: page is RetroDesktopPage<T> ? page.child : child,
      );
    },
  );
}

class _RetroDesktopPageRoute<T> extends PageRouteBuilder<T> {
  _RetroDesktopPageRoute({
    required this.motion,
    required super.pageBuilder,
    super.settings,
    super.fullscreenDialog,
  }) : super(
         transitionDuration: motion.travel,
         reverseTransitionDuration: motion.leave,
       );
  final RetroDesktopMotion motion;
  CurvedAnimation? _curve;
  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => FadeTransition(
    opacity: _curve ??= CurvedAnimation(
      parent: animation,
      curve: motion.enter,
      reverseCurve: motion.exit,
    ),
    child: child,
  );
  @override
  void dispose() {
    _curve?.dispose();
    super.dispose();
  }
}

/// The router's page for a sheet, raised on the root navigator over the shell: from a phone's foot, as a window in the middle
/// of a desktop. [drawer] stands it as tall as its content. The screen inside derives its close.
class RetroDesktopSheetPage<T> extends Page<T> {
  /// Creates a [RetroDesktopSheetPage].
  const RetroDesktopSheetPage({
    required this.child,
    this.drawer = false,
    this.fullScreen = false,
    super.key,
    super.name,
  });

  /// The widget displayed inside this part.
  final Widget child;

  /// Whether the sheet stands only as tall as its content, rather than most of the screen.
  final bool drawer;

  /// Whether this surface occupies the full screen.
  final bool fullScreen;
  @override
  Route<T> createRoute(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    // Read as it builds: a window that grows takes the sheet with it.
    double most(BuildContext sheetContext) =>
        MediaQuery.sizeOf(sheetContext).height * .9;
    Widget current(BuildContext sheetContext) {
      final page = ModalRoute.of(sheetContext)?.settings;
      return page is RetroDesktopSheetPage ? page.child : child;
    }

    // A sheet on a desktop is a phone-wide panel, so its parts lay out as they do on a phone: one column, phone type.
    Widget card(BuildContext sheetContext) {
      final media = MediaQuery.of(sheetContext);
      final currentTheme = RetroDesktopTheme.of(sheetContext);
      return MediaQuery(
        data: media.copyWith(
          size: Size(
            media.size.width < 560 ? media.size.width : 560,
            media.size.height,
          ),
        ),
        child: RetroDesktopTheme(
          data: currentTheme,
          child: RoutePresentationScope(
            presentation: RoutePresentation.sheet,
            child: retroDesktopFace(
              states: const {},
              component: currentTheme.sheetTheme,
              scale: RetroDesktopFaceScale.window,
              padding: EdgeInsets.zero,
              child: Material(
                type: MaterialType.transparency,
                child: current(sheetContext),
              ),
            ),
          ),
        ),
      );
    }

    if (fullScreen) {
      return _RetroDesktopPageRoute<T>(
        settings: this,
        fullscreenDialog: true,
        motion: RetroDesktopMotion.of(context),
        pageBuilder: (sheetContext, _, _) => RoutePresentationScope(
          presentation: RoutePresentation.sheet,
          child: ColoredBox(
            color: RetroDesktopTheme.of(sheetContext).colors.platinum,
            child: current(sheetContext),
          ),
        ),
      );
    }
    if (t.desk) {
      return RawDialogRoute<T>(
        settings: this,
        barrierDismissible: true,
        barrierLabel: DesignLocalizations.of(context).closeButtonLabel,
        transitionDuration: RetroDesktopMotion.of(context).raise,
        // Nothing behind is dimmed (the look's stacking law).
        barrierColor: const Color(0x00000000),
        pageBuilder: (sheetContext, _, _) => Center(
          child: SizedBox(
            width: 560,
            height: drawer ? null : most(sheetContext),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: most(sheetContext)),
              child: card(sheetContext),
            ),
          ),
        ),
      );
    }
    return ModalBottomSheetRoute<T>(
      settings: this,
      barrierLabel: DesignLocalizations.of(context).closeButtonLabel,
      sheetAnimationStyle: AnimationStyle(
        duration: RetroDesktopMotion.of(context).travel,
        reverseDuration: RetroDesktopMotion.of(context).leave,
      ),
      backgroundColor: const Color(0x00000000),
      modalBarrierColor: const Color(0x00000000),
      elevation: 0,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: most(sheetContext)),
          child: SizedBox(
            height: drawer ? null : most(sheetContext),
            child: card(sheetContext),
          ),
        ),
      ),
    );
  }
}

/// How a page stands in its preview.
enum RetroDesktopPresentation {
  /// The root page presentation.
  root,

  /// Whether the page is pushed above the root page.
  pushed,

  /// The sheet presentation.
  sheet,
}

/// One page's isolated preview: the same host, strip, route and sheet the app gives it live, without the router.
///
/// ```dart
/// RetroDesktopPreview(child: const Text('A page preview'))
/// ```
class RetroDesktopPreview extends StatelessWidget {
  /// Creates a [RetroDesktopPreview].
  const RetroDesktopPreview({
    super.key,
    required this.child,
    this.light,
    this.dark,
    this.presentation = RetroDesktopPresentation.root,
    this.tabs = const [],
    this.activeIndex = 0,
    this.action,
    this.brand,
    this.drawer = false,
    this.platform = PreviewPlatform.android,
    this.brightness = Brightness.light,
  });

  /// The widget displayed inside this part.
  final Widget child;

  /// The light appearance.
  final RetroDesktopThemeData? light;

  /// The dark appearance.
  final RetroDesktopThemeData? dark;

  /// The requested shell or page presentation.
  final RetroDesktopPresentation presentation;

  /// The tabs in reading order.
  final List<RetroDesktopTab> tabs;

  /// The index of the active item.
  final int activeIndex;

  /// An optional action shown beside the content.
  final ShellAction? action;

  /// The brand content shown in the desktop chrome.
  final String? brand;

  /// Whether the sheet stands only as tall as its content, rather than most of the screen.
  final bool drawer;

  /// An optional platform override for interaction conventions.
  final PreviewPlatform platform;

  /// The requested light or dark appearance.
  final Brightness brightness;
  @override
  Widget build(BuildContext context) {
    final direction = Directionality.maybeOf(context) ?? TextDirection.ltr;
    final nav = [
      for (final tab in tabs)
        RetroDesktopNavItem(
          label: tab.label,
          short: tab.label,
          icon: tab.icon,
          key: tab.key,
          onPressed: () {},
        ),
    ];
    Widget scoped(Widget page) => tabs.isEmpty
        ? page
        : RetroDesktopChromeScope(
            brand: brand ?? '',
            nav: nav,
            active: activeIndex,
            action: action,
            child: page,
          );
    return PreviewFrame(
      platform: platform,
      brightness: brightness,
      child: MaterialApp(
        key: ValueKey<Object>((presentation, drawer)),
        debugShowCheckedModeBanner: false,
        // The page reads in the direction of the screen it is shown on: the nested app's own locale turned a right-to-left
        // gallery's preview back to left to right.
        builder: (context, app) => Directionality(
          textDirection: direction,
          child: RetroDesktopHost(
            light: light,
            dark: dark,
            brightness: brightness,
            child: app ?? const SizedBox.shrink(),
          ),
        ),
        home: switch (presentation) {
          RetroDesktopPresentation.root => Builder(
            builder: (context) => tabs.isEmpty
                ? child
                : Column(
                    children: [
                      Expanded(child: scoped(child)),
                      if (!RetroDesktopTheme.of(context).desk)
                        RetroDesktopNavigationBar(
                          items: nav,
                          selectedIndex: activeIndex,
                          action: action,
                        ),
                    ],
                  ),
          ),
          RetroDesktopPresentation.pushed => PreviewStage(
            route: (context, page) => RetroDesktopPage<void>(
              key: const ValueKey<String>('platinum-preview'),
              child: page,
            ).createRoute(context),
            child: scoped(child),
          ),
          RetroDesktopPresentation.sheet => PreviewStage(
            route: (context, page) => RetroDesktopSheetPage<void>(
              key: const ValueKey<String>('platinum-preview'),
              drawer: drawer,
              child: page,
            ).createRoute(context),
            child: child,
          ),
        },
      ),
    );
  }
}

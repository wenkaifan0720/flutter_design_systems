// Comic's part of the host an app runs its pages under: the app's host around the navigator, its pages and sheets, the
// shell's action, the scope its chrome reads, and the preview frame. The package exports it from its host library, not
// the main one: an app draws its screens from the main library.
import 'package:ui_core/ui_core.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ui_core/host.dart';

import 'chrome.dart';
import 'press.dart';
import 'theme.dart';

ComicBrand _brand(String? name) => ComicBrand(name: name ?? '');

/// The app-level act beside the tabs: a small balloon in the tab bar's middle on a phone, at the masthead's end on a desktop.
/// Quieter (a plain square) when [accent] is off.
class ComicShellAction extends ShellAction {
  /// Creates a [ComicShellAction].
  // The lab's ShellAction keeps a deprecated alias in its initializer, so only the package's can be const.
  const ComicShellAction({
    required super.icon,
    required super.onPressed,
    super.label,
    super.accent = true,
    super.key,
  });
}

/// What every page under the shell reads: the app's name and its places.
///
/// ```dart
/// ComicChromeScope(brand: const ComicBrand(name: 'The Issue'), nav: const [], active: 0, child: page)
/// ```
class ComicChromeScope extends InheritedWidget {
  /// Creates a [ComicChromeScope].
  const ComicChromeScope({
    super.key,
    required this.brand,
    required this.nav,
    required this.active,
    this.action,
    required super.child,
  });

  /// The application identity shown by its chrome.
  final ComicBrand brand;

  /// Application destinations in display order.
  final List<ComicNavItem> nav;

  /// The active destination index.
  final int active;

  /// The optional action beside this content.
  final ShellAction? action;

  /// The nearest chrome scope, or null when none is installed.
  static ComicChromeScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ComicChromeScope>();
  @override
  bool updateShouldNotify(ComicChromeScope old) =>
      old.active != active ||
      old.brand != brand ||
      old.nav != nav ||
      old.action != action;
}

/// The app's host, mounted once around the router's navigator: Comic's theme, ground and text defaults.
///
/// ```dart
/// ComicHost(light: ComicThemeData.offset(), child: page)
/// ```
class ComicHost extends StatelessWidget {
  /// Creates a [ComicHost].
  const ComicHost({
    super.key,
    this.light,
    this.dark,
    this.brightness,
    required this.child,
  });

  /// [light]: the theme for the light appearance. [dark]: the theme or flag for the dark appearance.
  final ComicThemeData? light, dark;

  /// The requested light or dark appearance.
  final Brightness? brightness;

  /// Content placed inside this widget.
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final wanted =
        brightness ??
        PreviewFrame.maybeOf(context)?.brightness ??
        MediaQuery.platformBrightnessOf(context);
    final theme =
        (wanted == Brightness.dark ? dark : light) ??
        ComicTheme.preset(ComicThemeData.presets.first, wanted);
    // Day to night (and one preset to another) moves: every colour of the page lerps to the new palette.
    return AnimatedComicTheme(
      data: theme,
      duration: ComicMotion.of(context).raise,
      curve: comicStateCurve,
      child: Builder(
        builder: (context) {
          final t = ComicTheme.of(context);
          return ColoredBox(
            color: t.colors.background,
            child: DefaultTextStyle(
              style: t.type.body,
              child: IconTheme(
                data: IconThemeData(color: t.colors.text, size: 22),
                child: child,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// The router's page for a route pushed off a root, on the theme's ground.
class ComicPage<T> extends Page<T> {
  /// Creates a page on Comic's page ground.
  const ComicPage({required this.child, super.key, super.name});

  /// Page content, kept by the navigator when the page updates.
  final Widget child;
  @override
  Route<T> createRoute(BuildContext context) {
    return MaterialPageRoute<T>(
      settings: this,
      builder: (context) {
        final current = ModalRoute.of(context)?.settings;
        final page = current is ComicPage<T> ? current : this;
        return ColoredBox(
          color: ComicTheme.of(context).colors.background,
          child: page.child,
        );
      },
    );
  }
}

/// The router's page for a sheet, raised on the root navigator over the shell: from a phone's foot, as a card in the
/// middle of a desktop. [drawer] stands it as tall as its content. The screen inside derives its close.
class ComicSheetPage<T> extends Page<T> {
  /// Creates a [ComicSheetPage].
  const ComicSheetPage({
    required this.child,
    this.drawer = false,
    this.fullScreen = false,
    super.key,
    super.name,
  });

  /// Content placed inside this widget.
  final Widget child;

  /// [drawer]: sizes the sheet to its content rather than the usual height. [fullScreen]: presents the sheet as a full-screen page.
  final bool drawer, fullScreen;
  @override
  Route<T> createRoute(BuildContext context) {
    final t = ComicTheme.of(context);
    // Read as it builds: a window that grows takes the sheet with it.
    double most(BuildContext sheetContext) =>
        MediaQuery.sizeOf(sheetContext).height * .9;
    Widget current(BuildContext sheetContext) {
      final page = ModalRoute.of(sheetContext)?.settings;
      return page is ComicSheetPage ? page.child : child;
    }

    // A sheet on a desktop is a phone-wide panel, so its parts lay out as they do on a phone: one column, phone type.
    Widget card(BuildContext sheetContext) {
      final media = MediaQuery.of(sheetContext);
      return MediaQuery(
        data: media.copyWith(
          size: Size(
            media.size.width < 560 ? media.size.width : 560,
            media.size.height,
          ),
        ),
        child: ComicTheme(
          data: t,
          child: RoutePresentationScope(
            presentation: RoutePresentation.sheet,
            child: DecoratedBox(
              decoration: ShapeDecoration(
                color: t.colors.card,
                shape: t.shapes.large.copyWith(
                  side: BorderSide(color: t.colors.nightLine, width: t.rim(3)),
                ),
              ),
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
      return MaterialPageRoute<T>(
        settings: this,
        fullscreenDialog: true,
        builder: (sheetContext) => RoutePresentationScope(
          presentation: RoutePresentation.sheet,
          child: ColoredBox(
            color: t.colors.background,
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
        barrierColor: const Color(0x8C000000),
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
      backgroundColor: const Color(0x00000000),
      modalBarrierColor: const Color(0x8C000000),
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
enum ComicPresentation {
  /// A navigation root.
  root,

  /// A page pushed above a root.
  pushed,

  /// A raised sheet.
  sheet,
}

/// One page's isolated preview: the same host, tab bar, route and sheet the app gives it live, without the router.
///
/// ```dart
/// ComicPreview(child: ComicScaffold(body: Text('Preview')))
/// ```
class ComicPreview extends StatelessWidget {
  /// Creates a [ComicPreview].
  const ComicPreview({
    super.key,
    required this.child,
    this.light,
    this.dark,
    this.presentation = ComicPresentation.root,
    this.tabs = const [],
    this.activeIndex = 0,
    this.action,
    this.brand,
    this.drawer = false,
    this.platform = PreviewPlatform.android,
    this.brightness = Brightness.light,
  });

  /// Content placed inside this widget.
  final Widget child;

  /// [light]: the theme for the light appearance. [dark]: the theme or flag for the dark appearance.
  final ComicThemeData? light, dark;

  /// Whether the preview is a root, pushed page or sheet.
  final ComicPresentation presentation;

  /// Destinations represented by the shell.
  final List<ComicTab> tabs;

  /// The active destination index.
  final int activeIndex;

  /// The optional action beside this content.
  final ShellAction? action;

  /// The application identity shown by its chrome.
  final String? brand;

  /// Sizes the sheet to its content rather than the usual height.
  final bool drawer;

  /// The platform simulated by the preview.
  final PreviewPlatform platform;

  /// The requested light or dark appearance.
  final Brightness brightness;
  @override
  Widget build(BuildContext context) {
    final nav = [
      for (final tab in tabs)
        ComicNavItem(
          label: tab.label,
          short: tab.label,
          icon: tab.icon,
          key: tab.key,
          onPressed: () {},
        ),
    ];
    Widget scoped(Widget page) => tabs.isEmpty
        ? page
        : ComicChromeScope(
            brand: _brand(brand),
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
        builder: (context, app) => ComicHost(
          light: light,
          dark: dark,
          brightness: brightness,
          child: app ?? const SizedBox.shrink(),
        ),
        home: switch (presentation) {
          ComicPresentation.root => Builder(
            builder: (context) => tabs.isEmpty
                ? child
                : Column(
                    children: [
                      Expanded(child: scoped(child)),
                      if (!ComicTheme.of(context).desk)
                        ComicNavigationBar(
                          destinations: nav,
                          selectedIndex: activeIndex,
                          action: action,
                        ),
                    ],
                  ),
          ),
          ComicPresentation.pushed => PreviewStage(
            route: (context, page) => ComicPage<void>(
              key: const ValueKey<String>('kapow-preview'),
              child: page,
            ).createRoute(context),
            child: scoped(child),
          ),
          ComicPresentation.sheet => PreviewStage(
            route: (context, page) => ComicSheetPage<void>(
              key: const ValueKey<String>('kapow-preview'),
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

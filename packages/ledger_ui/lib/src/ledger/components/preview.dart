import 'package:material_ui/material_ui.dart'
    show Material, MaterialApp, MaterialType;
import 'package:flutter/widgets.dart';
import 'package:ui_core/host.dart';

import '../chrome_metrics.dart';
import '../internal/side_inset.dart';
import '../theme.dart';
import 'host.dart';
import 'nav_bar.dart';
import 'routes.dart';
import 'sheet_page.dart';
import 'side_bar.dart';
import 'top_bar.dart';

export 'package:ui_core/host.dart' show PreviewPlatform, RoutePresentation;
export 'package:ui_core/host.dart' show PreviewDevice, PreviewPlatformDevice;

/// How a previewed page stands in the app: as a nav root over the shell's
/// bar, pushed off one, or raised as a page sheet.
enum LedgerPresentation {
  /// A nav root, over the shell's bar.
  root,

  /// Pushed off a root, with the way back.
  pushed,

  /// Raised as a page sheet, with the close.
  sheet,
}

/// One page's isolated preview: the same host, bar, route and sheet the app
/// gives the page live, without the router, so preview pixels match in-app
/// pixels and the chrome the route derives is the real one: the way back
/// when pushed, the close on a sheet. A pushed or sheet page is raised over
/// a blank stage so its exit renders as it does live; a preview is looked
/// at, not walked out of, so the exit leaves the page standing. A root
/// stands over the tab bar on a phone; at desktop width a root and a pushed
/// page stand beside the sidebar ([tabs], [activeIndex] its current), as
/// the shell stands every page there. Given the page's [location], the
/// sidebar marks the account's foot when the page is its profile.
///
/// The preview stands in a [PreviewFrame] of the [platform] register and
/// [brightness], so the page's behaviour follows that platform.
///
/// ```dart
/// LedgerPreview(presentation: LedgerPresentation.pushed, child: const AccountPage())
/// ```
class LedgerPreview extends StatelessWidget {
  /// A preview of [child], standing as [presentation] says.
  const LedgerPreview({
    required this.child,
    this.light,
    this.dark,
    this.presentation = LedgerPresentation.root,
    this.tabs = const <LedgerNavItem>[],
    this.activeIndex = 0,
    this.action,
    this.brand,
    this.drawer = false,
    this.fullScreen = false,
    this.back = false,
    this.platform = PreviewPlatform.android,
    this.brightness = Brightness.light,
    this.device = false,
    this.location,
    super.key,
  });

  /// The page previewed.
  final Widget child;

  /// The light and dark themes; null is the default preset's.
  final LedgerThemeData? light;

  /// The dark theme; null is the default preset's.
  final LedgerThemeData? dark;

  /// How the page stands in the app.
  final LedgerPresentation presentation;

  /// The shell's tabs when the page is a nav root: the bar renders with
  /// [activeIndex] selected; empty renders no bar.
  final List<LedgerNavItem> tabs;

  /// The index of the current tab.
  final int activeIndex;

  /// The shell's act, the disc in the bar's middle.
  final ShellAction? action;

  /// The app's name: the sidebar's wordmark at desktop width, and the
  /// phone bar's (the preview's app takes it as its title, which the bar's
  /// wordmark reads, as it reads the running app's).
  final String? brand;

  /// With [LedgerPresentation.sheet], as tall as its content.
  final bool drawer;

  /// With [LedgerPresentation.sheet], the full-screen cover.
  final bool fullScreen;

  /// With [LedgerPresentation.sheet], closing by the way back.
  final bool back;

  /// The platform register the page behaves in.
  final PreviewPlatform platform;

  /// The appearance the preview stands in.
  final Brightness brightness;

  /// Whether the preview draws on the register's own device box.
  final bool device;

  /// The page's path in the app ('/home/profile'): at desktop width the
  /// sidebar's foot is current when it is the account's profile
  /// ([LedgerAccount.profileLocation]), and nothing is current on its
  /// notifications ([LedgerAccount.notificationsLocation]), as the shell
  /// marks them live.
  final String? location;

  // The preview is a window of its own: a side bar or rail of the app it
  // stands in (a gallery's) never reaches over its page.
  @override
  Widget build(BuildContext context) =>
      LedgerSideInset(inset: 0, child: _frame(context));

  Widget _frame(BuildContext context) => PreviewFrame(
    platform: platform,
    brightness: brightness,
    device: device,
    child: MaterialApp(
      // A new presentation is a new stack: raise it afresh.
      key: ValueKey<Object>((presentation, drawer, fullScreen, back)),
      title: brand ?? '',
      debugShowCheckedModeBanner: false,
      builder: (context, app) => LedgerHost(
        light: light,
        dark: dark,
        brightness: brightness,
        child: app ?? const SizedBox.shrink(),
      ),
      home: switch (presentation) {
        LedgerPresentation.root => _Root(
          tabs: tabs,
          activeIndex: activeIndex,
          action: action,
          brand: brand,
          location: location,
          child: child,
        ),
        // The sidebar stands in the pushed page's own route, as the shell
        // stands it over the branch the page is pushed on: under a sheet
        // raised from the page, over the page.
        LedgerPresentation.pushed => PreviewStage(
          route: (context, page) => LedgerPage<void>(
            key: const ValueKey<String>('quire-preview'),
            child: page,
          ).createRoute(context),
          child: _Beside(
            tabs: tabs,
            activeIndex: activeIndex,
            action: action,
            brand: brand,
            location: location,
            child: child,
          ),
        ),
        LedgerPresentation.sheet => PreviewStage(
          route: (context, page) => LedgerSheetPage<void>(
            key: const ValueKey<String>('quire-preview'),
            drawer: drawer,
            fullScreen: fullScreen,
            back: back,
            child: page,
          ).createRoute(context),
          child: child,
        ),
      },
    ),
  );
}

/// A nav root as the shell stands it: over the tab bar on a phone, the page
/// reserving the bar's height; beside the sidebar at desktop width.
class _Root extends StatelessWidget {
  const _Root({
    required this.tabs,
    required this.activeIndex,
    required this.action,
    required this.brand,
    required this.location,
    required this.child,
  });

  final List<LedgerNavItem> tabs;
  final int activeIndex;
  final ShellAction? action;
  final String? brand;
  final String? location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (tabs.isEmpty) return child;
    final media =
        activeIndex < tabs.length &&
        tabs[activeIndex].ground == ChromeGround.media;
    if (LedgerLayout.isWide(context)) {
      return _Beside(
        tabs: tabs,
        activeIndex: activeIndex,
        action: action,
        brand: brand,
        location: location,
        child: child,
      );
    }
    final inset = MediaQuery.paddingOf(context).bottom;
    final bar = LedgerNavBar.bandIn(
      context,
      inset: inset,
      count: tabs.length,
      action: action != null,
    );
    final Widget bottom = LedgerNavBar(
      items: tabs,
      selectedIndex: activeIndex,
      action: action,
      // An isolated page cannot switch roots; the bar stays put.
      onDestinationSelected: (_) {},
    );
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        Positioned(
          left: 0,
          top: 0,
          right: 0,
          bottom: media ? bar : 0,
          child: MediaQuery.removePadding(
            context: context,
            removeBottom: media,
            child: ShellInsets(bottomInset: media ? 0 : bar, child: child),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Material(
            type: MaterialType.transparency,
            child: media ? LedgerMediaGround(child: bottom) : bottom,
          ),
        ),
      ],
    );
  }
}

/// A page beside the sidebar at desktop width, as the shell stands every
/// page there (a root, and a page pushed on its branch): the page laid out
/// right of it. On a phone, or with no [tabs], the page alone.
class _Beside extends StatelessWidget {
  const _Beside({
    required this.tabs,
    required this.activeIndex,
    required this.action,
    required this.brand,
    required this.location,
    required this.child,
  });

  final List<LedgerNavItem> tabs;
  final int activeIndex;
  final ShellAction? action;
  final String? brand;
  final String? location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (tabs.isEmpty || !LedgerLayout.isWide(context)) return child;
    final media =
        activeIndex < tabs.length &&
        tabs[activeIndex].ground == ChromeGround.media;
    final side = LedgerSideBar(
      items: tabs,
      // A page none of the destinations is (the notifications) lights none.
      selectedIndex: switch (location) {
        final at?
            when LedgerAccountScope.maybeOf(context)?.showsNotifications(at) ??
                false =>
          null,
        _ => activeIndex,
      },
      // An isolated page cannot switch roots; the sidebar stays put.
      onDestinationSelected: (_) {},
      action: action,
      brand: brand,
      profileSelected: switch (location) {
        final at? =>
          LedgerAccountScope.maybeOf(context)?.showsProfile(at) ?? false,
        null => false,
      },
      solid: media,
    );
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        LedgerSideInset(inset: LedgerChromeMetrics.sideWidth, child: child),
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: LedgerChromeMetrics.sideWidth,
          child: Material(
            type: MaterialType.transparency,
            child: media ? LedgerMediaGround(child: side) : side,
          ),
        ),
      ],
    );
  }
}

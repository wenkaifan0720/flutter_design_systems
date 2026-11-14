import 'package:material_ui/material_ui.dart'
    show Material, MaterialApp, MaterialType;
import 'package:flutter/widgets.dart';
import 'package:ui_core/host.dart';

import '../theme.dart';
import 'account.dart';
import 'beside.dart';
import 'host.dart';
import 'nav_bar.dart';
import 'nav_pane.dart';
import 'routes.dart';
import 'sheet_page.dart';
import 'shell_frame.dart';

export 'package:ui_core/host.dart' show PreviewPlatform, RoutePresentation;
export 'package:ui_core/host.dart' show PreviewDevice, PreviewPlatformDevice;

/// How a previewed page stands in the app: as a nav root over the shell's
/// bar, pushed off one, or raised as a page sheet.
enum Fluent2Presentation {
  /// A tab's root page.
  root,

  /// A page pushed over another.
  pushed,

  /// A page shown as a sheet.
  sheet,
}

/// One page's isolated preview: the same host, bar, route and sheet the
/// app gives the page live, without the router, so preview pixels match
/// in-app pixels and the chrome the route derives is the real one: the way
/// back when pushed, the dismiss on a sheet. A pushed or sheet page is
/// raised over a blank stage so its exit renders as it does live. A root
/// stands over the tab bar on a phone; at desktop width a root and a
/// pushed page stand on the content layer beside the nav pane ([tabs],
/// [selectedIndex] its current). Given the page's [location], the pane marks
/// the account's foot when the page is its profile.
///
/// The preview stands in a [PreviewFrame] of the [platform] register and
/// [brightness], so the page's behaviour follows that platform.
///
/// ```dart
/// Fluent2Preview(presentation: Fluent2Presentation.pushed, child: const FilePage())
/// ```
class Fluent2Preview extends StatelessWidget {
  /// A preview of [child] as a page of an app.
  const Fluent2Preview({
    required this.child,
    this.light,
    this.darkData,
    this.presentation = Fluent2Presentation.root,
    this.tabs = const <Fluent2NavItem>[],
    this.selectedIndex = 0,
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

  /// The page.
  final Widget child;

  /// The light and dark themes; null is the default preset's.
  final Fluent2ThemeData? light;

  /// The dark theme; null is the default preset's.
  final Fluent2ThemeData? darkData;

  /// How the page is reached: a tab's root, pushed, or a sheet.
  final Fluent2Presentation presentation;

  /// The shell's tabs when the page is a nav root; empty renders no bar.
  final List<Fluent2NavItem> tabs;

  /// The index of the current tab.
  final int selectedIndex;

  /// The shell's act.
  final ShellAction? action;

  /// The nav pane's name at desktop width.
  final String? brand;

  /// With [Fluent2Presentation.sheet], as tall as its content (the end
  /// drawer on the desktop).
  final bool drawer;

  /// With [Fluent2Presentation.sheet], the full-screen cover.
  final bool fullScreen;

  /// With [Fluent2Presentation.sheet], closing by the way back.
  final bool back;

  /// The platform register the preview stands in.
  final PreviewPlatform platform;

  /// The appearance the preview draws in.
  final Brightness brightness;

  /// Whether the preview draws on the register's own device box.
  final bool device;

  /// The page's path in the app ('/home/profile').
  final String? location;

  @override
  Widget build(BuildContext context) => PreviewFrame(
    platform: platform,
    brightness: brightness,
    device: device,
    child: MaterialApp(
      key: ValueKey<Object>((presentation, drawer, fullScreen, back)),
      debugShowCheckedModeBanner: false,
      // The page reads the way the app round the preview reads: the inner
      // app's own locale would otherwise set it left to right.
      builder: (inner, app) => Directionality(
        textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
        child: Fluent2Host(
          light: light,
          darkData: darkData,
          brightness: brightness,
          child: app ?? const SizedBox.shrink(),
        ),
      ),
      home: switch (presentation) {
        Fluent2Presentation.root => _Root(
          tabs: tabs,
          activeIndex: selectedIndex,
          action: action,
          brand: brand,
          location: location,
          child: child,
        ),
        Fluent2Presentation.pushed => PreviewStage(
          route: (context, page) => Fluent2Page<void>(
            key: const ValueKey<String>('fluent2-preview'),
            child: page,
          ).createRoute(context),
          child: _Beside(
            tabs: tabs,
            activeIndex: selectedIndex,
            action: action,
            brand: brand,
            location: location,
            child: child,
          ),
        ),
        Fluent2Presentation.sheet => PreviewStage(
          route: (context, page) => Fluent2SheetPage<void>(
            key: const ValueKey<String>('fluent2-preview'),
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

class _Root extends StatelessWidget {
  const _Root({
    required this.tabs,
    required this.activeIndex,
    required this.action,
    required this.brand,
    required this.location,
    required this.child,
  });

  final List<Fluent2NavItem> tabs;
  final int activeIndex;
  final ShellAction? action;
  final String? brand;
  final String? location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (tabs.isEmpty) return child;
    if (Fluent2Layout.isWide(context)) {
      return _Beside(
        tabs: tabs,
        activeIndex: activeIndex,
        action: action,
        brand: brand,
        location: location,
        child: child,
      );
    }
    final media =
        activeIndex < tabs.length &&
        tabs[activeIndex].ground == ChromeGround.media;
    final inset = MediaQuery.paddingOf(context).bottom;
    final bar = Fluent2ShellInsets.allowance(
      systemInset: inset,
      action: action != null,
    );
    final Widget bottom = Fluent2NavigationBar(
      items: tabs,
      selectedIndex: activeIndex,
      action: action,
      onDestinationSelected: (_) {},
      solid: media,
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
            child: media ? Fluent2MediaGround(child: bottom) : bottom,
          ),
        ),
      ],
    );
  }
}

class _Beside extends StatelessWidget {
  const _Beside({
    required this.tabs,
    required this.activeIndex,
    required this.action,
    required this.brand,
    required this.location,
    required this.child,
  });

  final List<Fluent2NavItem> tabs;
  final int activeIndex;
  final ShellAction? action;
  final String? brand;
  final String? location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (tabs.isEmpty || !Fluent2Layout.isWide(context)) return child;
    final media =
        activeIndex < tabs.length &&
        tabs[activeIndex].ground == ChromeGround.media;
    final account = Fluent2AccountScope.maybeOf(context);
    final at = location;
    final pane = Fluent2NavigationDrawer(
      items: tabs,
      selectedIndex: activeIndex,
      onDestinationSelected: (_) {},
      action: action,
      brand: brand,
      onToggle: () {},
      profileCurrent: at != null && (account?.showsProfile(at) ?? false),
      noneCurrent: at != null && (account?.showsNotifications(at) ?? false),
      solid: media,
    );
    return Fluent2Beside(
      pane: Material(
        type: MaterialType.transparency,
        child: media ? Fluent2MediaGround(child: pane) : pane,
      ),
      child: child,
    );
  }
}

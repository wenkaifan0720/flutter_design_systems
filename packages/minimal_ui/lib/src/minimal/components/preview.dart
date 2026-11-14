import 'package:material_ui/material_ui.dart';

import '../internal/rail_action.dart';
import '../localizations.dart';
import '../theme.dart';
import 'host.dart';
import 'nav_bar.dart';
import 'navigation.dart';
import 'sheet.dart';
import 'shell_frame.dart';
import '../ground.dart';

/// How a previewed page stands in the app: as a nav root over the shell's
/// bar, pushed off one, or raised as a sheet.
enum MinimalPresentation {
  /// A nav root over the shell's bar.
  root,

  /// Pushed off a root.
  pushed,

  /// Raised as a sheet.
  sheet,
}

/// One page's isolated preview: the same host, bar, route and card the app
/// gives the page live, without the router, so preview pixels match in-app
/// pixels. The route decides the page's chrome exactly as it does live: a
/// root leads with its title, a pushed page gets the back button and
/// breadcrumb, a sheet page stands in the card with its close.
///
/// A pushed or sheet page is raised over a stage, so it can pop and its
/// exit renders as it does live — but a preview is looked at, not walked
/// out of: the exit leaves the page standing, and nothing reveals the
/// stage. The stage is blank unless [under] names the page the sheet (or
/// the push) was raised from: that page then stands beneath as a nav root,
/// with [tabs] under it — a create sheet over the dimmed list it adds to.
///
/// The preview reads the way the tree around it does: right to left under
/// a right-to-left [Directionality], though its own app's locale is
/// English.
///
/// ```dart
/// MinimalPreview(light: MinimalThemeData.preset('standard', Brightness.light), dark: MinimalThemeData.preset('standard', Brightness.dark), tabs: tabs, child: const TodayPage())
/// ```
class MinimalPreview extends StatelessWidget {
  /// A preview of the page [child].
  const MinimalPreview({
    required this.light,
    required this.dark,
    required this.child,
    this.presentation = MinimalPresentation.root,
    this.tabs = const <MinimalNavItem>[],
    this.activeIndex = 0,
    this.action,
    this.brightness,
    this.under,
    super.key,
  });

  /// The theme in the light appearance.
  final MinimalThemeData light;

  /// The theme in the dark appearance.
  final MinimalThemeData dark;

  /// The page.
  final Widget child;

  /// How the page stands: a tab's root, pushed, or in a sheet.
  final MinimalPresentation presentation;

  /// The shell's tabs when the page is a nav root — the bar renders under
  /// it, [activeIndex] current; empty renders no bar.
  final List<MinimalNavItem> tabs;

  /// The current tab.
  final int activeIndex;

  /// The shell's create action.
  final MinimalShellAction? action;

  /// Pins the appearance; null follows the platform.
  final Brightness? brightness;

  /// The page a pushed or sheet [child] was raised from, standing beneath
  /// it as a nav root (with [tabs]); null stands it over a blank stage. A
  /// root presentation ignores it.
  final Widget? under;

  @override
  Widget build(BuildContext context) {
    // The app's locale sets the direction again under it (English reads
    // left to right), so the direction around the preview is carried in.
    final direction = Directionality.maybeOf(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        final host = MinimalHost(
          light: light,
          dark: dark,
          brightness: brightness,
          child: child ?? const SizedBox.shrink(),
        );
        return direction == null
            ? host
            : Directionality(textDirection: direction, child: host);
      },
      home: switch (presentation) {
        MinimalPresentation.root => _root(child),
        MinimalPresentation.pushed => _Presented(
          route: (_, page) => MaterialPageRoute<void>(builder: (_) => page),
          stage: _stage(),
          child: child,
        ),
        MinimalPresentation.sheet => _Presented(
          // As the live sheet page: the card centred over a wide window.
          route: (context, page) =>
              MinimalBottomSheet.centresAt(
                context.size?.width ?? MediaQuery.sizeOf(context).width,
              )
              ? MinimalBottomSheet.centredRoute<void>(
                  context: context,
                  builder: (_) => page,
                )
              : MinimalBottomSheet.pageRoute<void>(
                  context: context,
                  builder: (_) => page,
                ),
          stage: _stage(),
          child: child,
        ),
      },
    );
  }

  Widget _root(Widget page) =>
      _Root(tabs: tabs, activeIndex: activeIndex, action: action, child: page);

  /// What a raised page stands over: [under] as a nav root, or nothing.
  Widget _stage() {
    final under = this.under;
    return under == null ? const SizedBox.expand() : _root(under);
  }
}

/// A nav root as the shell stands it: the bar docked under the page, the
/// page reserving the bar's height; from [MinimalLayout.compact] of its
/// own box (where the shell rails its tabs too), the tabs in a rail at the
/// start edge and the page beside it.
class _Root extends StatelessWidget {
  const _Root({
    required this.tabs,
    required this.activeIndex,
    required this.action,
    required this.child,
  });

  final List<MinimalNavItem> tabs;
  final int activeIndex;
  final MinimalShellAction? action;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (tabs.isEmpty) return child;
    return LayoutBuilder(
      builder: (context, box) => box.maxWidth >= MinimalLayout.compact
          ? _railed(context)
          : _barred(context),
    );
  }

  /// The wide form, as the shell's: the rail at the start edge on the
  /// tab's ground, the page beside it at its whole height.
  Widget _railed(BuildContext context) {
    final action = this.action;
    final ground = activeIndex < tabs.length
        ? tabs[activeIndex].ground
        : MinimalGround.surface;
    const rail = MinimalNavigationRail.width;
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        PositionedDirectional(
          start: rail,
          top: 0,
          end: 0,
          bottom: 0,
          child: child,
        ),
        PositionedDirectional(
          start: 0,
          top: 0,
          bottom: 0,
          width: rail,
          child: MinimalGroundScope(
            ground: ground,
            child: Builder(
              builder: (context) => ColoredBox(
                color: context.minimalTheme.card,
                child: SafeArea(
                  left: false,
                  right: false,
                  child: MinimalNavigationRail(
                    destinations: tabs,
                    selectedIndex: activeIndex,
                    // An isolated page cannot switch roots; the rail stays.
                    onDestinationSelected: (_) {},
                    leading: action == null
                        ? null
                        : MinimalRailAction(action: action),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// The phone's form: the bar docked along the bottom edge.
  Widget _barred(BuildContext context) {
    final action = this.action;
    final bar = MinimalNavigationBar.heightIn(
      MediaQuery.paddingOf(context).bottom,
    );
    final ground = activeIndex < tabs.length
        ? tabs[activeIndex].ground
        : MinimalGround.surface;
    final media = ground == MinimalGround.media;
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
            child: MinimalShellInsets(
              allowance: media ? 0 : bar,
              child: media
                  ? MinimalGroundScope(ground: ground, child: child)
                  : child,
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: MinimalGroundScope(
            ground: ground,
            child: MinimalNavigationBar(
              items: tabs,
              selectedIndex: activeIndex,
              // An isolated page cannot switch roots; the bar stays put.
              onDestinationSelected: (_) {},
              action: action?.icon,
              actionLabel:
                  action?.label ?? MinimalLocalizations.of(context).create,
              actionAccent: action?.primary ?? false,
              actionKey: action?.key,
              onAction: action == null ? null : () => action.onPressed(context),
            ),
          ),
        ),
      ],
    );
  }
}

/// A stage that raises [child] on [route] over itself once it is on
/// screen, and keeps it raised.
class _Presented extends StatefulWidget {
  const _Presented({
    required this.route,
    required this.stage,
    required this.child,
  });

  final Route<void> Function(BuildContext context, Widget page) route;
  final Widget stage;
  final Widget child;

  @override
  State<_Presented> createState() => _PresentedState();
}

class _PresentedState extends State<_Presented> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _raise());
  }

  // The page refuses every pop that asks — its exit, a scrim tap, the system
  // back — so they leave it standing. A pop that takes it anyway (a drag
  // past the sheet's edge, a direct `Navigator.pop`) raises it again rather
  // than leaving the blank on screen.
  void _raise() {
    if (!mounted) return;
    final page = PopScope<void>(canPop: false, child: widget.child);
    Navigator.of(context).push(widget.route(context, page)).then((_) {
      _raise();
    });
  }

  @override
  Widget build(BuildContext context) => widget.stage;
}

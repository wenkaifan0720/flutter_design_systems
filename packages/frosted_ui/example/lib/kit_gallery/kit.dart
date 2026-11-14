/// Shared host for the Frosted gallery's demo screens and catalog specimens,
/// and the sample owner, tabs and accounts they show.
///
/// Every demo renders inside the environment a Frosted page gets live: a
/// MaterialApp under [FrostedHost], themed by the preset the lab applied
/// (theme.dart's [kitPreset]), with the appearance pinned explicitly because
/// the preview host ignores the shell's simulated platform brightness, and
/// the owner's account ([kitMaren]) above the navigator as an app mounts it.
///
/// Demos import ONLY the Frosted barrel, this file, Flutter and the packages
/// Frosted depends on.
library;

import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_host.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'theme.dart';

/// A demo screen: a scrolling nav root titled [title], with labelled
/// sections, one per variant or state. [footer] pins a widget under the
/// scroll (an action bar); [body] replaces the sections for demos that own
/// their layout.
Widget kitScreen({
  required Brightness brightness,
  required String title,
  List<Widget> sections = const [],
  Widget? body,
  Widget? footer,
}) {
  assert(body == null || sections.isEmpty, 'sections or body, not both');
  return _kitApp(
    brightness: brightness,
    home: FrostedScaffold(
      topBar: FrostedAppBar(title: title),
      footer: footer,
      body:
          body ??
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final section in sections) ...[
                section,
                const FrostedGap(FrostedSpacing.s24),
              ],
            ],
          ),
    ),
  );
}

/// A demo that is its own whole surface (a route stack): the themed app
/// around exactly the widget the demo builds.
Widget kitSurface({required Brightness brightness, required Widget child}) =>
    _kitApp(brightness: brightness, home: child);

/// The preset the gallery shows: [kitPreset], unless the package's example
/// app or a test picks another while it runs.
String kitShownPreset = kitPreset;

/// The themes the gallery shows, by appearance: the shown preset's, unless
/// the package's example app (its Customize panel) or a test gives its own.
FrostedThemeData Function(Brightness brightness)? kitShownTheme;

/// The reading direction the demos lay out in: each demo is its own app,
/// whose localizations would set left to right, so the package's example
/// app (its Customize panel, a link's `dir=rtl`) or a test sets it here.
TextDirection kitShownDirection = TextDirection.ltr;

/// The gallery's today: every calendar and picker rings this day, so the
/// pages and the pictures agree whatever day they are opened on.
final DateTime kitToday = DateTime(2026, 11, 10);

/// Builds the observers each demo's navigator reports to: the package's
/// example gallery dims and softens its own bar under a demo's dialog or
/// sheet, as an app's whole window is. Null reports to none.
List<NavigatorObserver> Function()? kitNavigatorObservers;

/// The shown light and dark themes, for every demo and for demos that mount
/// their own host (a [FrostedPreview]).
FrostedThemeData kitTheme(Brightness brightness) =>
    kitShownTheme?.call(brightness) ??
    FrostedThemeData.preset(kitShownPreset, brightness);

Widget _kitApp({required Brightness brightness, required Widget home}) =>
    MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Frosted',
      navigatorObservers:
          kitNavigatorObservers?.call() ?? const <NavigatorObserver>[],
      builder: (context, child) => Directionality(
        textDirection: kitShownDirection,
        child: FrostedHost(
          light: kitTheme(Brightness.light),
          dark: kitTheme(Brightness.dark),
          brightness: brightness,
          child: FrostedAccountScope(
            account: kitMaren,
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ),
      home: home,
    );

/// One labelled variant band inside a demo screen.
Widget kitSection(String label, {required List<Widget> children}) => Builder(
  builder: (context) {
    final t = context.frostedTheme;
    // Keyed by its label, so a test finds each section (and its golden).
    return RepaintBoundary(
      key: ValueKey('kit-section/$label'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: t.textTheme.labelMedium),
          const FrostedGap(FrostedSpacing.s12),
          for (final child in children) ...[
            child,
            const FrostedGap(FrostedSpacing.s12),
          ],
        ],
      ),
    );
  },
);

/// A row of demo children that wraps instead of overflowing the phone.
Widget kitRow(List<Widget> children) => Wrap(
  spacing: FrostedSpacing.s12,
  runSpacing: FrostedSpacing.s12,
  crossAxisAlignment: WrapCrossAlignment.center,
  children: children,
);

/// A demo that is its own routed app (a shell over a go_router): the themed
/// app around [router], the owner's account above it.
Widget kitRouterApp({
  required Brightness brightness,
  required RouterConfig<Object> router,
}) => MaterialApp.router(
  debugShowCheckedModeBanner: false,
  title: 'Frosted',
  routerConfig: router,
  builder: (context, child) => Directionality(
    textDirection: kitShownDirection,
    child: FrostedHost(
      light: kitTheme(Brightness.light),
      dark: kitTheme(Brightness.dark),
      brightness: brightness,
      child: FrostedAccountScope(
        account: kitMaren,
        child: child ?? const SizedBox.shrink(),
      ),
    ),
  ),
);

/// [child] as a route of [register] draws it (a pushed page's bar, a sheet
/// page's head), for a still that stands on no route of its own.
Widget kitInRegister(RoutePresentation register, Widget child) =>
    RoutePresentationScope(presentation: register, child: child);

/// The sample's five root tabs, Move in the middle drawn as the ink pill (named
/// Move; the sidebar's ink button says its act, Move money, as the
/// source's does).
const List<FrostedNavItem> sampleTabs = [
  FrostedNavItem(LucideIcons.house, 'Home'),
  FrostedNavItem(LucideIcons.chartPie, 'Spending'),
  FrostedNavItem.action(
    LucideIcons.arrowLeftRight,
    'Move',
    actionLabel: 'Move money',
  ),
  FrostedNavItem(LucideIcons.target, 'Goals'),
  FrostedNavItem(LucideIcons.creditCard, 'Cards'),
];

/// The owner, as the pilot's chrome draws her. Her profile and notifications
/// are pages the gallery doesn't have, so they open nothing; they're still
/// given, as an app gives them, so the avatar and the bell draw live.
const kitMaren = FrostedAccount(
  name: 'Maren Holt',
  initials: 'MH',
  meta: 'Profile and settings',
  unread: 1,
  onProfile: _openNothing,
  onNotifications: _openNothing,
);

void _openNothing(BuildContext context) {}

/// Where a catalog specimen sits on its stage (the specimen's `frame` in
/// metadata.yaml names the same band): the bottom or top edge, a band across
/// the middle, or the whole phone.
class KitFrame {
  const KitFrame.bottom(double this.height) : _place = _KitPlace.bottom;
  const KitFrame.top(double this.height) : _place = _KitPlace.top;
  const KitFrame.band(double this.height) : _place = _KitPlace.band;
  const KitFrame.screen() : height = null, _place = _KitPlace.screen;

  /// The band's height in logical px; null for the whole phone.
  final double? height;
  final _KitPlace _place;
}

enum _KitPlace { bottom, top, band, screen }

/// The stage a catalog specimen renders on: the host themed by [style] (a
/// preset resolved at runtime, so one compile draws every preset) in
/// [brightness], on the page ground, the owner's account above it, with
/// [child] placed by [frame]. A specimen builder never names a style: the
/// stage decides it.
Widget kitSpecimenStage({
  required String style,
  required Brightness brightness,
  required KitFrame frame,
  required Widget child,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  title: 'Frosted',
  builder: (context, home) => Directionality(
    textDirection: kitShownDirection,
    child: FrostedHost(
      light: FrostedThemeData.preset(style, Brightness.light),
      dark: FrostedThemeData.preset(style, Brightness.dark),
      brightness: brightness,
      child: FrostedAccountScope(
        account: kitMaren,
        child: home ?? const SizedBox.shrink(),
      ),
    ),
  ),
  home: _KitStage(frame: frame, child: child),
);

class _KitStage extends StatelessWidget {
  const _KitStage({required this.frame, required this.child});

  final KitFrame frame;
  final Widget child;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: context.frostedTheme.colorScheme.background,
    child: switch (frame._place) {
      _KitPlace.bottom => Stack(
        fit: StackFit.expand,
        children: [Positioned(left: 0, right: 0, bottom: 0, child: child)],
      ),
      _KitPlace.top => Stack(
        fit: StackFit.expand,
        children: [Positioned(left: 0, right: 0, top: 0, child: child)],
      ),
      // A band sits on the page's own gutter, as it would in a body.
      _KitPlace.band => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: FrostedChromeMetrics.gutter,
          ),
          child: child,
        ),
      ),
      _KitPlace.screen => child,
    },
  );
}

/// A value the demo page owns: [builder] draws the part with it and a
/// setter, as a page holding the state would.
class KitHeld<T> extends StatefulWidget {
  const KitHeld(this.initial, this.builder, {super.key});

  final T initial;
  final Widget Function(T value, ValueChanged<T> set) builder;

  @override
  State<KitHeld<T>> createState() => _KitHeldState<T>();
}

class _KitHeldState<T> extends State<KitHeld<T>> {
  late T _value = widget.initial;

  @override
  Widget build(BuildContext context) =>
      widget.builder(_value, (v) => setState(() => _value = v));
}

/// A controller the demo owns while it shows (a table's rows, a tree's
/// open folders): [create] makes it once, [builder] draws the part with
/// it, and it is disposed with the demo.
class KitOwned<T extends ChangeNotifier> extends StatefulWidget {
  const KitOwned(this.create, this.builder, {super.key});

  final T Function() create;
  final Widget Function(T controller) builder;

  @override
  State<KitOwned<T>> createState() => _KitOwnedState<T>();
}

class _KitOwnedState<T extends ChangeNotifier> extends State<KitOwned<T>> {
  late final T _controller = widget.create();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(_controller);
}

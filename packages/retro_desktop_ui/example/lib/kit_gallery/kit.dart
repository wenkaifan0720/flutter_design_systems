/// Shared host for the Retro Desktop gallery's demo screens and catalog specimens.
///
/// Every demo renders inside the environment a Retro Desktop page gets live: a
/// MaterialApp under [RetroDesktopHost], themed by the preset the lab applied
/// (theme.dart's [kitPreset]), with the appearance pinned explicitly because
/// the preview host ignores the shell's simulated platform brightness.
///
/// Demos import ONLY the Retro Desktop barrel, this file, Flutter and the packages Retro Desktop
/// depends on.
library;

import 'package:flutter/material.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';
import 'package:retro_desktop_ui/retro_desktop_host.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'theme.dart';

/// Holds an example's controlled value without changing its initial specimen.
Widget kitValue<T>(T initial, Widget Function(T, ValueChanged<T>) builder) =>
    _KitValue<T>(initial: initial, builder: builder);

class _KitValue<T> extends StatefulWidget {
  const _KitValue({required this.initial, required this.builder});
  final T initial;
  final Widget Function(T, ValueChanged<T>) builder;
  @override
  State<_KitValue<T>> createState() => _KitValueState<T>();
}

class _KitValueState<T> extends State<_KitValue<T>> {
  late T value = widget.initial;
  @override
  Widget build(BuildContext context) =>
      widget.builder(value, (next) => setState(() => value = next));
}

/// Gives an action-only example visible completion feedback in its own theme.
Widget kitAction(String message, Widget Function(VoidCallback) builder) =>
    Builder(
      builder: (context) =>
          builder(() => showRetroDesktopSnackBar(context, message)),
    );

/// Lets a raised preview close and reopen without popping the gallery route.
Widget kitDismissible(String name, Widget Function(VoidCallback) builder) =>
    kitValue(
      true,
      (visible, change) => visible
          ? builder(() => change(false))
          : RetroDesktopButton('Show $name', onPressed: () => change(true)),
    );

/// A working popup example, with its menu anchored to the trigger.
Widget kitPopup(String initial, {IconData? icon}) => kitValue(
  initial,
  (value, change) => RetroDesktopMenuAnchor<String>(
    items: const [
      RetroDesktopMenuItem('Documents', 'Documents'),
      RetroDesktopMenuItem('Archive', 'Archive'),
    ],
    onSelected: change,
    builder: (context, open) =>
        RetroDesktopPopupButton(value, icon: icon, onPressed: open),
  ),
);

/// The sample tabs a chrome demo shows.
const kitTabs = [
  RetroDesktopNavItem(label: 'Today', short: 'Today', icon: LucideIcons.house),
  RetroDesktopNavItem(
    label: 'Places',
    short: 'Places',
    icon: LucideIcons.compass,
  ),
  RetroDesktopNavItem(label: 'You', short: 'You', icon: LucideIcons.user),
];

List<RetroDesktopNavItem> _kitPlaces(ValueChanged<int> change) => [
  for (final (index, item) in kitTabs.indexed)
    RetroDesktopNavItem(
      label: item.label,
      short: item.short,
      icon: item.icon,
      key: item.key,
      badgeLabel: item.badgeLabel,
      onPressed: () => change(index),
    ),
];

const _kitBrand = 'Retro Desktop';

/// A demo screen: a window titled [title] on a desktop, with labelled sections,
/// one per variant or state. [footer] pins a widget under the scroll.
/// [maxWindowWidth] centres one ordinary window instead of using the desktop tile grid.
/// [desk] stands the sections straight on the desktop ground, with no window
/// or grey round them: a page that is itself a desk of windows.
Widget kitScreen({
  required Brightness brightness,
  required String title,
  List<Widget> sections = const [],
  Widget? footer,
  bool bare = false,
  bool desk = false,
  double? maxWindowWidth,
}) => _kitApp(
  brightness: brightness,
  home: RetroDesktopScaffold(
    topBar: RetroDesktopAppBar(title: title),
    footer: footer,
    fullBleed: bare || desk || maxWindowWidth != null,
    body: desk
        ? _KitOnDesk(child: RetroDesktopSections(children: sections))
        : maxWindowWidth != null
        ? _KitBoundedWindow(
            title: title,
            width: maxWindowWidth,
            sections: sections,
          )
        : bare
        ? _KitBare(child: RetroDesktopSections(children: sections))
        : RetroDesktopSections(children: sections),
  ),
);

/// A screen that is a whole application: [home] draws its own menu bar, so
/// the gallery's sample bar of places stays out.
Widget kitAppScreen({required Brightness brightness, required Widget home}) =>
    MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Retro Desktop',
      builder: (context, child) => _kitDirected(
        RetroDesktopHost(
          light: kitTheme(Brightness.light),
          dark: kitTheme(Brightness.dark),
          brightness: brightness,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
      home: home,
    );

/// A screen whose [body] scrolls itself and fills what the bars leave.
Widget kitFilledScreen({
  required Brightness brightness,
  required String title,
  required Widget body,
}) => _kitApp(
  brightness: brightness,
  home: RetroDesktopScaffold(
    scroll: false,
    topBar: RetroDesktopAppBar(title: title),
    body: body,
  ),
);

// Ordinary examples share one horizontal centre and top inset on every screen.
class _KitBoundedWindow extends StatelessWidget {
  const _KitBoundedWindow({
    required this.title,
    required this.width,
    required this.sections,
  });
  final String title;
  final double width;
  final List<Widget> sections;
  @override
  Widget build(BuildContext context) => Padding(
    padding: RetroDesktopTheme.of(context).desk
        ? const EdgeInsets.all(24)
        : const EdgeInsets.fromLTRB(12, 12, 12, 20),
    child: Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width),
        child: RetroDesktopWindowScope(
          active: true,
          compact: true,
          child: RetroDesktopWindow(
            title: title,
            child: RetroDesktopSections(children: sections),
          ),
        ),
      ),
    ),
  );
}

/// The desktop's own margin round windows set straight on it.
class _KitOnDesk extends StatelessWidget {
  const _KitOnDesk({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.all(RetroDesktopTheme.of(context).desk ? 24 : 10),
    child: child,
  );
}

/// A window's grey with no window: a window inside a window is never the active
/// one, so the demo that shows an active window can't stand in one.
class _KitBare extends StatelessWidget {
  const _KitBare({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: context.retroDesktopTheme.colors.platinum,
    child: Padding(padding: const EdgeInsets.all(20), child: child),
  );
}

/// The selected preset and optional Customize theme builder.
String kitShownPreset = kitPreset;

/// Optional Customize-panel theme resolver.
RetroDesktopThemeData Function(Brightness)? kitShownTheme;

/// The reading direction the example shows its pages in; null keeps each
/// screen's own (its locale's).
TextDirection? kitShownDirection;

// A screen is an app of its own, and its Localizations sets its locale's
// direction: the example's choice is carried inside it.
Widget _kitDirected(Widget child) => kitShownDirection == null
    ? child
    : Directionality(textDirection: kitShownDirection!, child: child);

/// The preset's light and dark themes.
RetroDesktopThemeData kitTheme(Brightness brightness) =>
    kitShownTheme?.call(brightness) ??
    RetroDesktopThemeData.preset(kitShownPreset, brightness);

/// Whether a demo screen carries the sample menu bar (a brand and three
/// sample places). The example app turns it off: its own app bar and side
/// navigation are the chrome there, and a second bar of places that lead
/// nowhere would only confuse.
bool kitShownChrome = true;

Widget _kitApp({required Brightness brightness, required Widget home}) =>
    kitValue(
      0,
      (active, change) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Retro Desktop',
        builder: (context, child) => _kitDirected(
          RetroDesktopHost(
            light: kitTheme(Brightness.light),
            dark: kitTheme(Brightness.dark),
            brightness: brightness,
            child: kitShownChrome
                ? RetroDesktopChromeScope(
                    brand: _kitBrand,
                    nav: _kitPlaces(change),
                    active: active,
                    child: child ?? const SizedBox.shrink(),
                  )
                : child ?? const SizedBox.shrink(),
          ),
        ),
        home: home,
      ),
    );

/// One labelled variant band inside a demo screen.
Widget kitSection(String label, {required List<Widget> children}) =>
    RepaintBoundary(
      key: ValueKey('kit-section/$label'),
      child: Semantics(
        // Keep each named component demonstration in its own reading group.
        container: true,
        explicitChildNodes: true,
        child: RetroDesktopColumn(
          gap: 12,
          children: [RetroDesktopSectionHeader(label), ...children],
        ),
      ),
    );

/// A piece of the desk under a specimen that stands on one: a window, an alert,
/// the marks. A stage is a window's own grey, which a window can't stand out on.
class KitDesk extends StatelessWidget {
  /// Places [child] on the desktop ground.
  const KitDesk({super.key, required this.child});

  /// The demonstrated component.
  final Widget child;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: context.retroDesktopTheme.colors.desktop,
    child: Padding(padding: const EdgeInsets.all(12), child: child),
  );
}

/// Where a catalog specimen sits on its stage (the specimen's `frame` in
/// metadata.yaml names the same band): the bottom or top edge, a band across
/// the middle, or the whole phone.
class KitFrame {
  /// A band against the bottom of the viewport.
  const KitFrame.bottom(double this.height) : _place = _KitPlace.bottom;

  /// A band against the top of the viewport.
  const KitFrame.top(double this.height) : _place = _KitPlace.top;

  /// A vertically centered band.
  const KitFrame.band(double this.height) : _place = _KitPlace.band;

  /// The complete viewport.
  const KitFrame.screen() : height = null, _place = _KitPlace.screen;

  /// The band's height in logical px; null for the whole phone.
  final double? height;
  final _KitPlace _place;
}

enum _KitPlace { bottom, top, band, screen }

/// The stage a catalog specimen renders on: the host themed by [style] (a
/// preset resolved at runtime, so one compile draws every preset) in
/// [brightness], on the page's ground, with [child] placed by [frame]. A
/// specimen builder never names a style: the stage decides it.
Widget kitSpecimenStage({
  required String style,
  required Brightness brightness,
  required KitFrame frame,
  required Widget child,
}) => kitValue(
  0,
  (active, change) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Retro Desktop',
    builder: (context, home) => RetroDesktopHost(
      light: RetroDesktopThemeData.preset(style, Brightness.light),
      dark: RetroDesktopThemeData.preset(style, Brightness.dark),
      brightness: brightness,
      child: RetroDesktopChromeScope(
        brand: _kitBrand,
        nav: _kitPlaces(change),
        active: active,
        child: home ?? const SizedBox.shrink(),
      ),
    ),
    home: _KitStage(frame: frame, child: child),
  ),
);

class _KitStage extends StatelessWidget {
  const _KitStage({required this.frame, required this.child});

  final KitFrame frame;
  final Widget child;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: context.retroDesktopTheme.colors.platinum,
    child: switch (frame._place) {
      _KitPlace.bottom => Stack(
        fit: StackFit.expand,
        children: [Positioned(left: 0, right: 0, bottom: 0, child: child)],
      ),
      _KitPlace.top => Stack(
        fit: StackFit.expand,
        children: [Positioned(left: 0, right: 0, top: 0, child: child)],
      ),
      // A band sits in the page's own margins, as it would in a body.
      _KitPlace.band => Center(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: child,
        ),
      ),
      _KitPlace.screen => child,
    },
  );
}

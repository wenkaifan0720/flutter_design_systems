/// Shared host for the Comic gallery's demo screens and catalog specimens.
///
/// Every demo renders inside the environment a Comic page gets live: a
/// shared MaterialApp with each page under [ComicHost], themed by the preset the lab applied
/// (theme.dart's [kitPreset]), with the appearance pinned explicitly because
/// the preview host ignores the shell's simulated platform brightness.
///
/// Demos import ONLY the Comic barrel, this file, Flutter and the packages Comic
/// depends on.
library;

import 'package:flutter/material.dart';
import 'package:comic_ui/comic_ui.dart';
import 'package:comic_ui/comic_host.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'theme.dart';

/// The sample tabs a chrome demo shows.
const kitTabs = [
  ComicNavItem(label: 'Today', short: 'Today', icon: LucideIcons.house),
  ComicNavItem(label: 'Places', short: 'Places', icon: LucideIcons.compass),
  ComicNavItem(
    label: 'Figures',
    short: 'Figures',
    icon: LucideIcons.chartColumn,
  ),
  ComicNavItem(label: 'You', short: 'You', icon: LucideIcons.user),
];

const _kitBrand = ComicBrand(name: 'Your name');

/// A demo screen: a pushed page titled [title], with labelled sections, one per
/// variant or state. [footer] pins a widget under the scroll.
Widget kitScreen({
  required Brightness brightness,
  required String title,
  List<Widget> sections = const [],
  Widget? footer,
  bool showSampleNavigation = true,
}) => _kitApp(
  brightness: brightness,
  showSampleNavigation: showSampleNavigation,
  home: ComicScaffold(
    topBar: ComicAppBar(title: title),
    footer: footer,
    body: ComicSections(children: sections),
  ),
);

/// The preset the gallery shows, unless the example or a test chooses another.
String kitShownPreset = kitPreset;

/// A live theme override used by the example's Customize panel.
ComicThemeData Function(Brightness brightness)? kitShownTheme;

/// The shown preset and customization in either appearance.
ComicThemeData kitTheme(Brightness brightness) =>
    kitShownTheme?.call(brightness) ??
    ComicThemeData.preset(kitShownPreset, brightness);

/// Marks pages that share the example viewport's application and navigator.
/// The example's page picker replaces the catalog's fixed app destinations.
class KitGalleryScope extends InheritedWidget {
  /// Marks the embedded gallery [child].
  const KitGalleryScope({super.key, required super.child});

  /// Whether this page belongs to a shared gallery application.
  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<KitGalleryScope>() != null;

  @override
  bool updateShouldNotify(KitGalleryScope oldWidget) => false;
}

Widget _kitApp({
  required Brightness brightness,
  required Widget home,
  required bool showSampleNavigation,
}) => Builder(
  builder: (context) {
    final embedded = KitGalleryScope.of(context);
    Widget themed(Widget child) => ComicHost(
      light: kitTheme(Brightness.light),
      dark: kitTheme(Brightness.dark),
      brightness: brightness,
      child: showSampleNavigation && !embedded
          ? ComicChromeScope(
              brand: _kitBrand,
              nav: kitTabs,
              active: 0,
              child: child,
            )
          : child,
    );

    if (embedded) return themed(home);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Comic',
      builder: (context, child) => themed(child ?? const SizedBox.shrink()),
      home: home,
    );
  },
);

/// The demos' one today: every calendar, date picker and range picker in the gallery marks this day, so they agree
/// with each other and their pictures never change with the date they are taken.
final DateTime kitToday = DateTime(2026, 11, 6);

/// One labelled variant band inside a demo screen.
Widget kitSection(String label, {required List<Widget> children}) =>
    RepaintBoundary(
      key: ValueKey('kit-section/$label'),
      child: ComicColumn(gap: 12, children: [ComicLabel(label), ...children]),
    );

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
/// [brightness], on the page's ground, with [child] placed by [frame]. A
/// specimen builder never names a style: the stage decides it.
Widget kitSpecimenStage({
  required String style,
  required Brightness brightness,
  required KitFrame frame,
  required Widget child,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  title: 'Comic',
  builder: (context, home) => ComicHost(
    light: ComicTheme.preset(style, Brightness.light),
    dark: ComicTheme.preset(style, Brightness.dark),
    brightness: brightness,
    child: ComicChromeScope(
      brand: _kitBrand,
      nav: kitTabs,
      active: 0,
      child: home ?? const SizedBox.shrink(),
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
    color: context.comicTheme.colors.background,
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

/// Local state for a live specimen. Its initial value stays deterministic in
/// screenshots; every callback updates the mounted control rather than a dummy.
Widget kitState<T>(
  T initial,
  Widget Function(BuildContext, T, ValueChanged<T>) builder,
) => _KitState<T>(initial: initial, builder: builder);

class _KitState<T> extends StatefulWidget {
  const _KitState({required this.initial, required this.builder});
  final T initial;
  final Widget Function(BuildContext, T, ValueChanged<T>) builder;
  @override
  State<_KitState<T>> createState() => _KitStateValue<T>();
}

class _KitStateValue<T> extends State<_KitState<T>> {
  late T value = widget.initial;
  @override
  Widget build(BuildContext context) =>
      widget.builder(context, value, (next) => setState(() => value = next));
}

/// A visible response for an action whose destination is outside the gallery.
void kitFeedback(BuildContext context, String message) =>
    showComicSnackBar(context, message);

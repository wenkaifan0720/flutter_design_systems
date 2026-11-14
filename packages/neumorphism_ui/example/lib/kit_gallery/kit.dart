/// Shared host for the Neumorphism gallery's demo screens and catalog specimens.
///
/// Every demo renders inside the environment a Neumorphism page gets live: a
/// MaterialApp under [NeumorphicHost], themed by the preset the lab applied
/// (theme.dart's [kitPreset]), with the appearance pinned explicitly because
/// the preview host ignores the shell's simulated platform brightness.
///
/// Demos import ONLY the Neumorphism barrel, this file, Flutter and the packages Neumorphism
/// depends on.
library;

import 'package:flutter/material.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';
import 'package:neumorphism_ui/neumorphism_host.dart';

import 'theme.dart';

/// The sample tabs a chrome demo shows.
const kitTabs = [
  NeumorphicNavItem(
    label: 'Today',
    short: 'Today',
    icon: NeumorphicGlyphs.house,
  ),
  NeumorphicNavItem(
    label: 'Places',
    short: 'Places',
    icon: NeumorphicGlyphs.compass,
  ),
  NeumorphicNavItem(
    label: 'Figures',
    short: 'Figures',
    icon: NeumorphicGlyphs.chartColumn,
  ),
  NeumorphicNavItem(label: 'You', short: 'You', icon: NeumorphicGlyphs.user),
];

const _kitBrand = NeumorphicBrand(name: 'Your name');

/// A demo screen: a pushed page titled [title], with labelled sections, one per
/// variant or state. [footer] pins a widget under the scroll.
Widget kitScreen({
  required Brightness brightness,
  required String title,
  List<Widget> sections = const [],
  Widget? footer,
}) => _kitApp(
  brightness: brightness,
  home: NeumorphicScaffold(
    topBar: NeumorphicAppBar(title: title),
    footer: footer,
    body: NeumorphicSections(children: sections),
  ),
);

/// A demo screen whose [body] scrolls itself.
Widget kitScrollingScreen({
  required Brightness brightness,
  required String title,
  required Widget body,
}) => _kitApp(
  brightness: brightness,
  home: NeumorphicScaffold(
    topBar: NeumorphicAppBar(title: title),
    scroll: false,
    body: body,
  ),
);

/// A live specimen holding one value: [builder] gets it and its setter.
Widget kitValue<T>(
  T initial,
  Widget Function(BuildContext, T, ValueChanged<T>) builder,
) => _KitValue<T>(initial, builder);

class _KitValue<T> extends StatefulWidget {
  const _KitValue(this.initial, this.builder);
  final T initial;
  final Widget Function(BuildContext, T, ValueChanged<T>) builder;
  @override
  State<_KitValue<T>> createState() => _KitValueState<T>();
}

class _KitValueState<T> extends State<_KitValue<T>> {
  late T value = widget.initial;
  @override
  Widget build(BuildContext context) =>
      widget.builder(context, value, (next) => setState(() => value = next));
}

/// A live specimen that owns a controller: [create] makes it once, [builder] draws the part with it, and it is
/// disposed with the specimen.
Widget kitHeld<T extends ChangeNotifier>(
  T Function() create,
  Widget Function(BuildContext, T) builder,
) => _KitHeld<T>(create, builder);

class _KitHeld<T extends ChangeNotifier> extends StatefulWidget {
  const _KitHeld(this.create, this.builder);
  final T Function() create;
  final Widget Function(BuildContext, T) builder;
  @override
  State<_KitHeld<T>> createState() => _KitHeldState<T>();
}

class _KitHeldState<T extends ChangeNotifier> extends State<_KitHeld<T>> {
  late final T controller = widget.create();
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, controller);
}

/// The preset chosen in the package gallery, initially the catalog default.
String kitShownPreset = kitPreset;

/// Optional themes supplied by the Customize panel or its tests.
NeumorphicThemeData Function(Brightness brightness)? kitShownTheme;

/// The chosen light and dark themes.
NeumorphicThemeData kitTheme(Brightness brightness) =>
    kitShownTheme?.call(brightness) ??
    NeumorphicThemeData.preset(kitShownPreset, brightness);

Widget _kitApp({required Brightness brightness, required Widget home}) =>
    MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Neumorphism',
      builder: (context, child) => NeumorphicHost(
        light: kitTheme(Brightness.light),
        darkData: kitTheme(Brightness.dark),
        brightness: brightness,
        child: NeumorphicChromeScope(
          brand: _kitBrand,
          nav: kitTabs,
          active: 0,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
      home: home,
    );

/// One labelled variant band inside a demo screen.
Widget kitSection(String label, {required List<Widget> children}) =>
    RepaintBoundary(
      key: ValueKey('kit-section/$label'),
      // Titled as the gallery's own pages title a part: as a micro sub-head, the catalog's pages (tables, popovers,
      // button groups) read their section names as captions beside pages whose names were titles.
      child: NeumorphicColumn(
        gap: 14,
        children: [
          NeumorphicSectionHeader(title: label),
          ...children,
        ],
      ),
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
  title: 'Neumorphism',
  builder: (context, home) => NeumorphicHost(
    light: NeumorphicThemeData.preset(style, Brightness.light),
    darkData: NeumorphicThemeData.preset(style, Brightness.dark),
    brightness: brightness,
    child: NeumorphicChromeScope(
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
    color: context.neumorphicTheme.colors.ground,
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

// The screen already keeps the page's margin, so the list adds none beside it.
Widget kitLiveInventoryGallery() => const NeumorphicInventoryGallery(
  padding: EdgeInsets.only(top: 8, bottom: 32),
);

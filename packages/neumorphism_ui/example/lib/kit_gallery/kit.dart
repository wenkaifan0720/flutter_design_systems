/// Shared host for the Neumorphism gallery's demo screens and part specimens.
///
/// Every demo renders inside the environment a Neumorphism page gets live: a
/// MaterialApp under [NeumorphicHost], themed by the preset the lab applied
/// (theme.dart's [kitPreset]), with the appearance pinned explicitly because
/// the preview host ignores the shell's simulated platform brightness.
///
/// Demos import ONLY the Neumorphism barrel, this file, Flutter and the packages Neumorphism
/// depends on.
library;

import 'package:material_ui/material_ui.dart';
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

/// The preset chosen in the package gallery, initially the look's default.
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
      // Titled as the gallery's own pages title a part: as a micro sub-head, so no page's section names read as
      // captions beside pages whose names are titles.
      child: NeumorphicColumn(
        gap: 14,
        children: [
          NeumorphicSectionHeader(title: label),
          ...children,
        ],
      ),
    );

/// Where a specimen sits on its stage (the specimen's `frame` in
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

/// The room a specimen picture keeps round its specimen. A slab's light and shadow reach 34 px past its face (the
/// shadow's 12 px throw and its blur's visible tail), so a band's specimen stands 36 px off every edge of the picture
/// and no cast is cut flat by the picture's box, nor turns square behind a round corner.
const double kitCastRoom = 36;

/// The room a held part keeps: a dial or a house of rooms is lifted off the wall in the hand, and its shadow reaches
/// 8 px further than a slab's. Such a specimen stands this far off the picture's sides ([kitHeldCastRoom] less the band's
/// [kitCastRoom], added by the specimen).
const double kitHeldCastRoom = 44;

/// [child], a held part, with a held cast's room at a specimen picture's sides ([kitHeldCastRoom]); on a gallery page it
/// stands on the page's keyline as every part does.
Widget kitHeldPart(Widget child) => Builder(
  builder: (context) => Padding(
    padding: EdgeInsets.symmetric(
      horizontal: kitStageRoom(context) > 0 ? kitHeldCastRoom - kitCastRoom : 0,
    ),
    child: child,
  ),
);

/// The room the specimen stage round [context] keeps on each side of its band: [kitCastRoom] on a stage, none on a
/// gallery page. A specimen that is a screen of its own spans it, since a screen casts nothing.
double kitStageRoom(BuildContext context) =>
    context.dependOnInheritedWidgetOfExactType<_KitRoom>()?.room ?? 0;

class _KitRoom extends InheritedWidget {
  const _KitRoom({required this.room, required super.child});
  final double room;
  @override
  bool updateShouldNotify(_KitRoom old) => old.room != room;
}

/// The stage a specimen renders on: the host themed by [style] (a
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
      // A bar on the screen's foot or head: the picture's edge there is the screen's, and its other edge is left to
      // the bar's cast.
      _KitPlace.bottom => Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [Positioned(left: 0, right: 0, bottom: 0, child: child)],
      ),
      _KitPlace.top => Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [Positioned(left: 0, right: 0, top: 0, child: child)],
      ),
      // A band keeps a cast's room at its sides and clips nothing; its height (the specimen's frame in
      // metadata.yaml) leaves the same room above and below, so its specimen shows whole.
      _KitPlace.band => _KitRoom(
        room: kitCastRoom,
        child: Center(
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            clipBehavior: Clip.none,
            padding: const EdgeInsets.symmetric(horizontal: kitCastRoom),
            child: child,
          ),
        ),
      ),
      _KitPlace.screen => child,
    },
  );
}

/// The inventory in a window of the page, [height] tall. A list clips what it holds at its edges, so its window spans
/// a cast's room past the page's keyline on each side and the list keeps that room inside: the cards stand on the
/// page's keyline and their light and shadow show whole at the sides. Only the window's paint reaches past the
/// section; taps stay inside it. The last card keeps the same room above the window's foot.
Widget kitLiveInventoryGallery({double height = 640}) => SizedBox(
  height: height,
  child: LayoutBuilder(
    builder: (context, box) => OverflowBox(
      minWidth: box.maxWidth + 2 * kitCastRoom,
      maxWidth: box.maxWidth + 2 * kitCastRoom,
      child: const NeumorphicInventoryGallery(
        padding: EdgeInsets.fromLTRB(kitCastRoom, 8, kitCastRoom, kitCastRoom),
      ),
    ),
  ),
);

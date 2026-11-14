/// Shared helpers for the Expressive gallery's demo screens.
///
/// A demo is `Widget kit<Group>Demo(Brightness brightness)`: it is handed a
/// brightness and nothing else. Every demo renders inside the environment a
/// page gets — Expressive's host, themed by the preset in theme.dart (which
/// the lab rewrites when a preset is picked) — inside the design kit's
/// preview frame, in the register of the ambient platform ([kitPlatform]).
/// The smoke matrix's platform axis reaches a demo only that way (each
/// platform pass overrides `defaultTargetPlatform`), and it fails any frame
/// drawn in another register; the lab's platform toggle reaches demos the
/// same way.
///
/// Demos import only the Expressive barrel, Flutter's widgets or material
/// library, this file and, for a demo under a router, go_router and
/// kit_router.dart, so the gallery doubles as proof that the public surface
/// suffices to author with. This file takes no router: the package's
/// gallery carries it and leaves the router's demos with the host app.
///
/// WAVE 0 stand-ins, placed so that no two wave 1 items edit one file:
/// - `KitText` (kit_text.dart, imported here alone, never exported) is the
///   type this file's page chrome sets titles and labels in. w1-type
///   rewrites that file in place over the type scale, keeping its names, so
///   this file and the demos never change.
/// - `KitGlyphs` (kit_glyphs.dart, exported) stands in for Material Symbols.
///   The wave 1 item that bundles them rewrites that file in place, keeping
///   its names, so this file and the demos that use them never change.
/// - [kitGap] is the spacing scale's 8dp step (`ExpressiveSpacing.s8`),
///   w1-tokens' one edit to this file.
/// - [KitPage] frames every sectioned demo instead of `ExpressiveScaffold`:
///   it lays its sections out eagerly (see its doc) so the smoke matrix
///   checks every section, and it is gallery framing, not an app screen.
library;

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:material_expressive_ui/material_expressive_host.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

import 'kit_text.dart';
import 'theme.dart';

export 'kit_glyphs.dart';

/// The register of the ambient platform — the smoke matrix's platform under
/// test, or the device the gallery runs on — for a demo's preview frame. A
/// platform with no register of its own (a desktop, the web on one)
/// previews in the Android register, the lab's default. Read each time a
/// demo is built, never cached.
PreviewPlatform get kitPlatform => PreviewPlatform.values.firstWhere(
  (register) => register.targetPlatform == defaultTargetPlatform,
  orElse: () => PreviewPlatform.android,
);

/// The preset the demos are shown in: [kitPreset] unless the package's
/// gallery or a test picks another.
String kitShownPreset = kitPreset;

/// The shown preset's theme in [brightness], for a demo that mounts its
/// own host or preview.
ExpressiveThemeData Function(ExpressiveThemeData)? kitShownTheme;

final _kitPresetThemes = <(String, Brightness), ExpressiveThemeData>{};

/// Builds the shown theme and applies the package gallery's optional customization.
ExpressiveThemeData kitTheme(Brightness brightness) {
  final base = _kitPresetThemes.putIfAbsent((
    kitShownPreset,
    brightness,
  ), () => ExpressiveThemeData.preset(kitShownPreset, brightness));
  return kitShownTheme?.call(base) ?? base;
}

/// The demo page's meta line: the system and the shown preset
/// (`expressive · baseline`).
String get kitMeta => 'expressive · $kitShownPreset';

/// A demo that is its own whole page: [child] previewed alone, in the
/// ambient register and [brightness]. In the live example
/// ([KitLiveViewport]) the page sits under the example's own app bar, so
/// the register's drawn system bars stay off.
Widget kitSurface({required Brightness brightness, required Widget child}) =>
    Builder(
      builder: (context) => ExpressivePreview(
        platform: kitPlatform,
        brightness: brightness,
        light: kitTheme(Brightness.light),
        dark: kitTheme(Brightness.dark),
        systemBars: !KitLiveViewport.of(context),
        child: child,
      ),
    );

/// A demo screen: a scrolling [KitPage] titled [title], of labelled
/// [sections] (one per variant or state) or of one [body].
Widget kitScreen({
  required Brightness brightness,
  required String title,
  List<Widget> sections = const <Widget>[],
  List<Widget>? liveSections,
  Widget? body,
}) {
  assert(body == null || sections.isEmpty, 'sections or body, not both');
  return kitSurface(
    brightness: brightness,
    child: Builder(
      builder: (context) {
        final live = KitLiveViewport.of(context);
        final page = KitPage(
          key: ValueKey(title),
          title: title,
          children: body != null
              ? <Widget>[body]
              : live
              ? liveSections ?? sections
              : sections,
        );
        return live ? _KitPageTransition(child: page) : page;
      },
    ),
  );
}

/// Builds [KitPage] sections as they enter the live example's viewport.
/// Complete specimen sheets omit this scope to lay out every section for
/// captures and overflow checks.
class KitLiveViewport extends InheritedWidget {
  const KitLiveViewport({required super.child, super.key});

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<KitLiveViewport>() != null;

  @override
  bool updateShouldNotify(KitLiveViewport oldWidget) => false;
}

/// A titled specimen sheet without app chrome. By default a
/// [SingleChildScrollView] lays out every section eagerly, so the smoke matrix
/// checks the complete sheet. Under [KitLiveViewport], sections build lazily
/// and keep their state after scrolling out of view, and the heading gives
/// way to the example's app bar and tabs, which already name the page.
class KitPage extends StatelessWidget {
  const KitPage({required this.title, required this.children, super.key});

  /// The page's title.
  final String title;

  /// The page's content, top to bottom.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final allowance = ExpressiveShellInsets.of(context);
    const margin = ExpressiveChromeMetrics.margin;
    final padding = EdgeInsets.fromLTRB(
      margin,
      margin,
      margin,
      margin + allowance,
    );
    final heading = <Widget>[
      Text(
        title,
        style: KitText.title(context).copyWith(color: t.colors.onSurface),
      ),
      Text(kitMeta, style: TextStyle(color: t.colors.onSurfaceVariant)),
    ];
    if (KitLiveViewport.of(context)) {
      // On the start edge, where the example's app bar title and tabs
      // start: one edge down the window, not three.
      return SafeArea(
        bottom: allowance == 0,
        child: Align(
          alignment: AlignmentDirectional.topStart,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: ListView.builder(
              padding: padding,
              scrollCacheExtent: const ScrollCacheExtent.pixels(0),
              itemCount: children.length,
              itemBuilder: (context, index) => _KitPageItem(
                child: Padding(
                  padding: EdgeInsets.only(top: index == 0 ? 0 : margin),
                  child: children[index],
                ),
              ),
            ),
          ),
        ),
      );
    }
    return SafeArea(
      bottom: allowance == 0,
      child: SingleChildScrollView(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ...heading,
            for (final child in children) ...<Widget>[
              const SizedBox(height: margin),
              child,
            ],
          ],
        ),
      ),
    );
  }
}

// A control keeps its value when its section scrolls out of view and back.
class _KitPageItem extends StatefulWidget {
  const _KitPageItem({required this.child});

  final Widget child;

  @override
  State<_KitPageItem> createState() => _KitPageItemState();
}

class _KitPageItemState extends State<_KitPageItem>
    with AutomaticKeepAliveClientMixin<_KitPageItem> {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

// Reference navigation uses the native effects spring for its crossfade.
// Keep the outgoing page cached until it settles, so disposing its visited
// controls and laying out the next page do not compete in the same frame.
class _KitPageTransition extends StatefulWidget {
  const _KitPageTransition({required this.child});
  final Widget child;

  @override
  State<_KitPageTransition> createState() => _KitPageTransitionState();
}

class _KitPageTransitionState extends State<_KitPageTransition>
    with SingleTickerProviderStateMixin {
  late final _progress = AnimationController.unbounded(vsync: this, value: 1);
  Widget? _outgoing;
  var _serial = 0;

  @override
  void didUpdateWidget(_KitPageTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.child.key == oldWidget.child.key) return;
    final serial = ++_serial;
    _outgoing = oldWidget.child;
    _progress.value = 0;
    _progress
        .springTo(1, ExpressiveMotion.of(context).defaultEffects)
        .whenCompleteOrCancel(() {
          if (mounted && serial == _serial) {
            setState(() => _outgoing = null);
          }
        });
  }

  @override
  void dispose() {
    _serial++;
    _progress.dispose();
    super.dispose();
  }

  Widget _entry(Widget child, double opacity, {bool outgoing = false}) =>
      KeyedSubtree(
        key: child.key,
        child: IgnorePointer(
          ignoring: outgoing,
          child: ExcludeFocus(
            excluding: outgoing,
            child: ExcludeSemantics(
              excluding: outgoing,
              child: Opacity(
                opacity: opacity,
                child: RepaintBoundary(child: child),
              ),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _progress,
    builder: (context, _) {
      final alpha = _progress.value.clamp(0.0, 1.0);
      return Stack(
        fit: StackFit.expand,
        children: [
          if (_outgoing case final outgoing?)
            _entry(outgoing, 1 - alpha, outgoing: true),
          _entry(widget.child, _outgoing == null ? 1 : alpha),
        ],
      );
    },
  );
}

/// The breath between a section's lines: the spacing scale's 8dp step
/// (`space100`).
const double kitGap = ExpressiveSpacing.s8;

/// One labelled band inside a demo page: its label, then its children
/// [kitGap] apart.
///
/// The key lets a test find it, for its pixels and its semantics.
Widget kitSection(String label, {required List<Widget> children}) =>
    RepaintBoundary(
      key: ValueKey('kit-section/$label'),
      child: _section(label, children),
    );

Widget _section(String label, List<Widget> children) => Builder(
  builder: (context) {
    final t = context.expressiveTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          label,
          style: KitText.label(context).copyWith(color: t.colors.primary),
        ),
        for (final child in children) ...<Widget>[
          const SizedBox(height: kitGap),
          child,
        ],
      ],
    );
  },
);

/// A compact-width part (a navigation bar) as it stands on a phone: in a
/// window [ExpressiveSelect.wideFrom] or wider, [child] at a phone's width
/// (390) at its column's start, the foot of a phone's screen in an outline
/// of the large corner, the screen's [title] above the bar; on a phone, as
/// it is (its column is the phone).
Widget kitPhoneWidth({required Widget child, required String title}) => Builder(
  builder: (context) {
    if (MediaQuery.sizeOf(context).width < ExpressiveSelect.wideFrom) {
      return child;
    }
    final t = context.expressiveTheme;
    final shape = t.shapes.large;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: SizedBox(
        width: _kitPhoneWidth,
        child: ExpressiveSurface(
          shape: shape,
          color: t.colors.surface,
          // The phone's edge, drawn over the bar it holds (whose own
          // container would cover an edge drawn under it).
          child: DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: ShapeDecoration(
              // A frame between things, not a control's edge.
              shape: shape.copyWith(
                side: BorderSide(color: t.colors.outlineVariant),
              ),
            ),
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(
                size: Size(_kitPhoneWidth, MediaQuery.sizeOf(context).height),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // The screen the bar switches: its destination's name.
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      ExpressiveSpacing.s16,
                      ExpressiveSpacing.s24,
                      ExpressiveSpacing.s16,
                      ExpressiveSpacing.s48,
                    ),
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.type.titleLarge.copyWith(
                        color: t.colors.onSurface,
                      ),
                    ),
                  ),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  },
);

const double _kitPhoneWidth = 390;

/// What a wave-0 demo stands in for: the wave that builds its family or
/// foundation and the role-vocabulary ids it will cover (none for chrome
/// and the foundations).
Widget kitPlan({required int wave, List<String> roles = const <String>[]}) =>
    kitSection(
      'Built in wave $wave',
      children: <Widget>[
        Text(
          roles.isEmpty
              ? 'Fills no vocabulary role.'
              : 'Roles: ${roles.join(', ')}.',
        ),
      ],
    );

/// A tappable line in a demo page: [label] on the quiet container, running
/// [onTap]. Wave 0's stand-in until wave 3 builds the list row.
class KitAction extends StatelessWidget {
  const KitAction(this.label, {required this.onTap, super.key});

  /// What the line does.
  final String label;

  /// What a tap does.
  final VoidCallback onTap;

  // The look's own list row (its state layers, its target, its title on
  // the row's middle by its capitals), not a hand-built one.
  @override
  Widget build(BuildContext context) => ExpressiveListTile(
    title: Text(label),
    trailing: const Icon(ExpressiveSymbols.chevronRight),
    onTap: onTap,
  );
}

/// Where a catalog specimen sits on its stage — so also the part of the
/// phone the lab keeps of it (the specimen's `frame` in the module's
/// metadata.yaml names the same band): the bottom or top edge, a band
/// across the middle, or the whole phone.
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

/// The stage a catalog specimen renders on
/// (docs/architecture/component-catalog.md): the host themed by [style] —
/// a preset resolved at runtime, so one compile draws every preset — in
/// [brightness], in the Android register, on the page ground, with [child]
/// placed by [frame]. Edge chrome docks on its edge, so a bar lays out over
/// the real safe area.
///
/// A specimen builder never names a style: the stage decides it.
Widget kitSpecimenStage({
  required String style,
  required Brightness brightness,
  required KitFrame frame,
  required Widget child,
}) => Builder(
  builder: (outer) => PreviewFrame(
    brightness: brightness,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      // The stage reads in its page's direction, not its English locale's.
      builder: (context, home) => Directionality(
        textDirection: Directionality.maybeOf(outer) ?? TextDirection.ltr,
        child: ExpressiveHost(
          light: ExpressiveThemeData.preset(style, Brightness.light),
          dark: ExpressiveThemeData.preset(style, Brightness.dark),
          brightness: brightness,
          child: home ?? const SizedBox.shrink(),
        ),
      ),
      home: _KitStage(frame: frame, child: child),
    ),
  ),
);

class _KitStage extends StatelessWidget {
  const _KitStage({required this.frame, required this.child});

  final KitFrame frame;
  final Widget child;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: context.expressiveTheme.colors.surface,
    child: switch (frame._place) {
      _KitPlace.bottom => Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Positioned(left: 0, right: 0, bottom: 0, child: child),
        ],
      ),
      _KitPlace.top => Stack(
        fit: StackFit.expand,
        children: <Widget>[Positioned(left: 0, right: 0, top: 0, child: child)],
      ),
      // A band sits on the page's own margin, as it would in a body.
      _KitPlace.band => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: ExpressiveChromeMetrics.margin,
          ),
          child: child,
        ),
      ),
      _KitPlace.screen => child,
    },
  );
}

/// [child] under the look's host ([ExpressiveHost]): the gallery's light and
/// dark themes in [brightness], with the host's page transitions and ground.
Widget kitHost({required Brightness brightness, required Widget child}) =>
    ExpressiveHost(
      light: kitTheme(Brightness.light),
      dark: kitTheme(Brightness.dark),
      brightness: brightness,
      child: child,
    );

/// [child] as a route page with the platform's push and back
/// ([ExpressivePage]), keyed [key].
Page<void> kitRoutePage(LocalKey key, Widget child) =>
    ExpressivePage<void>(key: key, child: child);

/// Every row of the shared inventory, each its live class
/// ([ExpressiveInventoryGallery]).
Widget kitInventoryGallery() => const ExpressiveInventoryGallery();

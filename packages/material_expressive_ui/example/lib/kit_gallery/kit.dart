/// Shared page layout, typography and theme selection for the Expressive
/// gallery. Each demo takes a brightness and uses the current platform’s
/// preview frame.
library;

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart' show RenderProxyBox, ScrollCacheExtent;
import 'package:material_expressive_ui/material_expressive_host.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

import 'kit_focus.dart';
import 'kit_text.dart';
import 'theme.dart';

export 'kit_focus.dart';
export 'kit_glyphs.dart';

/// The Flutter `ThemeData` of the gallery's own apps: the look's push and pop
/// for Flutter's `MaterialPageRoute`, which reads this theme, not the look's.
final ThemeData kitAppTheme = ThemeData(
  pageTransitionsTheme: const PageTransitionsTheme(
    builders: expressivePageTransitions,
  ),
);

/// The preview frame for the current platform. Desktop platforms use the
/// Android frame.
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
        theme: kitTheme(Brightness.light),
        darkTheme: kitTheme(Brightness.dark),
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

/// A titled specimen sheet that builds all its sections in a [SingleChildScrollView].
/// Under [KitLiveViewport], sections build lazily, retain their state when
/// scrolled out of view, and use the example app bar for the page title.
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
      // start: one edge down the window, not three. Its own Tab: the page
      // stands in a preview, an app of its own (KitFocusActions).
      return KitFocusActions(
        child: SafeArea(
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

/// Where a camelCase name's next word starts: `cookie4|Sided`.
final RegExp _kitWordStart = RegExp('(?<=[a-z0-9])(?=[A-Z])');

/// [name] breakable only where its next word starts (a zero-width space
/// there): `surface|Container|Highest` wraps between its words in a narrow
/// cell or at large text, never inside one.
String kitWordBreaks(String name) => name.replaceAll(_kitWordStart, '​');

/// [name]'s words: `cookie4Sided` → `cookie4`, `Sided`.
List<String> kitWords(String name) => name.split(_kitWordStart);

/// Whether the reader's text is large (1.5× and up): a demo that sets words
/// side by side in narrow columns stacks them instead.
bool kitLargeText(BuildContext context) =>
    MediaQuery.textScalerOf(context).scale(kitBodySize) >= 1.5 * kitBodySize;

/// The body size [kitLargeText] scales.
const double kitBodySize = 16;

/// A cell [width] wide, or as wide as its longest word needs where that is
/// more (large text): a label in it breaks between its words, never inside
/// one. Never wider than its parent allows.
class KitWordCell extends SingleChildRenderObjectWidget {
  /// A cell at least [width] wide holding [child].
  const KitWordCell({required this.width, required super.child, super.key});

  /// The cell's width while its words fit.
  final double width;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderWordCell(width);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) =>
      (renderObject as _RenderWordCell).width = width;
}

class _RenderWordCell extends RenderProxyBox {
  _RenderWordCell(this._width);

  double _width;
  set width(double value) {
    if (value == _width) return;
    _width = value;
    markNeedsLayout();
  }

  BoxConstraints _inner(BoxConstraints c) {
    final words = child?.getMinIntrinsicWidth(double.infinity) ?? 0;
    final w = c.constrainWidth(words > _width ? words : _width);
    return c.copyWith(minWidth: w, maxWidth: w);
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    final words = child?.getMinIntrinsicWidth(height) ?? 0;
    return words > _width ? words : _width;
  }

  @override
  double computeMaxIntrinsicWidth(double height) =>
      computeMinIntrinsicWidth(height);

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      child?.getDryLayout(_inner(constraints)) ?? _inner(constraints).smallest;

  @override
  void performLayout() {
    final inner = _inner(constraints);
    final child = this.child;
    if (child == null) {
      size = inner.smallest;
      return;
    }
    child.layout(inner, parentUsesSize: true);
    size = child.size;
  }
}

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

/// A tappable line that displays [label] and invokes [onTap].
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

/// Placement of a gallery example within a phone-sized frame.
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

/// Renders [child] in the [style] preset at [brightness], positioned by
/// [frame]. Edge components use the frame’s safe area.
Widget kitSpecimenStage({
  required String style,
  required Brightness brightness,
  required KitFrame frame,
  required Widget child,
}) => Builder(
  builder: (outer) => PreviewFrame(
    brightness: brightness,
    // Its own screen to assistive technology: its first route's barrier hides
    // only what it paints, never the gallery around it.
    child: Semantics(
      container: true,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: kitAppTheme,
        // The stage reads in its page's direction, not its English locale's.
        builder: (context, home) => Directionality(
          textDirection: Directionality.maybeOf(outer) ?? TextDirection.ltr,
          child: ExpressiveHost(
            theme: ExpressiveThemeData.preset(style, Brightness.light),
            darkTheme: ExpressiveThemeData.preset(style, Brightness.dark),
            brightness: brightness,
            child: home ?? const SizedBox.shrink(),
          ),
        ),
        home: _KitStage(frame: frame, child: child),
      ),
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
      theme: kitTheme(Brightness.light),
      darkTheme: kitTheme(Brightness.dark),
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

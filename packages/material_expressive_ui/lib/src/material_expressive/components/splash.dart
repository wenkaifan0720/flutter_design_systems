/// The splash and its handoff: the app's mark on the theme's colours while
/// the app restores its session, then the mark morphing into the first
/// screen's anchor as the ground fades to show the page (the front doors'
/// threshold, docs/architecture/material-expressive-contract.md §3).
/// Owner: front-doors `sys`.
///
/// Not a Compose component: Android's splash screen hands its icon to the
/// app's first frame; an Expressive app's first Flutter frame is this
/// splash, so the handoff is the system's own. It is built from the
/// library: a shape mark is a library shape
/// ([ExpressiveMaterialShape.cookie9Sided] by default) that, while the app
/// restores, runs the loading indicator ([ExpressiveLoadingIndicator], its
/// own seven-shape sequence, unforked) at the large FAB's size; the handoff
/// is a morph ([ExpressivePolygonMorph], the library's shape matching) from the mark's shape
/// in its rectangle to the anchor's shape — a step of the corner scale or a
/// library shape — in the anchor's, on the theme's default spatial spring,
/// while the ground fades on the default effects spring; the anchor's own
/// widget then fades in over the morphed shape on the fast effects spring
/// and the overlay unmounts.
///
/// It never adds wait: a restore that ends before the first frame still
/// plays the handoff as the transition. No anchor within a few frames, a
/// custom mark with no [ExpressiveSplashScreenSource], or Reduce Motion: the
/// overlay cross-fades instead.
library;

import 'dart:ui' show lerpDouble;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../internal/shape/graphics/graphics.dart';
import '../internal/shape/library.dart';
import '../internal/tokens/fab_large_tokens.g.dart';
import '../internal/tokens/loading_indicator_tokens.g.dart';
import '../motion.dart';
import '../shape.dart';
import '../spacing.dart';
import '../strings.dart';
import '../theme.dart';
import 'loading.dart';

/// What the splash stands on.
enum ExpressiveSplashScreenGround {
  /// The page's `surface`, the mark in `primary`.
  surface,

  /// A full-bleed `primary`, the mark in `onPrimary`.
  primary,
}

/// Builds a custom mark; [restoring] is whether the app is still restoring
/// (run an indicator of the mark's own while it is).
typedef ExpressiveSplashScreenMarkBuilder = Widget Function(
  BuildContext context,
  bool restoring,
);

/// How many frames the handoff waits for the first screen's anchor before
/// it cross-fades instead.
const int _anchorFrames = 4;

/// The large FAB's container: the box a shape mark's indicator runs in.
const double _markBox = FabLargeTokens.containerHeight;

/// The shape at rest inside that box, as large as the indicator draws its
/// active shape (`activeSize` of `containerHeight`).
const double _markShape =
    _markBox *
    LoadingIndicatorTokens.activeSize /
    LoadingIndicatorTokens.containerHeight;

/// The app's mark on its splash ground: a library [shape] (the shape
/// constructor) or an app's own mark ([ExpressiveSplashScreenMark.custom]), with
/// an optional [wordmark] under it in `headlineMedium`.
///
/// Inside an [ExpressiveSplashScreen] it is the overlay's mark and follows the
/// host's restoring state; on its own (a splash route, a preview) it paints
/// its [ground] full-bleed and runs its indicator when [restoring].
///
/// ```dart
/// ExpressiveSplashScreenMark(wordmark: 'Steady', ground: ExpressiveSplashScreenGround.primary)
/// ```
class ExpressiveSplashScreenMark extends StatelessWidget {
  /// A library shape: the loading indicator's sequence while restoring.
  const ExpressiveSplashScreenMark({
    this.shape = ExpressiveMaterialShape.cookie9Sided,
    this.wordmark,
    this.ground = ExpressiveSplashScreenGround.surface,
    this.restoring = false,
    super.key,
  }) : builder = null;

  /// An app's own mark: [builder] draws it (and its own indicator while
  /// restoring). Wrap the piece that hands off in an
  /// [ExpressiveSplashScreenSource]; without one the handoff cross-fades.
  const ExpressiveSplashScreenMark.custom({
    required ExpressiveSplashScreenMarkBuilder this.builder,
    this.wordmark,
    this.ground = ExpressiveSplashScreenGround.surface,
    this.restoring = false,
    super.key,
  }) : shape = null;

  /// The library shape, or null for a custom mark.
  final ExpressiveMaterialShape? shape;

  /// A custom mark's builder, or null for a shape.
  final ExpressiveSplashScreenMarkBuilder? builder;

  /// The app's name under the mark.
  final String? wordmark;

  /// What the splash stands on.
  final ExpressiveSplashScreenGround ground;

  /// On its own: whether the mark runs its indicator. Inside an
  /// [ExpressiveSplashScreen] the host decides.
  final bool restoring;

  /// The ground's colour in [theme].
  Color groundColor(ExpressiveThemeData theme) => switch (ground) {
    ExpressiveSplashScreenGround.surface => theme.colors.surface,
    ExpressiveSplashScreenGround.primary => theme.colors.primary,
  };

  /// The mark's colour in [theme]: what a shape mark is drawn in.
  Color markColor(ExpressiveThemeData theme) => switch (ground) {
    ExpressiveSplashScreenGround.surface => theme.colors.primary,
    ExpressiveSplashScreenGround.primary => theme.colors.onPrimary,
  };

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final frame = _SplashFrame.maybeOf(context);
    final running = frame?.restoring ?? restoring;
    final ink = markColor(t);
    final shape = this.shape;
    final mark = shape == null
        ? builder!(context, running)
        : ExpressiveSplashScreenSource(
            shape: shape,
            color: ink,
            child: _ShapeMark(shape: shape, color: ink, running: running),
          );
    final onGround = switch (ground) {
      ExpressiveSplashScreenGround.surface => t.colors.onSurface,
      ExpressiveSplashScreenGround.primary => t.colors.onPrimary,
    };
    Widget content = Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          mark,
          if (wordmark != null) ...<Widget>[
            const SizedBox(height: ExpressiveSpacing.s24),
            Text(
              wordmark!,
              textAlign: TextAlign.center,
              style: t.type.headlineMedium.copyWith(color: onGround),
            ),
          ],
        ],
      ),
    );
    if (frame == null) {
      content = ColoredBox(color: groundColor(t), child: content);
    }
    return content;
  }
}

/// The shape mark: the library shape at rest, or the loading indicator's
/// sequence at the large FAB's size while restoring. Its box is the shape's
/// own, so the handoff starts from exactly what stands there.
class _ShapeMark extends StatelessWidget {
  const _ShapeMark({
    required this.shape,
    required this.color,
    required this.running,
  });

  final ExpressiveMaterialShape shape;
  final Color color;
  final bool running;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: _markShape,
    child: OverflowBox(
      maxWidth: _markBox,
      maxHeight: _markBox,
      child: SizedBox.square(
        dimension: _markBox,
        child: running
            ? FittedBox(child: ExpressiveLoadingIndicator(color: color))
            : Center(
                child: SizedBox.square(
                  dimension: _markShape,
                  child: DecoratedBox(
                    decoration: ShapeDecoration(
                      color: color,
                      shape: ExpressiveMaterialShapeBorder(shape),
                    ),
                  ),
                ),
              ),
      ),
    ),
  );
}

/// The piece of a mark that hands off: its box, in [shape] (a library
/// shape) or else the corner step [corner], filled with [color], morphs
/// into the first screen's anchor. A shape mark is its own source; a
/// custom mark wraps the piece that should become the anchor (Steady's big
/// block, Margin's front card) and the rest of it fades with the ground.
///
/// ```dart
/// ExpressiveSplashScreenSource(corner: ExpressiveCorner.extraLarge, color: t.colors.primaryContainer, child: bigBlock)
/// ```
class ExpressiveSplashScreenSource extends StatefulWidget {
  /// A splash source wrapping [child].
  const ExpressiveSplashScreenSource({
    required this.child,
    this.shape,
    this.corner = ExpressiveCorner.extraLarge,
    this.color,
    super.key,
  });

  /// What stands there before the handoff.
  final Widget child;

  /// A library shape, or null for [corner].
  final ExpressiveMaterialShape? shape;

  /// The corner step of the piece's shape when [shape] is null.
  final ExpressiveCorner corner;

  /// The piece's fill; `primary` when null.
  final Color? color;

  @override
  State<ExpressiveSplashScreenSource> createState() => _SplashSourceState();
}

class _SplashSourceState extends State<ExpressiveSplashScreenSource> {
  _ExpressiveSplashScreenState? _host;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final host = _SplashScope.maybeOf(context);
    if (host != _host) {
      _host?._sources.remove(this);
      _host = host;
      host?._sources.add(this);
    }
  }

  @override
  void dispose() {
    _host?._sources.remove(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The morph draws the piece while it hands off.
    final handingOff = _SplashScope.handingOff(context, this);
    return Opacity(opacity: handingOff ? 0 : 1, child: widget.child);
  }
}

/// Where the splash lands on the first screen: [child]'s box, in [shape]
/// (a library shape) or else the corner step [corner], filled with [color]
/// (the widget's own container colour: `primaryContainer` for a FAB,
/// `primary` for a filled button). The mark morphs into it, then [child]
/// fades in over it. Wrap one widget of the page the app opens on: a FAB
/// (the shell's action anchors itself: `ExpressiveShellAction(splashAnchor:
/// true)`), a button (`full`), a search bar, a tile.
/// Outside an [ExpressiveSplashScreen], or once it is gone, it is only [child].
///
/// ```dart
/// ExpressiveSplashScreenAnchor(corner: ExpressiveCorner.full, color: t.colors.primary, child: ExpressiveFilledButton('Measure now', onPressed: measure))
/// ```
class ExpressiveSplashScreenAnchor extends StatefulWidget {
  /// A splash anchor wrapping [child].
  const ExpressiveSplashScreenAnchor({
    required this.child,
    this.shape,
    this.corner = ExpressiveCorner.full,
    this.color,
    super.key,
  });

  /// The widget the splash becomes.
  final Widget child;

  /// A library shape, or null for [corner].
  final ExpressiveMaterialShape? shape;

  /// The corner step of [child]'s shape when [shape] is null.
  final ExpressiveCorner corner;

  /// [child]'s container colour; the mark's colour when null.
  final Color? color;

  @override
  State<ExpressiveSplashScreenAnchor> createState() => _SplashAnchorState();
}

class _SplashAnchorState extends State<ExpressiveSplashScreenAnchor> {
  _ExpressiveSplashScreenState? _host;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final host = _SplashScope.maybeOf(context);
    if (host != _host) {
      _host?._anchors.remove(this);
      _host = host;
      host?._anchors.add(this);
    }
  }

  @override
  void dispose() {
    _host?._anchors.remove(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final host = _SplashScope.maybeOf(context);
    final landing = host != null && _SplashScope.landsOn(context, this);
    // One structure always, so the child's state survives the handoff.
    return AnimatedBuilder(
      animation: landing ? host._reveal : kAlwaysCompleteAnimation,
      builder: (context, child) => Opacity(
        opacity: landing ? host._reveal.value.clamp(0.0, 1.0) : 1,
        child: child,
      ),
      child: widget.child,
    );
  }
}

/// The splash: an overlay above the app ([child], the router) that shows
/// [mark] on its ground while [restoring], then hands off into the first
/// screen's [ExpressiveSplashScreenAnchor] and unmounts.
///
/// Mount it in the `MaterialApp.router` builder, inside [ExpressiveHost]
/// (it reads the theme) and above the router's child, rebuilding when the
/// session changes; the router keeps its splash route while the session
/// restores (a plain ground: nothing on it is seen) and its guard
/// redirects when ready. [restoringLabel] is announced as a live region
/// while restoring (the strings' `loading` when null); nothing is, after.
///
/// ```dart
/// ExpressiveSplashScreen(restoring: session.isRestoring, restoringLabel: 'Restoring your session', mark: const ExpressiveSplashScreenMark(wordmark: 'Steady'), child: child!)
/// ```
class ExpressiveSplashScreen extends StatefulWidget {
  /// A splash showing [mark] while [restoring], over [child].
  const ExpressiveSplashScreen({
    required this.restoring,
    required this.mark,
    required this.child,
    this.restoringLabel,
    super.key,
  });

  /// Whether the app is still restoring; the handoff starts when it is not.
  final bool restoring;

  /// The mark and its ground.
  final ExpressiveSplashScreenMark mark;

  /// The app under the overlay: the router.
  final Widget child;

  /// What a screen reader hears while restoring.
  final String? restoringLabel;

  /// The overlay's key: gone once the handoff is over.
  static const Key overlayKey = ValueKey<String>('expressive-splash');

  @override
  State<ExpressiveSplashScreen> createState() => _ExpressiveSplashScreenState();
}

enum _Phase { mark, handoff, fade, done }

/// The handoff's geometry, fixed when it starts: the matched morph between
/// the two shapes, both centred on the origin at their own size, the
/// source's centre and colours; the anchor's centre is read as it paints,
/// so a page still settling into place is followed.
class _Handoff {
  _Handoff({
    required this.morph,
    required this.from,
    required this.target,
    required this.fromColor,
    required this.toColor,
  });

  final ExpressivePolygonMorph morph;
  final Offset from;
  final Offset Function() target;
  final Color fromColor;
  final Color toColor;
}

class _ExpressiveSplashScreenState extends State<ExpressiveSplashScreen>
    with TickerProviderStateMixin {
  final List<_SplashSourceState> _sources = <_SplashSourceState>[];
  final List<_SplashAnchorState> _anchors = <_SplashAnchorState>[];
  final GlobalKey _overlay = GlobalKey(debugLabel: 'expressive-splash');

  late final AnimationController _morph = AnimationController.unbounded(
    vsync: this,
  );
  late final AnimationController _ground = AnimationController.unbounded(
    vsync: this,
    value: 1,
  );
  late final AnimationController _reveal = AnimationController.unbounded(
    vsync: this,
  );

  _Phase _phase = _Phase.mark;
  _SplashSourceState? _source;
  _SplashAnchorState? _anchor;
  _Handoff? _handoff;
  bool _scheduled = false;
  int _waited = 0;

  @override
  void initState() {
    super.initState();
    if (!widget.restoring) _schedule();
  }

  @override
  void didUpdateWidget(ExpressiveSplashScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.restoring) _schedule();
  }

  @override
  void dispose() {
    _morph.dispose();
    _ground.dispose();
    _reveal.dispose();
    super.dispose();
  }

  void _schedule() {
    if (_scheduled || _phase != _Phase.mark) return;
    _scheduled = true;
    SchedulerBinding.instance
      ..addPostFrameCallback((_) => _tryHandoff())
      ..ensureVisualUpdate();
  }

  /// The anchor on the screen now showing: the latest one mounted on a
  /// current route with its ticker on (not an offstage tab), laid out.
  _SplashAnchorState? _liveAnchor() {
    for (final anchor in _anchors.reversed) {
      if (!anchor.mounted) continue;
      final context = anchor.context;
      if (!TickerMode.valuesOf(context).enabled) continue;
      if (!(ModalRoute.of(context)?.isCurrent ?? true)) continue;
      final box = context.findRenderObject();
      if (box is RenderBox && box.attached && box.hasSize) return anchor;
    }
    return null;
  }

  void _tryHandoff() {
    if (!mounted) return;
    if (widget.restoring) {
      _scheduled = false;
      return;
    }
    if (MediaQuery.disableAnimationsOf(context)) return _fade();
    final source = _sources.where((s) => s.mounted).lastOrNull;
    if (source == null) return _fade();
    final anchor = _liveAnchor();
    if (anchor != null) return _start(source, anchor);
    if (++_waited >= _anchorFrames) return _fade();
    SchedulerBinding.instance
      ..addPostFrameCallback((_) => _tryHandoff())
      ..scheduleFrame();
  }

  Rect? _rectOf(BuildContext context) {
    final overlay = _overlay.currentContext?.findRenderObject();
    final box = context.findRenderObject();
    if (overlay is! RenderBox || box is! RenderBox || !box.attached) {
      return null;
    }
    return MatrixUtils.transformRect(
      box.getTransformTo(overlay),
      Offset.zero & box.size,
    );
  }

  /// [shape] (else the theme's [corner] step) as a polygon of [size]
  /// centred on the origin.
  ExpressiveRoundedPolygon _polygon(
    ExpressiveMaterialShape? shape,
    ExpressiveCorner corner,
    Size size,
  ) {
    if (shape != null) {
      final unit = expressiveLibraryPolygon(shape);
      final b = unit.calculateBounds();
      final cx = (b[0] + b[2]) / 2;
      final cy = (b[1] + b[3]) / 2;
      return unit.transformed(
        (x, y) => ((x - cx) * size.width, (y - cy) * size.height),
      );
    }
    final r = context.expressiveTheme.shapes
        .corner(corner)
        .radiiOn(Offset.zero & size, Directionality.maybeOf(context));
    return ExpressiveRoundedPolygon.rectangle(
      width: size.width,
      height: size.height,
      // The rectangle's vertices run bottom-right, bottom-left, top-left,
      // top-right.
      perVertexRounding: <ExpressiveCornerRounding>[
        ExpressiveCornerRounding(radius: r.bottomRight.x),
        ExpressiveCornerRounding(radius: r.bottomLeft.x),
        ExpressiveCornerRounding(radius: r.topLeft.x),
        ExpressiveCornerRounding(radius: r.topRight.x),
      ],
    );
  }

  void _start(_SplashSourceState source, _SplashAnchorState anchor) {
    final from = _rectOf(source.context);
    final to = _rectOf(anchor.context);
    if (from == null || to == null || from.isEmpty || to.isEmpty) {
      return _fade();
    }
    final t = context.expressiveTheme;
    final fromColor = source.widget.color ?? t.colors.primary;
    var last = to.center;
    _handoff = _Handoff(
      morph: ExpressivePolygonMorph(
        _polygon(source.widget.shape, source.widget.corner, from.size),
        _polygon(anchor.widget.shape, anchor.widget.corner, to.size),
      ),
      from: from.center,
      target: () {
        final now = anchor.mounted ? _rectOf(anchor.context) : null;
        return last = now?.center ?? last;
      },
      fromColor: fromColor,
      toColor: anchor.widget.color ?? fromColor,
    );
    setState(() {
      _phase = _Phase.handoff;
      _source = source;
      _anchor = anchor;
    });
    final motion = ExpressiveMotion.of(context);
    _ground.springTo(0, motion.spring(ExpressiveMotionKey.defaultEffects));
    _morph.springTo(1, motion.spring(ExpressiveMotionKey.defaultSpatial)).then((
      _,
    ) {
      if (!mounted) return;
      _reveal
          .springTo(1, motion.spring(ExpressiveMotionKey.fastEffects))
          .then((_) => _finish());
    });
  }

  void _fade() {
    setState(() => _phase = _Phase.fade);
    _ground
        .springTo(
          0,
          ExpressiveMotion.of(context)
              .spring(ExpressiveMotionKey.defaultEffects),
        )
        .then((_) => _finish());
  }

  void _finish() {
    if (!mounted) return;
    setState(() {
      _phase = _Phase.done;
      _source = null;
      _anchor = null;
      _handoff = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final showing = _phase != _Phase.done;
    return _SplashScope(
      host: this,
      phase: _phase,
      source: _source,
      anchor: _anchor,
      child: Stack(
        fit: StackFit.passthrough,
        children: <Widget>[
          widget.child,
          if (showing)
            Positioned.fill(
              key: ExpressiveSplashScreen.overlayKey,
              child: _overlayOf(t),
            ),
        ],
      ),
    );
  }

  Widget _overlayOf(ExpressiveThemeData t) {
    final restoring = widget.restoring && _phase == _Phase.mark;
    Widget faded(Widget child) => AnimatedBuilder(
      animation: _ground,
      builder: (context, child) =>
          Opacity(opacity: _ground.value.clamp(0.0, 1.0), child: child),
      child: child,
    );
    Widget overlay = Stack(
      key: _overlay,
      fit: StackFit.expand,
      children: <Widget>[
        faded(ColoredBox(color: widget.mark.groundColor(t))),
        faded(_SplashFrame(restoring: restoring, child: widget.mark)),
        if (_handoff != null)
          CustomPaint(
            painter: _HandoffPainter(
              handoff: _handoff!,
              progress: _morph,
              reveal: _reveal,
            ),
          ),
      ],
    );
    if (_phase == _Phase.mark) {
      // The splash takes every touch while it stands; it announces the
      // restore and nothing else.
      overlay = Semantics(
        container: true,
        liveRegion: restoring,
        label: restoring
            ? widget.restoringLabel ??
                  ExpressiveLocalizations.of(context).loading
            : null,
        child: ExcludeSemantics(child: AbsorbPointer(child: overlay)),
      );
    } else {
      overlay = ExcludeSemantics(child: IgnorePointer(child: overlay));
    }
    return overlay;
  }
}

/// Paints the handoff: the morph at the spring's progress, moved from the
/// source's centre to the anchor's, its colour between theirs, fading out
/// as the anchor's own widget fades in.
class _HandoffPainter extends CustomPainter {
  _HandoffPainter({
    required this.handoff,
    required this.progress,
    required this.reveal,
  }) : super(repaint: Listenable.merge(<Listenable>[progress, reveal]));

  final _Handoff handoff;
  final Animation<double> progress;
  final Animation<double> reveal;

  final Path _path = Path();

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value;
    final to = handoff.target();
    handoff.morph.writePath(
      _path,
      t,
      dx: lerpDouble(handoff.from.dx, to.dx, t)!,
      dy: lerpDouble(handoff.from.dy, to.dy, t)!,
    );
    final color = Color.lerp(
      handoff.fromColor,
      handoff.toColor,
      t.clamp(0.0, 1.0),
    )!;
    final shown = 1 - reveal.value.clamp(0.0, 1.0);
    canvas.drawPath(
      _path,
      Paint()
        ..isAntiAlias = true
        ..color = color.withValues(alpha: color.a * shown),
    );
  }

  @override
  bool shouldRepaint(_HandoffPainter old) =>
      old.handoff != handoff ||
      old.progress != progress ||
      old.reveal != reveal;
}

/// Tells a mark inside the overlay the host's restoring state (and that it
/// stands on the host's ground).
class _SplashFrame extends InheritedWidget {
  const _SplashFrame({required this.restoring, required super.child});

  final bool restoring;

  static _SplashFrame? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SplashFrame>();

  @override
  bool updateShouldNotify(_SplashFrame oldWidget) =>
      restoring != oldWidget.restoring;
}

/// The host, for its sources and anchors to register with, and which of
/// them the handoff runs between.
class _SplashScope extends InheritedWidget {
  const _SplashScope({
    required this.host,
    required this.phase,
    required this.source,
    required this.anchor,
    required super.child,
  });

  final _ExpressiveSplashScreenState host;
  final _Phase phase;
  final _SplashSourceState? source;
  final _SplashAnchorState? anchor;

  static _ExpressiveSplashScreenState? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SplashScope>()?.host;

  static bool handingOff(BuildContext context, _SplashSourceState source) {
    final scope = context.dependOnInheritedWidgetOfExactType<_SplashScope>();
    return scope != null &&
        scope.phase == _Phase.handoff &&
        scope.source == source;
  }

  static bool landsOn(BuildContext context, _SplashAnchorState anchor) {
    final scope = context.dependOnInheritedWidgetOfExactType<_SplashScope>();
    return scope != null &&
        scope.phase == _Phase.handoff &&
        scope.anchor == anchor;
  }

  @override
  bool updateShouldNotify(_SplashScope oldWidget) =>
      host != oldWidget.host ||
      phase != oldWidget.phase ||
      source != oldWidget.source ||
      anchor != oldWidget.anchor;
}

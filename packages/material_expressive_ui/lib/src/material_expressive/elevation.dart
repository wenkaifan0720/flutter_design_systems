/// Expressive's elevation: [ExpressiveElevation], the six levels and the two
/// ways Compose shows them, and [ExpressiveSurface], Compose's `Surface`
/// (CONTRACT §2). Owner: w1-host, with `test/elevation_test.dart` and the
/// gallery's elevation demo.
///
/// Levels are [ExpressiveElevationLevel] (generated from `ElevationTokens`:
/// 0 · 1 · 3 · 6 · 8 · 12 dp); a component token names one symbolically
/// (`ElevatedButtonTokens.containerElevation`). Compose shows a level two
/// ways, and so does a surface here:
///
/// - **Tonal elevation**: a surface whose colour is the `surface` role is
///   tinted by `surfaceTint` at alpha (4.5 · ln(dp + 1) + 2) / 100
///   (`ColorScheme.surfaceColorAtElevation`; the constants are behaviour,
///   `HostBehavior`), accumulated through nested surfaces
///   (`LocalAbsoluteTonalElevation`). Any other colour is left alone: M3
///   Expressive paints most containers with the surface-container roles
///   instead, so the tint is rare.
/// - **Shadow elevation**: a shadow cast by the surface's shape in the
///   `shadow` role, drawn with Android's shadow model: HWUI's ambient +
///   spot shadows from a point light over the top centre of the window
///   ([ExpressiveShadowLight], [ExpressiveElevation.paintShadow]), not the
///   engine's `drawShadow` (a fixed directional light, spot alpha 0.25).
///   Only the few shadowed components use it (elevated buttons and cards,
///   FABs, menus, snackbars, the docked toolbar); a level animates between
///   states on a spring.
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'color.dart';
import 'component_themes.dart';
import 'internal/tokens/behavior.g.dart';
import 'internal/tokens/keys.g.dart';
import 'motion.dart';
import 'theme.dart';

export 'internal/tokens/keys.g.dart' show ExpressiveElevationLevel;

/// How a theme shows elevation: `context.expressiveTheme.elevation`.
@immutable
class ExpressiveElevation {
  /// An elevation drawn with the roles of [colors].
  const ExpressiveElevation(this.colors);

  /// The colour roles the tint and the shadow come from.
  final ExpressiveColorScheme colors;

  /// [level]'s height in dp.
  static double dpOf(ExpressiveElevationLevel level) => level.dp;

  /// The `surface` role tinted to [elevationDp] of tonal elevation
  /// (Compose's `ColorScheme.surfaceColorAtElevation`).
  Color surfaceAt(double elevationDp) {
    if (elevationDp <= 0) return colors.surface;
    final alpha =
        (HostBehavior.tonalElevationAlphaSlope * math.log(elevationDp + 1) +
            HostBehavior.tonalElevationAlphaIntercept) /
        100;
    return Color.alphaBlend(
      colors.surfaceTint.withValues(alpha: alpha),
      colors.surface,
    );
  }

  /// [background] at [elevationDp] of (absolute) tonal elevation: tinted
  /// when it is the `surface` role, else itself (Compose's
  /// `applyTonalElevation`).
  Color tonal(Color background, double elevationDp) =>
      background == colors.surface ? surfaceAt(elevationDp) : background;

  /// The colour shadows are cast in: the `shadow` role.
  Color get shadowColor => colors.shadow;

  /// Paints the shadow [path] casts at [elevationDp] of shadow elevation,
  /// lit by [light] (in the canvas's coordinates): HWUI's two layers, an
  /// ambient halo and a spot shadow projected from the light, in the
  /// `shadow` role at Android's alphas. Paint the caster over it.
  ///
  /// Without [light] the canvas is taken to sit at its current transform's
  /// offset in the implicit view (exact unless a layer boundary lies
  /// between the view and the canvas); a caller that knows its window
  /// position passes [ExpressiveShadowLight.overWindow] (as
  /// [ExpressiveSurface] does).
  ///
  /// The layers follow Skia's `SkShadowUtils` as HWUI calls it
  /// (`ReorderBarrierDrawables.cpp`) and Ganesh draws a round-rect caster
  /// (`GrShadowRRectOp`): the ambient is the shape outset by
  /// `z · ambientGeomFactor / ambientHeightDivisor` with a falloff that
  /// width times `1 + z_px / ambientHeightDivisor` wide; the spot is the
  /// shape projected from the light onto the ground (`p + r · (p − light)`,
  /// `r = z / (lightZ − z)`) with a penumbra `lightRadius · r` either side
  /// of its edge. Ganesh's falloff, `exp(−4(1 − t)²) − 0.018` across the
  /// band, is drawn as a Gaussian edge (a blurred, re-sized shape) fitted to
  /// it within 0.03 of its peak.
  ///
  /// Android never draws the shadow under the caster: HWUI casts with the
  /// outline's alpha, which a Compose surface leaves at 1 whatever its
  /// colour, and Skia skips the area an opaque occluder covers. An opaque
  /// fill painted over hides that area anyway; a caster whose fill is not
  /// opaque (a flat chip lifted on hover) passes [clipUnder], and the
  /// shadow stays outside its outline.
  void paintShadow(
    Canvas canvas,
    Path path,
    double elevationDp, {
    ExpressiveShadowLight? light,
    bool clipUnder = false,
  }) {
    if (elevationDp <= 0) return;
    final bounds = path.getBounds();
    if (bounds.isEmpty) return;
    if (clipUnder) {
      canvas
        ..save()
        ..clipPath(
          Path()
            ..fillType = PathFillType.evenOdd
            ..addRect(bounds.inflate(bounds.longestSide + 100 * elevationDp))
            ..addPath(path, Offset.zero),
        );
      paintShadow(canvas, path, elevationDp, light: light);
      canvas.restore();
      return;
    }
    final lit = light ?? ExpressiveShadowLight._fromCanvas(canvas, bounds);
    final z = elevationDp;
    final alpha = shadowColor.a * ExpressiveAndroidShadowModel.falloffPeak;

    // Ambient: SkDrawShadowMetrics::AmbientBlurRadius / AmbientRecipAlpha.
    final ambientOutset =
        z *
        ExpressiveAndroidShadowModel.ambientGeomFactor /
        ExpressiveAndroidShadowModel.ambientHeightDivisor;
    final ambientBand =
        ambientOutset *
        (1 +
            z *
                lit.devicePixelRatio /
                ExpressiveAndroidShadowModel.ambientHeightDivisor);
    _paintFalloff(
      canvas,
      path,
      bounds,
      grow:
          ambientOutset -
          ExpressiveAndroidShadowModel.falloffCentre * ambientBand,
      sigma: ExpressiveAndroidShadowModel.falloffSigma * ambientBand,
      color: shadowColor.withValues(
        alpha: alpha * ExpressiveAndroidShadowModel.ambientShadowAlpha,
      ),
    );

    // Spot: SkDrawShadowMetrics::GetSpotParams.
    final zRatio = (z / (lit.z - z)).clamp(
      0.0,
      ExpressiveAndroidShadowModel.maxSpotZRatio,
    );
    final scale = (lit.z / (lit.z - z)).clamp(
      1.0,
      ExpressiveAndroidShadowModel.maxSpotScale,
    );
    final penumbra = lit.radius * zRatio;
    final spot = path.transform(
      _scaleTranslate(
        scale,
        scale,
        -zRatio * lit.position.dx,
        -zRatio * lit.position.dy,
      ),
    );
    final band = penumbra * 2;
    _paintFalloff(
      canvas,
      spot,
      spot.getBounds(),
      grow: penumbra - ExpressiveAndroidShadowModel.falloffCentre * band,
      sigma: ExpressiveAndroidShadowModel.falloffSigma * band,
      color: shadowColor.withValues(
        alpha: alpha * ExpressiveAndroidShadowModel.spotShadowAlpha,
      ),
    );
  }

  /// Fills [path] grown by [grow] (about its centre) and blurred by
  /// [sigma]: a Gaussian edge centred [grow] outside the shape.
  static void _paintFalloff(
    Canvas canvas,
    Path path,
    Rect bounds, {
    required double grow,
    required double sigma,
    required Color color,
  }) {
    if (color.a <= 0) return;
    final sx = math.max(0.0, bounds.width + grow * 2) / bounds.width;
    final sy = math.max(0.0, bounds.height + grow * 2) / bounds.height;
    final centre = bounds.center;
    final grown = path.transform(
      _scaleTranslate(sx, sy, centre.dx * (1 - sx), centre.dy * (1 - sy)),
    );
    final paint = Paint()..color = color;
    if (sigma > 0) paint.maskFilter = MaskFilter.blur(BlurStyle.normal, sigma);
    canvas.drawPath(grown, paint);
  }

  static Float64List _scaleTranslate(
    double sx,
    double sy,
    double tx,
    double ty,
  ) => Float64List.fromList(<double>[
    sx, 0, 0, 0, //
    0, sy, 0, 0, //
    0, 0, 1, 0, //
    tx, ty, 0, 1, //
  ]);

  @override
  bool operator ==(Object other) =>
      other is ExpressiveElevation && other.colors == colors;

  @override
  int get hashCode => Object.hash(ExpressiveElevation, colors);
}

/// Android's shadow model, as the framework applies it on the oracle AVD
/// (`material_oracle`, android-36) and Skia draws it. The literal lint
/// excepts exactly these declarations (T `src/lint.ts`,
/// `LITERAL_EXCEPTIONS`): they are the platform's, not a design token.
abstract final class ExpressiveAndroidShadowModel {
  // frameworks/base core/res/res/values/dimens.xml, read from the AVD's
  // framework-res.apk (`aapt2 dump resources`); Theme.Material's
  // ambientShadowAlpha / spotShadowAlpha / lightY / lightZ / lightRadius
  // point at them.

  /// `@dimen/ambient_shadow_alpha`.
  static const double ambientShadowAlpha = 0.039;

  /// `@dimen/spot_shadow_alpha`.
  static const double spotShadowAlpha = 0.19;

  /// `@dimen/light_y`, dp above the window's top edge.
  static const double lightY = 0;

  /// `@dimen/light_z`, dp.
  static const double lightZ = 500;

  /// `@dimen/light_radius`, dp.
  static const double lightRadius = 800;

  // ThreadedRenderer.setLightCenter (framework.jar, `dexdump`): the light
  // sits at (displayWidth / 2 − windowLeft, lightY − windowTop) and its z
  // is lightZ · (min(displayW, displayH) / (450 dp) + 2) / 3.

  /// The display width (dp) at which lightZ is not rescaled.
  static const double lightZReferenceWidth = 450;

  /// The z rescale's weight: (ratio + weight) / (weight + 1).
  static const double lightZWeight = 2;

  // Skia SkDrawShadowMetrics.h (the model HWUI calls).

  /// `1 / kAmbientHeightFactor`.
  static const double ambientHeightDivisor = 128;

  /// `kAmbientGeomFactor`.
  static const double ambientGeomFactor = 64;

  /// GetSpotParams' pin on z / (lightZ − z).
  static const double maxSpotZRatio = 0.95;

  /// GetSpotParams' pin on lightZ / (lightZ − z).
  static const double maxSpotScale = 1.95;

  // Ganesh's shadow falloff (GrShadowRRectOp, SkGaussianColorFilter):
  // exp(−4(1 − t)²) − 0.018 across the band, t from its outer edge; its
  // Gaussian-edge fit 0.982 · Φ((t − 0.577) / 0.212), within 0.029.

  /// The falloff's full value, 1 − 0.018.
  static const double falloffPeak = 0.982;

  /// Where the fitted edge's midpoint sits, as a share of the band from
  /// its outer edge.
  static const double falloffCentre = 0.577;

  /// The fitted edge's sigma, as a share of the band.
  static const double falloffSigma = 0.212;
}

/// The light a shadow is cast from, in the painting canvas's coordinates
/// (logical pixels): HWUI's point light over the top centre of the window.
@immutable
class ExpressiveShadowLight {
  /// A light at [position] and height [z] with the given [radius], for a canvas at [devicePixelRatio].
  const ExpressiveShadowLight({
    required this.position,
    required this.z,
    required this.radius,
    this.devicePixelRatio = 1,
  });

  /// The light over a [window] of this size, for a canvas whose origin sits
  /// at [origin] in the window (Android's `ThreadedRenderer.setLightCenter`
  /// for a full-window surface: x at the centre, y at `lightY`, z scaled by
  /// the display's short side).
  factory ExpressiveShadowLight.overWindow(
    Size window, {
    Offset origin = Offset.zero,
    double devicePixelRatio = 1,
  }) {
    final ratio =
        window.shortestSide / ExpressiveAndroidShadowModel.lightZReferenceWidth;
    return ExpressiveShadowLight(
      position:
          Offset(window.width / 2, ExpressiveAndroidShadowModel.lightY) -
          origin,
      z:
          ExpressiveAndroidShadowModel.lightZ *
          (ratio + ExpressiveAndroidShadowModel.lightZWeight) /
          (ExpressiveAndroidShadowModel.lightZWeight + 1),
      radius: ExpressiveAndroidShadowModel.lightRadius,
      devicePixelRatio: devicePixelRatio,
    );
  }

  /// The light over the implicit view for a canvas at its transform's
  /// offset (the fallback for a painter that cannot place itself).
  factory ExpressiveShadowLight._fromCanvas(Canvas canvas, Rect bounds) {
    // Column-major: the translation is the last column's x and y.
    final transform = canvas.getTransform();
    final dx = transform[12];
    final dy = transform[13];
    final origin = Offset(dx, dy);
    final view = WidgetsBinding.instance.platformDispatcher.implicitView;
    if (view == null) {
      // No window: the light straight above the caster's centre.
      final side = bounds.center.dx + bounds.center.dx;
      return ExpressiveShadowLight.overWindow(Size(side, side));
    }
    return ExpressiveShadowLight.overWindow(
      view.physicalSize / view.devicePixelRatio,
      origin: origin,
      devicePixelRatio: view.devicePixelRatio,
    );
  }

  /// The light's position.
  final Offset position;

  /// Its height above the canvas.
  final double z;

  /// Its radius (the penumbra's source).
  final double radius;

  /// Device pixels per logical pixel (the ambient's width depends on the
  /// caster's height in device pixels).
  final double devicePixelRatio;

  @override
  bool operator ==(Object other) =>
      other is ExpressiveShadowLight &&
      other.position == position &&
      other.z == z &&
      other.radius == radius &&
      other.devicePixelRatio == devicePixelRatio;

  @override
  int get hashCode => Object.hash(position, z, radius, devicePixelRatio);
}

/// A surface's elevation by interaction state (Compose's `ButtonElevation`,
/// `FloatingActionButtonElevation`, `CardElevation`): the level at rest and,
/// where a component's tokens name one, while pressed, focused, hovered,
/// dragged or disabled. Precedence: disabled, then pressed, dragged,
/// focused, hovered, rest.
@immutable
class ExpressiveStateElevation {
  /// An elevation of [rest] that changes in the given states.
  const ExpressiveStateElevation({
    required this.rest,
    this.pressed,
    this.focused,
    this.hovered,
    this.dragged,
    this.disabled,
  });

  /// The same [level] in every state.
  const ExpressiveStateElevation.all(ExpressiveElevationLevel level)
    : rest = level,
      pressed = null,
      focused = null,
      hovered = null,
      dragged = null,
      disabled = null;

  /// No elevation at all.
  static const ExpressiveStateElevation none = ExpressiveStateElevation.all(
    ExpressiveElevationLevel.level0,
  );

  /// The level at rest.
  final ExpressiveElevationLevel rest;

  /// The level while pressed, or [rest] when null.
  final ExpressiveElevationLevel? pressed;

  /// The level while focused, or [rest] when null.
  final ExpressiveElevationLevel? focused;

  /// The level while hovered, or [rest] when null.
  final ExpressiveElevationLevel? hovered;

  /// The level while dragged, or [rest] when null.
  final ExpressiveElevationLevel? dragged;

  /// The level while disabled, or [rest] when null.
  final ExpressiveElevationLevel? disabled;

  /// The level for [states].
  ExpressiveElevationLevel resolve(Set<WidgetState> states) {
    if (states.contains(WidgetState.disabled)) return disabled ?? rest;
    if (states.contains(WidgetState.pressed) && pressed != null) {
      return pressed!;
    }
    if (states.contains(WidgetState.dragged) && dragged != null) {
      return dragged!;
    }
    if (states.contains(WidgetState.focused) && focused != null) {
      return focused!;
    }
    if (states.contains(WidgetState.hovered) && hovered != null) {
      return hovered!;
    }
    return rest;
  }

  @override
  bool operator ==(Object other) =>
      other is ExpressiveStateElevation &&
      other.rest == rest &&
      other.pressed == pressed &&
      other.focused == focused &&
      other.hovered == hovered &&
      other.dragged == dragged &&
      other.disabled == disabled;

  @override
  int get hashCode =>
      Object.hash(rest, pressed, focused, hovered, dragged, disabled);
}

/// Compose's `Surface`: [child] on a [shape] filled with [color] (tinted by
/// tonal elevation when it is the `surface` role), casting a shadow at
/// [shadowElevation], outlined by [side], clipping its content to the shape.
/// Content inherits [contentColor] (Compose's `LocalContentColor`) as its
/// text and icon colour.
///
/// A level change animates on [elevationMotion]'s spring; a shape or
/// colour is drawn as given (a pressable springs its shape itself).
class ExpressiveSurface extends StatelessWidget {
  /// A surface showing [child] on [shape] filled with [color].
  const ExpressiveSurface({
    required this.child,
    required this.shape,
    required this.color,
    this.contentColor,
    this.style,
    this.componentStyle,
    this.shapeDecorator,
    this.padding,
    this.states = const <WidgetState>{},
    this.side = BorderSide.none,
    this.tonalElevation = ExpressiveElevationLevel.level0,
    this.shadowElevation = ExpressiveElevationLevel.level0,
    this.elevationMotion = ExpressiveMotionKey.defaultEffects,
    this.clipBehavior = Clip.antiAlias,
    super.key,
  });

  /// Stateful overrides before the component's own defaults.
  final ExpressiveComponentThemeData? style;

  /// The enclosing component's visual defaults.
  final ExpressiveComponentThemeData? componentStyle;

  /// Adds geometry such as a tooltip caret to a supplied outline.
  final ShapeBorder Function(OutlinedBorder)? shapeDecorator;

  /// Default content padding, adjusted by density unless a style replaces it.
  final EdgeInsetsGeometry? padding;

  /// Interaction states owned by a component other than a pressable.
  final Set<WidgetState> states;

  /// What the surface holds.
  final Widget child;

  /// The surface's outline (a corner border from `shape.dart`, usually).
  final ShapeBorder shape;

  /// The fill: a colour role.
  final Color color;

  /// The colour content inherits; null leaves the ambient one.
  final Color? contentColor;

  /// The outline stroke, if any (outlined components).
  final BorderSide side;

  /// Tonal elevation, added to the enclosing surfaces'.
  final ExpressiveElevationLevel tonalElevation;

  /// Shadow elevation.
  final ExpressiveElevationLevel shadowElevation;

  /// The spring a change of [shadowElevation] runs on.
  final ExpressiveMotionKey elevationMotion;

  /// How content is clipped to [shape].
  final Clip clipBehavior;

  /// The absolute tonal elevation at [context], in dp: the sum of every
  /// enclosing surface's (Compose's `LocalAbsoluteTonalElevation`).
  static double absoluteTonalElevationOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<_AbsoluteTonalElevation>()
          ?.dp ??
      0;

  @override
  Widget build(BuildContext context) {
    final theme = context.expressiveTheme;
    final styled = (componentStyle ?? const ExpressiveComponentThemeData())
        .merge(style);
    final supplied = styled.shape?.resolve(states);
    final shape = supplied == null
        ? this.shape
        : shapeDecorator?.call(supplied) ?? supplied;
    final outline = styled.outline?.resolve(states);
    final side =
        styled.side?.resolve(states) ??
        this.side.copyWith(
          color: outline,
          style: outline == null ? null : BorderStyle.solid,
        );
    final color = Color.alphaBlend(
      styled.overlayColor?.resolve(states) ?? expressiveTransparent,
      styled.backgroundColor?.resolve(states) ?? this.color,
    );
    final contentColor =
        styled.foregroundColor?.resolve(states) ?? this.contentColor;
    final elevation = ExpressiveElevation(_colorsOf(context));
    final absolute = absoluteTonalElevationOf(context) + tonalElevation.dp;
    final fill = elevation.tonal(color, absolute);
    Widget content = child;
    final textStyle = styled.textStyle?.resolve(states);
    final iconSize = styled.iconSize?.resolve(states);
    if (textStyle != null) {
      content = DefaultTextStyle.merge(style: textStyle, child: content);
    }
    if (iconSize != null) {
      content = IconTheme.merge(
        data: IconThemeData(size: iconSize),
        child: content,
      );
    }
    final customPadding = styled.padding?.resolve(states);
    final insetShape =
        supplied ??
        (styled.side?.resolve(states) != null || outline != null
            ? (shape is OutlinedBorder ? shape : null)
            : null);
    if (padding != null || customPadding != null || insetShape != null) {
      final direction = Directionality.of(context);
      content = Padding(
        padding:
            (customPadding?.resolve(direction) ??
                _keylinePadding(
                  theme.density,
                  (padding ?? EdgeInsets.zero).resolve(direction),
                )) +
            (insetShape?.copyWith(side: side).dimensions.resolve(direction) ??
                EdgeInsets.zero),
        child: content,
      );
    }
    final minimum = styled.minimumSize?.resolve(states);
    if (minimum != null) {
      content = ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: minimum.width,
          minHeight: minimum.height,
        ),
        child: content,
      );
    }
    if (contentColor != null) {
      content = IconTheme.merge(
        data: IconThemeData(color: contentColor),
        child: DefaultTextStyle.merge(
          style: TextStyle(color: contentColor),
          child: content,
        ),
      );
    }
    return ExpressiveSpringValue(
      value: shadowElevation.dp,
      motion: elevationMotion,
      builder: (context, shadow, child) => _SurfacePaint(
        shape: shape,
        side: side,
        fill: fill,
        elevation: elevation,
        shadowDp: math.max(0, shadow),
        textDirection: Directionality.maybeOf(context),
        child: child,
      ),
      child: _AbsoluteTonalElevation(
        dp: absolute,
        child: clipBehavior == Clip.none
            ? content
            : ClipPath(
                clipper: ShapeBorderClipper(
                  shape: shape,
                  textDirection: Directionality.maybeOf(context),
                ),
                clipBehavior: clipBehavior,
                child: content,
              ),
      ),
    );
  }
}

ExpressiveColorScheme _colorsOf(BuildContext context) =>
    context.expressiveTheme.colors;

class _AbsoluteTonalElevation extends InheritedWidget {
  const _AbsoluteTonalElevation({required this.dp, required super.child});

  final double dp;

  @override
  bool updateShouldNotify(_AbsoluteTonalElevation oldWidget) =>
      dp != oldWidget.dp;
}

/// Paints the surface behind its child: the shadow (lit from the window
/// the surface sits in), the fill and the outline.
class _SurfacePaint extends SingleChildRenderObjectWidget {
  const _SurfacePaint({
    required this.shape,
    required this.side,
    required this.fill,
    required this.elevation,
    required this.shadowDp,
    required this.textDirection,
    super.child,
  });

  final ShapeBorder shape;
  final BorderSide side;
  final Color fill;
  final ExpressiveElevation elevation;
  final double shadowDp;
  final TextDirection? textDirection;

  @override
  _RenderSurface createRenderObject(BuildContext context) => _RenderSurface(
    shape: shape,
    side: side,
    fill: fill,
    elevation: elevation,
    shadowDp: shadowDp,
    textDirection: textDirection,
  );

  @override
  void updateRenderObject(BuildContext context, _RenderSurface renderObject) {
    renderObject
      ..shape = shape
      ..side = side
      ..fill = fill
      ..elevation = elevation
      ..shadowDp = shadowDp
      ..textDirection = textDirection;
  }
}

class _RenderSurface extends RenderProxyBox {
  _RenderSurface({
    required this._shape,
    required this._side,
    required this._fill,
    required this._elevation,
    required this._shadowDp,
    required this._textDirection,
  });

  ShapeBorder _shape;
  set shape(ShapeBorder value) {
    if (value == _shape) return;
    _shape = value;
    markNeedsPaint();
  }

  BorderSide _side;
  set side(BorderSide value) {
    if (value == _side) return;
    _side = value;
    markNeedsPaint();
  }

  Color _fill;
  set fill(Color value) {
    if (value == _fill) return;
    _fill = value;
    markNeedsPaint();
  }

  ExpressiveElevation _elevation;
  set elevation(ExpressiveElevation value) {
    if (value == _elevation) return;
    _elevation = value;
    markNeedsPaint();
  }

  double _shadowDp;
  set shadowDp(double value) {
    if (value == _shadowDp) return;
    _shadowDp = value;
    markNeedsPaint();
  }

  TextDirection? _textDirection;
  set textDirection(TextDirection? value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsPaint();
  }

  /// The light over this surface's view, in the coordinates of the canvas
  /// it paints at [offset] on; null outside a view.
  ExpressiveShadowLight? _light(Offset offset) {
    final root = owner?.rootNode;
    if (root is! RenderView) return null;
    return ExpressiveShadowLight.overWindow(
      root.size,
      origin: localToGlobal(Offset.zero) - offset,
      devicePixelRatio: root.configuration.devicePixelRatio,
    );
  }

  /// A surface takes the taps on its whole box, as the CustomPaint it
  /// replaced did and as Compose's non-clickable Surface does (it blocks
  /// touches with an empty `pointerInput`): a tap on its empty area never
  /// reaches what lies under it (a modal barrier, a menu's outside tap).
  @override
  bool hitTestSelf(Offset position) => true;

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    final rect = offset & size;
    final path = _shape.getOuterPath(rect, textDirection: _textDirection);
    if (_shadowDp > 0) {
      _elevation.paintShadow(
        canvas,
        path,
        _shadowDp,
        light: _light(offset),
        clipUnder: _fill.a < 1,
      );
    }
    canvas.drawPath(path, Paint()..color = _fill);
    if (_side.style != BorderStyle.none && _side.width > 0) {
      final shape = _shape;
      final outlined = shape is OutlinedBorder
          ? shape.copyWith(side: _side)
          : shape;
      outlined.paint(canvas, rect, textDirection: _textDirection);
    }
    super.paint(context, offset);
  }
}

/// A surface's [own] padding at [density]: density moves its top and
/// bottom, never its sides, which are the keyline its content starts on
/// (a card's words in line with the page's and its section header's).
EdgeInsets _keylinePadding(ExpressiveDensity density, EdgeInsets own) =>
    density.padding(own).copyWith(left: own.left, right: own.right);

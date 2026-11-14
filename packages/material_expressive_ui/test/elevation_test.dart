/// Elevation: the six generated levels, Compose's tonal-elevation tint
/// (`surfaceColorAtElevation`, accumulated through nested surfaces), the
/// shadow colour, Android's shadow model (the window light, the ambient and
/// spot layers), and elevation by interaction state.
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/src/material_expressive/internal/tokens/behavior.g.dart';
import 'package:material_expressive_ui/src/material_expressive/internal/tokens/elevated_button_tokens.g.dart';

void main() {
  test('the six levels are ElevationTokens', () {
    expect(
      ExpressiveElevationLevel.values.map(ExpressiveElevation.dpOf).toList(),
      <double>[0, 1, 3, 6, 8, 12],
    );
  });

  test('tonal elevation tints surface as Compose does', () {
    for (final id in ExpressiveThemeData.presets) {
      for (final b in Brightness.values) {
        final t = ExpressiveThemeData.preset(id, b);
        final e = t.elevation;
        expect(e, ExpressiveElevation(t.colors));
        expect(e.surfaceAt(0), t.colors.surface);
        for (final level in ExpressiveElevationLevel.values.skip(1)) {
          // ((4.5 · ln(dp + 1)) + 2) / 100 (ColorScheme.kt).
          final alpha = ((4.5 * math.log(level.dp + 1)) + 2) / 100;
          expect(
            e.surfaceAt(level.dp),
            Color.alphaBlend(
              t.colors.surfaceTint.withValues(alpha: alpha),
              t.colors.surface,
            ),
          );
        }
        // Only the surface role is tinted.
        expect(
          e.tonal(t.colors.surfaceContainer, 6),
          t.colors.surfaceContainer,
        );
        expect(e.tonal(t.colors.surface, 6), e.surfaceAt(6));
        expect(e.shadowColor, t.colors.shadow);
      }
    }
    expect(HostBehavior.tonalElevationAlphaSlope, 4.5);
    expect(HostBehavior.tonalElevationAlphaIntercept, 2);
  });

  test('the shadow light is HWUI\'s, over the top centre of the window', () {
    // The oracle AVD: 1080 × 2400 px at 2.625.
    const window = Size(1080 / 2.625, 2400 / 2.625);
    final light = ExpressiveShadowLight.overWindow(
      window,
      origin: const Offset(0, 132 / 2.625),
      devicePixelRatio: 2.625,
    );
    expect(light.position.dx, closeTo(1080 / 2.625 / 2, 1e-9));
    expect(light.position.dy, closeTo(-132 / 2.625, 1e-9));
    // ThreadedRenderer.setLightCenter: 500dp · (411.43 / 450 + 2) / 3.
    expect(light.z, closeTo(500 * (1080 / 2.625 / 450 + 2) / 3, 1e-9));
    expect(light.radius, 800);
    expect(ExpressiveAndroidShadowModel.ambientShadowAlpha, 0.039);
    expect(ExpressiveAndroidShadowModel.spotShadowAlpha, 0.19);
  });

  test('paintShadow draws an ambient and a projected spot layer', () {
    final t = ExpressiveThemeData.preset('baseline', Brightness.light);
    const window = Size(400, 800);
    final light = ExpressiveShadowLight.overWindow(window);
    final caster = Path()..addRect(const Rect.fromLTWH(20, 400, 100, 40));
    final canvas = _RecordingCanvas();
    t.elevation.paintShadow(canvas, caster, 6, light: light);
    expect(canvas.paths, hasLength(2));
    final (ambient, ambientPaint) = canvas.paths[0];
    final (spot, spotPaint) = canvas.paths[1];
    // Both in the shadow role, at Android's alphas under the falloff peak.
    expect(ambientPaint.color.a, closeTo(0.039 * 0.982, 1e-3));
    expect(spotPaint.color.a, closeTo(0.19 * 0.982, 1e-3));
    expect(ambientPaint.maskFilter, isNotNull);
    expect(spotPaint.maskFilter, isNotNull);
    // The ambient halo stays centred on the caster.
    expect(ambient.getBounds().center.dx, closeTo(70, 1e-4));
    expect(ambient.getBounds().center.dy, closeTo(420, 1e-4));
    // The spot is projected away from the light (200, 0): p + r(p − light).
    final r = 6 / (light.z - 6);
    final centre = spot.getBounds().center;
    expect(centre.dx, closeTo(70 + r * (70 - 200), 1e-4));
    expect(centre.dy, closeTo(420 + r * 420, 1e-4));
    // Nothing at rest.
    final none = _RecordingCanvas();
    t.elevation.paintShadow(none, caster, 0, light: light);
    expect(none.paths, isEmpty);
  });

  testWidgets('a surface lights its shadow from its place in the window', (
    tester,
  ) async {
    final t = ExpressiveThemeData.preset('baseline', Brightness.light);
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(400, 800);
    addTearDown(tester.view.reset);
    final key = GlobalKey();
    await tester.pumpWidget(
      ExpressiveTheme(
        data: t,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 150, top: 300),
              child: RepaintBoundary(
                key: key,
                child: ColoredBox(
                  color: const Color(0xFFFFFFFF),
                  child: SizedBox(
                    width: 120,
                    height: 120,
                    child: Center(
                      child: ExpressiveSurface(
                        shape: t.shapes.medium,
                        color: t.colors.surfaceContainerLow,
                        shadowElevation: ExpressiveElevationLevel.level5,
                        child: const SizedBox(width: 40, height: 40),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    // Centre of the window x = 200; the caster (190–230) sits right of the
    // light, so its spot leans right and down: more shadow below-right than
    // below-left, although the caster is symmetric in its crop.
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(key),
    );
    final bytes = await tester.runAsync(() async {
      final image = await boundary.toImage();
      final data = await image.toByteData();
      image.dispose();
      return data!;
    });
    int darkness(int x, int y) => 255 - bytes!.getUint8((y * 120 + x) * 4);
    // Just below the caster (y 80–120), beside its edges.
    var left = 0;
    var right = 0;
    for (var y = 81; y < 100; y++) {
      for (var d = 0; d < 20; d++) {
        left += darkness(40 + d, y);
        right += darkness(79 - d, y);
      }
    }
    expect(right, greaterThan(left));
    // Drawn pixels are the rasterizer's, as a golden's: macOS runs it.
  }, tags: const ['goldens']);

  testWidgets('a transparent surface casts its shadow only outside its '
      'outline, as Android does', (tester) async {
    final t = ExpressiveThemeData.preset('baseline', Brightness.light);
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(400, 800);
    addTearDown(tester.view.reset);
    final key = GlobalKey();
    await tester.pumpWidget(
      ExpressiveTheme(
        data: t,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: RepaintBoundary(
              key: key,
              child: ColoredBox(
                color: const Color(0xFFFFFFFF),
                child: SizedBox(
                  width: 120,
                  height: 120,
                  child: Center(
                    child: ExpressiveSurface(
                      shape: t.shapes.small,
                      color: const Color(0x00000000),
                      shadowElevation: ExpressiveElevationLevel.level3,
                      child: const SizedBox(width: 60, height: 32),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(key),
    );
    final bytes = await tester.runAsync(() async {
      final image = await boundary.toImage();
      final data = await image.toByteData();
      image.dispose();
      return data!;
    });
    int darkness(int x, int y) => 255 - bytes!.getUint8((y * 120 + x) * 4);
    // The caster spans x 30–90, y 44–76: inside it (clear of the corners
    // and the edge's anti-aliasing) the ground shows untouched; below it,
    // the shadow.
    for (var y = 48; y < 72; y++) {
      for (var x = 34; x < 86; x++) {
        expect(darkness(x, y), 0, reason: '($x, $y)');
      }
    }
    expect(darkness(60, 78), greaterThan(0));
  }, tags: const ['goldens']);

  test('elevation by state: disabled, pressed, dragged, focused, hovered', () {
    const e = ExpressiveStateElevation(
      rest: ElevatedButtonTokens.containerElevation,
      pressed: ElevatedButtonTokens.pressedContainerElevation,
      focused: ElevatedButtonTokens.focusedContainerElevation,
      hovered: ElevatedButtonTokens.hoveredContainerElevation,
      disabled: ElevatedButtonTokens.disabledContainerElevation,
    );
    expect(e.resolve(<WidgetState>{}), ExpressiveElevationLevel.level1);
    expect(e.resolve({WidgetState.hovered}), ExpressiveElevationLevel.level2);
    expect(
      e.resolve({WidgetState.hovered, WidgetState.pressed}),
      ElevatedButtonTokens.pressedContainerElevation,
    );
    expect(
      e.resolve({WidgetState.pressed, WidgetState.disabled}),
      ExpressiveElevationLevel.level0,
    );
    // Dragged names no level here: it falls through to focused.
    expect(
      e.resolve({WidgetState.dragged, WidgetState.focused}),
      ElevatedButtonTokens.focusedContainerElevation,
    );
    expect(
      const ExpressiveStateElevation.all(ExpressiveElevationLevel.level3)
          .resolve({WidgetState.disabled}),
      ExpressiveElevationLevel.level3,
    );
  });

  testWidgets('nested surfaces accumulate tonal elevation', (tester) async {
    final t = ExpressiveThemeData.preset('baseline', Brightness.light);
    late double inner;
    await tester.pumpWidget(
      ExpressiveTheme(
        data: t,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: ExpressiveSurface(
            shape: t.shapes.medium,
            color: t.colors.surface,
            tonalElevation: ExpressiveElevationLevel.level1,
            child: ExpressiveSurface(
              shape: t.shapes.medium,
              color: t.colors.surface,
              tonalElevation: ExpressiveElevationLevel.level2,
              child: Builder(
                builder: (context) {
                  inner = ExpressiveSurface.absoluteTonalElevationOf(context);
                  return const SizedBox.expand();
                },
              ),
            ),
          ),
        ),
      ),
    );
    expect(inner, 4);
  });

  testWidgets('a shadow level change springs, then settles on the level', (
    tester,
  ) async {
    final t = ExpressiveThemeData.preset('baseline', Brightness.light);
    Widget surface(ExpressiveElevationLevel level) => ExpressiveTheme(
      data: t,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: ExpressiveSurface(
          shape: t.shapes.medium,
          color: t.colors.surfaceContainerLow,
          shadowElevation: level,
          child: const SizedBox.expand(),
        ),
      ),
    );
    double shown() => tester
        .widget<ExpressiveSpringValue>(find.byType(ExpressiveSpringValue))
        .value;
    await tester.pumpWidget(surface(ExpressiveElevationLevel.level1));
    await tester.pumpWidget(surface(ExpressiveElevationLevel.level3));
    expect(shown(), 6);
    await tester.pumpAndSettle();
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('a tap on a surface\'s empty area stays on the surface', (
    tester,
  ) async {
    final t = ExpressiveThemeData.preset('baseline', Brightness.light);
    var under = 0;
    await tester.pumpWidget(
      ExpressiveTheme(
        data: t,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => under++,
                ),
              ),
              Center(
                child: ExpressiveSurface(
                  shape: t.shapes.medium,
                  color: t.colors.surfaceContainerLow,
                  shadowElevation: ExpressiveElevationLevel.level1,
                  child: const SizedBox(width: 200, height: 100),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tapAt(tester.getCenter(find.byType(ExpressiveSurface)));
    expect(under, 0);
    await tester.tapAt(const Offset(4, 4));
    expect(under, 1);
  });
}

/// Records the paths drawn on it.
class _RecordingCanvas implements Canvas {
  final List<(Path, Paint)> paths = <(Path, Paint)>[];

  @override
  void drawPath(Path path, Paint paint) => paths.add((path, paint));

  @override
  Float64List getTransform() => Matrix4.identity().storage;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

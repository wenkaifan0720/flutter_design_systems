/// Expressive's shape (w1-shape's test, with `shape.dart`, its
/// `internal/shape/` part and the generator's `emit/shape.ts`): the corner
/// scale exactly as the tokens state it, the 35 library shapes and the
/// morphs equal to Compose's own cubics (`shape_golden.json`, exported from
/// androidx graphics-shapes on the JVM by
/// `tools/expressive_tokens/src/shapes/golden.ts`) to 1e-4, the morph's
/// endpoints exact and its path reused frame to frame.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/rendering.dart' show BoxHitTestResult;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

import 'package:material_expressive_ui/src/material_expressive/internal/shape/graphics/graphics.dart';
import 'package:material_expressive_ui/src/material_expressive/internal/shape/library.dart';
import 'package:material_expressive_ui/src/material_expressive/internal/tokens/keys.g.dart';
import 'package:material_expressive_ui/src/material_expressive/internal/tokens/shape_tokens.g.dart';
import 'package:material_expressive_ui/src/material_expressive/internal/tokens/token_types.g.dart';

const double tolerance = 1e-4;

/// A 200 × 100 rectangle: percent corners resolve against its 100dp side.
const Rect wide = Rect.fromLTWH(0, 0, 200, 100);

double cornerPx(CornerToken corner, Rect rect) => switch (corner) {
  CornerDp(:final dp) => dp,
  CornerPercent(:final percent) => rect.shortestSide * percent / 100,
};

/// [corners] on [rect] as Compose resolves them (left-to-right): each
/// clamped to half the shorter side.
List<double> tokenRadii(CornersToken corners, Rect rect) {
  double r(CornerToken c) => cornerPx(c, rect).clamp(0, rect.shortestSide / 2);
  return <double>[
    r(corners.topStart),
    r(corners.topEnd),
    r(corners.bottomEnd),
    r(corners.bottomStart),
  ];
}

List<double> radii(BorderRadius b) => <double>[
  b.topLeft.x,
  b.topRight.x,
  b.bottomRight.x,
  b.bottomLeft.x,
];

String composeName(ExpressiveMaterialShape shape) =>
    shape.name[0].toUpperCase() + shape.name.substring(1);

List<List<double>> cubicsOf(Object? json) => <List<double>>[
  for (final cubic in json! as List<Object?>)
    <double>[for (final v in cubic! as List<Object?>) (v! as num).toDouble()],
];

void expectCubics(
  List<List<double>> actual,
  List<List<double>> golden,
  String what,
) {
  expect(actual.length, golden.length, reason: '$what: cubic count');
  for (var i = 0; i < golden.length; i++) {
    for (var j = 0; j < 8; j++) {
      final delta = (actual[i][j] - golden[i][j]).abs();
      if (delta > tolerance) {
        fail(
          '$what: cubic $i value $j is ${actual[i][j]}, Compose ${golden[i][j]}',
        );
      }
    }
  }
}

List<double> pointsOf(ExpressiveShapeCubic c) => <double>[
  c.anchor0X,
  c.anchor0Y,
  c.control0X,
  c.control0Y,
  c.control1X,
  c.control1Y,
  c.anchor1X,
  c.anchor1Y,
];

void main() {
  final golden = jsonDecode(
    File('test/shape_golden.json').readAsStringSync(),
  ) as Map<String, Object?>;
  final goldenShapes = golden['shapes']! as Map<String, Object?>;
  final goldenMorphs = golden['morphs']! as List<Object?>;

  group('corner scale', () {
    test('every step is its token, exactly', () {
      final expected = <ExpressiveCorner, double>{
        ExpressiveCorner.none: ShapeTokens.cornerValueNone,
        ExpressiveCorner.extraSmall: ShapeTokens.cornerValueExtraSmall,
        ExpressiveCorner.small: ShapeTokens.cornerValueSmall,
        ExpressiveCorner.medium: ShapeTokens.cornerValueMedium,
        ExpressiveCorner.large: ShapeTokens.cornerValueLarge,
        ExpressiveCorner.largeIncreased: ShapeTokens.cornerValueLargeIncreased,
        ExpressiveCorner.extraLarge: ShapeTokens.cornerValueExtraLarge,
        ExpressiveCorner.extraLargeIncreased:
            ShapeTokens.cornerValueExtraLargeIncreased,
        ExpressiveCorner.extraExtraLarge:
            ShapeTokens.cornerValueExtraExtraLarge,
        ExpressiveCorner.full: wide.shortestSide / 2,
      };
      expect(expected.values.toList(), <double>[
        0,
        4,
        8,
        12,
        16,
        20,
        28,
        32,
        48,
        50,
      ]);
      for (final id in ExpressiveThemeData.presets) {
        for (final brightness in Brightness.values) {
          final shapes = ExpressiveThemeData.preset(id, brightness).shapes;
          for (final MapEntry(key: corner, value: px) in expected.entries) {
            expect(radii(shapes.corner(corner).radiiOn(wide)), <double>[
              px,
              px,
              px,
              px,
            ], reason: '$id $brightness ${corner.name}');
          }
        }
      }
    });

    test('every shape key resolves to its token corners', () {
      final shapes = ExpressiveThemeData.preset(
        ExpressiveThemeData.presets.first,
        Brightness.light,
      ).shapes;
      for (final key in ExpressiveShapeKey.values) {
        expect(
          radii(shapes.of(key).radiiOn(wide)),
          tokenRadii(ShapeTokens.of(key), wide),
          reason: key.name,
        );
      }
    });

    test('top, bottom, start and end keep only their corners', () {
      final large = ExpressiveThemeData.preset(
        ExpressiveThemeData.presets.first,
        Brightness.light,
      ).shapes.large;
      const l = 16.0;
      expect(radii(large.top().radiiOn(wide)), <double>[l, l, 0, 0]);
      expect(radii(large.bottom().radiiOn(wide)), <double>[0, 0, l, l]);
      expect(radii(large.start().radiiOn(wide)), <double>[l, 0, 0, l]);
      expect(radii(large.end().radiiOn(wide)), <double>[0, l, l, 0]);
      expect(radii(large.start().radiiOn(wide, TextDirection.rtl)), <double>[
        0,
        l,
        l,
        0,
      ], reason: 'start is the right side right-to-left');
    });

    test('corners clamp to half the shorter side, as Compose clamps', () {
      final shapes = ExpressiveThemeData.preset(
        ExpressiveThemeData.presets.first,
        Brightness.light,
      ).shapes;
      const small = Rect.fromLTWH(0, 0, 60, 40);
      expect(radii(shapes.extraExtraLarge.radiiOn(small)), <double>[
        20,
        20,
        20,
        20,
      ]);
    });

    test('lerps corner by corner, linear in pixels', () {
      final shapes = ExpressiveThemeData.preset(
        ExpressiveThemeData.presets.first,
        Brightness.light,
      ).shapes;
      final half =
          ShapeBorder.lerp(shapes.medium, shapes.full, 0.5)!
              as ExpressiveCornerBorder;
      expect(radii(half.radiiOn(wide)), <double>[31, 31, 31, 31]);
    });
  });

  group('library shapes', () {
    test('every library pair interpolates with exact endpoint outlines', () {
      const rect = Rect.fromLTWH(11, 17, 120, 80);
      for (final from in ExpressiveMaterialShape.values) {
        for (final to in ExpressiveMaterialShape.values) {
          final a = ExpressiveMaterialShapeBorder(from);
          final b = ExpressiveMaterialShapeBorder(to);
          for (final progress in [0.0, .5, 1.0]) {
            final shape = ShapeBorder.lerp(a, b, progress)!;
            final path = shape.getOuterPath(rect);
            final bounds = path.getBounds();
            final reason = '$from -> $to at $progress';
            expect(bounds.isFinite, isTrue, reason: reason);
            expect(bounds.isEmpty, isFalse, reason: reason);
            expect(
              bounds.center.dx,
              closeTo(rect.center.dx, 1e-4),
              reason: reason,
            );
            expect(
              bounds.center.dy,
              closeTo(rect.center.dy, 1e-4),
              reason: reason,
            );
            final metrics = path.computeMetrics().toList();
            expect(metrics, isNotEmpty, reason: reason);
            expect(
              metrics.every(
                (metric) =>
                    metric.isClosed &&
                    metric.length.isFinite &&
                    metric.length > 0,
              ),
              isTrue,
              reason: reason,
            );
            if (progress == 0 || progress == 1) {
              final endpoint = (progress == 0 ? a : b).getOuterPath(rect);
              expect(bounds, endpoint.getBounds(), reason: reason);
              for (var x = rect.left + 1; x < rect.right; x += 7) {
                for (var y = rect.top + 1; y < rect.bottom; y += 7) {
                  final point = Offset(x, y);
                  expect(
                    path.contains(point),
                    endpoint.contains(point),
                    reason: reason,
                  );
                }
              }
            }
          }
        }
      }
    });

    test('there are the 35 of MaterialShapes, in its order', () {
      expect(ExpressiveMaterialShape.values, hasLength(35));
      expect(
        ExpressiveMaterialShape.values.map(composeName).toList(),
        goldenShapes.keys.toList(),
      );
    });

    for (final shape in ExpressiveMaterialShape.values) {
      test('${composeName(shape)} equals Compose to 1e-4', () {
        expectCubics(
          expressiveLibraryShapeCubics(shape),
          cubicsOf(goldenShapes[composeName(shape)]),
          composeName(shape),
        );
      });
    }

    test('the border lays a shape out as toShape does: centred', () {
      const rect = Rect.fromLTWH(10, 20, 120, 80);
      for (final shape in ExpressiveMaterialShape.values) {
        final bounds = ExpressiveMaterialShapeBorder(shape)
            .getOuterPath(rect)
            .getBounds();
        expect(
          bounds.center.dx,
          closeTo(rect.center.dx, 1e-4),
          reason: '$shape',
        );
        expect(
          bounds.center.dy,
          closeTo(rect.center.dy, 1e-4),
          reason: '$shape',
        );
      }
    });
  });

  group('morph', () {
    ExpressiveMaterialShape named(Object? name) => ExpressiveMaterialShape
        .values
        .firstWhere((s) => composeName(s) == name);

    for (final entry in goldenMorphs) {
      final morph = entry! as Map<String, Object?>;
      final from = named(morph['from']);
      final to = named(morph['to']);
      final progress = morph['progress']! as Map<String, Object?>;
      test('${morph['from']} → ${morph['to']} equals Compose to 1e-4', () {
        final m = ExpressiveMorph.between(from, to);
        for (final MapEntry(key: p, value: cubics) in progress.entries) {
          expectCubics(
            m.cubicsAt(double.parse(p)),
            cubicsOf(cubics),
            '${morph['from']} → ${morph['to']} at $p',
          );
        }
      });
    }

    test('its endpoints are exactly the matched start and end shapes', () {
      for (final entry in goldenMorphs) {
        final morph = entry! as Map<String, Object?>;
        final m = ExpressivePolygonMorph(
          expressiveLibraryPolygon(named(morph['from'])),
          expressiveLibraryPolygon(named(morph['to'])),
        );
        final match = m.morphMatch;
        for (final (progress, side) in <(double, int)>[(0, 0), (1, 1)]) {
          final cubics = m.asCubics(progress);
          expect(cubics, hasLength(match.length));
          for (var i = 0; i < match.length; i++) {
            final expected = pointsOf(side == 0 ? match[i].$1 : match[i].$2);
            final actual = pointsOf(cubics[i]);
            // The last curve closes exactly on the first anchor.
            final closing = i == match.length - 1;
            expect(
              actual.sublist(0, closing ? 6 : 8),
              expected.sublist(0, closing ? 6 : 8),
            );
            if (closing) {
              expect(actual.sublist(6), pointsOf(cubics.first).sublist(0, 2));
            }
          }
        }
        // The matched start side tiles the start shape: contiguous and
        // closed.
        for (var i = 0; i < match.length; i++) {
          final next = match[(i + 1) % match.length].$1;
          expect(match[i].$1.anchor1X, closeTo(next.anchor0X, 1e-5));
          expect(match[i].$1.anchor1Y, closeTo(next.anchor0Y, 1e-5));
        }
      }
    });

    test(
      'writes every frame into the caller\'s path, as asCubics shapes it',
      () {
        final m = ExpressiveMorph.between(
          ExpressiveMaterialShape.softBurst,
          ExpressiveMaterialShape.cookie9Sided,
        );
        const size = Size(48, 48);
        final path = Path();
        for (var frame = 1; frame <= 60; frame++) {
          final progress = frame / 60;
          m.writePath(path, progress, size);
          final reference = expressiveCubicsPath(<ExpressiveShapeCubic>[
            for (final c in m.cubicsAt(progress))
              ExpressiveShapeCubic(
                c[0],
                c[1],
                c[2],
                c[3],
                c[4],
                c[5],
                c[6],
                c[7],
              ),
          ]).transform(Matrix4.diagonal3Values(48, 48, 1).storage);
          final a = path.getBounds();
          final b = reference.getBounds();
          expect(a.left, closeTo(b.left, 1e-4));
          expect(a.top, closeTo(b.top, 1e-4));
          expect(a.right, closeTo(b.right, 1e-4));
          expect(a.bottom, closeTo(b.bottom, 1e-4));
        }
        expect(
          identical(
            ExpressiveMorph.between(
              ExpressiveMaterialShape.softBurst,
              ExpressiveMaterialShape.cookie9Sided,
            ),
            m,
          ),
          isTrue,
          reason: 'a pair is matched once',
        );
      },
    );

    testWidgets('the clipper re-clips with its progress', (tester) async {
      final progress = ValueNotifier<double>(0);
      addTearDown(progress.dispose);
      final clipper = ExpressiveMorphClipper(
        ExpressiveMorph.between(
          ExpressiveMaterialShape.circle,
          ExpressiveMaterialShape.square,
        ),
        progress,
      );
      await tester.pumpWidget(
        Center(
          child: SizedBox.square(
            dimension: 48,
            child: ClipPath(
              clipper: clipper,
              child: const ColoredBox(color: Color(0xFF000000)),
            ),
          ),
        ),
      );
      // The engine keeps paths in single precision: compare coverage.
      int covered() {
        final clip = clipper.getClip(const Size(48, 48));
        var inside = 0;
        for (var y = 0.5; y < 48; y++) {
          for (var x = 0.5; x < 48; x++) {
            if (clip.contains(Offset(x, y))) inside++;
          }
        }
        return inside;
      }

      final atStart = covered();
      progress.value = 1;
      await tester.pump();
      expect(covered(), greaterThan(atStart), reason: 'a square covers more');
    });

    testWidgets('clippers sharing a pair keep their own clips', (tester) async {
      final morph = ExpressiveMorph.between(
        ExpressiveMaterialShape.circle,
        ExpressiveMaterialShape.square,
      );
      final a = ValueNotifier<double>(0);
      final b = ValueNotifier<double>(1);
      addTearDown(a.dispose);
      addTearDown(b.dispose);
      Widget clipped(Key key, ValueNotifier<double> progress) =>
          SizedBox.square(
            dimension: 48,
            child: ClipPath(
              key: key,
              clipper: ExpressiveMorphClipper(morph, progress),
              child: const ColoredBox(color: Color(0xFF000000)),
            ),
          );
      const keyA = Key('a');
      const keyB = Key('b');
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[clipped(keyA, a), clipped(keyB, b)],
          ),
        ),
      );
      // Coverage by hit testing, which reads each render object's kept clip.
      int covered(Key key) {
        final box = tester.renderObject<RenderBox>(find.byKey(key));
        var inside = 0;
        for (var y = 0.5; y < 48; y++) {
          for (var x = 0.5; x < 48; x++) {
            if (box.hitTest(BoxHitTestResult(), position: Offset(x, y))) {
              inside++;
            }
          }
        }
        return inside;
      }

      final circle = covered(keyA);
      final square = covered(keyB);
      expect(square, greaterThan(circle), reason: 'b is the square');
      // Moving b re-clips b only; a keeps its circle.
      b.value = 0.5;
      await tester.pump();
      expect(covered(keyA), circle, reason: 'a unchanged after b moved');
      expect(covered(keyB), inInclusiveRange(circle + 1, square - 1));
      b.value = 1;
      await tester.pump();
      expect(covered(keyA), circle);
      expect(covered(keyB), square);
    });
  });
}

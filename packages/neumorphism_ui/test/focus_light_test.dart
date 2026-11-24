// Keyboard focus by night: the light on a focused part's lit side is a soft light like every other relief light, its
// brightness falling off over several device pixels outside the edge, never a hard copy of the part's outline with a
// notch where that copy ends. Read from the drawn pixels at a phone's width and a desktop's, left to right and right to
// left, on a short key and a long one; by day the same reads hold.
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import 'support.dart';

const _ratio = 2.0;

/// How far each pixel of [shot] stands above the [ground] (mean of the three channels), in device pixels.
typedef _Shot = (ByteData, int, int);

double _lift(_Shot shot, Color ground, int x, int y) {
  final (bytes, w, _) = shot;
  final at = (y * w + x) * 4;
  final g = (ground.r + ground.g + ground.b) / 3 * 255;
  return (bytes.getUint8(at) +
              bytes.getUint8(at + 1) +
              bytes.getUint8(at + 2)) /
          3 -
      g;
}

/// The largest change between neighbouring device pixels of [profile], as a share of the light's peak above the
/// ground; 1 when there is no light to read.
(double step, double peak) _steepest(List<double> profile) {
  final peak = profile.reduce(math.max);
  var step = 0.0;
  for (var i = 0; i + 1 < profile.length; i++) {
    step = math.max(step, (profile[i] - profile[i + 1]).abs());
  }
  return (peak <= 0 ? 1 : step / peak, peak);
}

Future<(_Shot, Rect, Color)> _focused(
  WidgetTester tester, {
  required String label,
  required double width,
  required bool dark,
  required TextDirection direction,
}) async {
  tester.view.devicePixelRatio = _ratio;
  tester.view.physicalSize = Size(width * _ratio, 300 * _ratio);
  addTearDown(tester.view.reset);
  final previous = FocusManager.instance.highlightStrategy;
  FocusManager.instance.highlightStrategy =
      FocusHighlightStrategy.alwaysTraditional;
  addTearDown(() => FocusManager.instance.highlightStrategy = previous);
  final node = FocusNode();
  addTearDown(node.dispose);
  final stage = GlobalKey();
  late Color ground;
  await tester.pumpWidget(
    neumorphicApp(
      Align(
        alignment: AlignmentDirectional.topStart,
        child: RepaintBoundary(
          key: stage,
          child: Builder(
            builder: (context) {
              ground = NeumorphicTheme.of(context).colors.ground;
              return ColoredBox(
                color: ground,
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: NeumorphicButton(
                    label,
                    focusNode: node,
                    onPressed: () {},
                  ),
                ),
              );
            },
          ),
        ),
      ),
      dark: dark,
      direction: direction,
    ),
  );
  node.requestFocus();
  await tester.pumpAndSettle();
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(stage),
  );
  // The face the lift is drawn round: the painter's own box.
  final lift = find
      .descendant(of: find.byKey(stage), matching: find.byType(CustomPaint))
      .evaluate()
      .where(
        (e) =>
            (e.widget as CustomPaint).foregroundPainter.runtimeType
                .toString() ==
            '_FocusLift',
      )
      .single;
  final box = lift.renderObject! as RenderBox;
  final face = box.localToGlobal(Offset.zero, ancestor: boundary) & box.size;
  final image = (await tester.runAsync(
    () => boundary.toImage(pixelRatio: _ratio),
  ))!;
  final bytes = (await tester.runAsync(
    () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
  ))!;
  final shot = (bytes, image.width, image.height);
  image.dispose();
  return (shot, face, ground);
}

void main() {
  setUpAll(loadNeumorphicFonts);

  for (final width in const [390.0, 1440.0]) {
    for (final dark in const [true, false]) {
      for (final direction in TextDirection.values) {
        for (final label in const ['Save', 'Save changes']) {
          final mode = dark ? 'night' : 'day';
          testWidgets(
            'a focused key\'s light falls off softly: "$label" at ${width.round()}, by $mode, ${direction.name}',
            (tester) async {
              debugDefaultTargetPlatformOverride = width < 600
                  ? TargetPlatform.android
                  : TargetPlatform.macOS;
              try {
                final (shot, face, ground) = await _focused(
                  tester,
                  label: label,
                  width: width,
                  dark: dark,
                  direction: direction,
                );
                final ltr = direction == TextDirection.ltr;
                // The light stands at the top start: its side is the left, or the right in a right-to-left app.
                final edge = ((ltr ? face.left : face.right) * _ratio).round();
                final out = ltr ? -1 : 1;
                final midY = (face.center.dy * _ratio).round();
                final midX = (face.center.dx * _ratio).round();
                final top = (face.top * _ratio).round();
                final bottom = (face.bottom * _ratio).round();
                final reach = (16 * _ratio).round();
                final profiles = <String, List<double>>{
                  // Out from the lit side, at the middle of its height.
                  'across the lit side': [
                    for (var i = 1; i <= reach; i++)
                      _lift(shot, ground, edge + out * i, midY),
                  ],
                  // Up from the top edge, at the middle of its width.
                  'across the top': [
                    for (var i = 1; i <= reach; i++)
                      _lift(shot, ground, midX, top - i),
                  ],
                  // Down the lit side, 2 px out from it, past the bottom corner: where a hard copy of the outline ends
                  // it leaves a notch.
                  'down the lit side': [
                    for (var y = midY; y < bottom + reach; y++)
                      _lift(shot, ground, edge + out * (2 * _ratio).round(), y),
                  ],
                };
                for (final MapEntry(key: where, value: profile)
                    in profiles.entries) {
                  final (step, peak) = _steepest(profile);
                  debugPrint(
                    'focus light $label ${width.round()} $mode ${direction.name} $where: '
                    'peak=${peak.toStringAsFixed(1)} steepest=${step.toStringAsFixed(3)}',
                  );
                  expect(
                    peak,
                    greaterThan(8),
                    reason: 'the light shows $where',
                  );
                  expect(
                    step,
                    lessThanOrEqualTo(.15),
                    reason:
                        'the light falls off over several device pixels $where, never in one step',
                  );
                }
              } finally {
                debugDefaultTargetPlatformOverride = null;
              }
            },
          );
        }
      }
    }
  }
}

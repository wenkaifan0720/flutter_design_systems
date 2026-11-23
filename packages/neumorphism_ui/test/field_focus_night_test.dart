// A field being typed in sits deeper than one at rest, as plainly by night as by day. Measured as the relief a well
// shows, in perceived lightness (CIE L*) away from the ground: by night a deeper shade is lost on the dark ground, so
// the well's lit lip carries the extra depth.
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import 'support.dart';

double _lightness(int r, int g, int b) {
  double linear(int v) {
    final c = v / 255;
    return c <= .04045
        ? c / 12.92
        : math.pow((c + .055) / 1.055, 2.4).toDouble();
  }

  final y = .2126 * linear(r) + .7152 * linear(g) + .0722 * linear(b);
  return y <= 216 / 24389 ? y * 24389 / 27 : 116 * math.pow(y, 1 / 3) - 16;
}

/// How far a focused field's well stands from the ground, over how far a resting one's does, in one frame.
Future<double> _deepening(WidgetTester tester, {required bool dark}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(400, 300);
  addTearDown(tester.view.reset);
  final key = GlobalKey();
  late Color ground;
  await tester.pumpWidget(
    neumorphicApp(
      RepaintBoundary(
        key: key,
        child: Builder(
          builder: (context) {
            ground = NeumorphicTheme.of(context).colors.ground;
            return ColoredBox(
              color: ground,
              child: Center(
                child: SizedBox(
                  width: 320,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      NeumorphicTextField(
                        key: const ValueKey('title'),
                        labelText: 'Title',
                        onChanged: (_) {},
                      ),
                      const SizedBox(height: 24),
                      NeumorphicTextField(
                        key: const ValueKey('notes'),
                        labelText: 'Notes',
                        onChanged: (_) {},
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      dark: dark,
      width: 400,
    ),
  );
  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  await tester.pumpAndSettle();
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
  final image = (await tester.runAsync(() => boundary.toImage()))!;
  final bytes = (await tester.runAsync(
    () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
  ))!;
  final width = image.width;
  image.dispose();
  final floor = _lightness(
    (ground.r * 255).round(),
    (ground.g * 255).round(),
    (ground.b * 255).round(),
  );
  double relief(String field) {
    final well = tester.getRect(
      find.descendant(
        of: find.byKey(ValueKey(field)),
        matching: find.byType(NeumorphicFieldBox),
      ),
    );
    var sum = 0.0;
    for (var y = well.top.ceil() + 1; y < well.bottom.floor() - 1; y++) {
      for (var x = well.left.ceil() + 1; x < well.right.floor() - 1; x++) {
        final i = (y * width + x) * 4;
        sum +=
            (_lightness(
                      bytes.getUint8(i),
                      bytes.getUint8(i + 1),
                      bytes.getUint8(i + 2),
                    ) -
                    floor)
                .abs();
      }
    }
    return sum;
  }

  expect(FocusManager.instance.primaryFocus, isNotNull);
  return relief('title') / relief('notes');
}

void main() {
  testWidgets('a focused field stands deeper by night as plainly as by day', (
    tester,
  ) async {
    final day = await _deepening(tester, dark: false);
    final night = await _deepening(tester, dark: true);
    expect(day, greaterThan(2), reason: 'focus deepens the well by day');
    expect(night, greaterThan(day * .95), reason: 'and as much by night');
  });
}

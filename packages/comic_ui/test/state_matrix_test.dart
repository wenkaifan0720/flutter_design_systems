// In the state matrix, every filled pressed, disabled and error cell differs from idle pixel for pixel, and every state
// keeps idle's size (an error cell may add its message below): toggling a state must not move the layout.
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';
import 'package:comic_ui/comic_host.dart';

import 'state_matrix_support.dart';

const _cell = ValueKey('cell');
const MatrixFlags _idle = (selected: false, disabled: false, error: false);

typedef _Shot = ({Uint8List pixels, Size size});

Future<_Shot> _take(WidgetTester tester) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_cell),
  );
  final image = (await tester.runAsync(() => boundary.toImage()))!;
  final data = (await tester.runAsync(
    () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
  ))!;
  final shot = (
    pixels: data.buffer.asUint8List(),
    size: Size(image.width.toDouble(), image.height.toDouble()),
  );
  image.dispose();
  return shot;
}

Future<_Shot> _paint(WidgetTester tester, MatrixRow row, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      home: ComicHost(
        brightness: Brightness.light,
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: row.width,
            child: Align(
              alignment: Alignment.topLeft,
              child: RepaintBoundary(key: _cell, child: child),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 600));
  return _take(tester);
}

Finder _pressTarget() {
  for (final type in [DesignPressable, ComicPressable]) {
    final found = find.descendant(
      of: find.byKey(_cell),
      matching: find.byType(type),
    );
    if (found.evaluate().isNotEmpty) return found.first;
  }
  return find.byKey(_cell);
}

void _differs(_Shot state, _Shot idle, String what) {
  // Differing sizes differ by more than pixels; the size check names that fault.
  if (state.size != idle.size) return;
  expect(
    listEquals(state.pixels, idle.pixels),
    isFalse,
    reason: 'its $what cell looks just like idle',
  );
}

void main() {
  setUp(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(900, 1200);
    view.devicePixelRatio = 1;
  });
  tearDown(() {
    TestWidgetsFlutterBinding.instance.platformDispatcher.views.first.reset();
  });

  // Each state is told from idle by its drawn pixels: the rasterizer's, as a golden's. Each test is tagged goldens
  // (flutter_test's group takes no tags), so Linux CI leaves them to the macOS goldens job.
  for (final row in matrixRows()) {
    group('state matrix: ${row.name}', () {
      if (row.press) {
        testWidgets('pressed differs from idle and keeps its size', (
          tester,
        ) async {
          final idle = await _paint(tester, row, row.build(_idle)!);
          final mouse = await tester.startGesture(
            tester.getCenter(_pressTarget()),
            kind: PointerDeviceKind.mouse,
          );
          // The press starts its look on the next frame; a second frame shows it.
          await tester.pump(const Duration(milliseconds: 300));
          await tester.pump(const Duration(milliseconds: 300));
          final pressed = await _take(tester);
          await mouse.cancel();
          await tester.pump(const Duration(milliseconds: 300));
          expect(pressed.size, idle.size);
          _differs(pressed, idle, 'pressed');
        }, tags: 'goldens');
      }

      final off = row.build((selected: false, disabled: true, error: false));
      if (off != null) {
        testWidgets('disabled differs from idle and keeps its size', (
          tester,
        ) async {
          final idle = await _paint(tester, row, row.build(_idle)!);
          final state = await _paint(tester, row, off);
          expect(state.size, idle.size);
          _differs(state, idle, 'disabled');
        }, tags: 'goldens');
      }

      final wrong = row.build((selected: false, disabled: false, error: true));
      if (wrong != null) {
        testWidgets('error differs from idle and only grows below', (
          tester,
        ) async {
          final idle = await _paint(tester, row, row.build(_idle)!);
          final state = await _paint(tester, row, wrong);
          expect(state.size.width, idle.size.width);
          expect(state.size.height, greaterThanOrEqualTo(idle.size.height));
          _differs(state, idle, 'error');
        }, tags: 'goldens');
      }
    });
  }
}

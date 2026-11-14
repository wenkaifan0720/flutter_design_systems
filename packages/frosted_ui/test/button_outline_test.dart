// The outline a person sees is the box (coordinator, 11-11; the user, 16:34: "the button doesnt have the same height
// here?"): every pair of acts sharing a row, read off the pixels, shows one top and one bottom by its visible
// outline, by day and by night: a glass button beside an ink one asking for a larger size, on a sheet and on the
// page, and a dialog's Cancel beside its danger act under compact. A variant differs in its fill, never in the size
// it shows. In a row of known sides, the row's two ends stand equally far in.
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/frosted_host.dart';

const _stage = ValueKey('stage');
const _width = 400;
const _height = 300;
const _side = 24.0;

double _apart(Color a, Color b) =>
    [(a.r - b.r).abs(), (a.g - b.g).abs(), (a.b - b.b).abs()].reduce(math.max);

typedef _Read = Color Function(int x, int y);

Future<_Read> _shot(WidgetTester tester) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_stage),
  );
  final px = (await tester.runAsync(() async {
    final image = await boundary.toImage();
    try {
      return (await image.toByteData())!.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }))!;
  return (int x, int y) {
    final i = (y * _width + x) * 4;
    return Color.fromARGB(px[i + 3], px[i], px[i + 1], px[i + 2]);
  };
}

/// An act's visible box along one column through it, clear of its corners
/// and its word: from 6 above and 6 below its layout box, where the pixels
/// part from the ground there by half as much as the face's middle does.
({int top, int bottom, int x}) _rows(_Read at, Rect r) {
  final x = (r.left + r.height).round();
  final mid = r.center.dy.round();
  final face = at(x, mid);
  final above = r.top.round() - 6;
  final below = r.bottom.round() + 6;
  final groundAbove = at(x, above);
  final groundBelow = at(x, below);
  expect(
    math.min(_apart(face, groundAbove), _apart(face, groundBelow)),
    greaterThanOrEqualTo(4 / 255),
    reason: 'the face at $x reads as the ground round it',
  );
  var top = above;
  while (top < mid &&
      _apart(at(x, top), groundAbove) < _apart(face, groundAbove) / 2) {
    top++;
  }
  var bottom = below;
  while (bottom > mid &&
      _apart(at(x, bottom), groundBelow) < _apart(face, groundBelow) / 2) {
    bottom--;
  }
  return (top: top, bottom: bottom, x: x);
}

Widget _app(FrostedThemeData t, Widget home) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, page) => FrostedHost(
    light: t,
    dark: t,
    brightness: t.isDark ? Brightness.dark : Brightness.light,
    child: RepaintBoundary(key: _stage, child: page!),
  ),
  home: home,
);

/// [row] on the theme's ground, inside a sheet's glass when [onSheet].
Widget _rowStage(FrostedThemeData t, Widget row, {required bool onSheet}) {
  final inside = Padding(
    padding: const EdgeInsets.symmetric(horizontal: _side),
    child: Center(child: row),
  );
  return Stack(
    children: [
      Positioned.fill(child: ColoredBox(color: t.colorScheme.background)),
      Positioned.fill(
        child: onSheet
            ? FrostedSurface(material: FrostedMaterial.slab, child: inside)
            : inside,
      ),
    ],
  );
}

Future<void> _expectOneRow(
  WidgetTester tester,
  Finder first,
  Finder second, {
  bool ends = false,
}) async {
  await tester.pump();
  final at = await _shot(tester);
  final a = tester.getRect(first);
  final b = tester.getRect(second);
  final ra = _rows(at, a);
  final rb = _rows(at, b);
  expect((ra.top - rb.top).abs(), lessThanOrEqualTo(1), reason: '$ra vs $rb');
  expect(
    (ra.bottom - rb.bottom).abs(),
    lessThanOrEqualTo(1),
    reason: '$ra vs $rb',
  );
  if (!ends) return;
  // The row's two ends, along the line through the faces' middles.
  final y = a.center.dy.round();
  final startGround = at(_side.round() - 8, y);
  final endGround = at(_width - _side.round() + 8, y);
  final aFace = at(ra.x, y);
  final bFace = at((b.right - b.height).round(), y);
  var left = _side.round() - 8;
  while (left < a.center.dx &&
      _apart(at(left, y), startGround) < _apart(aFace, startGround) / 2) {
    left++;
  }
  var right = _width - _side.round() + 8;
  while (right > b.center.dx &&
      _apart(at(right, y), endGround) < _apart(bFace, endGround) / 2) {
    right--;
  }
  expect(
    (left - (_width - 1 - right)).abs(),
    lessThanOrEqualTo(1),
    reason: 'insets $left and ${_width - 1 - right}',
  );
}

Finder _act(String label) => find
    .ancestor(of: find.text(label), matching: find.byType(FrostedPressable))
    .first;

void main() {
  setUpAll(frostedLoadFonts);

  for (final brightness in Brightness.values) {
    final day = brightness == Brightness.light ? 'day' : 'night';
    final t = FrostedThemeData.preset(
      FrostedThemeData.presets.first,
      brightness,
    );

    for (final onSheet in [true, false]) {
      testWidgets('a glass button and a wide ink one in a row '
          '${onSheet ? 'on a sheet' : 'on the page'} by $day show one box', (
        tester,
      ) async {
        tester.view.physicalSize = Size(_width.toDouble(), _height.toDouble());
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          _app(
            t,
            _rowStage(
              t,
              FrostedButtonRow(
                children: [
                  FrostedButton.glass('Keep', onPressed: () {}),
                  // Asks for the wide act; the row shows it on both.
                  FrostedButton('Freeze', expand: true, onPressed: () {}),
                ],
              ),
              onSheet: onSheet,
            ),
          ),
        );
        await _expectOneRow(tester, _act('Keep'), _act('Freeze'), ends: true);
      }, tags: const ['goldens']);
    }

    testWidgets('a dialog\'s Cancel beside its danger act under compact by '
        '$day show one box', (tester) async {
      tester.view.physicalSize = Size(_width.toDouble(), 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final compact = t.copyWith(density: FrostedDensity.compact);
      await tester.pumpWidget(
        _app(
          compact,
          Builder(
            builder: (context) => ColoredBox(
              color: compact.colorScheme.background,
              child: Center(
                child: FrostedButton(
                  'Open',
                  onPressed: () => FrostedDialog.show(
                    context,
                    title: 'Close your account?',
                    message: 'Your cards stop working today.',
                    confirmLabel: 'Close',
                    cancelLabel: 'Keep it',
                    destructive: true,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      // The stage is the view's height here.
      await _expectOneRowTall(tester, _act('Keep it'), _act('Close'));
    }, tags: const ['goldens']);
  }
}

/// [_expectOneRow] on a stage of 700: the dialog needs the room.
Future<void> _expectOneRowTall(
  WidgetTester tester,
  Finder first,
  Finder second,
) async {
  await tester.pump();
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_stage),
  );
  final width = boundary.size.width.round();
  final px = (await tester.runAsync(() async {
    final image = await boundary.toImage();
    try {
      return (await image.toByteData())!.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }))!;
  Color at(int x, int y) {
    final i = (y * width + x) * 4;
    return Color.fromARGB(px[i + 3], px[i], px[i + 1], px[i + 2]);
  }

  final ra = _rows(at, tester.getRect(first));
  final rb = _rows(at, tester.getRect(second));
  expect((ra.top - rb.top).abs(), lessThanOrEqualTo(1), reason: '$ra vs $rb');
  expect(
    (ra.bottom - rb.bottom).abs(),
    lessThanOrEqualTo(1),
    reason: '$ra vs $rb',
  );
}

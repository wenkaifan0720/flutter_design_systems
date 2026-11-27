import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:appliance_ui/appliance_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// Distinct plastics let the test read each painted edge through its lighting,
// independently of widget bounds, transparent hit targets and drop shadows.
const _outer = Color(0xFFDE0000);
const _inner = Color(0xFF00DE00);
const _frame = ValueKey('plate photograph');
const _ratio = 4;

enum _Plastic { outer, inner }

class _Photo {
  const _Photo(this.bytes, this.width, this.height);
  final Uint8List bytes;
  final int width;
  final int height;

  bool has(_Plastic plastic, int x, int y) {
    final i = (y * width + x) * 4;
    final channel = plastic.index;
    final value = bytes[i + channel];
    return value > bytes[i + 1 - channel] + 70 && value > bytes[i + 2] + 70;
  }

  Rect bounds(_Plastic plastic) {
    var left = width, right = -1, top = height, bottom = -1;
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        if (has(plastic, x, y)) {
          left = math.min(left, x);
          right = math.max(right, x);
          top = math.min(top, y);
          bottom = y;
        }
      }
    }
    expect(right, greaterThanOrEqualTo(left), reason: 'visible $plastic');
    return Rect.fromLTRB(
      left / _ratio,
      top / _ratio,
      (right + 1) / _ratio,
      (bottom + 1) / _ratio,
    );
  }

  // Turn the press tint on the smoked glass into a measurable fill. The
  // green keys' ink stays still in the two frames. Only its translucent
  // wash over the red glass gains green across the whole face.
  _Photo pressOverGlass(_Photo before) {
    final mask = Uint8List(bytes.length);
    for (var i = 0; i < bytes.length; i += 4) {
      if (before.bytes[i] > before.bytes[i + 1] + 70 &&
          before.bytes[i] > before.bytes[i + 2] + 70) {
        mask[i] = 220;
        if (bytes[i + 1] - before.bytes[i + 1] > 12 && bytes[i] > 90) {
          mask[i] = 0;
          mask[i + 1] = 220;
        }
      }
    }
    return _Photo(mask, width, height);
  }

  void corner(_Plastic plastic, Rect box, double radius, {bool right = false}) {
    final x = ((right ? box.right : box.left) * _ratio).round();
    final y = (box.top * _ratio).round();
    var depth = 0;
    while (depth < box.shortestSide * _ratio / 2 &&
        !has(plastic, right ? x - 1 - depth : x + depth, y + depth)) {
      depth++;
    }
    // A circle meets its 45-degree diagonal r * (1 - sqrt(1/2)) from
    // the bounding corner. Include one device pixel for edge coverage.
    expect(
      depth / _ratio,
      closeTo(radius * (1 - math.sqrt(.5)), .38),
      reason: '$plastic painted corner of $box, radius $radius',
    );
  }

  void inset(
    double gap,
    double radius, {
    bool right = false,
    bool bottom = true,
    bool bothEnds = false,
  }) {
    final outer = bounds(_Plastic.outer);
    final inner = bounds(_Plastic.inner);
    expect(inner.top - outer.top, closeTo(gap, .3), reason: 'top');
    if (bottom) {
      expect(outer.bottom - inner.bottom, closeTo(gap, .3), reason: 'bottom');
    }
    if (!right || bothEnds) {
      expect(inner.left - outer.left, closeTo(gap, .3), reason: 'left');
    }
    if (right || bothEnds) {
      expect(outer.right - inner.right, closeTo(gap, .3), reason: 'right');
    }
    corner(_Plastic.outer, outer, radius, right: right);
    corner(_Plastic.inner, inner, radius - gap, right: right);
  }
}

Future<_Photo> _photo(WidgetTester tester) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_frame),
  );
  return (await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: _ratio.toDouble());
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      return _Photo(data!.buffer.asUint8List(), image.width, image.height);
    } finally {
      image.dispose();
    }
  }))!;
}

Future<void> _stage(
  WidgetTester tester,
  double width,
  Widget body,
  ApplianceColors colors, {
  TextDirection direction = TextDirection.ltr,
  double scale = 1,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 850);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ApplianceTheme(
        data: ApplianceThemeData(colors: colors),
        child: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: Directionality(
              textDirection: direction,
              child: Align(
                alignment: Alignment.topLeft,
                child: RepaintBoundary(
                  key: _frame,
                  child: ColoredBox(
                    color: const Color(0xFF202025),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: SizedBox(
                        width: 300,
                        child: Align(alignment: Alignment.topLeft, child: body),
                      ),
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
  await tester.pumpAndSettle();
}

void main() {
  final keys = ApplianceColors.light.copyWith(
    well: _outer,
    trough: _outer,
    keyTop: _inner,
    keyBottom: _inner,
    signal: const Color(0xFFEEEEEE),
    shade: const Color(0xFF000000),
  );
  const segments = [
    ApplianceSegment(value: 0, label: 'Day'),
    ApplianceSegment(value: 1, label: 'Week'),
  ];
  for (final width in [390.0, 1440.0]) {
    for (final direction in TextDirection.values) {
      final right = direction == TextDirection.rtl;
      testWidgets(
        'switch, selector and tab in their end detent at $width $direction',
        (t) async {
          await _stage(
            t,
            width,
            ApplianceSwitch(value: false, onChanged: (_) {}),
            keys,
            direction: direction,
          );
          (await _photo(t)).inset(3, 6, right: right);
          for (final bar in <Widget>[
            ApplianceSegmentedButton(
              segments: segments,
              value: 0,
              onChanged: (_) {},
            ),
            ApplianceTabBar(tabs: segments, value: 0, onChanged: (_) {}),
          ]) {
            await _stage(t, width, bar, keys, direction: direction);
            (await _photo(t)).inset(4, 12, right: right);
          }
        },
      );
      testWidgets(
        'a selected radio lamp stays on its circular axis at $width $direction',
        (t) async {
          await _stage(
            t,
            width,
            RadioGroup<int>(
              groupValue: 1,
              onChanged: (_) {},
              child: const ApplianceRadio<int>(value: 1),
            ),
            keys.copyWith(
              keyDownTop: _outer,
              keyDownBottom: _outer,
              signal: _inner,
            ),
            direction: direction,
          );
          final shot = await _photo(t);
          final body = shot.bounds(_Plastic.outer);
          final lamp = shot.bounds(_Plastic.inner);
          expect(body.size, const Size.square(24));
          expect(lamp.width, closeTo(lamp.height, .5));
          expect(lamp.center.dx, closeTo(body.center.dx, .25));
          expect(lamp.center.dy, closeTo(body.center.dy, .25));
        },
      );
      testWidgets(
        'fader cap on the slot and its light inside at $width $direction',
        (t) async {
          await _stage(
            t,
            width,
            SizedBox(
              width: 280,
              child: ApplianceSlider(value: .6, onChanged: (_) {}),
            ),
            keys.copyWith(
              slot: _outer,
              signal: _inner,
              keyTop: const Color(0xFF2222EE),
              keyBottom: const Color(0xFF2222EE),
            ),
            direction: direction,
          );
          (await _photo(t)).inset(2, 3, right: right);
        },
      );
      testWidgets(
        'a toolbar key and a held banner close at $width $direction',
        (t) async {
          await _stage(
            t,
            width,
            ApplianceToolbar(
              children: [
                ApplianceIconButton(
                  icon: const Icon(Icons.edit),
                  semanticLabel: 'Edit',
                  onPressed: () {},
                ),
              ],
            ),
            keys,
            direction: direction,
          );
          (await _photo(t)).inset(3, 13, right: right, bothEnds: true);
          await _stage(
            t,
            width,
            ApplianceBanner(title: 'Saved', onClose: () {}),
            keys.copyWith(keyDownTop: _inner, keyDownBottom: _inner),
            direction: direction,
          );
          final gesture = await t.startGesture(
            t.getCenter(find.bySemanticsLabel('Dismiss')),
          );
          await t.pumpAndSettle();
          (await _photo(t)).inset(8, 12, right: !right);
          await gesture.up();
        },
      );
      for (final scale in [1.0, 2.0]) {
        testWidgets('tag in its field at $width $direction scale $scale', (
          t,
        ) async {
          await _stage(
            t,
            width,
            ApplianceTagInput<String>(
              values: const ['Tea'],
              onChanged: (_) {},
              options: const ['Tea', 'Coffee'],
            ),
            keys,
            direction: direction,
            scale: scale,
          );
          (await _photo(t)).inset(8, 10, right: right);
        });
      }
    }
    // Focus and hover light a menu row's legend; only a held press sinks it.
    testWidgets('selected list and held menu row at $width', (t) async {
      final pressed = keys.copyWith(
        face: _outer,
        keyDownTop: _inner,
        keyDownBottom: _inner,
      );
      await _stage(
        t,
        width,
        const ApplianceListGroup(
          children: [
            ApplianceListTile(title: 'Tea', selected: true),
            ApplianceListTile(title: 'Coffee'),
          ],
        ),
        pressed,
      );
      (await _photo(t)).inset(4, 14, bottom: false, bothEnds: true);
      await _stage(
        t,
        width,
        const ApplianceMenuPlate(
          child: Column(
            children: [
              ApplianceMenuRow(label: 'Tea', states: {WidgetState.pressed}),
              ApplianceMenuRow(label: 'Coffee', states: {}),
            ],
          ),
        ),
        pressed.copyWith(keyTop: _outer),
      );
      (await _photo(t)).inset(4, 12, bottom: false, bothEnds: true);
    });
    testWidgets('full progress light inside its slot at $width', (t) async {
      await _stage(
        t,
        width,
        const SizedBox(
          width: 280,
          child: ApplianceProgressBar(value: 1, height: 12),
        ),
        keys.copyWith(slot: _outer, signal: _inner),
      );
      (await _photo(t)).inset(1, 6, bothEnds: true);
    });
    testWidgets('the toast glass inside its moulded bezel at $width', (
      t,
    ) async {
      late BuildContext page;
      await _stage(
        t,
        width,
        SizedBox(
          height: 140,
          child: ApplianceToaster(
            child: Builder(
              builder: (context) {
                page = context;
                return const SizedBox.expand();
              },
            ),
          ),
        ),
        keys.copyWith(keyTop: _outer, face: _outer, display: _inner),
      );
      final toast = showApplianceToast(page, 'Saved', duration: null);
      await t.pumpAndSettle();
      (await _photo(t)).inset(4, 16, bothEnds: true);
      toast.dismiss();
      await t.pumpAndSettle();
    });
    testWidgets('a held toast close fits the window at $width', (t) async {
      late BuildContext page;
      await _stage(
        t,
        width,
        SizedBox(
          height: 140,
          child: ApplianceToaster(
            child: Builder(
              builder: (context) {
                page = context;
                return const SizedBox.expand();
              },
            ),
          ),
        ),
        keys.copyWith(
          keyTop: const Color(0xFF333333),
          face: const Color(0xFF333333),
          display: _outer,
          signalTop: const Color(0xFFEEEEEE),
          onDisplay: _inner,
        ),
      );
      final toast = showApplianceToast(page, 'Saved', duration: null);
      await t.pumpAndSettle();
      final before = await _photo(t);
      final gesture = await t.startGesture(
        t.getCenter(find.byIcon(LucideIcons.x)),
      );
      await t.pumpAndSettle();
      (await _photo(t)).pressOverGlass(before).inset(4, 12, right: true);
      await gesture.cancel();
      toast.dismiss();
      await t.pumpAndSettle();
    });
  }
}

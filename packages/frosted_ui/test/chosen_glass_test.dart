// A chosen part stays glass and says so with a printed mark: a check, a dot
// or a tick inside it (a switch also moves its knob). Unchosen against
// chosen, pixel for pixel inside the part, by day and by night: some pixels
// change by 3:1 or more (the mark reads at a glance), but only a small share
// of the part does (it is not filled with ink; 0.3.3's ink fills changed
// most of the part).
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/src/frosted/internal/face.dart';

void _none() {}

void _drop(Object? _) {}

final _parts = <String, Widget Function(bool on)>{
  'chip': (on) => FrostedChip('Research', selected: on, onPressed: _none),
  'switch': (on) =>
      FrostedSwitch(value: on, semanticLabel: 'Share', onChanged: _drop),
  'check': (on) =>
      FrostedCheckbox(value: on, semanticLabel: 'Walk', onChanged: _drop),
  'radio': (on) => FrostedRadioGroup<String>(
    labelText: 'Plan',
    value: on ? 'free' : null,
    onChanged: _drop,
    options: const [FrostedRadio('free', 'Free'), FrostedRadio('pro', 'Pro')],
  ),
  'quick amount': (on) => FrostedQuickAmounts(
    options: const [
      FrostedQuickAmount(100, 'A month'),
      FrostedQuickAmount(200, 'Two months'),
    ],
    value: on ? 100 : null,
    onChanged: _drop,
  ),
  'icon picker': (on) => FrostedIconPicker(
    icons: const [
      FrostedIconChoice(FrostedGlyphs.house, 'Home'),
      FrostedIconChoice(FrostedGlyphs.bell, 'Bell'),
    ],
    value: on ? 'Home' : null,
    onChanged: _drop,
  ),
  'icon button': (on) => FrostedIconButton(
    FrostedGlyphs.bell,
    semanticLabel: 'Alerts',
    selected: on,
    onPressed: _none,
  ),
  'menu option': (on) =>
      FrostedOption(label: 'Weekly', selected: on, onPressed: _none),
};

double _lum(ByteData d, int i) {
  double ch(int v) {
    final s = v / 255;
    return s <= .04045
        ? s / 12.92
        : math.pow((s + .055) / 1.055, 2.4).toDouble();
  }

  return .2126 * ch(d.getUint8(i)) +
      .7152 * ch(d.getUint8(i + 1)) +
      .0722 * ch(d.getUint8(i + 2));
}

void main() {
  testWidgets('a chosen well keeps its size, its dot inside its glass', (
    t,
  ) async {
    t.view.physicalSize = const Size(400, 240);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    for (final build in [_parts['quick amount']!, _parts['icon picker']!]) {
      await t.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          builder: (context, page) => FrostedHost(child: page!),
          home: Center(child: SizedBox(width: 360, child: build(true))),
        ),
      );
      await t.pumpAndSettle();
      final wells = find.byType(FrostedPressable);
      expect(wells, findsNWidgets(2));
      Rect face(int i) => t.getRect(
        find.descendant(of: wells.at(i), matching: find.byType(FrostedFace)),
      );
      final dot = t.getRect(
        find.descendant(
          of: wells.at(0),
          matching: find.byWidgetPredicate(
            (w) =>
                w is DecoratedBox &&
                w.decoration is BoxDecoration &&
                (w.decoration as BoxDecoration).shape == BoxShape.circle,
          ),
        ),
      );
      // The chosen well's glass is as wide and tall as the unchosen one's
      // and fills its cell; its dot is printed inside it.
      expect(face(0).size, face(1).size);
      expect(face(0).width, moreOrLessEquals(t.getRect(wells.at(0)).width));
      expect(
        face(0).contains(dot.topLeft),
        isTrue,
        reason: '$dot in ${face(0)}',
      );
      expect(face(0).contains(dot.bottomRight), isTrue);
    }
  });

  for (final mode in Brightness.values) {
    for (final MapEntry(key: name, value: build) in _parts.entries) {
      testWidgets('a chosen $name stays glass with a printed mark '
          '(${mode.name})', (t) async {
        t.view.physicalSize = const Size(400, 240);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
        final stage = GlobalKey();
        final part = GlobalKey();
        Future<ByteData> shoot(bool on) async {
          await t.pumpWidget(
            MaterialApp(
              debugShowCheckedModeBanner: false,
              builder: (context, page) =>
                  FrostedHost(brightness: mode, child: page!),
              home: RepaintBoundary(
                key: stage,
                child: ColoredBox(
                  color: mode == Brightness.light
                      ? const Color(0xFFF1ECF6)
                      : const Color(0xFF27232E),
                  child: Center(
                    child: SizedBox(
                      width: 360,
                      child: Center(
                        child: KeyedSubtree(key: part, child: build(on)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await t.pumpAndSettle();
          final boundary =
              stage.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final image = (await t.runAsync(() => boundary.toImage()))!;
          final data = (await t.runAsync(
            () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
          ))!;
          image.dispose();
          return data;
        }

        final off = await shoot(false);
        final on = await shoot(true);
        final box = t.getRect(find.byKey(part));
        var marked = 0, all = 0;
        for (var y = box.top.floor(); y < box.bottom.ceil(); y++) {
          for (var x = box.left.floor(); x < box.right.ceil(); x++) {
            final i = (y * 400 + x) * 4;
            final a = _lum(off, i), b = _lum(on, i);
            final ratio = (math.max(a, b) + .05) / (math.min(a, b) + .05);
            if (ratio >= 3) marked++;
            all++;
          }
        }
        expect(marked, greaterThanOrEqualTo(8), reason: 'a printed mark');
        // A switch also moves its knob, which changes its two places.
        expect(
          marked / all,
          // A switch's knob is most of its 40-tall target.
          lessThan(name == 'switch' ? .4 : .2),
          reason: '$marked of $all pixels: a mark, not a fill of ink',
        );
      });
    }
  }
}

// The light stands at the top start of the reading direction: the top left in a left-to-right app, the top right in a
// right-to-left one. Every relief takes its light and its shade from it (raised, pressed in, pressed down, focused and
// out of use), so a part right to left is drawn as the mirror of itself left to right, its light and shade mirrored
// with it. Measured at its edges, a raised face right to left is lit outside its right side and shaded outside its
// left, its shadow falling under its left half; a pressed one is shaded inside its right side and lit inside its left.
//
// The words are drawn in the test's own face, a box to a letter (the look's faces are not loaded), so a part's words
// mirror as exactly as its relief.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import 'support.dart' show neumorphicApp;

const _size = Size(600, 720);

/// How many pixels a mirror may differ in, all told: the smoothing at a coloured face's rounded corners can fall a step
/// apart either way round. A relief lit from the wrong side differs in hundreds.
const _smoothing = 8;
final _shot = GlobalKey();
const _spot = Key('spot');

/// A part in the middle of the screen, and what to do to it before it is drawn.
typedef _Case = ({
  Widget Function() part,
  Future<void> Function(WidgetTester tester)? act,
});

Widget _app(Widget part, TextDirection direction, bool dark) => RepaintBoundary(
  key: _shot,
  child: neumorphicApp(
    NeumorphicToaster(child: Center(child: part)),
    direction: direction,
    dark: dark,
    width: _size.width,
  ),
);

/// The screen's pixels, RGBA.
Future<Uint8List> _pixels(WidgetTester tester) async {
  final boundary =
      _shot.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  return (await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = await image.toByteData();
    image.dispose();
    return data!.buffer.asUint8List();
  }))!;
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// A screen's pixels, RGBA, and where its words and glyphs are drawn.
typedef _Shot = ({Uint8List pixels, List<Rect> words});

/// Where the words and glyphs are drawn. A Latin word reads left to right in either direction, so its letters don't
/// mirror; nor does an icon that keeps its own way round.
List<Rect> _words() {
  final words = <Rect>[];
  void visit(RenderObject o) {
    if (o is RenderParagraph || o is RenderEditable) {
      words.add(
        MatrixUtils.transformRect(
          o.getTransformTo(null),
          o.paintBounds,
        ).inflate(1),
      );
    }
    o.visitChildren(visit);
  }

  _shot.currentContext!.findRenderObject()!.visitChildren(visit);
  return words;
}

Future<_Shot> _take(WidgetTester tester) async =>
    (pixels: await _pixels(tester), words: _words());

/// The pixels of [b] that differ from the pixel of [a] at [mirror] (across the screen, or the same place) by more than
/// [tolerance] in a channel, the words of either aside: how many, and the box around them. The tolerance is an edge's
/// smoothing, which can fall a step apart either way round.
(int, Rect) _differing(
  _Shot a,
  _Shot b, {
  bool mirror = true,
  int tolerance = 8,
}) {
  final w = _size.width.toInt(), h = _size.height.toInt();
  final words = [
    ...b.words,
    for (final r in a.words)
      mirror ? Rect.fromLTRB(w - r.right, r.top, w - r.left, r.bottom) : r,
  ];
  var count = 0;
  var box = Rect.zero;
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final here = Offset(x + .5, y + .5);
      if (words.any((r) => r.contains(here))) continue;
      final i = (y * w + x) * 4, j = (y * w + (mirror ? w - 1 - x : x)) * 4;
      for (var c = 0; c < 3; c++) {
        if ((b.pixels[i + c] - a.pixels[j + c]).abs() > tolerance) {
          final pixel = Rect.fromLTWH(x.toDouble(), y.toDouble(), 1, 1);
          box = count == 0 ? pixel : box.expandToInclude(pixel);
          count++;
          break;
        }
      }
    }
  }
  return (count, box);
}

/// The mean brightness of the pixels in [r].
double _brightness(Uint8List px, Rect r) {
  final w = _size.width.toInt();
  var sum = 0.0, n = 0;
  for (var y = r.top.round(); y < r.bottom.round(); y++) {
    for (var x = r.left.round(); x < r.right.round(); x++) {
      final i = (y * w + x) * 4;
      sum += .2126 * px[i] + .7152 * px[i + 1] + .0722 * px[i + 2];
      n++;
    }
  }
  return sum / n;
}

/// The box [part]'s moulding is painted in.
Rect _face(WidgetTester tester, Type part) {
  final surface = find.descendant(
    of: find.byType(part),
    matching: find.byType(NeumorphicSurface),
  );
  return tester.getRect(
    surface.evaluate().isEmpty ? find.byType(part) : surface.first,
  );
}

Future<void> _press(WidgetTester tester) async {
  final gesture = await tester.startGesture(
    tester.getCenter(find.byType(NeumorphicButton)),
  );
  addTearDown(gesture.up);
  await _settle(tester);
}

Future<void> _focus(WidgetTester tester) async {
  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  await _settle(tester);
}

Future<void> _toast(WidgetTester tester) async {
  showNeumorphicToast(tester.element(find.byKey(_spot)), message: 'Saved');
  await _settle(tester);
}

void main() {
  Widget button() => NeumorphicButton('Save', onPressed: () {});
  Widget field() => const SizedBox(
    width: 280,
    child: NeumorphicTextField(labelText: 'Name', initialValue: 'Ada'),
  );
  Widget card() => const SizedBox(
    width: 320,
    child: NeumorphicCard(title: 'Living room', children: [Text('Warm')]),
  );
  Widget slider() => SizedBox(
    width: 280,
    child: NeumorphicSlider(value: .3, label: 'Volume', onChanged: (_) {}),
  );
  Widget on() =>
      NeumorphicSwitch(value: true, label: 'Share', onChanged: (_) {});

  final cases = <String, _Case>{
    'a raised button': (part: button, act: null),
    'a button pressed down': (part: button, act: _press),
    'a focused button': (part: button, act: _focus),
    'a button out of use': (
      part: () => const NeumorphicButton('Save'),
      act: null,
    ),
    'a filled button': (
      part: () => NeumorphicButton.filled('Save', onPressed: () {}),
      act: null,
    ),
    'a field': (part: field, act: null),
    'a focused field': (
      part: () => const SizedBox(
        width: 280,
        child: NeumorphicTextField(labelText: 'Name'),
      ),
      act: _focus,
    ),
    'a field out of use': (
      part: () => const SizedBox(
        width: 280,
        child: NeumorphicTextField(
          labelText: 'Name',
          initialValue: 'Ada',
          enabled: false,
        ),
      ),
      act: null,
    ),
    'a card': (part: card, act: null),
    'a switch, off': (
      part: () =>
          NeumorphicSwitch(value: false, label: 'Share', onChanged: (_) {}),
      act: null,
    ),
    'a switch, on': (part: on, act: null),
    'a focused switch': (part: on, act: _focus),
    'a switch out of use': (
      part: () => const NeumorphicSwitch(value: true, label: 'Share'),
      act: null,
    ),
    'a slider': (part: slider, act: null),
    'a focused slider': (part: slider, act: _focus),
    'a split button': (
      part: () => NeumorphicSplitButton(
        'Save',
        onPressed: () {},
        actions: [NeumorphicSplitAction('Save as copy', onPressed: () {})],
      ),
      act: null,
    ),
    'a segmented button': (
      part: () => NeumorphicSegmentedButton<String>(
        label: 'Plan',
        segments: const [
          NeumorphicButtonSegment('m', 'Month'),
          NeumorphicButtonSegment('y', 'Year'),
        ],
        value: 'y',
        onChanged: (_) {},
      ),
      act: null,
    ),
    'a checkbox': (
      part: () =>
          NeumorphicCheckbox(value: false, label: 'Agree', onChanged: (_) {}),
      act: null,
    ),
    'a checked checkbox': (
      part: () =>
          NeumorphicCheckbox(value: true, label: 'Agree', onChanged: (_) {}),
      act: null,
    ),
    'a calendar and its chosen day': (
      part: () => SizedBox(
        width: 360,
        child: NeumorphicCalendar(
          firstDate: DateTime(2026, 8),
          lastDate: DateTime(2026, 8, 31),
          initialDate: DateTime(2026, 8, 12),
        ),
      ),
      act: null,
    ),
    'a dialog': (
      part: () => NeumorphicDialog(
        title: 'Remove device',
        message: 'The lamp leaves this home.',
        actions: [
          NeumorphicButton('Cancel', onPressed: () {}),
          NeumorphicButton.filled('Remove', onPressed: () {}),
        ],
      ),
      act: null,
    ),
    'a sheet': (
      part: () => SizedBox(
        width: 320,
        height: 360,
        child: NeumorphicSheet(
          title: 'Filters',
          onClose: () {},
          child: const Text('Rooms'),
        ),
      ),
      act: null,
    ),
    'a toast': (part: () => const SizedBox(key: _spot), act: _toast),
  };

  for (final dark in [false, true]) {
    final mode = dark ? 'by night' : 'by day';

    for (final MapEntry(key: name, value: c) in cases.entries) {
      testWidgets('$mode, $name right to left is its mirror, light and '
          'shade too', (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = _size;
        addTearDown(tester.view.reset);
        Future<_Shot> shoot(TextDirection direction) async {
          await tester.pumpWidget(_app(c.part(), direction, dark));
          await _settle(tester);
          await c.act?.call(tester);
          final px = await _take(tester);
          await tester.pumpWidget(const SizedBox());
          await _settle(tester);
          return px;
        }

        final ltr = await shoot(TextDirection.ltr);
        final rtl = await shoot(TextDirection.rtl);
        final (count, box) = _differing(ltr, rtl);
        expect(count, lessThanOrEqualTo(_smoothing), reason: 'in $box');
      });
    }

    for (final (name, part, type, raised, act) in [
      ('a raised button', button, NeumorphicButton, true, null),
      ('a button pressed down', button, NeumorphicButton, false, _press),
      ('a focused button', button, NeumorphicButton, true, _focus),
      ('a field', field, NeumorphicTextField, false, null),
      ('a card', card, NeumorphicCard, true, null),
    ]) {
      for (final direction in TextDirection.values) {
        final right = direction == TextDirection.rtl;
        testWidgets('$mode, ${direction.name}: $name is lit from the top '
            '${right ? 'right' : 'left'}', (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = _size;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(_app(part(), direction, dark));
          await _settle(tester);
          await act?.call(tester);
          final px = await _pixels(tester);
          final f = _face(tester, type);
          final band = f.height / 4;
          // A strip 3 wide beside [edge] (a face's left or right), outside the face or inside it.
          double strip(bool leftEdge, bool outside) {
            final x = leftEdge ? f.left : f.right;
            final (from, to) = (leftEdge == outside)
                ? (x - 4, x - 1)
                : (x + 1, x + 4);
            return _brightness(
              px,
              Rect.fromLTRB(from, f.center.dy - band, to, f.center.dy + band),
            );
          }

          // Raised, the light falls beside the face on the light's side; pressed, the shade falls inside on that side.
          final (lit, shaded) = raised
              ? (strip(!right, true), strip(right, true))
              : (strip(right, false), strip(!right, false));
          expect(
            lit,
            greaterThan(shaded + 1),
            reason: 'lit $lit, shaded $shaded',
          );
          if (raised) {
            // Its shadow falls under its half away from the light.
            final top = f.bottom + 1, bottom = f.bottom + 5;
            final leftHalf = _brightness(
              px,
              Rect.fromLTRB(f.left, top, f.center.dx, bottom),
            );
            final rightHalf = _brightness(
              px,
              Rect.fromLTRB(f.center.dx, top, f.right, bottom),
            );
            final (near, far) = right
                ? (rightHalf, leftHalf)
                : (leftHalf, rightHalf);
            expect(far, lessThan(near), reason: 'far $far, near $near');
          }
          await tester.pumpWidget(const SizedBox());
          await _settle(tester);
        });
      }
    }

    // A press keeps its light through the whole sink and the rise after it: every frame right to left is the mirror
    // of the same frame left to right.
    testWidgets('$mode, a press and its release keep the mirrored light at '
        'every frame', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = _size;
      addTearDown(tester.view.reset);
      Future<List<_Shot>> frames(TextDirection direction) async {
        await tester.pumpWidget(_app(button(), direction, dark));
        await _settle(tester);
        final shots = <_Shot>[];
        final gesture = await tester.startGesture(
          tester.getCenter(find.byType(NeumorphicButton)),
        );
        for (var i = 0; i < 12; i++) {
          await tester.pump(const Duration(milliseconds: 20));
          shots.add(await _take(tester));
        }
        await gesture.up();
        for (var i = 0; i < 12; i++) {
          await tester.pump(const Duration(milliseconds: 20));
          shots.add(await _take(tester));
        }
        await tester.pumpWidget(const SizedBox());
        await _settle(tester);
        return shots;
      }

      final ltr = await frames(TextDirection.ltr);
      final rtl = await frames(TextDirection.rtl);
      // The press moves the relief: its frames are not all one.
      expect(
        _differing(ltr.first, ltr[11], mirror: false).$1,
        greaterThan(100),
      );
      for (var i = 0; i < ltr.length; i++) {
        final (count, box) = _differing(ltr[i], rtl[i]);
        expect(
          count,
          lessThanOrEqualTo(_smoothing),
          reason: 'frame $i, in $box',
        );
      }
    });
  }
}

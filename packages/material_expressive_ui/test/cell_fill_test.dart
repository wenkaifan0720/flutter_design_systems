// design6 P (added 11-11 noon), class (b): a pressed fill covers its whole
// cell. Wherever a part's reach is larger than what it draws (a segment, a
// toggle group's item, a split button's halves, a tab, an accordion's
// head), holding a press on it changes the pixels out to every edge of the
// cell the user sees: the drawn face where there is one, the part's own box
// where there is none. Read from the drawn pixels at each density the look
// ships.
//
// Drawn pixels are the rasterizer's, as a golden's: tagged `goldens`, so
// macOS runs it and Linux CI leaves it out.
@Tags(['goldens'])
library;

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';

import 'gallery_support.dart';

const _capture = ValueKey('capture');
const _paper = Color(0xFFFFFFFF);

Widget _host(Widget child, ExpressiveDensity density) => MaterialApp(
  debugShowCheckedModeBanner: false,
  home: ExpressiveHost(
    light: ExpressiveThemeData.preset(
      'baseline',
      Brightness.light,
    ).copyWith(density: density),
    brightness: Brightness.light,
    child: Align(
      alignment: Alignment.topLeft,
      child: RepaintBoundary(
        key: _capture,
        child: ColoredBox(
          color: _paper,
          child: SizedBox(
            width: 400,
            height: 200,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Align(alignment: Alignment.topLeft, child: child),
            ),
          ),
        ),
      ),
    ),
  ),
);

typedef _Frame = (ByteData, int, int);

Future<_Frame> _grab(WidgetTester tester) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_capture),
  );
  late _Frame frame;
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    try {
      final bytes = (await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!;
      frame = (bytes, image.width, image.height);
    } finally {
      image.dispose();
    }
  });
  return frame;
}

int _diff(_Frame a, _Frame b, int x, int y) {
  final (ab, w, _) = a;
  final (bb, _, _) = b;
  final i = (y * w + x) * 4;
  var d = 0;
  for (var c = 0; c < 3; c++) {
    d += (ab.getUint8(i + c) - bb.getUint8(i + c)).abs();
  }
  return d;
}

/// Whether the pixel at [x], [y] is not the paper.
bool _inked(_Frame f, int x, int y) {
  final (bytes, w, _) = f;
  final i = (y * w + x) * 4;
  return (255 - bytes.getUint8(i)) +
          (255 - bytes.getUint8(i + 1)) +
          (255 - bytes.getUint8(i + 2)) >
      12;
}

/// A part, the label of the node to press, and whether it draws a face (a
/// fill or an outline) the cell is read from.
typedef _Case = (String, Widget, Pattern, bool);

final _cases = <_Case>[
  (
    'segmented button segment',
    ExpressiveSegmentedButton<int>(
      segments: const [
        ExpressiveButtonSegment(0, 'Day'),
        ExpressiveButtonSegment(1, 'Week'),
        ExpressiveButtonSegment(2, 'Month'),
      ],
      value: 0,
      onChanged: (_) {},
    ),
    RegExp('^Week'),
    true,
  ),
  (
    'toggle group item',
    ExpressiveToggleGroup<String>(
      label: 'View',
      segments: const [
        ExpressiveButtonSegment('list', 'List'),
        ExpressiveButtonSegment('grid', 'Grid'),
      ],
      value: 'list',
      onChanged: (_) {},
    ),
    RegExp('^Grid'),
    true,
  ),
  (
    "split button's leading half",
    ExpressiveSplitButton(
      'Send',
      icon: ExpressiveSymbols.send,
      onPressed: () {},
      menu: (context, close) => const SizedBox(width: 120, height: 48),
      menuLabel: 'Send options',
    ),
    RegExp('^Send\$'),
    true,
  ),
  (
    "split button's trailing half",
    ExpressiveSplitButton(
      'Send',
      icon: ExpressiveSymbols.send,
      onPressed: () {},
      menu: (context, close) => const SizedBox(width: 120, height: 48),
      menuLabel: 'Send options',
    ),
    RegExp('^Send options'),
    true,
  ),
  (
    'tab',
    SizedBox(
      width: 352,
      child: ExpressiveTabBar(
        tabs: const [
          ExpressiveTab(label: 'Cards'),
          ExpressiveTab(label: 'Grid'),
          ExpressiveTab(label: 'Media'),
        ],
        selectedIndex: 0,
        onChanged: (_) {},
      ),
    ),
    RegExp('Media'),
    false,
  ),
  (
    "accordion's head",
    const SizedBox(
      width: 352,
      child: ExpressiveDisclosure(
        title: Text('Shipping'),
        child: Text('Ships in two days.'),
      ),
    ),
    RegExp('Shipping'),
    false,
  ),
];

void main() {
  setUpAll(loadExpressiveFonts);
  for (final (density, name) in const [
    (ExpressiveDensity.standard, 'standard'),
    (ExpressiveDensity.comfortable, 'comfortable'),
    (ExpressiveDensity.compact, 'compact'),
  ]) {
    for (final (part, widget, label, faced) in _cases) {
      testWidgets('$part at $name: a held press fills its cell', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(400, 200);
        addTearDown(tester.view.reset);
        final semantics = tester.ensureSemantics();
        await tester.pumpWidget(_host(widget, density));
        await tester.pumpAndSettle();
        final node = find.bySemanticsLabel(label).first;
        final box = tester.getRect(node);
        final idle = await _grab(tester);
        final (_, w, h) = idle;
        // The cell: the node's box; where the part draws a face, its drawn
        // rows within the node's columns (a reach taller than the face
        // grows the node, not what the user sees).
        var cell = box;
        if (faced) {
          int? top;
          int? bottom;
          for (var y = 0; y < h; y++) {
            for (var x = box.left.ceil() + 1; x < box.right.floor() - 1; x++) {
              if (_inked(idle, x, y)) {
                top ??= y;
                bottom = y;
                break;
              }
            }
          }
          expect(top, isNotNull, reason: '$part draws nothing');
          cell = Rect.fromLTRB(
            box.left,
            top!.toDouble(),
            box.right,
            bottom! + 1.0,
          );
        }
        // Held past the press's fade-in, short of a long press (a tooltip's
        // long press would win the arena and clear the pressed state).
        final gesture = await tester.startGesture(box.center);
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 250));
        final pressed = await _grab(tester);
        await gesture.up();
        await tester.pumpAndSettle();
        semantics.dispose();

        // What the press changed, near the cell.
        int? l, t, r, b;
        final x0 = (cell.left - 6).floor().clamp(0, w - 1);
        final x1 = (cell.right + 6).ceil().clamp(0, w - 1);
        final y0 = (cell.top - 6).floor().clamp(0, h - 1);
        final y1 = (cell.bottom + 6).ceil().clamp(0, h - 1);
        for (var y = y0; y <= y1; y++) {
          for (var x = x0; x <= x1; x++) {
            if (_diff(idle, pressed, x, y) > 6) {
              l = l == null || x < l ? x : l;
              r = r == null || x > r ? x : r;
              t = t == null || y < t ? y : t;
              b = b == null || y > b ? y : b;
            }
          }
        }
        expect(l, isNotNull, reason: '$part: a press changes nothing');
        final changed = Rect.fromLTRB(
          l!.toDouble(),
          t!.toDouble(),
          r! + 1.0,
          b! + 1.0,
        );
        // ignore: avoid_print
        print('CELL-FILL $part $name: cell $cell, changed $changed');
        const slack = 2.0;
        expect(
          changed.left <= cell.left + slack &&
              changed.top <= cell.top + slack &&
              changed.right >= cell.right - slack &&
              changed.bottom >= cell.bottom - slack,
          isTrue,
          reason: '$part at $name: the press fills $changed, the cell is $cell',
        );
        // And it is a fill, not a ring: the middle of each edge changed.
        final probes = <Offset>[
          Offset(cell.left + 6, cell.center.dy),
          Offset(cell.right - 7, cell.center.dy),
          Offset(cell.center.dx, cell.top + 3),
          Offset(cell.center.dx, cell.bottom - 4),
        ];
        for (final p in probes) {
          expect(
            _diff(idle, pressed, p.dx.floor(), p.dy.floor()),
            greaterThan(6),
            reason: '$part at $name: unchanged at $p in $cell',
          );
        }
      });
    }
  }
}

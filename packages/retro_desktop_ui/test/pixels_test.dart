// Bevels land on the pixel. A browser snaps a box's edges when it paints and Flutter doesn't, so a 1 px bevel at a fractional
// position blurs into two faint lines. Here a window's frame and pinstripes, the scroll thumb and the gauge are drawn at
// fractional positions, on device scales 1, 2, 3 and a phone's 2.625, and read back a device pixel at a time. Eyes checked the
// same crops, in entry_review.html.
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';
import 'package:retro_desktop_ui/src/retro_desktop/pixels.dart'
    show retroDesktopPinstripes;

import 'support.dart';

const _root = ValueKey('root');
const _part = ValueKey('part');

class _Shot {
  _Shot(this.width, this.bytes, this.scale, this.part);
  final int width;
  final Uint8List bytes;
  final double scale;
  final Rect part;
  int at(int x, int y) {
    final i = (y * width + x) * 4;
    return bytes[i] << 24 |
        bytes[i + 1] << 16 |
        bytes[i + 2] << 8 |
        bytes[i + 3];
  }

  /// Down a column of device pixels, [x] and the range in lp from the part's top left.
  List<int> down(double x, double from, double to) {
    final dx = ((part.left + x) * scale).floor();
    return [
      for (
        var y = ((part.top + from) * scale).floor();
        y < ((part.top + to) * scale).floor();
        y++
      )
        at(dx, y),
    ];
  }

  /// Across a row of device pixels.
  List<int> across(double y, double from, double to) {
    final dy = ((part.top + y) * scale).floor();
    return [
      for (
        var x = ((part.left + from) * scale).floor();
        x < ((part.left + to) * scale).floor();
        x++
      )
        at(x, dy),
    ];
  }
}

/// A gradient's dither is a level or two; a blur is far more.
bool _same(int a, int b) {
  for (var shift = 8; shift <= 24; shift += 8) {
    if ((((a >> shift) & 255) - ((b >> shift) & 255)).abs() > 3) return false;
  }
  return true;
}

/// How long each colour lasts along a line, its ends left out: they may be cut by the line's own ends.
List<int> _inner(List<int> line) {
  final runs = <int>[];
  var n = 0;
  for (var i = 0; i < line.length; i++) {
    n++;
    if (i + 1 == line.length || !_same(line[i + 1], line[i])) {
      runs.add(n);
      n = 0;
    }
  }
  if (runs.length <= 2) return const [];
  return runs.sublist(1, runs.length - 1);
}

String _hex(int v) => v.toRadixString(16).padLeft(8, '0');

/// A line as its runs, for a failure to read: each colour and how long it lasts.
String _runs(List<int> line) {
  final out = <String>[];
  var n = 0;
  for (var i = 0; i < line.length; i++) {
    n++;
    if (i + 1 == line.length || !_same(line[i + 1], line[i])) {
      out.add('${_hex(line[i]).substring(0, 6)}x$n');
      n = 0;
    }
  }
  return out.join(' ');
}

Future<_Shot> _shoot(
  WidgetTester tester,
  double dpr,
  Offset at,
  Size size,
  Widget part, {
  bool boundary = false,
  bool dark = false,
  RetroDesktopMotion motion = const RetroDesktopMotion(),
}) async {
  const view = Size(1100, 500);
  tester.view.physicalSize = view * dpr;
  tester.view.devicePixelRatio = dpr;
  addTearDown(tester.view.reset);
  final theme = RetroDesktopThemeData.preset(
    'classic',
    dark ? Brightness.dark : Brightness.light,
  ).copyWith(motion: motion).atWidth(view.width);
  final placed = SizedBox(
    key: _part,
    width: size.width,
    height: size.height,
    child: part,
  );
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: MediaQueryData(size: view, devicePixelRatio: dpr),
        child: RetroDesktopTheme(
          data: theme,
          child: RepaintBoundary(
            key: _root,
            child: Stack(
              children: [
                Positioned(
                  left: at.dx,
                  top: at.dy,
                  child: boundary ? RepaintBoundary(child: placed) : placed,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  if (motion.state > Duration.zero) await tester.pumpAndSettle();
  final b = tester.renderObject<RenderRepaintBoundary>(find.byKey(_root));
  final rect = tester.getRect(find.byKey(_part));
  return (await tester.runAsync(() async {
    final image = await b.toImage(pixelRatio: dpr);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final shot = _Shot(image.width, bytes!.buffer.asUint8List(), dpr, rect);
    image.dispose();
    return shot;
  }))!;
}

// Active: only the active window has pinstripes.
const _window = RetroDesktopWindowScope(
  active: true,
  compact: false,
  child: RetroDesktopWindow(title: 'x', child: SizedBox(height: 60)),
);

final _list = RetroDesktopListTable(
  total: 400,
  columns: const [RetroDesktopListTableColumn('Name')],
  rows: [
    for (var i = 0; i < 4; i++)
      RetroDesktopListTableRow(title: 'Row $i', note: 'A note'),
  ],
);

const _gauge = RetroDesktopThumbGauge(share: .6);

class _JustStripes extends RetroDesktopPixelPainter {
  const _JustStripes();
  @override
  void paint(RetroDesktopPixelGrid px, Size s) => retroDesktopPinstripes(
    px,
    Offset.zero & s,
    const Color(0xFF000000),
    const Color(0xFFFFFFFF),
  );
  @override
  bool shouldRepaint(_JustStripes o) => false;
}

// Each hair stands a whole number of device pixels: at 2.625 a hair is 3, so 3 lp of bevel never reads as 2.625 and a blur.
int _hair(double dpr) => dpr.round();

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadRetroDesktopFonts();
  });

  const positions = [Offset(10, 20), Offset(10.3, 20.7), Offset(33.5, 41.25)];

  for (final dark in const [false, true]) {
    final mode = dark ? 'dark' : 'light';
    // At a scale of 2 or more a hair is at least 2 device pixels, so a run of 1 is a blur and nothing else.
    for (final dpr in const [2.0, 3.0, 2.625]) {
      for (final at in positions) {
        for (final boundary in const [false, true]) {
          final where =
              '$mode @$dpr at ${at.dx},${at.dy}${boundary ? ' in a layer' : ''}';
          testWidgets('window frame and pinstripes $where', (tester) async {
            final s = await _shoot(
              tester,
              dpr,
              at,
              const Size(300, 120),
              _window,
              boundary: boundary,
              dark: dark,
            );
            final hair = _hair(dpr);
            for (final (what, line) in [
              ('pinstripes, down', s.down(40, 0, 40)),
              ('frame, across', s.across(60, 0, 20)),
              ('frame, up from the foot', s.down(150, 100, 120)),
              ('right edge, across', s.across(60, 280, 300)),
            ]) {
              final thin = _inner(line).where((n) => n < hair);
              expect(thin, isEmpty, reason: '$what: ${_runs(line)}');
            }
          }, tags: const ['goldens']);

          testWidgets('scroll thumb $where', (tester) async {
            final s = await _shoot(
              tester,
              dpr,
              at,
              const Size(320, 300),
              _list,
              boundary: boundary,
              dark: dark,
            );
            final hair = _hair(dpr);
            // Through the thumb, between its grip lines, down from the top arrow.
            final line = s.down(320 - 4, 4, 80);
            expect(
              _inner(line).where((n) => n < hair),
              isEmpty,
              reason: _runs(line),
            );
          }, tags: const ['goldens']);

          testWidgets('gauge $where', (tester) async {
            final s = await _shoot(
              tester,
              dpr,
              at,
              const Size(280, 18),
              _gauge,
              boundary: boundary,
              dark: dark,
            );
            final hair = _hair(dpr);
            final line = s.across(9, 0, 280);
            expect(
              _inner(line).where((n) => n < hair),
              isEmpty,
              reason: _runs(line),
            );
          }, tags: const ['goldens']);
        }
      }
    }

    // At a scale of 1 a hair is one pixel, so a blur shows as a difference from the same part on whole positions.
    for (final at in positions.skip(1)) {
      for (final boundary in const [false, true]) {
        final where =
            '$mode @1 at ${at.dx},${at.dy}${boundary ? ' in a layer' : ''}';
        testWidgets('window as sharp as on whole pixels $where', (
          tester,
        ) async {
          const size = Size(300, 120);
          final whole = await _shoot(
            tester,
            1,
            positions.first,
            size,
            _window,
            dark: dark,
          );
          final off = await _shoot(
            tester,
            1,
            at,
            size,
            _window,
            boundary: boundary,
            dark: dark,
          );
          // From the first pixel it paints: a window at 20.7 snaps to row 21, not 20.
          List<String> fromInk(List<int> line) => [
            ...line.skipWhile((p) => p & 255 == 0).take(15).map(_hex),
          ];
          expect(
            fromInk(off.down(40, -2, 40)),
            fromInk(whole.down(40, -2, 40)),
          );
          expect(
            fromInk(off.across(60, -2, 20)),
            fromInk(whole.across(60, -2, 20)),
          );
        }, tags: const ['goldens']);
      }
    }
  }

  testWidgets(
    'a settled window animation releases its cached device position',
    (tester) async {
      const motion = RetroDesktopMotion(state: Duration(milliseconds: 100));
      const size = Size(300, 120);
      Widget window(Color fill) => RetroDesktopWindowScope(
        active: true,
        compact: false,
        child: RetroDesktopWindow(
          title: 'x',
          style: RetroDesktopStyle(fill: WidgetStatePropertyAll(fill)),
          child: const SizedBox(height: 60),
        ),
      );
      await _shoot(
        tester,
        1,
        const Offset(10, 20),
        size,
        window(const Color(0xffdddddd)),
        motion: motion,
      );
      final whole = await _shoot(
        tester,
        1,
        const Offset(10, 20),
        size,
        window(const Color(0xffeac8a0)),
        motion: motion,
      );
      final moved = await _shoot(
        tester,
        1,
        const Offset(33.5, 41.25),
        size,
        window(const Color(0xffeac8a0)),
        motion: motion,
      );
      List<int> ink(List<int> line) =>
          line.skipWhile((value) => value & 255 == 0).take(15).toList();
      expect(ink(moved.down(40, -2, 40)), ink(whole.down(40, -2, 40)));
      expect(ink(moved.across(60, -2, 20)), ink(whole.across(60, -2, 20)));
    },
    tags: const ['goldens'],
  );

  // A law nothing else reaches: a stripe at the foot of the rect, cut by the rect, is a thinner line than its neighbours.
  for (final dpr in const [1.0, 1.5, 2.0, 2.625, 3.0, 3.5]) {
    testWidgets('every pinstripe is whole @$dpr', (tester) async {
      final s = await _shoot(
        tester,
        dpr,
        const Offset(10.3, 20.7),
        const Size(40, 12),
        const RetroDesktopPixelPaint(painter: _JustStripes()),
      );
      final lines = _inner(s.down(20, -1, 13));
      expect(lines.toSet().length, 1, reason: '$lines');
    }, tags: const ['goldens']);
  }
}

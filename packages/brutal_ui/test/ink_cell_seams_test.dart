// A chosen cell's ink meets the rules beside it with no seam of the page
// between where a row of cells falls on fractions of a pixel: a phone's bar
// split three ways at 2x and 2.625x, the places across a wide window's top, a
// segmented button that spans its column. The rules stand over the cells and
// a chosen cell's fill runs on under them, so a rule of its own colour still
// shows whole beside the ink.
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:brutal_ui/brutal_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const _shot = ValueKey('shot');

// A cell's words, as it sets them (a bar's in capitals).
Finder _words(String words) => find.byWidgetPredicate(
  (w) =>
      w is RichText &&
      w.text.toPlainText().toLowerCase() == words.toLowerCase(),
);
const _wine = Color(0xFF7A1F1F);

double _light(Color c) => (c.r + c.g + c.b) / 3;

class _Pixels {
  _Pixels(this.bytes, this.width, this.height, this.words);

  final ByteData bytes;
  final int width;
  final int height;

  // The words' and icons' boxes in the image's pixels: their strokes stand
  // in the ink on purpose.
  final List<Rect> words;

  double light(int x, int y) {
    final i = (y * width + x) * 4;
    return (bytes.getUint8(i) + bytes.getUint8(i + 1) + bytes.getUint8(i + 2)) /
        765;
  }

  bool skipped(int x, int y) =>
      words.any((r) => r.contains(Offset(x + .5, y + .5)));
}

Future<_Pixels> _grab(WidgetTester tester, double ratio) async {
  final shot = find.byKey(_shot);
  final origin = tester.getTopLeft(shot);
  final boundary = tester.renderObject<RenderRepaintBoundary>(shot);
  final image = (await tester.runAsync(
    () => boundary.toImage(pixelRatio: ratio),
  ))!;
  final bytes = (await tester.runAsync(
    () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
  ))!;
  final (w, h) = (image.width, image.height);
  image.dispose();
  final words = [
    for (final e
        in find
            .descendant(of: shot, matching: find.byType(RichText))
            .evaluate())
      () {
        final box = e.renderObject! as RenderBox;
        final r = (box.localToGlobal(Offset.zero) - origin) & box.size;
        return Rect.fromLTRB(
          r.left * ratio,
          r.top * ratio,
          r.right * ratio,
          r.bottom * ratio,
        ).inflate(2);
      }(),
  ];
  return _Pixels(bytes, w, h, words);
}

// The pixels lighter than the solid tones two pixels deep on both sides of
// them, along rows and columns: the page showing between a chosen cell's fill
// and a rule.
List<String> _seams(_Pixels p, List<double> tones) {
  double? tone(int x, int y) {
    if (p.skipped(x, y)) return null;
    final l = p.light(x, y);
    for (final t in tones) {
      if ((l - t).abs() < .04) return t;
    }
    return null;
  }

  final seams = <String>[];
  void look(int x, int y, int dx, int dy) {
    if (p.skipped(x, y)) return;
    final a = tone(x - 2 * dx, y - 2 * dy);
    final b = tone(x + 2 * dx, y + 2 * dy);
    if (a == null || b == null) return;
    if (tone(x - dx, y - dy) != a || tone(x + dx, y + dy) != b) return;
    if (p.light(x, y) > math.max(a, b) + .1) seams.add('($x, $y)');
  }

  for (var y = 0; y < p.height; y++) {
    for (var x = 2; x < p.width - 2; x++) {
      look(x, y, 1, 0);
    }
  }
  for (var x = 0; x < p.width; x++) {
    for (var y = 2; y < p.height - 2; y++) {
      look(x, y, 0, 1);
    }
  }
  return seams;
}

// The longest run of [rule]'s tone along the row through [chosen]'s words
// that meets the chosen fill's [ink] (a pixel of blend between at most).
int _ruleBesideInk(
  WidgetTester tester,
  _Pixels p,
  double ratio,
  String chosen,
  double ink,
  double rule,
) {
  final origin = tester.getTopLeft(find.byKey(_shot));
  final y = ((tester.getCenter(_words(chosen)).dy - origin.dy) * ratio).floor();
  String kind(int x) {
    if (x < 0 || x >= p.width || p.skipped(x, y)) return '-';
    final l = p.light(x, y);
    if ((l - ink).abs() < .04) return 'i';
    if ((l - rule).abs() < .04) return 'r';
    return '-';
  }

  var longest = 0;
  var x = 0;
  while (x < p.width) {
    if (kind(x) != 'r') {
      x++;
      continue;
    }
    final start = x;
    while (x < p.width && kind(x) == 'r') {
      x++;
    }
    final touches =
        kind(start - 1) == 'i' ||
        kind(start - 2) == 'i' ||
        kind(x) == 'i' ||
        kind(x + 1) == 'i';
    if (touches) longest = math.max(longest, x - start);
  }
  return longest;
}

// The chosen cell's fill, a little before its words.
double _fillAt(WidgetTester tester, _Pixels p, double ratio, String chosen) {
  final origin = tester.getTopLeft(find.byKey(_shot));
  final words = tester.getRect(_words(chosen)).shift(-origin);
  return p.light(
    ((words.left - 6) * ratio).floor(),
    (words.center.dy * ratio).floor(),
  );
}

Future<void> _pump(
  WidgetTester tester,
  Size size,
  double ratio,
  Widget child, {
  TextDirection direction = TextDirection.ltr,
}) async {
  tester.view.physicalSize = size * ratio;
  tester.view.devicePixelRatio = ratio;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Directionality(
        textDirection: direction,
        child: BrutalTheme(
          data: BrutalThemeData.light(),
          child: RepaintBoundary(
            key: _shot,
            child: ColoredBox(color: const Color(0xFFFFFFFF), child: child),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

const _places = [
  BrutalDestination(icon: IconData(0xe900), label: 'Books'),
  BrutalDestination(icon: IconData(0xe901), label: 'Add'),
  BrutalDestination(icon: IconData(0xe902), label: 'Settings'),
];

const _tabs = [
  BrutalTab(IconData(0xe900), 'Books'),
  BrutalTab(IconData(0xe901), 'Add'),
  BrutalTab(IconData(0xe902), 'Settings'),
];

Widget _bar(int chosen, {BrutalStyle? style}) => Align(
  alignment: Alignment.bottomCenter,
  child: BrutalNavigationBar(
    style: style,
    destinations: _places,
    selectedIndex: chosen,
    onDestinationSelected: (_) {},
  ),
);

Widget _segmented(String chosen, {BrutalStyle? style}) => Align(
  alignment: Alignment.topLeft,
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: SizedBox(
      width: 361,
      child: BrutalSegmentedButton<String>(
        expand: true,
        style: style,
        segments: const [
          BrutalSegment(value: 'Day', label: 'Day'),
          BrutalSegment(value: 'Week', label: 'Week'),
          BrutalSegment(value: 'Month', label: 'Month'),
        ],
        value: chosen,
        onChanged: (_) {},
      ),
    ),
  ),
);

void main() {
  final ink = _light(BrutalThemeData.light().colors.ink);

  Future<void> noSeams(
    WidgetTester tester,
    double ratio,
    String chosen, {
    double? rule,
  }) async {
    final p = await _grab(tester, ratio);
    expect(
      (_fillAt(tester, p, ratio, chosen) - ink).abs(),
      lessThan(.04),
      reason: 'the chosen cell is filled with ink',
    );
    expect(_seams(p, [ink, ?rule]), isEmpty);
    if (rule != null) {
      final width = BrutalThemeData.light().borderWidth * ratio;
      expect(
        _ruleBesideInk(tester, p, ratio, chosen, ink, rule),
        greaterThanOrEqualTo(width.floor() - 1),
        reason: 'the rule beside the ink stands whole over it',
      );
    }
  }

  for (final ratio in [2.0, 2.625]) {
    for (final (i, place) in _places.indexed) {
      testWidgets('a phone bar, ${place.label} chosen, at ${ratio}x', (
        tester,
      ) async {
        await _pump(tester, const Size(390, 844), ratio, _bar(i));
        await noSeams(tester, ratio, place.label);
      });
    }
  }

  testWidgets('a phone bar right to left, the first place chosen', (
    tester,
  ) async {
    await _pump(
      tester,
      const Size(390, 844),
      2,
      _bar(0),
      direction: TextDirection.rtl,
    );
    await noSeams(tester, 2, 'Books');
  });

  testWidgets("a phone bar whose rules are a colour of the app's own", (
    tester,
  ) async {
    await _pump(
      tester,
      const Size(390, 844),
      2,
      _bar(1, style: const BrutalStyle(edge: WidgetStatePropertyAll(_wine))),
    );
    await noSeams(tester, 2, 'Add', rule: _light(_wine));
  });

  testWidgets("an app shell's bar on a phone", (tester) async {
    await _pump(
      tester,
      const Size(390, 844),
      2,
      BrutalAppShell(
        tabs: _tabs,
        selectedIndex: 1,
        onDestinationSelected: (_) {},
        child: const SizedBox.expand(),
      ),
    );
    await noSeams(tester, 2, 'Add');
  });

  for (final ratio in [2.0, 2.625]) {
    for (final (i, tab) in _tabs.indexed) {
      testWidgets(
        "an app shell's places across the top, ${tab.label} chosen, at ${ratio}x",
        (tester) async {
          await _pump(
            tester,
            const Size(800, 480),
            ratio,
            BrutalAppShell(
              tabs: _tabs,
              selectedIndex: i,
              onDestinationSelected: (_) {},
              modeForWidth: (_) => RawNavigationMode.top,
              child: const SizedBox.expand(),
            ),
          );
          await noSeams(tester, ratio, tab.label);
        },
      );
    }
  }

  for (final chosen in ['Day', 'Week', 'Month']) {
    testWidgets('a segmented button across its column, $chosen chosen', (
      tester,
    ) async {
      await _pump(tester, const Size(393, 300), 2, _segmented(chosen));
      await noSeams(tester, 2, chosen);
    });
  }

  testWidgets("a segmented button whose rules are a colour of the app's own", (
    tester,
  ) async {
    await _pump(
      tester,
      const Size(393, 300),
      2,
      _segmented(
        'Week',
        style: const BrutalStyle(edge: WidgetStatePropertyAll(_wine)),
      ),
    );
    await noSeams(tester, 2, 'Week', rule: _light(_wine));
  });
}

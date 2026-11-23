// Gloss is lit once, from above and the reading start: a glaze's reflection
// runs from a part's start, so right to left it is the mirror of left to
// right (a lit row, a focused field's lip, a key's glaze). It ran from the
// left in both directions.

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloss_ui/gloss_ui.dart';

final _part = GlobalKey();

Future<List<int>> _paint(
  WidgetTester tester,
  Brightness brightness,
  TextDirection direction,
  Widget Function(GlossColors c) build,
) async {
  tester.view.physicalSize = const Size(400, 200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    Directionality(
      textDirection: direction,
      child: GlossTheme(
        data: brightness == Brightness.light
            ? GlossThemeData.light()
            : GlossThemeData.dark(),
        child: Builder(
          builder: (context) => Center(
            child: RepaintBoundary(
              key: _part,
              child: SizedBox(
                width: 240,
                height: 48,
                child: build(GlossTheme.of(context).colors),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  final boundary =
      _part.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  return (await tester.runAsync<List<int>>(() async {
    final image = await boundary.toImage();
    final bytes = (await image.toByteData())!.buffer.asUint8List();
    image.dispose();
    return bytes.toList();
  }))!;
}

/// How many pixels of [b] differ from [a] mirrored, by more than a hair.
int _unmirrored(List<int> a, List<int> b, {int width = 240}) {
  final rows = a.length ~/ (4 * width);
  var off = 0;
  for (var y = 0; y < rows; y++) {
    for (var x = 0; x < width; x++) {
      final i = 4 * (y * width + x), j = 4 * (y * width + width - 1 - x);
      for (var k = 0; k < 4; k++) {
        if ((a[i + k] - b[j + k]).abs() > 6) {
          off++;
          break;
        }
      }
    }
  }
  return off;
}

void main() {
  final parts = <String, Widget Function(GlossColors c)>{
    'a lit row': (c) => GlossSurface(
      face: GlossFace.pearl(c, radius: 12).copyWith(focus: c.focus),
    ),
    "a focused field's lip": (c) => GlossSurface(
      face: GlossFace.well(c, radius: GlossMetrics.fieldRadius).copyWith(
        lift: -1,
        edge: c.focus,
        glow: glossFocusGlow(c),
        focus: c.focus,
      ),
    ),
    "a key's glaze": (c) => const GlossGlazeHighlight(
      focused: true,
      radius: 12,
      child: SizedBox.expand(),
    ),
  };
  for (final brightness in Brightness.values) {
    for (final MapEntry(key: name, value: build) in parts.entries) {
      testWidgets('$name mirrors right to left (${brightness.name})', (
        tester,
      ) async {
        final ltr = await _paint(tester, brightness, TextDirection.ltr, build);
        final rtl = await _paint(tester, brightness, TextDirection.rtl, build);
        // Left to right it is lit from one side: the test can see it.
        expect(_unmirrored(ltr, ltr), greaterThan(40));
        // Right to left it is the mirror, but for a hair of antialiasing
        // (under 1% of the part).
        expect(_unmirrored(ltr, rtl), lessThan(ltr.length ~/ 4 ~/ 100));
      });
    }
  }
}

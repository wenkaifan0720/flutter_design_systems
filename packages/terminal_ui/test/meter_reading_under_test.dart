// A meter too narrow for its label, a cell of its bar and its reading on
// one line (a phone at large text) puts the reading on the line under them,
// whole, rather than running past its edge.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

import 'faces.dart';

Future<void> _meter(WidgetTester tester, double scale, double width) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(390, 844),
          textScaler: TextScaler.linear(scale),
        ),
        child: TermTheme(
          data: TermThemeData.dark(),
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: width,
              child: const TermMeter(
                value: 2 / 12,
                label: '2026',
                reading: '2 of 12 done',
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

bool _whole(WidgetTester tester, String words) {
  final p = tester.renderObject<RenderParagraph>(find.text(words));
  return !p.didExceedMaxLines &&
      p.size.width + 0.5 >= p.getMaxIntrinsicWidth(double.infinity);
}

void main() {
  setUpAll(loadFaces);

  testWidgets("at 200% in a phone's pane the reading goes under, whole", (
    tester,
  ) async {
    await _meter(tester, 2, 282);
    expect(tester.takeException(), isNull);
    expect(_whole(tester, '2026'), isTrue);
    expect(_whole(tester, '2 of 12 done'), isTrue);
    final reading = tester.getRect(find.text('2 of 12 done'));
    expect(reading.right, lessThanOrEqualTo(282.5));
    expect(
      reading.top,
      greaterThanOrEqualTo(tester.getRect(find.text('2026')).bottom - 0.5),
    );
    // The bar still shows beside the label.
    expect(
      tester
          .getSize(
            find
                .descendant(
                  of: find.byType(TermMeter),
                  matching: find.byType(CustomPaint),
                )
                .last,
          )
          .width,
      greaterThan(0),
    );
  });

  testWidgets('with room, label, bar and reading share one line', (
    tester,
  ) async {
    await _meter(tester, 1, 282);
    expect(
      tester.getCenter(find.text('2 of 12 done')).dy,
      closeTo(tester.getCenter(find.text('2026')).dy, 0.5),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('a screen reader hears the label and the reading either way', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _meter(tester, 2, 282);
    expect(
      tester.getSemantics(find.byType(TermMeter)),
      isSemantics(label: '2026', value: '2 of 12 done'),
    );
    semantics.dispose();
  });
}

// A section header keeps to one line, and takes two at a larger text size, as
// a list row's title does: at 200% on a phone a long header is no longer cut
// to its first words.
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keycap_ui/keycap_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

const _title = 'Checkboxes, radios, switches';

Future<RenderParagraph> _show(
  WidgetTester tester, {
  required double scale,
  required TextDirection direction,
}) async {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = const Size(390 * 2, 844 * 2);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) => MediaQuery.withClampedTextScaling(
        minScaleFactor: scale,
        maxScaleFactor: scale,
        child: KeycapHost(brightness: Brightness.light, child: app!),
      ),
      home: Directionality(
        textDirection: direction,
        child: const Padding(
          padding: EdgeInsets.all(24),
          child: Column(children: [KeycapSectionHeader(_title)]),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return tester.renderObject<RenderParagraph>(find.text(_title.toUpperCase()));
}

void main() {
  setUpAll(keycapLoadFonts);

  for (final direction in TextDirection.values) {
    testWidgets('at 2x text a long header is not cut, ${direction.name}', (
      tester,
    ) async {
      final header = await _show(tester, scale: 2, direction: direction);
      expect(header.didExceedMaxLines, isFalse);
    });
  }

  testWidgets('at the usual text size a header keeps to one line', (
    tester,
  ) async {
    final header = await _show(tester, scale: 1, direction: TextDirection.ltr);
    expect(header.maxLines, 1);
    expect(header.didExceedMaxLines, isFalse);
  });
}

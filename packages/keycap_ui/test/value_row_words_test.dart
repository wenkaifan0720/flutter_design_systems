// A row that opens a choice never breaks its title inside a word: beside its
// value cap the title keeps at least its longest word, and when the two don't
// fit (large text on a phone) the cap goes under the title. At the usual
// text size the cap stays at the row's end.
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keycap_ui/keycap_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

Future<void> _show(
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              KeycapListTile(
                leading: const Icon(LucideIcons.fileOutput),
                title: 'Export as',
                value: 'Markdown',
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(keycapLoadFonts);

  for (final direction in TextDirection.values) {
    testWidgets('at 2x text the title keeps its words, ${direction.name}', (
      tester,
    ) async {
      await _show(tester, scale: 2, direction: direction);
      final title = tester.renderObject<RenderParagraph>(
        find.text('Export as'),
      );
      expect(
        title.size.width,
        greaterThanOrEqualTo(title.getMinIntrinsicWidth(double.infinity)),
        reason: 'a word of the title is broken',
      );
      final words = tester.getRect(find.text('Export as'));
      final cap = tester.getRect(find.byType(KeycapValueCap));
      expect(words.overlaps(cap), isFalse);
      final row = tester.getRect(find.byType(KeycapListTile));
      expect(
        row.contains(cap.topLeft) && row.contains(cap.bottomRight),
        isTrue,
      );
    });
  }

  testWidgets('at 1x the cap stands at the end, beside the title', (
    tester,
  ) async {
    await _show(tester, scale: 1, direction: TextDirection.ltr);
    final words = tester.getRect(find.text('Export as'));
    final cap = tester.getRect(find.byType(KeycapValueCap));
    expect(cap.left, greaterThan(words.right));
    expect(cap.center.dy, moreOrLessEquals(words.center.dy, epsilon: 2));
    final row = tester.getRect(find.byType(KeycapListTile));
    expect(row.right - cap.right, moreOrLessEquals(16, epsilon: 0.5));
  });
}

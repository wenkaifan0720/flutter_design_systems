// A tag's glyph grows with its word, at any text size: at twice the text
// it stands twice as tall. It kept 14 px beside a word twice its size.
import 'package:clay_ui/clay_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets('a tag\'s glyph at ${(scale * 100).round()}% text', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, app) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: ClayTheme(
              data: ClayThemeData.clay(Brightness.light),
              child: app!,
            ),
          ),
          home: const Center(child: ClayTag('Reading', icon: IconData(0xe000))),
        ),
      );
      expect(tester.getSize(find.byType(Icon)).height, 14 * scale);
    });
  }
}

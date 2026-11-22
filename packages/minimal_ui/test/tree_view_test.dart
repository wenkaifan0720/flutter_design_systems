import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

import 'support/page_host.dart';

void main() {
  group('MinimalTreeView', () {
    testWidgets('rows stand in the ink until one is selected', (tester) async {
      final t = MinimalThemeData.preset('standard', Brightness.light);
      await tester.pumpWidget(
        pageApp(
          MinimalTreeView<String>(
            roots: const ['lib', 'test'],
            childrenOf: (_) => const <String>[],
            labelOf: (node) => node,
          ),
        ),
      );
      Color? ink(String row) =>
          tester.widget<Text>(find.text(row)).style?.color;
      expect(ink('lib'), t.foreground);
      expect(ink('test'), t.foreground);
      await tester.tap(find.text('lib'));
      await tester.pumpAndSettle();
      expect(ink('lib'), t.foreground);
      expect(ink('test'), t.mutedForeground);
    });
  });
}

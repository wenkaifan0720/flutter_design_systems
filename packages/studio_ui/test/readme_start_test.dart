// The README's first Dart block is a whole app that compiles and runs:
// readme_start.dart holds it word for word.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:studio_ui/studio_ui.dart';

import 'readme_start.dart' as start;

// The code alone, whitespace aside.
String _code(String source) =>
    source.substring(source.indexOf('import ')).replaceAll(RegExp(r'\s+'), '');

void main() {
  test('the README opens with readme_start.dart, in 12 lines or fewer', () {
    final readme = File('README.md').readAsStringSync();
    final open = readme.indexOf('```dart\n') + '```dart\n'.length;
    final block = readme.substring(open, readme.indexOf('```', open));
    expect(
      _code(block),
      _code(File('test/readme_start.dart').readAsStringSync()),
    );
    expect(block.trim().split('\n'), hasLength(lessThanOrEqualTo(12)));
  });

  testWidgets('the start runs: its glass stands in the theme', (tester) async {
    start.main();
    await tester.pump();
    expect(find.text('Rooms that sound right, 38 min.'), findsOneWidget);
    final theme = StudioTheme.of(tester.element(find.byType(StudioDisplay)));
    expect(theme.colors.indicator, StudioThemeData.light().colors.indicator);
  });
}

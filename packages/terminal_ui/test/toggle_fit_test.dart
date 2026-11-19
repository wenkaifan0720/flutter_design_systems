// A toggle group puts its choices on one line only where their words, as
// set, fit it: in its own face they fit as their cells say; in a face
// whose letters are wider than the grid's (Flutter's test font here, a
// fallback script in an app) they wrap instead of running past the line.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

import 'faces.dart';

void main() {
  setUpAll(loadFaces);

  // Stint's form at 1440 and 200% text: a 439 px column.
  Future<void> pump(WidgetTester tester, TermFace face) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(1440, 900),
            textScaler: TextScaler.linear(2),
          ),
          child: TermTheme(
            data: TermThemeData.light(face: face),
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 439,
                child: TermToggleGroup<String>(
                  semanticLabel: 'Priority',
                  options: const ['Low', 'Normal', 'High'],
                  selected: const {'High'},
                  labelOf: (v) => v,
                  onSelectionChanged: (_) {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('in its own face the three fit one line at 200%', (tester) async {
    await pump(tester, TermFace.jetBrainsMono);
    expect(tester.takeException(), isNull);
    final group = find.byType(TermToggleGroup<String>);
    expect(
      find.descendant(of: group, matching: find.byType(Wrap)),
      findsNothing,
    );
    final tops = {
      for (final label in ['Low', 'Normal', 'High'])
        tester.getTopLeft(find.text(label)).dy,
    };
    expect(tops, hasLength(1));
  });

  testWidgets('in a face wider than the grid they wrap, never overflow', (
    tester,
  ) async {
    // A family no test loads: Flutter's test font, each glyph 1 em wide
    // where the grid counts 0.6.
    await pump(tester, const TermFace(family: 'NotLoaded', advance: 0.6));
    expect(tester.takeException(), isNull);
    final group = find.byType(TermToggleGroup<String>);
    expect(find.descendant(of: group, matching: find.byType(Wrap)), findsOne);
    final box = tester.getRect(group);
    for (final label in ['Low', 'Normal', 'High']) {
      final r = tester.getRect(find.text(label));
      expect(r.right, lessThanOrEqualTo(box.right + 0.01), reason: label);
    }
  });
}

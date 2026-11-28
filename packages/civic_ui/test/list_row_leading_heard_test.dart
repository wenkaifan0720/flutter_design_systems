// A list row's leading control is heard: a checkbox before a row's words
// keeps its checked state, its tap and its focus. Since 0.8.0 the row had
// left every leading out of the screen reader's tree, so a checkbox there
// went unheard. In a row of words the row takes the checkbox's state and
// tap, as a checkbox list tile does; in a row that goes somewhere the
// checkbox keeps a node of its own beside the row's. A glyph or a monogram
// still stays out of the row's name, which it would only repeat.
import 'package:civic_ui/civic_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

Future<void> _show(WidgetTester tester, Widget row) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, child) =>
          CivicHost(child: child ?? const SizedBox.shrink()),
      home: CivicScreen(
        body: CivicPageBody(title: 'Today', children: [row]),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Widget _box(bool value, ValueChanged<bool?> onChanged) => SizedBox(
  width: CivicMetrics.box,
  child: CivicCheckbox(value: value, onChanged: onChanged),
);

void main() {
  testWidgets("a row of words takes its checkbox's state and tap", (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    var ticks = 0;
    await _show(
      tester,
      CivicListRow(
        leading: _box(true, (_) => ticks++),
        title: const Text('Water the plants'),
        subtitle: const Text('Home'),
      ),
    );
    final row = tester.getSemantics(find.text('Water the plants'));
    expect(
      row,
      isSemantics(hasCheckedState: true, isChecked: true, hasTapAction: true),
    );
    expect(row.label, contains('Water the plants'));
    row.owner!.performAction(row.id, SemanticsAction.tap);
    await tester.pumpAndSettle();
    expect(ticks, 1);
    handle.dispose();
  });

  for (final label in [null, 'Water the plants, Home']) {
    testWidgets('a row that goes somewhere keeps its checkbox apart'
        '${label == null ? '' : ' (its own name)'}', (tester) async {
      final handle = tester.ensureSemantics();
      var ticks = 0, opened = 0;
      await _show(
        tester,
        CivicListRow(
          leading: _box(false, (_) => ticks++),
          title: const Text('Water the plants'),
          subtitle: const Text('Home'),
          semanticLabel: label,
          onTap: () => opened++,
        ),
      );
      final box = tester.getSemantics(find.byType(CivicCheckbox));
      expect(
        box,
        isSemantics(
          hasCheckedState: true,
          isChecked: false,
          hasTapAction: true,
          isFocusable: true,
        ),
      );
      final row = tester.getSemantics(find.text('Water the plants'));
      expect(row.id, isNot(box.id));
      expect(row, isSemantics(isLink: true, hasTapAction: true));
      expect(row.label, contains('Water the plants'));
      expect('Water the plants'.allMatches(row.label), hasLength(1));
      box.owner!.performAction(box.id, SemanticsAction.tap);
      await tester.pumpAndSettle();
      expect((ticks, opened), (1, 0));
      row.owner!.performAction(row.id, SemanticsAction.tap);
      await tester.pumpAndSettle();
      expect((ticks, opened), (1, 1));
      handle.dispose();
    });
  }

  testWidgets('a glyph and a monogram stay out of the name', (tester) async {
    final handle = tester.ensureSemantics();
    await _show(
      tester,
      const Column(
        children: [
          CivicListRow(
            leading: Icon(LucideIcons.clock, semanticLabel: 'Clock'),
            title: Text('Opening hours'),
          ),
          CivicListRow(
            leading: CivicAvatar(name: 'Ana Ruiz'),
            title: Text('Ana Ruiz'),
          ),
        ],
      ),
    );
    expect(
      tester.getSemantics(find.text('Opening hours')).label,
      isNot(contains('Clock')),
    );
    expect(
      'Ana Ruiz'.allMatches(tester.getSemantics(find.text('Ana Ruiz')).label),
      hasLength(1),
    );
    handle.dispose();
  });
}

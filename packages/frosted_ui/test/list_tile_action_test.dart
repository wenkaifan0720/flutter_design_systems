// A list row's own control (its menu button) stands on the chosen row's
// plate, unbroken, yet stays its own target and its own node: a press on it
// is not the row's press, and the row's merged words don't swallow it.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/frosted_host.dart';
import 'package:frosted_ui/src/frosted/internal/face.dart';

void main() {
  for (final brightness in Brightness.values) {
    final t = FrostedThemeData.preset('opal', brightness);

    testWidgets(
      'a chosen row\'s plate runs under its action (${brightness.name})',
      (tester) async {
        var opened = 0, menus = 0;
        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            builder: (context, page) => FrostedHost(
              theme: t,
              darkTheme: t,
              brightness: brightness,
              child: page!,
            ),
            home: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: SizedBox(
                  width: 420,
                  child: FrostedListTile(
                    title: 'Write the brief',
                    meta: 'Due Friday',
                    trailing: const Text('2h'),
                    selected: true,
                    onPressed: () => opened++,
                    action: FrostedIconButton(
                      FrostedGlyphs.more,
                      label: 'Task actions',
                      onPressed: () => menus++,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        final plate = find.byWidgetPredicate(
          (w) => w is FrostedFace && w.material == FrostedMaterial.paint,
        );
        expect(plate, findsOneWidget);
        final button = find.byType(FrostedIconButton);
        final plateBox = tester.getRect(plate);
        final buttonBox = tester.getRect(button);
        expect(
          plateBox.left <= buttonBox.left && plateBox.right >= buttonBox.right,
          isTrue,
          reason: 'plate $plateBox, action $buttonBox',
        );

        await tester.tap(button);
        await tester.tap(find.text('Write the brief'));
        expect((menus, opened), (1, 1));

        final semantics = tester.ensureSemantics();
        final row = tester.getSemantics(find.text('Write the brief'));
        expect(row.label, isNot(contains('Task actions')));
        expect(tester.getSemantics(button).label, contains('Task actions'));
        semantics.dispose();
      },
    );
  }
}

// Two of the ink act's faces: out of use it is faint glass, its word in the quiet ink at full strength, never the ink
// pill dimmed (its white word fell under 3:1 on the dawn, the user, 11-18); and a destructive act is glass tinted with
// the danger hue, its word holding 4.5:1 on the tint. Every preset, day and night.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/frosted_host.dart';
import 'package:frosted_ui/src/frosted/internal/dim.dart';
import 'package:frosted_ui/src/frosted/internal/face.dart';

Future<void> _pump(WidgetTester tester, String preset, Brightness b) async {
  tester.view.physicalSize = const Size(390, 400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, page) => FrostedHost(
        light: FrostedThemeData.preset(preset, Brightness.light),
        dark: FrostedThemeData.preset(preset, Brightness.dark),
        brightness: b,
        child: page!,
      ),
      home: Material(
        type: MaterialType.transparency,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 16,
            children: [
              const FrostedButton('Save', onPressed: null),
              FrostedButton.destructive('Delete', onPressed: () {}),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final preset in FrostedThemeData.presets) {
    for (final b in Brightness.values) {
      testWidgets('$preset ${b.name}: an ink act out of use is faint glass '
          'with a readable word; a destructive act holds 4.5:1', (
        tester,
      ) async {
        await _pump(tester, preset, b);
        final t = FrostedThemeData.preset(preset, b);
        final ground = t.colorScheme.background.withValues(alpha: 1);
        // Out of use: the quiet ink, not dimmed again.
        final save = tester.widget<Text>(find.text('Save'));
        expect(save.style!.color, t.colorScheme.textSecondary);
        expect(
          tester
              .widgetList<FrostedDim>(
                find.ancestor(
                  of: find.text('Save'),
                  matching: find.byType(FrostedDim),
                ),
              )
              .where((d) => d.off),
          isEmpty,
          reason: 'its word at full strength',
        );
        expect(
          FrostedThemeData.contrast(t.colorScheme.textSecondary, ground),
          greaterThanOrEqualTo(4.5),
        );
        // Faint: the glass of a glass act out of use, a pane dimmed, under
        // the word (which no dim reaches).
        final pane = find.descendant(
          of: find.byWidgetPredicate((w) => w is FrostedDim && w.off),
          matching: find.byWidgetPredicate(
            (w) => w is FrostedFace && w.material == FrostedMaterial.pane,
          ),
        );
        expect(pane, findsWidgets);
        expect(
          tester
              .getRect(find.text('Save'))
              .overlaps(tester.getRect(pane.first)),
          isTrue,
        );
        // Destructive: the danger ink on the tint over the page.
        final delete = tester.widget<Text>(find.text('Delete'));
        final tint = Color.alphaBlend(t.colorScheme.dangerSubtle, ground);
        expect(
          delete.style!.color,
          frostedDangerInk(t, t.colorScheme.dangerSubtle),
        );
        expect(
          FrostedThemeData.contrast(delete.style!.color!, tint),
          greaterThanOrEqualTo(4.5),
        );
      });
    }
  }
}

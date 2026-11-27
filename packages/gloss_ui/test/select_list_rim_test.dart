// An open select's rows scroll inside its rim: the list's viewport stands
// 4 px inside the panel all round, cut concentric with it, so a row scrolled
// past the top or the bottom never shows its words in the panel's edge.
import 'package:flutter_test/flutter_test.dart';
import 'package:gloss_ui/gloss_ui.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  setUpAll(glossLoadFonts);

  testWidgets('a long open list scrolls inside the rim', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) =>
            GlossHost(brightness: Brightness.light, child: child!),
        home: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: 360,
            child: GlossSelect<int>(
              key: const Key('select'),
              labelText: 'Shelf',
              value: 0,
              items: [
                for (var i = 0; i < 30; i++)
                  GlossSelectItem(value: i, label: 'Shelf ${i + 1}'),
              ],
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('select')));
    await tester.pumpAndSettle();
    final scroll = find.byType(SingleChildScrollView).last;
    final panel = find
        .ancestor(of: scroll, matching: find.byType(GlossSurface))
        .first;
    final p = tester.getRect(panel);
    final v = tester.getRect(scroll);
    expect(v.left - p.left, closeTo(4, 0.01));
    expect(p.right - v.right, closeTo(4, 0.01));
    expect(v.top - p.top, closeTo(4, 0.01));
    expect(p.bottom - v.bottom, closeTo(4, 0.01));
    // Scrolled a little, the row under the top passes behind the clip, which
    // follows the panel's corner less the inset.
    await tester.drag(scroll, const Offset(0, -30));
    await tester.pumpAndSettle();
    final clip = tester.widget<ClipRRect>(
      find.ancestor(of: scroll, matching: find.byType(ClipRRect)).first,
    );
    expect(
      clip.borderRadius,
      BorderRadius.circular(
        GlossThemeData.defaultShapeScheme.corners.medium - 4,
      ),
    );
  });
}

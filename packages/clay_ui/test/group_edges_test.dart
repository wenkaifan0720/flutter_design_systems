// A group's header, the grooves between its rows and its footer start where
// its rows' words do, and where a form's labels and its fields' words start:
// one edge down a page. The header, the grooves and the footer stood 4 in
// from the words.
import 'package:clay_ui/clay_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

void main() {
  setUpAll(clayLoadFonts);
  for (final direction in TextDirection.values) {
    testWidgets('one edge down a page, ${direction.name}', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => Directionality(
            textDirection: direction,
            child: ClayHost(child: child!),
          ),
          home: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: 358,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClayGroup(
                    header: 'Morning',
                    footer: 'Two habits',
                    children: [
                      ClayListTile(title: 'Drink water', onTap: () {}),
                      ClayListTile(title: 'Stretch', onTap: () {}),
                    ],
                  ),
                  const ClayTextField(labelText: 'Name'),
                ],
              ),
            ),
          ),
        ),
      );
      final rtl = direction == TextDirection.rtl;
      double start(Finder f) =>
          rtl ? tester.getTopRight(f).dx : tester.getTopLeft(f).dx;
      final words = start(find.text('Drink water'));
      expect(start(find.text('Morning')), words);
      expect(start(find.text('Two habits')), words);
      expect(start(find.text('Name')), words);
      final groove = tester.widget<ClayGroove>(find.byType(ClayGroove));
      final slab = start(find.byType(ClayGroup));
      expect(slab + (rtl ? -1 : 1) * groove.indent, words);
      expect(groove.endIndent, groove.indent);
    });
  }
}

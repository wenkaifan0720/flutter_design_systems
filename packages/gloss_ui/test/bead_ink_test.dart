// The chevron on a pearl bead (a select's, a combobox's, a disclosure's)
// reads at 3:1 on the bead's crown, its lightest glaze, by day and by
// night: by night the slate bead takes the pearl's own ink, not the grey of
// supporting words, which melts into it.
// ignore_for_file: avoid_relative_lib_imports
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloss_ui/gloss_ui.dart';

import '../example/lib/kit_gallery/kit.dart';

double _contrast(Color a, Color b) {
  final (x, y) = (a.computeLuminance(), b.computeLuminance());
  return (x > y ? x + 0.05 : y + 0.05) / (x > y ? y + 0.05 : x + 0.05);
}

void main() {
  setUpAll(glossLoadFonts);

  for (final brightness in Brightness.values) {
    testWidgets('a pearl bead\'s chevron reads at 3:1 (${brightness.name})', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        kitApp(
          brightness: brightness,
          home: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: 360,
              child: Column(
                children: [
                  GlossSelect<String>(
                    items: const [
                      GlossSelectItem(value: 'a', label: 'Open studio'),
                      GlossSelectItem(value: 'b', label: 'Field guide'),
                    ],
                    value: 'a',
                    onChanged: (_) {},
                  ),
                  const GlossCombobox<String>(
                    options: ['Open studio', 'Field guide'],
                  ),
                  const GlossDisclosure(
                    title: 'Opening hours',
                    child: Text('Nine to five'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final crown = GlossFace.pearl(
        GlossTheme.of(tester.element(find.byType(Column).first)).colors,
      ).top;
      final chevrons = tester
          .widgetList(
            find.byWidgetPredicate(
              (w) => w.runtimeType.toString() == 'GlossChevron',
            ),
          )
          .map((w) => (w as dynamic).color as Color)
          .toList();
      expect(chevrons, hasLength(3));
      for (final ink in chevrons) {
        expect(_contrast(ink, crown), greaterThanOrEqualTo(3));
      }
    });
  }
}

// A chosen row's dim words read at 4.5:1 on the shade under them where its
// pane is not the active one (the bar is the shade there, not the inverse
// bar), with an action or without, in every palette, by day and by night.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

import 'faces.dart';

void main() {
  setUpAll(loadFaces);

  const meta = 'Open studio · Nov 20';

  for (final id in TermThemeData.palettes.map((p) => p.id)) {
    for (final b in Brightness.values) {
      for (final withAction in [false, true]) {
        final where = '${withAction ? 'with' : 'without'} an action';
        testWidgets('$id, ${b.name}, $where: the dim words read on the shade', (
          tester,
        ) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = const Size(900, 200);
          addTearDown(tester.view.reset);
          final theme = TermThemeData.preset(id, b);
          await tester.pumpWidget(
            MaterialApp(
              home: TermTheme(
                data: theme,
                child: ColoredBox(
                  color: theme.background,
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: SizedBox(
                      width: 640,
                      child: TermPaneScope(
                        active: false,
                        child: TermListTile(
                          title: const Text('proof the studio map'),
                          subtitle: const Text(meta),
                          selected: true,
                          onTap: () {},
                          action: withAction
                              ? TermIconButton(
                                  glyph: '⋯',
                                  semanticLabel: 'task actions',
                                  onPressed: () {},
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final words =
              (tester.renderObject<RenderParagraph>(find.text(meta)).text
                      as TextSpan)
                  .style!
                  .color!;
          // The shade a chosen row sits on, on whole 8-bit channels, as the
          // screen draws it.
          final drawn = Color(termRowShade(theme).toARGB32());
          expect(
            RawPalette.contrastRatio(words, drawn),
            greaterThanOrEqualTo(4.5),
          );
        });
      }
    }
  }
}

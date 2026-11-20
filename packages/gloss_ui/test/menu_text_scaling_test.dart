import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloss_ui/gloss_ui.dart';

void main() {
  setUpAll(glossLoadFonts);

  for (final kind in ['menu', 'select', 'combobox']) {
    for (final direction in TextDirection.values) {
      testWidgets(
        '$kind allows room for descenders at 200%, ${direction.name}',
        (tester) async {
          const label = 'Duplicate';
          final control = switch (kind) {
            'menu' => GlossMenuList(
              items: [GlossMenuItem(label: label, onPressed: () {})],
              close: () {},
            ),
            'select' => GlossSelect<String>(
              value: null,
              hint: 'Actions',
              items: const [GlossSelectItem(value: 'copy', label: label)],
              onChanged: (_) {},
            ),
            _ => GlossCombobox<String>(
              label: 'Actions',
              options: const [label],
              onSelected: (_) {},
            ),
          };
          await tester.pumpWidget(
            MaterialApp(
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(2)),
                child: Directionality(
                  textDirection: direction,
                  child: GlossHost(brightness: Brightness.light, child: child!),
                ),
              ),
              home: Align(
                alignment: Alignment.topCenter,
                child: SizedBox(width: 320, child: control),
              ),
            ),
          );
          if (kind == 'select') {
            await tester.tap(find.text('Actions'));
          } else if (kind == 'combobox') {
            await tester.enterText(find.byType(EditableText), 'Dup');
          }
          await tester.pumpAndSettle();

          void checkLine() {
            final words = find.text(label);
            final line = tester.renderObject<RenderParagraph>(words);
            final naturalHeight = line.getMaxIntrinsicHeight(line.size.width);
            expect(line.size.height, greaterThanOrEqualTo(naturalHeight));
            final row = tester.getRect(
              find
                  .ancestor(
                    of: words,
                    matching: find.byType(AnimatedGlossSurface),
                  )
                  .first,
            );
            final glyphs = line
                .getBoxesForSelection(
                  const TextSelection(
                    baseOffset: 0,
                    extentOffset: label.length,
                  ),
                )
                .single
                .toRect();
            expect(
              line.localToGlobal(glyphs.bottomCenter).dy,
              lessThanOrEqualTo(row.bottom),
            );
            expect(line.didExceedMaxLines, isFalse);
          }

          checkLine();
          await tester.sendKeyEvent(
            kind == 'menu'
                ? LogicalKeyboardKey.tab
                : LogicalKeyboardKey.arrowDown,
          );
          await tester.pumpAndSettle();
          checkLine();
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}

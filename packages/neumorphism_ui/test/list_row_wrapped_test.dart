// A row whose title wraps keeps its status and its key on one line: beside three lines both stand on the title's
// first line, beside fewer both stand on the words' middle. A short status ('Done') stands beside the words however
// many lines they take.

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import 'support.dart';

void main() {
  setUpAll(loadNeumorphicFonts);

  for (final title in ['Stoner', 'One Hundred Years of Solitude']) {
    for (final direction in TextDirection.values) {
      testWidgets('status and key share a line: "$title" ${direction.name}', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          neumorphicApp(
            Directionality(
              textDirection: direction,
              child: NeumorphicListSection(
                children: [
                  NeumorphicListTile(
                    leading: const NeumorphicMonogram('OH'),
                    title: title,
                    subtitle: 'Gabriel García Márquez',
                    trailing: const Text('Done'),
                    action: NeumorphicIconButton(
                      NeumorphicGlyphs.trash2,
                      semanticLabel: 'Delete',
                      onPressed: () {},
                    ),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        );
        final tag = tester.getRect(find.text('Done'));
        final key = tester.getRect(find.byType(NeumorphicIconButton));
        expect(
          (tag.center.dy - key.center.dy).abs(),
          lessThan(2),
          reason: 'the status on the key\'s line',
        );
      });
    }
  }
}

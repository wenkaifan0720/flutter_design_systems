// A list row's title keeps a word whole at the reader's largest text: on a
// phone at twice the text the row's glyphs (its leading glyph or monogram,
// its chevron) stand on a line of their own over the words, so the words
// take the row's whole width. Every row of a list stands the same, whatever
// its words; at the reader's text the glyphs stand beside the words.
import 'package:civic_ui/civic_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'screens_matrix.dart';

const _titles = [
  'Notifications',
  'Accessibility',
  'Neighbourhood',
  'Housekeeping',
];

Widget? _lead(String kind) => switch (kind) {
  'glyph' => const Icon(LucideIcons.book),
  'monogram' => const CivicAvatar(name: 'Ana Ruiz'),
  _ => null,
};

Future<void> _pump(
  WidgetTester tester, {
  required bool grouped,
  required String lead,
  required double text,
  TextDirection direction = TextDirection.ltr,
}) async {
  Widget row(String title) => CivicListRow(
    title: Text(title),
    subtitle: const Text('Ana Ruiz'),
    leading: _lead(lead),
    onTap: () {},
  );
  await showScreen(
    tester,
    Directionality(
      textDirection: direction,
      child: CivicPageBody(
        title: 'Books',
        children: [
          if (grouped)
            CivicListGroup(children: [for (final t in _titles) row(t)])
          else
            for (final t in _titles) row(t),
        ],
      ),
    ),
    width: 390,
    height: 2400,
    text: text,
  );
}

// The lines a paragraph is laid out in.
int _lines(WidgetTester tester, String words) {
  final p = tester.renderObject<RenderParagraph>(find.text(words));
  return p
      .getBoxesForSelection(
        TextSelection(baseOffset: 0, extentOffset: words.length),
      )
      .map((b) => b.top.round())
      .toSet()
      .length;
}

void main() {
  setUpAll(loadScreenFonts);
  for (final grouped in [false, true]) {
    for (final lead in ['none', 'glyph', 'monogram']) {
      for (final direction in TextDirection.values) {
        testWidgets('a ${grouped ? 'grouped' : 'lone'} row with $lead '
            'leading keeps each word of its title whole at twice the text '
            '(${direction.name})', (tester) async {
          await _pump(
            tester,
            grouped: grouped,
            lead: lead,
            text: 2,
            direction: direction,
          );
          for (final t in _titles) {
            expect(_lines(tester, t), 1, reason: '"$t" is broken mid-word');
          }
          // Every row stands its glyphs the same way: the chevrons line up.
          final chevrons = find.byIcon(LucideIcons.chevronRight);
          final xs = {
            for (final e in chevrons.evaluate())
              tester.getRect(find.byWidget(e.widget).first).left.round(),
          };
          expect(xs, hasLength(1));
        });
      }
    }
  }

  testWidgets("at the reader's text a row's glyphs stand beside its words", (
    tester,
  ) async {
    await _pump(tester, grouped: true, lead: 'monogram', text: 1);
    final title = tester.getRect(find.text('Notifications'));
    final mono = tester.getRect(find.byType(CivicAvatar).first);
    final chevron = tester.getRect(find.byIcon(LucideIcons.chevronRight).first);
    expect(mono.right, lessThan(title.left));
    expect(chevron.left, greaterThan(title.left));
    expect((mono.center.dy - chevron.center.dy).abs(), lessThan(1));
  });
}

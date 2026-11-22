// A combobox reads as a select does: it ends in the select's chevron, as far
// in, and a press on it opens the list; and the list either opens stands on
// the field's own 2 pt ink edge, square, not a card on a hairline and a soft
// shadow.
// ignore_for_file: avoid_relative_lib_imports
import 'package:civic_ui/civic_ui.dart';
import 'package:civic_ui/src/civic/internal/list_option.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../example/lib/kit_gallery/kit.dart';

const _people = ['Maya Reed', 'Sam Okafor', 'Noor Haddad'];

Future<void> _pump(
  WidgetTester tester, {
  TextDirection direction = TextDirection.ltr,
  Brightness brightness = Brightness.light,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    kitApp(
      brightness: brightness,
      direction: direction,
      home: Padding(
        padding: const EdgeInsets.all(CivicSpacing.s20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CivicSelect<String>(
              key: const Key('select'),
              labelText: 'Due',
              items: const [
                CivicSelectItem(value: 'today', label: 'Today'),
                CivicSelectItem(value: 'later', label: 'Later'),
              ],
              value: 'today',
              onChanged: (_) {},
            ),
            const SizedBox(height: CivicSpacing.s20),
            const CivicCombobox<String>(
              key: Key('combobox'),
              labelText: 'Assignee',
              options: _people,
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _chevron(Finder field) => find.descendant(
  of: field,
  matching: find.byWidgetPredicate(
    (w) => w is Icon && w.icon == LucideIcons.chevronDown,
  ),
);

void main() {
  for (final direction in TextDirection.values) {
    testWidgets(
      "a combobox ends in the select's chevron, as far in (${direction.name})",
      (tester) async {
        await _pump(tester, direction: direction);
        final select = _chevron(find.byKey(const Key('select')));
        final combobox = _chevron(find.byKey(const Key('combobox')));
        expect(select, findsOneWidget);
        expect(combobox, findsOneWidget);
        final a = tester.getRect(select), b = tester.getRect(combobox);
        expect(b.size, a.size);
        // The two fields span the same column: their ends are one line.
        expect(b.left, closeTo(a.left, 0.5));
      },
    );
  }

  testWidgets("a press on a combobox's chevron opens its list", (tester) async {
    await _pump(tester);
    // The chevron takes no press of its own: one there is the field's.
    await tester.tapAt(
      tester.getCenter(_chevron(find.byKey(const Key('combobox')))),
    );
    await tester.pumpAndSettle();
    expect(find.text('Noor Haddad'), findsOneWidget);
  });

  for (final brightness in Brightness.values) {
    testWidgets(
      "a combobox's list stands on the field's ink edge (${brightness.name})",
      (tester) async {
        await _pump(tester, brightness: brightness);
        await tester.tap(find.byType(EditableText));
        await tester.pumpAndSettle();
        final surface = find.byType(CivicOptionSurface);
        expect(surface, findsOneWidget);
        final t = CivicTheme.of(tester.element(surface));
        final box =
            tester
                    .widgetList<DecoratedBox>(
                      find.descendant(
                        of: surface,
                        matching: find.byType(DecoratedBox),
                      ),
                    )
                    .first
                    .decoration
                as BoxDecoration;
        expect(box.border, Border.all(color: t.border, width: 2));
        expect(box.borderRadius, isNull);
        expect(box.boxShadow, anyOf(isNull, isEmpty));
      },
    );
  }
}

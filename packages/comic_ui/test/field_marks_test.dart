// A combobox reads as a select does: it ends in the same chevron at the same place, and a combobox that starts on one
// of its options offers them all, not only the one it holds. An empty field's caret stands before its hint, not over
// its first letter; until the caret comes, the hint stands where a select's value does.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';
import 'package:comic_ui/src/comic/press.dart' show ComicStateDecoration;

import 'support.dart';

const _places = ['Open studio', 'Field guide', 'Errands'];

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  TextDirection direction = TextDirection.ltr,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    comicApp(
      Padding(padding: const EdgeInsets.all(16), child: child),
      direction: direction,
    ),
  );
  await tester.pumpAndSettle();
}

Finder _chevron(Finder field) => find.descendant(
  of: field,
  matching: find.byWidgetPredicate(
    (w) => w is Icon && w.icon == ComicGlyphs.chevronDown,
  ),
);

void main() {
  setUpAll(loadComicFonts);

  for (final direction in TextDirection.values) {
    testWidgets(
      "a combobox ends in the select's chevron, as far in (${direction.name})",
      (tester) async {
        await _pump(
          tester,
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ComicSelect<String>(
                key: const Key('select'),
                labelText: 'Due',
                options: const [
                  ComicSelectOption('today', 'Today'),
                  ComicSelectOption('later', 'Later'),
                ],
                value: 'today',
                onChanged: (_) {},
              ),
              const SizedBox(height: 16),
              const ComicCombobox<String>(
                key: Key('combobox'),
                labelText: 'Project',
                options: _places,
              ),
            ],
          ),
          direction: direction,
        );
        final select = _chevron(find.byKey(const Key('select')));
        final combobox = _chevron(find.byKey(const Key('combobox')));
        expect(select, findsOneWidget);
        expect(combobox, findsOneWidget);
        expect(tester.getSize(combobox), tester.getSize(select));
        double inset(Finder mark) {
          final box = tester.getRect(
            find
                .ancestor(of: mark, matching: find.byType(ComicStateDecoration))
                .first,
          );
          final at = tester.getRect(mark);
          return direction == TextDirection.ltr
              ? box.right - at.right
              : at.left - box.left;
        }

        expect(inset(combobox), closeTo(inset(select), 0.5));
      },
    );
  }

  testWidgets('a combobox that starts on an option offers every option', (
    tester,
  ) async {
    await _pump(
      tester,
      const ComicCombobox<String>(
        labelText: 'Project',
        options: _places,
        initialValue: 'Field guide',
      ),
    );
    await tester.tap(find.byType(EditableText));
    await tester.pumpAndSettle();
    expect(find.text('Open studio'), findsOneWidget);
    expect(find.text('Errands'), findsOneWidget);
  });

  testWidgets('a combobox holding the option taken offers every option', (
    tester,
  ) async {
    await _pump(
      tester,
      const ComicCombobox<String>(labelText: 'Project', options: _places),
    );
    await tester.tap(find.byType(EditableText));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Errands'));
    await tester.pumpAndSettle();
    // Away and back: the field holds the taken option's words.
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.tap(find.byType(EditableText));
    await tester.pumpAndSettle();
    expect(find.text('Open studio'), findsOneWidget);
    expect(find.text('Field guide'), findsOneWidget);
  });

  for (final direction in TextDirection.values) {
    testWidgets(
      "an empty field's caret stands before its hint (${direction.name})",
      (tester) async {
        final focus = FocusNode();
        addTearDown(focus.dispose);
        await _pump(
          tester,
          ComicTextField(hintText: 'Find a command', focusNode: focus),
          direction: direction,
        );
        focus.requestFocus();
        await tester.pumpAndSettle();
        final editable = tester
            .state<EditableTextState>(find.byType(EditableText))
            .renderEditable;
        final caret = MatrixUtils.transformRect(
          editable.getTransformTo(null),
          editable.getLocalRectForCaret(const TextPosition(offset: 0)),
        );
        final hint = tester.getRect(find.text('Find a command'));
        // A clear gap, a letter's space at this size, so a first letter with
        // no side bearing (F, T) doesn't meet the caret.
        const gap = 2.0;
        if (direction == TextDirection.ltr) {
          expect(hint.left, greaterThanOrEqualTo(caret.right + gap));
        } else {
          expect(hint.right, lessThanOrEqualTo(caret.left - gap));
        }
      },
    );
  }

  for (final direction in TextDirection.values) {
    testWidgets(
      "an empty field's hint stands where a select's value does (${direction.name})",
      (tester) async {
        final focus = FocusNode();
        addTearDown(focus.dispose);
        await _pump(
          tester,
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ComicSelect<String>(
                options: const [ComicSelectOption('today', 'Today')],
                value: 'today',
                onChanged: (_) {},
              ),
              const SizedBox(height: 16),
              ComicTextField(hintText: 'Find a command', focusNode: focus),
            ],
          ),
          direction: direction,
        );
        // How far in from the column's start a part begins.
        double start(Finder part) {
          final at = tester.getRect(part);
          return direction == TextDirection.ltr ? at.left : 390 - at.right;
        }

        final hint = find.text('Find a command');
        expect(start(hint), closeTo(start(find.text('Today')), 0.5));
        focus.requestFocus();
        await tester.pumpAndSettle();
        // Focused, the field lifts; the hint moves in from where the caret
        // stands, at the editor's start.
        expect(
          start(hint) - start(find.byType(EditableText)),
          greaterThan(2),
          reason: 'the caret stands before the hint',
        );
        focus.unfocus();
        await tester.pumpAndSettle();
        expect(start(hint), closeTo(start(find.text('Today')), 0.5));
      },
    );
  }
}

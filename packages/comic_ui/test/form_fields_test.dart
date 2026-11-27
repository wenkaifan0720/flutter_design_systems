// A text field checked by its form, as TextFormField is; a date field with no day yet; a date with its year.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';

import 'support.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  double width = 390,
}) async {
  tester.view.physicalSize = Size(width, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    comicApp(
      SingleChildScrollView(
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
      width: width,
    ),
  );
  await tester.pump();
}

bool _focusedWithin(WidgetTester tester, Finder finder) {
  final focused = FocusManager.instance.primaryFocus?.context;
  if (focused == null) return false;
  return find
          .descendant(
            of: finder,
            matching: find.byElementPredicate((e) => e == focused),
          )
          .evaluate()
          .isNotEmpty ||
      finder.evaluate().any((e) => e == focused);
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadComicFonts();
  });

  test('a date with its year', () {
    expect(ComicFormat.date(DateTime(2026, 3, 14)), '14 Mar 2026');
    expect(ComicFormat.date(DateTime(1999, 12, 1)), '1 Dec 1999');
  });

  testWidgets(
    'a text field with a validator: a failed submit shows its error and focuses it; then edits re-check it',
    (tester) async {
      final form = GlobalKey<RawFormState>();
      String? saved;
      await _pump(
        tester,
        RawForm(
          key: form,
          child: ComicColumn(
            children: [
              ComicTextField(
                key: const ValueKey('title'),
                labelText: 'Title',
                validator: (text) =>
                    (text ?? '').trim().isEmpty ? 'Give it a title' : null,
                onSaved: (text) => saved = text,
              ),
            ],
          ),
        ),
      );
      expect(find.text('Give it a title'), findsNothing);
      expect(form.currentState!.submit(), isFalse);
      await tester.pump();
      expect(find.text('Give it a title'), findsOneWidget);
      expect(
        _focusedWithin(tester, find.byKey(const ValueKey('title'))),
        isTrue,
      );
      await tester.enterText(find.byType(EditableText), 'Piranesi');
      await tester.pump();
      expect(find.text('Give it a title'), findsNothing);
      expect(form.currentState!.submit(), isTrue);
      expect(saved, 'Piranesi');
    },
  );

  testWidgets(
    'a text field with a controller is checked on the controller\'s text',
    (tester) async {
      final form = GlobalKey<RawFormState>();
      final text = TextEditingController(text: 'Piranesi');
      addTearDown(text.dispose);
      await _pump(
        tester,
        RawForm(
          key: form,
          child: ComicTextField(
            controller: text,
            labelText: 'Title',
            validator: (value) =>
                (value ?? '').isEmpty ? 'Give it a title' : null,
          ),
        ),
      );
      expect(form.currentState!.submit(), isTrue);
      text.clear();
      expect(form.currentState!.submit(), isFalse);
    },
  );

  for (final width in [390.0, 1440.0]) {
    testWidgets(
      'a date field: no day yet, then a day with its year; it takes the column / $width',
      (tester) async {
        final semantics = tester.ensureSemantics();
        DateTime? day;
        await _pump(
          tester,
          StatefulBuilder(
            builder: (context, setState) => ComicColumn(
              children: [
                ComicTextField(
                  key: const ValueKey('text'),
                  labelText: 'Title',
                  onChanged: (_) {},
                ),
                ComicDateField(
                  key: const ValueKey('date'),
                  labelText: 'Started',
                  value: day,
                  onChanged: (value) => setState(() => day = value),
                ),
                ComicButton(
                  'Set',
                  onPressed: () => setState(() => day = DateTime(2026, 3, 14)),
                ),
              ],
            ),
          ),
          width: width,
        );
        final column = tester.getRect(find.byKey(const ValueKey('text')));
        final face = tester.getRect(
          find
              .descendant(
                of: find.byKey(const ValueKey('date')),
                matching: find.byType(ComicPressable),
              )
              .first,
        );
        expect(face.left, moreOrLessEquals(column.left, epsilon: .5));
        expect(face.right, moreOrLessEquals(column.right, epsilon: .5));
        expect(
          find.textContaining(RegExp('choose a date', caseSensitive: false)),
          findsOneWidget,
        );
        await tester.tap(
          find
              .descendant(
                of: find.byType(ComicButton),
                matching: find.byType(ComicPressable),
              )
              .first,
        );
        await tester.pump();
        expect(find.text('14 Mar 2026'), findsOneWidget);
        // Its label is said once, its day after it.
        expect(find.bySemanticsLabel(RegExp('Started')), findsOneWidget);
        expect(
          find.bySemanticsLabel(RegExp('Started.*Started', dotAll: true)),
          findsNothing,
        );
        // A press raises the calendar; dismissed, the day stays.
        await tester.tap(find.text('14 Mar 2026'));
        await tester.pumpAndSettle();
        expect(find.byType(ComicDialog), findsOneWidget);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(find.byType(ComicDialog), findsNothing);
        expect(day, DateTime(2026, 3, 14));
        semantics.dispose();
      },
    );
  }

  testWidgets(
    'a date field with a validator fails a submit while it is empty',
    (tester) async {
      final form = GlobalKey<RawFormState>();
      await _pump(
        tester,
        RawForm(
          key: form,
          child: ComicDateField(
            key: const ValueKey('date'),
            labelText: 'Started',
            value: null,
            onChanged: (_) {},
            validator: (day) => day == null ? 'Pick the day you started' : null,
          ),
        ),
      );
      expect(form.currentState!.submit(), isFalse);
      await tester.pump();
      expect(find.text('Pick the day you started'), findsOneWidget);
      expect(
        _focusedWithin(tester, find.byKey(const ValueKey('date'))),
        isTrue,
      );
    },
  );
}

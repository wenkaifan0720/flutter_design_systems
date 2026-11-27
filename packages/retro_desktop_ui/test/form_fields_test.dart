// A form in Retro Desktop: a text field checks itself in a RawForm, as TextFormField does in a Form; the first wrong field
// takes the focus; an error changes the field's edge as well as the note under it. The date field holds a nullable day,
// opens the date dialog, shows the day in the one medium date, and checks itself in the form too.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

import 'support.dart';

/// The heavy edge an error draws round a field's box.
Finder _errorEdge(Finder field) => find.descendant(
  of: field,
  matching: find.byWidgetPredicate(
    (w) =>
        w is DecoratedBox &&
        w.decoration is ShapeDecoration &&
        ((w.decoration as ShapeDecoration).shape as OutlinedBorder)
                .side
                .width >=
            2,
  ),
);

void main() {
  setUpAll(loadRetroDesktopFonts);

  testWidgets(
    'a text field checks itself in a form; the first wrong one takes the focus',
    (tester) async {
      final form = GlobalKey<RawFormState>();
      var saved = 0;
      final title = TextEditingController(), author = TextEditingController();
      addTearDown(title.dispose);
      addTearDown(author.dispose);
      await tester.pumpWidget(
        retroDesktopApp(
          RawForm(
            key: form,
            onSubmit: () => saved++,
            child: Column(
              children: [
                RetroDesktopTextField(
                  labelText: 'Title',
                  controller: title,
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? 'Enter the title' : null,
                ),
                RetroDesktopTextField(
                  labelText: 'Author',
                  controller: author,
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? 'Enter who wrote it' : null,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final fields = find.byType(RetroDesktopTextField);
      expect(_errorEdge(fields.first), findsNothing);
      form.currentState!.submit();
      await tester.pumpAndSettle();
      expect(find.text('Enter the title'), findsOneWidget);
      expect(find.text('Enter who wrote it'), findsOneWidget);
      expect(saved, 0);
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText).first)
            .focusNode
            .hasFocus,
        isTrue,
      );
      expect(
        _errorEdge(fields.first),
        findsOneWidget,
        reason: "An error changes the field's edge",
      );
      await tester.enterText(find.byType(EditableText).first, 'Stoner');
      await tester.enterText(find.byType(EditableText).last, 'John Williams');
      form.currentState!.submit();
      await tester.pumpAndSettle();
      expect(saved, 1);
      expect(find.text('Enter the title'), findsNothing);
    },
  );

  testWidgets("a given errorText draws the field's error edge", (tester) async {
    await tester.pumpWidget(
      retroDesktopApp(
        const RetroDesktopTextField(labelText: 'Name', errorText: 'Taken'),
      ),
    );
    expect(_errorEdge(find.byType(RetroDesktopTextField)), findsOneWidget);
  });

  testWidgets('the medium date has the year, in the device language', (
    tester,
  ) async {
    late String shown;
    await tester.pumpWidget(
      retroDesktopApp(
        Builder(
          builder: (context) {
            shown = RetroDesktopFormat.mediumDate(
              context,
              DateTime(2026, 10, 2),
            );
            return const SizedBox();
          },
        ),
      ),
    );
    expect(shown, allOf(contains('Oct'), contains('2'), contains('2026')));
  });

  testWidgets(
    'a date field with no day shows its hint, and the dialog chooses one',
    (tester) async {
      DateTime? day;
      await tester.pumpWidget(
        retroDesktopApp(
          StatefulBuilder(
            builder: (context, set) => RetroDesktopDateField(
              labelText: 'Started',
              hintText: 'Not yet',
              value: day,
              firstDate: DateTime(2020),
              lastDate: DateTime(2026, 10, 2),
              onChanged: (next) => set(() => day = next),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Not yet'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('^Started')), findsOneWidget);
      await tester.tap(find.text('Not yet'));
      await tester.pumpAndSettle();
      expect(find.byType(RetroDesktopDialog), findsOneWidget);
      await tester.tap(find.text('Choose'));
      await tester.pumpAndSettle();
      expect(day, DateTime(2026, 10, 2));
      expect(
        find.text(
          RetroDesktopFormat.mediumDate(
            tester.element(find.byType(RetroDesktopDateField)),
            DateTime(2026, 10, 2),
          ),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('a date field checks itself in a form', (tester) async {
    final form = GlobalKey<RawFormState>();
    await tester.pumpWidget(
      retroDesktopApp(
        RawForm(
          key: form,
          onSubmit: () {},
          child: RetroDesktopDateField(
            labelText: 'Due',
            value: null,
            onChanged: (_) {},
            validator: (day) => day == null ? 'Choose the day' : null,
          ),
        ),
      ),
    );
    form.currentState!.submit();
    await tester.pumpAndSettle();
    expect(find.text('Choose the day'), findsOneWidget);
    expect(_errorEdge(find.byType(RetroDesktopDateField)), findsOneWidget);
  });
}

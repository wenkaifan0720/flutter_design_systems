// Forms: a field in error keeps the danger edge while it has focus, a text
// field says it is required, MinimalTextFormField validates in a MinimalForm
// as Flutter's TextFormField does in a Form, and the date field takes an
// unset value and prints the year.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

Widget _app(Widget child) => MaterialApp(
  builder: (context, app) => MinimalHost(
    light: MinimalThemeData.preset('standard', Brightness.light),
    dark: MinimalThemeData.preset('standard', Brightness.dark),
    brightness: Brightness.light,
    child: app!,
  ),
  home: MinimalScaffold(body: child),
);

/// The colours of the edges drawn over [within]'s faces.
List<Color> _edges(WidgetTester tester, Finder within) => [
  for (final box in tester.widgetList<DecoratedBox>(
    find.descendant(of: within, matching: find.byType(DecoratedBox)),
  ))
    if (box.position == DecorationPosition.foreground)
      if (box.decoration case BoxDecoration(border: final Border border))
        border.top.color
      else if (box.decoration case ShapeDecoration(
        shape: final OutlinedBorder shape,
      ))
        shape.side.color,
];

void main() {
  testWidgets('a focused field in error keeps the danger edge', (tester) async {
    await tester.pumpWidget(
      _app(
        const MinimalTextField(
          labelText: 'Title',
          errorText: 'Enter a title',
          autofocus: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final t = MinimalThemeData.preset('standard', Brightness.light);
    final edges = _edges(tester, find.byType(MinimalTextField));
    expect(edges, contains(t.destructive));
    expect(edges, isNot(contains(t.ring)));
  });

  testWidgets('a focused field with no error takes the accent edge', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(const MinimalTextField(labelText: 'Title', autofocus: true)),
    );
    await tester.pumpAndSettle();
    final t = MinimalThemeData.preset('standard', Brightness.light);
    expect(_edges(tester, find.byType(MinimalTextField)), contains(t.ring));
  });

  testWidgets('a required text field marks its label and says so', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(const MinimalTextField(labelText: 'Title', required: true)),
    );
    expect(find.text(' *'), findsOneWidget);
    expect(
      tester.widget<RawInputDecorator>(find.byType(RawInputDecorator)).required,
      isTrue,
    );
  });

  testWidgets('MinimalTextFormField validates, saves and resets in a form', (
    tester,
  ) async {
    String? saved;
    var submitted = 0;
    late BuildContext formContext;
    await tester.pumpWidget(
      _app(
        MinimalForm(
          onSubmit: () => submitted++,
          child: Builder(
            builder: (context) {
              formContext = context;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: MinimalSpacing.s16,
                children: [
                  MinimalTextFormField(
                    labelText: 'Title',
                    required: true,
                    validator: (value) =>
                        (value ?? '').trim().isEmpty ? 'Enter a title' : null,
                    onSaved: (value) => saved = value,
                  ),
                  const MinimalTextFormField(labelText: 'Author'),
                ],
              );
            },
          ),
        ),
      ),
    );

    expect(MinimalForm.submit(formContext), isFalse);
    await tester.pumpAndSettle();
    expect(find.text('Enter a title'), findsOneWidget);
    expect(submitted, 0);
    // The failed submit moved focus to the wrong field.
    final title = find.byType(EditableText).first;
    expect(tester.widget<EditableText>(title).focusNode.hasFocus, isTrue);

    await tester.enterText(title, 'Stoner');
    await tester.pumpAndSettle();
    expect(find.text('Enter a title'), findsNothing);

    expect(MinimalForm.submit(formContext), isTrue);
    expect(saved, 'Stoner');
    expect(submitted, 1);

    MinimalForm.reset(formContext);
    await tester.pumpAndSettle();
    expect(tester.widget<EditableText>(title).controller.text, isEmpty);
  });

  testWidgets('the date field takes an unset value and prints the year', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(1440, 900)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    DateTime? picked;
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, setState) => MinimalDatePicker(
            labelText: 'Date started',
            mode: MinimalDatePickerMode.date,
            currentDate: DateTime(2026, 11, 26),
            value: picked,
            onChanged: (value) => setState(() => picked = value),
          ),
        ),
      ),
    );
    expect(find.text('Choose'), findsOneWidget);
    await tester.tap(find.text('Choose'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('18'));
    await tester.pumpAndSettle();
    expect(picked, DateTime(2026, 11, 18));
    expect(find.text('18 Nov 2026'), findsOneWidget);
  });
}

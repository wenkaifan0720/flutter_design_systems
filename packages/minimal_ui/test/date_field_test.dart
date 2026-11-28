// A date picker in a form of boxed fields stands as one of them: the label
// over a box, the box at the text field's
// edges, height and rim, the label in the text field's ink and place.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

const _field = Key('field');
const _date = Key('date');

Widget _app(Widget child, {double width = 800}) => MaterialApp(
  builder: (context, app) =>
      MinimalHost(brightness: Brightness.light, child: app!),
  home: Scaffold(
    body: Center(
      child: SizedBox(
        width: width,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 16,
            children: [
              const MinimalTextField(key: _field, labelText: 'Title'),
              child,
            ],
          ),
        ),
      ),
    ),
  ),
);

/// The rects of the boxes drawn under [of]: every decorated box with a rim.
List<Rect> _boxes(WidgetTester tester, Finder of) => [
  for (final e
      in find
          .descendant(of: of, matching: find.byType(DecoratedBox))
          .evaluate())
    if (switch ((e.widget as DecoratedBox).decoration) {
      BoxDecoration(:final border?) => border.top.width > 0,
      ShapeDecoration(:final shape) =>
        shape is OutlinedBorder && shape.side.width > 0,
      _ => false,
    })
      tester.getRect(find.byWidget(e.widget)),
];

Color? _rim(WidgetTester tester, Finder of) {
  for (final e
      in find
          .descendant(of: of, matching: find.byType(DecoratedBox))
          .evaluate()) {
    switch ((e.widget as DecoratedBox).decoration) {
      // The focus edge stands over the rim, clear until focus.
      case BoxDecoration(:final Border border)
          when border.top.width > 0 && border.top.color.a > 0:
        return border.top.color;
      case ShapeDecoration(:final OutlinedBorder shape)
          when shape.side.width > 0 && shape.side.color.a > 0:
        return shape.side.color;
    }
  }
  return null;
}

void main() {
  testWidgets('a field date picker stands at the text field\'s edges', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        MinimalDatePicker(
          key: _date,
          labelText: 'Started',
          mode: MinimalDatePickerMode.date,
          presentation: MinimalDatePickerPresentation.field,
          value: DateTime(2026, 11, 9),
          onChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    final field = _boxes(tester, find.byKey(_field)).first;
    final date = _boxes(tester, find.byKey(_date));
    expect(date, hasLength(1));
    expect(date.single.left, field.left);
    expect(date.single.right, field.right);
    expect(date.single.height, field.height);
    // The labels: same place, same type and ink.
    final title = tester.getRect(find.text('Title'));
    final started = tester.getRect(find.text('Started'));
    expect(started.left, title.left);
    expect(started.height, title.height);
    expect(field.top - title.bottom, date.single.top - started.bottom);
    final a = tester.widget<Text>(find.text('Title'));
    final b = tester.widget<Text>(find.text('Started'));
    TextStyle? style(Text text) =>
        DefaultTextStyle.of(tester.element(find.byWidget(text))).style
            .merge(text.style);
    expect(style(b)!.fontSize, style(a)!.fontSize);
    expect(style(b)!.fontWeight, style(a)!.fontWeight);
    expect(style(b)!.color, style(a)!.color);
    expect(find.text('Nov 9, 2026'), findsOneWidget);
    // The rims match too.
    expect(_rim(tester, find.byKey(_date)), _rim(tester, find.byKey(_field)));
  });

  testWidgets('a date and a time stand in two boxes across the field', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        MinimalDatePicker(
          key: _date,
          labelText: 'Due',
          presentation: MinimalDatePickerPresentation.field,
          value: DateTime(2026, 11, 9, 21, 30),
          onChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    final field = _boxes(tester, find.byKey(_field)).first;
    final boxes = _boxes(tester, find.byKey(_date));
    expect(boxes, hasLength(2));
    expect(boxes.first.left, field.left);
    expect(boxes.last.right, field.right);
    expect(boxes.first.height, field.height);
    expect(boxes.last.height, field.height);
    expect(find.text('21:30'), findsOneWidget);
  });

  testWidgets('its box opens the calendar, a day picks', (tester) async {
    DateTime? picked;
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, setState) => MinimalDatePicker(
            key: _date,
            labelText: 'Started',
            mode: MinimalDatePickerMode.date,
            presentation: MinimalDatePickerPresentation.field,
            value: picked ?? DateTime(2026, 11, 9),
            onChanged: (v) => setState(() => picked = v),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nov 9, 2026'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('17').last);
    await tester.pumpAndSettle();
    expect(picked, DateTime(2026, 11, 17));
    expect(find.text('Nov 17, 2026'), findsOneWidget);
  });

  testWidgets('the label is heard once, with each box', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _app(
        MinimalDatePicker(
          key: _date,
          labelText: 'Started',
          mode: MinimalDatePickerMode.date,
          presentation: MinimalDatePickerPresentation.field,
          onChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Started'), findsNothing);
    expect(find.bySemanticsLabel(RegExp('^Started, date')), findsOneWidget);
    handle.dispose();
  });

  testWidgets('under a form field in error its rim turns', (tester) async {
    await tester.pumpWidget(
      _app(
        MinimalFormField(
          errorText: 'Pick the day you started',
          child: MinimalDatePicker(
            key: _date,
            labelText: 'Started',
            mode: MinimalDatePickerMode.date,
            presentation: MinimalDatePickerPresentation.field,
            onChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final t = MinimalTheme.of(tester.element(find.byKey(_date)));
    expect(_rim(tester, find.byKey(_date)), t.destructive);
  });
}

// Every field in a form column takes the column's width, at a phone's width
// and at a desktop's: the text field, the select, the date field and the
// slider's track stand edge to edge (Material parity). A segmented control
// is a choice, not a field: like Material's it keeps its own width, capped
// at MinimalLayout.controlMax from a tablet up.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

const _column = Key('column');

Widget _form() => MaterialApp(
  builder: (context, app) =>
      MinimalHost(brightness: Brightness.light, child: app!),
  home: Builder(
    builder: (context) => MinimalScaffold(
      maxWidth: MinimalLayout.contentWidth(context),
      body: Column(
        key: _column,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: MinimalSpacing.s16,
        children: [
          const MinimalTextField(labelText: 'Title'),
          MinimalSelect(
            labelText: 'Status',
            value: 'a',
            options: const [
              MinimalSelectOption('a', 'Want to read'),
              MinimalSelectOption('b', 'Reading'),
            ],
            onChanged: (_) {},
          ),
          MinimalDatePicker(
            labelText: 'Started',
            mode: MinimalDatePickerMode.date,
            currentDate: DateTime(2026, 11, 26),
            onChanged: (_) {},
          ),
          MinimalSlider(label: 'Rating', value: .5, onChanged: (_) {}),
        ],
      ),
    ),
  ),
);

bool _draws(Decoration decoration) => switch (decoration) {
  BoxDecoration(:final color, :final border) =>
    (color?.a ?? 0) > 0 ||
        (border is Border &&
            [
              border.top,
              border.bottom,
              border.left,
              border.right,
            ].any((side) => side.color.a > 0 && side.width > 0)),
  ShapeDecoration(:final color, :final shape) =>
    (color?.a ?? 0) > 0 ||
        (shape is OutlinedBorder &&
            shape.side.color.a > 0 &&
            shape.side.width > 0),
  _ => false,
};

void main() {
  for (final width in const [390.0, 1440.0]) {
    testWidgets('the fields take the column (${width.toInt()})', (
      tester,
    ) async {
      tester.view
        ..physicalSize = Size(width, 900)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_form());
      await tester.pumpAndSettle();
      final column = tester.getRect(find.byKey(_column));
      for (final (name, field) in [
        ('text field', find.byType(MinimalTextField)),
        ('select', find.byWidgetPredicate((w) => w is MinimalSelect)),
        ('date field', find.byType(MinimalDatePicker)),
        ('slider', find.byType(MinimalSlider)),
      ]) {
        // The drawn control: the widest painted box under the field.
        var widest = 0.0;
        for (final element
            in find
                .descendant(
                  of: field,
                  matching: find.byWidgetPredicate((_) => true),
                )
                .evaluate()) {
          final box = element.renderObject;
          // A box that draws: a visible fill or edge (a focus ring that is
          // not showing draws none).
          final draws = switch (box) {
            RenderDecoratedBox(:final decoration) => _draws(decoration),
            // The slider paints its track across its whole box.
            RenderCustomPaint(:final painter) => painter != null,
            _ => false,
          };
          if (draws && box is RenderBox && box.size.width > widest) {
            widest = box.size.width;
          }
        }
        expect(widest, column.width, reason: '$name at ${width.toInt()}');
      }
    });
  }
}

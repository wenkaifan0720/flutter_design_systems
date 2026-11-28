// Every field in a form column takes the column's width, at a phone's width
// and at a desktop's: the text field, the select, the date field (a row and
// a box), the slider's track and a segmented control a form field labels
// stand edge to edge (Material parity; a segmented control capped beside
// full-width fields left the desktop form's edge ragged).
// Standing alone (a view switch), a segmented control keeps
// MinimalLayout.controlMax from a tablet up.
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
          MinimalDatePicker(
            labelText: 'Finished',
            mode: MinimalDatePickerMode.date,
            presentation: MinimalDatePickerPresentation.field,
            currentDate: DateTime(2026, 11, 26),
            onChanged: (_) {},
          ),
          MinimalSlider(label: 'Rating', value: .5, onChanged: (_) {}),
          MinimalFormField(
            labelText: 'Shelf',
            child: MinimalSegmentedButton<String>(
              value: 'a',
              segments: const [
                MinimalButtonSegment('a', 'To read'),
                MinimalButtonSegment('b', 'Reading'),
                MinimalButtonSegment('c', 'Done'),
              ],
              onChanged: (_) {},
            ),
          ),
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
        ('date row', find.byType(MinimalDatePicker).first),
        ('date box', find.byType(MinimalDatePicker).last),
        ('slider', find.byType(MinimalSlider)),
        (
          'segmented in a form field',
          find.byWidgetPredicate((w) => w is MinimalSegmentedButton),
        ),
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

  testWidgets('a segmented control standing alone keeps a control\'s measure', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(1440, 900)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, app) =>
            MinimalHost(brightness: Brightness.light, child: app!),
        home: Builder(
          builder: (context) => MinimalScaffold(
            maxWidth: MinimalLayout.contentWidth(context),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MinimalSegmentedButton<String>(
                  value: 'w',
                  segments: const [
                    MinimalButtonSegment('w', 'Week'),
                    MinimalButtonSegment('m', 'Month'),
                  ],
                  onChanged: (_) {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .getSize(find.byWidgetPredicate((w) => w is MinimalSegmentedButton))
          .width,
      greaterThanOrEqualTo(MinimalLayout.controlMax),
    );
    final drawn = tester
        .renderObjectList<RenderBox>(
          find.descendant(
            of: find.byWidgetPredicate((w) => w is MinimalSegmentedButton),
            matching: find.byType(ConstrainedBox),
          ),
        )
        .map((b) => b.size.width)
        .reduce((a, b) => a < b ? a : b);
    expect(drawn, lessThanOrEqualTo(MinimalLayout.controlMax));
  });
}

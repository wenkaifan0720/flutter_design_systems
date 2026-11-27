// Round 0.8's behaviour changes, each failing first on 0.7.1: a row reads
// its title before a trailing status tag; a control named by its
// semanticLabel does not speak its tooltip too; the date field prints the
// look's medium date with the year; a select takes its column's width; a
// radio option's leading part (a palette's swatch) stands between its radio
// and its label, not read out.
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  double width = 390,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        RawWidgetsLocalizations.delegate,
        ExpressiveLocalizations.delegate,
      ],
      builder: (context, page) => ExpressiveHost(child: page!),
      home: Align(alignment: Alignment.topCenter, child: child),
    ),
  );
  await tester.pumpAndSettle();
}

/// A laid-out box's alphabetic baseline from its top, asked as a parent asks.
double _baseline(RenderBox box) =>
    box.getDryBaseline(box.constraints, TextBaseline.alphabetic)!;

void main() {
  testWidgets('a row reads its title, its line, then its trailing tag', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pump(
      tester,
      ExpressiveListTile(
        title: const Text('Dune'),
        subtitle: const Text('Frank Herbert'),
        trailing: const ExpressiveTag('Reading'),
        onTap: () {},
      ),
    );
    final label = tester.getSemantics(find.byType(ExpressiveListTile)).label;
    expect(label.indexOf('Dune'), lessThan(label.indexOf('Frank Herbert')));
    expect(label.indexOf('Frank Herbert'), lessThan(label.indexOf('Reading')));
    semantics.dispose();
  });

  testWidgets(
    'a semanticLabel names an icon button alone; a tooltip alone names it',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await _pump(
        tester,
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExpressiveIconButton(
              ExpressiveSymbols.delete,
              key: const ValueKey('labelled'),
              tooltip: 'Delete',
              semanticLabel: 'Delete Dune',
              onPressed: () {},
            ),
            ExpressiveIconButton(
              ExpressiveSymbols.delete,
              key: const ValueKey('tip'),
              tooltip: 'Delete',
              onPressed: () {},
            ),
          ],
        ),
      );
      final labelled = tester.getSemantics(
        find.byKey(const ValueKey('labelled')),
      );
      expect(labelled.label, 'Delete Dune');
      expect(labelled.tooltip, isEmpty);
      final tip = tester.getSemantics(find.byKey(const ValueKey('tip')));
      expect(tip.tooltip, 'Delete');
      semantics.dispose();
    },
  );

  testWidgets('the date field prints the medium date with the year', (
    tester,
  ) async {
    await _pump(
      tester,
      SizedBox(
        width: 360,
        child: ExpressiveDockedDatePicker(
          label: 'Date started',
          value: DateTime(2026, 10, 3),
          onChanged: (_) {},
        ),
      ),
    );
    expect(
      find.text(ExpressiveFormat.date(DateTime(2026, 10, 3))),
      findsOneWidget,
    );
    expect(find.text('3 Oct 2026'), findsOneWidget);
    expect(find.text('10/03/2026'), findsNothing);
  });

  for (final width in [390.0, 1440.0]) {
    testWidgets(
      'at $width a select takes its column\'s width, as a text field does',
      (tester) async {
        await _pump(
          tester,
          SizedBox(
            width: 560,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const ExpressiveTextField(
                  key: ValueKey('field'),
                  labelText: 'Title',
                ),
                ExpressiveSelect<String>(
                  key: const ValueKey('select'),
                  labelText: 'Palette',
                  value: 'baseline',
                  options: const [
                    ExpressiveSelectOption('baseline', 'Baseline'),
                    ExpressiveSelectOption('tide', 'Tide'),
                  ],
                  onChanged: (_) {},
                ),
              ],
            ),
          ),
          width: width,
        );
        // The select's face ends where the field's does: its arrow stands
        // at the column's end, not 320 in.
        final field = tester.getRect(find.byKey(const ValueKey('field')));
        final arrow = tester.getRect(
          find.descendant(
            of: find.byKey(const ValueKey('select')),
            matching: find.byType(ExpressiveSelectTrailingIcon),
          ),
        );
        expect(arrow.right, greaterThan(field.right - 32));
      },
    );
  }

  for (final direction in TextDirection.values) {
    testWidgets('${direction.name}: a radio option\'s leading stands between '
        'its radio and its label, unread', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pump(
        tester,
        Directionality(
          textDirection: direction,
          child: SizedBox(
            width: 360,
            child: ExpressiveRadioGroup<String>(
              semanticLabel: 'Colour',
              value: 'tide',
              options: const [
                ExpressiveRadioOption(
                  value: 'tide',
                  label: 'Tide',
                  leading: Text('Swatch', key: ValueKey('swatch')),
                ),
              ],
              onChanged: (_) {},
            ),
          ),
        ),
      );
      final radio = tester.getRect(
        find.byWidgetPredicate((w) => w is ExpressiveRadio),
      );
      final swatch = tester.getRect(find.byKey(const ValueKey('swatch')));
      final label = tester.getRect(find.text('Tide'));
      if (direction == TextDirection.ltr) {
        expect(radio.right, lessThanOrEqualTo(swatch.left));
        expect(swatch.right, lessThanOrEqualTo(label.left));
      } else {
        expect(radio.left, greaterThanOrEqualTo(swatch.right));
        expect(swatch.left, greaterThanOrEqualTo(label.right));
      }
      expect(find.bySemanticsLabel(RegExp('Swatch')), findsNothing);
      expect(find.bySemanticsLabel(RegExp('Tide')), findsWidgets);
      semantics.dispose();
    });
  }

  for (final direction in TextDirection.values) {
    testWidgets(
      'a description row from 600 sets its term on its value\'s baseline '
      '(${direction.name})',
      (tester) async {
        await _pump(
          tester,
          Directionality(
            textDirection: direction,
            child: const SizedBox(
              width: 640,
              child: ExpressiveDescriptionList(
                items: [
                  ExpressiveDescriptionItem('Author', 'George Eliot'),
                  ExpressiveDescriptionItem(
                    'Note',
                    'A long value that wraps onto a second line of its own '
                        'in the wider column, and then onto a third one',
                  ),
                ],
              ),
            ),
          ),
          width: 800,
        );
        double baseline(String text) {
          final box = tester.renderObject<RenderBox>(find.text(text));
          return box.localToGlobal(Offset.zero).dy + _baseline(box);
        }

        expect(baseline('Author'), closeTo(baseline('George Eliot'), 0.5));
        // A value of several lines keeps its first line on the term's.
        final note = tester.getRect(find.text('Note'));
        final value = tester.getRect(find.textContaining('A long value'));
        expect(value.height, greaterThan(note.height * 1.5));
        expect(
          baseline('Note'),
          closeTo(
            value.top +
                _baseline(
                  tester.renderObject<RenderBox>(
                    find.textContaining('A long value'),
                  ),
                ),
            0.5,
          ),
        );
      },
    );
  }
}

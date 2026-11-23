// A sorted column's heading says which way it is sorted with an arrow, as
// Material's DataTable does: the heading and its arrow are laid out whole
// however narrow its column was given, and its words stay over its rows'
// words, the arrow after them, or before them over numbers.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

import 'faces.dart';

String _plain(RenderParagraph p) =>
    p.text.toPlainText(includeSemanticsLabels: false);

const _at = {'run': 0, 'branch': 1, 'secs': 2};

RawDataTableController<List<String>> _runs() =>
    RawDataTableController<List<String>>(
      rows: const [
        ['#1482', 'main', '134'],
        ['#1481', 'release/2.4', '182'],
        ['#1480', 'feat/desk', '97'],
      ],
      rowKey: (r) => r.first,
      columns: [
        RawDataColumn<List<String>>(
          id: 'run',
          label: 'run',
          sortKey: (r) => r[0],
        ),
        const RawDataColumn<List<String>>(id: 'branch', label: 'branch'),
        RawDataColumn<List<String>>(
          id: 'secs',
          label: 'secs',
          numeric: true,
          sortKey: (r) => int.parse(r[2]),
        ),
      ],
    );

Future<RawDataTableController<List<String>>> _pump(
  WidgetTester tester,
  TextDirection direction,
) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final table = _runs();
  addTearDown(table.dispose);
  await tester.pumpWidget(
    MaterialApp(
      home: Directionality(
        textDirection: direction,
        child: MediaQuery.withClampedTextScaling(
          minScaleFactor: 2,
          maxScaleFactor: 2,
          child: TermTheme(
            data: TermThemeData.dark(),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Align(
                alignment: AlignmentDirectional.topStart,
                child: TermDataTable<List<String>>(
                  controller: table,
                  widths: const {'run': 6, 'secs': 5},
                  cellBuilder: (context, row, column) =>
                      Text(row[_at[column.id]!]),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return table;
}

RenderParagraph _paragraph(WidgetTester tester, bool Function(String) test) =>
    tester
        .renderObjectList<RenderParagraph>(find.byType(RichText))
        .firstWhere((p) => test(_plain(p)));

/// Where [words] in [p] start and end on the screen, left to right.
(double, double) _span(RenderParagraph p, String words) {
  final start = _plain(p).indexOf(words);
  final boxes = p.getBoxesForSelection(
    TextSelection(baseOffset: start, extentOffset: start + words.length),
  );
  var left = double.infinity;
  var right = double.negativeInfinity;
  for (final b in boxes) {
    if (b.left < left) left = b.left;
    if (b.right > right) right = b.right;
  }
  return (
    p.localToGlobal(Offset(left, 0)).dx,
    p.localToGlobal(Offset(right, 0)).dx,
  );
}

void main() {
  setUpAll(loadFaces);

  for (final direction in TextDirection.values) {
    for (final (id, first) in [('run', '#1482'), ('secs', '134')]) {
      for (final (order, arrow) in [
        (RawSortDirection.ascending, '↑'),
        (RawSortDirection.descending, '↓'),
      ]) {
        testWidgets('a column sorted by $id, ${order.name}, at 390, 2x, '
            '${direction.name}: its heading and $arrow laid out whole', (
          tester,
        ) async {
          final table = await _pump(tester, direction);
          table.sortBy(id, order);
          await tester.pumpAndSettle();
          final heading = _paragraph(
            tester,
            (s) => s.contains(id) && s.contains(arrow),
          );
          expect(heading.didExceedMaxLines, isFalse);
          expect(
            heading.getMaxIntrinsicWidth(double.infinity),
            lessThanOrEqualTo(heading.size.width + 0.5),
          );
        });
      }

      testWidgets('a column sorted by $id, ${direction.name}: its words over '
          "its rows' words", (tester) async {
        final table = await _pump(tester, direction);
        table.sortBy(id, RawSortDirection.descending);
        await tester.pumpAndSettle();
        final heading = _paragraph(
          tester,
          (s) => s.contains(id) && s.contains('↓'),
        );
        final cell = _paragraph(tester, (s) => s == first);
        final (wordsLeft, wordsRight) = _span(heading, id);
        final (cellLeft, cellRight) = _span(cell, first);
        // Words line up at the column's start, numbers at its end.
        final atStart = (id == 'run') == (direction == TextDirection.ltr);
        if (atStart) {
          expect(wordsLeft, moreOrLessEquals(cellLeft, epsilon: 0.5));
        } else {
          expect(wordsRight, moreOrLessEquals(cellRight, epsilon: 0.5));
        }
      });
    }
  }
}

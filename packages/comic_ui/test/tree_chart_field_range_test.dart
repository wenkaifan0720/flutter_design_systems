// Four parts that read their state plainly:
// - a tree's keyboard row is told apart from its picked row, which keeps the picked fill;
// - a chart is a tab stop (the arrows read its points) and shows the keyboard's focus when it has it;
// - a form field's error reddens the control's rim, not only the line under it;
// - a date range's heading drops the years it shares with today, so it stays on one line.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';
import 'package:comic_ui/src/comic/raised.dart' show ComicMenuRowFace;

import 'support.dart';

Future<void> _tab(WidgetTester tester) async {
  FocusManager.instance.highlightStrategy =
      FocusHighlightStrategy.alwaysTraditional;
  addTearDown(
    () => FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.automatic,
  );
  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  await tester.pump();
}

Iterable<ComicHighlight> _ringed(WidgetTester tester, Finder within) => tester
    .widgetList<ComicHighlight>(
      find.descendant(of: within, matching: find.byType(ComicHighlight)),
    )
    .where((h) => h.ring && h.states.contains(WidgetState.focused));

bool _dangerRim(WidgetTester tester, Finder within) {
  final danger = ComicTheme.of(tester.element(within)).colors.tones.danger;
  return tester
      .widgetList<DecoratedBox>(
        find.descendant(of: within, matching: find.byType(DecoratedBox)),
      )
      .map((b) => b.decoration)
      .whereType<ShapeDecoration>()
      .any(
        (d) =>
            d.shape is OutlinedBorder &&
            (d.shape as OutlinedBorder).side.color == danger,
      );
}

void main() {
  setUpAll(loadComicFonts);

  testWidgets(
    'a tree rings the keyboard row and keeps the fill for the picked one',
    (tester) async {
      final tree = RawTreeController<String>(
        roots: const ['Issue 12', 'Issue 13'],
        expanded: const ['Issue 12'],
        childrenOf: (node) =>
            node == 'Issue 12' ? const ['Cover', 'Story'] : const [],
      )..select('Cover');
      await tester.pumpWidget(
        comicApp(
          ComicTreeView<String>(controller: tree, labelOf: (node) => node),
        ),
      );
      await tester.pump();
      await _tab(tester);
      final view = find.byType(ComicTreeView<String>);
      expect(
        _ringed(tester, view),
        isNotEmpty,
        reason: 'no row rings under the keyboard',
      );
      final faces = tester
          .widgetList<ComicMenuRowFace>(find.byType(ComicMenuRowFace))
          .toList();
      expect(
        faces.where((f) => f.states.contains(WidgetState.focused)),
        isEmpty,
        reason: 'a row is lit by the focus',
      );
      expect(faces.where((f) => f.checked).map((f) => f.label), [
        'Cover',
      ], reason: 'the picked row is not the chosen one');
      tree.dispose();
    },
  );

  testWidgets('a chart with the focus wears the ring', (tester) async {
    await tester.pumpWidget(
      comicApp(
        const Padding(
          padding: EdgeInsets.all(16),
          child: ComicLineChart(
            label: 'Pages read',
            labels: ['Wk 1', 'Wk 2', 'Wk 3'],
            series: [
              ComicChartSeries('You', [12, 18, 16]),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    final chart = find.byType(ComicLineChart);
    expect(_ringed(tester, chart), isEmpty);
    await _tab(tester);
    expect(
      _ringed(tester, chart),
      isNotEmpty,
      reason: 'the focused chart shows no ring',
    );
  });

  testWidgets(
    'a form field in error reddens its control, not only the line under it',
    (tester) async {
      Widget field(String? error) => comicApp(
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              ComicFormField(
                'Your name',
                errorText: error,
                child: const ComicTextField(hintText: 'Name'),
              ),
              ComicFormField(
                'Code',
                errorText: error,
                child: const ComicInputGroup(hintText: 'Code'),
              ),
            ],
          ),
        ),
      );
      await tester.pumpWidget(field(null));
      await tester.pump();
      expect(_dangerRim(tester, find.byType(ComicTextField)), isFalse);
      expect(_dangerRim(tester, find.byType(ComicInputGroup)), isFalse);
      await tester.pumpWidget(field('Required'));
      // The rim turns to danger on the state motion, as every change of a face does: read where it lands.
      await tester.pumpAndSettle();
      expect(
        _dangerRim(tester, find.byType(ComicTextField)),
        isTrue,
        reason: 'the text field kept its idle rim',
      );
      expect(
        _dangerRim(tester, find.byType(ComicInputGroup)),
        isTrue,
        reason: 'the input group kept its idle rim',
      );
    },
  );

  testWidgets("a date range's heading drops the years it shares with today", (
    tester,
  ) async {
    Widget picker(DateTime start, DateTime end) => comicApp(
      SingleChildScrollView(
        child: ComicDateRangePicker(
          firstDate: DateTime(2026),
          lastDate: DateTime(2028, 12, 31),
          currentDate: DateTime(2026, 11, 9),
          value: RawDateRange(start, end),
          onChanged: (_) {},
        ),
      ),
    );
    await tester.pumpWidget(
      picker(DateTime(2026, 11, 9), DateTime(2026, 11, 13)),
    );
    await tester.pump();
    expect(find.text('Nov 9 – Nov 13'), findsOneWidget);
    await tester.pumpWidget(picker(DateTime(2027, 1, 4), DateTime(2027, 1, 8)));
    await tester.pump();
    expect(find.text('Jan 4 – Jan 8, 2027'), findsOneWidget);
    await tester.pumpWidget(
      picker(DateTime(2026, 12, 28), DateTime(2027, 1, 3)),
    );
    await tester.pump();
    expect(find.text('Dec 28, 2026 – Jan 3, 2027'), findsOneWidget);
  });
}

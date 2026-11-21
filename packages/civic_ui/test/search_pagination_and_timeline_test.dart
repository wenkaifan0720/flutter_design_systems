// The parts that find things and tell their history: a search field's
// button and its keyboard key both search; pagination folds far pages,
// keeps the page shown out of reach and moves by its links; a timeline
// reads as a list; an empty state's title is a heading.
// ignore_for_file: avoid_relative_lib_imports
import 'package:civic_ui/civic_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../example/lib/kit_gallery/kit.dart';

Future<void> _pump(WidgetTester tester, Widget child, {double width = 390}) {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  return tester.pumpWidget(
    kitApp(
      brightness: Brightness.light,
      home: Padding(
        padding: const EdgeInsets.all(CivicSpacing.s20),
        child: Align(alignment: AlignmentDirectional.topStart, child: child),
      ),
    ),
  );
}

void main() {
  testWidgets('the search button and the search key both search', (
    tester,
  ) async {
    final searched = <String>[];
    await _pump(tester, CivicSearchField(onSubmitted: searched.add));
    expect(find.text('Search'), findsOneWidget);
    await tester.enterText(find.byType(EditableText), 'Quay');
    await tester.tap(find.byIcon(LucideIcons.search));
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    expect(searched, ['Quay', 'Quay']);
    // The button is a box's height and a box's width: a finger's floor.
    final button = tester.getSize(
      find.ancestor(
        of: find.byIcon(LucideIcons.search),
        matching: find.byType(RawButton),
      ),
    );
    expect(button.width, 48);
    expect(button.height, greaterThanOrEqualTo(48));
  });

  testWidgets('pagination folds far pages and moves by its links', (
    tester,
  ) async {
    var page = 5;
    await _pump(
      tester,
      StatefulBuilder(
        builder: (context, setState) => CivicPagination(
          pageCount: 12,
          selectedIndex: page,
          onPageChanged: (i) => setState(() => page = i),
        ),
      ),
      width: 1440,
    );
    // 1 … 5 6 7 … 12, between the two links.
    for (final n in ['1', '5', '6', '7', '12']) {
      expect(find.text(n), findsOneWidget, reason: n);
    }
    expect(find.text('2'), findsNothing);
    expect(find.text('…'), findsNWidgets(2));
    await tester.tap(find.text('Next page'));
    await tester.pump();
    expect(page, 6);
    await tester.tap(find.text('12'));
    await tester.pump();
    expect(page, 11);
    expect(find.text('Next page'), findsNothing);
    // The page shown is no link: a tap on it changes nothing.
    await tester.tap(find.text('12'));
    await tester.pump();
    expect(page, 11);
  });

  testWidgets('a phone shows the page, its neighbours and the ends', (
    tester,
  ) async {
    await _pump(
      tester,
      CivicPagination(pageCount: 12, selectedIndex: 5, onPageChanged: (_) {}),
    );
    for (final n in ['1', '5', '6', '7', '12']) {
      expect(find.text(n), findsOneWidget, reason: n);
    }
    expect(find.text('4'), findsNothing);
    expect(find.text('8'), findsNothing);
  });

  testWidgets('a fold never hides one page', (tester) async {
    await _pump(
      tester,
      CivicPagination(pageCount: 5, selectedIndex: 2, onPageChanged: (_) {}),
    );
    // 1 2 3 … would hide only 4: it shows 4 instead.
    for (final n in ['1', '2', '3', '4', '5']) {
      expect(find.text(n), findsOneWidget, reason: n);
    }
    expect(find.text('…'), findsNothing);
  });

  testWidgets('a page number says its place', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(
      tester,
      CivicPagination(pageCount: 3, selectedIndex: 0, onPageChanged: (_) {}),
    );
    expect(find.bySemanticsLabel('2 of 3'), findsOneWidget);
    expect(
      tester.getSemantics(find.bySemanticsLabel('1 of 3')),
      isSemantics(label: '1 of 3', isSelected: true),
    );
    handle.dispose();
  });

  testWidgets('a timeline is a list of its events, newest first', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pump(
      tester,
      const CivicTimeline(
        entries: [
          CivicTimelineEntry(title: 'Permit approved', date: '7 November'),
          CivicTimelineEntry(title: 'Application received', date: '3 November'),
        ],
      ),
    );
    final first = tester.getRect(find.text('Permit approved'));
    final second = tester.getRect(find.text('Application received'));
    expect(first.top, lessThan(second.top));
    expect(find.bySemanticsLabel(RegExp('Permit approved')), findsOneWidget);
    handle.dispose();
  });

  testWidgets("an empty state's title is a heading", (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(
      tester,
      const CivicEmptyState(
        title: 'You have no applications yet',
        children: [Text('When you apply, it will show here.')],
      ),
    );
    expect(
      tester.getSemantics(find.text('You have no applications yet')),
      isSemantics(label: 'You have no applications yet', isHeader: true),
    );
    handle.dispose();
  });
}

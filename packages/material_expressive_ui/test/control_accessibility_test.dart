import 'dart:ui' show CheckedState;

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

import 'gallery_support.dart';

Future<void> _show(
  WidgetTester tester,
  Widget child, {
  double scale = 1,
  double width = 390,
  TextDirection dir = TextDirection.ltr,
  Brightness brightness = Brightness.light,
}) async {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = Size(width * 2, 1800);
  addTearDown(tester.view.reset);
  final theme = ExpressiveThemeData.preset('baseline', brightness);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) => ExpressiveHost(
        theme: theme,
        darkTheme: theme,
        brightness: brightness,
        child: MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: Directionality(textDirection: dir, child: app!),
        ),
      ),
      home: SingleChildScrollView(
        child: Center(
          child: SizedBox(width: width - 32, child: child),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _key(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pumpAndSettle();
}

RenderParagraph _paragraph(WidgetTester tester, String text) =>
    tester.renderObject<RenderParagraph>(findRichText(text));

Finder findRichText(String text) => find
    .byWidgetPredicate(
      (widget) => widget is RichText && widget.text.toPlainText() == text,
    )
    .first;

void main() {
  setUpAll(loadExpressiveFonts);

  testWidgets('a split menu button announces expanded and closed', (
    tester,
  ) async {
    await _show(
      tester,
      ExpressiveSplitButton(
        'Save',
        onPressed: () {},
        menuLabel: 'Save options',
        menu: (context, close) => const SizedBox(width: 120, height: 50),
      ),
    );
    final trigger = find.bySemanticsLabel('Save options');
    final closed = tester
        .getSemantics(trigger)
        .getSemanticsData()
        .flagsCollection;
    expect(closed.isButton, isTrue);
    expect(closed.isToggled.toBoolOrNull(), isNull);
    expect(closed.isExpanded.toBoolOrNull(), isFalse);
    await tester.tap(trigger);
    await tester.pumpAndSettle();
    expect(
      tester
          .getSemantics(trigger)
          .getSemanticsData()
          .flagsCollection
          .isExpanded
          .toBoolOrNull(),
      isTrue,
    );
    await _key(tester, LogicalKeyboardKey.escape);
    expect(
      tester
          .getSemantics(trigger)
          .getSemanticsData()
          .flagsCollection
          .isExpanded
          .toBoolOrNull(),
      isFalse,
    );
  });

  testWidgets('a rating announces its name, score and selected star', (
    tester,
  ) async {
    var score = 1;
    await _show(
      tester,
      StatefulBuilder(
        builder: (context, set) => ExpressiveRating(
          semanticLabel: 'Rate this trip',
          value: score.toDouble(),
          onChanged: (value) => set(() => score = value),
        ),
      ),
    );
    await tester.tap(find.bySemanticsLabel('Rate 4 of 5'));
    await tester.pumpAndSettle();
    final group = tester.getSemantics(find.bySemanticsLabel('Rate this trip'));
    expect(group.value, 'Rated 4 of 5');
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('Rate 4 of 5'))
          .flagsCollection
          .isChecked,
      CheckedState.isTrue,
    );
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('Rate 3 of 5'))
          .flagsCollection
          .isChecked,
      CheckedState.isFalse,
    );
  });

  testWidgets('moving a focused reorder handle retains focus on its item', (
    tester,
  ) async {
    final items = ['Tea', 'Coffee', 'Water'];
    await _show(
      tester,
      StatefulBuilder(
        builder: (context, set) => ExpressiveReorderableListView(
          itemCount: items.length,
          onReorder: (from, to) =>
              set(() => items.insert(to, items.removeAt(from))),
          itemBuilder: (context, index) => ExpressiveListTile(
            key: ValueKey(items[index]),
            title: Text(items[index]),
            trailing: ExpressiveReorderHandle(index: index),
          ),
        ),
      ),
    );
    Future<void> move(LogicalKeyboardKey key) async {
      await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
      await _key(tester, key);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
      await tester.pumpAndSettle();
    }

    await _key(tester, LogicalKeyboardKey.tab);
    await move(LogicalKeyboardKey.arrowDown);
    expect(items, ['Coffee', 'Tea', 'Water']);
    expect(
      FocusManager.instance.primaryFocus?.context
          ?.findAncestorWidgetOfExactType<ExpressiveListTile>()
          ?.key,
      const ValueKey('Tea'),
    );
    await move(LogicalKeyboardKey.arrowUp);
    expect(items, ['Tea', 'Coffee', 'Water']);
  });

  testWidgets(
    'the dial has one tab stop and chooses hours and minutes by key',
    (tester) async {
      final time = ExpressiveTimePickerController(hour: 9, minute: 15);
      addTearDown(time.dispose);
      await _show(tester, ExpressiveTimePicker(controller: time));
      for (
        var i = 0;
        i < 9 && FocusManager.instance.primaryFocus?.debugLabel != 'Clock 9';
        i++
      ) {
        await _key(tester, LogicalKeyboardKey.tab);
      }
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'Clock 9');
      await _key(tester, LogicalKeyboardKey.arrowRight);
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'Clock 10');
      await _key(tester, LogicalKeyboardKey.enter);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(time.hour, 10);
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'Clock 15');
      await _key(tester, LogicalKeyboardKey.arrowLeft);
      await _key(tester, LogicalKeyboardKey.space);
      expect(time.minute, 10);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  for (final dir in TextDirection.values) {
    testWidgets(
      'bar and line tooltips follow the visible reading order ${dir.name}',
      (tester) async {
        const points = [
          ExpressiveChartPoint('Mon', 2),
          ExpressiveChartPoint('Tue', 8),
        ];
        for (final chart in [
          const ExpressiveChart.bar(
            points: points,
            tooltip: true,
            highlight: 0,
          ),
          const ExpressiveChart.line(
            points: points,
            tooltip: true,
            highlight: 0,
          ),
        ]) {
          await _show(tester, chart, dir: dir);
          final plot = tester.getRect(
            find
                .descendant(
                  of: find.byType(ExpressiveChart),
                  matching: find.byWidgetPredicate(
                    (w) => w is CustomPaint && w.painter != null,
                  ),
                )
                .first,
          );
          final monday = tester.getCenter(find.text('Mon'));
          final tuesday = tester.getCenter(find.text('Tue'));
          expect(monday.dx < tuesday.dx, dir == TextDirection.ltr);
          final mouse = await tester.createGesture(
            kind: PointerDeviceKind.mouse,
          );
          await mouse.addPointer();
          for (final (point, value) in [
            (monday, 'Mon · 2'),
            (tuesday, 'Tue · 8'),
          ]) {
            await mouse.moveTo(Offset(point.dx, plot.center.dy));
            await tester.pumpAndSettle();
            expect(find.text(value), findsOneWidget);
          }
          await mouse.removePointer();
          await tester.pumpAndSettle();
        }
      },
    );

    testWidgets('the current meter value precedes the limit ${dir.name}', (
      tester,
    ) async {
      await _show(
        tester,
        const ExpressiveMeter(label: 'Files', value: 2, limit: 8),
        dir: dir,
        scale: 2,
      );
      final text = _paragraph(tester, '2 / 8');
      final current = text
          .getBoxesForSelection(
            const TextSelection(baseOffset: 0, extentOffset: 1),
          )
          .single;
      final limit = text
          .getBoxesForSelection(
            const TextSelection(baseOffset: 4, extentOffset: 5),
          )
          .single;
      expect(current.right, lessThan(limit.left));
    });

    testWidgets(
      'a read-only select shows its full selected value ${dir.name}',
      (tester) async {
        const name = 'Kirk Creek Campground';
        await _show(
          tester,
          ExpressiveSelect<String>(
            labelText: 'Where you stay',
            value: name,
            options: const [ExpressiveSelectOption(name, name)],
            onChanged: (_) {},
          ),
          dir: dir,
          scale: 2,
        );
        final render = tester
            .state<EditableTextState>(find.byType(EditableText))
            .renderEditable;
        final lastWord = render.getBoxesForSelection(
          const TextSelection(baseOffset: 11, extentOffset: name.length),
        );
        expect(lastWord, isNotEmpty);
        for (final box in lastWord) {
          expect(box.left, greaterThanOrEqualTo(-1));
          expect(box.right, lessThanOrEqualTo(render.size.width + 1));
          expect(box.bottom, lessThanOrEqualTo(render.size.height + 1));
        }
      },
    );
    testWidgets(
      'calendar, status and timeline show complete text at 2x ${dir.name}',
      (tester) async {
        await _show(
          tester,
          ExpressiveDatePicker(
            currentDate: DateTime(2026, 9, 18),
            selected: DateTime(2026, 9, 18),
            initialMonth: DateTime(2026, 9),
            onChanged: (_) {},
          ),
          scale: 2,
          dir: dir,
        );
        for (final text in ['18 Sep 2026', 'September 2026']) {
          final paragraph = _paragraph(tester, text);
          expect(paragraph.didExceedMaxLines, isFalse, reason: text);
          final year = paragraph.getBoxesForSelection(
            TextSelection(
              baseOffset: text.length - 4,
              extentOffset: text.length,
            ),
          );
          expect(year, isNotEmpty);
          expect(
            year.last.bottom,
            lessThanOrEqualTo(paragraph.size.height + 1),
          );
        }
        await _show(
          tester,
          const Column(
            children: [
              ExpressiveStatusView.error(title: 'Service unavailable'),
              ExpressiveTimeline(
                entries: [
                  ExpressiveTimelineEntry(title: 'Packed', time: '10 am'),
                ],
              ),
            ],
          ),
          scale: 2,
          dir: dir,
        );
        for (final text in ['Packed', '10 am']) {
          final paragraph = _paragraph(tester, text);
          expect(
            paragraph.size.height + 1,
            greaterThanOrEqualTo(
              paragraph.getMinIntrinsicHeight(paragraph.size.width),
            ),
          );
        }
        final status = _paragraph(tester, 'Service unavailable');
        final word = status.getBoxesForSelection(
          const TextSelection(baseOffset: 8, extentOffset: 19),
        );
        expect(word.map((box) => box.top).toSet(), hasLength(1));
      },
    );

    testWidgets(
      'a swipe row exposes and activates the trailing action by key ${dir.name}',
      (tester) async {
        var archives = 0;
        final row = FocusNode();
        addTearDown(row.dispose);
        await _show(
          tester,
          ExpressiveSwipeActions(
            trailing: [
              ExpressiveSwipeAction(
                label: 'Archive',
                icon: ExpressiveSymbols.archive,
                onPressed: () => archives++,
              ),
            ],
            child: ExpressiveListTile(
              title: const Text('Route note'),
              focusNode: row,
              onTap: () {},
            ),
          ),
          dir: dir,
        );
        row.requestFocus();
        await tester.pumpAndSettle();
        final toward = dir == TextDirection.ltr
            ? LogicalKeyboardKey.arrowLeft
            : LogicalKeyboardKey.arrowRight;
        await _key(tester, toward);
        expect(find.bySemanticsLabel('Archive'), findsOneWidget);
        await _key(tester, LogicalKeyboardKey.escape);
        expect(find.bySemanticsLabel('Archive'), findsNothing);
        expect(row.hasPrimaryFocus, isTrue);
        await _key(tester, toward);
        await _key(tester, LogicalKeyboardKey.enter);
        expect(archives, 1);
        expect(row.hasPrimaryFocus, isTrue);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );

    testWidgets(
      'keyboard focus shows a tooltip until Escape or blur ${dir.name}',
      (tester) async {
        await _show(
          tester,
          Column(
            children: [
              ExpressiveTooltip.plain(
                message: 'Keep in Saved files',
                child: ExpressiveIconButton(
                  ExpressiveSymbols.bookmark,
                  semanticLabel: 'Bookmark',
                  onPressed: () {},
                ),
              ),
              ExpressiveTextButton('Next', onPressed: () {}),
            ],
          ),
          dir: dir,
        );
        await _key(tester, LogicalKeyboardKey.tab);
        expect(find.byType(ExpressivePlainTooltip), findsOneWidget);
        await _key(tester, LogicalKeyboardKey.escape);
        expect(find.byType(ExpressivePlainTooltip), findsNothing);
        await _key(tester, LogicalKeyboardKey.tab);
        expect(find.byType(ExpressivePlainTooltip), findsNothing);
      },
    );

    testWidgets('the 2x navigation badge stays in the bar ${dir.name}', (
      tester,
    ) async {
      await _show(
        tester,
        ExpressiveNavigationBar(
          selectedIndex: 0,
          onDestinationSelected: (_) {},
          destinations: const [
            ExpressiveNavItem(ExpressiveSymbols.home, 'Home'),
            ExpressiveNavItem(
              ExpressiveSymbols.inbox,
              'Inbox',
              badge: ExpressiveBadge.count(8),
            ),
          ],
        ),
        scale: 2,
        dir: dir,
      );
      final badge = tester.getRect(find.byType(ExpressiveBadge));
      final bar = tester.getRect(find.byType(ExpressiveNavigationBar));
      expect(badge.top, greaterThanOrEqualTo(bar.top + 4));
      expect(bar.contains(badge.bottomCenter), isTrue);
      final count = tester.getRect(findRichText('8'));
      expect(badge.top, lessThanOrEqualTo(count.top + 1));
      expect(badge.bottom + 1, greaterThanOrEqualTo(count.bottom));
    });
  }
}

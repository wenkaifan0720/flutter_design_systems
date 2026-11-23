// ui_core 0.3.0's routes and values in Comic's parts: the bottom sheet's drag and Comic's 640 cap, the tab bar's keys
// and words, the wheel picker's page keys and the chart's keys.
import 'dart:async';
import 'dart:ui' show SemanticsAction;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';

import 'support.dart';

Widget _opener(void Function(BuildContext context) open) => Builder(
  builder: (context) =>
      Center(child: ComicButton('Open', onPressed: () => open(context))),
);

void main() {
  setUpAll(loadComicFonts);

  testWidgets('a bottom sheet follows a drag down and goes', (tester) async {
    await tester.pumpWidget(
      comicApp(
        _opener(
          (context) => unawaited(
            showComicBottomSheet<void>(
              context,
              builder: (_) => const ComicBottomSheet(
                title: 'Details',
                child: Text('Issue 12'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('OPEN'));
    await tester.pumpAndSettle();
    expect(find.text('Issue 12'), findsOneWidget);
    await tester.fling(find.text('Issue 12'), const Offset(0, 400), 2000);
    await tester.pumpAndSettle();
    expect(find.text('Issue 12'), findsNothing);
  });

  testWidgets(
    'on a wide window a bottom sheet stands 640 wide, centred, and a press beside it closes it',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1440, 900);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        comicApp(
          width: 1440,
          _opener(
            (context) => unawaited(
              showComicBottomSheet<void>(
                context,
                builder: (_) => const ComicBottomSheet(
                  title: 'Details',
                  child: Text('Issue 12'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();
      final sheet = tester.getRect(find.byType(ComicBottomSheet));
      expect(sheet.width, lessThanOrEqualTo(640));
      expect(sheet.center.dx, moreOrLessEquals(720, epsilon: 1));
      await tester.tapAt(Offset(sheet.left - 40, sheet.center.dy));
      await tester.pumpAndSettle();
      expect(find.text('Issue 12'), findsNothing);
    },
  );

  testWidgets(
    'a tab bar is one stop: the arrows choose, mirrored right to left, and each tab says its place',
    (tester) async {
      for (final direction in TextDirection.values) {
        var chosen = 0;
        await tester.pumpWidget(
          comicApp(
            direction: direction,
            StatefulBuilder(
              builder: (context, setState) => Padding(
                padding: const EdgeInsets.all(12),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ComicTabBar(
                    tabs: const ['All', 'Saved', 'Finished'],
                    selectedIndex: chosen,
                    onTap: (i) => setState(() => chosen = i),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.bySemanticsLabel(RegExp(r'^Saved\nTab 2 of 3$')),
          findsOneWidget,
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(
          direction == TextDirection.ltr
              ? LogicalKeyboardKey.arrowRight
              : LogicalKeyboardKey.arrowLeft,
        );
        await tester.pumpAndSettle();
        expect(chosen, 1);
        await tester.sendKeyEvent(LogicalKeyboardKey.end);
        await tester.pumpAndSettle();
        expect(chosen, 2);
      }
    },
  );

  testWidgets(
    'a wheel picker steps five with Page Down and its ends with Home',
    (tester) async {
      var copies = 1;
      await tester.pumpWidget(
        comicApp(
          StatefulBuilder(
            builder: (context, setState) => Padding(
              padding: const EdgeInsets.all(12),
              child: ComicWheelPicker<int>(
                label: 'Copies',
                values: [for (var i = 1; i <= 20; i++) i],
                value: copies,
                labelOf: (n) => '$n',
                autofocus: true,
                onChanged: (n) => setState(() => copies = n),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
      await tester.pumpAndSettle();
      expect(copies, 6);
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pumpAndSettle();
      expect(copies, 1);
      final wheel = tester
          .getSemantics(find.bySemanticsLabel('Copies'))
          .getSemanticsData();
      expect(wheel.value, '1');
      expect(wheel.increasedValue, '2');
      expect(wheel.hasAction(SemanticsAction.increase), isTrue);
    },
  );

  testWidgets(
    "a chart's keys read its points, and its summary is the chart's one node",
    (tester) async {
      await tester.pumpWidget(
        comicApp(
          const Padding(
            padding: EdgeInsets.all(12),
            child: ComicChart(
              label: 'Weekly pages',
              labels: ['Mon', 'Tue', 'Wed'],
              series: [
                ComicChartSeries('Pages', [12, 18, 16]),
                ComicChartSeries('Goal', [15, 15, 15]),
              ],
            ),
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      // The readout plate names the day and every series on it.
      expect(find.text('Pages: 12'), findsOneWidget);
      expect(find.text('Goal: 15'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pumpAndSettle();
      expect(find.text('Pages: 16'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Pages: 16'), findsNothing);
      // One node under the chart says it all: its own label and summary, not merged up from below.
      final read = tester.getSemantics(find.bySemanticsLabel('Weekly pages'));
      expect(read.isMergedIntoParent, isFalse);
      expect(read.label, 'Weekly pages');
      expect(read.value, 'Pages: 12, 18, 16; Goal: 15, 15, 15');
    },
  );
}

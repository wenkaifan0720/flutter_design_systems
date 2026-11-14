import 'dart:ui' show CheckedState, SemanticsAction;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';

import 'support.dart';

Widget _host(
  Widget child, {
  bool still = true,
  TextDirection direction = TextDirection.ltr,
}) => MaterialApp(
  builder: (context, home) => ComicTheme(
    data: ComicThemeData.offset(),
    child: MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: still),
      child: Directionality(textDirection: direction, child: home!),
    ),
  ),
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  setUpAll(loadComicFonts);
  testWidgets(
    'checkbox cycles false true mixed false and exposes mixed semantics',
    (tester) async {
      bool? value = false;
      final values = <bool?>[];
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, setState) => ComicCheckbox(
              value: value,
              tristate: true,
              label: 'Select issues',
              onChanged: (next) {
                values.add(next);
                setState(() => value = next);
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ComicCheckbox));
      await tester.pump();
      await tester.tap(find.byType(ComicCheckbox));
      await tester.pump();
      // The press's own node (on the pressable, getSemantics starts at its reach box, which owns none, and walks up).
      expect(
        tester
                .getSemantics(find.bySemanticsLabel('Select issues'))
                .getSemanticsData()
                .flagsCollection
                .isChecked ==
            CheckedState.mixed,
        isTrue,
      );
      await tester.tap(find.byType(ComicCheckbox));
      await tester.pump();
      expect(values, [true, null, false]);
    },
  );
  for (final direction in TextDirection.values) {
    testWidgets('tabs use arrows in ${direction.name} and one callback', (
      tester,
    ) async {
      final hits = <int>[];
      var selected = 1;
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, setState) => ComicTabBar(
              tabs: const ['All', 'Saved', 'Read'],
              selectedIndex: selected,
              onChanged: (next) {
                hits.add(next);
                setState(() => selected = next);
              },
            ),
          ),
          direction: direction,
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(hits, [direction == TextDirection.ltr ? 2 : 0]);
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pump();
      expect(hits.last, 2);
      expect(tester.takeException(), isNull);
    });
    testWidgets('slider keyboard and semantics settle in ${direction.name}', (
      tester,
    ) async {
      final changes = <double>[], ends = <double>[];
      var value = 50.0;
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, setState) => ComicSlider(
              label: 'Budget',
              value: value,
              min: 0,
              max: 100,
              divisions: 10,
              onChanged: (next) {
                changes.add(next);
                setState(() => value = next);
              },
              onChangeEnd: ends.add,
            ),
          ),
          direction: direction,
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(changes, [direction == TextDirection.ltr ? 60 : 40]);
      expect(ends, changes);
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pump();
      expect(value, 0);
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pump();
      expect(value, 100);

      final node = tester.getSemantics(find.bySemanticsLabel('Budget'));
      expect(node.getSemanticsData().flagsCollection.isSlider, isTrue);
      expect(
        node.getSemanticsData().hasAction(SemanticsAction.decrease),
        isTrue,
      );
      node.owner!.performAction(node.id, SemanticsAction.decrease);
      await tester.pump();
      expect(value, 90);
      expect(ends.last, 90);
    });
  }
  testWidgets(
    'slider drag reports one final value and disabled ignores input',
    (tester) async {
      final changes = <double>[], ends = <double>[];
      var value = .2;
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 300,
            child: StatefulBuilder(
              builder: (context, setState) => ComicSlider(
                label: 'Volume',
                value: value,
                onChanged: (next) {
                  changes.add(next);
                  setState(() => value = next);
                },
                onChangeEnd: ends.add,
              ),
            ),
          ),
        ),
      );
      await tester.drag(find.byType(ComicSlider), const Offset(100, 0));
      await tester.pump();
      expect(changes, isNotEmpty);
      expect(ends.length, 1);
      expect(ends.single, changes.last);
      await tester.pumpWidget(
        _host(const ComicSlider(label: 'Closed', value: .5)),
      );
      await tester.tap(find.byType(ComicSlider));
      await tester.pump();
      expect(ends.length, 1);
    },
  );
  testWidgets(
    'calendar month walking clamps days and external value updates visible month',
    (tester) async {
      DateTime value = DateTime(2026, 1, 31);
      late StateSetter redraw;
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, setState) {
              redraw = setState;
              return ComicDatePicker(
                value: value,
                firstDate: DateTime(2026),
                lastDate: DateTime(2026, 12, 31),
                onChanged: (day) => setState(() => value = day),
              );
            },
          ),
        ),
      );
      final next = find.byWidgetPredicate(
        (w) => w is ComicIconButton && w.label == 'Next month',
      );
      await tester.tap(next);
      await tester.pump();
      expect(find.text('February 2026'), findsOneWidget);
      expect(find.text('31'), findsNothing);
      redraw(() => value = DateTime(2026, 6, 12));
      await tester.pump();
      expect(find.text('June 2026'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('choosing a day moves no row of the calendar', (tester) async {
    // A chosen day draws a heavier rim than the days beside it; the rim must
    // not make its row taller (today's day, with its dot, is the tallest).
    final today = DateTime(2026, 11, 9);
    Rect last() => tester.getRect(find.text('30'));
    await tester.pumpWidget(
      _host(
        ComicDatePicker(value: null, currentDate: today, onChanged: (_) {}),
      ),
    );
    final before = last();
    for (final day in [today, DateTime(2026, 11, 3)]) {
      await tester.pumpWidget(
        _host(
          ComicDatePicker(value: day, currentDate: today, onChanged: (_) {}),
        ),
      );
      expect(last(), before, reason: 'choosing ${day.day} moved the rows');
    }
  });
  testWidgets('calendar excludes out-of-range dates and returns a date once', (
    tester,
  ) async {
    final picked = <DateTime>[];
    await tester.pumpWidget(
      _host(
        ComicDatePicker(
          value: DateTime(2026, 11, 6),
          firstDate: DateTime(2026, 11, 5),
          lastDate: DateTime(2026, 11, 8),
          onChanged: picked.add,
        ),
      ),
    );
    await tester.tap(find.text('4'));
    await tester.pump();
    expect(picked, isEmpty);
    await tester.tap(find.text('7'));
    await tester.pump();
    expect(picked, [DateTime(2026, 11, 7)]);
    expect(
      tester
          .widget<ComicIconButton>(
            find.byWidgetPredicate(
              (w) => w is ComicIconButton && w.label == 'Previous month',
            ),
          )
          .onPressed,
      isNull,
    );
  });
  testWidgets(
    'date picker confirmation returns selected date and cancellation returns null',
    (tester) async {
      DateTime? result;
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (context) => ComicButton(
              'Open',
              onPressed: () async {
                result = await showComicDatePicker(
                  context,
                  value: DateTime(2026, 11, 6),
                );
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('7'));
      await tester.pump();
      await tester.tap(find.text('CHOOSE'));
      await tester.pumpAndSettle();
      expect(result, DateTime(2026, 11, 7));
      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('CANCEL'));
      await tester.pumpAndSettle();
      expect(result, isNull);
    },
  );
  test('time is a value type and formats at noon and midnight', () {
    expect(const ComicTime(0, 5).format(use24hFormat: true), '00:05');
    expect(const ComicTime(12, 0), const ComicTime(12, 0));
    expect(const ComicTime(12, 0).hashCode, const ComicTime(12, 0).hashCode);
    expect(() => ComicTime(24, 0), throwsAssertionError);
  });
  testWidgets('time menus preserve minute precision and change period', (
    tester,
  ) async {
    ComicTime value = const ComicTime(7, 17);
    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setState) => ComicTimePicker(
            value: value,
            minuteStep: 15,
            onChanged: (time) => setState(() => value = time),
          ),
        ),
      ),
    );
    expect(find.text('17'), findsOneWidget);
    await tester.tap(find.text('AM'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('PM'));
    await tester.pumpAndSettle();
    expect(value, const ComicTime(19, 17));
  });
  testWidgets('disclosure supports controlled and uncontrolled state', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const ComicDisclosure(title: 'Details', child: Text('Full story'))),
    );
    expect(find.text('Full story'), findsNothing);
    await tester.tap(find.text('Details'));
    await tester.pump();
    expect(find.text('Full story'), findsOneWidget);
    final requested = <bool>[];
    await tester.pumpWidget(
      _host(
        ComicDisclosure(
          key: const ValueKey('controlled'),
          title: 'Details',
          expanded: false,
          onExpansionChanged: requested.add,
          child: const Text('Full story'),
        ),
      ),
    );
    await tester.tap(find.text('Details'));
    await tester.pump();
    expect(requested, [true]);
    expect(find.text('Full story'), findsNothing);
  });
  testWidgets('table becomes labelled ledger cards at compact width', (
    tester,
  ) async {
    const table = ComicTable(
      columns: ['Issue', 'Pages'],
      rows: [
        ['Twelve', '24'],
        ['Thirteen', '32'],
      ],
    );
    await tester.pumpWidget(_host(const SizedBox(width: 390, child: table)));
    expect(find.byType(Table), findsNothing);
    expect(find.text('Issue'), findsNWidgets(2));
    await tester.pumpWidget(_host(const SizedBox(width: 700, child: table)));
    expect(find.byType(Table), findsOneWidget);
    expect(find.text('Issue'), findsOneWidget);
  });
  testWidgets('busy action keeps focus but suppresses pointer and keys', (
    tester,
  ) async {
    var hits = 0, busy = false;
    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setState) => ComicButton.filled(
            'Save',
            busy: busy,
            onPressed: () {
              hits++;
              setState(() => busy = true);
            },
          ),
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    final node = FocusManager.instance.primaryFocus;
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(hits, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.tap(
      find.byWidgetPredicate((w) => '${w.runtimeType}' == '_Filled'),
    );
    await tester.pump();
    expect(hits, 1);
    expect(FocusManager.instance.primaryFocus, node);
    expect(find.byType(ComicCircularProgressIndicator), findsOneWidget);
  });
  testWidgets(
    'all waiting indicators stop with reduced motion and resume when enabled',
    (tester) async {
      const parts = Column(
        children: [
          ComicCircularProgressIndicator(),
          ComicLinearProgressIndicator(),
          ComicSkeleton(),
        ],
      );
      await tester.pumpWidget(_host(parts));
      await tester.pump();
      expect(tester.binding.hasScheduledFrame, isFalse);
      await tester.pumpWidget(_host(parts, still: false));
      await tester.pump(const Duration(milliseconds: 20));
      expect(tester.binding.hasScheduledFrame, isTrue);
      await tester.pumpWidget(_host(parts));
      await tester.pump();
      expect(tester.binding.hasScheduledFrame, isFalse);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('notice dismiss and removable chip call once', (tester) async {
    var dismissed = 0, deleted = 0;
    await tester.pumpWidget(
      _host(
        Column(
          children: [
            ComicBanner('Saved', onDismiss: () => dismissed++),
            ComicChip('History', onDeleted: () => deleted++),
          ],
        ),
      ),
    );
    await tester.tap(
      find.byWidgetPredicate(
        (w) => w is ComicIconButton && w.label == 'Dismiss',
      ),
    );
    await tester.pump();
    // The chip's cross is its own press inside the chip's face (11-12), not an icon button beside it.
    await tester.tap(
      find.byWidgetPredicate(
        (w) => w is ComicPressable && w.label == 'Delete History',
      ),
    );
    await tester.pump();
    expect(dismissed, 1);
    expect(deleted, 1);
  });
  for (final width in [320.0, 390.0, 1440.0]) {
    for (final direction in TextDirection.values) {
      testWidgets('new parts at 2x $width ${direction.name}', (tester) async {
        tester.view.physicalSize = Size(width, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          _host(
            Builder(
              builder: (context) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(2)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ComicButton.text(longLine, onPressed: () {}),
                      ComicButton(
                        longLine,
                        isDestructiveAction: true,
                        icon: ComicGlyphs.trash2,
                        onPressed: () {},
                      ),
                      ComicChip(longLine, onDeleted: () {}),
                      ComicTabBar(
                        tabs: const [long, 'Saved'],
                        onChanged: (_) {},
                      ),
                      const ComicStepProgress(
                        count: 6,
                        currentStep: 2,
                        name: longLine,
                      ),
                      const ComicCard(
                        title: longLine,
                        children: [Text(longLine)],
                      ),
                      const ComicTable(
                        columns: ['Issue', 'Pages'],
                        rows: [
                          [long, '24'],
                        ],
                      ),
                      const ComicBanner(
                        longLine,
                        title: longLine,
                        tone: ComicTone.warning,
                      ),
                      ComicDatePicker(
                        value: DateTime(2026, 11, 6),
                        onChanged: (_) {},
                      ),
                      ComicTimePicker(
                        value: const ComicTime(19, 30),
                        onChanged: (_) {},
                      ),
                      const ComicMeter(label: longLine, value: .5),
                    ],
                  ),
                ),
              ),
            ),
            direction: direction,
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
      });
    }
  }

  // Round 4, from the round-3 review: guides on round steps, a bar under its
  // own head, and a series too light for the page inked.
  group('round guides, labelled bars, inked light series', () {
    List<String> guides(WidgetTester tester) {
      final ink = tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((p) => p.painter)
          .firstWhere((p) => p.runtimeType.toString() == '_ChartInk');
      return ((ink as dynamic).ticks as List).cast<String>();
    }

    for (final (name, values, band, want) in [
      (
        'a line to 27 with a band to 22',
        const <double?>[12, 18, 16, 24, 21, 27],
        const ComicChartBand(15, 22),
        ['30', '20', '10', '0'],
      ),
      (
        'an area to 612',
        const <double?>[310, 402, 380, 520, 612, 590],
        null,
        ['750', '500', '250', '0'],
      ),
      (
        'a count to 12',
        const <double?>[3, 5, 4, 8, 7, 9, 12],
        null,
        ['15', '10', '5', '0'],
      ),
    ]) {
      testWidgets('$name: guides on round steps', (tester) async {
        await tester.pumpWidget(
          comicApp(
            SizedBox(
              width: 360,
              height: 240,
              child: ComicChart(
                label: name,
                series: [ComicChartSeries('One', values)],
                band: band,
              ),
            ),
          ),
        );
        expect(guides(tester), want);
      });
    }

    testWidgets('a bar with a label stands under its head, read together', (
      tester,
    ) async {
      await tester.pumpWidget(
        comicApp(
          const Center(
            child: SizedBox(
              width: 300,
              child: ComicBar(
                value: 5,
                of: 6,
                label: 'Pages inked',
                figure: '5 of 6',
              ),
            ),
          ),
        ),
      );
      final head = tester.getRect(find.text('Pages inked'));
      final bar = tester.getRect(find.byType(CustomPaint).last);
      expect(head.bottom, lessThanOrEqualTo(bar.top));
      expect(
        tester.getSemantics(find.text('Pages inked')).label,
        contains('5 of 6'),
      );
    });

    testWidgets('a series too light for the page is drawn over ink', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 300);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final key = GlobalKey();
      await tester.pumpWidget(
        comicApp(
          Center(
            child: RepaintBoundary(
              key: key,
              child: const SizedBox(
                width: 360,
                height: 220,
                child: ComicChart(
                  label: 'Flat',
                  labels: ['A', 'B', 'C'],
                  series: [
                    ComicChartSeries('Yellow', [5, 5, 5]),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      final colors = ComicTheme.of(tester.element(find.byType(ComicChart)))
          .colors;
      double lum(Color c) => c.computeLuminance();
      double ratio(Color a, Color b) {
        final hi = lum(a) > lum(b) ? lum(a) : lum(b);
        final lo = lum(a) > lum(b) ? lum(b) : lum(a);
        return (hi + .05) / (lo + .05);
      }

      final yellow = colors.series.first;
      expect(ratio(yellow, colors.background), lessThan(3)); // why it is inked
      final (width, height, bytes) = (await tester.runAsync(() async {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(key),
        );
        final image = await boundary.toImage();
        final data = await image.toByteData();
        return (image.width, image.height, data!);
      }))!;
      Color at(int x, int y) {
        final i = (y * width + x) * 4;
        return Color.fromARGB(
          bytes.getUint8(i + 3),
          bytes.getUint8(i),
          bytes.getUint8(i + 1),
          bytes.getUint8(i + 2),
        );
      }

      bool near(Color a, Color b) =>
          ((a.r - b.r).abs() + (a.g - b.g).abs() + (a.b - b.b).abs()) < .06;
      // A column through the flat line, between two points: the yellow run
      // has ink right above and right below it.
      final x = (width * .38).round();
      final run = [
        for (var y = 0; y < height; y++)
          if (near(at(x, y), yellow)) y,
      ];
      expect(run, isNotEmpty);
      // The darkest row within two of each edge of the yellow (antialiasing
      // blends the first).
      for (final (side, rows) in [
        ('above', [run.first - 1, run.first - 2]),
        ('below', [run.last + 1, run.last + 2]),
      ]) {
        final best = rows
            .map((y) => ratio(at(x, y), colors.background))
            .reduce((a, b) => a > b ? a : b);
        expect(best, greaterThanOrEqualTo(3), reason: 'ink $side the line');
      }
      // Drawn pixels: the rasterizer's, as a golden's (Linux CI leaves it to macOS).
    }, tags: 'goldens');
  });

  // An x label stands on its point (a line) or its group (bars), at its own
  // width, never moved off it; when they don't all fit they thin evenly, the
  // first and the last kept.
  group("a chart's x labels", () {
    const weeks = ['Wk 1', 'Wk 2', 'Wk 3', 'Wk 4', 'Wk 5', 'Wk 6'];
    for (final width in const [390.0, 1440.0, 200.0]) {
      for (final bars in const [false, true]) {
        for (final dir in TextDirection.values) {
          testWidgets('${bars ? 'bars' : 'a line'} @$width ${dir.name}', (
            tester,
          ) async {
            tester.view.physicalSize = Size(width, 900);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.reset);
            await tester.pumpWidget(
              comicApp(
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ComicChart(
                    label: 'Orders',
                    labels: weeks,
                    type: bars ? ComicChartType.bar : ComicChartType.line,
                    series: const [
                      ComicChartSeries('Online', [42, 51, 38, 60, 55, 64]),
                    ],
                    band: const ComicChartBand(40, 50, label: 'Target'),
                  ),
                ),
                direction: dir,
              ),
            );
            expect(tester.takeException(), isNull);
            final rtl = dir == TextDirection.rtl;
            // The plot as the ink lays it: the label row's own padding is the
            // axis gutter and the end room, then 4 of air.
            final row = find
                .ancestor(of: find.text('Wk 1'), matching: find.byType(Padding))
                .first;
            final pad =
                tester.widget<Padding>(row).padding as EdgeInsetsDirectional;
            final box = tester.getRect(row);
            final left = box.left + (rtl ? pad.end : pad.start) + 4;
            final right = box.right - (rtl ? pad.start : pad.end) - 4;
            double point(int i) {
              final at = bars ? (i + .5) / 6 : i / 5;
              return rtl
                  ? right - at * (right - left)
                  : left + at * (right - left);
            }

            final shown = [
              for (var i = 0; i < 6; i++)
                if (find.text(weeks[i]).evaluate().isNotEmpty) i,
            ];
            expect(shown.first, 0);
            expect(shown.last, 5);
            final steps = {
              for (var j = 1; j < shown.length; j++) shown[j] - shown[j - 1],
            };
            expect(steps, hasLength(1), reason: 'thinned unevenly: $shown');
            if (width >= 390) expect(shown, hasLength(6));
            for (final i in shown) {
              final r = tester.getRect(find.text(weeks[i]));
              expect(
                (r.center.dx - point(i)).abs(),
                lessThan(.5),
                reason:
                    '${weeks[i]} at ${r.center.dx}, its point at ${point(i)}',
              );
            }
            // A touch at a point reads that point: the plate and the ink use
            // the same places.
            for (final i in const [0, 2, 5]) {
              await tester.tapAt(
                Offset(
                  point(i),
                  tester.getRect(find.byType(ComicChart)).top + 60,
                ),
              );
              await tester.pump();
              expect(
                find.text('Online: ${[42, 51, 38, 60, 55, 64][i]}'),
                findsOneWidget,
                reason: 'a touch at ${weeks[i]}',
              );
            }
            // The band keys its own fill.
            final entry = find
                .ancestor(of: find.text('Target'), matching: find.byType(Row))
                .first;
            final swatch = tester.widget<Container>(
              find
                  .descendant(of: entry, matching: find.byType(Container))
                  .first,
            );
            expect(
              (swatch.decoration! as ShapeDecoration).color,
              ComicTheme.of(tester.element(entry)).colors.currentUserTint,
            );
          });
        }
      }
    }
  });

  testWidgets('a segment too narrow for its number keys it under the bar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      comicApp(
        const Center(
          child: SizedBox(
            width: 536,
            child: ComicSegments(
              [8, 5, 2, 5, 45, 5],
              long: 4,
              scaleStart: '0',
              scaleEnd: '70',
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    final key = find.ancestor(of: find.text('3'), matching: find.byType(Wrap));
    expect(key, findsOneWidget);
    final entry = find
        .ancestor(of: find.text('3'), matching: find.byType(Row))
        .first;
    expect(
      find.descendant(of: entry, matching: find.text('2')),
      findsOneWidget,
    );
  });
}

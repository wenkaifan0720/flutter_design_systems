// Each signature part with odd data: empty, one, many, long words, RTL. No overflow, no exception, at 320 and 1440, light and dark.
// The real faces are loaded, so a long word is measured as it would be on a device.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import 'support.dart';

NeumorphicBay _bay(int i, {String name = 'A room', double lit = 0}) =>
    NeumorphicBay(figure: '${18 + i}°', name: name, note: 'A note', lit: lit);

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadNeumorphicFonts();
  });

  group('NeumorphicDial', () {
    testWidgets(
      'its keys stay beside it in a very wide column, on a round scale',
      (tester) async {
        tester.view.physicalSize = const Size(1440, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(size: Size(1440, 1000)),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: NeumorphicTheme(
                data: NeumorphicThemeData.preset('porcelain', Brightness.light),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: 1170,
                    child: NeumorphicDial(
                      value: 72,
                      min: 40,
                      max: 90,
                      figure: '72',
                      onDecrease: () {},
                      onIncrease: () {},
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        final keys = find.byType(NeumorphicRoundButton);
        final apart =
            tester.getCenter(keys.last).dx - tester.getCenter(keys.first).dx;
        expect(apart, lessThan(620));
        expect(find.text('50'), findsOneWidget);
        expect(find.text('52.5'), findsNothing);
      },
    );
    check(
      'whole',
      () => NeumorphicDial(
        value: 21.5,
        min: 10,
        max: 30,
        now: 21,
        step: .5,
        major: 5,
        label: 'Rising to',
        labelIcon: NeumorphicGlyphs.flame,
        figure: '21.5°',
        sub: 'Now 21.0°',
        caption: '21.5° by about 20:25',
        captionDetail: 'Set at 19:45',
        onDecrease: () {},
        onIncrease: () {},
      ),
    );
    check(
      'compact',
      () => const NeumorphicDial(
        compact: true,
        value: 40,
        figure: '40',
        label: 'A label',
        caption: longLine,
      ),
    );
    check('bare', () => const NeumorphicDial(value: 0, figure: '0'));
    check(
      'below its scale',
      () => const NeumorphicDial(value: -40, figure: '-40'),
    );
    check(
      'over its scale',
      () => const NeumorphicDial(value: 400, figure: '400'),
    );
    check(
      'a scale of nothing',
      () => const NeumorphicDial(value: 1, min: 5, max: 5, figure: '5'),
    );
    check(
      'long words',
      () => const NeumorphicDial(
        value: 50,
        figure: '1,204,000,000',
        label: long,
        sub: longLine,
        caption: longLine,
        captionDetail: long,
      ),
    );
  });

  group('NeumorphicSpanDial', () {
    const span = NeumorphicSpanDial(
      start: '12:30',
      end: '13:15',
      elapsed: 35,
      total: 45,
      tag: '13:05',
      figure: '10',
      unit: 'min left',
      title: 'A thing that is on now',
      note: 'A place',
      noteMark: NeumorphicShapeMark(NeumorphicMarkShape.half),
    );
    check('whole', () => span);
    check(
      'compact',
      () => const NeumorphicSpanDial(
        compact: true,
        start: '12:30',
        end: '13:15',
        elapsed: 35,
        total: 45,
        figure: '10',
        unit: 'min left',
        title: longLine,
      ),
    );
    check(
      'nothing gone, all gone, none to count',
      () => const NeumorphicColumn(
        children: [
          NeumorphicSpanDial(
            start: 'a',
            end: 'b',
            elapsed: 0,
            total: 45,
            figure: '45',
          ),
          NeumorphicSpanDial(
            start: 'a',
            end: 'b',
            elapsed: 45,
            total: 45,
            figure: '0',
          ),
          NeumorphicSpanDial(
            start: 'a',
            end: 'b',
            elapsed: 9,
            total: 0,
            figure: '0',
          ),
        ],
      ),
    );
    check(
      'a long span and long words',
      () => const NeumorphicSpanDial(
        start: '2026-01-01',
        end: '2026-12-31',
        elapsed: 200,
        total: 365,
        figure: '1,204,000',
        unit: long,
        tag: long,
        title: long,
        note: longLine,
      ),
    );
  });

  group('NeumorphicGauge, NeumorphicKnob', () {
    check(
      'a row of three',
      () => const NeumorphicGridOf(
        columns: 3,
        gap: 8,
        children: [
          NeumorphicGauge(
            value: 40,
            figure: '40',
            name: 'A',
            note: 'B',
            live: true,
            noteIcon: NeumorphicGlyphs.flame,
          ),
          NeumorphicGauge(value: 0, figure: '0', name: long, note: longLine),
          NeumorphicGauge(value: 200, now: 90, figure: '1,204,000', name: 'C'),
        ],
      ),
    );
    check(
      'knob row',
      () =>
          const NeumorphicKnobRow(value: .4, label: long, figure: '1,204,000'),
    );
  });

  group('NeumorphicRelief', () {
    check(
      'whole',
      () => NeumorphicRelief(
        title: '14',
        subtitle: 'A place',
        count: '*5 of 9* on',
        courses: [
          NeumorphicCourse('Upper', [_bay(0), _bay(1), _bay(2)]),
          NeumorphicCourse('Middle', [
            _bay(3, lit: .8),
            const NeumorphicBay(
              name: 'A',
              lit: .8,
              flag: NeumorphicGlyphs.bell,
            ),
            _bay(5),
          ]),
          NeumorphicCourse('Lower', [
            _bay(6, lit: .4),
            _bay(7, lit: .2),
            _bay(8),
          ]),
        ],
        ground: const [
          NeumorphicGroundNote('A note', icon: NeumorphicGlyphs.trees),
          NeumorphicGroundNote('Another'),
          NeumorphicGroundNote('A third'),
        ],
      ),
    );
    check(
      'compact',
      () => NeumorphicRelief(
        compact: true,
        title: '14',
        subtitle: longLine,
        count: long,
        courses: [
          NeumorphicCourse('Upper', [_bay(0), _bay(1, lit: .4)]),
        ],
      ),
    );
    check('empty', () => const NeumorphicRelief(title: ''));
    check(
      'a floor with no bays',
      () => const NeumorphicRelief(
        title: '1',
        courses: [NeumorphicCourse('A', [])],
      ),
    );
    check(
      'one bay, many bays, long words',
      () => NeumorphicRelief(
        title: long,
        subtitle: longLine,
        count: longLine,
        courses: [
          NeumorphicCourse(longLine, [_bay(0, name: long)]),
          NeumorphicCourse(long, [
            for (var i = 0; i < 11; i++)
              _bay(i, name: long, lit: i.isEven ? .5 : 0),
          ]),
        ],
        ground: const [
          NeumorphicGroundNote(longLine),
          NeumorphicGroundNote(longLine),
        ],
      ),
    );
  });

  group('NeumorphicPushGroup', () {
    check('empty', () => const NeumorphicPushGroup(items: []));
    check(
      'one',
      () => const NeumorphicPushGroup(
        items: [
          NeumorphicPush(
            icon: NeumorphicGlyphs.sun,
            label: 'One',
            selected: true,
          ),
        ],
      ),
    );
    check(
      'many, long',
      () => NeumorphicPushGroup(
        items: [
          for (var i = 0; i < 9; i++)
            NeumorphicPush(
              icon: NeumorphicGlyphs.sun,
              label: i == 3 ? long : 'A label',
              note: i == 5 ? longLine : 'A note',
              selected: i == 2,
              onPressed: () {},
            ),
        ],
      ),
    );
  });

  group('NeumorphicDayTray', () {
    check('empty', () => const NeumorphicDayTray());
    check('one hour', () => const NeumorphicDayTray(from: 9, to: 9));
    check(
      'now is outside it',
      () => const NeumorphicDayTray(from: 9, to: 12, now: '23:50'),
    );
    check(
      'bad times',
      () => const NeumorphicDayTray(
        events: [
          NeumorphicTrayEvent(start: 'soon', end: 'later', title: 'A'),
          NeumorphicTrayEvent(start: '09:00', end: '09:00', title: 'B'),
          NeumorphicTrayEvent(start: '10:00', end: '09:00', title: 'C'),
        ],
        free: [NeumorphicTrayFree('x', 'y', 'Free')],
      ),
    );
    check(
      'a day of it',
      () => NeumorphicDayTray(
        now: '13:05',
        free: const [NeumorphicTrayFree('17:00', '18:00', 'Free, 1 h')],
        events: [
          const NeumorphicTrayEvent(
            start: '09:00',
            end: '09:15',
            title: long,
            subtitle: longLine,
            mark: NeumorphicMarkShape.solid,
          ),
          const NeumorphicTrayEvent(
            start: '09:00',
            end: '09:30',
            title: long,
            subtitle: longLine,
            mark: NeumorphicMarkShape.ring,
          ),
          const NeumorphicTrayEvent(
            start: '10:00',
            end: '11:30',
            title: long,
            subtitle: longLine,
            detail: longLine,
            isPast: true,
          ),
          NeumorphicTrayEvent(
            start: '12:30',
            end: '13:15',
            title: long,
            subtitle: longLine,
            isCurrent: true,
            onPressed: () {},
          ),
          const NeumorphicTrayEvent(
            start: '14:00',
            end: '15:00',
            title: 'A',
            mark: NeumorphicMarkShape.half,
          ),
          const NeumorphicTrayEvent(
            start: '14:30',
            end: '14:45',
            title: 'B',
            subtitle: 'C',
            mark: NeumorphicMarkShape.solid,
          ),
        ],
      ),
    );
  });

  group('NeumorphicMonth', () {
    // Weeks start on the locale's first day (89edc4711f): the test's English starts them on Sunday. Each month here
    // opens mid-week, so its first row holds the last month's days.
    for (final (year, month, lastDay, firstRow) in [
      (2026, 10, 31, ['27', '28', '29', '30', '1', '2', '3']),
      (2025, 2, 28, ['26', '27', '28', '29', '30', '31', '1']),
      (2024, 2, 29, ['28', '29', '30', '31', '1', '2', '3']),
      (2027, 1, 31, ['27', '28', '29', '30', '31', '1', '2']),
    ]) {
      testWidgets('adjacent dates stay in their month for $year-$month', (
        tester,
      ) async {
        int? selected;
        await tester.pumpWidget(
          neumorphicApp(
            NeumorphicMonth(
              year: year,
              month: month,
              onDay: (day) => selected = day,
            ),
          ),
        );
        final labels = tester
            .widgetList<Text>(
              find.descendant(
                of: find.byType(NeumorphicMonth),
                matching: find.byType(Text),
              ),
            )
            .map((text) => text.data!)
            .skip(7)
            .toList();
        expect(labels.take(7), firstRow);
        final actions = find.descendant(
          of: find.byType(NeumorphicMonth),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Semantics &&
                widget.properties.button == true &&
                widget.properties.onTap != null,
          ),
        );
        expect(actions, findsNWidgets(lastDay));
        await tester.tap(actions.first);
        expect(selected, 1);
        await tester.tap(actions.last);
        expect(selected, lastDay);
        expect(tester.takeException(), isNull);
      });
    }
    check(
      'a month',
      () => const NeumorphicMonth(
        year: 2026,
        month: 11,
        today: 11,
        marked: {1, 2, 11, 30},
      ),
    );
    check(
      'dense',
      () => const NeumorphicMonth(year: 2026, month: 2, dense: true),
    );
    check(
      'tappable',
      () => NeumorphicMonth(year: 2024, month: 2, today: 29, onDay: (_) {}),
    );
  });

  group('the charts', () {
    check('two way, empty', () => const NeumorphicTwoWayBars(above: []));
    check(
      'two way, no slots',
      () => const NeumorphicTwoWayBars(above: [1], slots: 0),
    );
    check(
      'two way, whole',
      () => const NeumorphicTwoWayBars(
        above: [.6, .5, 1.9, 0, 0, 1.1],
        below: {1: .3, 2: .6, 40: 2},
        slots: 24,
        now: 5.5,
        peak: '1.9',
        labels: {0: '00', 6: '06', 12: '12'},
        nowLabel: '05:30',
        keys: [
          NeumorphicLegendItem(long),
          NeumorphicLegendItem(longLine, kind: NeumorphicLegendSwatch.live),
        ],
      ),
    );
    check('columns, empty', () => const NeumorphicColumnBars(values: []));
    check(
      'columns, zeros',
      () => const NeumorphicColumnBars(
        values: [0, 0, 0],
        labels: ['A', 'B', 'C'],
      ),
    );
    check(
      'columns, one, long words',
      () => const NeumorphicColumnBars(
        values: [4],
        labels: [long],
        now: 0,
        forecast: 9,
      ),
    );
    check(
      'columns, many',
      () => NeumorphicColumnBars(
        values: [for (var i = 0; i < 60; i++) i * 2.0],
        labels: const ['A', 'B'],
        now: 4,
        forecast: 200,
      ),
    );
    check(
      'step line, empty',
      () => const NeumorphicStepLine(readings: [], xMax: 1, yMin: 0, yMax: 1),
    );
    check(
      'step line, one',
      () => const NeumorphicStepLine(
        readings: [(0, 1)],
        steps: [(0, 1)],
        xMax: 0,
        yMin: 2,
        yMax: 2,
      ),
    );
    check(
      'step line, whole',
      () => const NeumorphicStepLine(
        readings: [(0, 18.6), (12, 17.6), (20, 21)],
        steps: [(0, 17), (6.5, 20.5), (24, 17)],
        now: 20,
        xMax: 24,
        yMin: 16,
        yMax: 22,
        yTicks: [17, 19, 21],
        yLabel: '°',
        xLabels: [(0, '00'), (12, '12'), (24, '24')],
        keys: [
          NeumorphicLegendItem('A'),
          NeumorphicLegendItem('B', kind: NeumorphicLegendSwatch.line),
        ],
        note: longLine,
      ),
    );
    check('shares, empty', () => const NeumorphicShareBars(rows: []));
    check(
      'shares, long',
      () => const NeumorphicShareBars(
        title: long,
        rows: [
          NeumorphicShare(long, '1,204,000,000', 2),
          NeumorphicShare('B', '0', 0),
          NeumorphicShare('C', '1', -1),
        ],
      ),
    );
  });

  group('the small stars', () {
    check('figure, plain', () => const NeumorphicFigure('0'));
    check(
      'figure, long',
      () => const NeumorphicFigure(
        '1,204,000,000',
        unit: long,
        delta: longLine,
        icon: NeumorphicGlyphs.trendingUp,
      ),
    );
    check(
      'nudge',
      () => NeumorphicNudge(
        title: longLine,
        note: longLine,
        icon: NeumorphicGlyphs.bell,
        action: NeumorphicButton.filled(
          long,
          icon: NeumorphicGlyphs.power,
          onPressed: () {},
        ),
      ),
    );
    check('nudge, bare', () => const NeumorphicNudge(title: 'A'));
    check(
      'level rows',
      () => NeumorphicList(
        children: [
          NeumorphicLevelRow(
            icon: NeumorphicGlyphs.fan,
            title: long,
            state: longLine,
            value: true,
            level: .4,
            figure: '1,204,000',
            onChanged: (_) {},
            onLevel: (_) {},
            isFirst: true,
          ),
          const NeumorphicLevelRow(
            icon: NeumorphicGlyphs.fan,
            title: 'B',
            state: 'Off',
            value: false,
          ),
        ],
      ),
    );
    check(
      'note',
      () => const NeumorphicNote(
        icon: NeumorphicGlyphs.zap,
        overline: long,
        title: longLine,
        subtitle: longLine,
        well: true,
      ),
    );
    check(
      'hero band',
      () => const NeumorphicHeroBand(
        object: NeumorphicMonogram('A'),
        title: longLine,
        overline: long,
        body: longLine,
      ),
    );
  });

  // A dial is an object: whatever column it stands in, it stays round, and it never spills.
  for (final width in const [320.0, 390.0, 1440.0]) {
    for (final (name, part) in [
      ('dial', const NeumorphicDial(value: 40, figure: '40')),
      (
        'span dial',
        const NeumorphicSpanDial(
          start: 'a',
          end: 'b',
          elapsed: 1,
          total: 2,
          figure: '1',
        ),
      ),
    ]) {
      testWidgets('a $name stays round at $width', (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          neumorphicApp(
            Center(
              child: SizedBox(width: width - 40, child: part),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        final painted = tester.renderObjectList<RenderBox>(
          find.descendant(
            of: find.byWidget(part),
            matching: find.byType(CustomPaint),
          ),
        );
        for (final box in painted) {
          if (box.size.width < 100) continue;
          expect(box.size.width, box.size.height);
          expect(box.size.width, lessThanOrEqualTo(width - 40));
        }
      });
    }
  }
}

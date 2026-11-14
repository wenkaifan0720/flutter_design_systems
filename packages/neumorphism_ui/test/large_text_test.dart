import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import 'support.dart';

void main() {
  setUpAll(loadNeumorphicFonts);
  testWidgets('everyday figures and initials keep the requested text scale', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      neumorphicApp(
        SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const NeumorphicMonogram('NW'),
                NeumorphicNumberField(
                  value: '2',
                  unit: 'people',
                  onDecrease: () {},
                  onIncrease: () {},
                ),
                const NeumorphicStats([
                  NeumorphicStat('Energy', '12.4', 'kWh'),
                ]),
                const NeumorphicStepRow(time: '09:00', title: 'Lights on'),
                NeumorphicLevelRow(
                  icon: NeumorphicGlyphs.lamp,
                  title: 'Lamp',
                  state: 'On',
                  value: true,
                  figure: '30%',
                  level: .3,
                  onChanged: (_) {},
                  onLevel: (_) {},
                ),
              ],
            ),
          ),
        ),
        textScale: 2,
      ),
    );
    await tester.pumpAndSettle();
    for (final label in ['NW', '2', 'people', '09:00', '30%']) {
      final paragraph = tester.renderObject<RenderParagraph>(find.text(label));
      final painted = MatrixUtils.transformRect(
        paragraph.getTransformTo(null),
        Offset.zero & paragraph.size,
      );
      expect(
        painted.height,
        closeTo(paragraph.size.height, .01),
        reason: '$label must not be scaled back down',
      );
      expect(paragraph.didExceedMaxLines, isFalse, reason: label);
    }
    expect(tester.takeException(), isNull);
  });
  for (final direction in TextDirection.values) {
    testWidgets('schedule row uses its narrow width at 2x $direction', (
      tester,
    ) async {
      await tester.pumpWidget(
        neumorphicApp(
          const Center(
            child: SizedBox(
              width: 180,
              child: NeumorphicStepRow(
                time: '19:45',
                title: 'Busy, now',
                value: '72',
                state: NeumorphicStepStatus.live,
              ),
            ),
          ),
          textScale: 2,
          direction: direction,
        ),
      );
      await tester.pumpAndSettle();
      final title = tester.renderObject<RenderParagraph>(
        find.text('Busy, now'),
      );
      expect(title.size.width, greaterThan(100));
      expect(title.size.height, lessThanOrEqualTo(80));
      expect(
        tester.getTopLeft(find.text('Busy, now')).dy,
        greaterThan(tester.getTopLeft(find.text('19:45')).dy),
      );
      expect(tester.takeException(), isNull);
    });
  }
  check(
    'long stepper units',
    () => NeumorphicNumberField(
      value: '12345',
      unit: longLine,
      onDecrease: () {},
      onIncrease: () {},
    ),
  );
  check(
    'long stat figure',
    () => const NeumorphicStats([
      NeumorphicStat(longLine, '123456789.00', 'kWh'),
    ]),
  );
  testWidgets('dial readouts keep scaled text outside a full dome', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      neumorphicApp(
        SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                NeumorphicDial(
                  value: 21.5,
                  min: 10,
                  max: 30,
                  figure: '21.5°',
                  label: 'Rising to',
                  sub: 'Current temperature',
                  onDecrease: () {},
                  onIncrease: () {},
                ),
                const NeumorphicSpanDial(
                  start: '12:00',
                  end: '13:00',
                  elapsed: 45,
                  total: 60,
                  figure: '15',
                  unit: 'minutes remaining',
                ),
                const NeumorphicMiniDial(value: 75, figure: '75%'),
                const NeumorphicColumnBars(
                  values: [2, 4],
                  labels: ['Monday', 'Tuesday'],
                ),
              ],
            ),
          ),
        ),
        textScale: 2,
      ),
    );
    await tester.pumpAndSettle();
    for (final (owner, label) in <(Type, String)>[
      (NeumorphicDial, '21.5°'),
      (NeumorphicSpanDial, '15'),
      (NeumorphicSpanDial, 'minutes remaining'),
      (NeumorphicMiniDial, '75%'),
      (NeumorphicColumnBars, 'Monday'),
      (NeumorphicColumnBars, 'Tuesday'),
    ]) {
      final paragraph = tester.renderObject<RenderParagraph>(
        find.descendant(of: find.byType(owner), matching: find.text(label)),
      );
      final painted = MatrixUtils.transformRect(
        paragraph.getTransformTo(null),
        Offset.zero & paragraph.size,
      );
      expect(
        painted.height,
        closeTo(paragraph.size.height, .01),
        reason: label,
      );
      expect(paragraph.didExceedMaxLines, isFalse, reason: label);
    }
    final miniFace = find.descendant(
      of: find.byType(NeumorphicMiniDial),
      matching: find.byType(Stack),
    );
    expect(
      tester.getTopLeft(find.text('75%')).dy,
      greaterThanOrEqualTo(tester.getBottomLeft(miniFace).dy),
    );
    expect(tester.takeException(), isNull);
  });
  check(
    'long dial readout',
    () => const NeumorphicDial(
      value: 21,
      figure: '123456789.00°',
      label: longLine,
      sub: longLine,
    ),
  );
  check(
    'long push labels',
    () => NeumorphicPushGroup(
      items: [
        NeumorphicPush(
          icon: NeumorphicGlyphs.sun,
          label: longLine,
          note: longLine,
          selected: true,
          onPressed: () {},
        ),
        NeumorphicPush(
          icon: NeumorphicGlyphs.moon,
          label: longLine,
          onPressed: () {},
        ),
      ],
    ),
  );
  testWidgets('navigation and action labels wrap without eliding', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      neumorphicApp(
        SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                NeumorphicButton.filled(longLine, onPressed: () {}),
                NeumorphicChip(longLine, onPressed: () {}, onDeleted: () {}),
                NeumorphicLatchGroup(
                  options: const [NeumorphicLatch(longLine)],
                  value: longLine,
                  onChanged: (_) {},
                ),
                const NeumorphicTag(longLine),
                NeumorphicNavigationBar(
                  items: [
                    NeumorphicNavItem(
                      label: longLine,
                      icon: NeumorphicGlyphs.house,
                      onPressed: () {},
                    ),
                  ],
                ),
                SizedBox(
                  height: 300,
                  child: NeumorphicNavigationDrawer(
                    items: [
                      NeumorphicNavItem(
                        label: longLine,
                        icon: NeumorphicGlyphs.house,
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        textScale: 2,
      ),
    );
    await tester.pumpAndSettle();
    for (final rich in find.byType(RichText).evaluate()) {
      final paragraph = rich.findRenderObject()! as RenderParagraph;
      expect(
        paragraph.didExceedMaxLines,
        isFalse,
        reason: paragraph.text.toPlainText(),
      );
    }
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'large-type day trays preserve complete event details and order',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      var presses = 0;
      await tester.pumpWidget(
        neumorphicApp(
          SingleChildScrollView(
            child: NeumorphicDayTray(
              events: [
                NeumorphicTrayEvent(
                  start: '10:00',
                  end: '10:15',
                  title: 'Second',
                  subtitle: longLine,
                  detail: 'Bring every document',
                  onPressed: () => presses++,
                ),
                const NeumorphicTrayEvent(
                  start: '09:00',
                  end: '09:15',
                  title: 'First',
                ),
              ],
              free: const [NeumorphicTrayFree('09:15', '10:00', 'Available')],
            ),
          ),
          textScale: 2,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Bring every document'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('First')).dy,
        lessThan(tester.getTopLeft(find.text('Second')).dy),
      );
      for (final text in find.byType(RichText).evaluate()) {
        expect(
          (text.findRenderObject()! as RenderParagraph).didExceedMaxLines,
          isFalse,
        );
      }
      await tester.ensureVisible(find.text('Second'));
      await tester.tap(find.text('Second'));
      expect(presses, 1);
      expect(tester.takeException(), isNull);
    },
  );
}

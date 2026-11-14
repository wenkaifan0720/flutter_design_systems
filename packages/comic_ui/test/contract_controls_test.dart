import 'dart:ui' show Tristate;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';

Widget _host(Widget child) => MaterialApp(
  builder: (context, home) =>
      ComicTheme(data: ComicThemeData.offset(), child: home!),
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  testWidgets(
    'a compact captionless panel hugs content and honors tight slots',
    (tester) async {
      await tester.pumpWidget(
        _host(
          const Align(
            child: ComicPanel(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              child: SizedBox(width: 48, height: 96),
            ),
          ),
        ),
      );
      expect(tester.getSize(find.byType(ComicPanel)), const Size(54, 102));
      await tester.pumpWidget(
        _host(
          const SizedBox(
            width: 320,
            height: 180,
            child: ComicPanel(
              shrinkWrap: true,
              child: SizedBox.expand(key: ValueKey('compact panel body')),
            ),
          ),
        ),
      );
      final body = tester.getSize(
        find.byKey(const ValueKey('compact panel body')),
      );
      expect(body.width, greaterThan(0));
      expect(body.height, greaterThan(0));
      expect(body.isFinite, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'selectable panels announce their state with and without an action',
    (tester) async {
      final semantics = tester.ensureSemantics();
      for (final active in [false, true]) {
        for (final selected in [false, true]) {
          var opened = 0;
          await tester.pumpWidget(
            _host(
              ComicPanel(
                selected: selected,
                label: 'Saved place',
                onPressed: active ? () => opened++ : null,
                child: const Text('Mission'),
              ),
            ),
          );
          // The panel's own node: the press under it stands its target's sides outward, so its outermost box is
          // not the node's.
          final data = tester
              .getSemantics(
                find
                    .descendant(
                      of: find.byType(ComicPanel),
                      matching: find.byWidgetPredicate(
                        (w) => w is Semantics && w.properties.selected != null,
                      ),
                    )
                    .first,
              )
              .getSemanticsData();
          expect(
            data.flagsCollection.isSelected,
            selected ? Tristate.isTrue : Tristate.isFalse,
          );
          if (active) {
            await tester.tap(find.byType(ComicPanel));
            expect(opened, 1);
          }
          expect(tester.takeException(), isNull);
        }
      }
      semantics.dispose();
    },
  );

  testWidgets('a loose panel ceiling does not stretch a small surface', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const SizedBox(
          height: 600,
          child: Align(child: ComicPanel(child: SizedBox(height: 40))),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(ComicPanel)).height, lessThan(100));
  });

  testWidgets('bounded panels hand finite remaining height to their content', (
    tester,
  ) async {
    for (final caption in <String?>[null, 'A saved place']) {
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 320,
            height: 180,
            child: ComicPanel(
              caption: caption,
              child: const SizedBox.expand(key: ValueKey('panel content')),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      final content = tester.getRect(
        find.byKey(const ValueKey('panel content')),
      );
      final panel = tester.getRect(find.byType(ComicPanel));
      expect(content.height, greaterThan(0));
      expect(content.height.isFinite, isTrue);
      expect(panel.contains(content.topLeft), isTrue);
      expect(
        panel.contains(content.bottomRight - const Offset(.1, .1)),
        isTrue,
      );
      if (caption != null) {
        expect(
          tester.getBottomLeft(find.byType(ComicCaption)).dy,
          lessThanOrEqualTo(content.top),
        );
      }
    }
  });
  testWidgets('composite trailing content keeps its measured width in rows', (
    tester,
  ) async {
    for (final width in [240.0, 390.0]) {
      for (final direction in TextDirection.values) {
        await tester.pumpWidget(
          _host(
            Directionality(
              textDirection: direction,
              child: SizedBox(
                width: width,
                child: ComicListTile(
                  title: 'Dropped pin',
                  subtitle: 'A saved location',
                  onPressed: () {},
                  trailing: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(width: 120, height: 28),
                      SizedBox(width: 8),
                      SizedBox(
                        key: ValueKey('trailing mark'),
                        width: 48,
                        height: 28,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        final mark = tester.getRect(
          find.byKey(const ValueKey('trailing mark')),
        );
        final row = tester.getRect(find.byType(ComicListTile));
        expect(row.contains(mark.topLeft), isTrue);
        expect(row.contains(mark.bottomRight - const Offset(.1, .1)), isTrue);
      }
    }
  });
  testWidgets('ruled children collapse when their content becomes empty', (
    tester,
  ) async {
    const rowKey = ValueKey('ruled child');
    for (final strong in [false, true]) {
      for (final height in [20.0, 0.0, 30.0]) {
        await tester.pumpWidget(
          _host(
            ComicRuled(
              key: rowKey,
              strong: strong,
              child: SizedBox(height: height),
            ),
          ),
        );
        expect(
          tester.getSize(find.byKey(rowKey)).height,
          height == 0 ? 0 : height + (strong ? 3 : 2),
        );
        expect(tester.takeException(), isNull);
      }
    }
  });
  testWidgets('segments reserve their row slots without an enclosing width', (
    tester,
  ) async {
    for (final count in [2, 3, 4]) {
      await tester.pumpWidget(
        _host(
          Row(
            children: [
              ComicSegmentedButton<int>(
                label: 'View',
                value: 0,
                segments: List.generate(
                  count,
                  (i) => ComicButtonSegment(i, '$i'),
                ),
                onChanged: (_) {},
              ),
            ],
          ),
        ),
      );
      expect(
        tester.getSize(find.byType(ComicSegmentedButton<int>)).width,
        count * 104,
      );
      // The segments share the slots inside the trough's rim, one width each.
      final cells = find.descendant(
        of: find.byType(ComicSegmentedButton<int>),
        matching: find.byType(ComicPressable),
      );
      expect(cells, findsNWidgets(count));
      final rim =
          tester.getTopLeft(cells.first).dx -
          tester.getTopLeft(find.byType(ComicSegmentedButton<int>)).dx;
      expect(rim, greaterThan(0));
      for (final box in cells.evaluate()) {
        expect(
          (box.renderObject as RenderBox).size.width,
          closeTo((count * 104 - 2 * rim) / count, .01),
        );
      }
      expect(tester.takeException(), isNull);
    }
  });
  testWidgets(
    'error heading keeps caller case and its action a separate node',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          _host(
            ComicErrorState(
              title: 'Could not load your plan',
              action: ComicButton.filled('Try again', onPressed: () {}),
            ),
          ),
        );
        expect(
          find.bySemanticsLabel('Could not load your plan'),
          findsOneWidget,
        );
        expect(find.bySemanticsLabel('Try again'), findsOneWidget);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    },
  );
  testWidgets(
    'busy delay holds focus and suppresses input before progress appears',
    (tester) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      var hits = 0;
      await tester.pumpWidget(
        _host(
          ComicButton.filled('Save', focusNode: focus, onPressed: () => hits++),
        ),
      );
      focus.requestFocus();
      await tester.pump();
      await tester.pumpWidget(
        _host(
          ComicButton.filled(
            'Save',
            focusNode: focus,
            busy: true,
            showBusy: false,
            onPressed: () => hits++,
          ),
        ),
      );
      await tester.pump();
      expect(focus.hasFocus, isTrue);
      expect(find.byType(ComicCircularProgressIndicator), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(hits, 0);
      await tester.pumpWidget(
        _host(
          ComicButton.filled(
            'Save',
            focusNode: focus,
            busy: true,
            showBusy: true,
            onPressed: () => hits++,
          ),
        ),
      );
      expect(find.byType(ComicCircularProgressIndicator), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'password reveal preserves editing value and uses caller labels',
    (tester) async {
      final controller = TextEditingController(text: 'paper');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _host(
          ComicTextField(
            label: 'Password',
            password: true,
            controller: controller,
            revealLabels: ('Reveal letters', 'Conceal letters'),
          ),
        ),
      );
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).obscureText,
        isTrue,
      );
      await tester.tap(find.bySemanticsLabel('Reveal letters'));
      await tester.pump();
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).obscureText,
        isFalse,
      );
      expect(controller.text, 'paper');
      await tester.tap(find.bySemanticsLabel('Conceal letters'));
      await tester.pump();
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).obscureText,
        isTrue,
      );
    },
  );
  testWidgets('search clearing uses external focus and reports one edit', (
    tester,
  ) async {
    final focus = FocusNode(), controller = TextEditingController(text: 'ink');
    addTearDown(focus.dispose);
    addTearDown(controller.dispose);
    final edits = <String>[];
    await tester.pumpWidget(
      _host(
        ComicSearchField(
          hint: 'Search issues',
          name: 'Issue search',
          controller: controller,
          focusNode: focus,
          onChanged: edits.add,
        ),
      ),
    );
    await tester.tap(find.byType(ComicIconButton));
    await tester.pump();
    expect(edits, ['']);
    expect(focus.hasFocus, isTrue);
  });
  testWidgets('code completion and editor decorator reach the native editor', (
    tester,
  ) async {
    final values = <String>[];
    await tester.pumpWidget(
      _host(
        ComicInputOtp(
          label: 'Code',
          length: 4,
          onCompleted: values.add,
          decorate: (input) => Semantics(label: 'Verification', child: input),
        ),
      ),
    );
    await tester.enterText(find.byType(EditableText), '12ab34');
    await tester.pump();
    expect(values, ['1234']);
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      '1234',
    );
  });
  testWidgets('segment activation does not report the current value again', (
    tester,
  ) async {
    final values = <int>[];
    await tester.pumpWidget(
      _host(
        ComicSegmentedButton<int>(
          label: 'Format',
          value: 1,
          segments: const [
            ComicButtonSegment(1, 'Print', name: 'Printed copy'),
            ComicButtonSegment(2, 'Digital'),
          ],
          onChanged: values.add,
        ),
      ),
    );
    await tester.tap(find.text('Print'));
    await tester.pump();
    expect(values, isEmpty);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(values, isEmpty);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    expect(values, [2]);
  });
  testWidgets(
    'a selected radio takes focus without reporting the value again',
    (tester) async {
      final values = <int>[];
      await tester.pumpWidget(
        _host(
          ComicRadioGroup<int>(
            label: 'Format',
            value: 1,
            options: const [ComicRadio(1, 'Print'), ComicRadio(2, 'Digital')],
            onChanged: values.add,
          ),
        ),
      );
      await tester.tap(find.text('Print'));
      await tester.pump();
      expect(values, isEmpty);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      expect(values, [2]);
    },
  );
  testWidgets('the whole switch row is one activation target', (tester) async {
    final values = <bool>[];
    await tester.pumpWidget(
      _host(
        ComicSwitchRow(
          label: 'Print notifications',
          value: false,
          onChanged: values.add,
        ),
      ),
    );
    await tester.tap(find.text('Print notifications'));
    await tester.pump();
    expect(values, [true]);
  });
  testWidgets(
    'chart preserves signed values and null gaps in its accessible summary',
    (tester) async {
      for (final bars in [false, true]) {
        await tester.pumpWidget(
          _host(
            ComicChart(
              label: 'Balance',
              type: bars ? ComicChartType.bar : ComicChartType.line,
              height: 120,
              series: const [
                ComicChartSeries('Net', [-3, null, 8]),
              ],
              band: const ComicChartBand(-2, 4, label: 'Target'),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        expect(find.bySemanticsLabel('Balance'), findsOneWidget);
        expect(
          tester.getSemantics(find.byType(ComicChart)).getSemanticsData().value,
          'Net: -3, 8',
        );
      }
    },
  );
  testWidgets('custom action marks remain visible and decorative', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        ComicButton.filled(
          'Send',
          leading: const SizedBox(key: ValueKey('mark'), width: 20, height: 20),
          onPressed: () {},
        ),
      ),
    );
    expect(find.byKey(const ValueKey('mark')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('nested row actions keep independent targets at narrow widths', (
    tester,
  ) async {
    var opened = 0, removed = 0;
    await tester.pumpWidget(
      _host(
        SizedBox(
          width: 320,
          child: ComicListTile(
            title: 'Issue twelve',
            onPressed: () => opened++,
            action: ComicButton.text(
              'Remove issue',
              onPressed: () => removed++,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.bySemanticsLabel('Remove issue'));
    expect(removed, 1);
    expect(opened, 0);
    await tester.tap(find.bySemanticsLabel('Issue twelve'));
    expect(opened, 1);
    expect(removed, 1);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'empty column children do not reserve gaps and grow keeps its share',
    (tester) async {
      await tester.pumpWidget(
        _host(
          const ComicColumn(
            gap: 10,
            skipEmpty: true,
            children: [
              SizedBox.shrink(),
              SizedBox(key: ValueKey('first'), height: 20),
              SizedBox.shrink(),
              SizedBox(key: ValueKey('last'), height: 30),
              SizedBox.shrink(),
            ],
          ),
        ),
      );
      expect(tester.getSize(find.byType(ComicColumn)).height, 60);
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('last'))).dy -
            tester.getBottomLeft(find.byKey(const ValueKey('first'))).dy,
        10,
      );
      await tester.pumpWidget(
        _host(
          const SizedBox(
            height: 100,
            child: ComicColumn(
              gap: 10,
              skipEmpty: true,
              children: [
                SizedBox(height: 20),
                SizedBox.shrink(),
                ComicGrow(child: SizedBox(key: ValueKey('grow'))),
              ],
            ),
          ),
        ),
      );
      expect(tester.getSize(find.byKey(const ValueKey('grow'))).height, 70);
    },
  );
  testWidgets('sheet controller scrolls content while its action stays fixed', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _host(
        SizedBox(
          height: 360,
          child: ComicBottomSheet(
            title: 'Issues',
            controller: controller,
            showClose: false,
            actions: [ComicButton.filled('Done', onPressed: () {})],
            child: Column(
              children: List.generate(
                30,
                (i) => SizedBox(height: 40, child: Text('Issue $i')),
              ),
            ),
          ),
        ),
      ),
    );
    final before = tester.getTopLeft(
      find.byWidgetPredicate((w) => '${w.runtimeType}' == '_Filled'),
    );
    expect(controller.hasClients, isTrue);
    controller.jumpTo(200);
    await tester.pump();
    expect(controller.offset, 200);
    expect(
      tester.getTopLeft(
        find.byWidgetPredicate((w) => '${w.runtimeType}' == '_Filled'),
      ),
      before,
    );
    expect(tester.takeException(), isNull);
  });
  test('print format never reads the clock and keeps negative sums', () {
    expect(ComicFormat.badge(100), '99+');
    expect(ComicFormat.count(1234), '1,234');
    expect(ComicFormat.sum(-12.3), '−12.30');
    expect(ComicFormat.time(DateTime(2026, 11, 6, 19, 5)), '19:05');
    expect(
      ComicFormat.dayWord(DateTime(2026, 11, 7), now: DateTime(2026, 11, 6)),
      'Tomorrow',
    );
  });
}

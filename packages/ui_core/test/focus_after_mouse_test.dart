// Focus after a mouse: a mouse that connects and moves over a part before
// any key or press (an iPad's trackpad, a mouse on Android, a test's mouse)
// leaves the focus to show on the next Tab, on every focusable part.
//
// Before any input, Flutter's highlight mode on a touch platform is touch,
// and turns traditional when a mouse connects without telling its
// listeners, so a FocusableActionDetector built before it never offers its
// focus highlight. ui_core's parts take the focus itself and decide by the
// live mode (RawFocusVisible).
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_harness.dart';

const Key _part = ValueKey('part');

// One focusable part: [build] makes it, telling [seen] whether a builder was
// handed its focus; [dispose] lets go of what it made.
typedef _Case = ({
  String name,
  Widget Function(ValueChanged<bool> seen) build,
  VoidCallback? dispose,
});

bool _f(Set<WidgetState> states) => states.contains(WidgetState.focused);

_Case _case(
  String name,
  Widget Function(ValueChanged<bool> seen) build, [
  VoidCallback? dispose,
]) => (name: name, build: build, dispose: dispose);

final List<String> _names = [
  'RawButton',
  'RawTabGroupTab',
  'RawSegmentedButton',
  'RawValueHandle',
  'RawRangeSlider',
  'RawColorArea',
  'RawColorSlider',
  'RawPicker',
  'RawCalendarDatePicker',
  'RawCarousel',
  'RawScrollArea',
  'RawReorderableList handle',
  'RawChart',
  'RawRating',
  'RawTree row',
  'RawDataTable row',
  'RawMenuBar item',
  'RawSplitButton',
  'RawDateField segment',
];

_Case _make(String name) {
  switch (name) {
    case 'RawButton':
      return _case(
        name,
        (seen) => RawButton(
          onPressed: () {},
          semanticLabel: 'Save',
          builder: (context, states, _) {
            seen(_f(states));
            return const SizedBox(width: 80, height: 40);
          },
        ),
      );
    case 'RawTabGroupTab':
      return _case(
        name,
        (seen) => RawTabGroup<String>(
          groupValue: 'a',
          onChanged: (value) {},
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final v in ['a', 'b'])
                RawTabGroupTab(
                  value: v,
                  builder: (context, states, _) {
                    seen(_f(states));
                    return SizedBox(width: 60, height: 40, child: Text(v));
                  },
                ),
            ],
          ),
        ),
      );
    case 'RawSegmentedButton':
      return _case(
        name,
        (seen) => RawSegmentedButton<String>(
          options: const ['day', 'week'],
          selected: const {'day'},
          onSelectionChanged: (next) {},
          itemBuilder: (context, value, states) {
            seen(_f(states));
            return SizedBox(width: 60, height: 40, child: Text(value));
          },
        ),
      );
    case 'RawValueHandle':
      return _case(
        name,
        (seen) => RawValueHandle(
          value: 0.5,
          onChanged: (value) {},
          semanticLabel: 'Volume',
          builder: (context, states) {
            seen(_f(states));
            return const SizedBox(width: 20, height: 20);
          },
        ),
      );
    case 'RawRangeSlider':
      return _case(
        name,
        (seen) => SizedBox(
          width: 240,
          child: RawRangeSlider(
            values: const RawRangeValues(20, 80),
            max: 100,
            onChanged: (values) {},
            trackBuilder: (context, track) => const SizedBox(height: 4),
            thumbBuilder: (context, index, states) {
              seen(_f(states));
              return const SizedBox(width: 20, height: 20);
            },
          ),
        ),
      );
    case 'RawColorArea':
      final color = RawColorController(const Color(0xFF3366FF));
      return _case(
        name,
        (seen) => SizedBox(
          width: 120,
          height: 120,
          child: RawColorArea(
            controller: color,
            builder: (context, area) {
              seen(_f(area.states));
              return const SizedBox.expand();
            },
            thumbBuilder: (context, area) =>
                const SizedBox(width: 16, height: 16),
          ),
        ),
        color.dispose,
      );
    case 'RawColorSlider':
      final hue = RawColorController(const Color(0xFF3366FF));
      return _case(
        name,
        (seen) => SizedBox(
          width: 200,
          child: RawColorSlider(
            controller: hue,
            channel: RawColorChannel.hue,
            trackBuilder: (context, channel, color) =>
                const SizedBox(height: 8),
            thumbBuilder: (context, states) {
              seen(_f(states));
              return const SizedBox(width: 16, height: 16);
            },
          ),
        ),
        hue.dispose,
      );
    case 'RawPicker':
      return _case(
        name,
        (seen) => SizedBox(
          width: 120,
          height: 200,
          child: RawPicker(
            columns: (selection) => [
              RawPickerColumn(
                itemCount: 24,
                itemLabel: (index) => '$index',
                semanticLabel: 'Hour',
              ),
            ],
            selection: const [9],
            onChanged: (selection) {},
            itemExtent: 40,
            itemBuilder: (context, details) =>
                Center(child: Text(details.label)),
            columnBuilder: (context, details, wheel) {
              seen(_f(details.states));
              return wheel;
            },
          ),
        ),
      );
    case 'RawCalendarDatePicker':
      final calendar = RawCalendarController(
        firstDate: DateTime(2026),
        lastDate: DateTime(2027),
      );
      return _case(
        name,
        (seen) => SizedBox(
          width: 320,
          child: RawCalendarDatePicker(
            controller: calendar,
            dayBuilder: (context, day, states) {
              seen(_f(states));
              return Text(day.label);
            },
          ),
        ),
        calendar.dispose,
      );
    case 'RawCarousel':
      return _case(
        name,
        (seen) => SizedBox(
          width: 240,
          height: 120,
          child: RawCarousel(
            itemCount: 3,
            itemBuilder: (context, index) => Text('Slide $index'),
            layoutBuilder: (context, viewport, controls) {
              seen(controls.focused);
              return viewport;
            },
          ),
        ),
      );
    case 'RawScrollArea':
      final scroll = ScrollController();
      return _case(
        name,
        (seen) => SizedBox(
          width: 200,
          height: 100,
          child: RawScrollArea(
            controller: scroll,
            thumbBuilder: (context, thumb) =>
                const ColoredBox(color: Color(0x66000000)),
            frameBuilder: (context, focused, area) {
              seen(focused);
              return area;
            },
            child: SingleChildScrollView(
              controller: scroll,
              child: const SizedBox(height: 600),
            ),
          ),
        ),
        scroll.dispose,
      );
    case 'RawReorderableList handle':
      return _case(
        name,
        (seen) => SizedBox(
          width: 200,
          height: 120,
          child: RawReorderableList<String>(
            items: const ['a', 'b'],
            onReorder: (from, to) {},
            labelOf: (item) => item,
            itemBuilder: (context, item, reorder) => Row(
              children: [
                Text(item),
                reorder.buildHandle((context, states, _) {
                  seen(_f(states));
                  return const SizedBox(width: 24, height: 24);
                }),
              ],
            ),
          ),
        ),
      );
    case 'RawChart':
      return _case(
        name,
        (seen) => SizedBox(
          width: 200,
          height: 120,
          child: RawChart(
            semanticLabel: 'Revenue',
            series: const [
              RawChartSeries(
                label: 'Revenue',
                points: [RawChartPoint(0, 820), RawChartPoint(1, 1240)],
              ),
            ],
            builder: (context, chart) {
              seen(_f(chart.states));
              return CustomPaint(size: chart.size);
            },
          ),
        ),
      );
    case 'RawRating':
      return _case(
        name,
        (seen) => RawRating(
          value: 3,
          onChanged: (value) {},
          itemBuilder: (context, item) {
            seen(_f(item.states));
            return const SizedBox(width: 24, height: 24);
          },
        ),
      );
    case 'RawTree row':
      final tree = RawTreeController<String>(
        roots: const ['src', 'test'],
        childrenOf: (node) => const [],
      );
      return _case(
        name,
        (seen) => SizedBox(
          width: 200,
          height: 120,
          child: RawTree<String>(
            controller: tree,
            labelOf: (node) => node,
            rowBuilder: (context, item) {
              seen(_f(item.states));
              return SizedBox(height: 32, child: Text(item.row.node));
            },
          ),
        ),
        tree.dispose,
      );
    case 'RawDataTable row':
      final table = RawDataTableController<String>(
        rows: const ['a', 'b'],
        columns: [
          RawDataColumn<String>(
            id: 'name',
            label: 'Name',
            sortKey: (row) => row,
          ),
        ],
      );
      return _case(
        name,
        (seen) => SizedBox(
          width: 300,
          height: 160,
          child: RawDataTable<String>(
            controller: table,
            headerBuilder: (context, column, sort, states) =>
                Text(column.label),
            cellBuilder: (context, row, column) => Text(row),
            rowBuilder: (context, row, cells) {
              seen(_f(row.states));
              return SizedBox(height: 32, child: Row(children: cells));
            },
          ),
        ),
        table.dispose,
      );
    case 'RawMenuBar item':
      return _case(
        name,
        (seen) => RawMenuBar(
          menus: [
            RawMenuEntry(
              label: 'File',
              children: [RawMenuEntry(label: 'New', onPressed: () {})],
            ),
          ],
          itemBuilder: (context, entry, level, states) {
            seen(_f(states));
            return SizedBox(width: 60, height: 32, child: Text(entry.label));
          },
          surfaceBuilder: (context, info, items) =>
              Column(mainAxisSize: MainAxisSize.min, children: items),
        ),
      );
    case 'RawSplitButton':
      return _case(
        name,
        (seen) => RawSplitButton(
          label: 'Save',
          onPressed: () {},
          actions: [RawSplitAction(label: 'Save as', onPressed: () {})],
          buttonBuilder: (context, part, states, open) {
            seen(_f(states));
            return SizedBox(width: 60, height: 32, child: Text(part.name));
          },
          itemBuilder: (context, action, states) => Text(action.label),
          surfaceBuilder: (context, info, items) =>
              Column(mainAxisSize: MainAxisSize.min, children: items),
        ),
      );
    case 'RawDateField segment':
      return _case(
        name,
        (seen) => RawDateField(
          value: DateTime(2026, 11, 16),
          onChanged: (day) {},
          segmentBuilder: (context, details) {
            seen(_f(details.states));
            return Text(details.text);
          },
        ),
      );
  }
  throw ArgumentError.value(name);
}

void main() {
  for (final name in _names) {
    for (final mouseFirst in [false, true]) {
      testWidgets('$name shows its focus on Tab, '
          '${mouseFirst ? 'after a mouse moved over it' : 'with no mouse'}', (
        tester,
      ) async {
        final c = _make(name);
        addTearDown(() => c.dispose?.call());
        var shown = false;
        await tester.pumpWidget(
          harness(
            Center(
              child: KeyedSubtree(
                key: _part,
                child: c.build((on) {
                  if (on) shown = true;
                }),
              ),
            ),
          ),
        );
        if (mouseFirst) {
          final mouse = await tester.createGesture(
            kind: PointerDeviceKind.mouse,
          );
          await mouse.addPointer(location: const Offset(1, 1));
          addTearDown(mouse.removePointer);
          await mouse.moveTo(tester.getCenter(find.byKey(_part)));
          await tester.pumpAndSettle();
          await mouse.moveTo(const Offset(1, 1));
          await tester.pumpAndSettle();
        }
        expect(shown, isFalse, reason: 'no focus shown before a key');
        for (var tab = 0; tab < 3 && !shown; tab++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pumpAndSettle();
        }
        expect(shown, isTrue, reason: 'Tab shows the focus');
      });
    }
  }

  testWidgets('RawColorArea shows a mouse\'s hover before any input', (
    tester,
  ) async {
    final color = RawColorController(const Color(0xFF3366FF));
    addTearDown(color.dispose);
    var hovered = false;
    await tester.pumpWidget(
      harness(
        Center(
          child: SizedBox(
            width: 120,
            height: 120,
            child: RawColorArea(
              controller: color,
              builder: (context, area) {
                hovered = area.states.contains(WidgetState.hovered);
                return const SizedBox.expand();
              },
              thumbBuilder: (context, area) =>
                  const SizedBox(width: 16, height: 16),
            ),
          ),
        ),
      ),
    );
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(1, 1));
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(find.byType(RawColorArea)));
    await tester.pumpAndSettle();
    expect(hovered, isTrue);
    await mouse.moveTo(const Offset(1, 1));
    await tester.pumpAndSettle();
    expect(hovered, isFalse);
  });
}

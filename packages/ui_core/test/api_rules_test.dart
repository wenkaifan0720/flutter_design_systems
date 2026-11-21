// The API's Flutter rules, held where they are easy to break: a focus node
// the caller gives is the one the widget focuses, and the widget never
// disposes it; autofocus takes the focus; a null callback disables, with no
// separate switch; a calendar's onChanged gives the day.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_harness.dart';

// The single-stop widgets that take a focus node, each built with [node]
// and [autofocus].
final Map<String, Widget Function(FocusNode node, bool autofocus)> _stops = {
  'RawCarousel': (node, autofocus) => RawCarousel(
    itemCount: 3,
    itemBuilder: (context, index) => Text('Slide $index'),
    focusNode: node,
    autofocus: autofocus,
  ),
  'RawScrollArea': (node, autofocus) => _ScrollHost(
    builder: (controller) => RawScrollArea(
      controller: controller,
      thumbBuilder: (context, thumb) => const SizedBox.expand(),
      focusNode: node,
      autofocus: autofocus,
      child: SingleChildScrollView(
        controller: controller,
        child: const SizedBox(height: 2000),
      ),
    ),
  ),
  'RawColorArea': (node, autofocus) => _ColorHost(
    builder: (controller) => SizedBox(
      width: 200,
      height: 200,
      child: RawColorArea(
        controller: controller,
        builder: (context, area) => const SizedBox.expand(),
        thumbBuilder: (context, area) => const SizedBox(width: 16, height: 16),
        focusNode: node,
        autofocus: autofocus,
      ),
    ),
  ),
  'RawColorSlider': (node, autofocus) => _ColorHost(
    builder: (controller) => SizedBox(
      width: 200,
      child: RawColorSlider(
        controller: controller,
        channel: RawColorChannel.hue,
        trackBuilder: (context, channel, color) => const SizedBox(height: 8),
        thumbBuilder: (context, states) =>
            const SizedBox(width: 16, height: 16),
        focusNode: node,
        autofocus: autofocus,
      ),
    ),
  ),
  'RawSplitView': (node, autofocus) => SizedBox(
    width: 400,
    height: 200,
    child: RawSplitView(
      first: const SizedBox.expand(),
      second: const SizedBox.expand(),
      dividerBuilder: (context, states, axis) => const SizedBox.expand(),
      focusNode: node,
      autofocus: autofocus,
    ),
  ),
  'RawCommandPalette': (node, autofocus) => RawCommandPalette(
    commands: [RawCommand(label: 'New file', onPressed: () {})],
    fieldBuilder: (context, field) => EditableText(
      controller: field.controller,
      focusNode: field.focusNode,
      style: const TextStyle(),
      cursorColor: const Color(0xFF000000),
      backgroundCursorColor: const Color(0xFF808080),
    ),
    itemBuilder: (context, command, states) => Text(command.label),
    focusNode: node,
    autofocus: autofocus,
  ),
  // 0.3.0 values
  'RawNumberField': (node, autofocus) => RawNumberField(
    value: 2,
    onChanged: (value) {},
    fieldBuilder: (context, field) => SizedBox(
      width: 120,
      child: EditableText(
        controller: field.controller,
        focusNode: field.focusNode,
        style: const TextStyle(),
        cursorColor: const Color(0xFF000000),
        backgroundCursorColor: const Color(0xFF808080),
      ),
    ),
    buttonBuilder: (context, button) => const SizedBox(width: 44, height: 44),
    focusNode: node,
    autofocus: autofocus,
  ),
  'RawRating': (node, autofocus) => RawRating(
    value: 3,
    onChanged: (value) {},
    itemBuilder: (context, item) => const SizedBox(width: 24, height: 24),
    focusNode: node,
    autofocus: autofocus,
  ),
  'DesignChart': (node, autofocus) => SizedBox(
    width: 200,
    height: 100,
    child: DesignChart(
      semanticLabel: 'Chart',
      series: const [
        DesignChartSeries(label: 'A', points: [DesignChartPoint(0, 1)]),
      ],
      builder: (context, chart) => const SizedBox.expand(),
      focusNode: node,
      autofocus: autofocus,
    ),
  ),
  'DesignPieChart': (node, autofocus) => SizedBox(
    width: 100,
    height: 100,
    child: DesignPieChart(
      semanticLabel: 'Pie',
      slices: const [DesignPieSlice(label: 'A', value: 1)],
      builder: (context, pie) => const SizedBox.expand(),
      focusNode: node,
      autofocus: autofocus,
    ),
  ),
  // 0.3.0 values end
};

class _ScrollHost extends StatefulWidget {
  const _ScrollHost({required this.builder});

  final Widget Function(ScrollController controller) builder;

  @override
  State<_ScrollHost> createState() => _ScrollHostState();
}

class _ScrollHostState extends State<_ScrollHost> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      SizedBox(height: 300, child: widget.builder(_controller));
}

class _ColorHost extends StatefulWidget {
  const _ColorHost({required this.builder});

  final Widget Function(RawColorController controller) builder;

  @override
  State<_ColorHost> createState() => _ColorHostState();
}

class _ColorHostState extends State<_ColorHost> {
  final _controller = RawColorController(const Color(0xFF3366FF));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(_controller);
}

void main() {
  for (final MapEntry(key: name, value: build) in _stops.entries) {
    testWidgets('$name focuses the node it is given, autofocus takes the '
        'focus, and the node outlives it', (tester) async {
      final node = FocusNode(debugLabel: name);
      addTearDown(node.dispose);
      await tester.pumpWidget(harness(Center(child: build(node, true))));
      await tester.pumpAndSettle();
      expect(node.hasFocus, isTrue, reason: 'autofocus: true');

      await tester.pumpWidget(harness(Center(child: build(node, false))));
      node.unfocus();
      await tester.pumpAndSettle();
      expect(node.hasFocus, isFalse);
      node.requestFocus();
      await tester.pumpAndSettle();
      expect(node.hasFocus, isTrue, reason: 'the node given is the one used');

      await tester.pumpWidget(harness(const SizedBox()));
      expect(
        () => node.addListener(() {}),
        returnsNormally,
        reason: 'the caller disposes the node it gave',
      );
    });
  }

  test('a menu entry with no onPressed is disabled; a submenu with items '
      'is not; a divider never is', () {
    expect(RawMenuEntry(label: 'Paste', onPressed: () {}).enabled, isTrue);
    expect(const RawMenuEntry(label: 'Paste').enabled, isFalse);
    expect(
      const RawMenuEntry(
        label: 'Open recent',
        children: [RawMenuEntry(label: 'a.txt')],
      ).enabled,
      isTrue,
    );
    expect(
      const RawMenuEntry(label: 'Open recent', children: []).enabled,
      isFalse,
    );
    expect(const RawMenuEntry.divider().enabled, isFalse);
  });

  testWidgets("a split button's action with no onPressed is listed but "
      'cannot be pressed', (tester) async {
    var saved = 0;
    await tester.pumpWidget(
      harness(
        Center(
          child: RawSplitButton(
            label: 'Save',
            onPressed: () {},
            actions: [
              RawSplitAction(label: 'Save a copy', onPressed: () => saved++),
              const RawSplitAction(label: 'Save as', onPressed: null),
            ],
            buttonBuilder: (context, part, states, open) =>
                Text(part == RawSplitPart.main ? 'Save' : 'More'),
            itemBuilder: (context, action, states) => Text(
              '${action.label}${states.contains(WidgetState.disabled) ? ' (off)' : ''}',
            ),
            surfaceBuilder: (context, info, items) =>
                Column(mainAxisSize: MainAxisSize.min, children: items),
          ),
        ),
      ),
    );
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    expect(find.text('Save as (off)'), findsOneWidget);
    await tester.tap(find.text('Save as (off)'));
    await tester.pumpAndSettle();
    expect(find.text('Save as (off)'), findsOneWidget, reason: 'still open');
    await tester.tap(find.text('Save a copy'));
    await tester.pumpAndSettle();
    expect(saved, 1);
  });

  testWidgets("a calendar's onChanged gives the day chosen; the controller "
      'holds the selection', (tester) async {
    final controller = RawCalendarController(
      firstDate: DateTime(2026),
      lastDate: DateTime(2026, 12, 31),
      initialMonth: DateTime(2026, 3),
      mode: RawCalendarMode.range,
    );
    addTearDown(controller.dispose);
    final days = <DateTime>[];
    await tester.pumpWidget(
      harness(
        Center(
          child: RawCalendarDatePicker(
            controller: controller,
            firstWeekday: DateTime.monday,
            onChanged: days.add,
            dayBuilder: (context, day, states) => Text('${day.date.day}'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('10'));
    await tester.pump();
    await tester.tap(find.text('14'));
    await tester.pump();
    expect(days, [DateTime(2026, 3, 10), DateTime(2026, 3, 14)]);
    expect(controller.selectedRange?.start, DateTime(2026, 3, 10));
    expect(controller.selectedRange?.end, DateTime(2026, 3, 14));
  });
}

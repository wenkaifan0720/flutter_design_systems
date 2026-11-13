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
  'DesignCarousel': (node, autofocus) => DesignCarousel(
    itemCount: 3,
    itemBuilder: (context, index) => Text('Slide $index'),
    focusNode: node,
    autofocus: autofocus,
  ),
  'DesignScrollArea': (node, autofocus) => _ScrollHost(
    builder: (controller) => DesignScrollArea(
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
  'DesignColorArea': (node, autofocus) => _ColorHost(
    builder: (controller) => SizedBox(
      width: 200,
      height: 200,
      child: DesignColorArea(
        controller: controller,
        builder: (context, area) => const SizedBox.expand(),
        thumbBuilder: (context, area) => const SizedBox(width: 16, height: 16),
        focusNode: node,
        autofocus: autofocus,
      ),
    ),
  ),
  'DesignColorSlider': (node, autofocus) => _ColorHost(
    builder: (controller) => SizedBox(
      width: 200,
      child: DesignColorSlider(
        controller: controller,
        channel: DesignColorChannel.hue,
        trackBuilder: (context, channel, color) => const SizedBox(height: 8),
        thumbBuilder: (context, states) =>
            const SizedBox(width: 16, height: 16),
        focusNode: node,
        autofocus: autofocus,
      ),
    ),
  ),
  'DesignSplitView': (node, autofocus) => SizedBox(
    width: 400,
    height: 200,
    child: DesignSplitView(
      first: const SizedBox.expand(),
      second: const SizedBox.expand(),
      dividerBuilder: (context, states, axis) => const SizedBox.expand(),
      focusNode: node,
      autofocus: autofocus,
    ),
  ),
  'DesignCommandPalette': (node, autofocus) => DesignCommandPalette(
    commands: [DesignCommand(label: 'New file', onPressed: () {})],
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

  final Widget Function(DesignColorController controller) builder;

  @override
  State<_ColorHost> createState() => _ColorHostState();
}

class _ColorHostState extends State<_ColorHost> {
  final _controller = DesignColorController(const Color(0xFF3366FF));

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
    expect(DesignMenuEntry(label: 'Paste', onPressed: () {}).enabled, isTrue);
    expect(const DesignMenuEntry(label: 'Paste').enabled, isFalse);
    expect(
      const DesignMenuEntry(
        label: 'Open recent',
        children: [DesignMenuEntry(label: 'a.txt')],
      ).enabled,
      isTrue,
    );
    expect(
      const DesignMenuEntry(label: 'Open recent', children: []).enabled,
      isFalse,
    );
    expect(const DesignMenuEntry.divider().enabled, isFalse);
  });

  testWidgets("a split button's action with no onPressed is listed but "
      'cannot be pressed', (tester) async {
    var saved = 0;
    await tester.pumpWidget(
      harness(
        Center(
          child: DesignSplitButton(
            label: 'Save',
            onPressed: () {},
            actions: [
              DesignSplitAction(label: 'Save a copy', onPressed: () => saved++),
              const DesignSplitAction(label: 'Save as', onPressed: null),
            ],
            buttonBuilder: (context, part, states, open) =>
                Text(part == DesignSplitPart.main ? 'Save' : 'More'),
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
    final controller = DesignCalendarController(
      firstDate: DateTime(2026),
      lastDate: DateTime(2026, 12, 31),
      initialMonth: DateTime(2026, 3),
      mode: DesignCalendarMode.range,
    );
    addTearDown(controller.dispose);
    final days = <DateTime>[];
    await tester.pumpWidget(
      harness(
        Center(
          child: DesignCalendar(
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

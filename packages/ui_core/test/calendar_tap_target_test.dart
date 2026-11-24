import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_harness.dart';

// A day is a tap target at the floor: a face smaller than RawTapTargets'
// floor stands in a target as tall as the floor, as wide as its column.

final Map<DateTime, RawCalendarDayDetails> _seen = {};

// A face far under any floor: the day number in a 16 tall box.
Widget _day(
  BuildContext context,
  RawCalendarDayDetails day,
  Set<WidgetState> states,
) {
  _seen[day.date] = day;
  return SizedBox(
    key: ValueKey(
      '${day.inMonth ? 'in' : 'out'}-${day.date.month}-${day.date.day}',
    ),
    height: 16,
    child: Center(child: Text('${day.date.day}')),
  );
}

Widget _calendar(
  RawCalendarController c, {
  required RawInput input,
  double width = 340,
  Size? touch,
}) => harness(
  RawTapTargetScope(
    targets: touch == null
        ? RawTapTargets(input: input)
        : RawTapTargets(input: input, touch: touch),
    child: Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: width,
        child: RawCalendarDatePicker(controller: c, dayBuilder: _day),
      ),
    ),
  ),
);

RawCalendarController _controller() => RawCalendarController(
  firstDate: DateTime(2025),
  lastDate: DateTime(2027, 12, 31),
  initialMonth: DateTime(2026, 1, 28),
  currentDate: DateTime(2026, 1, 15),
);

Finder _face(int day) => find.byKey(ValueKey('in-1-$day'));

void main() {
  setUp(_seen.clear);

  testWidgets('under a finger a day is 44 tall, and a tap in its padding '
      'picks the day', (tester) async {
    final semantics = tester.ensureSemantics();
    final c = _controller();
    addTearDown(c.dispose);
    await tester.pumpWidget(_calendar(c, input: RawInput.touch));

    // Thursday the 15th, and the Thursday under it: a week is 44 apart.
    final fifteenth = tester.getCenter(_face(15));
    expect(tester.getCenter(_face(22)).dy - fifteenth.dy, 44);
    expect(tester.getSize(_face(15)).height, 16);

    // 18 below the face's centre is past the face but in its target.
    await tester.tapAt(fifteenth + const Offset(0, 18));
    await tester.pump();
    expect(_seen[DateTime(2026, 1, 15)]!.selected, isTrue);
    expect(_seen[DateTime(2026, 1, 22)]!.selected, isFalse);

    // The day's one node spans the target, not the face.
    final node = tester.getSemantics(_face(15)).getSemanticsData();
    expect(node.label, 'Thursday, 15 January 2026');
    expect(node.rect.height, 44);
    semantics.dispose();
  });

  testWidgets('under a pointer the floor is 24', (tester) async {
    final c = _controller();
    addTearDown(c.dispose);
    await tester.pumpWidget(_calendar(c, input: RawInput.pointer));
    expect(tester.getCenter(_face(22)).dy - tester.getCenter(_face(15)).dy, 24);
  });

  testWidgets("a look's own floor sets the day's height", (tester) async {
    final c = _controller();
    addTearDown(c.dispose);
    await tester.pumpWidget(
      _calendar(c, input: RawInput.touch, touch: const Size.square(48)),
    );
    final fifteenth = tester.getCenter(_face(15));
    expect(tester.getCenter(_face(22)).dy - fifteenth.dy, 48);
  });

  testWidgets('a row narrower than seven floors keeps each day its column', (
    tester,
  ) async {
    final c = _controller();
    addTearDown(c.dispose);
    await tester.pumpWidget(_calendar(c, input: RawInput.touch, width: 280));
    expect(tester.takeException(), isNull);
    final fifteenth = tester.getCenter(_face(15));
    expect(tester.getCenter(_face(16)).dx - fifteenth.dx, 40);
    expect(tester.getCenter(_face(22)).dy - fifteenth.dy, 44);
  });

  testWidgets('the neighbours\' days stay out of the semantics tree', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final c = _controller();
    addTearDown(c.dispose);
    await tester.pumpWidget(_calendar(c, input: RawInput.touch));
    // December's last four days share January's first week.
    expect(find.byKey(const ValueKey('out-12-28')), findsOneWidget);
    final blank = <SemanticsNode>[];
    void visit(SemanticsNode node) {
      final children = <SemanticsNode>[];
      node.visitChildren((child) {
        children.add(child);
        return true;
      });
      // A node that merges its descendants speaks for them.
      final merges = node.mergeAllDescendantsIntoThisNode;
      if ((children.isEmpty || merges) &&
          node.getSemanticsData().label.isEmpty) {
        blank.add(node);
      }
      if (!merges) children.forEach(visit);
    }

    visit(tester.getSemantics(find.byType(RawCalendarDatePicker)));
    expect(blank, isEmpty, reason: 'a neighbour\'s day is no empty node');
    expect(find.bySemanticsLabel('Sunday, 28 December 2025'), findsNothing);
    semantics.dispose();
  });
}

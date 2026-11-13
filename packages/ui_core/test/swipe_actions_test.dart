import 'dart:ui' show Tristate;

import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_contract.dart';
import 'behaviour_harness.dart';

final List<String> _ran = [];
final Map<String, DesignSwipeActionDetails> _seen = {};
final FocusNode _rowNode = FocusNode();

// The bare reference painter: a 300 by 60 row; actions as labelled boxes.
Widget _row({
  TextDirection direction = TextDirection.ltr,
  bool reduceMotion = false,
  bool initiallyOpen = false,
  double underlap = 0,
}) => harness(
  _view(initiallyOpen: initiallyOpen, underlap: underlap),
  textDirection: direction,
  reduceMotion: reduceMotion,
);

Widget _view({bool initiallyOpen = false, double underlap = 0}) => Align(
  alignment: Alignment.topLeft,
  child: SizedBox(
    width: 300,
    child: DesignSwipeActions(
      initiallyOpen: initiallyOpen,
      underlap: underlap,
      startActions: [
        DesignSwipeAction(label: 'Pin', onPressed: () => _ran.add('pin')),
      ],
      endActions: [
        DesignSwipeAction(
          label: 'Delete',
          destructive: true,
          onPressed: () => _ran.add('delete'),
        ),
        DesignSwipeAction(
          label: 'Archive',
          onPressed: () => _ran.add('archive'),
        ),
      ],
      actionBuilder: (context, action, state) {
        _seen[action.label] = state;
        return Center(child: Text(action.label));
      },
      child: DesignPressable(
        focusNode: _rowNode,
        onPressed: () => _ran.add('open'),
        builder: (context, states, _) =>
            const SizedBox(height: 60, child: Text('Message')),
      ),
    ),
  ),
);

double _rowLeft(WidgetTester tester) =>
    tester.getTopLeft(find.text('Message')).dx;

void main() {
  setUp(() {
    _ran.clear();
    _seen.clear();
  });

  bool focused(WidgetTester t, String label) =>
      t
          .getSemantics(find.text(label))
          .getSemanticsData()
          .flagsCollection
          .isFocused ==
      Tristate.isTrue;

  behaviourContract(
    'DesignSwipeActions',
    build: (c) => _view(),
    node: () => find.text('Message'),
    semantics: isSemantics(
      label: 'Message',
      isFocusable: true,
      hasTapAction: true,
      customActions: const [
        CustomSemanticsAction(label: 'Pin'),
        CustomSemanticsAction(label: 'Delete'),
        CustomSemanticsAction(label: 'Archive'),
      ],
    ),
    noDisabledState:
        'the row is the look\'s and disables itself; an action has no '
        'disabled state (leave it out)',
    keyboard: (p) async {
      await p.tabInto();
      await p.key(LogicalKeyboardKey.arrowLeft);
      expect(
        focused(p.tester, 'Delete'),
        isTrue,
        reason: 'Left shows the end actions, the first focused',
      );
      await p.key(LogicalKeyboardKey.escape);
      expect(find.text('Delete'), findsNothing);
      expect(p.focused, isTrue, reason: 'Escape: back in the row');
    },
    rtl: (p) async {
      await p.tabInto();
      await p.key(LogicalKeyboardKey.arrowLeft);
      expect(
        focused(p.tester, 'Pin'),
        isTrue,
        reason: 'right to left, Left shows the start actions',
      );
    },
    motion: (p) async {
      await p.tabInto();
      await p.key(LogicalKeyboardKey.arrowLeft);
    },
  );

  testWidgets('a swipe past half the actions opens them; a short one closes; '
      'an action runs and closes the row', (tester) async {
    await tester.pumpWidget(_row());
    await tester.timedDrag(
      find.text('Message'),
      const Offset(-60, 0),
      const Duration(milliseconds: 500),
    );
    await tester.pumpAndSettle();
    expect(_rowLeft(tester), 0, reason: '60 of 160 px: closed again');

    await tester.timedDrag(
      find.text('Message'),
      const Offset(-120, 0),
      const Duration(milliseconds: 500),
    );
    await tester.pumpAndSettle();
    expect(_rowLeft(tester), -160);
    expect(find.text('Delete'), findsOneWidget);
    expect(
      tester.getCenter(find.text('Delete')).dx,
      greaterThan(tester.getCenter(find.text('Archive')).dx),
      reason: 'the first action sits at the edge',
    );
    // The row's visible strip, left of the actions.
    await tester.tapAt(const Offset(60, 30));
    await tester.pumpAndSettle();
    expect(_ran, isEmpty, reason: 'a tap on the open row closes it');
    expect(_rowLeft(tester), 0);

    await tester.timedDrag(
      find.text('Message'),
      const Offset(100, 0),
      const Duration(milliseconds: 500),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pin'));
    await tester.pumpAndSettle();
    expect(_ran, ['pin']);
    expect(_rowLeft(tester), 0);
  });

  testWidgets('initiallyOpen starts with the end actions shown; a tap on '
      'the row closes it', (tester) async {
    await tester.pumpWidget(_row(initiallyOpen: true));
    expect(_rowLeft(tester), -160);
    expect(find.text('Delete'), findsOneWidget);
    await tester.tapAt(const Offset(60, 30));
    await tester.pumpAndSettle();
    expect(_ran, isEmpty);
    expect(_rowLeft(tester), 0);
  });

  testWidgets('a full swipe arms the edge action and runs it; a destructive '
      'one slides the row away first', (tester) async {
    await tester.pumpWidget(_row());
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Message')),
    );
    await gesture.moveBy(const Offset(-20, 0));
    await gesture.moveBy(const Offset(-200, 0));
    await tester.pump();
    expect(_seen['Delete']!.armed, isTrue);
    expect(_seen['Archive']!.armed, isFalse);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(_ran, ['delete']);
    expect(_rowLeft(tester), -300);
  });

  testWidgets('arming widens the edge action over frames, and disarming '
      'narrows it back; each action knows its place', (tester) async {
    await tester.pumpWidget(_row());
    double slot(String label) => tester
        .getSize(
          find
              .ancestor(
                of: find.text(label),
                matching: find.byType(DesignPressable),
              )
              .first,
        )
        .width;
    // The edge action's share of the strip.
    double share() => slot('Delete') / (slot('Delete') + slot('Archive'));
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Message')),
    );
    await gesture.moveBy(const Offset(-20, 0));
    await gesture.moveBy(const Offset(-130, 0));
    await tester.pump();
    expect(_seen['Delete']!.armed, isFalse);
    expect(share(), moreOrLessEquals(0.5));
    expect(
      [
        for (final l in ['Delete', 'Archive'])
          (_seen[l]!.index, _seen[l]!.count),
      ],
      [(0, 2), (1, 2)],
    );

    await gesture.moveBy(const Offset(-70, 0));
    await tester.pump();
    expect(_seen['Delete']!.armed, isTrue);
    await tester.pump(const Duration(milliseconds: 32));
    expect(share(), inExclusiveRange(0.5, 0.8), reason: 'widening');
    await tester.pump(const Duration(milliseconds: 300));
    expect(share(), moreOrLessEquals(0.8), reason: 'four shares of five');

    await gesture.moveBy(const Offset(70, 0));
    await tester.pump();
    expect(_seen['Delete']!.armed, isFalse);
    await tester.pump(const Duration(milliseconds: 32));
    expect(share(), inExclusiveRange(0.5, 0.8), reason: 'narrowing');
    await tester.pump(const Duration(milliseconds: 300));
    expect(share(), moreOrLessEquals(0.5));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(_ran, isEmpty);
  });

  testWidgets('an underlap runs the strip on under the row: the innermost '
      'slot is that much wider, and the row still takes the tap', (
    tester,
  ) async {
    await tester.pumpWidget(_row(initiallyOpen: true, underlap: 12));
    expect(_rowLeft(tester), -160);
    final archive = tester.getRect(
      find
          .ancestor(
            of: find.text('Archive'),
            matching: find.byType(DesignPressable),
          )
          .first,
    );
    expect(archive.width, 92);
    expect(archive.left, 300 - 160 - 12);
    expect(_seen['Archive']!.underlap, 12);
    expect(_seen['Delete']!.underlap, 0);
    // Under the row's edge: the row's, which closes it.
    await tester.tapAt(const Offset(300 - 160 - 6, 30));
    await tester.pumpAndSettle();
    expect(_ran, isEmpty);
    expect(_rowLeft(tester), 0);
  });

  testWidgets('keyboard: Left shows the end actions and focuses the first; '
      'Escape closes and focus is back in the row; right to left mirrors', (
    tester,
  ) async {
    await tester.pumpWidget(_row(reduceMotion: true));
    _rowNode.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    await tester.pump();
    expect(_rowLeft(tester), -160, reason: 'Reduce Motion: no slide');
    expect(_rowNode.hasFocus, isFalse);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(_rowLeft(tester), 0);
    expect(_rowNode.hasFocus, isTrue);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      _row(direction: TextDirection.rtl, reduceMotion: true),
    );
    _rowNode.requestFocus();
    await tester.pump();
    final rest = _rowLeft(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    await tester.pump();
    expect(
      _rowLeft(tester) - rest,
      -80,
      reason: 'right to left, Left slides the row left, showing the start',
    );
  });

  testWidgets('a screen reader gets each action on the row', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_row());
    final node = tester.getSemantics(find.text('Message'));
    final ids = node.getSemanticsData().customSemanticsActionIds!;
    expect(ids, hasLength(3));
    final owner = semanticsOwner();
    final archive = CustomSemanticsAction.getIdentifier(
      const CustomSemanticsAction(label: 'Archive'),
    );
    owner.performAction(node.id, SemanticsAction.customAction, archive);
    expect(_ran, ['archive']);
    semantics.dispose();
  });

  testWidgets('the swipe adds no unlabelled node, closed or open', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_row());
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await tester.pumpWidget(_row(initiallyOpen: true));
    await tester.pumpAndSettle();
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    semantics.dispose();
  });
}

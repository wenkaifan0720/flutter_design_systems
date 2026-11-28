import 'dart:ui' show Tristate;

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_contract.dart';
import 'behaviour_harness.dart';

final List<String> _ran = [];
final Map<String, RawSwipeActionDetails> _seen = {};
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
    child: RawSwipeActions(
      initiallyOpen: initiallyOpen,
      underlap: underlap,
      startActions: [
        RawSwipeAction(label: 'Pin', onPressed: () => _ran.add('pin')),
      ],
      endActions: [
        RawSwipeAction(
          label: 'Delete',
          destructive: true,
          onPressed: () => _ran.add('delete'),
        ),
        RawSwipeAction(label: 'Archive', onPressed: () => _ran.add('archive')),
      ],
      actionBuilder: (context, action, state) {
        _seen[action.label] = state;
        return Center(child: Text(action.label));
      },
      child: RawButton(
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
    'RawSwipeActions',
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

  testWidgets('the open row shows the click cursor: a click there closes '
      'it', (tester) async {
    await tester.pumpWidget(_row(initiallyOpen: true));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: const Offset(60, 30));
    await tester.pump();
    expect(
      RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
      SystemMouseCursors.click,
    );
    await tester.tapAt(const Offset(60, 30));
    await tester.pumpAndSettle();
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
              .ancestor(of: find.text(label), matching: find.byType(RawButton))
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

  testWidgets('the uncovered strip clips at its start and end only, so an '
      'action\'s shadow reaches past the row; a reader of the paint clip '
      'sees the clip itself', (tester) async {
    await tester.pumpWidget(_row(initiallyOpen: true));
    final clip = tester.renderObject<RenderClipRect>(
      find
          .ancestor(of: find.text('Delete'), matching: find.byType(ClipRect))
          .first,
    );
    final size = clip.size;
    final cut = clip.clipper!.getClip(size);
    expect(cut.left, 0);
    expect(cut.right, size.width);
    expect(cut.top, lessThan(-6), reason: 'open above, past a shadow');
    expect(cut.bottom, greaterThan(size.height + 6), reason: 'and below');
    expect(clip.clipper!.getApproximateClipRect(size), cut);
    expect(clip.describeApproximatePaintClip(clip.child!), cut);
  });

  testWidgets('a slid row is cut at its start and end, open above and '
      'below; at rest nothing is cut', (tester) async {
    // Keycap r3: a swiped title ran past the row onto the well's wall.
    Rect visible(Finder f) {
      final box = tester.renderObject<RenderBox>(f);
      var rect = MatrixUtils.transformRect(
        box.getTransformTo(null),
        Offset.zero & box.size,
      );
      for (RenderObject? o = box.parent; o != null; o = o.parent) {
        if (o is RenderClipRect && o.clipBehavior != Clip.none) {
          final cut = o.clipper?.getClip(o.size) ?? Offset.zero & o.size;
          rect = rect.intersect(
            MatrixUtils.transformRect(o.getTransformTo(null), cut),
          );
        }
      }
      return rect;
    }

    await tester.pumpWidget(_row(initiallyOpen: true));
    expect(_rowLeft(tester), -160);
    final words = visible(find.text('Message'));
    expect(words.left, 0, reason: "cut at the row's start");
    final clip = tester.renderObject<RenderClipRect>(
      find
          .ancestor(of: find.text('Message'), matching: find.byType(ClipRect))
          .first,
    );
    final cut = clip.clipper!.getClip(clip.size);
    expect(cut.top, lessThan(-6), reason: 'open above, past a shadow');
    expect(cut.bottom, greaterThan(clip.size.height + 6), reason: 'and below');

    // The row's strip still in sight closes it.
    await tester.tapAt(const Offset(70, 30));
    await tester.pumpAndSettle();
    expect(_rowLeft(tester), 0);
    expect(clip.clipBehavior, Clip.none, reason: 'a ring round it shows whole');
  });

  testWidgets('an underlap runs the strip on under the row: the innermost '
      'slot is that much wider, and the row still takes the tap', (
    tester,
  ) async {
    await tester.pumpWidget(_row(initiallyOpen: true, underlap: 12));
    expect(_rowLeft(tester), -160);
    final archive = tester.getRect(
      find
          .ancestor(of: find.text('Archive'), matching: find.byType(RawButton))
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

  // Android's and the web's flag, then iOS's alone.
  for (final ios in [false, true]) {
    testWidgets('keyboard: Left shows the end actions and focuses the first; '
        'Escape closes and focus is back in the row; right to left mirrors'
        '${ios ? ' (iOS\'s Reduce Motion alone)' : ''}', (tester) async {
      if (ios) iosReduceMotion(tester);
      await tester.pumpWidget(_row(reduceMotion: !ios));
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
        _row(direction: TextDirection.rtl, reduceMotion: !ios),
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
  }

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

  group('0.3.0', () {
    Widget row(
      String label, {
      RawSwipeActionsController? controller,
      bool closeOnScroll = true,
      double dampingRatio = 1,
    }) => RawSwipeActions(
      key: ValueKey(label),
      controller: controller,
      closeOnScroll: closeOnScroll,
      dampingRatio: dampingRatio,
      startActions: [RawSwipeAction(label: 'Pin', onPressed: () {})],
      endActions: [
        RawSwipeAction(
          label: 'Delete',
          destructive: true,
          onPressed: () => _ran.add('delete $label'),
        ),
      ],
      actionBuilder: (context, action, details) =>
          Center(child: Text(action.label)),
      child: SizedBox(height: 60, child: Text(label)),
    );

    double left(WidgetTester tester, String label) =>
        tester.getTopLeft(find.text(label)).dx;

    Widget list({
      bool closeOnScroll = true,
      ScrollController? scroll,
      List<String> played = const [],
    }) => harness(
      RawHapticsScope(
        haptics: RawHaptics(
          selectionChanged: () => played.add('selectionChanged'),
          longPress: () => played.add('longPress'),
          thresholdCrossed: () => played.add('thresholdCrossed'),
        ),
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 300,
            child: ListView(
              controller: scroll,
              children: [
                for (var i = 0; i < 30; i++)
                  row('Row $i', closeOnScroll: closeOnScroll),
              ],
            ),
          ),
        ),
      ),
    );

    testWidgets('the controller opens either side, closes it, and says so', (
      tester,
    ) async {
      final controller = RawSwipeActionsController();
      addTearDown(controller.dispose);
      var told = 0;
      controller
        ..addListener(() => told++)
        ..openEndActions();
      expect(controller.isOpen, isFalse, reason: 'no row: nothing');
      await tester.pumpWidget(
        harness(
          Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 300,
              child: row('Message', controller: controller),
            ),
          ),
        ),
      );
      controller.openEndActions();
      await tester.pumpAndSettle();
      expect(controller.isOpen, isTrue);
      expect(left(tester, 'Message'), -80);
      controller.openStartActions();
      await tester.pumpAndSettle();
      expect(left(tester, 'Message'), 80);
      controller.close();
      await tester.pumpAndSettle();
      expect(controller.isOpen, isFalse);
      expect(left(tester, 'Message'), 0);
      expect(told, 2);

      // A new controller takes over; the old one lets go.
      final next = RawSwipeActionsController();
      addTearDown(next.dispose);
      await tester.pumpWidget(
        harness(
          Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 300,
              child: row('Message', controller: next),
            ),
          ),
        ),
      );
      controller.openEndActions();
      next.openEndActions();
      await tester.pumpAndSettle();
      expect(left(tester, 'Message'), -80);
      expect(controller.isOpen, isFalse);
      expect(next.isOpen, isTrue);
    });

    testWidgets('rows in one scroll view open one at a time', (tester) async {
      await tester.pumpWidget(list());
      await tester.drag(find.text('Row 1'), const Offset(-60, 0));
      await tester.pumpAndSettle();
      expect(left(tester, 'Row 1'), -80);
      await tester.drag(find.text('Row 3'), const Offset(60, 0));
      await tester.pumpAndSettle();
      expect(left(tester, 'Row 3'), 80);
      expect(left(tester, 'Row 1'), 0, reason: 'the other closed');
    });

    testWidgets('its scroll view scrolling closes it, unless told not to', (
      tester,
    ) async {
      for (final closes in [true, false]) {
        final scroll = ScrollController();
        addTearDown(scroll.dispose);
        await tester.pumpWidget(list(closeOnScroll: closes, scroll: scroll));
        await tester.drag(find.text('Row 1'), const Offset(-60, 0));
        await tester.pumpAndSettle();
        expect(left(tester, 'Row 1'), -80);
        await tester.drag(find.text('Row 4'), const Offset(0, -40));
        await tester.pumpAndSettle();
        expect(scroll.offset, greaterThan(0));
        expect(left(tester, 'Row 1'), closes ? 0 : -80);
        await tester.pumpWidget(const SizedBox());
      }
    });

    testWidgets('a full swipe plays the threshold as it arms, and runs the '
        'edge action once slid away', (tester) async {
      final played = <String>[];
      await tester.pumpWidget(list(played: played));
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Row 0')),
      );
      await gesture.moveBy(const Offset(-20, 0));
      await gesture.moveBy(const Offset(-100, 0));
      await tester.pump();
      expect(played, isEmpty);
      await gesture.moveBy(const Offset(-100, 0));
      await tester.pump();
      expect(played, ['thresholdCrossed']);
      await gesture.moveBy(const Offset(-10, 0));
      await tester.pump();
      expect(played, ['thresholdCrossed'], reason: 'once as it arms');
      await gesture.up();
      await tester.pumpAndSettle();
      expect(_ran, ['delete Row 0']);
    });

    testWidgets('an underdamped token springs past its rest and back', (
      tester,
    ) async {
      final controller = RawSwipeActionsController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        harness(
          Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 300,
              child: row('Message', controller: controller, dampingRatio: 0.3),
            ),
          ),
        ),
      );
      controller.openEndActions();
      final xs = <double>[];
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        xs.add(left(tester, 'Message'));
      }
      expect(xs.reduce((a, b) => a < b ? a : b), lessThan(-82));
      await tester.pumpAndSettle();
      expect(left(tester, 'Message'), -80);
    });

    test('its new fields, for the inspector', () {
      final text = RawSwipeActions(
        closeOnScroll: false,
        dampingRatio: 0.5,
        actionBuilder: (context, action, details) => const SizedBox(),
        child: const SizedBox(),
      ).toDiagnosticsNode().toStringDeep();
      expect(text, contains('closeOnScroll: false'));
      expect(text, contains('dampingRatio: 0.5'));
    });
  });
}

import 'dart:async';

import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_contract.dart';
import 'behaviour_harness.dart';

const _panel = ValueKey('panel');

// Where a screen reader outlines the barrier, [label], in the screen's
// coordinates: null when no node says it.
Rect? _barrierRect(String label) {
  Rect? found;
  void visit(SemanticsNode node, Matrix4 parent) {
    final m = parent.clone();
    if (node.transform != null) m.multiply(node.transform!);
    if (node.getSemanticsData().label == label) {
      found = MatrixUtils.transformRect(m, node.rect);
    }
    node.visitChildren((child) {
      visit(child, m);
      return true;
    });
  }

  visit(semanticsOwner().rootSemanticsNode!, Matrix4.identity());
  return found;
}

// The bare reference painter: a grey panel, a handle, a close button,
// [field] and, when [rows], a list under them.
Widget _panelOf(
  RawBottomSheetDetails details, {
  int rows = 0,
  Widget? field,
  ValueChanged<RawBottomSheetDetails>? onDetails,
}) {
  onDetails?.call(details);
  return Container(
    key: _panel,
    color: const Color(0xFFEEEEEE),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RawBottomSheetDragHandle(
          builder: (context, states) => Container(
            key: const ValueKey('handle'),
            width: 32,
            height: 4,
            color: states.contains(WidgetState.focused)
                ? const Color(0xFF000000)
                : const Color(0xFF888888),
          ),
        ),
        RawButton(
          onPressed: details.close,
          semanticLabel: 'Close',
          excludeSemantics: true,
          minimumSize: const Size(44, 44),
          builder: (context, states, _) => const Text('close'),
        ),
        ?field,
        if (rows > 0)
          Expanded(
            child: ListView(
              controller: details.scrollController,
              children: [
                for (var i = 0; i < rows; i++)
                  SizedBox(height: 50, child: Text('Row $i')),
              ],
            ),
          ),
      ],
    ),
  );
}

// An app whose opener pushes [route]; haptics recorded into [played].
Widget _app(
  RawBottomSheetRoute<void> Function() route, {
  List<String>? played,
  TextDirection direction = TextDirection.ltr,
  bool reduceMotion = false,
  double textScale = 1,
}) => harness(
  Builder(
    builder: (context) => Align(
      alignment: Alignment.topCenter,
      child: RawButton(
        semanticLabel: 'Open',
        excludeSemantics: true,
        minimumSize: const Size(44, 44),
        onPressed: () => Navigator.of(context).push(route()),
        builder: (context, states, _) => const Text('open'),
      ),
    ),
  ),
  textDirection: direction,
  reduceMotion: reduceMotion,
  textScale: textScale,
  wrap: played == null
      ? null
      : (context, navigator) => RawHapticsScope(
          haptics: RawHaptics(
            selectionChanged: () => played.add('selectionChanged'),
            longPress: () => played.add('longPress'),
            thresholdCrossed: () => played.add('thresholdCrossed'),
          ),
          child: navigator!,
        ),
);

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

Rect _rect(WidgetTester tester) => tester.getRect(find.byKey(_panel));

// A text field on [node], torn down with the test.
Widget _field(WidgetTester tester, FocusNode node) {
  final text = TextEditingController(text: 'Blue');
  addTearDown(text.dispose);
  return SizedBox(
    width: 200,
    child: EditableText(
      controller: text,
      focusNode: node,
      style: const TextStyle(fontSize: 14, color: Color(0xFF000000)),
      cursorColor: const Color(0xFF000000),
      backgroundCursorColor: const Color(0xFF888888),
    ),
  );
}

// A slow drag from the panel's top, by [dy].
Future<void> _drag(WidgetTester tester, double dy) async {
  final top = _rect(tester).topCenter + const Offset(0, 2);
  final gesture = await tester.startGesture(top);
  for (var i = 1; i <= 10; i++) {
    await gesture.moveTo(top + Offset(0, dy * i / 10));
    await tester.pump(const Duration(milliseconds: 100));
  }
  await gesture.up();
}

void main() {
  testWidgets("the barrier's node stops at the sheet's top, as Material's "
      'modal bottom sheet does', (tester) async {
    final semantics = tester.ensureSemantics();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      harness(
        Builder(
          builder: (context) => Center(
            child: RawButton(
              semanticLabel: 'Open',
              onPressed: () => Navigator.of(context).push(
                RawBottomSheetRoute<void>(
                  barrierLabel: 'Dismiss',
                  builder: (context, details) =>
                      const SizedBox(height: 400, width: double.infinity),
                ),
              ),
              builder: (context, states, _) => const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(_barrierRect('Dismiss'), const Rect.fromLTRB(0, 0, 390, 444));
    semantics.dispose();
  });

  for (final reduce in [false, true]) {
    testWidgets(
      'a full-screen sheet is a named page with motion and Escape (reduce $reduce)',
      (tester) async {
        final route = RawSheetRoute<void>(
          semanticLabel: 'Edit recording',
          builder: (_) =>
              const ColoredBox(key: _panel, color: Color(0xFFEEEEEE)),
        );
        await tester.pumpWidget(
          harness(
            Builder(
              builder: (context) => GestureDetector(
                onTap: () => Navigator.of(context).push(route),
                child: const Text('Open'),
              ),
            ),
            reduceMotion: reduce,
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 40));
        expect(_rect(tester).top, reduce ? isZero : greaterThan(0));
        await tester.pumpAndSettle();
        expect(route.opaque && route.fullscreenDialog, isTrue);
        expect(_rect(tester), const Rect.fromLTWH(0, 0, 800, 600));
        expect(find.bySemanticsLabel('Edit recording'), findsOneWidget);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(find.text('Open'), findsOneWidget);
      },
    );
  }

  behaviourContract(
    'RawBottomSheetRoute',
    build: (c) => Builder(
      builder: (context) => Center(
        child: RawButton(
          semanticLabel: 'Open',
          excludeSemantics: true,
          minimumSize: const Size(44, 44),
          onPressed: () => Navigator.of(context).push(
            RawBottomSheetRoute<void>(
              semanticLabel: 'Filters',
              snapSizes: const [0.5, 1],
              builder: (context, details) => _panelOf(details),
            ),
          ),
          builder: (context, states, _) => const Text('open'),
        ),
      ),
    ),
    // Opened from the keyboard, so there is a focus to go back to.
    open: (tester) async {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    },
    node: () => find.bySemanticsLabel('Filters'),
    // A route of its own: it scopes what a screen reader reaches, names it,
    // and a screen reader can dismiss it.
    semantics: isSemantics(
      label: 'Filters',
      scopesRoute: true,
      namesRoute: true,
      hasDismissAction: true,
    ),
    noDisabledState: 'a sheet has no disabled state',
    root: () => find.byKey(_panel),
    keyboard: (p) async {
      await p.tabInto(find.byKey(_panel));
      for (var i = 0; i < 3; i++) {
        await p.tab();
        expect(p.focusIn(find.byKey(_panel)), isTrue, reason: 'Tab stays');
      }
      await p.key(LogicalKeyboardKey.escape);
      expect(find.byKey(_panel), findsNothing, reason: 'Escape closes it');
      expect(
        p.tester.getSemantics(find.bySemanticsLabel('Open')),
        isSemantics(isFocused: true),
        reason: 'focus goes back to what opened it',
      );
    },
    rtl: (p) async {
      final r = p.tester.getRect(find.byKey(_panel));
      expect(r.left, 0);
      expect(r.right, 800);
    },
    motion: (p) async {
      await p.tester.tap(find.text('close'));
      await p.tester.pump();
    },
  );

  testWidgets('Enter activates the first action in a keyboard-opened sheet', (
    tester,
  ) async {
    final activated = <String>[];
    await tester.pumpWidget(
      _app(
        () => RawBottomSheetRoute<void>(
          builder: (_, details) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final label in ['Pin', 'Share'])
                RawButton(
                  onPressed: () {
                    activated.add(label);
                    details.close();
                  },
                  builder: (_, states, child) => Text(label),
                ),
            ],
          ),
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(tester.getSemantics(find.text('Pin')), isSemantics(isFocused: true));
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(activated, ['Pin']);
    expect(Focus.of(tester.element(find.text('open'))).hasPrimaryFocus, isTrue);
  });

  testWidgets('it rises to its first size, a share of the room, and is laid '
      'out at it', (tester) async {
    late RawBottomSheetDetails details;
    await tester.pumpWidget(
      _app(
        () => RawBottomSheetRoute<void>(
          snapSizes: const [0.5, 1],
          builder: (context, d) => _panelOf(details = d),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(_rect(tester).top, greaterThan(300), reason: 'still rising');
    await tester.pumpAndSettle();
    expect(_rect(tester), const Rect.fromLTRB(0, 300, 800, 600));
    expect(details.size.value, 0.5);
    expect(details.animation.value, 1);
    expect(details.snapSizes, [0.5, 1]);
  });

  testWidgets('a drag moves it with the finger; let go, it settles on the '
      'size nearest, playing a step', (tester) async {
    final played = <String>[];
    final dragging = <bool>[];
    await tester.pumpWidget(
      _app(
        () => RawBottomSheetRoute<void>(
          snapSizes: const [0.5, 1],
          builder: (context, d) =>
              _panelOf(d, onDetails: (d) => dragging.add(d.dragging)),
        ),
        played: played,
      ),
    );
    await _open(tester);
    final gesture = await tester.startGesture(const Offset(400, 302));
    await gesture.moveTo(const Offset(400, 202));
    await tester.pump();
    expect(_rect(tester).top, 200, reason: 'with the finger, no jump');
    expect(dragging.last, isTrue);
    await gesture.moveTo(const Offset(400, 102));
    await tester.pump(const Duration(seconds: 1));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(_rect(tester).top, 0, reason: 'nearer the full size');
    expect(played, ['selectionChanged']);
    expect(dragging.last, isFalse);

    await _drag(tester, 120);
    await tester.pumpAndSettle();
    expect(_rect(tester).top, 0, reason: 'nearer where it was: back');
  });

  testWidgets('a fling settles on the next size it points to; flung down '
      'from its smallest, it closes', (tester) async {
    await tester.pumpWidget(
      _app(
        () => RawBottomSheetRoute<void>(
          snapSizes: const [0.25, 0.5, 1],
          initialSize: 0.5,
          builder: (context, d) => _panelOf(d),
        ),
      ),
    );
    await _open(tester);
    expect(_rect(tester).top, 300);
    await tester.fling(find.text('close'), const Offset(0, -100), 1500);
    await tester.pumpAndSettle();
    expect(_rect(tester).top, 0, reason: 'up to the next size');
    await tester.fling(find.text('close'), const Offset(0, 100), 1500);
    await tester.pumpAndSettle();
    expect(_rect(tester).top, 300, reason: 'down one size, not closed');
    await tester.fling(find.text('close'), const Offset(0, 100), 1500);
    await tester.pumpAndSettle();
    expect(_rect(tester).top, 450);
    await tester.fling(find.text('close'), const Offset(0, 100), 1500);
    await tester.pumpAndSettle();
    expect(find.byKey(_panel), findsNothing, reason: 'closed');
  });

  testWidgets('dragged below half its smallest size it slides away, playing '
      'the threshold as it passes it', (tester) async {
    final played = <String>[];
    await tester.pumpWidget(
      _app(
        () => RawBottomSheetRoute<void>(
          snapSizes: const [0.5],
          builder: (context, d) => _panelOf(d),
        ),
        played: played,
      ),
    );
    await _open(tester);
    await _drag(tester, 100);
    await tester.pumpAndSettle();
    expect(_rect(tester).top, 300, reason: 'a third down: back');
    expect(played, isEmpty);
    await _drag(tester, 200);
    expect(played, ['thresholdCrossed']);
    await tester.pumpAndSettle();
    expect(find.byKey(_panel), findsNothing);
  });

  testWidgets('a PopScope refuses: a dragged sheet springs back, and the '
      'app is told', (tester) async {
    var asked = 0;
    await tester.pumpWidget(
      _app(
        () => RawBottomSheetRoute<void>(
          snapSizes: const [0.5],
          builder: (context, d) => PopScope<void>(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) asked++;
            },
            child: _panelOf(d),
          ),
        ),
      ),
    );
    await _open(tester);
    await _drag(tester, 250);
    await tester.pumpAndSettle();
    expect(asked, 1);
    expect(_rect(tester).top, 300, reason: 'back open');
    await tester.tapAt(const Offset(400, 100));
    await tester.pumpAndSettle();
    expect(asked, 2, reason: 'the barrier asked too');
    expect(find.byKey(_panel), findsOneWidget);
  });

  testWidgets('dragged to another size and back, the field in it keeps the '
      'focus, and Escape still closes it', (tester) async {
    final field = FocusNode(debugLabel: 'field');
    addTearDown(field.dispose);
    await tester.pumpWidget(
      _app(
        () => RawBottomSheetRoute<void>(
          snapSizes: const [0.5, 1],
          builder: (context, d) => _panelOf(d, field: _field(tester, field)),
        ),
      ),
    );
    await _open(tester);
    field.requestFocus();
    await tester.pump();
    expect(field.hasPrimaryFocus, isTrue);
    await _drag(tester, -300);
    await tester.pumpAndSettle();
    expect(_rect(tester).top, 0, reason: 'at its largest');
    expect(field.hasPrimaryFocus, isTrue, reason: 'kept through the drag');
    await _drag(tester, 300);
    await tester.pumpAndSettle();
    expect(_rect(tester).top, 300, reason: 'back at its smallest');
    expect(field.hasPrimaryFocus, isTrue, reason: 'kept through the drag');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byKey(_panel), findsNothing, reason: 'Escape closes it');
  });

  testWidgets('a drag a PopScope refuses springs back with the focus in it', (
    tester,
  ) async {
    final field = FocusNode(debugLabel: 'field');
    addTearDown(field.dispose);
    await tester.pumpWidget(
      _app(
        () => RawBottomSheetRoute<void>(
          snapSizes: const [0.5],
          builder: (context, d) => PopScope<void>(
            canPop: false,
            child: _panelOf(d, field: _field(tester, field)),
          ),
        ),
      ),
    );
    await _open(tester);
    field.requestFocus();
    await tester.pump();
    await _drag(tester, 250);
    await tester.pumpAndSettle();
    expect(_rect(tester).top, 300, reason: 'back open');
    expect(field.hasPrimaryFocus, isTrue);
  });

  testWidgets('a drag that closes it gives the focus back to what opened '
      'it, as Escape does', (tester) async {
    final field = FocusNode(debugLabel: 'field');
    addTearDown(field.dispose);
    await tester.pumpWidget(
      _app(
        () => RawBottomSheetRoute<void>(
          snapSizes: const [0.5, 1],
          builder: (context, d) => _panelOf(d, field: _field(tester, field)),
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    field.requestFocus();
    await tester.pump();
    await _drag(tester, 280);
    await tester.pumpAndSettle();
    expect(find.byKey(_panel), findsNothing);
    expect(
      Focus.of(tester.element(find.text('open'))).hasPrimaryFocus,
      isTrue,
      reason: 'focus goes back to what opened it',
    );
    expect(field.hasFocus, isFalse);
  });

  testWidgets('its content\'s scroll view hands the drag over: up, the sheet '
      'grows first; down at the top, it shrinks', (tester) async {
    await tester.pumpWidget(
      _app(
        () => RawBottomSheetRoute<void>(
          snapSizes: const [0.5, 1],
          builder: (context, d) => _panelOf(d, rows: 40),
        ),
      ),
    );
    await _open(tester);
    final list = find.byType(Scrollable);
    final position = tester.state<ScrollableState>(list).position;
    final gesture = await tester.startGesture(const Offset(400, 500));
    await gesture.moveBy(const Offset(0, -20));
    await tester.pump();
    await gesture.moveBy(const Offset(0, -200));
    await tester.pump();
    // The list's own drag starts past its slop: 200 of the 220 moved it.
    expect(_rect(tester).top, closeTo(100, 0.5), reason: 'the sheet grew');
    expect(position.pixels, 0, reason: 'the content waited');
    await gesture.moveBy(const Offset(0, -200));
    await tester.pump();
    expect(_rect(tester).top, 0, reason: 'grown to its largest');
    expect(position.pixels, closeTo(100, 0.5), reason: 'the rest scrolled');
    await gesture.up();
    await tester.pumpAndSettle();
    expect(_rect(tester).top, 0);

    // Down: the content scrolls back first, then the sheet shrinks.
    final down = await tester.startGesture(const Offset(400, 300));
    await down.moveBy(const Offset(0, 20));
    await tester.pump();
    await down.moveBy(const Offset(0, 300));
    await tester.pump();
    expect(position.pixels, 0);
    expect(_rect(tester).top, closeTo(200, 0.5), reason: '100 scrolled back');
    expect(_rect(tester).top, greaterThan(0), reason: 'then the sheet');
    await down.up();
    await tester.pumpAndSettle();
    expect(_rect(tester).top, 300);
  });

  testWidgets('a fling up its content at the largest size scrolls the '
      'content; a fling down with the content scrolled flings it', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        () => RawBottomSheetRoute<void>(
          snapSizes: const [0.5, 1],
          initialSize: 1,
          builder: (context, d) => _panelOf(d, rows: 60),
        ),
      ),
    );
    await _open(tester);
    final position = tester
        .state<ScrollableState>(find.byType(Scrollable))
        .position;
    await tester.fling(find.text('Row 3'), const Offset(0, -200), 2000);
    await tester.pumpAndSettle();
    expect(position.pixels, greaterThan(200));
    expect(_rect(tester).top, 0);
    final scrolled = position.pixels;
    await tester.fling(find.byType(ListView), const Offset(0, 100), 1000);
    await tester.pumpAndSettle();
    expect(position.pixels, lessThan(scrolled));
    expect(_rect(tester).top, 0, reason: 'the sheet stays');
  });

  testWidgets('at its content\'s own height: a drag down closes it past '
      'half', (tester) async {
    await tester.pumpWidget(
      _app(
        () => RawBottomSheetRoute<void>(builder: (context, d) => _panelOf(d)),
      ),
    );
    await _open(tester);
    final r = _rect(tester);
    expect(r.bottom, 600);
    expect(r.height, lessThan(200), reason: 'its content\'s height');
    await _drag(tester, -100);
    await tester.pumpAndSettle();
    expect(_rect(tester), r, reason: 'it does not grow');
    await _drag(tester, r.height * 0.7);
    await tester.pumpAndSettle();
    expect(find.byKey(_panel), findsNothing);
  });

  testWidgets('past its largest size it gives a little, and comes back', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        () => RawBottomSheetRoute<void>(
          snapSizes: const [0.3, 0.6],
          initialSize: 0.6,
          builder: (context, d) => _panelOf(d),
        ),
      ),
    );
    await _open(tester);
    expect(_rect(tester).top, 240);
    final gesture = await tester.startGesture(const Offset(400, 242));
    for (var i = 0; i < 10; i++) {
      await gesture.moveBy(const Offset(0, -10));
    }
    await tester.pump();
    final top = _rect(tester).top;
    expect(top, lessThan(240));
    expect(top, greaterThan(190), reason: 'it resists');
    await gesture.up();
    await tester.pumpAndSettle();
    expect(_rect(tester).top, 240);
  });

  testWidgets('the controller moves it, says its size, and lets go as it '
      'closes', (tester) async {
    final controller = RawBottomSheetController();
    addTearDown(controller.dispose);
    var told = 0;
    controller.addListener(() => told++);
    await tester.pumpWidget(
      _app(
        () => RawBottomSheetRoute<void>(
          snapSizes: const [0.25, 0.5, 1],
          sheetController: controller,
          builder: (context, d) => _panelOf(d),
        ),
      ),
    );
    expect(controller.isAttached, isFalse);
    await _open(tester);
    expect(controller.isAttached, isTrue);
    expect(controller.size, 0.25);
    unawaited(controller.animateTo(0.9));
    await tester.pumpAndSettle();
    expect(controller.size, 1, reason: 'the nearest snap size');
    expect(told, greaterThan(1));
    controller.jumpTo(0.4);
    await tester.pump();
    expect(controller.size, 0.5);
    expect(_rect(tester).top, 300);
    await controller.animateTo(0.5);
    await tester.tap(find.text('close'));
    await tester.pumpAndSettle();
    expect(controller.isAttached, isFalse);
  });

  testWidgets('the drag handle: a press goes to the next size and round; '
      'Up and Down; a screen reader\'s increase and decrease', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _app(
        () => RawBottomSheetRoute<void>(
          snapSizes: const [0.5, 1],
          builder: (context, d) => _panelOf(d),
        ),
      ),
    );
    await _open(tester);
    final handle = find.bySemanticsLabel('Drag handle');
    expect(
      tester.getSemantics(handle),
      isSemantics(
        label: 'Drag handle',
        isButton: true,
        hasTapAction: true,
        hasIncreaseAction: true,
        hasDecreaseAction: false,
        isFocusable: true,
      ),
    );
    await tester.tap(find.byKey(const ValueKey('handle')));
    await tester.pumpAndSettle();
    expect(_rect(tester).top, 0);
    expect(
      tester.getSemantics(handle),
      isSemantics(
        label: 'Drag handle',
        isButton: true,
        hasTapAction: true,
        hasIncreaseAction: false,
        hasDecreaseAction: true,
        isFocusable: true,
      ),
    );
    await tester.tap(find.byKey(const ValueKey('handle')));
    await tester.pumpAndSettle();
    expect(_rect(tester).top, 300, reason: 'from the largest, round');

    final owner = semanticsOwner();
    owner.performAction(
      tester.getSemantics(handle).id,
      SemanticsAction.increase,
    );
    await tester.pumpAndSettle();
    expect(_rect(tester).top, 0);
    owner.performAction(
      tester.getSemantics(handle).id,
      SemanticsAction.decrease,
    );
    await tester.pumpAndSettle();
    expect(_rect(tester).top, 300);

    // The keys, focused.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(tester.getSemantics(handle), isSemantics(isFocused: true));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(_rect(tester).top, 0);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(_rect(tester).top, 0, reason: 'nothing larger');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(_rect(tester).top, 300);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(_rect(tester).top, 300, reason: 'nothing smaller; not closed');
    semantics.dispose();
  });

  testWidgets('a sheet of one size: its handle closes it; outside a sheet a '
      'handle is painted and moves nothing', (tester) async {
    await tester.pumpWidget(
      _app(
        () => RawBottomSheetRoute<void>(builder: (context, d) => _panelOf(d)),
      ),
    );
    await _open(tester);
    await tester.tap(find.byKey(const ValueKey('handle')));
    await tester.pumpAndSettle();
    expect(find.byKey(_panel), findsNothing);

    await tester.pumpWidget(
      harness(
        Center(
          child: RawBottomSheetDragHandle(
            semanticLabel: 'Grip',
            builder: (context, states) =>
                const SizedBox(key: ValueKey('grip'), width: 32, height: 4),
          ),
        ),
      ),
    );
    expect(find.bySemanticsLabel('Grip'), findsOneWidget);
    await tester.tap(find.byType(RawBottomSheetDragHandle));
    await tester.pump();
  });

  testWidgets("the handle's states take dragged while a finger drags the "
      "sheet, as Material's sheet's handle does", (tester) async {
    Set<WidgetState>? handle;
    await tester.pumpWidget(
      _app(
        () => RawBottomSheetRoute<void>(
          snapSizes: const [0.5],
          builder: (context, d) => Container(
            key: _panel,
            color: const Color(0xFFEEEEEE),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RawBottomSheetDragHandle(
                  builder: (context, states) {
                    handle = states;
                    return const SizedBox(width: 32, height: 4);
                  },
                ),
                const SizedBox(height: 200),
              ],
            ),
          ),
        ),
      ),
    );
    await _open(tester);
    expect(handle, isNot(contains(WidgetState.dragged)));
    final top = _rect(tester).topCenter + const Offset(0, 60);
    final gesture = await tester.startGesture(top);
    await gesture.moveBy(const Offset(0, 30));
    await gesture.moveBy(const Offset(0, 30));
    await tester.pump();
    expect(handle, contains(WidgetState.dragged));
    expect(handle, isNot(contains(WidgetState.pressed)));
    await gesture.moveBy(const Offset(0, -60));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(handle, isNot(contains(WidgetState.dragged)));
  });

  testWidgets('under Reduce Motion it fades in place; a drag still moves '
      'it', (tester) async {
    final seen = <double>[];
    await tester.pumpWidget(
      _app(
        () => RawBottomSheetRoute<void>(
          snapSizes: const [0.5],
          dampingRatio: 0.5,
          builder: (context, d) {
            seen.add(d.animation.value);
            return _panelOf(d);
          },
        ),
        reduceMotion: true,
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    expect(_rect(tester).top, 300, reason: 'in place');
    final fade = tester.widget<FadeTransition>(
      find
          .ancestor(
            of: find.byKey(_panel),
            matching: find.byType(FadeTransition),
          )
          .first,
    );
    expect(fade.opacity.value, lessThan(1));
    expect(seen, everyElement(1.0));
    await tester.pumpAndSettle();
    final gesture = await tester.startGesture(const Offset(400, 302));
    await gesture.moveBy(const Offset(0, 20));
    await gesture.moveBy(const Offset(0, 60));
    await tester.pump();
    expect(_rect(tester).top, closeTo(380, 0.5));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(_rect(tester).top, 300);
  });

  testWidgets('it stands above the on-screen keyboard and, with '
      'useSafeArea, under the top inset', (tester) async {
    tester.view.viewInsets = const FakeViewPadding(bottom: 200);
    tester.view.padding = const FakeViewPadding(top: 40);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 600);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _app(
        () => RawBottomSheetRoute<void>(
          snapSizes: const [1],
          useSafeArea: true,
          builder: (context, d) => _panelOf(d),
        ),
      ),
    );
    await _open(tester);
    expect(_rect(tester), const Rect.fromLTRB(0, 40, 800, 400));
  });

  testWidgets('without drag, a drag moves nothing; a barrier tap closes it; '
      'a barrier builder paints the barrier', (tester) async {
    await tester.pumpWidget(
      _app(
        () => RawBottomSheetRoute<void>(
          snapSizes: const [0.5, 1],
          enableDrag: false,
          barrierBuilder: (context, animation) => const ColoredBox(
            key: ValueKey('screen'),
            color: Color(0x33000000),
          ),
          builder: (context, d) => _panelOf(d, rows: 30),
        ),
      ),
    );
    await _open(tester);
    expect(find.byKey(const ValueKey('screen')), findsOneWidget);
    final route =
        ModalRoute.of(tester.element(find.byKey(_panel)))!
            as RawBottomSheetRoute<void>;
    expect(route.barrierColor, isNull);
    expect(route.barrierLabel, 'Dismiss');
    expect(route.barrierDismissible, isTrue);
    expect(route.transitionDuration, isNot(Duration.zero));
    await _drag(tester, -200);
    await tester.pumpAndSettle();
    expect(_rect(tester).top, 300);
    await tester.tapAt(const Offset(400, 100));
    await tester.pumpAndSettle();
    expect(find.byKey(_panel), findsNothing);
  });

  testWidgets('one drag down past its smallest size and back up: it comes '
      'back in, then grows', (tester) async {
    await tester.pumpWidget(
      _app(
        () => RawBottomSheetRoute<void>(
          snapSizes: const [0.5, 1],
          builder: (context, d) => _panelOf(d),
        ),
      ),
    );
    await _open(tester);
    final gesture = await tester.startGesture(const Offset(400, 302));
    await gesture.moveBy(const Offset(0, 100));
    await tester.pump();
    expect(_rect(tester).top, closeTo(400, 0.5), reason: 'sliding away');
    await gesture.moveBy(const Offset(0, -280));
    await tester.pump();
    expect(_rect(tester).top, closeTo(120, 0.5), reason: 'back in, grown');
    await tester.pump(const Duration(seconds: 1));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(_rect(tester).top, 0);
  });

  testWidgets('at its content\'s own height, its size is its share of the '
      'room', (tester) async {
    late RawBottomSheetDetails details;
    await tester.pumpWidget(
      _app(
        () => RawBottomSheetRoute<void>(
          builder: (context, d) => _panelOf(details = d),
        ),
      ),
    );
    await _open(tester);
    expect(details.snapSizes, isEmpty);
    expect(details.size.value, closeTo(_rect(tester).height / 600, 1e-9));
  });

  testWidgets('a drag up the content that grows the sheet to its largest '
      'and flings on scrolls the content', (tester) async {
    await tester.pumpWidget(
      _app(
        () => RawBottomSheetRoute<void>(
          snapSizes: const [0.9, 1],
          builder: (context, d) => _panelOf(d, rows: 60),
        ),
      ),
    );
    await _open(tester);
    final position = tester
        .state<ScrollableState>(find.byType(Scrollable))
        .position;
    await tester.fling(find.byType(ListView), const Offset(0, -200), 3000);
    await tester.pumpAndSettle();
    expect(_rect(tester).top, 0);
    expect(position.pixels, greaterThan(200), reason: 'the content flung');
  });

  testWidgets('the route going mid-drag ends the drag where it is', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        () => RawBottomSheetRoute<void>(
          snapSizes: const [0.5, 1],
          builder: (context, d) => _panelOf(d, rows: 40),
        ),
      ),
    );
    await _open(tester);
    final navigator = Navigator.of(tester.element(find.text('open')));
    final gesture = await tester.startGesture(const Offset(400, 500));
    await gesture.moveBy(const Offset(0, -30));
    await gesture.moveBy(const Offset(0, -60));
    await tester.pump();
    expect(navigator.userGestureInProgress, isTrue);
    await tester.pumpWidget(const SizedBox());
    await gesture.up();
    expect(tester.takeException(), isNull);
  });

  testWidgets('its content\'s scroll view going mid-drag, the sheet staying, '
      'the drag ends as a let-go there and the focus comes back to it', (
    tester,
  ) async {
    final field = FocusNode(debugLabel: 'field');
    addTearDown(field.dispose);
    final listed = ValueNotifier(true);
    addTearDown(listed.dispose);
    await tester.pumpWidget(
      _app(
        () => RawBottomSheetRoute<void>(
          snapSizes: const [0.5, 1],
          builder: (context, d) => ValueListenableBuilder<bool>(
            valueListenable: listed,
            builder: (context, list, _) =>
                _panelOf(d, rows: list ? 40 : 0, field: _field(tester, field)),
          ),
        ),
      ),
    );
    await _open(tester);
    field.requestFocus();
    await tester.pump();
    final navigator = Navigator.of(tester.element(find.text('open')));
    final gesture = await tester.startGesture(const Offset(400, 500));
    await gesture.moveBy(const Offset(0, -30));
    await gesture.moveBy(const Offset(0, -60));
    await tester.pump();
    expect(navigator.userGestureInProgress, isTrue);
    listed.value = false;
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(navigator.userGestureInProgress, isFalse);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.byKey(_panel), findsOneWidget);
    expect(_rect(tester).top, 300, reason: 'settled on the size nearest');
    expect(field.hasPrimaryFocus, isTrue);
  });

  test('the drag handle\'s properties for the inspector', () {
    final text = RawBottomSheetDragHandle(
      semanticLabel: 'Grip',
      builder: (context, states) => const SizedBox(),
    ).toDiagnosticsNode().toStringDeep();
    expect(text, contains('builder'));
    expect(text, contains('semanticLabel: "Grip"'));
  });

  // Every size, direction and text size: nothing overflows and it rests
  // where its size says.
  group('sweep', () {
    for (final size in const [
      Size(390, 844),
      Size(768, 1024),
      Size(1440, 900),
    ]) {
      for (final direction in TextDirection.values) {
        for (final scale in const [1.0, 2.0]) {
          testWidgets('${size.width.toInt()} ${direction.name} x$scale', (
            tester,
          ) async {
            tester.view.physicalSize = size;
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.reset);
            await tester.pumpWidget(
              _app(
                () => RawBottomSheetRoute<void>(
                  snapSizes: const [0.4, 0.9],
                  builder: (context, d) => _panelOf(d, rows: 20),
                ),
                direction: direction,
                textScale: scale,
              ),
            );
            await _open(tester);
            expect(tester.takeException(), isNull);
            expect(_rect(tester).top, closeTo(size.height * 0.6, 0.5));
            await tester.tap(find.byKey(const ValueKey('handle')));
            await tester.pumpAndSettle();
            expect(_rect(tester).top, closeTo(size.height * 0.1, 0.5));
          }, tags: 'sweep');
        }
      }
    }
  });
}

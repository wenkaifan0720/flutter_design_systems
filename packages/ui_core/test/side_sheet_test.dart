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

// The opener and the bare reference painter: a grey panel with a field-less
// close button.
Widget _app({
  RawSheetEdge edge = RawSheetEdge.end,
  TextDirection direction = TextDirection.ltr,
  bool reduceMotion = false,
  RawBarrierBuilder? barrierBuilder,
}) => harness(
  Builder(
    builder: (context) => Center(
      child: RawButton(
        semanticLabel: 'Open',
        onPressed: () => Navigator.of(context).push(
          RawSideSheetRoute<void>(
            edge: edge,
            barrierBuilder: barrierBuilder,
            semanticLabel: 'Filters',
            builder: (context, sheet) => Container(
              key: _panel,
              color: const Color(0xFFEEEEEE),
              child: Align(
                alignment: Alignment.topCenter,
                child: RawButton(
                  onPressed: sheet.close,
                  semanticLabel: 'Close',
                  minimumSize: const Size(44, 44),
                  builder: (context, states, _) => const Text('close'),
                ),
              ),
            ),
          ),
        ),
        builder: (context, states, _) => const Text('open'),
      ),
    ),
  ),
  textDirection: direction,
  reduceMotion: reduceMotion,
);

// An opener pushing a side sheet with a text field on [field] in it.
Widget _fieldApp(WidgetTester tester, FocusNode field) {
  final text = TextEditingController(text: 'Blue');
  addTearDown(text.dispose);
  return harness(
    Builder(
      builder: (context) => Center(
        child: RawButton(
          semanticLabel: 'Open',
          onPressed: () => Navigator.of(context).push(
            RawSideSheetRoute<void>(
              builder: (context, sheet) => Container(
                key: _panel,
                color: const Color(0xFFEEEEEE),
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: 200,
                  child: EditableText(
                    controller: text,
                    focusNode: field,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF000000),
                    ),
                    cursorColor: const Color(0xFF000000),
                    backgroundCursorColor: const Color(0xFF888888),
                  ),
                ),
              ),
            ),
          ),
          builder: (context, states, _) => const Text('open'),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets("the barrier's node is the part the sheet leaves, at either "
      'edge, either way the screen reads', (tester) async {
    final semantics = tester.ensureSemantics();
    tester.view.physicalSize = const Size(1000, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final (edge, direction, expected) in [
      (
        RawSheetEdge.end,
        TextDirection.ltr,
        const Rect.fromLTRB(0, 0, 640, 600),
      ),
      (
        RawSheetEdge.start,
        TextDirection.ltr,
        const Rect.fromLTRB(360, 0, 1000, 600),
      ),
      (
        RawSheetEdge.end,
        TextDirection.rtl,
        const Rect.fromLTRB(360, 0, 1000, 600),
      ),
    ]) {
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(_app(edge: edge, direction: direction));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      final route = ModalRoute.of(tester.element(find.byKey(_panel)))!;
      expect(
        _barrierRect(route.barrierLabel!),
        expected,
        reason: '$edge ${direction.name}',
      );
    }
    semantics.dispose();
  });

  behaviourContract(
    'RawSideSheetRoute',
    build: (c) => Builder(
      builder: (context) => Center(
        child: RawButton(
          semanticLabel: 'Open',
          excludeSemantics: true,
          minimumSize: const Size(44, 44),
          onPressed: () => Navigator.of(context).push(
            RawSideSheetRoute<void>(
              semanticLabel: 'Filters',
              builder: (context, sheet) => Container(
                key: _panel,
                color: const Color(0xFFEEEEEE),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: RawButton(
                    onPressed: sheet.close,
                    semanticLabel: 'Close',
                    excludeSemantics: true,
                    minimumSize: const Size(44, 44),
                    builder: (context, states, _) => const Text('close'),
                  ),
                ),
              ),
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
    // A route of its own: it scopes what a screen reader reaches, and names
    // it.
    semantics: isSemantics(
      label: 'Filters',
      scopesRoute: true,
      namesRoute: true,
    ),
    noDisabledState: 'a sheet has no disabled state',
    keyboard: (p) async {
      await p.tabInto(find.byKey(_panel));
      await p.tab();
      expect(p.focusIn(find.byKey(_panel)), isTrue, reason: 'Tab stays in it');
      await p.key(LogicalKeyboardKey.escape);
      expect(find.byKey(_panel), findsNothing, reason: 'Escape closes it');
      expect(
        p.tester.getSemantics(find.bySemanticsLabel('Open')),
        isSemantics(isFocused: true),
        reason: 'focus goes back to what opened it',
      );
    },
    rtl: (p) async {
      expect(
        p.tester.getTopLeft(find.byKey(_panel)).dx,
        0,
        reason: 'right to left, the end edge is the left',
      );
    },
    motion: (p) async {
      await p.tester.tap(find.text('close'));
      await p.tester.pump();
    },
  );

  testWidgets('it slides in from the end; Escape closes it and focus goes '
      'back to the opener', (tester) async {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(
      () => FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic,
    );
    await tester.pumpWidget(_app());
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    final mid = tester.getRect(find.byKey(_panel));
    await tester.pumpAndSettle();
    final open = tester.getRect(find.byKey(_panel));
    expect(open.right, 800);
    expect(open.width, 360);
    expect(mid.left, greaterThan(open.left), reason: 'it came from the right');

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    final focused = FocusManager.instance.primaryFocus!.context!;
    expect(
      find.descendant(
        of: find.byKey(_panel),
        matching: find.byElementPredicate((e) => e == focused),
      ),
      findsOneWidget,
      reason: 'Tab goes into the sheet',
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byKey(_panel), findsNothing);
    final opener = Focus.of(tester.element(find.text('open')));
    expect(opener.hasFocus, isTrue, reason: 'focus returned');
  });

  testWidgets('right to left: the start edge is on the right; a tap on the '
      'barrier closes it', (tester) async {
    await tester.pumpWidget(
      _app(edge: RawSheetEdge.start, direction: TextDirection.rtl),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(_panel)).right, 800);
    await tester.tapAt(const Offset(20, 300));
    await tester.pumpAndSettle();
    expect(find.byKey(_panel), findsNothing);
  });

  testWidgets('a barrier builder paints the barrier in place of its colour; '
      'the barrier still takes the tap and says its label', (tester) async {
    final semantics = tester.ensureSemantics();
    final seen = <double>[];
    await tester.pumpWidget(
      _app(
        barrierBuilder: (context, animation) {
          seen.add(animation.value);
          return AnimatedBuilder(
            animation: animation,
            builder: (context, _) => Container(
              key: const ValueKey('dots'),
              color: Color.fromRGBO(0, 0, 255, animation.value / 2),
              child: const Text('dots'),
            ),
          );
        },
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('dots')), findsOneWidget);
    final route =
        ModalRoute.of(tester.element(find.byKey(_panel)))!
            as RawSideSheetRoute<void>;
    expect(route.barrierColor, isNull, reason: 'the builder paints it');
    expect(route.animation!.value, 1);
    // The painting is only seen: the barrier says its label, not the dots.
    expect(find.bySemanticsLabel('Close sheet'), findsOneWidget);
    expect(find.bySemanticsLabel('dots'), findsNothing);
    await tester.tapAt(
      tester.getCenter(find.byKey(const ValueKey('dots'))) -
          const Offset(300, 0),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(_panel), findsNothing);
    expect(find.byKey(const ValueKey('dots')), findsNothing);
    expect(seen, isNotEmpty);
    semantics.dispose();
  });

  testWidgets('without a builder the barrier is its colour', (tester) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    final route =
        ModalRoute.of(tester.element(find.byKey(_panel)))!
            as RawSideSheetRoute<void>;
    expect(route.barrierColor, const Color(0x66000000));
  });

  testWidgets('a drag toward its edge closes it; a short one does not', (
    tester,
  ) async {
    await tester.pumpWidget(_app(edge: RawSheetEdge.start));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(_panel)).left, 0);
    await tester.timedDrag(
      find.byKey(_panel),
      const Offset(-60, 0),
      const Duration(milliseconds: 600),
    );
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(_panel)).left, 0, reason: 'went back');
    await tester.drag(find.byKey(_panel), const Offset(-200, 0));
    await tester.pumpAndSettle();
    expect(find.byKey(_panel), findsNothing);
  });

  testWidgets('let go part way, it settles from where it is: no frame '
      'jumps, back open or closed', (tester) async {
    await tester.pumpWidget(_app(edge: RawSheetEdge.start));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    double? left() {
      final panel = find.byKey(_panel);
      return panel.evaluate().isEmpty ? null : tester.getRect(panel).left;
    }

    for (final (by, closes) in [(-100.0, false), (-150.0, true)]) {
      final drag = await tester.startGesture(const Offset(200, 300));
      for (var i = 0; i < 10; i++) {
        await drag.moveBy(Offset(by / 10, 0));
        await tester.pump(const Duration(milliseconds: 16));
      }
      // Held still, so it is let go with no fling.
      await tester.pump(const Duration(milliseconds: 300));
      expect(left(), moreOrLessEquals(by, epsilon: 0.5));
      await drag.up();
      await tester.pump();
      expect(
        left(),
        moreOrLessEquals(by, epsilon: 1),
        reason: 'the frame it is let go, it is where the finger left it',
      );
      final places = <double>[by];
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        final x = left();
        if (x == null) break;
        places.add(x);
      }
      for (var i = 1; i < places.length; i++) {
        final step = places[i] - places[i - 1];
        expect(step.abs(), lessThanOrEqualTo(40), reason: 'frame $i: $places');
        expect(
          closes ? step <= 0 : step >= 0,
          isTrue,
          reason: 'it goes one way: $places',
        );
      }
      await tester.pumpAndSettle();
      expect(left(), closes ? isNull : 0);
    }
  });

  testWidgets('a tap inside is no drag: it leaves the sheet open and the '
      "navigator's gesture count alone; its close button closes it", (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    await tester.tapAt(tester.getRect(find.byKey(_panel)).center);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(_panel), findsOneWidget);
    expect(navigator.userGestureInProgress, isFalse);

    // A short drag after the taps still counts as one gesture while it
    // lasts, and the sheet goes back.
    final drag = await tester.startGesture(
      tester.getRect(find.byKey(_panel)).center,
    );
    await drag.moveBy(const Offset(30, 0));
    await tester.pump();
    expect(navigator.userGestureInProgress, isTrue);
    await drag.up();
    await tester.pumpAndSettle();
    expect(navigator.userGestureInProgress, isFalse);
    expect(tester.getRect(find.byKey(_panel)).right, 800);

    await tester.tap(find.text('close'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(_panel), findsNothing);
  });

  // Android's and the web's flag, then iOS's alone.
  for (final ios in [false, true]) {
    testWidgets(
      'Reduce Motion${ios ? ', iOS\'s alone,' : ''} fades it in place; a narrow '
      'screen leaves a '
      'gap beside it; a screen reader hears its name',
      (tester) async {
        final semantics = tester.ensureSemantics();
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        if (ios) iosReduceMotion(tester);
        await tester.pumpWidget(_app(reduceMotion: !ios));
        await tester.tap(find.text('open'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        final rect = tester.getRect(find.byKey(_panel));
        expect(
          rect.left,
          56,
          reason: 'already in place, and 56 px left beside it',
        );
        expect(find.byType(FadeTransition), findsWidgets);
        await tester.pumpAndSettle();
        expect(find.bySemanticsLabel('Filters'), findsOneWidget);
        semantics.dispose();
      },
    );
  }

  test('it moves on a spring: critically damped by default, or the one '
      'given', () {
    final sheet = RawSideSheetRoute<void>(
      builder: (context, sheet) => const SizedBox(),
    );
    expect(sheet.dampingRatio, 1);
    expect(sheet.stiffness, 700);
    final given = RawSideSheetRoute<void>(
      dampingRatio: 0.5,
      stiffness: 400,
      builder: (context, sheet) => const SizedBox(),
    );
    expect(given.dampingRatio, 0.5);
    expect(given.stiffness, 400);
  });

  testWidgets('an underdamped token: the route stays within 0 and 1', (
    tester,
  ) async {
    late RawSideSheetRoute<void> route;
    await tester.pumpWidget(
      harness(
        Builder(
          builder: (context) => Center(
            child: RawButton(
              semanticLabel: 'Open',
              minimumSize: const Size(44, 44),
              onPressed: () => Navigator.of(context).push(
                route = RawSideSheetRoute<void>(
                  dampingRatio: 0.3,
                  stiffness: 900,
                  builder: (context, sheet) => const SizedBox(key: _panel),
                ),
              ),
              builder: (context, states, _) => const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    final values = <double>[];
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      values.add(route.animation!.value);
    }
    expect(values.every((v) => v >= 0 && v <= 1), isTrue);
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(_panel)).right, 800);
  });

  testWidgets('a drag that leaves it open keeps the focus in it, and Escape '
      'still closes it', (tester) async {
    final field = FocusNode(debugLabel: 'field');
    addTearDown(field.dispose);
    await tester.pumpWidget(_fieldApp(tester, field));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    field.requestFocus();
    await tester.pump();
    await tester.timedDrag(
      find.byKey(_panel),
      const Offset(60, 0),
      const Duration(milliseconds: 600),
    );
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(_panel)).right, 800, reason: 'went back');
    expect(field.hasPrimaryFocus, isTrue, reason: 'kept through the drag');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byKey(_panel), findsNothing, reason: 'Escape closes it');
    expect(
      Focus.of(tester.element(find.text('open'))).hasPrimaryFocus,
      isTrue,
      reason: 'focus returned',
    );
  });

  testWidgets('a drag that closes it gives the focus back to the opener', (
    tester,
  ) async {
    final field = FocusNode(debugLabel: 'field');
    addTearDown(field.dispose);
    await tester.pumpWidget(_fieldApp(tester, field));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    field.requestFocus();
    await tester.pump();
    await tester.drag(find.byKey(_panel), const Offset(200, 0));
    await tester.pumpAndSettle();
    expect(find.byKey(_panel), findsNothing);
    expect(
      Focus.of(tester.element(find.text('open'))).hasPrimaryFocus,
      isTrue,
      reason: 'focus returned',
    );
  });
}

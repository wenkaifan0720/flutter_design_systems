import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_contract.dart';
import 'behaviour_harness.dart';

const _panel = ValueKey('panel');

// The opener and the bare reference painter: a grey panel with a field-less
// close button.
Widget _app({
  DesignSheetEdge edge = DesignSheetEdge.end,
  TextDirection direction = TextDirection.ltr,
  bool reduceMotion = false,
}) => harness(
  Builder(
    builder: (context) => Center(
      child: DesignPressable(
        semanticLabel: 'Open',
        onPressed: () => Navigator.of(context).push(
          DesignSideSheetRoute<void>(
            edge: edge,
            semanticLabel: 'Filters',
            builder: (context, sheet) => Container(
              key: _panel,
              color: const Color(0xFFEEEEEE),
              child: Align(
                alignment: Alignment.topCenter,
                child: DesignPressable(
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

void main() {
  behaviourContract(
    'DesignSideSheetRoute',
    build: (c) => Builder(
      builder: (context) => Center(
        child: DesignPressable(
          semanticLabel: 'Open',
          excludeSemantics: true,
          minimumSize: const Size(44, 44),
          onPressed: () => Navigator.of(context).push(
            DesignSideSheetRoute<void>(
              semanticLabel: 'Filters',
              builder: (context, sheet) => Container(
                key: _panel,
                color: const Color(0xFFEEEEEE),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: DesignPressable(
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
      _app(edge: DesignSheetEdge.start, direction: TextDirection.rtl),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(_panel)).right, 800);
    await tester.tapAt(const Offset(20, 300));
    await tester.pumpAndSettle();
    expect(find.byKey(_panel), findsNothing);
  });

  testWidgets('a drag toward its edge closes it; a short one does not', (
    tester,
  ) async {
    await tester.pumpWidget(_app(edge: DesignSheetEdge.start));
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
    await tester.pumpWidget(_app(edge: DesignSheetEdge.start));
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
      // ignore: avoid_print
      print(
        'PROBE route=${ModalRoute.of(tester.element(find.byKey(_panel)))!.animation!.value} slide=${tester.widget<SlideTransition>(find.ancestor(of: find.byKey(_panel), matching: find.byType(SlideTransition)).first).position.value}',
      );
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

  testWidgets('Reduce Motion fades it in place; a narrow screen leaves a '
      'gap beside it; a screen reader hears its name', (tester) async {
    final semantics = tester.ensureSemantics();
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(reduceMotion: true));
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final rect = tester.getRect(find.byKey(_panel));
    expect(rect.left, 56, reason: 'already in place, and 56 px left beside it');
    expect(find.byType(FadeTransition), findsWidgets);
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Filters'), findsOneWidget);
    semantics.dispose();
  });
}

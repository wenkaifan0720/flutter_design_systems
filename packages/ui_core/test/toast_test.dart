import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_contract.dart';
import 'behaviour_harness.dart';

// The bare reference painter: the message, and the action as a pressable.
Widget _paint(BuildContext context, RawToastDetails details) => Container(
  key: ValueKey('toast-${details.toast.message}'),
  color: const Color(0xFFEEEEEE),
  padding: const EdgeInsets.all(8),
  child: Row(
    children: [
      Expanded(child: Text(details.toast.message)),
      if (details.runAction != null)
        RawButton(
          onPressed: details.runAction,
          minimumSize: const Size(48, 48),
          builder: (context, states, _) => Text(details.toast.actionLabel!),
        ),
    ],
  ),
);

late RawToasterState _toaster;

Widget _app({
  int maxVisible = 3,
  bool reduceMotion = false,
  bool accessibleNavigation = false,
  double dampingRatio = 1,
  TextDirection textDirection = TextDirection.ltr,
  double textScale = 1,
  AlignmentGeometry alignment = AlignmentDirectional.bottomCenter,
  Widget home = const SizedBox.expand(),
  RawToastBuilder toastBuilder = _paint,
}) => harness(
  home,
  reduceMotion: reduceMotion,
  accessibleNavigation: accessibleNavigation,
  textDirection: textDirection,
  textScale: textScale,
  wrap: (context, navigator) => RawToaster(
    maxVisible: maxVisible,
    dampingRatio: dampingRatio,
    alignment: alignment,
    constraints: const BoxConstraints(maxWidth: 300),
    toastBuilder: toastBuilder,
    child: Builder(
      builder: (context) {
        _toaster = RawToaster.of(context);
        return navigator!;
      },
    ),
  ),
);

void main() {
  testWidgets('RawToasterKeepClear: a bar along the top keeps top toasts '
      'below it, in place of the safe inset, and lets go as it leaves', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final toaster = GlobalKey<RawToasterState>();
    var bar = true;
    late StateSetter setOuter;
    await tester.pumpWidget(
      harness(
        Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(padding: const EdgeInsets.only(top: 24)),
            child: RawToaster(
              key: toaster,
              alignment: AlignmentDirectional.topCenter,
              toastBuilder: (context, details) => SizedBox(
                key: const ValueKey('toast'),
                height: 48,
                child: Text(details.toast.message),
              ),
              child: StatefulBuilder(
                builder: (context, setState) {
                  setOuter = setState;
                  return Column(
                    children: [
                      if (bar)
                        const RawToasterKeepClear(
                          child: SizedBox(height: 80, width: double.infinity),
                        ),
                      const Expanded(child: SizedBox.expand()),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    toaster.currentState!.show(
      const RawToast(message: 'Saved', duration: null),
    );
    await tester.pumpAndSettle();
    Rect toast() => tester.getRect(find.byKey(const ValueKey('toast')));
    expect(toast().top, 80 + 16, reason: 'below the bar, its inset its own');
    setOuter(() => bar = false);
    await tester.pumpAndSettle();
    expect(toast().top, 24 + 16, reason: 'the safe inset again');
  });

  group('RawToaster keeps the nodes of what it holds', () {
    Widget toaster(Widget child, {bool f6 = true}) => RawToaster(
      toastBuilder: (context, details) => Text(details.toast.message),
      focusShortcut: f6 ? const SingleActivator(LogicalKeyboardKey.f6) : null,
      child: child,
    );

    for (final f6 in [true, false]) {
      testWidgets('a heading and the text under it stay two nodes, F6 '
          '${f6 ? 'on' : 'off'}', (tester) async {
        final semantics = tester.ensureSemantics();
        await tester.pumpWidget(harness(toaster(headingAndText(), f6: f6)));
        expectHeadingAndTextApart(tester);
        semantics.dispose();
      });
    }

    testWidgets('on the page of a pushed route too', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(harness(const Text('Home')));
      unawaited(
        tester
            .state<NavigatorState>(find.byType(Navigator))
            .push(
              PageRouteBuilder<void>(
                pageBuilder: (context, _, _) => toaster(headingAndText()),
              ),
            ),
      );
      await tester.pumpAndSettle();
      expectHeadingAndTextApart(tester);
      semantics.dispose();
    });
  });

  group('RawToasterKeepClear on a route', () {
    final toaster = GlobalKey<RawToasterState>();
    late StateSetter setPage;
    var barHeight = 80.0;
    NavigatorState navigator(WidgetTester tester) =>
        tester.state<NavigatorState>(find.byType(Navigator));
    Rect toast(WidgetTester tester) =>
        tester.getRect(find.byKey(const ValueKey('toast')));

    // A page with a bar along the bottom, under a toaster over the navigator.
    Future<void> pumpPage(WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      barHeight = 80;
      await tester.pumpWidget(
        harness(
          StatefulBuilder(
            builder: (context, setState) {
              setPage = setState;
              return Column(
                children: [
                  const Expanded(child: SizedBox.expand()),
                  RawToasterKeepClear(
                    child: SizedBox(height: barHeight, width: double.infinity),
                  ),
                ],
              );
            },
          ),
          wrap: (context, navigator) => RawToaster(
            key: toaster,
            toastBuilder: (context, details) => SizedBox(
              key: const ValueKey('toast'),
              height: 40,
              child: Text(details.toast.message),
            ),
            child: navigator!,
          ),
        ),
      );
      toaster.currentState!.show(
        const RawToast(message: 'Saved', duration: null),
      );
      await tester.pumpAndSettle();
      expect(toast(tester).bottom, 700 - 80 - 16, reason: 'above the bar');
    }

    PageRouteBuilder<void> opaque() => PageRouteBuilder<void>(
      pageBuilder: (context, _, _) => const SizedBox.expand(),
    );

    testWidgets('an opaque route over the bar lets the toasts go, and they '
        'keep clear of it again as the route pops', (tester) async {
      await pumpPage(tester);
      unawaited(navigator(tester).push(opaque()));
      await tester.pumpAndSettle();
      expect(
        toast(tester).bottom,
        700 - 16,
        reason: 'the bar is under the pushed page, out of sight',
      );
      navigator(tester).pop();
      await tester.pumpAndSettle();
      expect(toast(tester).bottom, 700 - 80 - 16, reason: 'the bar is back');
    });

    testWidgets('a dialog over the page leaves its bar in sight, and the '
        'toasts clear of it', (tester) async {
      await pumpPage(tester);
      unawaited(
        navigator(tester).push(
          RawDialogRoute<void>(
            pageBuilder: (context, _, _) =>
                const SizedBox(width: 200, height: 100),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(toast(tester).bottom, 700 - 80 - 16);
    });

    testWidgets('a bar that rebuilds while covered keeps nothing clear, and '
        'is read afresh as it comes back', (tester) async {
      await pumpPage(tester);
      unawaited(navigator(tester).push(opaque()));
      await tester.pumpAndSettle();
      setPage(() => barHeight = 96);
      await tester.pumpAndSettle();
      expect(toast(tester).bottom, 700 - 16);
      navigator(tester).pop();
      await tester.pumpAndSettle();
      expect(toast(tester).bottom, 700 - 96 - 16);
    });
  });

  var undone = 0;
  final page = FocusNode(debugLabel: 'page');
  tearDownAll(page.dispose);
  behaviourContract(
    'RawToaster',
    build: (c) => RawToaster(
      toastBuilder: _paint,
      constraints: const BoxConstraints(maxWidth: 300),
      child: Builder(
        builder: (context) {
          _toaster = RawToaster.of(context);
          return Focus(focusNode: page, child: plainFace('page'));
        },
      ),
    ),
    open: (tester) async => _toaster.show(
      RawToast(
        message: 'Saved',
        actionLabel: 'Undo',
        onAction: () => undone++,
        duration: null,
      ),
    ),
    node: () => find.byKey(const ValueKey('toast-Saved')),
    // Heard as it appears, and a screen reader can dismiss it.
    semantics: isSemantics(isLiveRegion: true, hasDismissAction: true),
    noDisabledState: 'a toast has no disabled state',
    keyboard: (p) async {
      expect(p.data.label, contains('Saved'));
      page.requestFocus();
      await p.tester.pump();
      await p.key(LogicalKeyboardKey.f6);
      expect(
        FocusManager.instance.primaryFocus?.debugLabel,
        'RawToast',
        reason: 'F6 jumps to the newest toast',
      );
      await p.key(LogicalKeyboardKey.escape);
      expect(p.node, findsNothing, reason: 'Escape dismisses it');
      expect(page.hasPrimaryFocus, isTrue, reason: 'focus goes back');
    },
    motion: (p) async {
      _toaster.show(const RawToast(message: 'More', duration: null));
      await p.tester.pump();
    },
  );

  testWidgets('more than maxVisible wait their turn, in order', (tester) async {
    await tester.pumpWidget(_app(maxVisible: 2));
    final a = _toaster.show(const RawToast(message: 'a'));
    final b = _toaster.show(
      const RawToast(message: 'b', duration: Duration(seconds: 8)),
    );
    final c = _toaster.show(const RawToast(message: 'c'));
    await tester.pump();
    expect(find.text('a'), findsOneWidget);
    expect(find.text('b'), findsOneWidget);
    expect(find.text('c'), findsNothing);
    expect(_toaster.waitingCount, 1);

    await tester.pump(const Duration(seconds: 4));
    expect(await a.closed, RawToastClosedReason.timeout);
    await tester.pumpAndSettle();
    expect(find.text('a'), findsNothing);
    expect(find.text('c'), findsOneWidget);
    expect(_toaster.waitingCount, 0);

    // c's own four seconds start when it shows, not when it was queued.
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('c'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(await b.closed, RawToastClosedReason.timeout);
    expect(await c.closed, RawToastClosedReason.timeout);
    expect(find.text('c'), findsNothing);
  });

  testWidgets('a pointer over the stack pauses its time', (tester) async {
    await tester.pumpWidget(_app());
    final handle = _toaster.show(const RawToast(message: 'hover'));
    await tester.pumpAndSettle();
    var closed = false;
    unawaited(handle.closed.then((_) => closed = true));

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.text('hover')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 20));
    expect(closed, isFalse);
    expect(find.text('hover'), findsOneWidget);

    await mouse.moveTo(Offset.zero);
    await tester.pump();
    // About 3.6 s were left when the pointer came; the clock picks up there.
    await tester.pump(const Duration(seconds: 3));
    expect(closed, isFalse);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(closed, isTrue);
    expect(find.text('hover'), findsNothing);
  });

  testWidgets('F6 jumps to the newest toast, focus pauses it, Escape '
      'dismisses it and focus goes back', (tester) async {
    final field = FocusNode(debugLabel: 'field');
    addTearDown(field.dispose);
    await tester.pumpWidget(
      _app(
        home: Focus(
          focusNode: field,
          autofocus: true,
          child: const SizedBox.expand(),
        ),
      ),
    );
    await tester.pump();
    expect(field.hasPrimaryFocus, isTrue);
    _toaster.show(const RawToast(message: 'older'));
    final newest = _toaster.show(const RawToast(message: 'newest'));
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.f6);
    await tester.pump();
    expect(field.hasFocus, isFalse);
    expect(_toaster.paused, isTrue);
    await tester.pump(const Duration(seconds: 30));
    expect(find.text('newest'), findsOneWidget);
    expect(find.text('older'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(await newest.closed, RawToastClosedReason.dismissed);
    expect(field.hasPrimaryFocus, isTrue);
    await tester.pumpAndSettle();
    expect(find.text('newest'), findsNothing);
    expect(_toaster.paused, isFalse);
  });

  // Android's and the web's flag, then iOS's alone.
  for (final ios in [false, true]) {
    testWidgets(
      'Reduce Motion${ios ? ', iOS\'s alone,' : ''} neither shortens the time '
      'nor bounces',
      (tester) async {
        // Android's flag also reaches the binding (AnimationController); iOS's
        // reaches no one but the kit.
        if (ios) {
          iosReduceMotion(tester);
        } else {
          debugSemanticsDisableAnimations = true;
          addTearDown(() => debugSemanticsDisableAnimations = null);
        }
        var most = 0.0;
        Widget watch(BuildContext context, RawToastDetails details) =>
            AnimatedBuilder(
              animation: details.animation,
              builder: (context, _) {
                if (details.animation.value > most) {
                  most = details.animation.value;
                }
                return _paint(context, details);
              },
            );
        await tester.pumpWidget(
          _app(reduceMotion: !ios, dampingRatio: 0.4, toastBuilder: watch),
        );
        _toaster.show(const RawToast(message: 'calm'));
        await tester.pumpAndSettle(const Duration(milliseconds: 16));
        await tester.pump(const Duration(seconds: 3));
        expect(find.text('calm'), findsOneWidget);
        expect(most, lessThanOrEqualTo(1.0));

        // Without Reduce Motion the same spring overshoots.
        debugSemanticsDisableAnimations = null;
        if (ios) {
          iosReduceMotion(tester, on: false);
        }
        most = 0;
        await tester.pumpWidget(_app(dampingRatio: 0.4, toastBuilder: watch));
        _toaster.show(const RawToast(message: 'lively'));
        await tester.pumpAndSettle(const Duration(milliseconds: 16));
        expect(most, greaterThan(1.0));
      },
    );
  }

  testWidgets('with a screen reader an action toast stays until acted on', (
    tester,
  ) async {
    var undone = 0;
    await tester.pumpWidget(_app(accessibleNavigation: true));
    final undo = _toaster.show(
      RawToast(
        message: 'Deleted',
        actionLabel: 'Undo',
        onAction: () => undone++,
      ),
    );
    final plain = _toaster.show(const RawToast(message: 'Saved'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();
    expect(await plain.closed, RawToastClosedReason.timeout);
    expect(find.text('Deleted'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    expect(undone, 1);
    expect(await undo.closed, RawToastClosedReason.action);
    await tester.pumpAndSettle();
    expect(find.text('Deleted'), findsNothing);
  });

  testWidgets('a focused action that leaves the tree holds no toast: clay '
      "r3's toasts that stacked for good under the web's semantics", (
    tester,
  ) async {
    // The web's semantics focus the key a click lands on; Flutter tells the
    // parts above a focused node that leaves the tree nothing, so the stack
    // kept itself focused and every later toast waited.
    final focused = <String, bool>{};
    Widget paint(BuildContext context, RawToastDetails details) {
      focused[details.toast.message] = details.focused;
      return _paint(context, details);
    }

    await tester.pumpWidget(
      _app(accessibleNavigation: true, toastBuilder: paint),
    );
    final saved = _toaster.show(const RawToast(message: 'Saved'));
    _toaster.show(
      RawToast(
        id: 'book',
        message: 'Deleted',
        actionLabel: 'Undo',
        onAction: () {},
      ),
    );
    await tester.pumpAndSettle();
    Focus.of(tester.element(find.text('Undo'))).requestFocus();
    await tester.pump();
    await tester.pump();
    expect(_toaster.paused, isTrue, reason: 'focus in a toast pauses it');
    expect(focused['Deleted'], isTrue);
    await tester.pump(const Duration(seconds: 10));
    expect(find.text('Saved'), findsOneWidget, reason: 'paused with it');

    // The key leaves while focused: the toast, replaced in place, has none.
    final restored = _toaster.show(
      const RawToast(id: 'book', message: 'Restored'),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('Undo'), findsNothing);
    expect(_toaster.paused, isFalse);
    expect(focused['Restored'], isFalse);
    final added = _toaster.show(const RawToast(message: 'Added'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    // Each left after its time: none of them waits for good.
    for (final message in ['Saved', 'Restored', 'Added']) {
      expect(find.text(message), findsNothing, reason: message);
    }
    expect(await saved.closed, RawToastClosedReason.timeout);
    expect(await restored.closed, RawToastClosedReason.timeout);
    expect(await added.closed, RawToastClosedReason.timeout);
  });

  testWidgets('a toast with a shown id replaces it in place', (tester) async {
    await tester.pumpWidget(_app());
    final first = _toaster.show(
      const RawToast(message: 'Uploading', id: 'upload', duration: null),
    );
    await tester.pumpAndSettle();
    final second = _toaster.show(
      const RawToast(message: 'Uploaded', id: 'upload'),
    );
    await tester.pump();
    expect(first.id, second.id);
    expect(_toaster.shownCount, 1);
    expect(find.text('Uploading'), findsNothing);
    expect(find.text('Uploaded'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    expect(await first.closed, RawToastClosedReason.timeout);
  });

  testWidgets('a swipe dismisses it', (tester) async {
    await tester.pumpWidget(_app());
    final handle = _toaster.show(const RawToast(message: 'swipe me'));
    await tester.pumpAndSettle();
    await tester.fling(find.text('swipe me'), const Offset(300, 0), 1000);
    await tester.pumpAndSettle();
    expect(await handle.closed, RawToastClosedReason.swiped);
    expect(find.text('swipe me'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a swiped toast leaves through the look\'s exit: its '
      'animation goes to 0 as its slot closes, and the one below moves up '
      'with it, frame by frame', (tester) async {
    final seen = <String, RawToastDetails>{};
    // A look that sizes each toast by its animation.
    Widget sized(BuildContext context, RawToastDetails details) {
      seen[details.toast.message] = details;
      return SizeTransition(
        sizeFactor: details.animation.drive(Tween(begin: 0.0, end: 1.0)),
        child: SizedBox(height: 60, child: Text(details.toast.message)),
      );
    }

    await tester.pumpWidget(
      _app(alignment: AlignmentDirectional.topCenter, toastBuilder: sized),
    );
    final handle = _toaster.show(const RawToast(message: 'first'));
    _toaster.show(const RawToast(message: 'second'));
    await tester.pumpAndSettle();
    double top() => tester.getTopLeft(find.text('second')).dy;
    final before = top();
    await tester.fling(find.text('first'), const Offset(300, 0), 1000);
    // The swipe carries it out; then its slot closes.
    final tops = <double>[];
    var mid = false;
    // (Its own face is gone once the swipe has carried it out.)
    for (var i = 0; i < 40 && _toaster.shownCount == 2; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      final d = seen['first']!;
      if (d.exiting && d.animation.value > 0 && d.animation.value < 1) {
        mid = true;
      }
      tops.add(top());
    }
    expect(mid, isTrue, reason: 'its animation went part way to 0');
    expect(await handle.closed, RawToastClosedReason.swiped);
    await tester.pumpAndSettle();
    expect(find.text('first'), findsNothing);
    expect(top(), before - 60);
    final steps = [for (var i = 1; i < tops.length; i++) tops[i - 1] - tops[i]];
    expect(steps, everyElement(inInclusiveRange(-0.01, 20)), reason: '$tops');
    expect(
      steps.where((s) => s > 0.5).length,
      greaterThan(3),
      reason: 'it moved up over frames: $tops',
    );
  });

  testWidgets('a screen reader hears it live and can dismiss it', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_app());
    final handle = _toaster.show(const RawToast(message: 'Heard'));
    await tester.pumpAndSettle();
    final node = tester.getSemantics(find.byKey(const ValueKey('toast-Heard')));
    expect(node, isSemantics(isLiveRegion: true, hasDismissAction: true));
    semanticsOwner().performAction(node.id, SemanticsAction.dismiss);
    expect(await handle.closed, RawToastClosedReason.dismissed);
    semantics.dispose();
  });

  testWidgets('right to left at 200% text: it sits at the start and fits', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        textDirection: TextDirection.rtl,
        textScale: 2,
        alignment: AlignmentDirectional.bottomStart,
      ),
    );
    _toaster.show(
      const RawToast(
        message:
            'A long message that wraps over several lines at twice the '
            'size, and still fits',
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final box = tester.getRect(
      find.byKey(
        const ValueKey(
          'toast-A long message that wraps over several lines at twice the size, '
          'and still fits',
        ),
      ),
    );
    final width = tester.view.physicalSize.width / tester.view.devicePixelRatio;
    expect(box.right, greaterThan(width - 20));
  });
}

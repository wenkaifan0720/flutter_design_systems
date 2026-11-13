import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_contract.dart';
import 'behaviour_harness.dart';

// The bare reference painter: the message, and the action as a pressable.
Widget _paint(BuildContext context, DesignToastDetails details) => Container(
  key: ValueKey('toast-${details.toast.message}'),
  color: const Color(0xFFEEEEEE),
  padding: const EdgeInsets.all(8),
  child: Row(
    children: [
      Expanded(child: Text(details.toast.message)),
      if (details.runAction != null)
        DesignPressable(
          onPressed: details.runAction,
          minimumSize: const Size(48, 48),
          builder: (context, states, _) => Text(details.toast.actionLabel!),
        ),
    ],
  ),
);

late DesignToasterState _toaster;

Widget _app({
  int maxVisible = 3,
  bool reduceMotion = false,
  bool accessibleNavigation = false,
  double dampingRatio = 1,
  TextDirection textDirection = TextDirection.ltr,
  double textScale = 1,
  AlignmentGeometry alignment = AlignmentDirectional.bottomCenter,
  Widget home = const SizedBox.expand(),
  DesignToastBuilder toastBuilder = _paint,
}) => harness(
  home,
  reduceMotion: reduceMotion,
  accessibleNavigation: accessibleNavigation,
  textDirection: textDirection,
  textScale: textScale,
  wrap: (context, navigator) => DesignToaster(
    maxVisible: maxVisible,
    dampingRatio: dampingRatio,
    alignment: alignment,
    constraints: const BoxConstraints(maxWidth: 300),
    toastBuilder: toastBuilder,
    child: Builder(
      builder: (context) {
        _toaster = DesignToaster.of(context);
        return navigator!;
      },
    ),
  ),
);

void main() {
  var undone = 0;
  final page = FocusNode(debugLabel: 'page');
  tearDownAll(page.dispose);
  behaviourContract(
    'DesignToaster',
    build: (c) => DesignToaster(
      toastBuilder: _paint,
      constraints: const BoxConstraints(maxWidth: 300),
      child: Builder(
        builder: (context) {
          _toaster = DesignToaster.of(context);
          return Focus(focusNode: page, child: plainFace('page'));
        },
      ),
    ),
    open: (tester) async => _toaster.show(
      DesignToast(
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
        'DesignToast',
        reason: 'F6 jumps to the newest toast',
      );
      await p.key(LogicalKeyboardKey.escape);
      expect(p.node, findsNothing, reason: 'Escape dismisses it');
      expect(page.hasPrimaryFocus, isTrue, reason: 'focus goes back');
    },
    motion: (p) async {
      _toaster.show(const DesignToast(message: 'More', duration: null));
      await p.tester.pump();
    },
  );

  testWidgets('more than maxVisible wait their turn, in order', (tester) async {
    await tester.pumpWidget(_app(maxVisible: 2));
    final a = _toaster.show(const DesignToast(message: 'a'));
    final b = _toaster.show(
      const DesignToast(message: 'b', duration: Duration(seconds: 8)),
    );
    final c = _toaster.show(const DesignToast(message: 'c'));
    await tester.pump();
    expect(find.text('a'), findsOneWidget);
    expect(find.text('b'), findsOneWidget);
    expect(find.text('c'), findsNothing);
    expect(_toaster.waitingCount, 1);

    await tester.pump(const Duration(seconds: 4));
    expect(await a.closed, DesignToastClosedReason.timeout);
    await tester.pumpAndSettle();
    expect(find.text('a'), findsNothing);
    expect(find.text('c'), findsOneWidget);
    expect(_toaster.waitingCount, 0);

    // c's own four seconds start when it shows, not when it was queued.
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('c'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(await b.closed, DesignToastClosedReason.timeout);
    expect(await c.closed, DesignToastClosedReason.timeout);
    expect(find.text('c'), findsNothing);
  });

  testWidgets('a pointer over the stack pauses its time', (tester) async {
    await tester.pumpWidget(_app());
    final handle = _toaster.show(const DesignToast(message: 'hover'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    var closed = false;
    handle.closed.then((_) => closed = true);

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
    _toaster.show(const DesignToast(message: 'older'));
    final newest = _toaster.show(const DesignToast(message: 'newest'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    await tester.sendKeyEvent(LogicalKeyboardKey.f6);
    await tester.pump();
    expect(field.hasFocus, isFalse);
    expect(_toaster.paused, isTrue);
    await tester.pump(const Duration(seconds: 30));
    expect(find.text('newest'), findsOneWidget);
    expect(find.text('older'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(await newest.closed, DesignToastClosedReason.dismissed);
    expect(field.hasPrimaryFocus, isTrue);
    await tester.pumpAndSettle();
    expect(find.text('newest'), findsNothing);
    expect(_toaster.paused, isFalse);
  });

  testWidgets('Reduce Motion neither shortens the time nor bounces', (
    tester,
  ) async {
    debugSemanticsDisableAnimations = true;
    addTearDown(() => debugSemanticsDisableAnimations = null);
    var most = 0.0;
    Widget watch(BuildContext context, DesignToastDetails details) =>
        AnimatedBuilder(
          animation: details.animation,
          builder: (context, _) {
            if (details.animation.value > most) most = details.animation.value;
            return _paint(context, details);
          },
        );
    await tester.pumpWidget(
      _app(reduceMotion: true, dampingRatio: 0.4, toastBuilder: watch),
    );
    _toaster.show(const DesignToast(message: 'calm'));
    await tester.pumpAndSettle(const Duration(milliseconds: 16));
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('calm'), findsOneWidget);
    expect(most, lessThanOrEqualTo(1.0));

    // Without Reduce Motion the same spring overshoots.
    debugSemanticsDisableAnimations = null;
    most = 0;
    await tester.pumpWidget(_app(dampingRatio: 0.4, toastBuilder: watch));
    _toaster.show(const DesignToast(message: 'lively'));
    await tester.pumpAndSettle(const Duration(milliseconds: 16));
    expect(most, greaterThan(1.0));
  });

  testWidgets('with a screen reader an action toast stays until acted on', (
    tester,
  ) async {
    var undone = 0;
    await tester.pumpWidget(_app(accessibleNavigation: true));
    final undo = _toaster.show(
      DesignToast(
        message: 'Deleted',
        actionLabel: 'Undo',
        onAction: () => undone++,
      ),
    );
    final plain = _toaster.show(const DesignToast(message: 'Saved'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();
    expect(await plain.closed, DesignToastClosedReason.timeout);
    expect(find.text('Deleted'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    expect(undone, 1);
    expect(await undo.closed, DesignToastClosedReason.action);
    await tester.pumpAndSettle();
    expect(find.text('Deleted'), findsNothing);
  });

  testWidgets('a toast with a shown id replaces it in place', (tester) async {
    await tester.pumpWidget(_app());
    final first = _toaster.show(
      const DesignToast(message: 'Uploading', id: 'upload', duration: null),
    );
    await tester.pumpAndSettle();
    final second = _toaster.show(
      const DesignToast(message: 'Uploaded', id: 'upload'),
    );
    await tester.pump();
    expect(first.id, second.id);
    expect(_toaster.shownCount, 1);
    expect(find.text('Uploading'), findsNothing);
    expect(find.text('Uploaded'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    expect(await first.closed, DesignToastClosedReason.timeout);
  });

  testWidgets('a swipe dismisses it', (tester) async {
    await tester.pumpWidget(_app());
    final handle = _toaster.show(const DesignToast(message: 'swipe me'));
    await tester.pumpAndSettle();
    await tester.fling(find.text('swipe me'), const Offset(300, 0), 1000);
    await tester.pumpAndSettle();
    expect(await handle.closed, DesignToastClosedReason.swiped);
    expect(find.text('swipe me'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a swiped toast leaves through the look\'s exit: its '
      'animation goes to 0 as its slot closes, and the one below moves up '
      'with it, frame by frame', (tester) async {
    final seen = <String, DesignToastDetails>{};
    // A look that sizes each toast by its animation.
    Widget sized(BuildContext context, DesignToastDetails details) {
      seen[details.toast.message] = details;
      return SizeTransition(
        sizeFactor: details.animation.drive(Tween(begin: 0.0, end: 1.0)),
        child: SizedBox(height: 60, child: Text(details.toast.message)),
      );
    }

    await tester.pumpWidget(
      _app(alignment: AlignmentDirectional.topCenter, toastBuilder: sized),
    );
    final handle = _toaster.show(const DesignToast(message: 'first'));
    _toaster.show(const DesignToast(message: 'second'));
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
    expect(await handle.closed, DesignToastClosedReason.swiped);
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
    final handle = _toaster.show(const DesignToast(message: 'Heard'));
    await tester.pumpAndSettle();
    final node = tester.getSemantics(find.byKey(const ValueKey('toast-Heard')));
    expect(node, isSemantics(isLiveRegion: true, hasDismissAction: true));
    semanticsOwner().performAction(node.id, SemanticsAction.dismiss);
    expect(await handle.closed, DesignToastClosedReason.dismissed);
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
      const DesignToast(
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

// A toast's time under a pointer and a screen reader: a pointer resting
// where a toast rises (the Save key the reader just pressed, at the foot)
// does not hold it, as Radix's toast viewport pauses on a pointer's move,
// not on a toast appearing under it; a pointer moved onto the stack pauses
// it and moving off resumes it. With a screen reader on (as the web's
// semantics turn on), a toast without an action still leaves after its
// time; only one with an action stays, as Material's SnackBar does.
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_harness.dart';

final GlobalKey<RawToasterState> _toaster = GlobalKey();

Future<void> _pump(WidgetTester tester, {bool reader = false}) async {
  tester.view.physicalSize = const Size(400, 600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    harness(
      const Align(alignment: Alignment.bottomLeft, child: Text('Save')),
      accessibleNavigation: reader,
      wrap: (context, navigator) => RawToaster(
        key: _toaster,
        padding: EdgeInsets.zero,
        toastBuilder: (context, details) => SizedBox(
          width: 400,
          height: 60,
          child: Text(details.toast.message),
        ),
        child: navigator!,
      ),
    ),
  );
}

void main() {
  testWidgets('a toast rising under a resting pointer runs its time', (
    tester,
  ) async {
    await _pump(tester);
    // The pointer rests on the Save key, where the toast will rise.
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(20, 590));
    addTearDown(mouse.removePointer);
    await tester.pump();
    _toaster.currentState!.show(
      const RawToast(message: 'Added', duration: Duration(seconds: 3)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Added'), findsOneWidget);
    expect(_toaster.currentState!.paused, isFalse, reason: 'not hovered');
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.text('Added'), findsNothing);
  });

  testWidgets('a pointer moved onto the stack pauses it; moving off resumes', (
    tester,
  ) async {
    await _pump(tester);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(200, 100));
    addTearDown(mouse.removePointer);
    _toaster.currentState!.show(
      const RawToast(message: 'Added', duration: Duration(seconds: 3)),
    );
    await tester.pumpAndSettle();
    await mouse.moveTo(const Offset(200, 570));
    await tester.pump();
    expect(_toaster.currentState!.paused, isTrue);
    await tester.pump(const Duration(seconds: 5));
    expect(find.text('Added'), findsOneWidget, reason: 'held while hovered');
    await mouse.moveTo(const Offset(200, 100));
    await tester.pump();
    expect(_toaster.currentState!.paused, isFalse);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.text('Added'), findsNothing);
  });

  testWidgets('with a screen reader on, only a toast with an action stays', (
    tester,
  ) async {
    await _pump(tester, reader: true);
    _toaster.currentState!.show(
      const RawToast(message: 'Added', duration: Duration(seconds: 3)),
    );
    _toaster.currentState!.show(
      RawToast(
        message: 'Archived',
        actionLabel: 'Undo',
        onAction: () {},
        duration: const Duration(seconds: 3),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.text('Added'), findsNothing, reason: 'no action: it leaves');
    expect(find.text('Archived'), findsOneWidget, reason: 'an action stays');
  });
}

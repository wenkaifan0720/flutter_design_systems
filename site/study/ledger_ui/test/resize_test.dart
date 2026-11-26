import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stint_ledger/stint_ledger.dart';
import 'package:stint_core/stint_core.dart';

// A window that widens and narrows again comes to rest: no part keeps asking
// for frames (a layout that flips each frame, an animation that never ends).
void main() {
  for (final (name, launch) in const [
    ('Today', StintLaunch(place: Place.today)),
    ('Tasks with a task open', StintLaunch(place: Place.tasks, detail: true)),
    ('Time', StintLaunch(place: Place.time)),
    ('Settings', StintLaunch(place: Place.settings)),
  ]) {
    testWidgets('$name comes to rest at 390, 1440 and 390 again', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.physicalSize = const Size(390, 900);
      await tester.pumpWidget(
        StintLedger(launch: launch, repository: StintRepository()),
      );
      for (final width in [390.0, 1440.0, 390.0]) {
        tester.view.physicalSize = Size(width, 900);
        await tester.pumpAndSettle(
          const Duration(milliseconds: 100),
          EnginePhase.sendSemanticsUpdate,
          const Duration(seconds: 30),
        );
        expect(tester.binding.hasScheduledFrame, isFalse, reason: 'at $width');
      }
    });
  }
}

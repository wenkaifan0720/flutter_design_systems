// A press on a range fader's track takes the keyboard's focus on the cap it
// moves (ui_core 0.8.8's range slider), as Material's slider does, so the
// arrows after a press move that cap, not the control focused before it.
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:studio_ui/studio_ui.dart';

void main() {
  testWidgets('a press on the track focuses the cap it moves', (tester) async {
    var values = const StudioRangeValues(10, 40);
    final before = FocusNode();
    addTearDown(before.dispose);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, app) =>
            StudioHost(brightness: Brightness.light, child: app!),
        home: Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: 320,
              child: StatefulBuilder(
                builder: (context, setState) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Focus(
                      focusNode: before,
                      child: const SizedBox(width: 20, height: 20),
                    ),
                    StudioRangeFader(
                      values: values,
                      max: 60,
                      divisions: 60,
                      startLabel: 'Shortest',
                      endLabel: 'Longest',
                      onChanged: (v) => setState(() => values = v),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    before.requestFocus();
    await tester.pumpAndSettle();
    expect(before.hasFocus, isTrue);

    final track = tester.getRect(find.byType(StudioRangeFader));
    await tester.tapAt(Offset(track.left + track.width * 0.9, track.center.dy));
    await tester.pumpAndSettle();
    expect(before.hasFocus, isFalse);
    final pressed = values.end;
    expect(pressed, greaterThan(40));

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(values.end, pressed + 1);
    expect(values.start, 10);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));
}

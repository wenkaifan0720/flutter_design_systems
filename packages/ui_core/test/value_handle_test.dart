// RawValueHandle's states: a caller's WidgetStatesController watches and
// drives them, and a drag adds dragged beside pressed, as Flutter's Slider
// and Scrollbar do.
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_harness.dart';

Set<WidgetState>? _built;

Widget _handle({
  WidgetStatesController? controller,
  bool dragging = false,
  bool enabled = true,
}) => harness(
  Center(
    child: RawValueHandle(
      value: 0.5,
      onChanged: enabled ? (_) {} : null,
      dragging: dragging,
      semanticLabel: 'Volume',
      statesController: controller,
      builder: (context, states) {
        _built = states;
        return const SizedBox(width: 20, height: 20);
      },
    ),
  ),
);

// A handle on a track of the look's own beside a radio holding the focus:
// the look's press on the track drags it ([dragging]).
Widget _beside(FocusNode other, {bool dragging = false}) => harness(
  Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Focus(
        focusNode: other,
        autofocus: true,
        child: const SizedBox(width: 10, height: 10),
      ),
      StatefulBuilder(
        builder: (context, setState) => RawValueHandle(
          value: _value,
          onChanged: (v) => setState(() => _value = v),
          dragging: dragging,
          semanticLabel: 'Grain',
          builder: (context, states) {
            _built = states;
            return const SizedBox(
              key: ValueKey('thumb'),
              width: 20,
              height: 20,
            );
          },
        ),
      ),
    ],
  ),
);

double _value = 0.5;

void main() {
  testWidgets('a press on it takes the focus, unshown, so the arrows after '
      'it move it, not the radio focused before (studio r3)', (tester) async {
    _value = 0.5;
    final other = FocusNode(debugLabel: 'radio');
    addTearDown(other.dispose);
    await tester.pumpWidget(_beside(other));
    await tester.pump();
    expect(other.hasPrimaryFocus, isTrue);
    await tester.tap(
      find.byKey(const ValueKey('thumb')),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pump();
    expect(other.hasFocus, isFalse);
    expect(
      _built,
      isNot(contains(WidgetState.focused)),
      reason: "a pointer's press shows no ring",
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(_value, greaterThan(0.5));
  });

  testWidgets("a look's press on its track, dragging it, takes the focus too", (
    tester,
  ) async {
    _value = 0.5;
    final other = FocusNode(debugLabel: 'radio');
    addTearDown(other.dispose);
    await tester.pumpWidget(_beside(other));
    await tester.pump();
    await tester.pumpWidget(_beside(other, dragging: true));
    await tester.pump();
    expect(other.hasFocus, isFalse);
    await tester.pumpWidget(_beside(other));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(_value, lessThan(0.5));
  });

  testWidgets('a caller\'s controller holds the states the face is built '
      'for: hovered, dragged and pressed, disabled', (tester) async {
    final controller = WidgetStatesController();
    addTearDown(controller.dispose);
    final told = <Set<WidgetState>>[];
    controller.addListener(() => told.add(Set.of(controller.value)));
    await tester.pumpWidget(_handle(controller: controller));
    expect(controller.value, isEmpty);

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: tester.getCenter(find.byType(SizedBox)));
    addTearDown(mouse.removePointer);
    await tester.pump();
    expect(controller.value, {WidgetState.hovered});
    expect(_built, {WidgetState.hovered});

    // A drag starts with a press, which takes the focus unshown.
    await mouse.down(tester.getCenter(find.byType(SizedBox)));
    await tester.pumpWidget(_handle(controller: controller, dragging: true));
    expect(_built, {
      WidgetState.hovered,
      WidgetState.pressed,
      WidgetState.dragged,
    });
    await tester.pump();
    expect(told.last, _built, reason: 'told once the frame is built');

    await mouse.up();
    await tester.pumpWidget(_handle(controller: controller));
    expect(_built, {WidgetState.hovered});

    await tester.pumpWidget(_handle(controller: controller, enabled: false));
    expect(_built, {WidgetState.disabled});
    await tester.pumpWidget(_handle(controller: controller));
    expect(_built, {WidgetState.hovered}, reason: 'still under the pointer');
  });

  testWidgets('a state the caller drives shows on the face', (tester) async {
    final controller = WidgetStatesController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_handle(controller: controller));
    controller.update(WidgetState.selected, true);
    await tester.pump();
    expect(_built, {WidgetState.selected});
  });

  testWidgets('with no controller a drag still adds dragged beside pressed', (
    tester,
  ) async {
    await tester.pumpWidget(_handle(dragging: true));
    expect(_built, {WidgetState.pressed, WidgetState.dragged});
    await tester.pumpWidget(_handle());
    expect(_built, isEmpty);
  });
}

// DesignValueHandle's states: a caller's WidgetStatesController watches and
// drives them, and a drag adds dragged beside pressed, as Flutter's Slider
// and Scrollbar do.
import 'package:flutter/gestures.dart';
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
    child: DesignValueHandle(
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

void main() {
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

    await tester.pumpWidget(_handle(controller: controller, dragging: true));
    expect(_built, {
      WidgetState.hovered,
      WidgetState.pressed,
      WidgetState.dragged,
    });
    await tester.pump();
    expect(told.last, _built, reason: 'told once the frame is built');

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

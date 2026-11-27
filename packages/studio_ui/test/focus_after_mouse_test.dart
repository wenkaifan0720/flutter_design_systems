// A Tab shows a fader's or a knob's focus after a mouse that came before any
// other input (a trackpad on an iPad, a mouse on Android), and a click leaves
// no ring: both take ui_core's focus (RawFocusShown on the focus itself), not
// the detector's highlight, which such a mouse leaves stale and a click lights.
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_ui/studio_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

final _shot = GlobalKey();

Future<Uint8List> _pixels(WidgetTester tester) async {
  final boundary =
      _shot.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  return (await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    return data!.buffer.asUint8List();
  }))!;
}

// The part alone, and a mouse that connects before any other input (a
// trackpad on an iPad, a mouse on Android), away from the part.
Future<TestGesture> _show(WidgetTester tester, Widget part) async {
  await tester.pumpWidget(
    RepaintBoundary(
      key: _shot,
      child: MaterialApp(
        builder: (context, app) =>
            StudioHost(brightness: Brightness.light, child: app!),
        home: Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(width: 320, child: part),
          ),
        ),
      ),
    ),
  );
  final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await mouse.addPointer(location: const Offset(700, 500));
  addTearDown(mouse.removePointer);
  await tester.pumpAndSettle();
  return mouse;
}

final _touch = TargetPlatformVariant.only(TargetPlatform.android);

void main() {
  final parts = <String, Widget Function()>{
    'fader': () => StudioFader(value: 0.5, onChanged: (_) {}),
    'knob': () => Align(
      alignment: Alignment.topLeft,
      child: StudioKnob(value: 0.5, onChanged: (_) {}),
    ),
  };
  for (final MapEntry(key: name, value: part) in parts.entries) {
    testWidgets('a Tab after a mouse shows the $name\'s focus', (tester) async {
      await _show(tester, part());
      final rest = await _pixels(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(FocusManager.instance.primaryFocus?.context, isNotNull);
      expect(listEquals(rest, await _pixels(tester)), isFalse);
    }, variant: _touch);
  }

  testWidgets("a click leaves no ring on a knob", (tester) async {
    final mouse = await _show(
      tester,
      Align(
        alignment: Alignment.topLeft,
        child: StudioKnob(value: 0.5, onChanged: (_) {}),
      ),
    );
    final rest = await _pixels(tester);
    await mouse.moveTo(tester.getCenter(find.byType(StudioKnob)));
    await mouse.down(tester.getCenter(find.byType(StudioKnob)));
    await tester.pump(const Duration(milliseconds: 50));
    await mouse.up();
    await mouse.moveTo(const Offset(700, 500));
    await tester.pumpAndSettle();
    expect(listEquals(rest, await _pixels(tester)), isTrue);
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));
}

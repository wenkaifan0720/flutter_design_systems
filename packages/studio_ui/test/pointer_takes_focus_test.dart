// A fader and a knob take the keyboard's focus when a pointer goes down on
// them, as Material's slider does, so the arrow keys move the one just
// touched; the ring stays dark until a key is pressed.
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

Future<void> _show(WidgetTester tester, Widget part) async {
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
  await tester.pumpAndSettle();
}

void main() {
  final parts = <String, (Type, Widget Function(FocusNode?))>{
    'fader': (
      StudioFader,
      (node) => StudioFader(value: 0.5, focusNode: node, onChanged: (_) {}),
    ),
    'knob': (
      StudioKnob,
      (node) => Align(
        alignment: Alignment.topLeft,
        child: StudioKnob(value: 0.5, focusNode: node, onChanged: (_) {}),
      ),
    ),
  };
  for (final MapEntry(key: name, value: (type, part)) in parts.entries) {
    testWidgets("a click takes the $name's focus, the ring after a key", (
      tester,
    ) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await _show(tester, part(node));
      final rest = await _pixels(tester);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      final centre = tester.getCenter(find.byType(type));
      await mouse.addPointer(location: centre);
      await mouse.down(centre);
      await tester.pump();
      expect(node.hasFocus, isTrue);
      await mouse.up();
      await mouse.moveTo(const Offset(700, 500));
      await tester.pumpAndSettle();
      expect(node.hasFocus, isTrue);
      expect(listEquals(rest, await _pixels(tester)), isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle();
      expect(listEquals(rest, await _pixels(tester)), isFalse);
    }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

    testWidgets("a finger takes the $name's focus without its own node", (
      tester,
    ) async {
      await _show(tester, part(null));
      await tester.tap(find.byType(type));
      await tester.pumpAndSettle();
      final focus = FocusManager.instance.primaryFocus?.context;
      expect(focus, isNotNull);
      expect(
        find.descendant(
          of: find.byType(type),
          matching: find.byWidget(focus!.widget),
        ),
        findsOneWidget,
      );
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));
  }
}

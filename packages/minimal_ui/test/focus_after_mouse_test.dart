// A Tab shows a part's focus after a mouse that came before any other input
// (a trackpad on an iPad, a mouse on Android): each part takes ui_core's
// focus (RawFocusShown on the focus itself), not the detector's highlight,
// which such a mouse leaves stale.
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
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
            MinimalHost(brightness: Brightness.light, child: app!),
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
    'button': () => MinimalButton('Save', onPressed: () {}),
    'segmented button': () => MinimalSegmentedButton<int>(
      segments: const [
        MinimalButtonSegment(0, 'Day'),
        MinimalButtonSegment(1, 'Week'),
      ],
      value: 0,
      onChanged: (_) {},
    ),
    'slider': () =>
        MinimalSlider(label: 'Volume', value: 0.5, onChanged: (_) {}),
    'pagination': () =>
        MinimalPagination(page: 1, pageCount: 5, onPageChanged: (_) {}),
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
}

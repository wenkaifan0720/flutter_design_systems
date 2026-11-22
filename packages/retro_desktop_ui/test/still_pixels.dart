// A part pumped alone on the machine's grey, in an appearance and a time of day, and read back as pixels: settled, or
// idle and then held under the pointer.
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart' show kPressTimeout;
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

Future<Uint8List> _pixels(WidgetTester tester, GlobalKey key) async {
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  return (await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    return data!.buffer.asUint8List();
  }))!;
}

Future<GlobalKey> _host(
  WidgetTester tester,
  RetroDesktopAppearance appearance,
  Brightness brightness,
  Widget child,
) async {
  tester.view.physicalSize = const Size(700, 500);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final key = GlobalKey();
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, app) => RetroDesktopTheme(
        data: RetroDesktopThemeData.classic(brightness)
            .copyWith(appearance: appearance),
        child: app!,
      ),
      home: Builder(
        builder: (context) => ColoredBox(
          color: RetroDesktopTheme.of(context).colors.platinum,
          child: Align(
            alignment: Alignment.topLeft,
            child: RepaintBoundary(
              key: key,
              child: ColoredBox(
                color: RetroDesktopTheme.of(context).colors.platinum,
                child: Padding(padding: const EdgeInsets.all(12), child: child),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return key;
}

/// The pixels of [child] idle, and while the pointer holds its first press
/// (a pressable, or a radio).
Future<(Uint8List, Uint8List, Size, Size)> idleAndHeldPixels(
  WidgetTester tester,
  RetroDesktopAppearance appearance,
  Brightness brightness,
  Widget child,
) async {
  final key = await _host(tester, appearance, brightness, child);
  final idle = await _pixels(tester, key);
  final idleSize = tester.getSize(find.byKey(key));
  final down = await tester.startGesture(
    tester.getCenter(
      find
          .byWidgetPredicate((w) => w is RetroDesktopPressable || w is RawRadio)
          .first,
    ),
  );
  await tester.pump(kPressTimeout);
  await tester.pump(const Duration(milliseconds: 100));
  final held = await _pixels(tester, key);
  final heldSize = tester.getSize(find.byKey(key));
  await down.cancel();
  await tester.pumpAndSettle();
  return (idle, held, idleSize, heldSize);
}

/// The pixels and size of [child], settled.
Future<(Uint8List, Size)> stillPixels(
  WidgetTester tester,
  RetroDesktopAppearance appearance,
  Brightness brightness,
  Widget child,
) async {
  final key = await _host(tester, appearance, brightness, child);
  return (await _pixels(tester, key), tester.getSize(find.byKey(key)));
}

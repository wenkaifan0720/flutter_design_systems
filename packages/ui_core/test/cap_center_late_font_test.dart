// A label's font arriving after its first layout, as fonts load on the web:
// DesignCapCenter over a text entry with a hint lays out and paints again
// with the new font's metrics, its capitals on the middle.
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

const _black = Color(0xFF000000);
const _late = 'LateFace';

Future<void> _loadLate() async {
  final root =
      Platform.environment['FLUTTER_ROOT'] ??
      File(Platform.resolvedExecutable)
          .parent
          .parent
          .parent
          .parent
          .parent
          .parent
          .path;
  final bytes = File(
    '$root/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf',
  ).readAsBytesSync();
  await (FontLoader(
    _late,
  )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
}

// The entry: a hint while [controller] is empty, under a cap centre.
Widget _entry(TextEditingController controller, FocusNode focus) {
  const style = TextStyle(fontFamily: _late, fontSize: 20, color: _black);
  return MediaQuery(
    data: const MediaQueryData(),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: SizedBox(
          width: 240,
          height: 48,
          child: DesignCapCenter(
            capHeightFactor: 0.7,
            child: DesignTextEntryBox(
              minHeight: 48,
              controller: controller,
              hint: const Text('Search', style: style),
              child: EditableText(
                controller: controller,
                focusNode: focus,
                style: style,
                cursorColor: _black,
                backgroundCursorColor: _black,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

// How far the cap centre moves its label down.
double _shift(WidgetTester tester) {
  final cap = tester.renderObject<RenderDesignCapCenter>(
    find.byType(DesignCapCenter),
  );
  final m = Matrix4.identity();
  cap.applyPaintTransform(cap.child!, m);
  return m.getTranslation().y;
}

void main() {
  testWidgets("a text entry with a hint whose font arrives after its first "
      'layout paints on without an assertion, its capitals on the middle '
      "once the engine says so, as a fresh one's", (tester) async {
    final controller = TextEditingController();
    final focus = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focus.dispose);
    await tester.pumpWidget(_entry(controller, focus));
    expect(tester.takeException(), isNull);
    final early = _shift(tester);
    // The font is in the engine; a frame paints before it says so.
    await tester.runAsync(_loadLate);
    tester.binding.scheduleFrame();
    await tester.pump();
    expect(tester.takeException(), isNull);
    // The engine's word, as the web sends it once a font has loaded.
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      SystemChannels.system.name,
      SystemChannels.system.codec.encodeMessage(<String, Object?>{
        'type': 'fontsChange',
      }),
      (_) {},
    );
    await tester.pump();
    await tester.pump();
    expect(tester.takeException(), isNull);
    final late = _shift(tester);
    expect(late, isNot(early), reason: 'the new font moves the line');
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(_entry(controller, focus));
    expect(late, moreOrLessEquals(_shift(tester)));
    // Typed text too.
    controller.text = 'Saturday';
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}

// A row's title takes its surface's ink, eased with the face as a pointer
// comes and goes, never switched in one frame.
// A latched icon key's glyph lights with the key, eased the same way.
import 'package:studio_ui/studio_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

Future<TestGesture> _show(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) =>
          StudioHost(brightness: Brightness.light, child: app!),
      home: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(width: 360, child: child),
      ),
    ),
  );
  final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await mouse.addPointer(location: const Offset(700, 500));
  addTearDown(mouse.removePointer);
  await tester.pumpAndSettle();
  return mouse;
}

// The colour at rest, a frame into the hover, and settled.
Future<(Color, Color, Color)> _hover(
  WidgetTester tester,
  TestGesture mouse,
  Finder target,
  Color Function() read,
) async {
  final rest = read();
  await mouse.moveTo(tester.getCenter(target));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 30));
  final mid = read();
  await tester.pumpAndSettle();
  return (rest, mid, read());
}

void main() {
  testWidgets("a row's title eases to its hover ink", (tester) async {
    final mouse = await _show(
      tester,
      StudioListTile(title: 'Booth', onTap: () {}),
    );
    Color ink() => tester
        .renderObject<RenderParagraph>(find.text('Booth'))
        .text
        .style!
        .color!;
    final (rest, mid, lit) = await _hover(
      tester,
      mouse,
      find.text('Booth'),
      ink,
    );
    expect(lit, isNot(rest));
    expect(mid, isNot(rest));
    expect(mid, isNot(lit));
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  testWidgets("a latched icon key's glyph eases to its light", (tester) async {
    final latched = ValueNotifier(false);
    addTearDown(latched.dispose);
    await _show(
      tester,
      Align(
        alignment: Alignment.topLeft,
        child: ValueListenableBuilder<bool>(
          valueListenable: latched,
          builder: (context, on, _) => StudioIconButton(
            icon: const Icon(IconData(0x41)),
            tooltip: 'Pin',
            selected: on,
            onPressed: () {},
          ),
        ),
      ),
    );
    Color glyph() => IconTheme.of(tester.element(find.byType(Icon))).color!;
    final rest = glyph();
    latched.value = true;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 30));
    final mid = glyph();
    await tester.pumpAndSettle();
    final lit = glyph();
    expect(lit, isNot(rest));
    expect(mid, isNot(rest));
    expect(mid, isNot(lit));
  });
}

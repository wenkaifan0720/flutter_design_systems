// The words beside a value (a text field's unit, an input group's
// add-on) read at one size and ink: the value's size in secondary ink, as
// Material's suffix text takes the input's style (they stood 14 and 16);
// and a unit stands on the value's line, to the pixel.
// GlossScaffold is deprecated (GlossAppShell replaces it); tested until 0.7.0 removes it.
// ignore_for_file: deprecated_member_use_from_same_package
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloss_ui/gloss_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

void main() {
  setUpAll(glossLoadFonts);

  for (final brightness in Brightness.values) {
    testWidgets('a unit reads as an add-on, $brightness', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          builder: (context, app) => GlossHost(
            theme: GlossThemeData.light(),
            darkTheme: GlossThemeData.dark(),
            brightness: brightness,
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: app!,
            ),
          ),
          home: const SingleChildScrollView(
            child: Column(
              children: [
                GlossTextField(labelText: 'Serves', suffix: Text('people')),
                GlossInputGroup(labelText: 'Weight', suffixText: 'g'),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      TextStyle style(String words) => tester
          .renderObject<RenderParagraph>(find.text(words).first)
          .text
          .style!;
      final unit = style('people'), addOn = style('g');
      expect(unit.fontSize, addOn.fontSize);
      expect(unit.color, addOn.color);
    });
  }

  for (final brightness in Brightness.values) {
    testWidgets('a unit stands on the value\'s line, $brightness', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(360, 200)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final controller = TextEditingController(text: 'HH');
      addTearDown(controller.dispose);
      final shot = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: shot,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            builder: (context, app) => GlossHost(
              theme: GlossThemeData.light(),
              darkTheme: GlossThemeData.dark(),
              brightness: brightness,
              child: app!,
            ),
            home: GlossScaffold(
              body: Padding(
                padding: const EdgeInsets.all(20),
                child: GlossTextField(
                  controller: controller,
                  suffix: const Text('HH'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final field = tester.getRect(find.byType(GlossTextField));
      final boundary =
          shot.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final bytes = (await tester.runAsync(() async {
        final image = await boundary.toImage();
        final data = await image.toByteData();
        image.dispose();
        return data!;
      }))!;
      final ground = brightness == Brightness.light;
      bool ink(int x, int y) {
        final i = (y * 360 + x) * 4;
        final v =
            (bytes.getUint8(i) +
                bytes.getUint8(i + 1) +
                bytes.getUint8(i + 2)) /
            3;
        return ground ? v < 150 : v > 120;
      }

      // The lowest row of ink under a span of the field: the capitals' foot.
      int foot(double from, double to) {
        var lowest = -1;
        for (var y = field.top.ceil() + 4; y < field.bottom.floor() - 4; y++) {
          for (var x = from.round(); x < to.round(); x++) {
            if (ink(x, y)) lowest = y;
          }
        }
        return lowest;
      }

      final value = foot(field.left + 8, field.left + field.width * 0.4);
      final unit = foot(field.right - field.width * 0.25, field.right - 8);
      expect(value, greaterThan(0));
      expect(unit, value);
    });
  }
}

// A time picker keeps hours before minutes, left to right, in either
// direction, as Material's time picker keeps them: in Arabic, right to left,
// the heading's hour stands left of its minutes ("٩:٠٥" is one run of
// figures), and the hours' keys stand above the minutes', at a phone's
// width and a desktop's, on either face.
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_host.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

Future<void> _pump(
  WidgetTester tester, {
  required Size size,
  required bool h24,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    WidgetsApp(
      color: const Color(0xFF000000),
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        NeumorphicLocalizations.delegate,
        RawWidgetsLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      builder: (context, _) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: h24),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: NeumorphicHost(
            brightness: Brightness.light,
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: size.width < 600 ? 358 : 800,
                  child: NeumorphicTimePicker(
                    value: const NeumorphicTime(9, 5),
                    onChanged: (_) {},
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Where [part] of [paragraph]'s words lies, left to right.
double _left(RenderParagraph paragraph, String part) {
  final text = paragraph.text.toPlainText();
  final at = text.indexOf(part);
  final boxes = paragraph.getBoxesForSelection(
    TextSelection(baseOffset: at, extentOffset: at + part.length),
  );
  return boxes.map((b) => b.left).reduce((a, b) => a < b ? a : b);
}

void main() {
  for (final size in const [Size(390, 844), Size(1440, 900)]) {
    for (final (h24, hour) in const [(false, '٩'), (true, '٠٩')]) {
      testWidgets('ar, ${h24 ? '24' : '12'}-hour, ${size.width.toInt()} '
          'wide, right to left: hours before minutes', (tester) async {
        await _pump(tester, size: size, h24: h24);
        final heading = tester.allRenderObjects
            .whereType<RenderParagraph>()
            .firstWhere((p) => p.text.toPlainText().startsWith('$hour:'));
        expect(_left(heading, hour), lessThan(_left(heading, '٠٥')));
        final words = NeumorphicLocalizations.of(
          tester.element(find.byType(NeumorphicTimePicker)),
        );
        expect(
          tester.getTopLeft(find.text(words.hour)).dy,
          lessThan(tester.getTopLeft(find.text(words.minute)).dy),
        );
      });
    }
  }
}

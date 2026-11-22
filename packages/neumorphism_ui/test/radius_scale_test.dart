// Radii stay on the look's scale (controls 8 to 12, a card 20 at most) unless the thing is an object drawn from its
// own size, and a page writes no radius of its own.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import 'flat_stage.dart';
import 'support.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadNeumorphicFonts();
  });

  group('radii', () {
    test('the scale: controls 8 to 12, a card 20 at most', () {
      expect(NeumorphicRadii.slab, lessThanOrEqualTo(24));
      expect(NeumorphicRadii.well, lessThanOrEqualTo(NeumorphicRadii.slab));
      expect(NeumorphicRadii.control, inInclusiveRange(8, 12));
      expect(NeumorphicRadii.chip, inInclusiveRange(8, 12));
      expect(NeumorphicRadii.cap, inInclusiveRange(8, 12));
    });

    test('no radius over the scale, unless it is drawn on an object', () {
      // An object's round end is drawn from its own size (w / 2, a thumb, a slot), not written as a number.
      final big = RegExp(
        r'(?:BorderRadius|Radius)\.circular\(\s*(\d+(?:\.\d+)?)',
      );
      final found = <String>[];
      for (final f in [...lookLibrary(), ...examplePages()]) {
        for (final m in big.allMatches(f.readAsStringSync())) {
          if (double.parse(m[1]!) > NeumorphicRadii.slab) {
            found.add('${f.path}: ${m[0]}');
          }
        }
      }
      expect(found, isEmpty);
    });

    test('a page holds no radius of its own', () {
      final found = <String>[];
      for (final f in examplePages()) {
        if (RegExp(r'BorderRadius|Radius\.').hasMatch(f.readAsStringSync())) {
          found.add(f.path);
        }
      }
      expect(found, isEmpty);
    });

    testWidgets('a word never stands in a bay window: words are under it', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1440, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        neumorphicApp(
          const SizedBox(
            width: 600,
            child: NeumorphicRelief(
              title: '1',
              courses: [
                NeumorphicCourse('A', [
                  NeumorphicBay(figure: '18°', name: 'A word', note: 'Another'),
                ]),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      final figure = tester.getRect(find.text('18°'));
      final window = tester
          .renderObjectList<RenderCustomPaint>(find.byType(CustomPaint))
          .where((b) => b.painter.runtimeType.toString() == '_WindowPainter')
          .single;
      final box = (window.localToGlobal(Offset.zero)) & window.size;
      expect(figure.top, greaterThanOrEqualTo(box.bottom - .5));
    });
  });
}

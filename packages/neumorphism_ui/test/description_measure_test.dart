// A description list on a wide page keeps each detail near its term: the list stands at a reading page's measure
// (760) at the start, its rules too; on a phone it takes the width it is given.

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import 'support.dart';

void main() {
  for (final direction in TextDirection.values) {
    for (final width in [340.0, 1100.0]) {
      testWidgets('details stay near their terms at $width ${direction.name}', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(1440, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          neumorphicApp(
            Directionality(
              textDirection: direction,
              child: Align(
                alignment: AlignmentDirectional.topStart,
                child: SizedBox(
                  key: const ValueKey('box'),
                  width: width,
                  child: const NeumorphicDescriptionList([
                    NeumorphicDescription('Author', 'George Eliot'),
                    NeumorphicDescription('Started', 'Not yet'),
                  ]),
                ),
              ),
            ),
          ),
        );
        final box = tester.getRect(find.byKey(const ValueKey('box')));
        final term = tester.getRect(find.text('Author'));
        final details = tester.getRect(find.text('George Eliot'));
        final rtl = direction == TextDirection.rtl;
        final span = rtl
            ? term.right - details.left
            : details.right - term.left;
        expect(
          span,
          lessThanOrEqualTo(760),
          reason: 'the detail near its term',
        );
        // It starts where the box starts.
        expect(
          rtl ? box.right - term.right : term.left - box.left,
          lessThan(1),
        );
        if (width < 760) {
          expect(
            rtl ? details.left - box.left : box.right - details.right,
            lessThan(1),
            reason: 'on a phone the details end at the side',
          );
        }
      });
    }
  }
}

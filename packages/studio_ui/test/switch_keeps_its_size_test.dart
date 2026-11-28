// A switch keeps its own size in a form's column, as Material's does: in a
// StudioFormField (which names it) it stands at the field's start, 52 by 28,
// and only the switch turns it, not the rest of the line.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_ui/studio_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

void main() {
  for (final direction in TextDirection.values) {
    testWidgets(
      'a labelled switch in a form keeps its size (${direction.name})',
      (tester) async {
        tester.view
          ..physicalSize = const Size(390, 800)
          ..devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        var on = true;
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => Directionality(
              textDirection: direction,
              child: StudioHost(child: child!),
            ),
            home: StudioScreen(
              body: StudioForm(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const StudioTextFormField(labelText: 'Title'),
                    StatefulBuilder(
                      builder: (context, setState) => StudioFormField(
                        labelText: 'Favourite',
                        child: StudioSwitch(
                          value: on,
                          onChanged: (value) => setState(() => on = value),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final paint = tester.getRect(
          find
              .descendant(
                of: find.byType(StudioSwitch),
                matching: find.byType(CustomPaint),
              )
              .last,
        );
        final title = tester.getRect(find.byType(StudioTextFormField));
        expect(paint.size, StudioSwitch.size);
        if (direction == TextDirection.ltr) {
          expect(paint.left, closeTo(title.left, 0.5));
        } else {
          expect(paint.right, closeTo(title.right, 0.5));
        }

        // The far end of the line is not the switch.
        final far = direction == TextDirection.ltr
            ? Offset(title.right - 8, paint.center.dy)
            : Offset(title.left + 8, paint.center.dy);
        await tester.tapAt(far);
        await tester.pumpAndSettle();
        expect(on, isTrue);
        await tester.tapAt(paint.center);
        await tester.pumpAndSettle();
        expect(on, isFalse);
      },
    );
  }
}

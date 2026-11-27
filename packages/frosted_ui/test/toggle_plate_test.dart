// A chosen toggle stands on the strip's chosen plate, the brightest glass on
// it, as a segmented button's choice does, by day and by night; the others
// show the strip.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';

final _plates = find.byWidgetPredicate(
  (w) => w.runtimeType.toString() == 'FrostedChosenPlate',
);

final _faces = find.byWidgetPredicate(
  (w) => w.runtimeType.toString() == 'FrostedFace',
);

void main() {
  for (final brightness in Brightness.values) {
    testWidgets(
      'a chosen toggle stands on the chosen plate (${brightness.name})',
      (t) async {
        await t.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            builder: (context, page) =>
                FrostedHost(brightness: brightness, child: page!),
            home: FrostedScaffold(
              body: Center(
                child: FrostedToggleGroup<String>(
                  semanticLabel: 'Alignment',
                  segments: const [
                    FrostedButtonSegment('left', 'Left'),
                    FrostedButtonSegment('centre', 'Centre'),
                    FrostedButtonSegment('right', 'Right'),
                  ],
                  selected: const {'left'},
                  onSelectionChanged: (_) {},
                ),
              ),
            ),
          ),
        );
        await t.pumpAndSettle();
        final shown = [
          for (final e in _plates.evaluate())
            if ((e.findAncestorWidgetOfExactType<AnimatedOpacity>()?.opacity ??
                    1) >
                0)
              t.getRect(find.byElementPredicate((x) => identical(x, e))),
        ];
        expect(shown, hasLength(1));
        expect(shown.single.contains(t.getCenter(find.text('Left'))), isTrue);
        // Nothing is painted over the plate: the words' own face is clear.
        final own = find.ancestor(
          of: find.text('Left'),
          matching: find.descendant(
            of: find.byType(FrostedToggleGroup<String>),
            matching: _faces,
          ),
        );
        expect(own, findsWidgets);
        for (final e in own.evaluate()) {
          final fill = e.widget.toDiagnosticsNode().getProperties().where(
            (p) => p.name == 'color',
          );
          expect(fill.single.value, isNull);
        }
      },
    );
  }
}

// A toned icon tile draws no rim.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

import 'support/scaled_page.dart';

/// The rim [decoration] paints, or null.
BorderSide? _rimOf(Decoration? decoration) => switch (decoration) {
  BoxDecoration(border: final Border border) => border.top,
  ShapeDecoration(shape: final OutlinedBorder shape)
      when shape.side != BorderSide.none =>
    shape.side,
  _ => null,
};

void main() {
  testWidgets('a toned icon tile draws no rim; a neutral one keeps its '
      'hairline', (tester) async {
    await tester.pumpWidget(
      scaledPage(
        const Row(
          children: [
            MinimalIconTile(Icons.check, tone: MinimalTone.success),
            MinimalIconTile(Icons.check),
          ],
        ),
      ),
    );
    Decoration? frame(int i) => tester
        .widget<Container>(
          find
              .descendant(
                of: find.byType(MinimalIconTile).at(i),
                matching: find.byType(Container),
              )
              .first,
        )
        .decoration;
    expect(_rimOf(frame(0)), isNull);
    expect(_rimOf(frame(1)), isNotNull);
  });
}

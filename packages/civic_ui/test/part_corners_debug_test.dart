// A full corner is held to Civic's extra large, and debug says so once,
// however many parts ask for it.
import 'package:civic_ui/civic_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('a full corner prints its debug line once', (tester) async {
    final lines = <String>[];
    final before = debugPrint;
    debugPrint = (message, {wrapWidth}) => lines.add(message ?? '');
    try {
      for (var i = 0; i < 2; i++) {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: CivicTheme(
              data: CivicThemeData.light(),
              child: Column(
                children: [
                  for (final label in ['Due', 'Paid'])
                    CivicTag(
                      label: label,
                      style: const CivicStyle(
                        corners: WidgetStatePropertyAll(
                          RawCorners.only(topStart: RawCorner.full),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }
    } finally {
      debugPrint = before;
    }
    expect(lines, [
      'Civic holds corner full to extraLarge, the nearest step it allows.',
    ]);
  });
}

// Every box a field takes words in is a well (frosted-glass.md: a field is recessed glass, a step darker than what
// holds it). Round 10: the one-time code's six boxes were still paint, white at 82%, so on a card they stood whiter
// than the card instead of cut into it, unlike the text field beside them. By day and by night, the code's boxes are
// well glass, as the text field's box is.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/frosted_host.dart';
import 'package:frosted_ui/src/frosted/internal/face.dart';

Iterable<FrostedMaterial> _faces(WidgetTester tester, Type part) => tester
    .widgetList<FrostedFace>(
      find.descendant(
        of: find.byType(part),
        matching: find.byType(FrostedFace),
      ),
    )
    .map((f) => f.material);

void main() {
  for (final brightness in Brightness.values) {
    final t = FrostedThemeData.preset(
      FrostedThemeData.presets.first,
      brightness,
    );

    testWidgets('by ${brightness.name} the one-time code stands in wells, as '
        'the text field does', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          builder: (context, page) => FrostedHost(
            light: t,
            dark: t,
            brightness: brightness,
            child: page!,
          ),
          home: Center(
            child: SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FrostedTextField(label: 'Name', onChanged: (_) {}),
                  const FrostedInputOtp(label: 'Code'),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));

      expect(_faces(tester, FrostedTextField).toSet(), {FrostedMaterial.well});
      final code = _faces(tester, FrostedInputOtp).toList();
      expect(code, hasLength(6), reason: 'one face per box');
      expect(code.toSet(), {FrostedMaterial.well});
    });
  }
}

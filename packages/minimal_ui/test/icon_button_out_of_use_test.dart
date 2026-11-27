// An icon button out of use fades as a button out of use does: its square
// takes the muted fill and the ink, and stands at the same strength, by day
// and by night, in every variant.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

double _strength(WidgetTester tester, Finder of) => tester
    .widget<AnimatedOpacity>(
      find.descendant(of: of, matching: find.byType(AnimatedOpacity)).first,
    )
    .opacity;

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('an icon button out of use fades as a button does '
        '(${brightness.name})', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          builder: (context, navigator) => MinimalHost(
            light: MinimalThemeData.preset('standard', Brightness.light),
            dark: MinimalThemeData.preset('standard', Brightness.dark),
            brightness: brightness,
            child: navigator!,
          ),
          home: MinimalScaffold(
            padding: EdgeInsets.zero,
            body: Wrap(
              children: [
                const MinimalButton('Start'),
                for (final variant in MinimalIconButtonVariant.values)
                  MinimalIconButton(
                    LucideIcons.play,
                    semanticLabel: variant.name,
                    variant: variant,
                  ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final button = _strength(tester, find.byType(MinimalButton));
      for (final variant in MinimalIconButtonVariant.values) {
        final key = find.byWidgetPredicate(
          (w) => w is MinimalIconButton && w.variant == variant,
        );
        expect(
          _strength(tester, key),
          lessThanOrEqualTo(button + 0.01),
          reason: variant.name,
        );
      }
    });
  }
}

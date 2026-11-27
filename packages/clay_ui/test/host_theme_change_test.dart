// ClayHost moves to a new theme over a moment, as Material's app does: day
// to night and one palette to another, at once under Reduce Motion. It
// switched at once.
import 'package:clay_ui/clay_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final reduce in [false, true]) {
    testWidgets(
      'day to night ${reduce ? 'at once under Reduce Motion' : 'over a moment'}',
      (tester) async {
        late Color ground;
        Widget host(Brightness brightness) => MediaQuery(
          data: MediaQueryData(disableAnimations: reduce),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: ClayHost(
              brightness: brightness,
              child: Builder(
                builder: (context) {
                  ground = ClayTheme.of(context).colors.ground;
                  return const SizedBox.expand();
                },
              ),
            ),
          ),
        );
        final day = ClayThemeData.clay(Brightness.light).colors.ground;
        final night = ClayThemeData.clay(Brightness.dark).colors.ground;
        await tester.pumpWidget(host(Brightness.light));
        expect(ground, day);
        await tester.pumpWidget(host(Brightness.dark));
        await tester.pump(const Duration(milliseconds: 60));
        if (reduce) {
          expect(ground, night);
        } else {
          expect(ground, isNot(day));
          expect(ground, isNot(night));
        }
        await tester.pumpAndSettle();
        expect(ground, night);
      },
    );
  }
}

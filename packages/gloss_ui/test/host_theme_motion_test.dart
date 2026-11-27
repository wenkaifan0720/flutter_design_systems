// The host moves to a new theme as MaterialApp does: day to night (or one
// palette to another) eases through the colours between, and under Reduce
// Motion it changes at once.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloss_ui/gloss_ui.dart';

Color? _page;

Widget _app(Brightness b, {bool still = false}) => MediaQuery(
  data: MediaQueryData(disableAnimations: still),
  child: Directionality(
    textDirection: TextDirection.ltr,
    child: GlossHost(
      brightness: b,
      child: Builder(
        builder: (context) {
          _page = GlossTheme.of(context).colors.page;
          return const SizedBox.expand();
        },
      ),
    ),
  ),
);

void main() {
  final day = GlossThemeData.preset('jade', Brightness.light).colors.page;
  final night = GlossThemeData.preset('jade', Brightness.dark).colors.page;

  testWidgets('day to night eases through the colours between', (t) async {
    await t.pumpWidget(_app(Brightness.light));
    expect(_page, day);
    await t.pumpWidget(_app(Brightness.dark));
    await t.pump(const Duration(milliseconds: 80));
    expect(_page, isNot(day));
    expect(_page, isNot(night));
    await t.pumpAndSettle();
    expect(_page, night);
  });

  testWidgets('under Reduce Motion it changes at once', (t) async {
    await t.pumpWidget(_app(Brightness.light, still: true));
    await t.pumpWidget(_app(Brightness.dark, still: true));
    await t.pump();
    expect(_page, night);
  });
}

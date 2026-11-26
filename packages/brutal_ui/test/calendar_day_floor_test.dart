// A calendar's day stands 44, the look's week, under a finger (whose floor,
// 40, it stands over) and under a pointer alike, so each day's face fills
// the target its calendar gives it and the rules between the weeks meet: at
// 44 under a 48 floor the weeks stood 4 apart, each rule broken by a strip
// of the page.
import 'package:brutal_ui/brutal_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, Brightness brightness) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    WidgetsApp(
      color: const Color(0xFF000000),
      builder: (context, _) => BrutalTheme(
        data: brightness == Brightness.light
            ? BrutalThemeData.light()
            : BrutalThemeData.dark(),
        child: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: 358,
            child: BrutalCalendar(
              firstDate: DateTime(2026),
              lastDate: DateTime(2027, 12, 31),
              selectedDate: DateTime(2026, 11, 20),
              currentDate: DateTime(2026, 11, 23),
              onDateChanged: (_) {},
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

// A day's face: the cell that draws its rules and its fill.
Rect _face(WidgetTester tester, String day) => tester.getRect(
  find
      .ancestor(
        of: find.text(day),
        matching: find.byWidgetPredicate(
          (w) => w is SizedBox && w.height != null && w.height! >= 40,
        ),
      )
      .first,
);

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('under a finger (${brightness.name}) each day stands 44 and '
        'the weeks meet', (tester) async {
      await _pump(tester, brightness);
      for (final (above, below) in const [('15', '22'), ('20', '27')]) {
        final a = _face(tester, above);
        final b = _face(tester, below);
        expect(a.height, 44, reason: above);
        expect(b.top, moreOrLessEquals(a.bottom, epsilon: .01), reason: below);
      }
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));

    testWidgets('under a pointer (${brightness.name}) each day stands 44 and '
        'the weeks meet', (tester) async {
      await _pump(tester, brightness);
      final a = _face(tester, '15');
      final b = _face(tester, '22');
      expect(a.height, 44);
      expect(b.top, moreOrLessEquals(a.bottom, epsilon: .01));
    }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));
  }
}

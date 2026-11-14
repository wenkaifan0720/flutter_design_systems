// A tab strip keeps the column's leading edge (Files' "Recent" once started
// 12 in from the title, search and list, with no surface to explain it). A row of transparent or subtle tabs hangs its
// first tab's padding toward the start, so its first word starts on the
// column's edge, its indicator under the word, from either side; a pill
// strip keeps its pill's edge on the column; the strip keeps the column's
// width, and its tabs still take a press.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluent2_ui/fluent2_ui.dart';
import 'package:fluent2_ui/fluent2_host.dart';

const _edge = 40.0;

Widget _host(Widget bar, {TextDirection direction = TextDirection.ltr}) {
  final theme = Fluent2ThemeData.preset('lapis', Brightness.light);
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    builder: (context, route) => Fluent2Host(
      light: theme,
      darkData: theme,
      brightness: Brightness.light,
      child: route!,
    ),
    home: Directionality(
      textDirection: direction,
      child: Material(
        type: MaterialType.transparency,
        child: Padding(
          padding: const EdgeInsets.all(_edge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(key: ValueKey('column'), height: 8),
              bar,
            ],
          ),
        ),
      ),
    ),
  );
}

/// The selected word's drawn box (the strong cut both texts share).
Rect _word(WidgetTester t, String word) => t.getRect(find.text(word).last);

void main() {
  for (final appearance in [
    Fluent2TabAppearance.transparent,
    Fluent2TabAppearance.subtle,
  ]) {
    for (final size in Fluent2TabSize.values) {
      for (final direction in TextDirection.values) {
        testWidgets('a ${appearance.name} ${size.name} strip, '
            '${direction.name}: its first word on the column\'s edge', (
          t,
        ) async {
          var chosen = 0;
          await t.pumpWidget(
            _host(
              StatefulBuilder(
                builder: (context, set) => Fluent2TabList(
                  tabs: const ['Recent', 'Shared', 'Starred'],
                  selectedIndex: chosen,
                  appearance: appearance,
                  size: size,
                  onChanged: (i) => set(() => chosen = i),
                ),
              ),
              direction: direction,
            ),
          );
          await t.pumpAndSettle();
          final column = t.getRect(find.byKey(const ValueKey('column')));
          final word = _word(t, 'Recent');
          if (direction == TextDirection.ltr) {
            expect(word.left, moreOrLessEquals(column.left, epsilon: .5));
          } else {
            expect(word.right, moreOrLessEquals(column.right, epsilon: .5));
          }
          // The strip keeps the column's width.
          final strip = t.getRect(find.byType(Fluent2TabList));
          expect(strip.left, greaterThanOrEqualTo(column.left - .01));
          expect(strip.right, lessThanOrEqualTo(column.right + .01));
          await t.tap(find.text('Shared').last);
          await t.pumpAndSettle();
          expect(chosen, 1);
          await t.tap(find.text('Recent').last);
          await t.pumpAndSettle();
          expect(chosen, 0);
        });
      }
    }
  }

  testWidgets('a pill strip keeps its first pill on the column\'s edge', (
    t,
  ) async {
    await t.pumpWidget(
      _host(
        Fluent2TabList(
          tabs: const ['Recent', 'Shared'],
          selectedIndex: 0,
          appearance: Fluent2TabAppearance.filledCircular,
          onChanged: (_) {},
        ),
      ),
    );
    await t.pumpAndSettle();
    final column = t.getRect(find.byKey(const ValueKey('column')));
    final strip = t.getRect(find.byType(Fluent2TabList));
    expect(strip.left, moreOrLessEquals(column.left, epsilon: .01));
    expect(_word(t, 'Recent').left, greaterThan(column.left + 8));
  });
}

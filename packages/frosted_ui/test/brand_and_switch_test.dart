// The brand as the app writes it, beside its own logo; a switch that is on
// reads at a glance: its glass tinted with the act, in every palette, by
// day and by night.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';

Future<void> _pump(
  WidgetTester t,
  Widget child, {
  FrostedThemeData? theme,
  Brightness? brightness,
}) async {
  await t.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, page) => FrostedHost(
        theme: theme,
        darkTheme: theme,
        brightness: brightness,
        child: page!,
      ),
      home: Center(child: child),
    ),
  );
  await t.pumpAndSettle();
  expect(t.takeException(), isNull);
}

void main() {
  testWidgets('the wordmark draws the name as it is given', (t) async {
    await _pump(t, const FrostedWordmark('Shelf'));
    expect(find.text('Shelf'), findsOneWidget);
    expect(find.text('shelf'), findsNothing);
  });

  testWidgets("the app's own logo stands in the mark's place", (t) async {
    const logo = Key('logo');
    await _pump(t, const FrostedWordmark('Shelf', logo: SizedBox(key: logo)));
    expect(find.byType(FrostedMark), findsNothing);
    expect(t.getSize(find.byKey(logo)), const Size.square(28));
    expect(find.bySemanticsLabel('Shelf'), findsOneWidget);
  });

  for (final b in Brightness.values) {
    for (final p in FrostedThemeData.palettes) {
      testWidgets(
        'an on switch tints its glass with the act (${p.id}, ${b.name})',
        (t) async {
          final theme = FrostedThemeData(palette: p, brightness: b);
          // The act's tint: a layer on the glass inside the rim, shown while the
          // switch is on.
          Color? wash(bool on) {
            for (final layer in t.widgetList<AnimatedOpacity>(
              find.descendant(
                of: find.byType(FrostedSwitch),
                matching: find.byType(AnimatedOpacity),
              ),
            )) {
              final box = layer.child;
              if (layer.opacity > 0 &&
                  box is DecoratedBox &&
                  box.decoration is ShapeDecoration) {
                return (box.decoration as ShapeDecoration).color;
              }
            }
            return null;
          }

          await _pump(
            t,
            FrostedSwitch(
              value: false,
              semanticLabel: 'Share',
              onChanged: (_) {},
            ),
            theme: theme,
            brightness: b,
          );
          expect(wash(false), isNull);
          await _pump(
            t,
            FrostedSwitch(
              value: true,
              semanticLabel: 'Share',
              onChanged: (_) {},
            ),
            theme: theme,
            brightness: b,
          );
          final on = wash(true)!;
          expect(
            on.withValues(alpha: 1),
            theme.colorScheme.accent.withValues(alpha: 1),
          );
          expect(on.a, greaterThan(.15));
        },
      );
    }
  }
}

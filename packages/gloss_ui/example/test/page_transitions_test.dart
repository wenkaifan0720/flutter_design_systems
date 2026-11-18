// The example's app plays Gloss's own page change, with iOS's swipe back kept round it.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloss_ui/gloss_ui.dart';

void main() {
  test('every platform plays Gloss’s push; iOS keeps the swipe back', () {
    for (final platform in TargetPlatform.values) {
      final builder = glossPageTransitions[platform];
      if (platform == TargetPlatform.iOS) {
        expect(builder, isA<DesignSwipeBackPageTransitionsBuilder>());
        expect(
          (builder! as DesignSwipeBackPageTransitionsBuilder).builder,
          isA<GlossPageTransitionsBuilder>(),
        );
      } else {
        expect(builder, isA<GlossPageTransitionsBuilder>());
      }
    }
  });

  testWidgets('a push and a pop settle', (tester) async {
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        theme: ThemeData(
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: glossPageTransitions,
          ),
        ),
        home: const Text('first'),
      ),
    );
    navigator.currentState!.push(
      MaterialPageRoute<void>(builder: (_) => const Text('second')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.byType(GlossPageTransition), findsWidgets);
    await tester.pumpAndSettle();
    expect(find.text('second'), findsOneWidget);
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(find.text('first'), findsOneWidget);
  });
}

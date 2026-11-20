// The example's app plays Clay's own page change, with iOS's swipe back kept round it.
import 'package:clay_ui/clay_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every platform plays Clay’s push; iOS keeps the swipe back', () {
    for (final platform in TargetPlatform.values) {
      final builder = clayPageTransitions[platform];
      if (platform == TargetPlatform.iOS) {
        expect(builder, isA<DesignSwipeBackPageTransitionsBuilder>());
        expect(
          (builder! as DesignSwipeBackPageTransitionsBuilder).builder,
          isA<ClayPageTransitionsBuilder>(),
        );
      } else {
        expect(builder, isA<ClayPageTransitionsBuilder>());
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
            builders: clayPageTransitions,
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
    expect(find.byType(ClayPageTransition), findsWidgets);
    await tester.pumpAndSettle();
    expect(find.text('second'), findsOneWidget);
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(find.text('first'), findsOneWidget);
  });
}

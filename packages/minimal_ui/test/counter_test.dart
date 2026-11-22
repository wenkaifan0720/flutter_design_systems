import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

import 'support/padded_host.dart';

void main() {
  group('MinimalCounter', () {
    testWidgets('it rolls to the new value and lands exactly on it', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        paddedHost(MinimalCounter(12, format: (v) => '${v}d')),
      );
      expect(find.bySemanticsLabel('12d'), findsOneWidget);

      await tester.pumpWidget(
        paddedHost(MinimalCounter(13, format: (v) => '${v}d')),
      );
      await tester.pump(const Duration(milliseconds: 60));
      // Mid-roll: the old units digit leaves while the new one arrives.
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('2'), findsNothing);
      expect(find.bySemanticsLabel('13d'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('under disableAnimations it swaps at once', (tester) async {
      Widget counter(int v) => MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: MinimalCounter(v),
      );
      await tester.pumpWidget(paddedHost(counter(9)));
      await tester.pumpWidget(paddedHost(counter(10)));
      await tester.pump();
      expect(find.text('9'), findsNothing);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
    });
  });
}

// Two months stand their names on their grids' edges.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'support/text_scale_host.dart';

void main() {
  testWidgets('two months side by side stand their names on their grids\' '
      'edges, as one month does, both chevrons after the last', (tester) async {
    await tester.pumpWidget(
      textScaleHost(
        SizedBox(
          width: 700,
          child: MinimalCalendar(
            firstDate: DateTime(2026),
            lastDate: DateTime(2026, 12, 31),
            value: DateTime(2026, 3, 18),
            onChanged: (_) {},
            months: 2,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final left = tester.getRect(find.byType(MinimalCalendar)).left;
    // A month's seven 44 px slots and the 32 px gutter between the grids,
    // wider than a column step, so the months read as two.
    const second = 7 * MinimalLayout.minHitTarget + MinimalSpacing.s32;
    expect(startOf(tester, 'March 2026'), moreOrLessEquals(left, epsilon: 1));
    expect(
      startOf(tester, 'April 2026'),
      moreOrLessEquals(left + second, epsilon: 1),
    );
    final previous = find.byWidgetPredicate(
      (w) => w is MinimalIconButton && w.icon == LucideIcons.chevronLeftDir,
    );
    final next = find.byWidgetPredicate(
      (w) => w is MinimalIconButton && w.icon == LucideIcons.chevronRightDir,
    );
    expect(previous, findsOneWidget);
    expect(next, findsOneWidget);
    expect(tester.getRect(previous).left, greaterThan(left + second));
    expect(tester.getRect(previous).left, lessThan(tester.getRect(next).left));
    await tester.tap(previous);
    await tester.pumpAndSettle();
    expect(find.text('February 2026'), findsOneWidget);
    await tester.tap(next);
    await tester.pumpAndSettle();
    expect(find.text('April 2026'), findsOneWidget);
  });
}

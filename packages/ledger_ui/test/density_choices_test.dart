// Density reaches a toggle group's pills and the filters' as it reaches
// rows and fields: 32 at standard, 4 off each step; the tap floor holds.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_ui.dart';

Future<double> _face(WidgetTester t, Widget part, LedgerDensity d) async {
  await t.pumpWidget(
    WidgetsApp(
      color: const Color(0xFF000000),
      localizationsDelegates: const [RawWidgetsLocalizations.delegate],
      builder: (context, _) => LedgerHost(
        brightness: Brightness.light,
        theme: LedgerThemeData.light(density: d),
        child: Align(alignment: Alignment.topCenter, child: part),
      ),
    ),
  );
  await t.pumpAndSettle();
  return t
      .getSize(
        find
            .ancestor(
              of: find.text('Week'),
              matching: find.byType(DecoratedBox),
            )
            .first,
      )
      .height;
}

void main() {
  final parts = <String, Widget>{
    'toggle group': LedgerToggleGroup<String>(
      options: const ['Week', 'Month'],
      selected: const {'Week'},
      semanticLabel: 'Period',
      labelOf: (v) => v,
      onSelectionChanged: (_) {},
    ),
    'filters': LedgerFilters<String>(
      options: const ['Week', 'Month'],
      value: 'Week',
      semanticLabel: 'Period',
      labelOf: (v) => v,
      onChanged: (_) {},
    ),
  };
  for (final MapEntry(key: name, value: part) in parts.entries) {
    testWidgets('a $name follows the density', (t) async {
      final standard = await _face(t, part, LedgerDensity.standard);
      final compact = await _face(t, part, LedgerDensity.compact);
      expect(standard - compact, 8, reason: name);
    });
  }
}

// An optional date (no value yet) opens its sheet with no day struck, and
// Done without a day leaves it unset, as the value's docs say; a day picked
// is struck and Done keeps it.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_ui.dart';

Future<void> _pump(WidgetTester t, Widget picker) async {
  t.view.physicalSize = const Size(390, 844);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    WidgetsApp(
      color: const Color(0xFF000000),
      localizationsDelegates: const [RawWidgetsLocalizations.delegate],
      builder: (context, _) => LedgerHost(
        brightness: Brightness.light,
        child: Navigator(
          onGenerateRoute: (_) => PageRouteBuilder<void>(
            pageBuilder: (_, _, _) => Align(
              alignment: Alignment.topCenter,
              child: SizedBox(width: 342, child: picker),
            ),
          ),
        ),
      ),
    ),
  );
  await t.pumpAndSettle();
}

final _today = DateTime(2026, 11, 27);

/// The days the open calendar reads as chosen.
List<String> _struck(WidgetTester t) => [
  for (final node
      in find
          .byWidgetPredicate(
            (w) => w is Semantics && w.properties.selected == true,
          )
          .evaluate())
    (node.widget as Semantics).properties.label ?? '',
];

void main() {
  testWidgets(
    'an optional date opens with no day struck; Done leaves it unset',
    (t) async {
      final told = <DateTime?>[];
      await _pump(
        t,
        LedgerDatePicker(
          labelText: 'Date started',
          value: null,
          currentDate: _today,
          lastDate: _today,
          onChanged: told.add,
        ),
      );
      await t.tap(find.text('Select date'));
      await t.pumpAndSettle();
      expect(find.text('November 2026'), findsOneWidget);
      expect(_struck(t), isEmpty);
      await t.tap(find.text('Done'));
      await t.pumpAndSettle();
      expect(told, isEmpty);
      expect(find.text('Select date'), findsOneWidget);
    },
  );

  testWidgets('a day picked in the sheet is struck and Done keeps it', (
    t,
  ) async {
    final told = <DateTime?>[];
    await _pump(
      t,
      LedgerDatePicker(
        labelText: 'Date started',
        value: null,
        currentDate: _today,
        lastDate: _today,
        onChanged: told.add,
      ),
    );
    await t.tap(find.text('Select date'));
    await t.pumpAndSettle();
    await t.tap(find.text('3'));
    await t.pumpAndSettle();
    expect(_struck(t), hasLength(1));
    await t.tap(find.text('Done'));
    await t.pumpAndSettle();
    expect(told, [DateTime(2026, 11, 3)]);
  });
}

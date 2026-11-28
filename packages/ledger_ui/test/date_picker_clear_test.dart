// An app that takes onClear offers Clear in a date's sheet once a day is
// chosen, and only then; Clear tells the app and closes the sheet.
import 'package:flutter/semantics.dart';
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

void main() {
  testWidgets('with onClear, a chosen date offers Clear, which clears it', (
    t,
  ) async {
    var cleared = 0;
    await _pump(
      t,
      LedgerDatePicker(
        labelText: 'Date started',
        value: DateTime(2026, 11, 3),
        currentDate: _today,
        onChanged: (_) {},
        onClear: () => cleared++,
      ),
    );
    await t.tap(find.text('Nov 3, 2026'));
    await t.pumpAndSettle();
    expect(find.text('Clear'), findsOneWidget);
    await t.tap(find.text('Clear'));
    await t.pumpAndSettle();
    expect(cleared, 1);
    expect(find.text('November 2026'), findsNothing);
  });

  testWidgets('no Clear without onClear', (t) async {
    await _pump(
      t,
      LedgerDatePicker(
        labelText: 'Due',
        value: DateTime(2026, 11, 3),
        currentDate: _today,
        onChanged: (_) {},
      ),
    );
    await t.tap(find.text('Nov 3, 2026'));
    await t.pumpAndSettle();
    expect(find.text('Clear'), findsNothing);
  });

  testWidgets('no Clear with no date chosen', (t) async {
    await _pump(
      t,
      LedgerDatePicker(
        labelText: 'Due',
        value: null,
        currentDate: _today,
        onChanged: (_) {},
        onClear: () {},
      ),
    );
    await t.tap(find.text('Select date'));
    await t.pumpAndSettle();
    expect(find.text('Clear'), findsNothing);
  });

  testWidgets('Clear is a button a screen reader reaches', (t) async {
    final handle = t.ensureSemantics();
    await _pump(
      t,
      LedgerDatePicker(
        labelText: 'Date started',
        value: DateTime(2026, 11, 3),
        currentDate: _today,
        onChanged: (_) {},
        onClear: () {},
      ),
    );
    await t.tap(find.text('Nov 3, 2026'));
    await t.pumpAndSettle();
    final node = t.getSemantics(find.text('Clear'));
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    handle.dispose();
  });
}

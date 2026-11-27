// Ledger's date picker in a form: an optional date asks for one until it is
// chosen (its pill in the second ink, its picker opening on today with no day
// struck), and a chosen day prints as one medium date with its year, in
// English as Ledger writes it ("Nov 20, 2026") and in another language as
// ui_core's RawWidgetsLocalizations.formatMediumDate does.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_ui.dart';

Future<void> _pump(WidgetTester t, Widget picker, {Locale? locale}) async {
  t.view.physicalSize = const Size(390, 844);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    WidgetsApp(
      color: const Color(0xFF000000),
      locale: locale ?? const Locale('en'),
      supportedLocales: RawWidgetsLocalizations.supportedLocales,
      localizationsDelegates: const [RawWidgetsLocalizations.delegate],
      builder: (context, _) => LedgerHost(
        brightness: Brightness.light,
        child: Navigator(
          onGenerateRoute: (_) => PageRouteBuilder<void>(
            pageBuilder: (_, _, _) => Align(
              alignment: Alignment.topCenter,
              child: Padding(padding: const EdgeInsets.all(20), child: picker),
            ),
          ),
        ),
      ),
    ),
  );
  await t.pumpAndSettle();
}

void main() {
  testWidgets('an optional date asks for one, and its picker gives it', (
    tester,
  ) async {
    DateTime? picked;
    await _pump(
      tester,
      StatefulBuilder(
        builder: (context, setState) => LedgerDatePicker(
          labelText: 'Date started',
          value: picked,
          currentDate: DateTime(2026, 11, 20),
          onChanged: (day) => setState(() => picked = day),
        ),
      ),
    );
    expect(find.text('Select date'), findsOneWidget);
    final ask = tester.widget<Text>(find.text('Select date'));
    final t = LedgerThemeData.preset('quire', Brightness.light);
    expect(ask.style?.color, t.textSecondary);
    await tester.tap(find.text('Select date'));
    await tester.pumpAndSettle();
    // The month opens on the current date's, nothing struck yet: Done takes
    // the day the picker stands on.
    expect(find.text('November 2026'), findsOneWidget);
    await tester.tap(find.text('21'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(picked, DateTime(2026, 11, 21));
    expect(find.text('Nov 21, 2026'), findsOneWidget);
    expect(find.text('Select date'), findsNothing);
  });

  testWidgets("a chosen day prints as the reader's medium date with its year", (
    tester,
  ) async {
    final day = DateTime(2026, 3, 3);
    for (final code in ['de', 'ja', 'fr']) {
      final locale = Locale(code);
      await _pump(
        tester,
        LedgerDatePicker(labelText: 'Date', value: day, onChanged: (_) {}),
        locale: locale,
      );
      final words = await RawWidgetsLocalizations.delegate.load(locale);
      expect(
        find.text(words.formatMediumDate(day)),
        findsOneWidget,
        reason: code,
      );
    }
  });
}

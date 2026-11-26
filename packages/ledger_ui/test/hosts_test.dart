// Ledger under each of Flutter's app hosts (the production bar's line 2): a MaterialApp, a CupertinoApp and a bare
// WidgetsApp, by day and by night, on a phone and a desk. The look needs only what every host gives (a Navigator's
// overlay, MediaQuery, Directionality); its field, act, switch and checkbox answer a finger and the keyboard in each.
import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoApp;
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_ui.dart';

class _Page extends StatefulWidget {
  const _Page();

  @override
  State<_Page> createState() => _PageState();
}

class _PageState extends State<_Page> {
  var moved = 0;
  var alerts = false;
  bool? cleared = false;

  @override
  Widget build(BuildContext context) => LedgerScreen(
    body: Center(
      child: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 12,
          children: [
            const LedgerTextField(labelText: 'Payee'),
            LedgerButton.filled(
              'Move money',
              onPressed: () => setState(() => moved++),
            ),
            LedgerSwitch(
              value: alerts,
              semanticLabel: 'Alerts',
              onChanged: (v) => setState(() => alerts = v),
            ),
            LedgerCheckbox(
              value: cleared,
              label: 'Cleared',
              onChanged: (v) => setState(() => cleared = v),
            ),
            Text('moved $moved alerts $alerts cleared $cleared'),
          ],
        ),
      ),
    ),
  );
}

Widget _ledger(Brightness b, Widget child) =>
    LedgerTheme(data: LedgerThemeData.preset('quire', b), child: child);

final _hosts = <String, Widget Function(Brightness)>{
  'MaterialApp': (b) => MaterialApp(
    debugShowCheckedModeBanner: false,
    builder: (context, navigator) => _ledger(b, navigator!),
    home: const _Page(),
  ),
  'CupertinoApp': (b) => CupertinoApp(
    debugShowCheckedModeBanner: false,
    builder: (context, navigator) => _ledger(b, navigator!),
    home: const _Page(),
  ),
  'WidgetsApp': (b) => WidgetsApp(
    color: const Color(0xFF1E5A44),
    debugShowCheckedModeBanner: false,
    builder: (context, _) => _ledger(
      b,
      Navigator(
        onGenerateRoute: (_) =>
            PageRouteBuilder<void>(pageBuilder: (_, _, _) => const _Page()),
      ),
    ),
  ),
};

void main() {
  for (final MapEntry(key: host, value: app) in _hosts.entries) {
    for (final b in Brightness.values) {
      for (final size in const [Size(390, 844), Size(1440, 960)]) {
        testWidgets('under a $host, ${b.name}, ${size.width.round()} wide', (
          t,
        ) async {
          t.view
            ..physicalSize = size * 2
            ..devicePixelRatio = 2;
          addTearDown(t.view.reset);
          await t.pumpWidget(app(b));
          await t.pumpAndSettle();
          expect(t.takeException(), isNull);
          // The theme in force is the one given, under every host.
          final ctx = t.element(find.byType(LedgerButton));
          expect(LedgerTheme.of(ctx).brightness, b);

          await t.tap(find.text('Move money'));
          await t.tap(find.byType(LedgerSwitch));
          await t.tap(find.text('Cleared'));
          await t.pumpAndSettle();
          expect(find.text('moved 1 alerts true cleared true'), findsOneWidget);

          await t.enterText(find.byType(EditableText), 'Harbor Transit');
          await t.pump();
          expect(find.text('Harbor Transit'), findsOneWidget);

          // The keyboard reaches the act: focused, space presses it.
          final focus = Focus.of(t.element(find.text('Move money')));
          focus.requestFocus();
          await t.pump();
          await t.sendKeyEvent(LogicalKeyboardKey.space);
          await t.pumpAndSettle();
          expect(find.text('moved 2 alerts true cleared true'), findsOneWidget);
          expect(t.takeException(), isNull);
        });
      }
    }
  }
}

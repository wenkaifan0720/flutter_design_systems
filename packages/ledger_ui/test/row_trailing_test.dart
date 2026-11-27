// A row with a trailing control, as an adopter builds a list with a menu on
// each row: the control keeps its own node and its own press beside the row's
// (a screen reader reaches the menu), and it takes half the row at most. A
// row follows the density: 52 at standard, 4 off each step.
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

Future<void> _pump(WidgetTester t, Widget row, {LedgerDensity? density}) async {
  t.view.physicalSize = const Size(390, 600);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  final day = LedgerThemeData.light(density: density ?? LedgerDensity.standard);
  await t.pumpWidget(
    WidgetsApp(
      color: const Color(0xFF000000),
      localizationsDelegates: const [RawWidgetsLocalizations.delegate],
      builder: (context, _) => LedgerHost(
        brightness: Brightness.light,
        theme: day,
        child: Align(
          alignment: Alignment.topCenter,
          // In a list's column, as rows stand.
          child: SizedBox(
            width: 342,
            child: Column(mainAxisSize: MainAxisSize.min, children: [row]),
          ),
        ),
      ),
    ),
  );
  await t.pumpAndSettle();
}

void main() {
  testWidgets('a trailing control keeps its own node and press', (t) async {
    final semantics = t.ensureSemantics();
    var opened = 0, menus = 0;
    await _pump(
      t,
      LedgerRow(
        title: 'Rent',
        subtitle: 'Monthly',
        onTap: () => opened++,
        trailing: LedgerIconButton(
          LucideIcons.ellipsis,
          semanticLabel: 'More for Rent',
          onPressed: () => menus++,
        ),
      ),
    );
    final row = t.getSemantics(find.text('Monthly'));
    final menu = t.getSemantics(find.bySemanticsLabel('More for Rent'));
    expect(identical(row, menu), isFalse);
    expect(row.label, isNot(contains('More for Rent')));
    expect(menu.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    await t.tap(find.byIcon(LucideIcons.ellipsis));
    await t.tap(find.text('Rent'));
    expect((menus, opened), (1, 1));
    semantics.dispose();
  });

  testWidgets('a wide trailing part takes half the row at most', (t) async {
    await _pump(
      t,
      const LedgerRow(
        title: 'Rent',
        trailing: SizedBox(key: Key('wide'), width: 2000, height: 20),
      ),
    );
    expect(t.getSize(find.byKey(const Key('wide'))).width, 342 / 2);
    expect(t.takeException(), isNull);
  });

  testWidgets('a row follows the density', (t) async {
    double height(LedgerDensity d) => t.getSize(find.byType(LedgerRow)).height;
    final heights = <double>[];
    for (final d in LedgerDensity.values) {
      await _pump(t, const LedgerRow(title: 'Rent'), density: d);
      heights.add(height(d));
    }
    expect(heights[0] - heights[1], 4);
    expect(heights[1] - heights[2], 4);
  });
}

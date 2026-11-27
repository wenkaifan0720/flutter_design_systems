// A row's end: a trailing part takes its own width up to two thirds of the
// row and a long tag ellipsizes rather than overflowing, the title keeping
// the rest; a tag is in the row's name, said as written rather than in its
// printed capitals; an avatar of the title's own name stays out of it.
import 'package:appliance_ui/appliance_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp, Scaffold;

Future<void> _show(WidgetTester tester, Widget row) async {
  tester.view
    ..physicalSize = const Size(390, 400)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) =>
          ApplianceHost(brightness: Brightness.light, child: app!),
      home: Scaffold(
        body: Align(
          alignment: Alignment.topCenter,
          child: ApplianceListGroup(children: [row]),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a long tag ellipsizes within two thirds of the row', (
    tester,
  ) async {
    await _show(
      tester,
      ApplianceListTile(
        title: 'Proof the studio map',
        onTap: () {},
        trailing: const ApplianceTag(
          'Waiting on the print shop for the second proof',
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    final row = tester.getRect(find.byType(ApplianceListTile));
    final tag = tester.getRect(find.byType(ApplianceTag));
    final title = tester.getRect(find.text('Proof the studio map'));
    expect(tag.right, lessThanOrEqualTo(row.right));
    expect(tag.width, lessThanOrEqualTo(row.width * 2 / 3));
    expect(title.width, greaterThan(0));
    expect(title.right, lessThanOrEqualTo(tag.left));
  });

  testWidgets('a tag is in the row name, as written', (tester) async {
    final semantics = tester.ensureSemantics();
    await _show(
      tester,
      ApplianceListTile(
        title: 'Proof the studio map',
        onTap: () {},
        trailing: const ApplianceTag('Waiting', tone: ApplianceTagTone.signal),
      ),
    );
    // The row's words merge up into its node.
    final label = tester
        .getSemantics(find.bySemanticsLabel(RegExp('^Proof the studio map')))
        .getSemanticsData()
        .label;
    expect(label, contains('Waiting'));
    expect(label, isNot(contains('WAITING')));
    expect(find.bySemanticsLabel(RegExp('WAITING')), findsNothing);
    semantics.dispose();
  });

  testWidgets('a tag alone is said as written', (tester) async {
    final semantics = tester.ensureSemantics();
    await _show(tester, const ApplianceTag('Ready'));
    expect(find.bySemanticsLabel('Ready'), findsOneWidget);
    expect(find.bySemanticsLabel('READY'), findsNothing);
    semantics.dispose();
  });

  testWidgets("an avatar of the title's name stays out of the row name", (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _show(
      tester,
      ApplianceListTile(
        title: 'Ada Lovelace',
        subtitle: 'Owner',
        leading: const ApplianceAvatar(name: 'Ada Lovelace', size: 32),
        onTap: () {},
      ),
    );
    final label = tester
        .getSemantics(find.bySemanticsLabel(RegExp('Owner')))
        .getSemanticsData()
        .label;
    expect('Ada Lovelace'.allMatches(label).length, 1);
    semantics.dispose();
  });
}

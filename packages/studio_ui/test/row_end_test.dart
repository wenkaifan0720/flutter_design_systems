// A row's end part: a status tag is read with the row's name, a control at
// its end (a menu key) keeps its own node beside the row's, and the end part
// takes its own width up to two thirds of the line, a long tag ellipsizing
// rather than pushing the title out. An avatar of the title's own name stays
// out of the row's name.
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_ui/studio_ui.dart';
import 'package:ui_core_test/ui_core_test.dart';

Future<void> _rows(
  WidgetTester tester,
  List<Widget> rows, {
  double width = 390,
}) async {
  tester.view
    ..physicalSize = Size(width, 800)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) =>
          StudioHost(brightness: Brightness.light, child: app!),
      home: StudioScreen(body: StudioListGroup(children: rows)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(studioLoadFonts);

  testWidgets('a status tag is read with the row', (tester) async {
    final semantics = tester.ensureSemantics();
    await _rows(tester, [
      StudioListTile(
        title: 'The quiet booth',
        subtitle: 'Roomtone',
        trailing: const StudioTag('Editing', tone: StudioTagTone.lit),
        onTap: () {},
      ),
    ]);
    expect(
      find.bySemanticsLabel('The quiet booth, Roomtone, Editing'),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('a menu key at the end keeps its own node', (tester) async {
    final semantics = tester.ensureSemantics();
    var opened = 0;
    var more = 0;
    await _rows(tester, [
      StudioListTile(
        title: 'The quiet booth',
        subtitle: 'Roomtone',
        trailing: StudioIconButton(
          icon: const Icon(LucideIcons.ellipsis),
          tooltip: 'More',
          onPressed: () => more++,
        ),
        onTap: () => opened++,
      ),
    ]);
    const DesignControlNodesCheck(look: 'Studio')
        .check(tester.element(find.byType(StudioListGroup)))
        .verify();
    expect(find.bySemanticsLabel('More'), findsOneWidget);
    expect(find.bySemanticsLabel('The quiet booth, Roomtone'), findsOneWidget);
    await tester.tap(find.byType(StudioIconButton));
    await tester.tap(find.text('The quiet booth'));
    expect((more, opened), (1, 1));
    semantics.dispose();
  });

  testWidgets('a long tag takes at most two thirds of a 320 row', (
    tester,
  ) async {
    await _rows(width: 320, tester, [
      StudioListTile(
        title: 'The quiet booth',
        trailing: const StudioTag(
          'Waiting for the second engineer to sign off',
          tone: StudioTagTone.lit,
        ),
        onTap: () {},
      ),
    ]);
    expect(tester.takeException(), isNull);
    final row = tester.getRect(find.byType(StudioListTile));
    final tag = tester.getRect(find.byType(StudioTag));
    expect(tag.width, lessThanOrEqualTo(row.width * 2 / 3));
    expect(tester.getRect(find.text('The quiet booth')).width, greaterThan(40));
  });

  testWidgets("an avatar of the title's name stays out of the row's name", (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _rows(tester, [
      StudioListTile(
        leading: const StudioAvatar(name: 'Ada Lovelace', size: 32),
        title: 'Ada Lovelace',
        subtitle: 'Host',
        trailing: const StudioTag('Live', tone: StudioTagTone.lit),
        onTap: () {},
      ),
    ]);
    expect(find.bySemanticsLabel('Ada Lovelace, Host, Live'), findsOneWidget);
    semantics.dispose();
  });
}

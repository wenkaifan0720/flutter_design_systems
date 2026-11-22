// A menu entry that destroys something (Delete, Remove) prints its words in
// the danger ink, in a menu key's menu and in a menu bar's, as the action
// sheet's destructive rows do; its neighbours keep the print.
import 'package:appliance_ui/appliance_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp, Scaffold;

const _entries = [
  RawMenuEntry(label: 'Rename', onPressed: _none),
  RawMenuEntry(label: 'Delete', isDestructiveAction: true, onPressed: _none),
];

void _none() {}

Color? _ink(WidgetTester tester, String words) => tester
    .renderObject<RenderParagraph>(find.text(words).last)
    .text
    .style
    ?.color;

Future<void> _show(WidgetTester tester, Widget menu) async {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = const Size(780, 600);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) =>
          ApplianceHost(brightness: Brightness.light, child: app!),
      home: Scaffold(
        body: Align(alignment: Alignment.topCenter, child: menu),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a menu key\'s menu prints Delete in the danger ink', (
    tester,
  ) async {
    await _show(
      tester,
      ApplianceMenu(
        semanticLabel: 'Task',
        entries: _entries,
        builder: (context, anchor) => ApplianceIconButton(
          icon: const Icon(LucideIcons.ellipsis),
          semanticLabel: 'Task actions',
          onPressed: anchor.toggle,
        ),
      ),
    );
    await tester.tap(find.bySemanticsLabel('Task actions'));
    await tester.pumpAndSettle();
    final c = ApplianceTheme.of(tester.element(find.text('Delete'))).colors;
    expect(_ink(tester, 'Delete'), c.danger);
    expect(_ink(tester, 'Rename'), c.print);
  });

  testWidgets('a menu bar\'s menu prints Delete in the danger ink', (
    tester,
  ) async {
    await _show(
      tester,
      const ApplianceMenuBar(
        menus: [RawMenuEntry(label: 'Task', children: _entries)],
      ),
    );
    await tester.tap(find.text('Task'));
    await tester.pumpAndSettle();
    final c = ApplianceTheme.of(tester.element(find.text('Delete'))).colors;
    expect(_ink(tester, 'Delete'), c.danger);
    expect(_ink(tester, 'Rename'), c.print);
  });
}

// A key row with a control at its end (a row's ⋯ menu key): the control
// stands inside the row's key and latches down with it, yet stays a key of
// its own, to a press and to a screen reader, as a ListTile's trailing
// IconButton does.
import 'package:appliance_ui/appliance_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp, Scaffold;

int _opened = 0;
int _menus = 0;

Future<void> _show(WidgetTester tester, {bool selected = false}) async {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = const Size(780, 600);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) =>
          ApplianceHost(brightness: Brightness.light, child: app!),
      home: Scaffold(
        body: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: 380,
            child: ApplianceListGroup(
              children: [
                ApplianceListTile(
                  title: 'Proof the studio map',
                  subtitle: 'Open studio · Nov 20',
                  selected: selected,
                  showChevron: false,
                  onTap: () => _opened++,
                  trailing: ApplianceIconButton(
                    icon: const Icon(LucideIcons.ellipsis),
                    semanticLabel: 'Task actions',
                    onPressed: () => _menus++,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(applianceLoadFonts);
  setUp(() => _opened = _menus = 0);

  testWidgets('a press on the control reaches the control', (tester) async {
    await _show(tester);
    await tester.tap(find.byType(ApplianceIconButton));
    await tester.pumpAndSettle();
    expect((_menus, _opened), (1, 0));
    await tester.tap(find.text('Proof the studio map'));
    await tester.pumpAndSettle();
    expect((_menus, _opened), (1, 1));
  });

  testWidgets('the control is its own node, the row names itself', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _show(tester);
    final menu = tester.getSemantics(find.byType(ApplianceIconButton));
    expect(menu, isSemantics(label: 'Task actions', isButton: true));
    final row = tester.getSemantics(
      find.bySemanticsLabel(RegExp('^Proof the studio map')),
    );
    final words = row.getSemanticsData().label;
    expect(words, contains('Proof the studio map'));
    expect(words, isNot(contains('Task actions')));
    expect(row.id, isNot(menu.id));
    // A screen reader's press on the control runs the control.
    tester.semantics.tap(find.semantics.byLabel('Task actions'));
    await tester.pumpAndSettle();
    expect((_menus, _opened), (1, 0));
    semantics.dispose();
  });

  testWidgets('a selected row latches round its control', (tester) async {
    await _show(tester, selected: true);
    final key = tester
        .widgetList<AnimatedApplianceSurface>(
          find.ancestor(
            of: find.byType(ApplianceIconButton),
            matching: find.byType(AnimatedApplianceSurface),
          ),
        )
        .where((s) => s.face.lift < 0);
    expect(key, isNotEmpty, reason: 'the latched row holds the control');
  });
}

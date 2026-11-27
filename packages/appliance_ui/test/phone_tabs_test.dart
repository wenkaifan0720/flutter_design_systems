// ApplianceScaffold at a phone's width: its key strip's places are ui_core's
// tabs, read as "Tab 1 of 3" and selected when chosen, the act key at the
// strip's end a button of its own.
import 'dart:ui' show Tristate;

import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:appliance_ui/appliance_ui.dart';
import 'package:ui_core_test/ui_core_test.dart';

const _places = [
  ApplianceDestination(icon: LucideIcons.listChecks, label: 'Lists'),
  ApplianceDestination(icon: LucideIcons.shoppingBasket, label: 'Basket'),
  ApplianceDestination(icon: LucideIcons.settings, label: 'Settings'),
];

void main() {
  testWidgets("a phone's places are tabs; the chosen one says so", (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, app) =>
            ApplianceHost(brightness: Brightness.light, child: app!),
        home: ApplianceScaffold(
          destinations: _places,
          selectedIndex: 1,
          onSelected: (_) {},
          action: ApplianceShellAction(
            icon: LucideIcons.plus,
            label: 'New list',
            onPressed: (context) {},
          ),
          body: const ApplianceScreen(body: Text('Basket body')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    const DesignNavigationCheck(look: 'Appliance')
        .check(
          tester.element(find.byType(ApplianceScaffold)),
          destinations: ['Lists', 'Basket', 'Settings'],
        )
        .verify();
    final basket = tester.getSemantics(
      find.bySemanticsLabel(RegExp('^Basket(\n.*)?Tab 2 of 3', dotAll: true)),
    );
    expect(
      basket.getSemanticsData().flagsCollection.isSelected,
      Tristate.isTrue,
    );
    expect(find.bySemanticsLabel('New list'), findsOneWidget);
    semantics.dispose();
  });
}

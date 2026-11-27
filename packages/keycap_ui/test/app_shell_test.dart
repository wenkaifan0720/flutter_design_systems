// Keycap's app frame: the places at every width through ui_core's shell, a phone's bar as tabs with the chosen one
// selected; the branches form keeps a stack per place: a pushed page keeps the rail or the side column while the phone's
// bar steps away, and back pops it.
import 'dart:ui' show SemanticsRole, Tristate;

import 'package:material_ui/material_ui.dart'
    show MaterialApp, MaterialPageRoute;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keycap_ui/keycap_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const _places = [
  KeycapDestination(icon: LucideIcons.notebook, label: 'Notes'),
  KeycapDestination(icon: LucideIcons.tag, label: 'Tags'),
  KeycapDestination(icon: LucideIcons.settings, label: 'Settings'),
];

class _Branches extends StatefulWidget {
  const _Branches();

  @override
  State<_Branches> createState() => _BranchesState();
}

class _BranchesState extends State<_Branches> {
  int at = 0;

  @override
  Widget build(BuildContext context) => KeycapScaffold.branches(
    destinations: _places,
    selectedIndex: at,
    onDestinationSelected: (i) => setState(() => at = i),
    branches: [
      for (final p in _places)
        (context) => KeycapScreen(
          topBar: KeycapAppBar(title: '${p.label} home'),
          body: KeycapButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => KeycapScreen(
                  topBar: KeycapAppBar(title: '${p.label} page'),
                  body: const Text('Deep'),
                ),
              ),
            ),
            child: Text('Open ${p.label}'),
          ),
        ),
    ],
  );
}

Future<void> _pump(WidgetTester tester, double width) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, page) =>
          KeycapHost(brightness: Brightness.light, child: page!),
      home: const _Branches(),
    ),
  );
  await tester.pumpAndSettle();
}

SemanticsData? _tab(WidgetTester tester, String label) {
  SemanticsData? found;
  void visit(SemanticsNode node) {
    final d = node.getSemanticsData();
    if (d.role == SemanticsRole.tab && d.label.contains(label)) found ??= d;
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  visit(
    tester.binding.renderViews.first.owner!.semanticsOwner!.rootSemanticsNode!,
  );
  return found;
}

void main() {
  testWidgets("a phone's places are tabs, the chosen one selected", (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester, 390);
    final notes = _tab(tester, 'Notes');
    final tags = _tab(tester, 'Tags');
    expect(notes, isNotNull, reason: 'a tab named Notes');
    expect(notes!.flagsCollection.isSelected, Tristate.isTrue);
    expect(tags!.flagsCollection.isSelected, Tristate.isFalse);
    semantics.dispose();
  });

  for (final width in [390.0, 800.0, 1440.0]) {
    testWidgets(
      'at ${width.round()} a pushed page keeps the rail or the side column; back pops it',
      (tester) async {
        await _pump(tester, width);
        await tester.tap(find.text('Tags'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Open Tags'));
        await tester.pumpAndSettle();
        expect(find.text('Tags page'), findsOneWidget);
        final placesShown = find
            .text('Settings')
            .hitTestable()
            .evaluate()
            .isNotEmpty;
        expect(
          placesShown,
          width >= 600,
          reason: 'the phone bar steps away; a rail or side column stays',
        );
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.text('Tags page'), findsNothing);
        expect(find.text('Open Tags'), findsOneWidget);
        expect(find.text('Settings').hitTestable(), findsOneWidget);
      },
    );
  }
}

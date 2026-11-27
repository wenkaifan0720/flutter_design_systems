// MinimalTabBar with ui_core's RawTabController: the strip and a
// RawTabBarView of the panels share one choice (a tap moves the panels, a
// swipe of the panels moves the strip), each tab may wear a glyph that grows
// with the reader's text, and the controller-free form keeps working.
import 'dart:ui' show Tristate;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class _Tabs extends StatefulWidget {
  const _Tabs({this.scale = 1});

  final double scale;

  @override
  State<_Tabs> createState() => _TabsState();
}

class _TabsState extends State<_Tabs> with TickerProviderStateMixin {
  late final controller = RawTabController(length: 3, vsync: this);
  final heard = <int>[];

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MediaQuery(
    data: MediaQuery.of(context)
        .copyWith(textScaler: TextScaler.linear(widget.scale)),
    child: Column(
      children: [
        MinimalTabBar(
          tabs: const ['Overview', 'Activity', 'Notes'],
          icons: const [LucideIcons.layoutGrid, null, LucideIcons.notebookPen],
          controller: controller,
          onChanged: heard.add,
        ),
        Expanded(
          child: RawTabBarView(
            controller: controller,
            children: const [
              Center(child: Text('Overview panel')),
              Center(child: Text('Activity panel')),
              Center(child: Text('Notes panel')),
            ],
          ),
        ),
      ],
    ),
  );
}

Future<_TabsState> _pump(WidgetTester tester, {double scale = 1}) async {
  tester.view
    ..physicalSize = const Size(390, 700)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MinimalHost(child: child!),
      home: Scaffold(body: _Tabs(scale: scale)),
    ),
  );
  await tester.pumpAndSettle();
  return tester.state<_TabsState>(find.byType(_Tabs));
}

bool _selected(WidgetTester tester, String tab) =>
    tester
        .getSemantics(find.bySemanticsLabel(RegExp('^$tab')).first)
        .getSemanticsData()
        .flagsCollection
        .isSelected ==
    Tristate.isTrue;

void main() {
  testWidgets('a tap on a tab moves the panels', (tester) async {
    final semantics = tester.ensureSemantics();
    final state = await _pump(tester);
    expect(find.text('Overview panel'), findsOneWidget);
    await tester.tap(find.text('Notes'));
    await tester.pumpAndSettle();
    expect(find.text('Notes panel'), findsOneWidget);
    expect(state.controller.index, 2);
    expect(state.heard, [2]);
    expect(_selected(tester, 'Notes'), isTrue);
    semantics.dispose();
  });

  testWidgets('a swipe of the panels moves the strip', (tester) async {
    final semantics = tester.ensureSemantics();
    final state = await _pump(tester);
    await tester.fling(
      find.text('Overview panel'),
      const Offset(-300, 0),
      1000,
    );
    await tester.pumpAndSettle();
    expect(find.text('Activity panel'), findsOneWidget);
    expect(state.controller.index, 1);
    expect(_selected(tester, 'Activity'), isTrue);
    expect(_selected(tester, 'Overview'), isFalse);
    expect(state.heard, [1]);
    semantics.dispose();
  });

  testWidgets('a glyph stands before its name and grows with the text', (
    tester,
  ) async {
    await _pump(tester);
    final glyph = find.byIcon(LucideIcons.layoutGrid);
    expect(glyph, findsOneWidget);
    expect(find.byIcon(LucideIcons.notebookPen), findsOneWidget);
    final small = tester.getSize(glyph).height;
    expect(
      tester.getRect(glyph).right,
      lessThan(tester.getRect(find.text('Overview')).left),
    );
    await _pump(tester, scale: 1.5);
    expect(tester.getSize(glyph).height, closeTo(small * 1.5, 0.5));
  });

  testWidgets('without a controller the page holds the choice', (tester) async {
    var tab = 0;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MinimalHost(child: child!),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => MinimalTabBar(
              tabs: const ['One', 'Two'],
              selectedIndex: tab,
              onChanged: (i) => setState(() => tab = i),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Two'));
    await tester.pumpAndSettle();
    expect(tab, 1);
  });
}

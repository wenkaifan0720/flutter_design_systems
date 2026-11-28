// A tooltip whose words repeat the name its control already gives itself
// stays out of the semantics: the top bar's Back, a labelled icon button
// under a tooltip that says Back, is heard "Back" once, as Material's
// IconButton is, not "Back, Back". A tooltip that adds words keeps them as
// the control's tooltip; excludeFromSemantics drops any.
import 'dart:async';

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';
import 'package:material_ui/material_ui.dart';

const _back = ValueKey('back');

Future<SemanticsData> _backNode(
  WidgetTester tester,
  String message, {
  bool excludeFromSemantics = false,
}) async {
  tester.view
    ..physicalSize = const Size(390, 844)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  // A pushed page: its top bar stands a way back at its start.
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => Fluent2Host(child: child!),
      home: const SizedBox(),
    ),
  );
  unawaited(
    tester
        .state<NavigatorState>(find.byType(Navigator))
        .push(
          MaterialPageRoute<void>(
            builder: (context) => Fluent2Scaffold(
              topBar: Fluent2AppBar(
                title: 'Task',
                leading: Fluent2Tooltip(
                  message: message,
                  excludeFromSemantics: excludeFromSemantics,
                  child: Fluent2IconButton(
                    Fluent2Icons.arrowLeft,
                    key: _back,
                    semanticLabel: 'Back',
                    onPressed: () {},
                  ),
                ),
              ),
              body: const SizedBox(),
            ),
          ),
        ),
  );
  await tester.pumpAndSettle();
  return tester.getSemantics(find.byKey(_back)).getSemanticsData();
}

void main() {
  testWidgets('the top bar\'s Back is heard once', (tester) async {
    final handle = tester.ensureSemantics();
    try {
      final back = await _backNode(tester, 'Back');
      expect(back.label, 'Back');
      expect(back.tooltip, isEmpty);
    } finally {
      handle.dispose();
    }
  });

  testWidgets('a tooltip that adds words keeps them', (tester) async {
    final handle = tester.ensureSemantics();
    try {
      final back = await _backNode(tester, 'Back to tasks (Alt+Left)');
      expect(back.label, 'Back');
      expect(back.tooltip, 'Back to tasks (Alt+Left)');
    } finally {
      handle.dispose();
    }
  });

  testWidgets('excludeFromSemantics drops the words', (tester) async {
    final handle = tester.ensureSemantics();
    try {
      final back = await _backNode(
        tester,
        'Back to tasks',
        excludeFromSemantics: true,
      );
      expect(back.label, 'Back');
      expect(back.tooltip, isEmpty);
    } finally {
      handle.dispose();
    }
  });
}

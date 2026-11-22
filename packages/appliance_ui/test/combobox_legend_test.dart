// A combobox says it opens a list as a select does, with the select's own
// up-and-down legend at the end of its well, and a press on that legend
// opens the list as a press on the words does.
import 'package:appliance_ui/appliance_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp, Scaffold;

const _projects = ['Open studio', 'Field guide', 'Workshop series'];

Future<void> _form(WidgetTester tester) async {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = const Size(780, 1400);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) =>
          ApplianceHost(brightness: Brightness.light, child: app!),
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ApplianceTextField(label: 'Title', onChanged: (_) {}),
              ApplianceSelect<String>(
                label: 'Project',
                value: _projects.first,
                items: [
                  for (final p in _projects)
                    ApplianceSelectItem(value: p, label: p),
                ],
                onChanged: (_) {},
              ),
              ApplianceCombobox<String>(
                label: 'Assignee',
                options: _projects,
                value: _projects.first,
                onSelected: (_) {},
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Set<Type> _painters(WidgetTester tester, Finder part) => {
  for (final paint in tester.renderObjectList<RenderCustomPaint>(
    find.descendant(of: part, matching: find.byType(CustomPaint)),
  ))
    if (paint.painter != null) paint.painter.runtimeType,
};

void main() {
  setUpAll(applianceLoadFonts);

  testWidgets('the combobox carries the select\'s legend', (tester) async {
    await _form(tester);
    final legend = _painters(tester, find.byType(ApplianceSelect<String>))
        .intersection(_painters(tester, find.byType(ApplianceCombobox<String>)))
        .difference(_painters(tester, find.byType(ApplianceTextField)));
    expect(legend, hasLength(1));
  });

  testWidgets('a press on the legend opens the list', (tester) async {
    await _form(tester);
    final legend = _painters(
      tester,
      find.byType(ApplianceSelect<String>),
    ).difference(_painters(tester, find.byType(ApplianceTextField))).single;
    final mark = find.descendant(
      of: find.byType(ApplianceCombobox<String>),
      matching: find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter.runtimeType == legend,
      ),
    );
    expect(find.text('Field guide'), findsNothing);
    await tester.tap(mark);
    await tester.pumpAndSettle();
    expect(find.text('Field guide'), findsOneWidget);
  });
}

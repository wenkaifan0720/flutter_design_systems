// One form marks a list's rows one way: the select's and the combobox's lit
// row (where the pointer or the keys are) sits down as a pressed key, with
// plain words; the chosen option's lamp is lit and its words stand in medium
// weight.
import 'package:appliance_ui/appliance_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp, Scaffold;

const _projects = ['Open studio', 'Field guide', 'Workshop series'];

Future<void> _show(WidgetTester tester, Widget part) async {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = const Size(780, 1000);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) =>
          ApplianceHost(brightness: Brightness.light, child: app!),
      home: Scaffold(
        body: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(width: 358, child: part),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _row(String words) => find.descendant(
  of: find.byType(ApplianceMenuPlate),
  matching: find.text(words),
);

ApplianceFace _face(WidgetTester tester, String words) => tester
    .widget<AnimatedApplianceSurface>(
      find
          .ancestor(
            of: _row(words),
            matching: find.byType(AnimatedApplianceSurface),
          )
          .first,
    )
    .face;

TextStyle _style(WidgetTester tester, String words) =>
    tester.widget<Text>(_row(words)).style!;

void main() {
  setUpAll(applianceLoadFonts);

  testWidgets('a select lights the row the keys are on by sinking it', (
    tester,
  ) async {
    await _show(
      tester,
      ApplianceSelect<String>(
        labelText: 'Project',
        value: _projects.first,
        items: [
          for (final p in _projects) ApplianceSelectItem(value: p, label: p),
        ],
        onChanged: (_) {},
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(_face(tester, _projects.first).lift, lessThan(0));
    expect(
      _style(tester, _projects.first).decoration,
      isNot(TextDecoration.underline),
    );
  });

  testWidgets('a combobox lights the row the keys are on the same way', (
    tester,
  ) async {
    await _show(
      tester,
      ApplianceCombobox<String>(
        labelText: 'Project',
        options: _projects,
        value: _projects.first,
        onSelected: (_) {},
      ),
    );
    await tester.tap(find.byType(EditableText));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    final lit = [
      for (final p in _projects)
        if (_face(tester, p).lift < 0) p,
    ];
    expect(lit, hasLength(1));
    for (final p in _projects) {
      expect(_style(tester, p).decoration, isNot(TextDecoration.underline));
    }
    // The chosen option keeps its own mark: medium words.
    expect(_style(tester, _projects.first).fontWeight, FontWeight.w600);
  });
}

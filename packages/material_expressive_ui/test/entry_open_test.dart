// Material Expressive's lists on ui_core 0.5.0:
// - a combobox's and a multi-select's entry says whether its list stands
//   open (expanded, then collapsed after Escape);
// - a select opened from the keys focuses its chosen option.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

Widget _app(Widget home) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, child) =>
      ExpressiveHost(brightness: Brightness.light, child: child!),
  home: Material(type: MaterialType.transparency, child: home),
);

void _phone(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.reset);
}

const _fruit = [
  ExpressiveSelectOption('Apple', 'Apple'),
  ExpressiveSelectOption('Apricot', 'Apricot'),
  ExpressiveSelectOption('Avocado', 'Avocado'),
  ExpressiveSelectOption('Banana', 'Banana'),
  ExpressiveSelectOption('Cherry', 'Cherry'),
];

Widget _high(Widget child) => Align(
  alignment: const Alignment(0, -0.8),
  child: SizedBox(width: 358, child: child),
);

void main() {
  group("a list's entry says whether the list stands open", () {
    final fields = <String, Widget Function()>{
      'ExpressiveCombobox': () =>
          const ExpressiveCombobox<String>(labelText: 'Fruit', options: _fruit),
      'ExpressiveMultiSelect': () => ExpressiveMultiSelect<String>(
        labelText: 'Fruit',
        values: const [],
        onChanged: (_) {},
        options: _fruit,
      ),
    };
    for (final MapEntry(key: name, value: field) in fields.entries) {
      testWidgets(name, (tester) async {
        final semantics = tester.ensureSemantics();
        _phone(tester);
        await tester.pumpWidget(_app(_high(field())));
        await tester.pumpAndSettle();
        final entry = find.byType(EditableText);
        expect(
          tester.getSemantics(entry),
          isSemantics(
            isTextField: true,
            hasExpandedState: true,
            isExpanded: false,
          ),
        );
        await tester.tap(entry);
        await tester.enterText(entry, 'A');
        await tester.pumpAndSettle();
        expect(find.text('Apricot'), findsWidgets);
        expect(
          tester.getSemantics(entry),
          isSemantics(
            isTextField: true,
            hasExpandedState: true,
            isExpanded: true,
          ),
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(
          tester.getSemantics(entry),
          isSemantics(
            isTextField: true,
            hasExpandedState: true,
            isExpanded: false,
          ),
        );
        semantics.dispose();
      });
    }
  });

  testWidgets('a select opened from the keys focuses its chosen option', (
    tester,
  ) async {
    _phone(tester);
    final focus = FocusNode();
    addTearDown(focus.dispose);
    await tester.pumpWidget(
      _app(
        _high(
          ExpressiveSelect<String>(
            labelText: 'Room',
            options: const [
              ExpressiveSelectOption('k', 'Kitchen'),
              ExpressiveSelectOption('s', 'Study'),
              ExpressiveSelectOption('b', 'Bedroom'),
              ExpressiveSelectOption('g', 'Garden'),
              ExpressiveSelectOption('h', 'Hall'),
            ],
            value: 'b',
            focusNode: focus,
            onChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    focus.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    // The focused item is the chosen option's row.
    final focused = FocusManager.instance.primaryFocus!.context!;
    final box = focused.findRenderObject()! as RenderBox;
    final row = box.localToGlobal(Offset.zero) & box.size;
    final semantics = tester.ensureSemantics();
    expect(
      row.contains(tester.getCenter(find.bySemanticsLabel('Bedroom').last)),
      isTrue,
    );
    semantics.dispose();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
  });
}

// Ledger's lists on ui_core 0.5.0:
// - a combobox's and a multi-select's entry says whether its list stands
//   open (expanded, then collapsed after Escape);
// - a select opened from the keys focuses its chosen option, in view.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_ui.dart';

Widget _app(Widget home) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, child) =>
      LedgerHost(brightness: Brightness.light, child: child!),
  home: Material(type: MaterialType.transparency, child: home),
);

void _phone(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.reset);
}

const _fruit = ['Apple', 'Apricot', 'Avocado', 'Banana', 'Cherry'];

Widget _high(Widget child) => Align(
  alignment: const Alignment(0, -0.8),
  child: SizedBox(width: 358, child: child),
);

void main() {
  group("a list's entry says whether the list stands open", () {
    final fields = <String, Widget Function()>{
      'LedgerCombobox': () =>
          const LedgerCombobox<String>(labelText: 'Fruit', options: _fruit),
      'LedgerMultiSelect': () => LedgerMultiSelect<String>(
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
          LedgerSelect<String>(
            labelText: 'Room',
            items: [
              for (final (v, l) in const [
                ('k', 'Kitchen'),
                ('s', 'Study'),
                ('b', 'Bedroom'),
                ('g', 'Garden'),
                ('h', 'Hall'),
                ('l', 'Loft'),
                ('c', 'Cellar'),
                ('a', 'Attic'),
              ])
                LedgerSelectItem(value: v, label: l),
            ],
            value: 'b',
            focusNode: focus,
            onChanged: (_) {},
          ),
        ),
      ),
    );
    focus.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    final focused = FocusManager.instance.primaryFocus;
    expect(focused?.debugLabel, 'Bedroom');
    // In view: inside the list's paper.
    final row = tester.getRect(find.byWidget(focused!.context!.widget));
    expect(tester.binding.renderViews.first.size.contains(row.center), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
  });
}

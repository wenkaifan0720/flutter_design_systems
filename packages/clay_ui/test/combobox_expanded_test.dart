// A combobox's and a tag input's text field says whether their list is open:
// its node reads expanded while the options show under it and collapsed once
// Escape closes them, and the combobox's chevron turns with the list, not
// with the focus.
import 'package:clay_ui/clay_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:clay_ui/clay_parts.dart' show ClayChevronPainter;

Widget _app(Widget home, {Brightness brightness = Brightness.light}) =>
    MaterialApp(
      builder: (context, app) =>
          ClayTheme(data: ClayThemeData.clay(brightness), child: app!),
      home: home,
    );

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

const _habits = ['Drink water', 'Stretch', 'Read', 'Walk', 'Journal'];

double _chevron(WidgetTester tester) => tester
    .widgetList<CustomPaint>(find.byType(CustomPaint))
    .map((p) => p.painter)
    .whereType<ClayChevronPainter>()
    .single
    .open;

void main() {
  final fields = <String, Widget Function()>{
    'combobox': () => ClayCombobox<String>(
      options: _habits,
      semanticLabel: 'Habit',
      onSelected: (_) {},
    ),
    'tag input': () => ClayTagInput<String>(
      values: const [],
      options: _habits,
      semanticLabel: 'Tags',
      onChanged: (_) {},
    ),
  };
  for (final MapEntry(key: kind, value: field) in fields.entries) {
    testWidgets('a $kind field reads expanded while its list shows', (
      tester,
    ) async {
      _phone(tester);
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(
          Align(
            alignment: Alignment.topCenter,
            child: Padding(padding: const EdgeInsets.all(24), child: field()),
          ),
        ),
      );
      final input = find.byType(EditableText);
      expect(
        tester.getSemantics(input),
        isSemantics(
          isTextField: true,
          hasExpandedState: true,
          isExpanded: false,
        ),
      );
      await tester.tap(input);
      await tester.pumpAndSettle();
      expect(find.text('Stretch'), findsOneWidget, reason: 'the list opens');
      expect(
        tester.getSemantics(input),
        isSemantics(
          isTextField: true,
          hasExpandedState: true,
          isExpanded: true,
        ),
      );
      if (kind == 'combobox') expect(_chevron(tester), 1);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Stretch'), findsNothing, reason: 'Escape closes it');
      expect(
        tester.getSemantics(input),
        isSemantics(
          isTextField: true,
          hasExpandedState: true,
          isExpanded: false,
        ),
      );
      // The focus stays on the field; the chevron turns back with the list.
      if (kind == 'combobox') expect(_chevron(tester), 0);
      semantics.dispose();
    });
  }
}

// A combobox's and a tag input's text field says whether their list is open:
// its node reads expanded while the options show under it and collapsed once
// Escape closes them, and the combobox's chevron turns with the list, not
// with the focus.
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keycap_ui/keycap_parts.dart' show KeycapSpringValue;
import 'package:keycap_ui/keycap_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:lucide_icons_flutter/lucide_icons.dart';

Widget _app(Widget home, {Brightness brightness = Brightness.light}) =>
    MaterialApp(
      builder: (context, app) =>
          KeycapHost(brightness: brightness, child: app!),
      home: home,
    );

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

const _folders = ['Groceries', 'Reading list', 'Ideas', 'Work', 'Travel'];

// The turn the chevron springs to.
double _chevron(WidgetTester tester) => tester
    .widget<KeycapSpringValue>(
      find.ancestor(
        of: find.byIcon(LucideIcons.chevronDown),
        matching: find.byType(KeycapSpringValue),
      ),
    )
    .value;

void main() {
  final fields = <String, Widget Function()>{
    'combobox': () => KeycapCombobox<String>(
      options: _folders,
      semanticLabel: 'Folder',
      onSelected: (_) {},
    ),
    'tag input': () => KeycapTagInput<String>(
      values: const [],
      options: _folders,
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
      expect(find.text('Ideas'), findsOneWidget, reason: 'the list opens');
      expect(
        tester.getSemantics(input),
        isSemantics(
          isTextField: true,
          hasExpandedState: true,
          isExpanded: true,
        ),
      );
      if (kind == 'combobox') expect(_chevron(tester), 0.5);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Ideas'), findsNothing, reason: 'Escape closes it');
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

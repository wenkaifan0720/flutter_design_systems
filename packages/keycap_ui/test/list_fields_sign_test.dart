// Every field that opens a list ends in one sign, the select's chevron: a
// combobox beside a select in one form reads as the same kind of field, and
// a combobox says it opens a list before it is typed in.
// ignore_for_file: avoid_relative_lib_imports
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keycap_ui/keycap_ui.dart';
import 'package:material_ui/material_ui.dart' show Material;

import '../example/lib/kit_gallery/kit.dart';

IconData? _sign(WidgetTester tester, Finder field) => tester
    .widgetList<Icon>(find.descendant(of: field, matching: find.byType(Icon)))
    .last
    .icon;

void main() {
  testWidgets('a combobox ends in the select\'s chevron', (tester) async {
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(780, 1000);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      kitApp(
        brightness: Brightness.light,
        home: Material(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                KeycapSelect<String>(
                  labelText: 'Folder',
                  value: 'Work',
                  items: const [
                    KeycapSelectItem(value: 'Work', label: 'Work'),
                    KeycapSelectItem(value: 'Home', label: 'Home'),
                  ],
                  onChanged: (_) {},
                ),
                const SizedBox(height: 24),
                KeycapCombobox<String>(
                  labelText: 'Tag',
                  options: const ['Draft', 'Recipe'],
                  onSelected: (_) {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final select = _sign(tester, find.byType(KeycapSelect<String>));
    expect(select, isNotNull);
    expect(_sign(tester, find.byType(KeycapCombobox<String>)), select);
  });
}

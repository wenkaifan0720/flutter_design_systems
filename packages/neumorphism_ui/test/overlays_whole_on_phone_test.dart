// Each of Neumorphism's selects, lists and pickers opens whole on a phone (390 x 844) with its field high, in the
// middle and low on the screen: on the screen, nothing in it cut (DesignOverlayCheck).
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';
import 'package:neumorphism_ui/neumorphism_host.dart';
import 'package:ui_core_review/ui_core_review.dart' show DesignOverlayCheck;

import 'support.dart';

const _rooms = [
  'Kitchen',
  'Study',
  'Hall',
  'Landing',
  'Bedroom',
  'Bathroom',
  'Garden room',
  'Cellar',
];

Widget _app(double above, Widget field) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, app) =>
      NeumorphicHost(brightness: Brightness.light, child: app!),
  home: Scaffold(
    body: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: above),
          field,
        ],
      ),
    ),
  ),
);

void main() {
  setUpAll(loadNeumorphicFonts);

  final cases = <String, Widget Function()>{
    'select': () => NeumorphicSelect<int>(
      labelText: 'Repeat every',
      value: 3,
      options: [for (var i = 1; i <= 14; i++) NeumorphicMenuItem(i, '$i days')],
      onChanged: (_) {},
    ),
    'combobox': () => NeumorphicCombobox<String>(
      labelText: 'Room',
      options: _rooms,
      onSelected: (_) {},
    ),
    'multi-select': () => NeumorphicMultiSelect<String>(
      labelText: 'Rooms',
      values: const [],
      options: _rooms,
      onChanged: (_) {},
    ),
    'date picker': () => Builder(
      builder: (context) => NeumorphicButton(
        'Arrival',
        onPressed: () => showNeumorphicDatePicker(
          context,
          value: DateTime(2026, 11, 20),
          currentDate: DateTime(2026, 11, 2),
        ),
      ),
    ),
  };
  for (final MapEntry(key: kind, value: build) in cases.entries) {
    for (final (where, above) in [
      ('high', 40.0),
      ('middle', 380.0),
      ('low', 720.0),
    ]) {
      testWidgets('a $kind opened $where on a phone', (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final field = build();
        await tester.pumpWidget(_app(above, field));
        await tester.pumpAndSettle();
        final editable = find.descendant(
          of: find.byWidget(field),
          matching: find.byType(EditableText),
        );
        if (editable.evaluate().isNotEmpty) {
          await tester.tap(editable.first);
          await tester.enterText(editable.first, 'a');
        } else {
          await tester.tap(find.byWidget(field));
        }
        await tester.pumpAndSettle();
        const DesignOverlayCheck(look: 'Neumorphism')
            .check(tester.element(find.byWidget(field)))
            .verify();
      });
    }
  }
}

// Each of Minimal's pickers, menus, selects and lists opens whole on a phone
// (390 × 844) with its field high, in the middle and low on the screen: on
// the screen, nothing in it cut, and no month shrunk to scroll where the
// other side of its field holds it whole (DesignOverlayCheck).
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';
import 'package:ui_core_review/ui_core_review.dart';

const _habits = [
  'Drink water',
  'Stretch',
  'Read',
  'Walk',
  'Journal',
  'Meditate',
  'Floss',
  'Sleep by 11',
];

Widget _app(double above, Widget field) => MaterialApp(
  builder: (context, app) => MinimalHost(
    light: MinimalThemeData.preset('standard', Brightness.light),
    dark: MinimalThemeData.preset('standard', Brightness.dark),
    brightness: Brightness.light,
    child: app!,
  ),
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
  final cases = <String, Widget Function()>{
    'date range picker': () => MinimalDateRangePicker(
      labelText: 'Away',
      value: RawDateRange(DateTime(2026, 11, 20), DateTime(2026, 11, 24)),
      firstDate: DateTime(2026),
      lastDate: DateTime(2027, 12, 31),
      onChanged: (_) {},
    ),
    'select': () => MinimalSelect<int>(
      labelText: 'Repeat every',
      value: 3,
      options: [
        for (var i = 1; i <= 14; i++) MinimalSelectOption(i, '$i days'),
      ],
      onChanged: (_) {},
    ),
    'combobox': () => MinimalCombobox<String>(
      labelText: 'Habit',
      options: _habits,
      onSelected: (_) {},
    ),
    'multi-select': () => MinimalMultiSelect<String>(
      labelText: 'Tags',
      values: const [],
      options: _habits,
      onChanged: (_) {},
    ),
    'menu': () => Align(
      alignment: AlignmentDirectional.centerStart,
      child: MinimalMenu.button(
        Icons.more_horiz,
        label: 'Habit actions',
        items: [
          for (final h in _habits.take(5)) MinimalMenuItem(h, onPressed: () {}),
          MinimalMenuItem(
            'Delete',
            onPressed: () {},
            isDestructiveAction: true,
          ),
        ],
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
        await tester.tap(
          editable.evaluate().isNotEmpty
              ? editable.first
              : find
                    .descendant(
                      of: find.byWidget(field),
                      matching: find.byType(MinimalPressable),
                    )
                    .first,
        );
        await tester.pumpAndSettle();
        const DesignOverlayCheck(look: 'Minimal')
            .check(tester.element(find.byWidget(field)))
            .verify();
      });
    }
  }
}

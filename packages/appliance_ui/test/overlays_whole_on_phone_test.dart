// Each of Appliance's pickers, selects, lists and menus opens whole on a
// phone (390 × 844) with its field high, in the middle and low on the
// screen: on the screen, nothing in it cut, and no month shrunk to scroll
// where the other side of its field holds it whole (DesignOverlayCheck).
import 'package:appliance_ui/appliance_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core_test/ui_core_test.dart';

const _goods = [
  'Kettle',
  'Toaster',
  'Teapot',
  'Mixing bowl',
  'Bread bin',
  'Scales',
  'Colander',
  'Oven gloves',
];

Widget _app(double above, Widget field) => MaterialApp(
  builder: (context, app) =>
      ApplianceHost(brightness: Brightness.light, child: app!),
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
  setUpAll(applianceLoadFonts);
  final cases = <String, Widget Function()>{
    'date picker': () => ApplianceDatePicker(
      labelText: 'Delivery day',
      value: DateTime(2026, 11, 20),
      firstDate: DateTime(2026),
      lastDate: DateTime(2027, 12, 31),
      onChanged: (_) {},
    ),
    'date range picker': () => ApplianceDateRangePicker(
      labelText: 'Away',
      value: RawDateRange(DateTime(2026, 11, 20), DateTime(2026, 11, 24)),
      firstDate: DateTime(2026),
      lastDate: DateTime(2027, 12, 31),
      onChanged: (_) {},
    ),
    'select': () => ApplianceSelect<int>(
      labelText: 'Deliver every',
      value: 3,
      items: [
        for (var i = 1; i <= 14; i++)
          ApplianceSelectItem(value: i, label: '$i days'),
      ],
      onChanged: (_) {},
    ),
    'combobox': () => ApplianceCombobox<String>(
      labelText: 'Item',
      options: _goods,
      onSelected: (_) {},
    ),
    'tag input': () => ApplianceTagInput<String>(
      labelText: 'Rooms',
      values: const [],
      options: _goods,
      onChanged: (_) {},
    ),
    'menu': () => Align(
      alignment: AlignmentDirectional.centerStart,
      child: ApplianceMenu(
        semanticLabel: 'Item actions',
        entries: [
          for (final g in _goods.take(5))
            RawMenuEntry(label: g, onPressed: () {}),
        ],
        builder: (context, anchor) => ApplianceIconButton(
          icon: const Icon(Icons.more_horiz),
          semanticLabel: 'More',
          onPressed: anchor.toggle,
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
        final button = find.descendant(
          of: find.byWidget(field),
          matching: find.byType(ApplianceIconButton),
        );
        await tester.tap(
          editable.evaluate().isNotEmpty
              ? editable.first
              : button.evaluate().isNotEmpty
              ? button.first
              : find.byWidget(field),
        );
        await tester.pumpAndSettle();
        const DesignOverlayCheck(look: 'Appliance')
            .check(tester.element(find.byWidget(field)))
            .verify();
      });
    }
  }
}

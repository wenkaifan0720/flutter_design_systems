// Each of Retro Desktop's selects, lists and pickers opens whole on a phone (390 x 844) with its field high, in the
// middle and low on the screen: on the screen, nothing in it cut (DesignOverlayCheck).
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';
import 'package:retro_desktop_ui/retro_desktop_host.dart';
import 'package:ui_core_review/ui_core_review.dart' show DesignOverlayCheck;

import 'support.dart';

const _folders = [
  'Applications',
  'Documents',
  'Downloads',
  'Desktop',
  'Library',
  'Movies',
  'Music',
  'Pictures',
];

Widget _app(double above, Widget field) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, app) =>
      RetroDesktopHost(brightness: Brightness.light, child: app!),
  home: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: above),
        field,
      ],
    ),
  ),
);

void main() {
  setUpAll(loadRetroDesktopFonts);

  final cases = <String, Widget Function()>{
    'select': () => RetroDesktopSelect<int>(
      labelText: 'Repeat every',
      value: 3,
      options: [for (var i = 1; i <= 14; i++) RetroDesktopOption(i, '$i days')],
      onChanged: (_) {},
    ),
    'combobox': () => RetroDesktopCombobox<String>(
      labelText: 'Folder',
      options: _folders,
      onSelected: (_) {},
    ),
    'date picker': () => Builder(
      builder: (context) => RetroDesktopButton(
        'Arrival',
        onPressed: () => showRetroDesktopDatePicker(
          context,
          value: DateTime(2026, 11, 20),
          today: DateTime(2026, 11, 2),
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
          await tester.enterText(editable.first, 'D');
        } else {
          await tester.tap(find.byWidget(field));
        }
        await tester.pumpAndSettle();
        const DesignOverlayCheck(look: 'Retro Desktop')
            .check(tester.element(find.byWidget(field)))
            .verify();
      });
    }
  }
}

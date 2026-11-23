// Every field that opens a list or a calendar from its face ends in one
// sign: the select, the combobox and the date range picker all end in the
// up-down chevron.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'support/centred_host.dart';

Finder _glyph(IconData icon) =>
    find.byWidgetPredicate((w) => w is MinimalIcon && w.icon == icon);

void main() {
  final fields = <String, Widget>{
    'select': MinimalSelect<int>(
      labelText: 'Repeats',
      value: 1,
      options: const [MinimalSelectOption(1, 'Every day')],
      onChanged: (_) {},
    ),
    'combobox': MinimalCombobox<String>(
      labelText: 'Habit',
      options: const ['Read', 'Walk'],
      onSelected: (_) {},
    ),
    'date range picker': MinimalDateRangePicker(
      labelText: 'Away',
      firstDate: DateTime(2026),
      lastDate: DateTime(2027, 12, 31),
      onChanged: (_) {},
    ),
  };
  for (final MapEntry(key: kind, value: field) in fields.entries) {
    testWidgets('a $kind ends in the up-down chevron', (tester) async {
      await tester.pumpWidget(centredHost(SizedBox(width: 360, child: field)));
      expect(_glyph(LucideIcons.chevronsUpDown), findsOneWidget);
      expect(_glyph(LucideIcons.chevronDown), findsNothing);
    });
  }
}

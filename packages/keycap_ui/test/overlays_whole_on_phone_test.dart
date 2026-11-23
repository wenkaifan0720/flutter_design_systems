// Each of Keycap's pickers, menus, selects, sheets and dialogs opens whole on a
// phone (390 × 844) with its anchor high, in the middle and low on the
// screen: on the screen, nothing in it cut, and no month shrunk to scroll
// where the other side of its field holds it whole (DesignOverlayCheck).
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keycap_ui/keycap_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:ui_core_test/ui_core_test.dart';

const _habits = [
  'Groceries',
  'Reading list',
  'Ideas',
  'Work',
  'Travel',
  'Recipes',
  'Journal',
  'Archive',
];

typedef _Case = ({Widget Function() build, bool tapFoot});

void main() {
  Widget key(String words, VoidCallback onPressed) =>
      KeycapButton(onPressed: onPressed, child: Text(words));
  final cases = <String, _Case>{
    'date picker': (
      build: () => KeycapDatePicker(
        labelText: 'Remind me on',
        value: DateTime(2026, 11, 20),
        firstDate: DateTime(2026),
        lastDate: DateTime(2027, 12, 31),
        onChanged: (_) {},
      ),
      tapFoot: true,
    ),
    'date range picker': (
      build: () => KeycapDateRangePicker(
        labelText: 'Show notes from',
        value: RawDateRange(DateTime(2026, 11, 20), DateTime(2026, 11, 24)),
        firstDate: DateTime(2026),
        lastDate: DateTime(2027, 12, 31),
        onChanged: (_) {},
      ),
      tapFoot: true,
    ),
    'time picker': (
      build: () => KeycapTimePicker(
        labelText: 'Remind me at',
        value: const RawTimeOfDay(hour: 8, minute: 0),
        onChanged: (_) {},
      ),
      tapFoot: true,
    ),
    'select': (
      build: () => KeycapSelect<int>(
        labelText: 'Keep notes for',
        items: [
          for (var i = 1; i <= 14; i++)
            KeycapSelectItem(value: i, label: '$i days'),
        ],
        value: 3,
        onChanged: (_) {},
      ),
      tapFoot: true,
    ),
    'combobox': (
      build: () => KeycapCombobox<String>(
        labelText: 'Folder',
        options: _habits,
        onSelected: (_) {},
      ),
      tapFoot: true,
    ),
    'tag input': (
      build: () => KeycapTagInput<String>(
        labelText: 'Tags',
        values: const [],
        options: _habits,
        onChanged: (_) {},
      ),
      tapFoot: true,
    ),
    'menu': (
      build: () => KeycapMenu(
        entries: [
          for (final h in _habits.take(5))
            RawMenuEntry(label: h, onPressed: () {}),
          RawMenuEntry(
            label: 'Delete',
            onPressed: () {},
            isDestructiveAction: true,
          ),
        ],
        builder: (context, anchor) => key('More', anchor.toggle),
      ),
      tapFoot: false,
    ),
    'bottom sheet': (
      build: () => Builder(
        builder: (context) => key(
          'Reminder',
          () => showKeycapBottomSheet<void>(
            context: context,
            title: 'Reminder time',
            builder: (context) => const Text('A nudge at 8:00 each morning.'),
            footer: [key('Save', () {})],
          ),
        ),
      ),
      tapFoot: false,
    ),
    'action sheet': (
      build: () => Builder(
        builder: (context) => key(
          'Actions',
          () => showKeycapActionSheet(
            context: context,
            title: 'Groceries',
            actions: [
              KeycapSheetAction('Pin', onPressed: () {}),
              KeycapSheetAction(
                'Delete',
                onPressed: () {},
                isDestructiveAction: true,
              ),
            ],
          ),
        ),
      ),
      tapFoot: false,
    ),
    'dialog': (
      build: () => Builder(
        builder: (context) => key(
          'Delete',
          () => showKeycapDialog<void>(
            context: context,
            builder: (context) => KeycapDialog(
              title: 'Delete this note?',
              content: const Text('Its 12 links go with it.'),
              actions: [
                key('Keep', () {}),
                KeycapButton.accent(
                  isDestructiveAction: true,
                  onPressed: () {},
                  child: const Text('Delete'),
                ),
              ],
            ),
          ),
        ),
      ),
      tapFoot: false,
    ),
  };
  for (final MapEntry(key: kind, value: c) in cases.entries) {
    for (final (where, above) in const [
      ('high', 24.0),
      ('in the middle', 380.0),
      ('low', 700.0),
    ]) {
      testWidgets('a $kind opened $where on a phone shows whole', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final anchor = c.build();
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, app) =>
                KeycapHost(brightness: Brightness.light, child: app!),
            home: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: above),
                  anchor,
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final at = tester.getRect(find.byWidget(anchor));
        if (c.tapFoot) {
          await tester.tapAt(at.bottomCenter - const Offset(0, 16));
        } else {
          await tester.tap(find.byType(KeycapButton).first);
        }
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        const DesignOverlayCheck(look: 'Keycap')
            .check(tester.element(find.byWidget(anchor)))
            .verify();
      });
    }
  }
}

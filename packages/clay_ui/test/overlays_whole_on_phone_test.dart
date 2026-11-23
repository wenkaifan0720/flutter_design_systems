// Each of Clay's pickers, menus, selects, sheets and dialogs opens whole on a
// phone (390 × 844) with its anchor high, in the middle and low on the
// screen: on the screen, nothing in it cut, and no month shrunk to scroll
// where the other side of its field holds it whole (DesignOverlayCheck).
import 'package:clay_ui/clay_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:ui_core_test/ui_core_test.dart';

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

typedef _Case = ({Widget Function() build, bool tapFoot});

void main() {
  final cases = <String, _Case>{
    'date picker': (
      build: () => ClayDatePicker(
        labelText: 'Starts on',
        value: DateTime(2026, 11, 20),
        firstDate: DateTime(2026),
        lastDate: DateTime(2027, 12, 31),
        onChanged: (_) {},
      ),
      tapFoot: true,
    ),
    'date range picker': (
      build: () => ClayDateRangePicker(
        labelText: 'Away',
        value: ClayDateRange(
          start: DateTime(2026, 11, 20),
          end: DateTime(2026, 11, 24),
        ),
        firstDate: DateTime(2026),
        lastDate: DateTime(2027, 12, 31),
        onChanged: (_) {},
      ),
      tapFoot: true,
    ),
    'select': (
      build: () => ClaySelect<int>(
        labelText: 'Repeat every',
        items: [
          for (var i = 1; i <= 14; i++)
            ClaySelectItem(value: i, label: '$i days'),
        ],
        value: 3,
        onChanged: (_) {},
      ),
      tapFoot: true,
    ),
    'combobox': (
      build: () => ClayCombobox<String>(
        labelText: 'Habit',
        options: _habits,
        onSelected: (_) {},
      ),
      tapFoot: true,
    ),
    'tag input': (
      build: () => ClayTagInput<String>(
        labelText: 'Tags',
        values: const [],
        options: _habits,
        onChanged: (_) {},
      ),
      tapFoot: true,
    ),
    'menu': (
      build: () => ClayMenu(
        items: [
          for (final h in _habits.take(5))
            ClayMenuItem(label: h, onPressed: () {}),
          ClayMenuItem(
            label: 'Delete',
            onPressed: () {},
            isDestructiveAction: true,
          ),
        ],
        builder: (context, toggle, open) =>
            ClayButton('More', onPressed: toggle),
      ),
      tapFoot: false,
    ),
    'bottom sheet': (
      build: () => Builder(
        builder: (context) => ClayButton(
          'Reminder',
          onPressed: () => showClayBottomSheet<void>(
            context: context,
            title: 'Reminder time',
            builder: (context) => const Text('A nudge at 8:00 each morning.'),
            footerBuilder: (context) => ClayButton('Save', onPressed: () {}),
          ),
        ),
      ),
      tapFoot: false,
    ),
    'action sheet': (
      build: () => Builder(
        builder: (context) => ClayButton(
          'Actions',
          onPressed: () => showClayActionSheet<String>(
            context: context,
            title: 'Drink water',
            actions: const [
              ClaySheetAction(label: 'Pause', value: 'pause'),
              ClaySheetAction(
                label: 'Delete',
                value: 'delete',
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
        builder: (context) => ClayButton(
          'Delete',
          onPressed: () => showClayDialog<void>(
            context: context,
            builder: (context) => ClayDialog(
              title: 'Delete this habit?',
              content: const Text('Its 42-day streak goes with it.'),
              actions: [
                ClayDialogAction(label: 'Keep', onPressed: () {}),
                ClayDialogAction(
                  label: 'Delete',
                  onPressed: () {},
                  isDefaultAction: true,
                  isDestructiveAction: true,
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
            builder: (context, app) => ClayTheme(
              data: ClayThemeData.clay(Brightness.light),
              child: app!,
            ),
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
          await tester.tap(find.byType(ClayButton).first);
        }
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final report = const DesignOverlayCheck(look: 'Clay')
            .check(tester.element(find.byWidget(anchor)));
        // A phone's sheet runs its slab a corner's height past the screen's
        // foot, cut there, so only its top corners show; the check reads the
        // slab's box, not the cut. Its content stands on the screen.
        final problems = [
          for (final p in report.problems)
            if (!(kind == 'bottom sheet' &&
                p.contains("runs past the screen's foot by 32 px")))
              p,
        ];
        expect(problems, isEmpty);
        if (kind == 'bottom sheet') {
          for (final words in ['Reminder time', 'Save']) {
            expect(tester.getRect(find.text(words)).bottom, lessThan(844));
          }
        }
      });
    }
  }
}

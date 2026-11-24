import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/inventory.dart';

import 'behaviour_harness.dart';

// Every row answered: the B rows live, the rest gaps with a reason.
List<RawInventoryEntry> _complete() => [
  for (final row in RawInventoryRow.all)
    row.isBehaviour
        ? RawInventoryEntry.present(row.id, (context) => Text('live ${row.id}'))
        : RawInventoryEntry.absent(row.id, 'Out of this look\'s vocabulary'),
];

RawInventory _bare(List<RawInventoryEntry> entries) =>
    RawInventory(look: 'Bare', entries: entries);

// A look's classes, as small as a class can be.
/// A look's button.
class BareButton extends StatelessWidget {
  /// A button.
  const BareButton({super.key});

  @override
  Widget build(BuildContext context) => const Text('Save');
}

/// A look's select.
class BareSelect<T> extends StatelessWidget {
  /// A select.
  const BareSelect({super.key});

  @override
  Widget build(BuildContext context) => const Text('Pick');
}

void main() {
  test(
    'the rows: 89, ids unique labels, every group known, the B rows named',
    () {
      final rows = RawInventoryRow.all;
      expect(rows, hasLength(89));
      expect(rows.map((r) => r.id).toSet(), hasLength(89));
      expect(
        rows.every((r) => RegExp(r'^[A-Z][A-Za-z]*$').hasMatch(r.id)),
        isTrue,
        reason: 'an id reads as a component\'s name',
      );
      expect(
        rows.every((r) => RawInventoryRow.groups.contains(r.group)),
        isTrue,
      );
      // 0.3.0: 26, and the overlays' tooltip and context menu; the routes'
      // dialog, bottom sheet, tab bar and the shell's navigation bar, rail,
      // drawer and scaffold; the values' number field, rating, wheel and
      // time pickers and five charts. 0.3.3: the segmented control, on the
      // toggle group as the toggle group's row is.
      expect(rows.where((r) => r.isBehaviour), hasLength(45));
      // Material's names where Material has the thing, shadcn's where only
      // shadcn does.
      for (final id in [
        'Button',
        'TextField',
        'Select',
        'SegmentedButton',
        'NavigationBar',
        'TabBar',
        'DataTable',
        'SnackBar',
        'Dialog',
        'Combobox',
        'Popover',
        'HoverCard',
        'Command',
        'Resizable',
        'ScrollArea',
        'Breadcrumb',
        'InputOtp',
        'ToggleGroup',
        'Sheet',
      ]) {
        expect(RawInventoryRow.byId(id), isNotNull, reason: id);
      }
      expect(RawInventoryRow.byId('InputOtp'), same(RawInventoryRow.inputOtp));
      expect(RawInventoryRow.byId('otp'), isNull);
    },
  );

  test('a complete inventory verifies', () {
    final inventory = _bare(_complete());
    expect(inventory.problems, isEmpty);
    inventory.verify();
    // 0.3.0: overlays 2, routes 7, values 9. 0.3.3: the segmented control.
    expect(inventory.presentCount, 45);
    expect(inventory.absentCount, 44);
  });

  test('it names every way an inventory is wrong', () {
    final entries = _complete()
      ..removeWhere((e) => e.row == 'FloatingActionButton' || e.row == 'Kbd')
      ..add(const RawInventoryEntry('Kbd'))
      ..add(RawInventoryEntry('Link', builder: (_) => const Text('x')))
      ..add(
        RawInventoryEntry(
          'Meter',
          builder: (_) => const Text('x'),
          absentReason: 'both',
        ),
      )
      ..add(const RawInventoryEntry.absent('CarouselView', 'Not built yet'))
      ..add(const RawInventoryEntry.absent('Tooltip', 'TODO'))
      ..add(const RawInventoryEntry.absent('fancyThing', 'unknown'))
      ..add(const RawInventoryEntry.absent('fab', 'An old id'));
    final inventory = RawInventory(look: 'Broken', entries: entries);
    final problems = inventory.problems.join('\n');
    expect(problems, contains('FloatingActionButton: missing'));
    expect(
      problems,
      contains('Kbd: neither a live specimen nor a reason it is absent'),
    );
    expect(problems, contains('Link: answered more than once'));
    expect(
      problems,
      contains('Meter: both a live specimen and a reason it is absent'),
    );
    expect(problems, contains('CarouselView: "Not built yet" is a to-do'));
    expect(problems, contains('Tooltip: "TODO" is a to-do'));
    expect(problems, contains('unknown row id "fancyThing"'));
    expect(problems, contains('unknown row id "fab"'));
    expect(
      inventory.verify,
      throwsA(
        isA<RawInventoryError>().having(
          (e) => e.toString(),
          'message',
          contains('Broken inventory'),
        ),
      ),
    );
  });

  test('a real reason with a soft word in it is a reason', () {
    const entry = RawInventoryEntry.absent(
      'FloatingActionButton',
      'Material vocabulary; a later Material spec moved it to the app bar',
    );
    final inventory = _bare([
      ..._complete().where((e) => e.row != 'FloatingActionButton'),
      entry,
    ]);
    expect(inventory.problems, isEmpty);
  });

  List<RawInventoryEntry> answer(Map<String, WidgetBuilder> present) => [
    for (final row in RawInventoryRow.all)
      present.containsKey(row.id)
          ? RawInventoryEntry.present(row.id, present[row.id]!)
          : RawInventoryEntry.absent(row.id, 'Out of this look\'s vocabulary'),
  ];

  test('a specimen may be any class: the inventory names none', () {
    _bare(
      answer({
        'Button': (_) => const BareButton(),
        'Link': (_) => const Text('Terms'),
      }),
    ).verify();
  });

  testWidgets(
    'the gallery heads a specimen with its class, and lists deliberate '
    'absences',
    (tester) async {
      final inventory = _bare(
        answer({
          'Button': (_) => const BareButton(),
          'Select': (_) => const BareSelect<String>(),
          'SnackBar': (_) => const Text('live SnackBar'),
        }).where((e) => e.row != 'Card').toList(),
      );
      await tester.pumpWidget(
        harness(RawInventoryGallery(inventory: inventory)),
      );
      expect(find.text('Actions (1/8)'), findsOneWidget);
      expect(
        find.text('BareButton · Button (filled/outlined/text/danger)'),
        findsOneWidget,
      );
      expect(find.text('Icon button'), findsOneWidget, reason: 'an absent row');
      expect(
        find.text('Deliberately absent: Out of this look\'s vocabulary'),
        findsWidgets,
      );
      // Type arguments aside.
      await tester.scrollUntilVisible(
        find.textContaining('BareSelect · '),
        400,
      );
      await tester.scrollUntilVisible(find.text('live SnackBar'), 400);
      expect(find.text('live SnackBar'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Missing: the inventory does not answer this row'),
        -400,
      );
    },
  );

  testWidgets('a gallery of the behaviour rows only', (tester) async {
    await tester.pumpWidget(
      harness(
        RawInventoryGallery(inventory: _bare(_complete()), behaviourOnly: true),
      ),
    );
    expect(find.text('live ToggleGroup'), findsOneWidget);
    expect(find.textContaining('Deliberately absent'), findsNothing);
  });
}

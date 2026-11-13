import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/inventory.dart';

import 'behaviour_harness.dart';

// Every row answered: the B rows live, the rest gaps with a reason.
List<DesignInventoryEntry> _complete() => [
  for (final row in DesignInventoryRow.all)
    row.isBehaviour
        ? DesignInventoryEntry.present(
            row.id,
            (context) => Text('live ${row.id}'),
          )
        : DesignInventoryEntry.absent(row.id, 'Out of this look\'s vocabulary'),
];

DesignInventory _bare(List<DesignInventoryEntry> entries) =>
    DesignInventory(look: 'Bare', entries: entries);

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
      final rows = DesignInventoryRow.all;
      expect(rows, hasLength(89));
      expect(rows.map((r) => r.id).toSet(), hasLength(89));
      expect(
        rows.every((r) => RegExp(r'^[A-Z][A-Za-z]*$').hasMatch(r.id)),
        isTrue,
        reason: 'an id reads as a component\'s name',
      );
      expect(
        rows.every((r) => DesignInventoryRow.groups.contains(r.group)),
        isTrue,
      );
      expect(rows.where((r) => r.isBehaviour), hasLength(26));
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
        expect(DesignInventoryRow.byId(id), isNotNull, reason: id);
      }
      expect(
        DesignInventoryRow.byId('InputOtp'),
        same(DesignInventoryRow.inputOtp),
      );
      expect(DesignInventoryRow.byId('otp'), isNull);
    },
  );

  test('a complete inventory verifies', () {
    final inventory = _bare(_complete());
    expect(inventory.problems, isEmpty);
    inventory.verify();
    expect(inventory.presentCount, 26);
    expect(inventory.absentCount, 63);
  });

  test('it names every way an inventory is wrong', () {
    final entries = _complete()
      ..removeWhere((e) => e.row == 'FloatingActionButton' || e.row == 'Kbd')
      ..add(const DesignInventoryEntry('Kbd'))
      ..add(DesignInventoryEntry('Link', builder: (_) => const Text('x')))
      ..add(
        DesignInventoryEntry(
          'Meter',
          builder: (_) => const Text('x'),
          absentReason: 'both',
        ),
      )
      ..add(const DesignInventoryEntry.absent('CarouselView', 'Not built yet'))
      ..add(const DesignInventoryEntry.absent('Tooltip', 'TODO'))
      ..add(const DesignInventoryEntry.absent('fancyThing', 'unknown'))
      ..add(const DesignInventoryEntry.absent('fab', 'An old id'));
    final inventory = DesignInventory(look: 'Broken', entries: entries);
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
        isA<DesignInventoryError>().having(
          (e) => e.toString(),
          'message',
          contains('Broken inventory'),
        ),
      ),
    );
  });

  test('a real reason with a soft word in it is a reason', () {
    const entry = DesignInventoryEntry.absent(
      'FloatingActionButton',
      'Material vocabulary; a later Material spec moved it to the app bar',
    );
    final inventory = _bare([
      ..._complete().where((e) => e.row != 'FloatingActionButton'),
      entry,
    ]);
    expect(inventory.problems, isEmpty);
  });

  List<DesignInventoryEntry> answer(Map<String, WidgetBuilder> present) => [
    for (final row in DesignInventoryRow.all)
      present.containsKey(row.id)
          ? DesignInventoryEntry.present(row.id, present[row.id]!)
          : DesignInventoryEntry.absent(
              row.id,
              'Out of this look\'s vocabulary',
            ),
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
        harness(DesignInventoryGallery(inventory: inventory)),
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
        DesignInventoryGallery(
          inventory: _bare(_complete()),
          behaviourOnly: true,
        ),
      ),
    );
    expect(find.text('live ToggleGroup'), findsOneWidget);
    expect(find.textContaining('Deliberately absent'), findsNothing);
  });
}

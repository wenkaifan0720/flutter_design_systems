// The rows Frosted paints on ui_core's behaviours, one test each through
// Frosted's own widgets: what a page hands in comes back through its
// callback, and what the reader hears is Frosted's words. ui_core's own
// tests prove the behaviour in full.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/frosted_host.dart';

Future<void> _pump(WidgetTester t, Widget child) async {
  t.view.physicalSize = const Size(390, 844);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (BuildContext context, Widget? page) =>
          FrostedHost(brightness: Brightness.light, child: page!),
      home: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(child: child),
      ),
    ),
  );
  expect(t.takeException(), isNull);
}

void main() {
  testWidgets('FrostedCombobox filters as you type and hands back the '
      'option pressed', (t) async {
    final chosen = <String>[];
    await _pump(
      t,
      FrostedCombobox<String>(
        label: 'City',
        options: const ['Lisbon', 'London', 'Madrid'],
        onSelected: chosen.add,
      ),
    );
    await t.enterText(find.byType(EditableText), 'Li');
    await t.pumpAndSettle();
    expect(find.text('Lisbon'), findsOneWidget);
    expect(find.text('Madrid'), findsNothing);
    await t.tap(find.text('Lisbon'));
    await t.pumpAndSettle();
    expect(chosen, ['Lisbon']);
  });

  testWidgets('FrostedCombobox says so when no option fits the words', (
    t,
  ) async {
    await _pump(
      t,
      const FrostedCombobox<String>(
        label: 'City',
        options: ['Lisbon', 'London', 'Madrid'],
      ),
    );
    await t.enterText(find.byType(EditableText), 'Atlantis');
    await t.pumpAndSettle();
    expect(find.text('No results'), findsOneWidget);
    expect(find.text('Lisbon'), findsNothing);
  });

  testWidgets('FrostedInputOtp completes with the code typed', (t) async {
    final done = <String>[];
    await _pump(
      t,
      FrostedInputOtp(label: 'Code', length: 4, onCompleted: done.add),
    );
    await t.enterText(find.byType(EditableText), '4321');
    await t.pump();
    expect(done, ['4321']);
    expect(find.text('4'), findsOneWidget);
  });

  testWidgets('FrostedPasswordField shows and hides the password by its eye', (
    t,
  ) async {
    await _pump(
      t,
      const FrostedPasswordField(label: 'Password', value: 'secret'),
    );
    bool hidden() =>
        t.widget<EditableText>(find.byType(EditableText)).obscureText;
    expect(hidden(), isTrue);
    await t.tap(find.bySemanticsLabel('Show password'));
    await t.pump();
    expect(hidden(), isFalse);
    expect(find.bySemanticsLabel('Hide password'), findsOneWidget);
  });

  testWidgets('FrostedToggleGroup hands back the set pressed', (t) async {
    final seen = <Set<String>>[];
    await _pump(
      t,
      FrostedToggleGroup<String>(
        label: 'Text style',
        multiple: true,
        segments: const [
          FrostedButtonSegment('b', 'Bold'),
          FrostedButtonSegment('i', 'Italic'),
        ],
        selected: const {'b'},
        onChanged: seen.add,
      ),
    );
    await t.tap(find.text('Italic'));
    await t.pump();
    expect(seen, [
      {'b', 'i'},
    ]);
  });

  testWidgets('FrostedDataTable sorts by the column pressed', (t) async {
    final rows = DesignTableController<String>(
      rows: const ['Pear', 'Apple', 'Fig'],
      columns: [
        DesignTableColumn(id: 'name', label: 'Name', sortKey: (s) => s),
      ],
    );
    addTearDown(rows.dispose);
    await _pump(
      t,
      FrostedDataTable<String>(
        controller: rows,
        cellBuilder: (context, row, column) => Text(row),
      ),
    );
    double top(String s) => t.getTopLeft(find.text(s)).dy;
    expect(top('Pear'), lessThan(top('Apple')));
    await t.tap(find.text('Name'));
    await t.pump();
    expect(top('Apple'), lessThan(top('Fig')));
    expect(top('Fig'), lessThan(top('Pear')));
  });

  testWidgets('FrostedSheet.showSide raises the panel; Escape closes it', (
    t,
  ) async {
    late BuildContext context;
    await _pump(
      t,
      Builder(
        builder: (c) {
          context = c;
          return const SizedBox(height: 40);
        },
      ),
    );
    FrostedSheet.showSide<void>(
      context,
      title: 'Filters',
      builder: (_) => [const Text('Only unread')],
    );
    await t.pumpAndSettle();
    expect(find.text('Only unread'), findsOneWidget);
    expect(find.byType(FrostedSheet), findsOneWidget);
    await t.sendKeyEvent(LogicalKeyboardKey.escape);
    await t.pumpAndSettle();
    expect(find.text('Only unread'), findsNothing);
  });
}

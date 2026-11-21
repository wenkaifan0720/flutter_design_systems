// Every count Studio's parts say is a real plural through localizations
// (StudioLocalizations, and ui_core's RawWidgetsLocalizations where it holds
// the word), never a number glued to a noun: a filter that leaves one row
// reads "1 row", not "1 rows".
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_ui/studio_parts.dart';

Widget _host(Widget child) => MaterialApp(
  localizationsDelegates: const [
    StudioLocalizations.delegate,
    RawWidgetsLocalizations.delegate,
  ],
  builder: (context, page) =>
      StudioTheme(data: StudioThemeData.light(), child: page!),
  home: Builder(
    builder: (context) => ColoredBox(
      color: StudioTheme.of(context).colors.chassis,
      child: SingleChildScrollView(child: child),
    ),
  ),
);

void main() {
  test('a row count is one row, then rows', () {
    const words = DefaultStudioLocalizations();
    expect(words.rowCount(1), '1 row');
    expect(words.rowCount(2), '2 rows');
    expect(words.rowCount(0), '0 rows');
  });

  testWidgets('a paged table counts its rows and its chosen rows as plurals', (
    tester,
  ) async {
    final table = StudioTableController<String>(
      rows: const ['Pilot', 'The long table', 'Field notes'],
      rowKey: (r) => r,
      pageSize: 1,
      filter: (r, query) => !r.startsWith(query),
      columns: const [StudioDataColumn<String>(id: 'title', label: 'Episode')],
    );
    addTearDown(table.dispose);
    await tester.pumpWidget(
      _host(StudioDataTable<String>(controller: table, cell: (r, _) => r)),
    );
    expect(find.text('3 rows'), findsOneWidget);
    table.query = 'Field';
    await tester.pump();
    expect(find.text('2 rows'), findsOneWidget);
    table.toggle('Pilot');
    await tester.pump();
    expect(find.text('1 item selected'), findsOneWidget);
    table.toggle('The long table');
    await tester.pump();
    expect(find.text('2 items selected'), findsOneWidget);
  });
}

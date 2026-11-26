import 'package:flutter/widgets.dart';
import 'package:minimal_ui/minimal_ui.dart';

class SortStock extends StatelessWidget {
  const SortStock({super.key});
  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 620),
    child: SingleChildScrollView(
      child: MinimalDataTable<(String, int)>(
        rows: const [('Ink', 12), ('Paper', 4), ('Pens', 8)],
        rowKey: (item) => item.$1,
        pageSize: 2,
        columns: [
          MinimalDataColumn('Item', value: (item) => item.$1, sortable: true),
          MinimalDataColumn(
            'Units',
            value: (item) => '${item.$2}',
            sortKey: (item) => item.$2,
            numeric: true,
          ),
        ],
      ),
    ),
  );
}

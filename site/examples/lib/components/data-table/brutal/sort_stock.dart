import 'package:flutter/widgets.dart';
import 'package:brutal_ui/brutal_ui.dart';

class SortStock extends StatefulWidget {
  const SortStock({super.key});
  @override
  State<SortStock> createState() => _SortStockState();
}

class _SortStockState extends State<SortStock> {
  final stock = BrutalTableController<(String, int)>(
    rows: const [('Ink', 12), ('Paper', 4), ('Pens', 8)],
    rowKey: (item) => item.$1,
    pageSize: 2,
    columns: [
      BrutalDataColumn(id: 'item', label: 'Item', sortKey: (item) => item.$1),
      BrutalDataColumn(
        id: 'units',
        label: 'Units',
        numeric: true,
        sortKey: (item) => item.$2,
      ),
    ],
  );
  @override
  void dispose() {
    stock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 620),
    child: SingleChildScrollView(
      child: BrutalDataTable<(String, int)>(
        controller: stock,
        cell: (item, column) => column == 'item' ? item.$1 : '${item.$2}',
      ),
    ),
  );
}

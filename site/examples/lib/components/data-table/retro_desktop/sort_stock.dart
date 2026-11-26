import 'package:flutter/widgets.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

class SortStock extends StatefulWidget {
  const SortStock({super.key});
  @override
  State<SortStock> createState() => _SortStockState();
}

class _SortStockState extends State<SortStock> {
  final stock = RawDataTableController<(String, int)>(
    rows: const [('Ink', 12), ('Paper', 4), ('Pens', 8)],
    pageSize: 2,
    rowKey: (item) => item.$1,
    columns: [
      RawDataColumn(id: 'item', label: 'Item', sortKey: (item) => item.$1),
      RawDataColumn(
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
      child: RetroDesktopDataTable<(String, int)>(
        controller: stock,
        cellText: (item, column) =>
            column.id == 'item' ? item.$1 : '${item.$2}',
      ),
    ),
  );
}

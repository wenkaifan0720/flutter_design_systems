import 'package:flutter/widgets.dart';
import 'package:keycap_ui/keycap_ui.dart';

class SortStock extends StatefulWidget {
  const SortStock({super.key});
  @override
  State<SortStock> createState() => _SortStockState();
}

class _SortStockState extends State<SortStock> {
  final stock = RawDataTableController<(String, int)>(
    rows: const [('Ink', 12), ('Paper', 4), ('Pens', 8)],
    rowKey: (item) => item.$1,
    pageSize: 2,
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          KeycapDataTable<(String, int)>(
            controller: stock,
            cellText: (item, column) =>
                column.id == 'item' ? item.$1 : '${item.$2}',
          ),
          const SizedBox(height: 12),
          ListenableBuilder(
            listenable: stock,
            builder: (context, _) => KeycapPagination(
              page: stock.page + 1,
              pageCount: stock.pageCount,
              onPageChanged: (page) => stock.goToPage(page - 1),
            ),
          ),
        ],
      ),
    ),
  );
}

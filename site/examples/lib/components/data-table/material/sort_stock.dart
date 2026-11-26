import 'package:material_ui/material_ui.dart';

class SortStock extends StatefulWidget {
  const SortStock({super.key});
  @override
  State<SortStock> createState() => _SortStockState();
}

class _SortStockState extends State<SortStock> {
  final source = _StockSource();
  int? sortColumn;
  bool ascending = true;

  void sort(int column, bool up) {
    setState(() {
      sortColumn = column;
      ascending = up;
    });
    source.sort(column, up);
  }

  @override
  void dispose() {
    source.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 620),
    child: SingleChildScrollView(
      child: PaginatedDataTable(
        rowsPerPage: 2,
        sortColumnIndex: sortColumn,
        sortAscending: ascending,
        columns: [
          DataColumn(label: const Text('Item'), onSort: sort),
          DataColumn(label: const Text('Units'), numeric: true, onSort: sort),
        ],
        source: source,
      ),
    ),
  );
}

class _StockSource extends DataTableSource {
  final rows = [('Ink', 12), ('Paper', 4), ('Pens', 8)];
  final selected = <String>{};

  void sort(int column, bool ascending) {
    rows.sort((a, b) {
      final order = column == 0 ? a.$1.compareTo(b.$1) : a.$2.compareTo(b.$2);
      return ascending ? order : -order;
    });
    notifyListeners();
  }

  @override
  DataRow getRow(int index) {
    final (item, units) = rows[index];
    return DataRow.byIndex(
      index: index,
      selected: selected.contains(item),
      onSelectChanged: (on) {
        on == true ? selected.add(item) : selected.remove(item);
        notifyListeners();
      },
      cells: [DataCell(Text(item)), DataCell(Text('$units'))],
    );
  }

  @override
  int get rowCount => rows.length;

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => selected.length;
}

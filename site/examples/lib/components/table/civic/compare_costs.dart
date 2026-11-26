import 'package:flutter/widgets.dart';
import 'package:civic_ui/civic_ui.dart';

class CompareCosts extends StatefulWidget {
  const CompareCosts({super.key});
  @override
  State<CompareCosts> createState() => _CompareCostsState();
}

class _CompareCostsState extends State<CompareCosts> {
  bool doubleOrder = false;
  final orders = RawDataTableController<(String, int)>(
    rows: const [('Paper', 4), ('Ink', 7)],
    columns: const [
      RawDataColumn(id: 'item', label: 'Item'),
      RawDataColumn(id: 'cost', label: 'Cost', numeric: true),
    ],
  );
  @override
  void dispose() {
    orders.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 760),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CivicTable<(String, int)>(
            controller: orders,
            cellBuilder: (context, item, column) => Text(
              column.id == 'item'
                  ? item.$1
                  : '£${item.$2 * (doubleOrder ? 2 : 1)}',
            ),
          ),
          const SizedBox(height: 12),
          CivicButton(
            onPressed: () => setState(() => doubleOrder = !doubleOrder),
            child: Text(doubleOrder ? 'One order' : 'Two orders'),
          ),
        ],
      ),
    ),
  );
}

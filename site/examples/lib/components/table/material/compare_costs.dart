import 'package:material_ui/material_ui.dart';

class CompareCosts extends StatefulWidget {
  const CompareCosts({super.key});
  @override
  State<CompareCosts> createState() => _CompareCostsState();
}

class _CompareCostsState extends State<CompareCosts> {
  bool doubleOrder = false;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 760),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DataTable(
            columns: const [
              DataColumn(label: Text('Item')),
              DataColumn(label: Text('Cost'), numeric: true),
            ],
            rows: [
              DataRow(
                cells: [
                  const DataCell(Text('Paper')),
                  DataCell(Text(doubleOrder ? '£8' : '£4')),
                ],
              ),
              DataRow(
                cells: [
                  const DataCell(Text('Ink')),
                  DataCell(Text(doubleOrder ? '£14' : '£7')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => setState(() => doubleOrder = !doubleOrder),
            child: Text(doubleOrder ? 'One order' : 'Two orders'),
          ),
        ],
      ),
    ),
  );
}

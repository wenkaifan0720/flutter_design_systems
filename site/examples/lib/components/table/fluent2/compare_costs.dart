import 'package:flutter/widgets.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';

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
          Fluent2Table(
            columns: const [
              Fluent2TableColumn('Item', minWidth: 72),
              Fluent2TableColumn('Cost', minWidth: 60, numeric: true),
            ],
            rows: [
              Fluent2TableRow(
                cells: [
                  const Fluent2TableCell('Paper'),
                  Fluent2TableCell(doubleOrder ? '£8' : '£4'),
                ],
              ),
              Fluent2TableRow(
                cells: [
                  const Fluent2TableCell('Ink'),
                  Fluent2TableCell(doubleOrder ? '£14' : '£7'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Fluent2Button(
            doubleOrder ? 'One order' : 'Two orders',
            onPressed: () => setState(() => doubleOrder = !doubleOrder),
          ),
        ],
      ),
    ),
  );
}

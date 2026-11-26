import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

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
          ExpressiveTable(
            columns: const [
              ExpressiveTableColumn('Item'),
              ExpressiveTableColumn('Cost', numeric: true),
            ],
            rows: [
              ExpressiveTableRow(['Paper', doubleOrder ? '£8' : '£4']),
              ExpressiveTableRow(['Ink', doubleOrder ? '£14' : '£7']),
            ],
          ),
          const SizedBox(height: 12),
          ExpressiveOutlinedButton(
            doubleOrder ? 'One order' : 'Two orders',
            onPressed: () => setState(() => doubleOrder = !doubleOrder),
          ),
        ],
      ),
    ),
  );
}

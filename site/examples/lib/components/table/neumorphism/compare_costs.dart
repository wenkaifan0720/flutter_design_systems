import 'package:flutter/widgets.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

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
          NeumorphicTable(
            columns: const [
              NeumorphicTableColumn('Item'),
              NeumorphicTableColumn('Cost', numeric: true),
            ],
            rows: [
              NeumorphicTableRow(['Paper', doubleOrder ? '£8' : '£4']),
              NeumorphicTableRow(['Ink', doubleOrder ? '£14' : '£7']),
            ],
          ),
          const SizedBox(height: 12),
          NeumorphicButton(
            doubleOrder ? 'One order' : 'Two orders',
            onPressed: () => setState(() => doubleOrder = !doubleOrder),
          ),
        ],
      ),
    ),
  );
}

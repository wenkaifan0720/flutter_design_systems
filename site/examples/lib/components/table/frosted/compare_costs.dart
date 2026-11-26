import 'package:flutter/widgets.dart';
import 'package:frosted_ui/frosted_ui.dart';

class CompareCosts extends StatefulWidget {
  const CompareCosts({super.key});
  @override
  State<CompareCosts> createState() => _CompareCostsState();
}

class _CompareCostsState extends State<CompareCosts> {
  bool doubleOrder = false;
  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 700),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FrostedTable(
            columns: const [
              FrostedTableColumn('Item'),
              FrostedTableColumn('Cost', numeric: true),
            ],
            rows: [
              ['Paper', doubleOrder ? '£8' : '£4'],
              ['Ink', doubleOrder ? '£14' : '£7'],
            ],
          ),
          const SizedBox(height: 12),
          FrostedButton(
            doubleOrder ? 'One order' : 'Two orders',
            onPressed: () => setState(() => doubleOrder = !doubleOrder),
          ),
        ],
      ),
    ),
  );
}

import 'package:flutter/widgets.dart';
import 'package:brutal_ui/brutal_ui.dart';

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
          BrutalTable(
            columns: const [
              BrutalTableColumn('Item'),
              BrutalTableColumn('Cost', numeric: true),
            ],
            rows: [
              ['Paper', doubleOrder ? '£8' : '£4'],
              ['Ink', doubleOrder ? '£14' : '£7'],
            ],
          ),
          const SizedBox(height: 12),
          BrutalButton(
            doubleOrder ? 'One order' : 'Two orders',
            onPressed: () => setState(() => doubleOrder = !doubleOrder),
          ),
        ],
      ),
    ),
  );
}

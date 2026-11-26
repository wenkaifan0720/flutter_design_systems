import 'package:flutter/widgets.dart';
import 'package:clay_ui/clay_ui.dart';

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
          ClayTable(
            columns: const [
              ClayTableColumn('Item'),
              ClayTableColumn('Cost', numeric: true),
            ],
            rows: [
              ['Paper', doubleOrder ? '£8' : '£4'],
              ['Ink', doubleOrder ? '£14' : '£7'],
            ],
          ),
          const SizedBox(height: 12),
          ClayButton(
            doubleOrder ? 'One order' : 'Two orders',
            onPressed: () => setState(() => doubleOrder = !doubleOrder),
          ),
        ],
      ),
    ),
  );
}

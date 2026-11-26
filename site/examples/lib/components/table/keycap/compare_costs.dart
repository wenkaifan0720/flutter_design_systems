import 'package:flutter/widgets.dart';
import 'package:keycap_ui/keycap_ui.dart';

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
          KeycapTable(
            columns: const [
              KeycapTableColumn('Item'),
              KeycapTableColumn('Cost', numeric: true),
            ],
            rows: [
              ['Paper', doubleOrder ? '£8' : '£4'],
              ['Ink', doubleOrder ? '£14' : '£7'],
            ],
          ),
          const SizedBox(height: 12),
          KeycapButton(
            onPressed: () => setState(() => doubleOrder = !doubleOrder),
            child: Text(doubleOrder ? 'One order' : 'Two orders'),
          ),
        ],
      ),
    ),
  );
}

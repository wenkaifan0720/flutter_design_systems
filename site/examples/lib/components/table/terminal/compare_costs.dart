import 'package:flutter/widgets.dart';
import 'package:terminal_ui/terminal_ui.dart';

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
          TermTable(
            semanticLabel: 'Costs',
            columns: const [
              TermColumn(label: 'Item', cols: 9),
              TermColumn(label: 'Cost', cols: 6, numeric: true),
            ],
            rows: [
              [const Text('Paper'), Text(doubleOrder ? '£8' : '£4')],
              [const Text('Ink'), Text(doubleOrder ? '£14' : '£7')],
            ],
          ),
          const SizedBox(height: 12),
          TermButton(
            label: doubleOrder ? 'One order' : 'Two orders',
            onPressed: () => setState(() => doubleOrder = !doubleOrder),
          ),
        ],
      ),
    ),
  );
}

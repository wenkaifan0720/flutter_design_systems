import 'package:flutter/widgets.dart';
import 'package:minimal_ui/minimal_ui.dart';

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
          MinimalTable(
            columns: const [
              MinimalColumn('Item'),
              MinimalColumn('Cost', numeric: true),
            ],
            rows: [
              MinimalTableRow([
                const MinimalCell('Paper'),
                MinimalCell(doubleOrder ? '£8' : '£4'),
              ]),
              MinimalTableRow([
                const MinimalCell('Ink'),
                MinimalCell(doubleOrder ? '£14' : '£7'),
              ]),
            ],
          ),
          const SizedBox(height: 12),
          MinimalButton(
            doubleOrder ? 'One order' : 'Two orders',
            onPressed: () => setState(() => doubleOrder = !doubleOrder),
          ),
        ],
      ),
    ),
  );
}

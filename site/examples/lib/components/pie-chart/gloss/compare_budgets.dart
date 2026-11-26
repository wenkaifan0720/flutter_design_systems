import 'package:flutter/widgets.dart';
import 'package:gloss_ui/gloss_ui.dart';

class CompareBudgets extends StatefulWidget {
  const CompareBudgets({super.key});
  @override
  State<CompareBudgets> createState() => _CompareBudgetsState();
}

class _CompareBudgetsState extends State<CompareBudgets> {
  bool alternate = false;

  String get period => alternate ? 'Plan B' : 'Plan A';

  List<double> get amounts =>
      alternate ? const [40, 40, 20] : const [50, 30, 20];

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$period · budget by category'),
          const SizedBox(height: 12),
          GlossPieChart(
            slices: [
              GlossSlice('Supplies', amounts[0]),
              GlossSlice('Travel', amounts[1]),
              GlossSlice('Fees', amounts[2]),
            ],
            semanticLabel: '$period budget by category',
          ),
          const SizedBox(height: 12),
          GlossButton(
            alternate ? 'Show Plan A' : 'Show Plan B',
            onPressed: () => setState(() => alternate = !alternate),
          ),
        ],
      ),
    ),
  );
}

import 'package:flutter/widgets.dart';
import 'package:comic_ui/comic_ui.dart';

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
          ComicPieChart(
            slices: [
              ComicSlice('Supplies', amounts[0]),
              ComicSlice('Travel', amounts[1]),
              ComicSlice('Fees', amounts[2]),
            ],
            centre: '100',
            unit: 'budget',
          ),
          const SizedBox(height: 12),
          ComicButton(
            alternate ? 'Show Plan A' : 'Show Plan B',
            onPressed: () => setState(() => alternate = !alternate),
          ),
        ],
      ),
    ),
  );
}

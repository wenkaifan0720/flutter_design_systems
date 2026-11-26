import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

class CompareBalances extends StatefulWidget {
  const CompareBalances({super.key});
  @override
  State<CompareBalances> createState() => _CompareBalancesState();
}

class _CompareBalancesState extends State<CompareBalances> {
  bool alternate = false;

  String get period => alternate ? 'February' : 'January';

  List<double> get balances =>
      alternate ? const [86, 92, 98, 112] : const [90, 100, 94, 106];

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$period · daily balance'),
          const SizedBox(height: 12),
          ExpressiveLineChart(
            points: [
              for (var i = 0; i < balances.length; i++)
                ExpressiveChartPoint('Day ${i + 1}', balances[i]),
            ],
          ),
          const SizedBox(height: 12),
          ExpressiveFilledButton(
            alternate ? 'Show January' : 'Show February',
            onPressed: () => setState(() => alternate = !alternate),
          ),
        ],
      ),
    ),
  );
}

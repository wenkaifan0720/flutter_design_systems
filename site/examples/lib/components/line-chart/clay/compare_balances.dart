import 'package:flutter/widgets.dart';
import 'package:clay_ui/clay_ui.dart';

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
          ClayLineChart(
            categories: const ['1', '2', '3', '4'],
            series: [
              ClayChartSeries(
                label: 'Balance',
                points: [
                  for (final (i, v) in balances.indexed)
                    ClayChartPoint(i.toDouble(), v),
                ],
              ),
            ],
            semanticLabel: '$period daily balance',
          ),
          const SizedBox(height: 12),
          ClayButton(
            alternate ? 'Show January' : 'Show February',
            onPressed: () => setState(() => alternate = !alternate),
          ),
        ],
      ),
    ),
  );
}

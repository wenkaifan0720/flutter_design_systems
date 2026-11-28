import 'package:flutter/widgets.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';

class TrackSpending extends StatefulWidget {
  const TrackSpending({super.key});
  @override
  State<TrackSpending> createState() => _TrackSpendingState();
}

class _TrackSpendingState extends State<TrackSpending> {
  bool alternate = false;

  String get period => alternate ? 'February' : 'January';

  List<double> get totals =>
      alternate ? const [24, 42, 68, 96] : const [12, 34, 55, 80];

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$period · cumulative spending'),
          const SizedBox(height: 12),
          Fluent2AreaChart(
            labels: const ['1', '2', '3', '4'],
            series: [Fluent2ChartSeries('Spent', totals)],
            semanticLabel: '$period cumulative spending',
          ),
          const SizedBox(height: 12),
          Fluent2Button(
            alternate ? 'Show January' : 'Show February',
            onPressed: () => setState(() => alternate = !alternate),
          ),
        ],
      ),
    ),
  );
}

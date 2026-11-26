import 'package:flutter/widgets.dart';
import 'package:terminal_ui/terminal_ui.dart';

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
          TermAreaChart(
            series: [TermSeries(label: 'Spent', values: totals)],
            xLabels: ('Day 1', 'Day 4'),
            lines: 6,
            semanticLabel: '$period cumulative spending',
          ),
          const SizedBox(height: 12),
          TermButton(
            label: alternate ? 'Show January' : 'Show February',
            onPressed: () => setState(() => alternate = !alternate),
          ),
        ],
      ),
    ),
  );
}

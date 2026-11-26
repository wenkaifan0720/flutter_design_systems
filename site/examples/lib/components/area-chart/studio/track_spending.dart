import 'package:flutter/widgets.dart';
import 'package:studio_ui/studio_ui.dart';

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
          StudioAreaChart(
            labels: const ['1', '2', '3', '4'],
            series: [StudioSeries('Spent', totals)],
            semanticLabel: '$period cumulative spending',
          ),
          const SizedBox(height: 12),
          StudioButton(
            alternate ? 'Show January' : 'Show February',
            onPressed: () => setState(() => alternate = !alternate),
          ),
        ],
      ),
    ),
  );
}

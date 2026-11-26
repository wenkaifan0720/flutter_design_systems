import 'package:flutter/widgets.dart';
import 'package:ledger_ui/ledger_ui.dart';

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
          LedgerCumulativeChart(
            cumulative: totals,
            budget: 120,
            budgetLabel: 'Budget 120',
            days: alternate ? 28 : 31,
            high: 150,
            grid: const [LedgerGridLine(60, '60'), LedgerGridLine(120, '120')],
            month: period,
            semanticLabel:
                '$period cumulative spending: ${totals.map((v) => v.round()).join(', ')}',
          ),
          const SizedBox(height: 12),
          LedgerButton(
            alternate ? 'Show January' : 'Show February',
            onPressed: () => setState(() => alternate = !alternate),
          ),
        ],
      ),
    ),
  );
}

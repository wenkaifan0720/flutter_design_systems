import 'package:flutter/widgets.dart';
import 'package:ledger_ui/ledger_ui.dart';

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
          LedgerMonthLine(
            values: balances,
            start: balances.first,
            days: alternate ? 28 : 31,
            low: 80,
            high: 120,
            grid: const [LedgerGridLine(90, '90'), LedgerGridLine(110, '110')],
            month: period,
            semanticLabel:
                '$period daily balance: ${balances.map((v) => v.round()).join(', ')}',
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

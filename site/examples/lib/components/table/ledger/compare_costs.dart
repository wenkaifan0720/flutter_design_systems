import 'package:flutter/widgets.dart';
import 'package:ledger_ui/ledger_ui.dart';

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
          LedgerRegister(
            columns: LedgerRegisterColumns.noCategoryOneAccount,
            heads: const ['Time', 'Item', 'Cost'],
            children: [
              for (final item in const [('Paper', 4.0), ('Ink', 7.0)])
                LedgerTransactionRow(
                  title: item.$1,
                  category: 'Supplies',
                  when: '2 pm',
                  account: 'Desk',
                  amount: item.$2 * (doubleOrder ? 2 : 1),
                ),
            ],
          ),
          const SizedBox(height: 12),
          LedgerButton(
            doubleOrder ? 'One order' : 'Two orders',
            onPressed: () => setState(() => doubleOrder = !doubleOrder),
          ),
        ],
      ),
    ),
  );
}

import 'package:flutter/widgets.dart';
import 'package:ledger_ui/ledger_ui.dart';

class DraftDetails extends StatelessWidget {
  const DraftDetails({super.key});

  @override
  Widget build(BuildContext context) => LedgerButton.filled(
    'View draft details',
    onPressed: () => LedgerDialog.show(
      context,
      title: 'Draft details',
      body: 'Only visible to you until you publish',
      type: LedgerDialogType.acknowledge,
      confirmLabel: 'Done',
    ),
  );
}

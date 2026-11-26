import 'package:flutter/widgets.dart';
import 'package:ledger_ui/ledger_ui.dart';

class InspectFile extends StatelessWidget {
  const InspectFile({super.key});

  @override
  Widget build(BuildContext context) => LedgerButton(
    'File details',
    onPressed: () => showLedgerSideSheet<void>(
      context,
      title: 'File details',
      builder: (_) => const Text('Owner: Mara Chen\nLast edited: 14 June'),
    ),
  );
}

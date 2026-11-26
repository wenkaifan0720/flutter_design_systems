import 'package:flutter/widgets.dart';
import 'package:ledger_ui/ledger_ui.dart';

class ReadSharingDetails extends StatelessWidget {
  const ReadSharingDetails({super.key});

  @override
  Widget build(BuildContext context) => LedgerPopover(
    semanticLabel: 'Sharing details',
    anchor: (_, anchor) =>
        LedgerButton('Sharing details', onPressed: anchor.toggle),
    child: const Text('Only invited people can read this file.'),
  );
}

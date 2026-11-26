import 'package:flutter/widgets.dart';
import 'package:ledger_ui/ledger_ui.dart';

class FindCommand extends StatefulWidget {
  const FindCommand({super.key});
  @override
  State<FindCommand> createState() => _FindCommandState();
}

class _FindCommandState extends State<FindCommand> {
  bool reviewed = false;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      LedgerButton(
        'Commands',
        onPressed: () => showLedgerCommandPalette(
          context,
          commands: [
            LedgerCommand(
              label: 'Review note',
              onPressed: () => setState(() => reviewed = true),
            ),
            LedgerCommand(
              label: 'Reset note',
              onPressed: () => setState(() => reviewed = false),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Text(reviewed ? 'Reviewed' : 'Draft'),
    ],
  );
}

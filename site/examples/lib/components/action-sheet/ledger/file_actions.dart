import 'package:flutter/widgets.dart';
import 'package:ledger_ui/ledger_ui.dart';

class FileActions extends StatefulWidget {
  const FileActions({super.key});
  @override
  State<FileActions> createState() => _FileActionsState();
}

class _FileActionsState extends State<FileActions> {
  bool pinned = false;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      LedgerButton(
        'File actions',
        onPressed: () async {
          final choice = await showLedgerActionSheet<bool>(
            context,
            title: 'File actions',
            acts: const [
              LedgerSheetAct('Pin', value: true),
              LedgerSheetAct('Unpin', value: false),
            ],
          );
          if (mounted && choice != null) setState(() => pinned = choice);
        },
      ),
      const SizedBox(height: 12),
      Text(pinned ? 'Pinned' : 'Unpinned'),
    ],
  );
}

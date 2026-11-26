import 'package:flutter/widgets.dart';
import 'package:brutal_ui/brutal_ui.dart';

class DraftDetails extends StatelessWidget {
  const DraftDetails({super.key});

  @override
  Widget build(BuildContext context) => BrutalButton.filled(
    'View draft details',
    onPressed: () => showBrutalDialog<void>(
      context: context,
      builder: (dialogContext) => BrutalDialog(
        title: 'Draft details',
        content: const Text('Only visible to you until you publish'),
        actions: [
          BrutalDialogAction(
            label: 'Done',
            isDefaultAction: true,
            onPressed: () => Navigator.pop(dialogContext),
          ),
        ],
      ),
    ),
  );
}

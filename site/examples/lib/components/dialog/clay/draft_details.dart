import 'package:flutter/widgets.dart';
import 'package:clay_ui/clay_ui.dart';

class DraftDetails extends StatelessWidget {
  const DraftDetails({super.key});

  @override
  Widget build(BuildContext context) => ClayButton.filled(
    'View draft details',
    onPressed: () => showClayDialog(
      context: context,
      builder: (context) => ClayDialog(
        title: 'Draft details',
        content: const Text('Only visible to you until you publish'),
        actions: [
          ClayDialogAction(
            label: 'Done',
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    ),
  );
}

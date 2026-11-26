import 'package:flutter/widgets.dart';
import 'package:appliance_ui/appliance_ui.dart';

class DraftDetails extends StatelessWidget {
  const DraftDetails({super.key});

  @override
  Widget build(BuildContext context) => ApplianceButton.filled(
    'View draft details',
    onPressed: () => showApplianceDialog<void>(
      context: context,
      builder: (dialogContext) => ApplianceDialog(
        title: 'Draft details',
        content: const Text('Only visible to you until you publish'),
        actions: [
          ApplianceButton.filled(
            'Done',
            onPressed: () => Navigator.pop(dialogContext),
          ),
        ],
      ),
    ),
  );
}

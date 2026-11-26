import 'package:flutter/widgets.dart';
import 'package:studio_ui/studio_ui.dart';

class DraftDetails extends StatelessWidget {
  const DraftDetails({super.key});

  @override
  Widget build(BuildContext context) => StudioButton.lit(
    'View draft details',
    onPressed: () => showStudioDialog<void>(
      context: context,
      builder: (dialogContext) => StudioDialog(
        title: 'Draft details',
        content: const Text('Only visible to you until you publish'),
        actions: [
          StudioButton.lit(
            'Done',
            onPressed: () => Navigator.pop(dialogContext),
          ),
        ],
      ),
    ),
  );
}

import 'package:civic_ui/civic_ui.dart';
import 'package:flutter/widgets.dart';

class DraftDetails extends StatelessWidget {
  const DraftDetails({super.key});
  @override
  Widget build(BuildContext context) => CivicButton(
    child: const Text('View draft details'),
    onPressed: () => showCivicDialog<void>(
      context: context,
      builder: (dialogContext) => CivicDialog(
        title: 'Draft details',
        content: const Text('Only visible to you until you publish'),
        actions: [
          CivicButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Done'),
          ),
        ],
      ),
    ),
  );
}

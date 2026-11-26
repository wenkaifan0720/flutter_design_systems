import 'package:flutter/widgets.dart';
import 'package:gloss_ui/gloss_ui.dart';

class DraftDetails extends StatelessWidget {
  const DraftDetails({super.key});

  @override
  Widget build(BuildContext context) => GlossButton.filled(
    'View draft details',
    onPressed: () => showGlossDialog(
      context: context,
      builder: (context) => GlossDialog(
        title: 'Draft details',
        content: const Text('Only visible to you until you publish'),
        actions: [
          GlossDialogAction(
            label: 'Done',
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    ),
  );
}

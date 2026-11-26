import 'package:flutter/widgets.dart';
import 'package:keycap_ui/keycap_ui.dart';

class DraftDetails extends StatelessWidget {
  const DraftDetails({super.key});

  @override
  Widget build(BuildContext context) => KeycapButton.accent(
    onPressed: () => showKeycapDialog<void>(
      context: context,
      builder: (dialogContext) => KeycapDialog(
        title: 'Draft details',
        content: const Text('Only visible to you until you publish'),
        actions: [
          KeycapButton.accent(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Done'),
          ),
        ],
      ),
    ),
    child: const Text('View draft details'),
  );
}

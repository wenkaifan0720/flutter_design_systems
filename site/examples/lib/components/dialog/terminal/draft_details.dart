import 'package:flutter/widgets.dart';
import 'package:terminal_ui/terminal_ui.dart';

class DraftDetails extends StatelessWidget {
  const DraftDetails({super.key});

  @override
  Widget build(BuildContext context) => TermButton.filled(
    label: 'View draft details',
    onPressed: () => showTermDialog(
      context: context,
      builder: (context) => TermDialog(
        title: 'Draft details',
        content: const Text('Only visible to you until you publish'),
        actions: [
          TermButton.filled(
            label: 'Done',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    ),
  );
}

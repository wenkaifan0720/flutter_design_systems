import 'package:flutter/widgets.dart';
import 'package:minimal_ui/minimal_ui.dart';

class DraftDetails extends StatelessWidget {
  const DraftDetails({super.key});

  @override
  Widget build(BuildContext context) => MinimalButton(
    'View draft details',
    onPressed: () => showMinimalDialog<bool>(
      context,
      builder: (_) => const MinimalDialog(
        title: 'Draft details',
        message: 'Only visible to you until you publish',
        confirmLabel: 'Done',
      ),
    ),
  );
}

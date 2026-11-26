import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

class DraftDetails extends StatelessWidget {
  const DraftDetails({super.key});

  @override
  Widget build(BuildContext context) => ExpressiveFilledButton(
    'View draft details',
    onPressed: () => showExpressiveDialog<void>(
      context: context,
      builder: (_) => const ExpressiveDialog(
        title: 'Draft details',
        text: 'Only visible to you until you publish',
        actions: [ExpressiveDialogAction('Done')],
      ),
    ),
  );
}

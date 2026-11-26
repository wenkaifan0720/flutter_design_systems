import 'package:flutter/widgets.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';

class DraftDetails extends StatelessWidget {
  const DraftDetails({super.key});

  @override
  Widget build(BuildContext context) => Fluent2Button(
    'View draft details',
    appearance: Fluent2ButtonAppearance.primary,
    onPressed: () => showFluent2Dialog<void>(
      context,
      builder: (dialogContext) => Fluent2Dialog(
        title: 'Draft details',
        message: 'Only visible to you until you publish',
        actions: [
          Fluent2Button(
            'Done',
            appearance: Fluent2ButtonAppearance.primary,
            onPressed: () => Navigator.pop(dialogContext),
          ),
        ],
      ),
    ),
  );
}

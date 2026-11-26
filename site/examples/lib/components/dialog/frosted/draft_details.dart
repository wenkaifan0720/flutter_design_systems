import 'package:flutter/widgets.dart';
import 'package:frosted_ui/frosted_ui.dart';

class DraftDetails extends StatelessWidget {
  const DraftDetails({super.key});

  @override
  Widget build(BuildContext context) => FrostedButton(
    'View draft details',
    onPressed: () => FrostedDialog.show(
      context,
      title: 'Draft details',
      message: 'Only visible to you until you publish',
      confirmLabel: 'Done',
    ),
  );
}

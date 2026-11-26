import 'package:flutter/widgets.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

class DraftDetails extends StatelessWidget {
  const DraftDetails({super.key});

  @override
  Widget build(BuildContext context) => NeumorphicButton.filled(
    'View draft details',
    onPressed: () => showNeumorphicDialog(
      context,
      builder: (context) => NeumorphicDialog(
        title: 'Draft details',
        message: 'Only visible to you until you publish',
        actions: [
          NeumorphicButton.filled(
            'Done',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    ),
  );
}

import 'package:flutter/widgets.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

class DraftDetails extends StatelessWidget {
  const DraftDetails({super.key});

  @override
  Widget build(BuildContext context) => RetroDesktopButton(
    'View draft details',
    onPressed: () => showRetroDesktopDialog(
      context,
      builder: (_) => const RetroDesktopDialog(
        title: 'Draft details',
        message: 'Only visible to you until you publish',
        actions: [RetroDesktopDialogAction('Done', isDefaultAction: true)],
      ),
    ),
  );
}

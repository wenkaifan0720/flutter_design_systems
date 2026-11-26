import 'package:flutter/widgets.dart';
import 'package:comic_ui/comic_ui.dart';

class DraftDetails extends StatelessWidget {
  const DraftDetails({super.key});

  @override
  Widget build(BuildContext context) => ComicButton.filled(
    'View draft details',
    onPressed: () => showComicDialog<void>(
      context,
      builder: (dialogContext) => ComicDialog(
        title: 'Draft details',
        message: 'Only visible to you until you publish',
        actions: [
          ComicButton.filled(
            'Done',
            onPressed: () => Navigator.pop(dialogContext),
          ),
        ],
      ),
    ),
  );
}

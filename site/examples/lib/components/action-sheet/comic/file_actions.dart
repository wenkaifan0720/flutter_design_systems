import 'package:flutter/widgets.dart';
import 'package:comic_ui/comic_ui.dart';

class FileActions extends StatefulWidget {
  const FileActions({super.key});
  @override
  State<FileActions> createState() => _FileActionsState();
}

class _FileActionsState extends State<FileActions> {
  bool pinned = false;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      ComicButton(
        'File actions',
        onPressed: () async {
          final choice = await showComicActionSheet<bool>(
            context,
            title: 'File actions',
            actions: const [
              ComicSheetAction('Pin', value: true),
              ComicSheetAction('Unpin', value: false),
            ],
          );
          if (mounted && choice != null) setState(() => pinned = choice);
        },
      ),
      const SizedBox(height: 12),
      Text(pinned ? 'Pinned' : 'Unpinned'),
    ],
  );
}

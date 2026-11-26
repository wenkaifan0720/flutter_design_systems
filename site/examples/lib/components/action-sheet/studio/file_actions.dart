import 'package:flutter/widgets.dart';
import 'package:studio_ui/studio_ui.dart';

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
      StudioButton(
        'File actions',
        onPressed: () async {
          final choice = await showStudioActionSheet<bool>(
            context: context,
            title: 'File actions',
            actions: const [
              StudioSheetAction(label: 'Pin', value: true),
              StudioSheetAction(label: 'Unpin', value: false),
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

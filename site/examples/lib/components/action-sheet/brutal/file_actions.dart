import 'package:flutter/widgets.dart';
import 'package:brutal_ui/brutal_ui.dart';

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
      BrutalButton(
        'File actions',
        onPressed: () async {
          final choice = await showBrutalActionSheet<bool>(
            context: context,
            title: 'File actions',
            actions: const [
              BrutalSheetAction(label: 'Pin', value: true),
              BrutalSheetAction(label: 'Unpin', value: false),
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

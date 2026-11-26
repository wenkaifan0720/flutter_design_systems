import 'package:flutter/widgets.dart';
import 'package:gloss_ui/gloss_ui.dart';

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
      GlossButton(
        'File actions',
        onPressed: () async {
          final choice = await showGlossActionSheet<bool>(
            context: context,
            title: 'File actions',
            actions: const [
              GlossSheetAction(label: 'Pin', value: true),
              GlossSheetAction(label: 'Unpin', value: false),
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

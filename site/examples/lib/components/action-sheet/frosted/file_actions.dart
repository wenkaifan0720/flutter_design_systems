import 'package:flutter/widgets.dart';
import 'package:frosted_ui/frosted_ui.dart';

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
      FrostedButton(
        'File actions',
        onPressed: () async {
          final choice = await showFrostedActionSheet<bool>(
            context,
            builder: (_) => const FrostedActionSheet<bool>(
              title: 'File actions',
              actions: [
                FrostedActionSheetAction('Pin', value: true),
                FrostedActionSheetAction('Unpin', value: false),
              ],
            ),
          );
          if (mounted && choice != null) setState(() => pinned = choice);
        },
      ),
      const SizedBox(height: 12),
      Text(pinned ? 'Pinned' : 'Unpinned'),
    ],
  );
}

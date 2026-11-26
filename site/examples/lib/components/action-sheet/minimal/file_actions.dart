import 'package:flutter/widgets.dart';
import 'package:minimal_ui/minimal_ui.dart';

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
      MinimalButton(
        'File actions',
        onPressed: () => showMinimalActionSheet(
          context,
          title: 'File actions',
          actions: [
            MinimalActionSheetAction(
              'Pin',
              onPressed: () => setState(() => pinned = true),
            ),
            MinimalActionSheetAction(
              'Unpin',
              onPressed: () => setState(() => pinned = false),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Text(pinned ? 'Pinned' : 'Unpinned'),
    ],
  );
}

import 'package:flutter/widgets.dart';
import 'package:keycap_ui/keycap_ui.dart';

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
      KeycapButton(
        onPressed: () => showKeycapActionSheet(
          context: context,
          title: 'File actions',
          actions: [
            KeycapSheetAction(
              'Pin',
              onPressed: () => setState(() => pinned = true),
            ),
            KeycapSheetAction(
              'Unpin',
              onPressed: () => setState(() => pinned = false),
            ),
          ],
        ),
        child: const Text('File actions'),
      ),
      const SizedBox(height: 12),
      Text(pinned ? 'Pinned' : 'Unpinned'),
    ],
  );
}

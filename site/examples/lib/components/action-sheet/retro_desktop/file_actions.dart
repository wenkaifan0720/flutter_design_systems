import 'package:flutter/widgets.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

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
      RetroDesktopButton(
        'File actions',
        onPressed: () => showRetroDesktopActionSheet(
          context,
          title: 'File actions',
          actions: [
            RetroDesktopActionSheetAction(
              'Pin',
              onPressed: () => setState(() => pinned = true),
            ),
            RetroDesktopActionSheetAction(
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

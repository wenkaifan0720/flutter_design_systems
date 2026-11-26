import 'package:flutter/widgets.dart';
import 'package:comic_ui/comic_ui.dart';

class SyncFolder extends StatefulWidget {
  const SyncFolder({super.key});
  @override
  State<SyncFolder> createState() => _SyncFolderState();
}

class _SyncFolderState extends State<SyncFolder> {
  bool running = false;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    spacing: 12,
    children: [
      if (running)
        const ComicCircularProgressIndicator(label: 'Syncing folder'),
      Text(running ? 'Syncing folder' : 'Folder ready'),
      ComicButton(
        running ? 'Finish sync' : 'Start sync',
        onPressed: () => setState(() => running = !running),
      ),
    ],
  );
}

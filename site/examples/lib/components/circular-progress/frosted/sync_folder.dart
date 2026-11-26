import 'package:flutter/widgets.dart';
import 'package:frosted_ui/frosted_ui.dart';

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
        const FrostedCircularProgressIndicator(label: 'Syncing folder'),
      Text(running ? 'Syncing folder' : 'Folder ready'),
      FrostedButton(
        running ? 'Finish sync' : 'Start sync',
        onPressed: () => setState(() => running = !running),
      ),
    ],
  );
}

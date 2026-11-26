import 'package:cupertino_ui/cupertino_ui.dart';

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
        Semantics(
          label: 'Syncing folder',
          child: const CupertinoActivityIndicator(radius: 14),
        ),
      Text(running ? 'Syncing folder' : 'Folder ready'),
      CupertinoButton(
        onPressed: () => setState(() => running = !running),
        child: Text(running ? 'Finish sync' : 'Start sync'),
      ),
    ],
  );
}

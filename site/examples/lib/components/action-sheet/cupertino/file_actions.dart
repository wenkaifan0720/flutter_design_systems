import 'package:cupertino_ui/cupertino_ui.dart';

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
      CupertinoButton(
        onPressed: () => showCupertinoModalPopup<void>(
          context: context,
          builder: (context) => CupertinoActionSheet(
            title: const Text('File actions'),
            actions: [
              for (final (label, pin) in [('Pin', true), ('Unpin', false)])
                CupertinoActionSheetAction(
                  onPressed: () {
                    setState(() => pinned = pin);
                    Navigator.pop(context);
                  },
                  child: Text(label),
                ),
            ],
            cancelButton: CupertinoActionSheetAction(
              isDefaultAction: true,
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ),
        ),
        child: const Text('File actions'),
      ),
      const SizedBox(height: 12),
      Text(pinned ? 'Pinned' : 'Unpinned'),
    ],
  );
}

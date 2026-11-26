import 'package:flutter/widgets.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

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
      NeumorphicButton(
        'File actions',
        onPressed: () async {
          final choice = await showNeumorphicActionSheet<bool>(
            context,
            title: 'File actions',
            actions: const [
              NeumorphicActionSheetAction(true, 'Pin'),
              NeumorphicActionSheetAction(false, 'Unpin'),
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

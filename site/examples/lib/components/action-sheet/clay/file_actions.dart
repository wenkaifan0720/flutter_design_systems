import 'package:flutter/widgets.dart';
import 'package:clay_ui/clay_ui.dart';

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
      ClayButton(
        'File actions',
        onPressed: () async {
          final choice = await showClayActionSheet<bool>(
            context: context,
            title: 'File actions',
            actions: const [
              ClaySheetAction(label: 'Pin', value: true),
              ClaySheetAction(label: 'Unpin', value: false),
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

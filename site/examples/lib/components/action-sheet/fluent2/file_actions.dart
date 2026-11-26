import 'package:flutter/widgets.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';

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
      Fluent2Button(
        'File actions',
        onPressed: () async {
          final choice = await showFluent2ActionSheet<bool>(
            context,
            title: 'File actions',
            actions: const [
              Fluent2ActionSheetAction(true, 'Pin'),
              Fluent2ActionSheetAction(false, 'Unpin'),
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

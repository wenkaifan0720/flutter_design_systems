import 'package:flutter/widgets.dart';
import 'package:appliance_ui/appliance_ui.dart';

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
      ApplianceButton(
        'File actions',
        onPressed: () => showApplianceActionSheet(
          context: context,
          title: 'File actions',
          actions: [
            ApplianceSheetAction(
              'Pin',
              onPressed: () => setState(() => pinned = true),
            ),
            ApplianceSheetAction(
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

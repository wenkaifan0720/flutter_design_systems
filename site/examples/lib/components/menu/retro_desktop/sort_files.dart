import 'package:flutter/widgets.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

class SortFiles extends StatefulWidget {
  const SortFiles({super.key});
  @override
  State<SortFiles> createState() => _SortFilesState();
}

class _SortFilesState extends State<SortFiles> {
  String order = 'Name';

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      RetroDesktopMenuAnchor<String>(
        items: const [
          RetroDesktopMenuItem('Name', 'Name'),
          RetroDesktopMenuItem('Date', 'Date'),
        ],
        builder: (_, open) => RetroDesktopButton('Sort files', onPressed: open),
        onSelected: (sort) => setState(() => order = sort),
      ),
      const SizedBox(height: 12),
      Text('Sort order: $order'),
    ],
  );
}

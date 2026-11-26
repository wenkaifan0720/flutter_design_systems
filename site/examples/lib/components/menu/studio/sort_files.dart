import 'package:flutter/widgets.dart';
import 'package:studio_ui/studio_ui.dart';

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
      StudioMenu(
        semanticLabel: 'Sort files',
        items: [
          for (final sort in ['Name', 'Date'])
            StudioMenuItem(
              label: sort,
              onPressed: () => setState(() => order = sort),
            ),
        ],
        builder: (_, toggle, open) =>
            StudioButton('Sort files', onPressed: toggle),
      ),
      const SizedBox(height: 12),
      Text('Sort order: $order'),
    ],
  );
}

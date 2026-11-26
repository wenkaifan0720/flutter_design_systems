import 'package:flutter/widgets.dart';
import 'package:clay_ui/clay_ui.dart';

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
      ClayMenu(
        semanticLabel: 'Sort files',
        items: [
          for (final sort in ['Name', 'Date'])
            ClayMenuItem(
              label: sort,
              onPressed: () => setState(() => order = sort),
            ),
        ],
        builder: (_, toggle, open) =>
            ClayButton('Sort files', onPressed: toggle),
      ),
      const SizedBox(height: 12),
      Text('Sort order: $order'),
    ],
  );
}

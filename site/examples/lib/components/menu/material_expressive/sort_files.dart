import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

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
      ExpressiveMenu(
        label: 'Sort files',
        builder: (_, menu) =>
            ExpressiveFilledButton('Sort files', onPressed: menu.toggle),
        entries: [
          for (final sort in ['Name', 'Date'])
            ExpressiveMenuItem(
              sort,
              onPressed: () => setState(() => order = sort),
            ),
        ],
      ),
      const SizedBox(height: 12),
      Text('Sort order: $order'),
    ],
  );
}

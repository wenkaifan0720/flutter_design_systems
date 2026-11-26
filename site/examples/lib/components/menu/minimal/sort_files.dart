import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show Icons;
import 'package:minimal_ui/minimal_ui.dart';

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
      MinimalMenu.button(
        Icons.sort,
        text: order,
        label: 'Sort files',
        items: [
          for (final sort in ['Name', 'Date'])
            MinimalMenuItem(
              sort,
              selected: order == sort,
              onPressed: () => setState(() => order = sort),
            ),
        ],
      ),
      const SizedBox(height: 12),
      Text('Sort order: $order'),
    ],
  );
}

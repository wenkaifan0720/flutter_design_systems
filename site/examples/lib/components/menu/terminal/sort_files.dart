import 'package:flutter/widgets.dart';
import 'package:terminal_ui/terminal_ui.dart';

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
      TermMenu(
        semanticLabel: 'Sort files',
        anchorBuilder: (_, a) =>
            TermButton(label: 'Sort files', onPressed: a.toggle),
        items: [
          for (final sort in ['Name', 'Date'])
            TermMenuItem(
              label: sort,
              onPressed: () => setState(() => order = sort),
            ),
        ],
      ),
      const SizedBox(height: 12),
      Text('Sort order: $order'),
    ],
  );
}

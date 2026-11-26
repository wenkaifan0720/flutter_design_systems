import 'package:flutter/widgets.dart';
import 'package:appliance_ui/appliance_ui.dart';

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
      ApplianceMenu(
        semanticLabel: 'Sort files',
        entries: [
          for (final sort in ['Name', 'Date'])
            RawMenuEntry(
              label: sort,
              onPressed: () => setState(() => order = sort),
            ),
        ],
        builder: (_, anchor) =>
            ApplianceButton('Sort files', onPressed: anchor.toggle),
      ),
      const SizedBox(height: 12),
      Text('Sort order: $order'),
    ],
  );
}

import 'package:flutter/widgets.dart';
import 'package:keycap_ui/keycap_ui.dart';

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
      KeycapMenu(
        semanticLabel: 'Sort files',
        entries: [
          for (final sort in ['Name', 'Date'])
            RawMenuEntry(
              label: sort,
              onPressed: () => setState(() => order = sort),
            ),
        ],
        builder: (_, anchor) => KeycapButton(
          onPressed: anchor.toggle,
          child: const Text('Sort files'),
        ),
      ),
      const SizedBox(height: 12),
      Text('Sort order: $order'),
    ],
  );
}

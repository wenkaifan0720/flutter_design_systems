import 'package:flutter/widgets.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';

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
      Builder(
        builder: (anchor) => Fluent2Button(
          'Sort files',
          onPressed: () async {
            final sort = await Fluent2Menu.show<String>(
              anchor,
              semanticLabel: 'Sort files',
              items: const [
                Fluent2MenuItem('Name', 'Name'),
                Fluent2MenuItem('Date', 'Date'),
              ],
            );
            if (mounted && sort != null) setState(() => order = sort);
          },
        ),
      ),
      const SizedBox(height: 12),
      Text('Sort order: $order'),
    ],
  );
}

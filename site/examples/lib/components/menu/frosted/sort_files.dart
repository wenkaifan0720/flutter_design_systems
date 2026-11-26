import 'package:flutter/widgets.dart';
import 'package:frosted_ui/frosted_ui.dart';

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
        builder: (anchor) => FrostedButton(
          'Sort files',
          onPressed: () async {
            final sort = await FrostedMenu.show<String>(
              anchor,
              label: 'Sort files',
              items: const [
                FrostedMenuItem('Name', 'Name'),
                FrostedMenuItem('Date', 'Date'),
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

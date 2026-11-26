import 'package:flutter/widgets.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

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
        builder: (anchor) => NeumorphicButton(
          'Sort files',
          onPressed: () async {
            final box = anchor.findRenderObject()! as RenderBox;
            final sort = await showNeumorphicMenu<String>(
              anchor,
              anchor: box.localToGlobal(Offset.zero) & box.size,
              label: 'Sort files',
              items: const [
                NeumorphicMenuItem('Name', 'Name'),
                NeumorphicMenuItem('Date', 'Date'),
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

import 'package:flutter/widgets.dart';
import 'package:comic_ui/comic_ui.dart';

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
      ComicMenuAnchor<String>(
        items: const [
          ComicMenuItem('Name', 'Name'),
          ComicMenuItem('Date', 'Date'),
        ],
        builder: (_, open) => ComicButton('Sort files', onPressed: open),
        onSelected: (sort) => setState(() => order = sort),
      ),
      const SizedBox(height: 12),
      Text('Sort order: $order'),
    ],
  );
}

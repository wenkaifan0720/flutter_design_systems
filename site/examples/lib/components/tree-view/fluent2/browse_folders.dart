import 'package:flutter/widgets.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';

class BrowseFolders extends StatelessWidget {
  const BrowseFolders({super.key});
  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 440),
    child: SingleChildScrollView(
      child: const Fluent2Tree<String>(
        semanticLabel: 'Folders',
        items: [
          Fluent2TreeItem(
            'files',
            'Files',
            children: [
              Fluent2TreeItem('notes', 'Notes'),
              Fluent2TreeItem('maps', 'Maps'),
            ],
          ),
        ],
      ),
    ),
  );
}

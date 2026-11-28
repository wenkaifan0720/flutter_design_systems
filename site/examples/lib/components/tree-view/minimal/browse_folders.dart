import 'package:flutter/widgets.dart';
import 'package:minimal_ui/minimal_ui.dart';

class BrowseFolders extends StatelessWidget {
  const BrowseFolders({super.key});
  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 440),
    child: SingleChildScrollView(
      child: MinimalTreeView<String>(
        semanticLabel: 'Folders',
        roots: const ['Files'],
        childrenOf: (folder) =>
            folder == 'Files' ? const ['Notes', 'Maps'] : const [],
        labelOf: (folder) => folder,
      ),
    ),
  );
}

import 'package:flutter/widgets.dart';
import 'package:studio_ui/studio_ui.dart';

class BrowseFolders extends StatefulWidget {
  const BrowseFolders({super.key});
  @override
  State<BrowseFolders> createState() => _BrowseFoldersState();
}

class _BrowseFoldersState extends State<BrowseFolders> {
  final folders = StudioTreeController<String>(
    roots: const ['Files'],
    childrenOf: (folder) =>
        folder == 'Files' ? const ['Notes', 'Maps'] : const [],
  );
  @override
  void dispose() {
    folders.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 440),
    child: SingleChildScrollView(
      child: StudioTree<String>(
        semanticLabel: 'Folders',
        controller: folders,
        labelOf: (folder) => folder,
      ),
    ),
  );
}

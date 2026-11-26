import 'package:flutter/widgets.dart';
import 'package:comic_ui/comic_ui.dart';

class ResizePanes extends StatelessWidget {
  const ResizePanes({super.key});
  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 640),
    child: const SizedBox(
      height: 140,
      child: ComicResizable(
        minFirst: 88,
        minSecond: 88,
        first: Center(child: Text('Files')),
        second: Center(child: Text('Notes')),
      ),
    ),
  );
}

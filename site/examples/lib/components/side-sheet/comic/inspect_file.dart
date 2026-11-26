import 'package:flutter/widgets.dart';
import 'package:comic_ui/comic_ui.dart';

class InspectFile extends StatelessWidget {
  const InspectFile({super.key});

  @override
  Widget build(BuildContext context) => ComicButton(
    'File details',
    onPressed: () => showComicSheet<void>(
      context,
      builder: (_) => const ComicSheet(
        title: 'File details',
        child: Text('Owner: Mara Chen\nLast edited: 14 June'),
      ),
    ),
  );
}

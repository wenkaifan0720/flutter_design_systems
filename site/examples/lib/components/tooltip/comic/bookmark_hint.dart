import 'package:flutter/widgets.dart';
import 'package:comic_ui/comic_ui.dart';

class BookmarkHint extends StatefulWidget {
  const BookmarkHint({super.key});
  @override
  State<BookmarkHint> createState() => _BookmarkHintState();
}

class _BookmarkHintState extends State<BookmarkHint> {
  bool saved = false;

  @override
  Widget build(BuildContext context) => ComicTooltip(
    message: saved ? 'Remove from Saved files' : 'Keep in Saved files',
    child: ComicButton(
      saved ? 'Remove bookmark' : 'Bookmark',
      onPressed: () => setState(() => saved = !saved),
    ),
  );
}

import 'package:flutter/widgets.dart';
import 'package:brutal_ui/brutal_ui.dart';

class BookmarkHint extends StatefulWidget {
  const BookmarkHint({super.key});
  @override
  State<BookmarkHint> createState() => _BookmarkHintState();
}

class _BookmarkHintState extends State<BookmarkHint> {
  bool saved = false;

  @override
  Widget build(BuildContext context) => BrutalTooltip(
    message: saved ? 'Remove from Saved files' : 'Keep in Saved files',
    child: BrutalButton(
      saved ? 'Remove bookmark' : 'Bookmark',
      onPressed: () => setState(() => saved = !saved),
    ),
  );
}

import 'package:material_ui/material_ui.dart';

class BookmarkHint extends StatefulWidget {
  const BookmarkHint({super.key});
  @override
  State<BookmarkHint> createState() => _BookmarkHintState();
}

class _BookmarkHintState extends State<BookmarkHint> {
  bool saved = false;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: saved ? 'Remove from Saved files' : 'Keep in Saved files',
    child: OutlinedButton.icon(
      onPressed: () => setState(() => saved = !saved),
      icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border),
      label: Text(saved ? 'Remove bookmark' : 'Bookmark'),
    ),
  );
}

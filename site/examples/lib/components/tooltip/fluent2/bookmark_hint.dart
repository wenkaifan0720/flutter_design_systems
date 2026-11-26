import 'package:flutter/widgets.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';

class BookmarkHint extends StatefulWidget {
  const BookmarkHint({super.key});
  @override
  State<BookmarkHint> createState() => _BookmarkHintState();
}

class _BookmarkHintState extends State<BookmarkHint> {
  bool saved = false;

  @override
  Widget build(BuildContext context) => Fluent2Tooltip(
    message: saved ? 'Remove from Saved files' : 'Keep in Saved files',
    child: Fluent2Button(
      saved ? 'Remove bookmark' : 'Bookmark',
      onPressed: () => setState(() => saved = !saved),
    ),
  );
}

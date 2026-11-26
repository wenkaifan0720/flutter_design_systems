import 'package:flutter/widgets.dart';
import 'package:keycap_ui/keycap_ui.dart';

class BookmarkHint extends StatefulWidget {
  const BookmarkHint({super.key});
  @override
  State<BookmarkHint> createState() => _BookmarkHintState();
}

class _BookmarkHintState extends State<BookmarkHint> {
  bool saved = false;

  @override
  Widget build(BuildContext context) => KeycapTooltip(
    message: saved ? 'Remove from Saved files' : 'Keep in Saved files',
    child: KeycapButton(
      onPressed: () => setState(() => saved = !saved),
      child: Text(saved ? 'Remove bookmark' : 'Bookmark'),
    ),
  );
}

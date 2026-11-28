import 'package:flutter/widgets.dart';
import 'package:comic_ui/comic_ui.dart';

class ArchiveNote extends StatefulWidget {
  const ArchiveNote({super.key});
  @override
  State<ArchiveNote> createState() => _ArchiveNoteState();
}

class _ArchiveNoteState extends State<ArchiveNote> {
  bool archived = false;
  bool read = false;
  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 440),
    child: archived
        ? ComicButton(
            'Restore note',
            onPressed: () => setState(() {
              archived = false;
              read = false;
            }),
          )
        : ComicSwipeActions(
            endActions: [
              RawSwipeAction(
                label: 'Archive',
                onPressed: () => setState(() => archived = true),
              ),
            ],
            child: ComicListTile(
              title: 'Route note',
              subtitle: read ? 'Read' : 'Unread',
              semanticLabel: read ? 'Route note, read' : 'Route note, unread',
              onPressed: () => setState(() => read = !read),
            ),
          ),
  );
}

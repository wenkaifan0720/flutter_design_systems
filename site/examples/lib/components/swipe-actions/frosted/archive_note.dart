import 'package:flutter/widgets.dart';
import 'package:frosted_ui/frosted_ui.dart';

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
        ? FrostedButton(
            'Restore note',
            onPressed: () => setState(() {
              archived = false;
              read = false;
            }),
          )
        : FrostedSwipeActions(
            trailing: [
              FrostedSwipeAction(
                label: 'Archive',
                icon: FrostedGlyphs.file,
                onPressed: () => setState(() => archived = true),
              ),
            ],
            child: FrostedListTile(
              title: 'Route note',
              meta: read ? 'Read' : 'Unread',
              onPressed: () => setState(() => read = !read),
            ),
          ),
  );
}

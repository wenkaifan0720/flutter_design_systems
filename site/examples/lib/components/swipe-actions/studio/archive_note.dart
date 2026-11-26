import 'package:flutter/widgets.dart';
import 'package:studio_ui/studio_ui.dart';

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
        ? StudioButton(
            'Restore note',
            onPressed: () => setState(() {
              archived = false;
              read = false;
            }),
          )
        : StudioSwipeRow(
            endActions: [
              StudioSwipeAction(
                label: 'Archive',
                onPressed: () => setState(() => archived = true),
              ),
            ],
            child: StudioListTile(
              title: 'Route note',
              subtitle: read ? 'Read' : 'Unread',
              onTap: () => setState(() => read = !read),
            ),
          ),
  );
}

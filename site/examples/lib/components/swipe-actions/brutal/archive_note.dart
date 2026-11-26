import 'package:flutter/widgets.dart';
import 'package:brutal_ui/brutal_ui.dart';

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
        ? BrutalButton(
            'Restore note',
            onPressed: () => setState(() {
              archived = false;
              read = false;
            }),
          )
        : BrutalSwipeRow(
            endActions: [
              BrutalSwipeAction(
                label: 'Archive',
                onPressed: () => setState(() => archived = true),
              ),
            ],
            child: BrutalListTile(
              title: 'Route note',
              subtitle: read ? 'Read' : 'Unread',
              onTap: () => setState(() => read = !read),
            ),
          ),
  );
}

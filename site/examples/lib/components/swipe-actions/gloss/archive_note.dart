import 'package:flutter/widgets.dart';
import 'package:gloss_ui/gloss_ui.dart';

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
        ? GlossButton(
            'Restore note',
            onPressed: () => setState(() {
              archived = false;
              read = false;
            }),
          )
        : GlossSwipeRow(
            endActions: [
              GlossSwipeAction(
                label: 'Archive',
                onPressed: () => setState(() => archived = true),
              ),
            ],
            child: GlossListTile(
              title: 'Route note',
              subtitle: read ? 'Read' : 'Unread',
              onTap: () => setState(() => read = !read),
            ),
          ),
  );
}

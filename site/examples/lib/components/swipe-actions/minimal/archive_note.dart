import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show Icons;
import 'package:minimal_ui/minimal_ui.dart';

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
        ? MinimalButton(
            'Restore note',
            onPressed: () => setState(() {
              archived = false;
              read = false;
            }),
          )
        : MinimalSwipeActions(
            trailing: [
              MinimalSwipeAction(
                'Archive',
                onPressed: () => setState(() => archived = true),
              ),
              // A delete marks itself destructive: the danger tone and a bin.
              MinimalSwipeAction(
                'Delete',
                icon: Icons.delete_outline,
                destructive: true,
                onPressed: () => setState(() => archived = true),
              ),
            ],
            child: MinimalListTile(
              title: 'Route note',
              subtitle: read ? 'Read' : 'Unread',
              onTap: () => setState(() => read = !read),
            ),
          ),
  );
}

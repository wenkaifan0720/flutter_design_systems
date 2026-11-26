import 'package:flutter/widgets.dart';
import 'package:keycap_ui/keycap_ui.dart';

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
        ? KeycapButton(
            onPressed: () => setState(() {
              archived = false;
              read = false;
            }),
            child: const Text('Restore note'),
          )
        : KeycapSwipeActions(
            endActions: [
              RawSwipeAction(
                label: 'Archive',
                onPressed: () => setState(() => archived = true),
              ),
            ],
            child: KeycapListTile(
              title: 'Route note',
              subtitle: read ? 'Read' : 'Unread',
              onTap: () => setState(() => read = !read),
            ),
          ),
  );
}

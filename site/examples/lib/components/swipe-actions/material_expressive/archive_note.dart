import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

class ArchiveNote extends StatefulWidget {
  const ArchiveNote({super.key});
  @override
  State<ArchiveNote> createState() => _ArchiveNoteState();
}

class _ArchiveNoteState extends State<ArchiveNote> {
  bool archived = false;
  bool read = false;

  void archive() => setState(() => archived = true);

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 440),
    child: SingleChildScrollView(
      child: archived
          ? ExpressiveOutlinedButton(
              'Restore note',
              onPressed: () => setState(() {
                archived = false;
                read = false;
              }),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExpressiveSwipeActions(
                  trailing: [
                    ExpressiveSwipeAction(
                      label: 'Archive',
                      icon: ExpressiveSymbols.archive,
                      onPressed: archive,
                    ),
                  ],
                  child: ExpressiveListTile(
                    title: const Text('Route note'),
                    subtitle: Text(read ? 'Read' : 'Unread'),
                    onTap: () => setState(() => read = !read),
                  ),
                ),
                const SizedBox(height: 12),
                ExpressiveOutlinedButton('Archive note', onPressed: archive),
              ],
            ),
    ),
  );
}

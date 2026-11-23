/// Jotter's folders: each with its count, and the choice of folder the
/// move sheet offers.
library;

import 'package:material_ui/material_ui.dart';
import 'package:keycap_ui/keycap_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'data.dart';
import 'jotter.dart';

/// The folders.
class JotterFolders extends StatelessWidget {
  /// The folders.
  const JotterFolders({super.key});

  @override
  Widget build(BuildContext context) {
    final frame = JotterFrame.of(context);
    final notes = frame.notes;
    final tags = <String, int>{};
    for (final n in notes) {
      for (final t in n.tags) {
        tags[t] = (tags[t] ?? 0) + 1;
      }
    }
    final folders = KeycapListGroup(
      header: 'Folders',
      children: [
        for (final f in jotterFolders)
          KeycapListTile(
            leading: Icon(f.icon),
            title: f.name,
            trailingText: '${jotterCount(notes, f.id)}',
            onTap: () => frame.showFolder(f.id),
          ),
      ],
    );
    // A tag's row searches for it, so its count stands where a folder's does.
    final tagged = KeycapListGroup(
      header: 'Tags',
      children: [
        for (final e in tags.entries)
          KeycapListTile(
            leading: const Icon(LucideIcons.hash),
            title: e.key,
            trailingText: '${e.value}',
            onTap: () => frame.searchFor(e.key),
          ),
      ],
    );
    final two = MediaQuery.sizeOf(context).width >= 1024;
    return JotterPage(
      title: 'Folders',
      maxWidth: two ? KeycapScreen.pageWidth : KeycapMetrics.readingWidth,
      actions: [
        KeycapButton(
          icon: const Icon(LucideIcons.folderPlus),
          onPressed: () => showKeycapToast(context, 'New folder added'),
          child: const Text('New folder'),
        ),
      ],
      // From 1024 the folders and the tags stand side by side.
      children: two
          ? [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: folders),
                  const SizedBox(width: KeycapSpacing.extraLarge),
                  Expanded(child: tagged),
                ],
              ),
            ]
          : [folders, jotterGroupGap, tagged],
    );
  }
}

/// The folders as a radio list, for the move sheet: [initial] chosen,
/// Move calls [onChosen].
class JotterFolderChoice extends StatefulWidget {
  /// A choice of folder.
  const JotterFolderChoice({
    super.key,
    required this.notes,
    required this.initial,
    required this.onChosen,
  });

  /// The notebook, for the counts.
  final List<JotterNote> notes;

  /// The folder the note is in.
  final String initial;

  /// Called with the folder chosen.
  final ValueChanged<String> onChosen;

  @override
  State<JotterFolderChoice> createState() => _JotterFolderChoiceState();
}

class _JotterFolderChoiceState extends State<JotterFolderChoice> {
  late String _to = widget.initial;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      KeycapRadioGroup<String>(
        semanticLabel: 'Folder',
        options: [for (final f in jotterFolders) f.id],
        groupValue: _to,
        labelOf: (id) =>
            '${jotterFolder(id).name} (${jotterCount(widget.notes, id)})',
        onChanged: (v) => setState(() => _to = v),
      ),
      const SizedBox(height: KeycapSpacing.large),
      SizedBox(
        width: double.infinity,
        child: _MoveKey(
          to: _to,
          from: widget.initial,
          onChosen: widget.onChosen,
        ),
      ),
    ],
  );
}

/// Moving a note from 600 wide: the folders in a dialog, Cancel and the
/// move at its foot.
class JotterMoveDialog extends StatefulWidget {
  /// A dialog moving a note from [initial].
  const JotterMoveDialog({
    super.key,
    required this.notes,
    required this.initial,
  });

  /// Every note, for the folders' counts.
  final List<JotterNote> notes;

  /// The folder the note is in.
  final String initial;

  @override
  State<JotterMoveDialog> createState() => _JotterMoveDialogState();
}

class _JotterMoveDialogState extends State<JotterMoveDialog> {
  late String _to = widget.initial;

  @override
  Widget build(BuildContext context) => KeycapDialog(
    title: 'Move to folder',
    content: KeycapRadioGroup<String>(
      semanticLabel: 'Folder',
      options: [for (final f in jotterFolders) f.id],
      groupValue: _to,
      labelOf: (id) =>
          '${jotterFolder(id).name} (${jotterCount(widget.notes, id)})',
      onChanged: (v) => setState(() => _to = v),
    ),
    actions: [
      KeycapButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      _MoveKey(
        to: _to,
        from: widget.initial,
        onChosen: (f) => Navigator.of(context).pop(f),
      ),
    ],
  );
}

// The move's key: off while the folder chosen is the note's own, and saying
// so.
class _MoveKey extends StatelessWidget {
  const _MoveKey({
    required this.to,
    required this.from,
    required this.onChosen,
  });

  final String to;
  final String from;
  final ValueChanged<String> onChosen;

  @override
  Widget build(BuildContext context) => KeycapButton.accent(
    onPressed: to == from ? null : () => onChosen(to),
    child: Text(
      to == from
          ? 'Already in ${jotterFolder(to).name}'
          : 'Move to ${jotterFolder(to).name}',
    ),
  );
}

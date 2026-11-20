/// Jotter's Notes: every note, by folder and by filter. From 1024 wide the
/// list and the open note stand side by side.
library;

import 'package:material_ui/material_ui.dart';
import 'package:keycap_ui/keycap_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'data.dart';
import 'editor.dart';
import 'jotter.dart';

/// The notes list (and, from 1024, the editor beside it).
class JotterNotes extends StatelessWidget {
  /// The notes.
  const JotterNotes({super.key});

  @override
  Widget build(BuildContext context) {
    final frame = JotterFrame.of(context);
    final theme = context.keycapTheme;
    // From 600 the rail and the side column carry the New note key.
    final actions = [
      KeycapIconButton(
        icon: const Icon(LucideIcons.search),
        semanticLabel: 'Search notes',
        onPressed: frame.search,
        style: const KeycapStyle(
          minimumSize: WidgetStatePropertyAll(
            Size.square(KeycapAppBar.keySide),
          ),
        ),
      ),
      if (!frame.wide)
        KeycapIconButton(
          icon: const Icon(LucideIcons.squarePen),
          semanticLabel: 'New note',
          onPressed: frame.newNote,
          style: const KeycapStyle(
            minimumSize: WidgetStatePropertyAll(
              Size.square(KeycapAppBar.keySide),
            ),
          ),
        ),
    ];
    if (!frame.split) {
      return JotterPage(
        title: 'Notes',
        actions: actions,
        maxWidth: KeycapMetrics.readingWidth,
        children: const [
          _Filters(),
          SizedBox(height: KeycapSpacing.large),
          _List(),
        ],
      );
    }
    // The pane shows the open note while the list holds it, else the
    // list's first; with nothing in the list, nothing is open.
    final shown = frame.shownNotes;
    final open =
        shown.where((n) => n.id == frame.openNote).firstOrNull ??
        shown.firstOrNull;
    return ColoredBox(
      color: theme.colors.ground,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 400,
            child: KeycapScreen(
              topBar: KeycapAppBar(title: 'Notes', actions: actions),
              body: const Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Filters(),
                  SizedBox(height: KeycapSpacing.large),
                  _List(),
                ],
              ),
            ),
          ),
          const KeycapDivider(vertical: true),
          Expanded(
            child: open == null
                ? const Center(
                    child: KeycapEmptyState(
                      icon: LucideIcons.notebookText,
                      title: 'No note open',
                      message: 'Pick a note in the list to read it here.',
                    ),
                  )
                : JotterEditorPane(key: ValueKey(open.id), noteId: open.id),
          ),
        ],
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters();

  @override
  Widget build(BuildContext context) {
    final frame = JotterFrame.of(context);
    final notes = frame.notes;
    final select = KeycapSelect<String?>(
      semanticLabel: 'Folder',
      value: frame.folder,
      items: [
        KeycapSelectItem(value: null, label: 'All folders (${notes.length})'),
        for (final f in jotterFolders)
          KeycapSelectItem(
            value: f.id,
            label: '${f.name} (${jotterCount(notes, f.id)})',
          ),
      ],
      onChanged: frame.showFolder,
    );
    final filter = KeycapSegmentedButton<String>(
      semanticLabel: 'Show',
      segments: const [
        KeycapSegment(value: 'all', label: 'All'),
        KeycapSegment(value: 'drafts', label: 'Drafts'),
        KeycapSegment(value: 'pinned', label: 'Pinned'),
      ],
      selected: {frame.filter},
      onSelectionChanged: (s) => frame.showFilter(s.first),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        select,
        const SizedBox(height: KeycapSpacing.medium),
        filter,
      ],
    );
  }
}

class _List extends StatelessWidget {
  const _List();

  @override
  Widget build(BuildContext context) {
    final frame = JotterFrame.of(context);
    final shown = frame.shownNotes;
    if (shown.isEmpty) {
      final where = frame.folder == null
          ? 'your notebook'
          : jotterFolder(frame.folder!).name;
      final filtered = frame.filter != 'all';
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: KeycapSpacing.large),
        child: KeycapEmptyState(
          icon: filtered ? LucideIcons.listFilter : LucideIcons.notebook,
          title: switch (frame.filter) {
            'drafts' => 'No drafts in $where',
            'pinned' => 'No pinned notes in $where',
            _ => 'No notes in $where yet',
          },
          message: filtered
              ? 'Try another filter, or show them all.'
              : 'Notes you write in this folder show up here.',
          action: filtered
              ? KeycapButton(
                  onPressed: () => frame.showFilter('all'),
                  child: const Text('Show all notes'),
                )
              : null,
        ),
      );
    }
    return KeycapListGroup(
      header: '${shown.length} ${shown.length == 1 ? 'note' : 'notes'}',
      children: [
        for (final n in shown)
          KeycapListTile(
            title: n.title.isEmpty ? 'Untitled' : n.title,
            subtitle: n.excerpt.isEmpty ? 'No words yet' : n.excerpt,
            trailingText: n.editedShort,
            showChevron: false,
            selected:
                frame.split &&
                n.id ==
                    (shown.any((s) => s.id == frame.openNote)
                        ? frame.openNote
                        : shown.first.id),
            onTap: () => frame.open(n.id),
          ),
      ],
    );
  }
}

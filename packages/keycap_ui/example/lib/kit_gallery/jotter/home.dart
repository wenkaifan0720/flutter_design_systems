/// Jotter's Home: the pinned draft to go back to, the folders as a cluster
/// of keys, and the notes written lately.
library;

import 'package:material_ui/material_ui.dart';
import 'package:keycap_ui/keycap_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'data.dart';
import 'jotter.dart';

/// Home.
class JotterHome extends StatelessWidget {
  /// Home.
  const JotterHome({super.key});

  @override
  Widget build(BuildContext context) {
    final frame = JotterFrame.of(context);
    final notes = frame.notes;
    final pinned = notes.where((n) => n.pinned).firstOrNull;
    final recent = notes.where((n) => n != pinned).take(4).toList();
    final twoColumns = MediaQuery.sizeOf(context).width >= 1024;
    final lead = <Widget>[
      if (pinned != null) _PinnedDraft(note: pinned),
      jotterGroupGap,
      KeycapListGroup(
        header: 'Recent',
        children: [
          for (final n in recent)
            KeycapListTile(
              title: n.title.isEmpty ? 'Untitled' : n.title,
              subtitle: n.excerpt,
              trailingText: n.editedShort,
              showChevron: false,
              onTap: () => frame.open(n.id),
            ),
          // The way on to the rest is a row of the list, not words printed
          // over it.
          KeycapListTile(
            title: 'All notes',
            trailingText: '${notes.length}',
            onTap: () => frame.showFolder(null),
          ),
        ],
      ),
    ];
    final folders = _FolderKeys(notes: notes);
    // When sync fails, the news stands over everything, the notes safe.
    final news = <Widget>[
      if (frame.syncFailed) ...[
        KeycapBanner(
          tone: KeycapTone.warning,
          title: 'Couldn’t sync',
          message:
              '3 changes are saved on this device. Jotter tries again '
              'every minute.',
          actions: [
            KeycapButton(
              onPressed: frame.syncing ? null : frame.retrySync,
              child: Text(frame.syncing ? 'Syncing…' : 'Try again'),
            ),
          ],
        ),
        const SizedBox(height: KeycapSpacing.large),
      ],
    ];
    return JotterPage(
      // From 600 the side column carries the name; the page is Home.
      title: frame.wide ? 'Home' : 'Jotter',
      actions: [
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
      ],
      children: twoColumns
          ? [
              ...news,
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: lead,
                    ),
                  ),
                  const SizedBox(width: KeycapSpacing.extraLarge),
                  Expanded(flex: 2, child: folders),
                ],
              ),
            ]
          : [...news, ...lead, jotterGroupGap, folders],
    );
  }
}

class _PinnedDraft extends StatelessWidget {
  const _PinnedDraft({required this.note});

  final JotterNote note;

  @override
  Widget build(BuildContext context) {
    final theme = context.keycapTheme;
    final frame = JotterFrame.of(context);
    final folder = jotterFolder(note.folder);
    final narrow = MediaQuery.sizeOf(context).width < 600;
    final go = KeycapButton.accent(
      icon: const Icon(LucideIcons.penLine),
      onPressed: () => frame.open(note.id),
      child: const Text('Continue writing'),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const KeycapSectionHeader('Pinned draft'),
        KeycapCard(
          padding: const EdgeInsets.fromLTRB(
            KeycapSpacing.regular,
            KeycapSpacing.regular,
            KeycapSpacing.regular,
            KeycapSpacing.regular,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(note.title, style: theme.textTheme.title),
              const SizedBox(height: KeycapSpacing.small),
              Text(
                note.excerpt,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.body.copyWith(
                  color: theme.colors.inkMuted,
                ),
              ),
              const SizedBox(height: KeycapSpacing.medium),
              Text(
                '${folder.name} · ${note.words} words · ${note.edited}',
                style: theme.textTheme.secondary,
              ),
              const SizedBox(height: KeycapSpacing.regular),
              if (narrow)
                go
              else
                Align(alignment: AlignmentDirectional.centerStart, child: go),
            ],
          ),
        ),
      ],
    );
  }
}

class _FolderKeys extends StatelessWidget {
  const _FolderKeys({required this.notes});

  final List<JotterNote> notes;

  @override
  Widget build(BuildContext context) {
    final frame = JotterFrame.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const KeycapSectionHeader('Folders'),
        LayoutBuilder(
          builder: (context, box) {
            final columns = box.maxWidth >= 560 ? 3 : 2;
            const gap = KeycapMetrics.keyGap * 2;
            final width = (box.maxWidth - gap * (columns - 1)) / columns;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final f in jotterFolders)
                  SizedBox(
                    width: width,
                    child: KeycapLegendKey(
                      icon: Icon(f.icon),
                      legend: f.name,
                      subLegend: '${jotterCount(notes, f.id)}',
                      semanticLabel:
                          '${f.name}, ${jotterCount(notes, f.id)} notes',
                      onPressed: () => frame.showFolder(f.id),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

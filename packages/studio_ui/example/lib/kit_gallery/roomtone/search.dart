/// Search: the library's shows and episodes found by a word in a name, a
/// host or the notes; recent searches before anything is typed, and a plain
/// answer when nothing matches.
library;

import 'package:material_ui/material_ui.dart';
import 'package:studio_ui/studio_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'data.dart';
import 'episode.dart';
import 'home.dart';
import 'roomtone.dart';
import 'words.dart';

const _recent = ['harbour', 'cello', 'Ines Okafor'];

/// The search page, opening on [initialQuery].
class RoomtoneSearchPage extends StatefulWidget {
  /// The page.
  const RoomtoneSearchPage({super.key, this.initialQuery = ''});

  /// What the field holds as it opens.
  final String initialQuery;

  @override
  State<RoomtoneSearchPage> createState() => _RoomtoneSearchPageState();
}

class _RoomtoneSearchPageState extends State<RoomtoneSearchPage> {
  late final _query = TextEditingController(text: widget.initialQuery);

  @override
  void initState() {
    super.initState();
    _query.addListener(_changed);
  }

  void _changed() => setState(() {});

  @override
  void dispose() {
    _query
      ..removeListener(_changed)
      ..dispose();
    super.dispose();
  }

  bool _has(String text, String q) => text.toLowerCase().contains(q);

  @override
  Widget build(BuildContext context) {
    final frame = RoomtoneFrame.of(context);
    final q = _query.text.trim().toLowerCase();
    final shows = q.isEmpty
        ? const <RoomtoneShow>[]
        : [
            for (final s in roomtoneShows)
              if (_has(s.name, q) || _has(s.host, q) || _has(s.blurb, q)) s,
          ];
    final episodes = q.isEmpty
        ? const <RoomtoneEpisode>[]
        : [
            for (final e in roomtoneEpisodes)
              if (_has(e.title, q) || _has(e.show.name, q) || _has(e.notes, q))
                e,
          ];
    final showsGroup = StudioListGroup(
      header: RoomtoneWords.of(context).shows(shows.length),
      children: [
        for (final s in shows)
          StudioListTile(
            leading: RoomtoneCover(show: s, size: 44),
            title: s.name,
            subtitle: s.host,
            onTap: () => showStudioToast(context, s.blurb),
          ),
      ],
    );
    final episodesGroup = StudioListGroup(
      header: RoomtoneWords.of(context).episodes(episodes.length),
      dividerIndent: StudioSpacing.regular + StudioListTile.leadingExtent + 20,
      children: [
        for (final e in episodes)
          roomtoneEpisodeRow(
            context,
            e,
            onTap: () => frame.push(RoomtoneEpisodePage(episode: e)),
          ),
      ],
    );
    return RoomtonePage(
      title: 'Search',
      maxWidth: roomtonePageWidth(context),
      children: [
        StudioSearchField(
          controller: _query,
          hintText: 'Shows, hosts, episodes',
          semanticLabel: 'Search the library',
        ),
        roomtoneGroupGap,
        if (q.isEmpty)
          StudioListGroup(
            header: 'Recent',
            children: [
              for (final r in _recent)
                StudioListTile(
                  leading: const Icon(LucideIcons.history),
                  title: r,
                  onTap: () => _query.text = r,
                ),
            ],
          )
        else if (shows.isEmpty && episodes.isEmpty)
          StudioStatusView(
            icon: const Icon(LucideIcons.searchX),
            title: 'Nothing for “${_query.text.trim()}”',
            message: "Try a show’s name, a host, or a word from the notes.",
            actionLabel: 'Clear the search',
            onAction: _query.clear,
          )
        else if (shows.isNotEmpty && episodes.isNotEmpty)
          ...roomtoneColumns(context, [showsGroup], [episodesGroup])
        else if (shows.isNotEmpty)
          showsGroup
        else
          episodesGroup,
      ],
    );
  }
}

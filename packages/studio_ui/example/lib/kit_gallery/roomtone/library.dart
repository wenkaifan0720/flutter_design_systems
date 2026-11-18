/// The Library: every episode of the shows the listener follows, filtered
/// by a bank of keys. On a desk the list and the open episode's player stand
/// side by side, the open row's lamp lit.
library;

import 'package:material_ui/material_ui.dart';
import 'package:studio_ui/studio_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'data.dart';
import 'episode.dart';
import 'home.dart';
import 'roomtone.dart';
import 'words.dart';
import 'search.dart';

enum _Filter { all, unplayed, downloaded }

/// The Library, [open] standing beside it on a desk.
class RoomtoneLibrary extends StatefulWidget {
  /// The Library.
  const RoomtoneLibrary({super.key, this.open, this.downloadedOnly = false});

  /// The episode open beside the list on a desk; the first when null.
  final RoomtoneEpisode? open;

  /// Whether it opens on the downloaded episodes alone.
  final bool downloadedOnly;

  @override
  State<RoomtoneLibrary> createState() => _RoomtoneLibraryState();
}

class _RoomtoneLibraryState extends State<RoomtoneLibrary> {
  late _Filter _filter = widget.downloadedOnly
      ? _Filter.downloaded
      : _Filter.all;
  late RoomtoneEpisode _open = widget.open ?? roomtoneEpisodes.first;

  List<RoomtoneEpisode> _shown(bool removed) => [
    for (final e in roomtoneEpisodes)
      if (switch (_filter) {
        _Filter.all => true,
        _Filter.unplayed => e.unplayed,
        _Filter.downloaded => e.downloaded && !removed,
      })
        e,
  ];

  @override
  Widget build(BuildContext context) {
    final frame = RoomtoneFrame.of(context);
    final theme = context.studioTheme;
    final desk = frame.desk;
    final prefs = RoomtonePrefs.of(context);
    final shown = _shown(prefs.downloadsRemoved);
    final filters = StudioSegmentedButton<_Filter>(
      semanticLabel: 'Show',
      expand: true,
      segments: const [
        StudioSegment(value: _Filter.all, label: 'All'),
        StudioSegment(value: _Filter.unplayed, label: 'Unplayed'),
        StudioSegment(value: _Filter.downloaded, label: 'Downloaded'),
      ],
      value: _filter,
      onChanged: (v) => setState(() => _filter = v),
    );
    final Widget list = shown.isEmpty
        ? StudioStatusView(
            icon: const Icon(LucideIcons.download),
            title: switch (_filter) {
              _Filter.downloaded => 'Nothing downloaded',
              _ => 'All played',
            },
            message: switch (_filter) {
              _Filter.downloaded =>
                'Download an episode to play it with no connection. '
                    'Downloads use Wi-Fi unless Settings says otherwise.',
              _ => 'New episodes of the shows you follow arrive here.',
            },
            actionLabel: 'Show every episode',
            onAction: () => setState(() => _filter = _Filter.all),
          )
        : StudioListGroup(
            header: RoomtoneWords.of(context).episodes(shown.length),
            dividerIndent:
                StudioSpacing.regular + StudioListTile.leadingExtent + 20,
            children: [
              for (final e in shown)
                roomtoneEpisodeRow(
                  context,
                  e,
                  selected: desk && e.id == _open.id,
                  onTap: desk
                      ? () => setState(() => _open = e)
                      : () => frame.push(RoomtoneEpisodePage(episode: e)),
                ),
            ],
          );
    final actions = [
      StudioIconButton(
        icon: const Icon(LucideIcons.search),
        tooltip: 'Search the library',
        onPressed: () => frame.push(const RoomtoneSearchPage()),
      ),
    ];
    if (!desk) {
      return RoomtonePage(
        title: 'Library',
        actions: actions,
        children: [
          filters,
          const SizedBox(height: StudioSpacing.large),
          list,
        ],
      );
    }
    final margin = StudioSpacing.pageMargin(MediaQuery.sizeOf(context).width);
    final c = theme.colors;
    return StudioSurface(
      face: StudioFace(
        fill: c.panel,
        fillLow: c.panelLow,
        depth: StudioDepth.level,
        radius: 0,
        brushed: true,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StudioAppBar(title: 'Library', actions: actions),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 440,
                  child: ListView(
                    padding: EdgeInsetsDirectional.fromSTEB(
                      margin,
                      StudioSpacing.large,
                      StudioSpacing.large,
                      StudioSpacing.huge,
                    ),
                    children: [
                      filters,
                      const SizedBox(height: StudioSpacing.large),
                      list,
                    ],
                  ),
                ),
                // The seam between the list's module and the player's.
                SizedBox(
                  width: 2,
                  child: Row(
                    children: [
                      Expanded(child: ColoredBox(color: c.groove)),
                      Expanded(child: ColoredBox(color: c.edgeLight)),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsetsDirectional.fromSTEB(
                      StudioSpacing.extraLarge,
                      StudioSpacing.large,
                      margin,
                      StudioSpacing.huge,
                    ),
                    children: [
                      Align(
                        alignment: AlignmentDirectional.topStart,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 640),
                          child: RoomtoneEpisodeDetail(
                            key: ValueKey(_open.id),
                            episode: _open,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

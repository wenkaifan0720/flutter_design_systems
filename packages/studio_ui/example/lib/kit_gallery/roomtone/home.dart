/// Home: the episode the listener is in the middle of, lit on its own pane
/// with its readout and play key, then the latest episodes of the shows they
/// follow, then their own drafts.
library;

import 'package:material_ui/material_ui.dart';
import 'package:studio_ui/studio_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'data.dart';
import 'episode.dart';
import 'roomtone.dart';
import 'words.dart';

/// Home.
class RoomtoneHome extends StatelessWidget {
  /// Home.
  const RoomtoneHome({super.key});

  @override
  Widget build(BuildContext context) {
    final frame = RoomtoneFrame.of(context);
    final wide = MediaQuery.sizeOf(context).width >= 1024;
    final lead = _ContinueListening(
      episode: roomtoneNowPlaying,
      onOpen: () =>
          frame.push(RoomtoneEpisodePage(episode: roomtoneNowPlaying)),
    );
    final latest = StudioListGroup(
      header: 'Latest episodes',
      dividerIndent: StudioSpacing.regular + StudioListTile.leadingExtent + 20,
      children: [
        // A desk has the room for the rest of the week.
        for (final e
            in roomtoneEpisodes.skip(1).take(roomtoneDesk(context) ? 6 : 4))
          roomtoneEpisodeRow(
            context,
            e,
            onTap: () => frame.push(RoomtoneEpisodePage(episode: e)),
          ),
      ],
    );
    final drafts = StudioListGroup(
      header: 'Your drafts',
      children: [
        StudioListTile(
          title: 'Episode 12: the neighbour with the bees',
          subtitle: 'Recorded yesterday · 41 min · 3 markers',
          leading: const Icon(LucideIcons.micVocal),
          onTap: () => frame.go(RoomtonePlace.record),
        ),
        StudioListTile(
          title: 'Trailer, take 4',
          subtitle: 'Recorded 9 Nov · 1 min',
          leading: const Icon(LucideIcons.micVocal),
          onTap: () => frame.go(RoomtonePlace.record),
        ),
      ],
    );
    return RoomtonePage(
      title: 'Home',
      maxWidth: wide ? 1080 : StudioMetrics.readingWidth,
      actions: [
        StudioIconButton(
          icon: const Icon(LucideIcons.search),
          tooltip: 'Search',
          onPressed: () => frame.go(RoomtonePlace.library),
        ),
      ],
      children: wide
          ? [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [lead, roomtoneGroupGap, drafts],
                    ),
                  ),
                  const SizedBox(width: StudioSpacing.extraLarge),
                  Expanded(flex: 6, child: latest),
                ],
              ),
            ]
          : [lead, roomtoneGroupGap, latest, roomtoneGroupGap, drafts],
    );
  }
}

/// A row of an episode in a list: its show's tile, its title, its show,
/// date and length or what is left.
Widget roomtoneEpisodeRow(
  BuildContext context,
  RoomtoneEpisode e, {
  required VoidCallback onTap,
  bool selected = false,
}) => StudioListTile(
  leading: RoomtoneCover(show: e.show, size: 44),
  title: e.title,
  subtitle: [
    e.show.name,
    e.published,
    if (e.started)
      RoomtoneWords.of(context).timeLeft(e.minutesLeft)
    else
      RoomtoneWords.of(context).minutes(e.minutes),
  ].join(' · '),
  selected: selected,
  onTap: onTap,
);

class _ContinueListening extends StatefulWidget {
  const _ContinueListening({required this.episode, required this.onOpen});

  final RoomtoneEpisode episode;
  final VoidCallback onOpen;

  @override
  State<_ContinueListening> createState() => _ContinueListeningState();
}

class _ContinueListeningState extends State<_ContinueListening> {
  bool _playing = false;

  @override
  Widget build(BuildContext context) {
    final theme = context.studioTheme;
    final t = theme.textTheme;
    final c = theme.colors;
    final e = widget.episode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const StudioSectionHeader('Continue listening'),
        StudioDisplay(
          onTap: widget.onOpen,
          semanticLabel:
              'Continue ${e.title}, ${e.show.name}, '
              '${RoomtoneWords.of(context).timeLeft(e.minutesLeft)}',
          padding: const EdgeInsets.all(StudioSpacing.regular),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // At large text the cover stands over the words, which keep
              // the card's width.
              Flex(
                direction: MediaQuery.textScalerOf(context).scale(1) > 1.4
                    ? Axis.vertical
                    : Axis.horizontal,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RoomtoneCover(show: e.show, size: 64),
                  const SizedBox(
                    width: StudioSpacing.regular,
                    height: StudioSpacing.medium,
                  ),
                  Flexible(
                    flex: MediaQuery.textScalerOf(context).scale(1) > 1.4
                        ? 0
                        : 1,
                    fit: FlexFit.tight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.show.name,
                          style: t.secondary.copyWith(color: c.onDisplayMuted),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          e.title,
                          style: t.title.copyWith(
                            color: c.onDisplay,
                            fontSize: 20,
                            height: 26 / 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: StudioSpacing.regular),
              Row(
                children: [
                  Expanded(
                    child: ExcludeSemantics(
                      child: StudioMeter(
                        level: e.progress,
                        segments: 32,
                        clip: 1.1,
                        thickness: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: StudioSpacing.medium),
                  Text(
                    RoomtoneWords.of(context).timeLeft(e.minutesLeft),
                    style: t.caption.copyWith(
                      color: c.onDisplayMuted,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: StudioSpacing.medium),
        Row(
          children: [
            Expanded(
              child: StudioButton.lit(
                _playing ? 'Pause' : 'Resume',
                icon: Icon(_playing ? LucideIcons.pause : LucideIcons.play),
                onPressed: () => setState(() => _playing = !_playing),
              ),
            ),
            const SizedBox(width: StudioSpacing.medium),
            StudioButton(
              'Queue',
              icon: const Icon(LucideIcons.listMusic),
              onPressed: () => showStudioToast(context, 'Queue is empty'),
            ),
          ],
        ),
      ],
    );
  }
}

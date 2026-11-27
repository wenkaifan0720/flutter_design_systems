/// Home: the episode the listener is in the middle of, lit on its own pane
/// with its readout and play key, then the latest episodes of the shows they
/// follow, then their own drafts. A desk with a rack's width sets the whole
/// player beside the latest, and the shows they follow beside the drafts.
library;

import 'package:material_ui/material_ui.dart';
import 'package:studio_ui/studio_ui.dart';

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
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 1024;
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
    final actions = [
      StudioIconButton(
        icon: const Icon(LucideIcons.search),
        tooltip: 'Search',
        onPressed: () => frame.go(RoomtonePlace.library),
      ),
    ];
    if (!wide) {
      return RoomtonePage(
        title: 'Home',
        actions: actions,
        children: [lead, roomtoneGroupGap, latest, roomtoneGroupGap, drafts],
      );
    }
    Widget pair(Widget start, Widget end) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 5, child: start),
        const SizedBox(width: StudioSpacing.extraLarge),
        Expanded(flex: 6, child: end),
      ],
    );
    // A narrow desk: the card beside the latest, the drafts under the card.
    if (width < _rack) {
      return RoomtonePage(
        title: 'Home',
        maxWidth: 1080,
        actions: actions,
        children: [
          pair(
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [lead, roomtoneGroupGap, drafts],
            ),
            latest,
          ),
        ],
      );
    }
    // A desk fills its screen as a rack does: the episode they are in the
    // middle of on the whole player, beside the latest; then their drafts,
    // beside the shows they follow.
    return RoomtonePage(
      title: 'Home',
      maxWidth: 1080,
      actions: actions,
      children: [
        pair(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const StudioSectionHeader('Continue listening'),
              RoomtonePlayer(episode: roomtoneNowPlaying),
            ],
          ),
          latest,
        ),
        roomtoneGroupGap,
        pair(drafts, const _Shows()),
      ],
    );
  }
}

// The narrowest window whose Home stands as a rack: the whole player beside
// the latest, and the four shows they follow beside the drafts, each show's
// name on one line.
const double _rack = 1280;

/// The shows they follow, labelled as a desk labels its channels: each
/// show's tile over its name and how many of its episodes are in.
class _Shows extends StatelessWidget {
  const _Shows();

  @override
  Widget build(BuildContext context) {
    final theme = context.studioTheme;
    final t = theme.textTheme;
    final c = theme.colors;
    final words = RoomtoneWords.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const StudioSectionHeader('Shows you follow'),
        StudioPanel(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (i, show) in roomtoneShows.indexed) ...[
                if (i > 0) const SizedBox(width: StudioSpacing.regular),
                Expanded(
                  child: MergeSemantics(
                    child: Column(
                      children: [
                        RoomtoneCover(show: show, size: 56),
                        const SizedBox(height: StudioSpacing.small),
                        Text(
                          show.name,
                          textAlign: TextAlign.center,
                          style: t.label.copyWith(color: c.legend),
                        ),
                        Text(
                          words.episodes(
                            roomtoneEpisodes
                                .where((e) => e.show.id == show.id)
                                .length,
                          ),
                          textAlign: TextAlign.center,
                          style: t.caption.copyWith(color: c.legendMuted),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
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

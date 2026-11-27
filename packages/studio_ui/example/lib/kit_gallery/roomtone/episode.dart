/// An episode: its cover tile, its player (readouts, scrubber, transport,
/// speed) and its notes. [RoomtonePlayer] stands on the episode's page and,
/// on a desk, beside the Library.
library;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/scheduler.dart' show Ticker;
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:studio_ui/studio_ui.dart';

import 'data.dart';
import 'roomtone.dart';
import 'words.dart';

/// A show's tile: its initials in a readout's words on its glass (pale and
/// lit from behind by day, dark by night), as a channel's label on a desk
/// (amber stays for what is on). No pictures: the show's mark is its name.
class RoomtoneCover extends StatelessWidget {
  /// The tile of [show], [size] square.
  const RoomtoneCover({super.key, required this.show, this.size = 44});

  /// The show.
  final RoomtoneShow show;

  /// Its side.
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = context.studioTheme;
    final initials = show.name
        .split(' ')
        .where((w) => w.isNotEmpty && w != 'The')
        .take(2)
        .map((w) => w[0])
        .join();
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: StudioSurface(
          // By night a smoked tile, so it parts from the dark glass.
          face: theme.colors.readoutFace.copyWith(
            radius: size >= 80 ? StudioRadii.display : StudioRadii.small,
            fill: theme.colors.brightness == Brightness.dark
                ? Color.lerp(theme.colors.readout, theme.colors.onDisplay, 0.12)
                : null,
            fillLow: theme.colors.brightness == Brightness.dark
                ? Color.lerp(
                    theme.colors.readoutLow,
                    theme.colors.onDisplay,
                    0.07,
                  )
                : null,
          ),
          child: Center(
            // The tile's mark, sized to its side: it does not grow with the
            // reader's text.
            child: Text(
              initials,
              textScaler: TextScaler.noScaling,
              style: theme.textTheme.readout.copyWith(
                fontSize: size * 0.36,
                height: 1,
                color: theme.colors.onReadout,
                // A glow on the dark glass; on the lit glass, sharp.
                shadows: theme.colors.readoutGlow(
                  theme.colors.onReadout,
                  alpha: 0.35,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The player for [episode]: on a pane of glass, its tile, show and title;
/// two readouts (played and left); the scrubber; the transport keys; the
/// speed bank.
class RoomtonePlayer extends StatefulWidget {
  /// A player for [episode].
  const RoomtonePlayer({
    super.key,
    required this.episode,
    this.compact = false,
    this.showDetails = false,
  });

  /// What it plays.
  final RoomtoneEpisode episode;

  /// Whether it stands small (the Overview's live screen): no speed bank.
  final bool compact;

  /// Shows the episode notes and seekable chapter list under the transport.
  final bool showDetails;

  @override
  State<RoomtonePlayer> createState() => _RoomtonePlayerState();
}

class _RoomtonePlayerState extends State<RoomtonePlayer>
    with SingleTickerProviderStateMixin {
  late double _at = widget.episode.minutes * 60 * widget.episode.progress;
  late final Ticker _ticker = createTicker(_tick);
  Duration _lastTick = Duration.zero;
  int _tab = 0;
  bool get _playing => _ticker.isActive;
  double get _end => widget.episode.minutes * 60.0;

  void _tick(Duration elapsed) {
    final delta = elapsed - _lastTick;
    if (delta.inMilliseconds < 200) return;
    _lastTick = elapsed;
    _seek(_at + delta.inMicroseconds / Duration.microsecondsPerSecond * _speed);
  }

  void _seek(double position) {
    setState(() {
      _at = position.clamp(0.0, _end).toDouble();
      if (_at == _end) _ticker.stop();
    });
  }

  void _toggle() {
    setState(() {
      if (_playing) {
        _ticker.stop();
      } else {
        if (_at >= _end) _at = 0;
        _lastTick = Duration.zero;
        _ticker.start();
      }
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  double _speed = 1;

  @override
  void didUpdateWidget(RoomtonePlayer old) {
    super.didUpdateWidget(old);
    if (old.episode.id != widget.episode.id) {
      _at = widget.episode.minutes * 60 * widget.episode.progress;
      _ticker.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.studioTheme;
    final t = theme.textTheme;
    final c = theme.colors;
    final e = widget.episode;
    final total = e.minutes * 60.0;
    final played = roomtoneClock(_at.round());
    final left = roomtoneClock((total - _at).round());
    final stacked = MediaQuery.textScalerOf(context).scale(1) > 1.4;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudioDisplay(
          padding: const EdgeInsets.all(StudioSpacing.regular),
          // At large text the tile stands over the words, which keep the
          // pane's width (a word never breaks).
          child: Flex(
            direction: stacked ? Axis.vertical : Axis.horizontal,
            crossAxisAlignment: stacked
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              RoomtoneCover(show: e.show, size: widget.compact ? 56 : 80),
              const SizedBox.square(dimension: StudioSpacing.regular),
              Flexible(
                flex: stacked ? 0 : 1,
                fit: FlexFit.tight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.show.name,
                      style: t.secondary.copyWith(color: c.onDisplayMuted),
                    ),
                    const SizedBox(height: 2),
                    Semantics(
                      header: true,
                      child: Text(
                        e.title,
                        style: (widget.compact ? t.title : t.headline).copyWith(
                          color: c.onDisplay,
                        ),
                      ),
                    ),
                    const SizedBox(height: StudioSpacing.tight),
                    Text(
                      '${e.published} · '
                      '${RoomtoneWords.of(context).minutes(e.minutes)}',
                      style: t.caption.copyWith(color: c.onDisplayMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: StudioSpacing.regular),
        Row(
          children: [
            StudioReadout(
              played,
              minWidth: 92,
              semanticsLabel: 'Played $played',
            ),
            const Spacer(),
            StudioReadout('−$left', minWidth: 92, semanticsLabel: '$left left'),
          ],
        ),
        const SizedBox(height: StudioSpacing.small),
        StudioFader(
          value: _at,
          max: total,
          onChanged: _seek,
          semanticLabel: 'Position',
          semanticFormatter: (v) => roomtoneClock(v.round()),
          ticks: 12,
        ),
        const SizedBox(height: StudioSpacing.regular),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            StudioTransportKey(
              icon: const Icon(LucideIcons.rotateCcw),
              tooltip: 'Back 15 seconds',
              size: 52,
              onPressed: () => _seek(_at - 15),
            ),
            const SizedBox(width: StudioSpacing.large),
            StudioTransportKey(
              icon: Icon(_playing ? LucideIcons.pause : LucideIcons.play),
              tooltip: _playing ? 'Pause' : 'Play',
              lit: _playing,
              size: 72,
              onPressed: _toggle,
            ),
            const SizedBox(width: StudioSpacing.large),
            StudioTransportKey(
              icon: const Icon(LucideIcons.rotateCw),
              tooltip: 'Forward 30 seconds',
              size: 52,
              onPressed: () => _seek(_at + 30),
            ),
          ],
        ),
        if (!widget.compact) ...[
          const SizedBox(height: StudioSpacing.large),
          const StudioSectionHeader('Speed'),
          StudioSegmentedButton<double>(
            semanticLabel: 'Speed',
            segments: const [
              StudioSegment(value: 1, label: '1×'),
              StudioSegment(value: 1.25, label: '1.25×'),
              StudioSegment(value: 1.5, label: '1.5×'),
              StudioSegment(value: 2, label: '2×'),
            ],
            value: _speed,
            onChanged: (v) => setState(() => _speed = v),
          ),
        ],
        if (widget.showDetails) ...[
          roomtoneGroupGap,
          StudioTabBar(
            tabs: const ['Notes', 'Chapters'],
            selectedIndex: _tab,
            onChanged: (i) => setState(() => _tab = i),
          ),
          const SizedBox(height: StudioSpacing.regular),
          if (_tab == 0)
            StudioDisplay(
              padding: const EdgeInsets.all(StudioSpacing.regular),
              child: Text(e.notes, style: theme.textTheme.body),
            )
          else
            StudioListGroup(
              children: [
                for (final (at, name) in e.chapters)
                  StudioListTile(
                    title: name,
                    trailingText: roomtoneClock(at),
                    selected:
                        at ==
                        e.chapters.lastWhere((chapter) => chapter.$1 <= _at).$1,
                    onTap: () => _seek(at.toDouble()),
                    showChevron: false,
                  ),
              ],
            ),
        ],
      ],
    );
  }
}

/// Copies a link that opens [episode] on a phone or in the desktop Library.
Future<void> copyRoomtoneEpisodeLink(
  BuildContext context,
  RoomtoneEpisode episode,
) async {
  final base = Uri.base;
  final gallery = base.isScheme('http') || base.isScheme('https')
      ? base.resolve('.')
      : Uri.parse(
          'https://wenkaifan0720.github.io/flutter_design_systems/studio/',
        );
  final fragment = Uri(
    path: '/scene/episode',
    queryParameters: {'id': episode.id},
  );
  final link = gallery.replace(fragment: fragment.toString()).toString();
  try {
    await Clipboard.setData(ClipboardData(text: link));
  } catch (_) {
    if (!context.mounted) return;
    await showStudioDialog<void>(
      context: context,
      builder: (context) => StudioDialog(
        title: 'Share episode',
        content: SelectableText(link),
        actions: [
          StudioButton('Done', onPressed: () => Navigator.pop(context)),
        ],
      ),
    );
    return;
  }
  if (context.mounted) showStudioToast(context, 'Link copied');
}

/// An episode's page: its player, then its notes and chapters.
class RoomtoneEpisodePage extends StatefulWidget {
  /// The page of [episode].
  const RoomtoneEpisodePage({super.key, required this.episode});

  /// The episode.
  final RoomtoneEpisode episode;

  @override
  State<RoomtoneEpisodePage> createState() => _RoomtoneEpisodePageState();
}

class _RoomtoneEpisodePageState extends State<RoomtoneEpisodePage> {
  @override
  Widget build(BuildContext context) => RoomtonePage(
    title: widget.episode.show.name,
    actions: [
      StudioIconButton(
        icon: const Icon(LucideIcons.share2),
        tooltip: 'Share',
        onPressed: () => copyRoomtoneEpisodeLink(context, widget.episode),
      ),
    ],
    children: [RoomtoneEpisodeDetail(episode: widget.episode)],
  );
}

/// What an episode's page and the desk's player pane hold: the player, then
/// the notes and chapters under tabs.
class RoomtoneEpisodeDetail extends StatelessWidget {
  /// The detail of [episode].
  const RoomtoneEpisodeDetail({super.key, required this.episode});

  /// The episode whose notes and chapters accompany the player.
  final RoomtoneEpisode episode;

  @override
  Widget build(BuildContext context) =>
      RoomtonePlayer(episode: episode, showDetails: true);
}

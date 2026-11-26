/// The Overview: the look's pitch. What it is in a sentence, a live player
/// set in it, the app's screens, what the package holds, then the index of
/// every part's page.
library;

import 'package:material_ui/material_ui.dart';
import 'package:studio_ui/studio_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'data.dart';
import 'episode.dart';
import 'roomtone.dart';

/// The Overview.
class RoomtoneOverview extends StatelessWidget {
  /// The Overview, its index over [parts].
  const RoomtoneOverview({super.key, this.parts = const []});

  /// The package's parts, each with its page.
  final List<RoomtonePart> parts;

  @override
  Widget build(BuildContext context) {
    final theme = context.studioTheme;
    final t = theme.textTheme;
    final c = theme.colors;
    final frame = RoomtoneFrame.of(context);
    final wide = MediaQuery.sizeOf(context).width >= 1024;
    // The look's description is English in both layout directions.
    final english = Directionality.of(context) == TextDirection.rtl
        ? TextAlign.right
        : TextAlign.left;
    // The pitch's name stands over its card as the player's does over the
    // player, so on a desk the two cards' tops meet one line.
    final card = StudioSurface(
      face: c.panelFace.copyWith(brushed: false),
      child: Padding(
        padding: const EdgeInsets.all(StudioSpacing.regular),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                'An app as a well-made piece of studio gear.',
                textDirection: TextDirection.ltr,
                textAlign: english,
                style: t.display.copyWith(color: c.legend),
              ),
            ),
            const SizedBox(height: StudioSpacing.regular),
            Text(
              'Brushed anodised panels with machined edges, glass displays set '
              'into them, keys that latch and light, faders and knobs with a real '
              'throw. One light falls from the top; by day the gear stands in a '
              'bright room, by night in low light. The amber lamp is the one '
              'accent, and it means something is on.',
              textDirection: TextDirection.ltr,
              textAlign: english,
              style: t.body.copyWith(color: c.legendMuted),
            ),
            const SizedBox(height: StudioSpacing.large),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: StudioButton.lit(
                'Open Roomtone',
                icon: const Icon(LucideIcons.audioLines),
                onPressed: () => frame.go(RoomtonePlace.home),
              ),
            ),
          ],
        ),
      ),
    );
    final pitch = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [const StudioSectionHeader('A Flutter design system'), card],
    );
    final live = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const StudioSectionHeader('Live: the player'),
        RoomtonePlayer(episode: roomtoneNowPlaying, compact: true),
      ],
    );
    final screens = StudioListGroup(
      header: 'The screens',
      children: [
        for (final (place, icon, note) in const [
          (
            RoomtonePlace.home,
            LucideIcons.house,
            'Continue listening, then the latest',
          ),
          (
            RoomtonePlace.library,
            LucideIcons.libraryBig,
            'Every episode; the player beside it on a desk',
          ),
          (
            RoomtonePlace.record,
            LucideIcons.mic,
            'Meters, gain, the record key, markers',
          ),
          (
            RoomtonePlace.settings,
            LucideIcons.slidersHorizontal,
            'Plain controls, no colour needed',
          ),
        ])
          StudioListTile(
            leading: Icon(icon),
            title: switch (place) {
              RoomtonePlace.home => 'Home',
              RoomtonePlace.library => 'Library',
              RoomtonePlace.record => 'Record',
              _ => 'Settings',
            },
            subtitle: note,
            onTap: () => frame.go(place),
          ),
      ],
    );
    const holds = StudioListGroup(
      header: 'In the package',
      children: [
        StudioListTile(
          leading: Icon(LucideIcons.sunMoon),
          title: 'Day and night',
          subtitle: 'The same gear in a bright room and in low light',
        ),
        StudioListTile(
          leading: Icon(LucideIcons.monitorSmartphone),
          title: 'Phone, tablet and desktop',
          subtitle: 'A key bank, a rail, then a rack of modules',
        ),
        StudioListTile(
          leading: Icon(LucideIcons.accessibility),
          title: 'For everyone',
          subtitle: 'Screen reader, keyboard, 200% text, right to left',
        ),
        StudioListTile(
          leading: Icon(LucideIcons.palette),
          title: 'Your light, your finish',
          subtitle: 'Recolour the lamp and the anodising; the rest holds',
        ),
      ],
    );
    final index = StudioListGroup(
      header: 'Every part',
      children: [
        for (final p in parts)
          StudioListTile(
            title: p.title,
            onTap: () => frame.push(p.build(c.brightness)),
          ),
      ],
    );
    return RoomtonePage(
      title: 'Studio',
      maxWidth: wide ? 1080 : StudioMetrics.readingWidth,
      children: wide
          ? [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 6, child: pitch),
                  const SizedBox(width: StudioSpacing.huge),
                  Expanded(flex: 5, child: live),
                ],
              ),
              roomtoneGroupGap,
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: screens),
                  const SizedBox(width: StudioSpacing.extraLarge),
                  const Expanded(child: holds),
                ],
              ),
              if (parts.isNotEmpty) ...[roomtoneGroupGap, index],
            ]
          : [
              pitch,
              roomtoneGroupGap,
              live,
              roomtoneGroupGap,
              screens,
              roomtoneGroupGap,
              holds,
              if (parts.isNotEmpty) ...[roomtoneGroupGap, index],
            ],
    );
  }
}

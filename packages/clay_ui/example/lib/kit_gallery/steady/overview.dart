/// Clay's Overview, the pitch: what the look is, its three moves shown
/// working, a handful of its parts together, and the index of every part's
/// page.
library;

import 'package:material_ui/material_ui.dart';
import 'package:clay_ui/clay_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'steady.dart';

/// The Overview.
class SteadyOverview extends StatelessWidget {
  /// The pitch, listing [parts].
  const SteadyOverview({super.key, this.parts = const []});

  /// The gallery's pages.
  final List<SteadyPart> parts;

  @override
  Widget build(BuildContext context) {
    final theme = context.clayTheme;
    final c = theme.colors;
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 900;
    final pitch = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Clay',
          style: theme.textTheme.display.copyWith(
            fontSize: wide ? 48 : 40,
            height: 1.1,
            color: c.ink,
          ),
        ),
        const SizedBox(height: ClaySpacing.small),
        Text(
          'Soft, inflated, matte clay for Flutter. Coloured volumes float a '
          'little above a pale ground, lit from the top and shaded below, '
          'and press in when touched.',
          style: theme.textTheme.body.copyWith(
            fontSize: 18,
            height: 26 / 18,
            color: c.inkSecondary,
          ),
        ),
        const SizedBox(height: ClaySpacing.large),
        Wrap(
          spacing: ClaySpacing.medium,
          runSpacing: ClaySpacing.medium,
          children: [
            ClayButton.filled(
              'See Today',
              icon: const Icon(LucideIcons.sun),
              onPressed: () => SteadyFrame.of(context).go(SteadyPlace.today),
            ),
            ClayButton(
              'Habits',
              onPressed: () => SteadyFrame.of(context).go(SteadyPlace.habits),
            ),
          ],
        ),
      ],
    );
    return SteadyPage(
      title: 'Overview',
      maxWidth: 1080,
      children: [
        if (wide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Each column its own Tab group: down one, then the next.
              Expanded(child: FocusTraversalGroup(child: pitch)),
              const SizedBox(width: ClaySpacing.extraLarge),
              Expanded(child: FocusTraversalGroup(child: const _Still())),
            ],
          )
        else ...[
          pitch,
          const SizedBox(height: ClaySpacing.extraLarge),
          const _Still(),
        ],
        const SizedBox(height: ClaySpacing.huge),
        Text(
          'Three moves',
          style: theme.textTheme.headline.copyWith(color: c.ink),
        ),
        const SizedBox(height: ClaySpacing.regular),
        _Moves(wide: width >= 760),
        if (parts.isNotEmpty) ...[
          const SizedBox(height: ClaySpacing.huge),
          ClayGroup(
            header: 'Every part',
            children: [
              for (final p in parts)
                ClayListTile(
                  title: p.title,
                  onTap: () =>
                      SteadyFrame.of(context).push(p.build(theme.brightness)),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// A still life of parts: what Today is made of, at rest.
class _Still extends StatefulWidget {
  const _Still();

  @override
  State<_Still> createState() => _StillState();
}

class _StillState extends State<_Still> {
  bool _water = true;
  bool _walk = false;
  bool _remind = true;
  String _range = 'week';

  @override
  Widget build(BuildContext context) {
    final theme = context.clayTheme;
    final c = theme.colors;
    // One keyline: the ring's row stands as far in as the rows' contents.
    return ClayCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: ClayListTile.inset),
            child: Row(
              children: [
                ClayProgressRing(
                  value: 0.6,
                  size: 84,
                  thickness: 11,
                  semanticLabel: 'Done today',
                  child: Text(
                    '3/5',
                    style: theme.textTheme.title.copyWith(color: c.ink),
                  ),
                ),
                const SizedBox(width: ClaySpacing.regular),
                Expanded(
                  child: ClaySegmentedButton<String>(
                    segments: const [
                      ClaySegment(value: 'week', label: 'Week'),
                      ClaySegment(value: 'month', label: 'Month'),
                    ],
                    selected: _range,
                    expanded: true,
                    onChanged: (v) => setState(() => _range = v),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: ClaySpacing.regular),
          MergeSemantics(
            child: ClayListTile(
              leading: const ClayIconTile(
                tint: ClayTint.sky,
                child: Icon(LucideIcons.droplets),
              ),
              title: 'Drink water',
              subtitle: '5 of 8 glasses',
              showChevron: false,
              checked: _water,
              onTap: () => setState(() => _water = !_water),
              trailing: ExcludeFocus(
                child: ClayCheckbox(
                  value: _water,
                  onChanged: (v) => setState(() => _water = v ?? false),
                ),
              ),
            ),
          ),
          MergeSemantics(
            child: ClayListTile(
              leading: const ClayIconTile(
                tint: ClayTint.mint,
                child: Icon(LucideIcons.footprints),
              ),
              title: 'Morning walk',
              subtitle: '20 minutes',
              showChevron: false,
              checked: _walk,
              onTap: () => setState(() => _walk = !_walk),
              trailing: ExcludeFocus(
                child: ClayCheckbox(
                  value: _walk,
                  onChanged: (v) => setState(() => _walk = v ?? false),
                ),
              ),
            ),
          ),
          MergeSemantics(
            child: ClayListTile(
              title: 'Remind me',
              showChevron: false,
              toggled: _remind,
              onTap: () => setState(() => _remind = !_remind),
              trailing: ExcludeFocus(
                child: ClaySwitch(
                  value: _remind,
                  onChanged: (v) => setState(() => _remind = v),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Moves extends StatelessWidget {
  const _Moves({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    final c = context.clayTheme.colors;
    final moves = [
      _Move(
        title: 'Inflated volume',
        body:
            'A soft light inside the top-leading edge, a soft shade inside '
            'the bottom-trailing one, continuous corners, no stroke.',
        specimen: SizedBox(
          width: 96,
          height: 64,
          child: ClaySurface(
            face: ClayFace.raised(c, radius: ClayRadius.large),
          ),
        ),
      ),
      _Move(
        title: 'Coloured float',
        body:
            'One soft shadow straight down, in the part’s own hue: lilac '
            'under white clay, coral under the accent. Never grey.',
        specimen: SizedBox(
          width: 96,
          height: 64,
          child: ClaySurface(
            face: ClayFace.raised(c, color: c.accent, radius: ClayRadius.large),
          ),
        ),
      ),
      _Move(
        title: 'Pressed in',
        body:
            'A press squashes a part into the ground; fields and grooves are '
            'pressed in from the start; what is chosen rises out of them.',
        specimen: SizedBox(
          width: 96,
          height: 64,
          child: ClaySurface(face: ClayFace.well(c, radius: ClayRadius.large)),
        ),
      ),
    ];
    if (!wide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, m) in moves.indexed) ...[
            if (i > 0) const SizedBox(height: ClaySpacing.regular),
            m,
          ],
        ],
      );
    }
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, m) in moves.indexed) ...[
            if (i > 0) const SizedBox(width: ClaySpacing.regular),
            Expanded(child: m),
          ],
        ],
      ),
    );
  }
}

class _Move extends StatelessWidget {
  const _Move({
    required this.title,
    required this.body,
    required this.specimen,
  });

  final String title;
  final String body;
  final Widget specimen;

  @override
  Widget build(BuildContext context) {
    final theme = context.clayTheme;
    return ClayCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(child: specimen),
          const SizedBox(height: ClaySpacing.roomy),
          Text(
            title,
            style: theme.textTheme.title.copyWith(color: theme.colors.ink),
          ),
          const SizedBox(height: ClaySpacing.tight),
          Text(body, style: theme.textTheme.secondary),
        ],
      ),
    );
  }
}

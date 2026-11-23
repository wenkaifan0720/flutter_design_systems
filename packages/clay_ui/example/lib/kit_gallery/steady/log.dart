/// Steady's check-in: how the day feels, how much energy is left, the water
/// drunk so far against the day's goal and the week's, and a note.
library;

import 'package:material_ui/material_ui.dart';
import 'package:clay_ui/clay_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'steady.dart';

/// How a day feels, from low to great.
enum SteadyMood {
  /// A hard day.
  low,

  /// Flat.
  meh,

  /// Fine.
  okay,

  /// A good day.
  good,

  /// A great one.
  great;

  /// Its word.
  String get label => switch (this) {
    low => 'Low',
    meh => 'Meh',
    okay => 'Okay',
    good => 'Good',
    great => 'Great',
  };

  /// Its face.
  IconData get icon => switch (this) {
    low => LucideIcons.frown,
    meh => LucideIcons.meh,
    okay => LucideIcons.smile,
    good => LucideIcons.smilePlus,
    great => LucideIcons.laugh,
  };

  /// The pastel it is moulded in.
  ClayTint get tint => switch (this) {
    low => ClayTint.sky,
    meh => ClayTint.lilac,
    okay => ClayTint.butter,
    good => ClayTint.mint,
    great => ClayTint.peach,
  };
}

/// The check-in page.
class SteadyLog extends StatefulWidget {
  /// A check-in for today.
  const SteadyLog({super.key});

  @override
  State<SteadyLog> createState() => _SteadyLogState();
}

class _SteadyLogState extends State<SteadyLog> {
  SteadyMood _mood = SteadyMood.good;
  double _energy = 0.6;
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _save() {
    showClayToast(context, 'Check-in saved');
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final frame = SteadyFrame.of(context);
    final theme = context.clayTheme;
    final c = theme.colors;
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= ClayMetrics.sidebarBreakpoint;
    final water = frame.habits.where((h) => h.id == 'water').firstOrNull;

    final mood = ClayCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ClayIconTile(tint: _mood.tint, size: 56, child: Icon(_mood.icon)),
              const SizedBox(width: ClaySpacing.regular),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How does today feel?',
                      style: theme.textTheme.title.copyWith(color: c.ink),
                    ),
                    Text(_mood.label, style: theme.textTheme.secondary),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: ClaySpacing.regular),
          ClaySegmentedButton<SteadyMood>(
            segments: [
              for (final m in SteadyMood.values)
                ClaySegment(value: m, label: m.label),
            ],
            selected: _mood,
            onChanged: (m) => setState(() => _mood = m),
            expanded: true,
            semanticLabel: 'Mood',
          ),
          const SizedBox(height: ClaySpacing.large),
          const ClayFieldLabel('Energy'),
          ClaySlider(
            value: _energy,
            onChanged: (v) => setState(() => _energy = v),
            semanticLabel: 'Energy',
          ),
          Row(
            children: [
              Expanded(child: Text('Drained', style: theme.textTheme.caption)),
              Text('Bright', style: theme.textTheme.caption),
            ],
          ),
        ],
      ),
    );

    final glasses = ClayCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Water', style: theme.textTheme.title.copyWith(color: c.ink)),
          Text(
            water == null
                ? 'Glasses drunk today'
                : 'Goal: ${water.goal} ${water.unit} a day',
            style: theme.textTheme.secondary,
          ),
          const SizedBox(height: ClaySpacing.regular),
          if (water != null) ...[
            LayoutBuilder(
              builder: (context, box) {
                final words = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Glasses today',
                      style: theme.textTheme.label.copyWith(color: c.ink),
                    ),
                    Text(
                      'One for each glass',
                      style: theme.textTheme.secondary,
                    ),
                  ],
                );
                final stepper = ClayNumberField(
                  value: water.progress.toDouble(),
                  min: 0,
                  max: 20,
                  onChanged: (v) =>
                      setState(() => frame.log(water, (v ?? 0).round())),
                  semanticLabel: 'Glasses today',
                );
                // Side by side where the words keep a line of their own;
                // the words over the stepper where they would not.
                if (box.maxWidth < 440) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      words,
                      const SizedBox(height: ClaySpacing.medium),
                      stepper,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: words),
                    const SizedBox(width: ClaySpacing.regular),
                    stepper,
                  ],
                );
              },
            ),
            const SizedBox(height: ClaySpacing.regular),
            ClayMeter(
              value: water.progress.toDouble(),
              max: water.goal.toDouble(),
              label: 'Today',
              valueText: '${water.progress} of ${water.goal}',
            ),
          ],
          const SizedBox(height: ClaySpacing.large),
          ClayBarChart(
            semanticLabel: 'Glasses this week',
            height: 180,
            categories: const ['Mon', 'Tue', 'Wed', 'Thu'],
            series: [
              ClayChartSeries(
                label: 'Glasses',
                points: [
                  const ClayChartPoint(0, 7),
                  const ClayChartPoint(1, 8),
                  const ClayChartPoint(2, 5),
                  ClayChartPoint(3, (water?.progress ?? 0).toDouble()),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    final note = ClayCard(
      child: ClayTextArea(
        controller: _note,
        labelText: 'Note',
        hintText: 'What helped today, or what got in the way',
      ),
    );

    return SteadyPage(
      title: 'Check in',
      maxWidth: wide ? 1080 : ClayMetrics.readingWidth,
      bottom: SteadyKeys(
        primary: ClayButton.filled(
          'Save check-in',
          icon: const Icon(LucideIcons.check),
          onPressed: _save,
        ),
      ),
      children: [
        if (wide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Each column its own Tab group: down one, then the next.
              Expanded(
                child: FocusTraversalGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [mood, steadyGroupGap, note],
                  ),
                ),
              ),
              const SizedBox(width: ClaySpacing.large),
              Expanded(child: FocusTraversalGroup(child: glasses)),
            ],
          )
        else ...[
          mood,
          steadyGroupGap,
          glasses,
          steadyGroupGap,
          note,
        ],
      ],
    );
  }
}

/// Today's way to the check-in: a row with the water so far.
class SteadyCheckInRow extends StatelessWidget {
  /// The row.
  const SteadyCheckInRow({super.key});

  @override
  Widget build(BuildContext context) {
    final frame = SteadyFrame.of(context);
    final water = frame.habits.where((h) => h.id == 'water').firstOrNull;
    return ClayGroup(
      children: [
        ClayListTile(
          leading: const ClayIconTile(
            tint: ClayTint.sky,
            child: Icon(LucideIcons.smilePlus),
          ),
          title: 'Check in',
          subtitle: water == null
              ? 'Mood and water'
              : 'Mood and water, ${water.progress} of ${water.goal} glasses',
          onTap: () => frame.push(const SteadyLog()),
        ),
      ],
    );
  }
}

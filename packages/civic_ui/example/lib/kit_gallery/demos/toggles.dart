// Toggles, chips and keys: a toggle group to show some of a list, a
// segmented control for one view of it, chips to filter and to remove a
// filter, and the keys a shortcut takes, named in a sentence.
import 'package:material_ui/material_ui.dart';
import 'package:civic_ui/civic_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

Widget kitTogglesDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Toggles, chips & keys',
  intro:
      'A chosen toggle is solid, with a tick, so the choice reads without '
      'colour. Chips are flat, so they never read as the page’s action.',
  sections: const [_Toggles(), _Chips(), _Keys()],
);

class _Toggles extends StatefulWidget {
  const _Toggles();

  @override
  State<_Toggles> createState() => _TogglesState();
}

class _TogglesState extends State<_Toggles> {
  Set<String> _shown = {'drafts', 'sent'};
  String _period = 'month';

  @override
  Widget build(BuildContext context) => KitSection(
    title: 'Toggle group & segmented control',
    caption:
        'Any of a few, or one view of a list. Either stacks full width when '
        'the row does not fit.',
    spacing: CivicSpacing.s32,
    children: [
      CivicToggleGroup<String>(
        labelText: 'Show applications',
        helperText: 'Choose any.',
        segments: const [
          CivicSegment(value: 'closed', label: 'Closed'),
          CivicSegment(value: 'drafts', label: 'Drafts'),
          CivicSegment(value: 'sent', label: 'Sent'),
        ],
        selected: _shown,
        onSelectionChanged: (next) => setState(() => _shown = next),
      ),
      CivicSegmentedControl<String>(
        labelText: 'Period',
        segments: const [
          CivicSegment(value: 'week', label: 'Week'),
          CivicSegment(value: 'month', label: 'Month'),
          CivicSegment(value: 'year', label: 'Year'),
        ],
        value: _period,
        onChanged: (next) => setState(() => _period = next),
      ),
      const CivicSegmentedControl<String>(
        labelText: 'Period (not available yet)',
        segments: [
          CivicSegment(value: 'week', label: 'Week'),
          CivicSegment(value: 'month', label: 'Month'),
        ],
        value: 'week',
        onChanged: null,
      ),
    ],
  );
}

class _Chips extends StatefulWidget {
  const _Chips();

  @override
  State<_Chips> createState() => _ChipsState();
}

class _ChipsState extends State<_Chips> {
  bool _openNow = true;
  bool _review = false;
  final List<String> _zones = ['Zone B', 'Zone C'];

  @override
  Widget build(BuildContext context) => KitSection(
    title: 'Chips',
    caption:
        'A chip filters a list; a removable chip is one target, and the '
        'whole face removes it.',
    children: [
      Wrap(
        spacing: CivicSpacing.s8,
        runSpacing: CivicSpacing.s8,
        children: [
          CivicChip(
            label: 'Open now',
            icon: LucideIcons.clock,
            selected: _openNow,
            onSelected: (on) => setState(() => _openNow = on),
          ),
          CivicChip(
            label: 'Under review',
            selected: _review,
            onSelected: (on) => setState(() => _review = on),
          ),
          const CivicChip(label: 'Closed', selected: false, onSelected: null),
          for (final zone in _zones)
            CivicChip.removable(
              label: zone,
              onDeleted: () => setState(() => _zones.remove(zone)),
            ),
        ],
      ),
    ],
  );
}

class _Keys extends StatelessWidget {
  const _Keys();

  @override
  Widget build(BuildContext context) {
    final style = context.civicText.body.copyWith(
      color: context.civicTheme.textPrimary,
    );
    return KitSection(
      title: 'Keys',
      caption: 'A key cap, not a button. A shortcut reads left to right.',
      children: [
        Text.rich(
          TextSpan(
            style: style,
            children: const [
              TextSpan(text: 'Press '),
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: CivicKbd.combination(['Ctrl', 'K']),
              ),
              TextSpan(text: ' to search the service.'),
            ],
          ),
        ),
        const SizedBox(height: CivicSpacing.s16),
        Text.rich(
          TextSpan(
            style: style,
            children: const [
              TextSpan(text: 'Press '),
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: CivicKbd('Enter'),
              ),
              TextSpan(text: ' to continue.'),
            ],
          ),
        ),
      ],
    );
  }
}

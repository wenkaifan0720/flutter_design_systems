/// Clay's choices: cups, grooves, switches, segments, chips, sliders,
/// ratings and the file well.
library;

import 'package:material_ui/material_ui.dart';
import 'package:clay_ui/clay_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

/// The choices page.
Widget kitChoicesDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Choices',
  sections: const [
    KitSection(
      title: 'Checkboxes and radios',
      note: 'Pressed into the ground; chosen, they puff up in the accent.',
      children: [_Checks()],
    ),
    KitSection(
      title: 'Switches',
      note: 'A clay ball rolling in a groove that fills with coral.',
      children: [_Switches()],
    ),
    KitSection(
      title: 'Segments',
      note: 'The choice rises out of its groove.',
      children: [_Segments()],
    ),
    KitSection(title: 'Chips', children: [_Chips()]),
    KitSection(
      title: 'Sliders',
      note:
          'A white clay ball rolled along a groove, the run behind it raised '
          'in coral; two balls for a range.',
      maxWidth: 480,
      children: [_Sliders()],
    ),
    KitSection(
      title: 'Ratings',
      note: 'Stars pressed into the clay, those given raised in coral.',
      children: [_Ratings()],
    ),
    KitSection(
      title: 'Files',
      note: 'A well to drop files in, each one a slab with its progress.',
      maxWidth: 480,
      children: [_Files()],
    ),
  ],
);

class _Checks extends StatefulWidget {
  const _Checks();

  @override
  State<_Checks> createState() => _ChecksState();
}

class _ChecksState extends State<_Checks> {
  bool _a = true;
  bool _b = false;
  bool? _c;
  String _when = 'morning';

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      KitRow(
        children: [
          ClayCheckbox(
            value: _a,
            onChanged: (v) => setState(() => _a = v ?? false),
            semanticLabel: 'Water',
          ),
          ClayCheckbox(
            value: _b,
            onChanged: (v) => setState(() => _b = v ?? false),
            semanticLabel: 'Walk',
          ),
          ClayCheckbox(
            value: _c,
            tristate: true,
            onChanged: (v) => setState(() => _c = v),
            semanticLabel: 'All',
          ),
          const ClayCheckbox(
            value: true,
            onChanged: null,
            semanticLabel: 'Off',
          ),
          ClayCheckbox(
            value: false,
            isError: true,
            onChanged: (_) {},
            semanticLabel: 'Required',
          ),
          // Radios on their own, grouped where their choice is held: one
          // Tab stop, and arrows that choose.
          DesignRadioGroup<String>(
            options: const ['morning', 'evening'],
            value: _when,
            onChanged: (v) => setState(() => _when = v),
            semanticLabel: 'Time of day',
            layoutBuilder: (context, radios) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final (i, radio) in radios.indexed) ...[
                  if (i > 0) const SizedBox(width: ClaySpacing.regular),
                  radio,
                ],
              ],
            ),
            itemBuilder: (context, value, node, select) => ClayRadio<String>(
              value: value,
              groupValue: _when,
              focusNode: node,
              onChanged: select == null ? null : (_) => select(),
              semanticLabel: value == 'morning' ? 'Morning' : 'Evening',
            ),
          ),
        ],
      ),
      const SizedBox(height: ClaySpacing.regular),
      ClayRadioGroup<String>(
        options: const ['morning', 'afternoon', 'evening'],
        value: _when,
        labelOf: (v) => '${v[0].toUpperCase()}${v.substring(1)}',
        onChanged: (v) => setState(() => _when = v),
        semanticLabel: 'Time of day',
      ),
      const SizedBox(height: ClaySpacing.regular),
      const KitRow(
        children: [
          ClayCheckMark(value: true, states: {}),
          ClayRadioMark(chosen: true, states: {}),
        ],
      ),
    ],
  );
}

class _Switches extends StatefulWidget {
  const _Switches();

  @override
  State<_Switches> createState() => _SwitchesState();
}

class _SwitchesState extends State<_Switches> {
  bool _on = true;
  bool _off = false;

  @override
  Widget build(BuildContext context) => KitRow(
    children: [
      ClaySwitch(
        value: _on,
        onChanged: (v) => setState(() => _on = v),
        semanticLabel: 'Reminders',
      ),
      ClaySwitch(
        value: _off,
        onChanged: (v) => setState(() => _off = v),
        semanticLabel: 'Sounds',
      ),
      const ClaySwitch(value: true, onChanged: null, semanticLabel: 'Synced'),
      const ClaySwitch(value: false, onChanged: null, semanticLabel: 'Beta'),
    ],
  );
}

class _Segments extends StatefulWidget {
  const _Segments();

  @override
  State<_Segments> createState() => _SegmentsState();
}

class _SegmentsState extends State<_Segments> {
  String _range = 'week';

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ClaySegmentedButton<String>(
        segments: const [
          ClaySegment(value: 'week', label: 'Week'),
          ClaySegment(value: 'month', label: 'Month'),
          ClaySegment(value: 'year', label: 'Year'),
        ],
        selected: _range,
        onChanged: (v) => setState(() => _range = v),
        semanticLabel: 'Range',
      ),
      const SizedBox(height: ClaySpacing.regular),
      const ClaySegmentedButton<String>(
        segments: [
          ClaySegment(
            value: 'am',
            label: 'Morning',
            icon: Icon(LucideIcons.sunrise),
          ),
          ClaySegment(
            value: 'pm',
            label: 'Evening',
            icon: Icon(LucideIcons.moon),
          ),
        ],
        selected: 'am',
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
  final Set<String> _on = {'Morning'};
  final List<String> _tags = ['Health', 'Focus'];

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      KitRow(
        children: [
          for (final f in const ['Morning', 'Afternoon', 'Evening', 'Paused'])
            ClayChip(
              label: f,
              selected: _on.contains(f),
              onSelected: (v) => setState(() => v ? _on.add(f) : _on.remove(f)),
            ),
        ],
      ),
      const SizedBox(height: ClaySpacing.regular),
      KitRow(
        children: [
          ClayChip(
            label: 'Add tag',
            icon: const Icon(LucideIcons.plus),
            onPressed: () {},
          ),
          for (final t in _tags)
            ClayChip(
              label: t,
              onPressed: () {},
              onDeleted: () => setState(() => _tags.remove(t)),
            ),
          const ClayChip(label: 'Archived'),
        ],
      ),
    ],
  );
}

class _Sliders extends StatelessWidget {
  const _Sliders();

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ClayFieldLabel('Energy'),
        KitLive<double>(
          0.6,
          (context, v, set) =>
              ClaySlider(value: v, onChanged: set, semanticLabel: 'Energy'),
        ),
        const SizedBox(height: ClaySpacing.regular),
        const ClayFieldLabel('Quiet hours'),
        KitLive<ClayRangeValues>(
          const ClayRangeValues(21, 23),
          (context, v, set) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClayRangeSlider(
                values: v,
                min: 18,
                max: 24,
                divisions: 6,
                onChanged: set,
                startLabel: 'From',
                endLabel: 'Until',
                semanticFormatterCallback: (h) => '${h.round()}:00',
              ),
              Text(
                'From ${v.start.round()}:00 until ${v.end.round()}:00',
                style: theme.textTheme.secondary,
              ),
            ],
          ),
        ),
        const SizedBox(height: ClaySpacing.regular),
        const ClaySlider(value: 0.3, onChanged: null, semanticLabel: 'Locked'),
      ],
    );
  }
}

class _Ratings extends StatelessWidget {
  const _Ratings();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      KitLive<double>(
        4,
        (context, v, set) => ClayRating(
          value: v,
          onChanged: set,
          semanticLabel: 'How the week felt',
        ),
      ),
      const SizedBox(height: ClaySpacing.regular),
      KitLive<double>(
        3.5,
        (context, v, set) => ClayRating(
          value: v,
          allowHalf: true,
          onChanged: set,
          semanticLabel: 'How the walk felt',
        ),
      ),
      const SizedBox(height: ClaySpacing.regular),
      const ClayRating(value: 3, onChanged: null, semanticLabel: 'Last week'),
    ],
  );
}

class _Files extends StatelessWidget {
  const _Files();

  @override
  Widget build(BuildContext context) => KitLive<List<ClayFile>>(
    const [
      ClayFile(name: 'morning-walk.jpg', bytes: 2400000),
      ClayFile(name: 'route.gpx', bytes: 86000, progress: 0.4),
    ],
    (context, files, set) => ClayFileDrop(
      label: 'Photos',
      hint: 'Pictures for this habit, up to 5 MB each',
      files: files,
      onChoose: () => set([
        ...files,
        ClayFile(name: 'photo-${files.length + 1}.jpg', bytes: 1200000),
      ]),
      onRemove: (file) => set([
        for (final f in files)
          if (f != file) f,
      ]),
    ),
  );
}

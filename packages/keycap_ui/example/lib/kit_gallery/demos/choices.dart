import 'package:material_ui/material_ui.dart';
import 'package:keycap_ui/keycap_ui.dart';

import '../kit.dart';

/// Choices: latching keys.
Widget kitChoicesDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Selection',
  sections: [
    const _Toggles(),
    const _Rows(),
    ...kitSpecimens(const ['Slider', 'RangeSlider', 'Rating', 'WheelPicker']),
  ],
);

class _Toggles extends StatefulWidget {
  const _Toggles();

  @override
  State<_Toggles> createState() => _TogglesState();
}

class _TogglesState extends State<_Toggles> {
  bool _images = true;
  bool? _all;
  bool _sync = true;
  bool _sounds = false;
  String _paper = 'A4';

  @override
  Widget build(BuildContext context) {
    final t = context.keycapTheme.textTheme;
    Widget line(String words, Widget control) => Row(
      children: [
        control,
        const SizedBox(width: KeycapSpacing.medium),
        Expanded(child: Text(words, style: t.body)),
      ],
    );
    return KitSection(
      title: 'Checkboxes, radios, switches',
      note: 'Each a small key that latches down when on.',
      children: [
        line(
          'Include images',
          KeycapCheckbox(
            value: _images,
            semanticLabel: 'Include images',
            onChanged: (v) => setState(() => _images = v!),
          ),
        ),
        line(
          'Every note in the folder',
          KeycapCheckbox(
            value: _all,
            tristate: true,
            semanticLabel: 'Every note in the folder',
            onChanged: (v) => setState(() => _all = v),
          ),
        ),
        line(
          'Disabled, on',
          const KeycapCheckbox(
            value: true,
            onChanged: null,
            semanticLabel: 'Disabled, on',
          ),
        ),
        KeycapRadioGroup<String>(
          semanticLabel: 'Paper',
          options: const ['A4', 'Letter', 'A5'],
          value: _paper,
          labelOf: (p) => p,
          onChanged: (v) => setState(() => _paper = v),
        ),
        Row(
          children: [
            Expanded(child: Text('Sync on mobile data', style: t.body)),
            KeycapSwitch(
              value: _sync,
              semanticLabel: 'Sync on mobile data',
              onChanged: (v) => setState(() => _sync = v),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(child: Text('Key sounds', style: t.body)),
            KeycapSwitch(
              value: _sounds,
              semanticLabel: 'Key sounds',
              onChanged: (v) => setState(() => _sounds = v),
            ),
          ],
        ),
      ],
    );
  }
}

class _Rows extends StatefulWidget {
  const _Rows();

  @override
  State<_Rows> createState() => _RowsState();
}

class _RowsState extends State<_Rows> {
  String _sort = 'edited';
  Set<String> _show = {'notes'};
  String _tab = 'notes';

  @override
  Widget build(BuildContext context) => KitSection(
    title: 'Rows of keys',
    note: 'The chosen key latched, its legend down with it.',
    children: [
      KeycapSegmentedButton<String>(
        semanticLabel: 'Sort by',
        segments: const [
          KeycapSegment(value: 'edited', label: 'Edited'),
          KeycapSegment(value: 'created', label: 'Created'),
          KeycapSegment(value: 'title', label: 'Title'),
        ],
        selected: {_sort},
        onSelectionChanged: (s) => setState(() => _sort = s.first),
      ),
      KeycapSegmentedButton<String>(
        semanticLabel: 'Show',
        multiSelectionEnabled: true,
        emptySelectionAllowed: true,
        segments: const [
          KeycapSegment(value: 'notes', label: 'Notes'),
          KeycapSegment(value: 'tasks', label: 'Tasks'),
          KeycapSegment(value: 'links', label: 'Links'),
        ],
        selected: _show,
        onSelectionChanged: (s) => setState(() => _show = s),
      ),
      KeycapTabBar<String>(
        semanticLabel: 'Sections',
        tabs: const [
          KeycapSegment(value: 'notes', label: 'Notes'),
          KeycapSegment(value: 'tags', label: 'Tags'),
          KeycapSegment(value: 'trash', label: 'Deleted'),
        ],
        value: _tab,
        onChanged: (v) => setState(() => _tab = v),
      ),
    ],
  );
}

import 'package:flutter/material.dart';
import 'package:brutal_ui/brutal_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

/// Choices: checkboxes, radios, switches, segments and a stepper, live.
Widget kitChoicesDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Selection',
  sections: const [_Choices(), _More()],
);

class _Choices extends StatefulWidget {
  const _Choices();

  @override
  State<_Choices> createState() => _ChoicesState();
}

class _ChoicesState extends State<_Choices> {
  bool _terms = true;
  bool _news = false;
  String _pay = 'card';
  bool _remind = true;
  bool _sound = false;
  String _range = 'week';
  int _standing = 2;
  int _seated = 0;

  @override
  Widget build(BuildContext context) {
    final t = context.brutalTheme.textTheme;
    Widget line(Widget control, String words) => Row(
      children: [
        control,
        const SizedBox(width: BrutalSpacing.medium),
        Expanded(child: Text(words, style: t.body)),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KitSection(
          title: 'Checkboxes',
          note: 'Square. Checked, the box fills with ink.',
          gap: BrutalSpacing.small,
          children: [
            line(
              BrutalCheckbox(
                value: _terms,
                onChanged: (v) => setState(() => _terms = v!),
                semanticLabel: 'I agree to the terms',
              ),
              'I agree to the terms',
            ),
            line(
              BrutalCheckbox(
                value: _news,
                onChanged: (v) => setState(() => _news = v!),
                semanticLabel: 'Send me the weekly listings',
              ),
              'Send me the weekly listings',
            ),
            line(
              const BrutalCheckbox(
                value: false,
                onChanged: null,
                isError: true,
                semanticLabel: 'Required',
              ),
              'Required, left empty (off)',
            ),
          ],
        ),
        const SizedBox(height: BrutalSpacing.extraLarge),
        KitSection(
          title: 'Radios',
          note: 'The one round control: round means one of a set.',
          gap: BrutalSpacing.small,
          children: [
            for (final (v, label) in const [
              ('card', 'Card'),
              ('wallet', 'Phone wallet'),
              ('invoice', 'Invoice (companies)'),
            ])
              line(
                BrutalRadio<String>(
                  value: v,
                  groupValue: _pay,
                  onChanged: v == 'invoice'
                      ? null
                      : (x) => setState(() => _pay = x!),
                  semanticLabel: label,
                ),
                label,
              ),
          ],
        ),
        const SizedBox(height: BrutalSpacing.extraLarge),
        KitSection(
          title: 'Switches',
          note: 'A square track, a square thumb. On, the track fills with ink.',
          gap: BrutalSpacing.small,
          children: [
            line(
              BrutalSwitch(
                value: _remind,
                onChanged: (v) => setState(() => _remind = v),
                semanticLabel: 'Reminders',
              ),
              'Reminders',
            ),
            line(
              BrutalSwitch(
                value: _sound,
                onChanged: (v) => setState(() => _sound = v),
                semanticLabel: 'Sounds',
              ),
              'Sounds',
            ),
            line(
              const BrutalSwitch(
                value: true,
                onChanged: null,
                semanticLabel: 'Location',
              ),
              'Location (off)',
            ),
          ],
        ),
        const SizedBox(height: BrutalSpacing.extraLarge),
        KitSection(
          title: 'Segments',
          note: 'Cells on shared rules; the chosen one filled with ink.',
          children: [
            BrutalSegmentedButton<String>(
              segments: const [
                BrutalSegment(value: 'today', label: 'Today'),
                BrutalSegment(value: 'week', label: 'This week'),
                BrutalSegment(value: 'month', label: 'Month'),
              ],
              value: _range,
              onChanged: (v) => setState(() => _range = v),
              semanticLabel: 'When',
            ),
          ],
        ),
        const SizedBox(height: BrutalSpacing.extraLarge),
        KitSection(
          title: 'Steppers',
          note: 'Minus, the number, plus: three cells, two shared rules.',
          children: [
            Row(
              children: [
                Expanded(child: Text('Standing', style: t.label)),
                BrutalStepper(
                  value: _standing,
                  max: 8,
                  onChanged: (v) => setState(() => _standing = v),
                  semanticLabel: 'Standing tickets',
                ),
              ],
            ),
            Row(
              children: [
                Expanded(child: Text('Seated', style: t.label)),
                BrutalStepper(
                  value: _seated,
                  max: 8,
                  onChanged: (v) => setState(() => _seated = v),
                  semanticLabel: 'Seated tickets',
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _More extends StatefulWidget {
  const _More();

  @override
  State<_More> createState() => _MoreState();
}

class _MoreState extends State<_More> {
  double _volume = 0.6;
  BrutalRangeValues _price = const BrutalRangeValues(10, 35);
  final Set<String> _kinds = {'Music'};
  int _stars = 3;
  final List<BrutalFile> _files = [
    const BrutalFile(name: 'student-card.jpg', bytes: 845000),
    const BrutalFile(name: 'letter.pdf', bytes: 2400000, progress: 0.4),
  ];

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SizedBox(height: BrutalSpacing.extraLarge),
      KitSection(
        title: 'Sliders',
        note:
            'A ruled track inked to the thumb; the square thumb presses into '
            'its shadow while it is dragged.',
        children: [
          BrutalSlider(
            value: _volume,
            semanticLabel: 'Volume',
            onChanged: (v) => setState(() => _volume = v),
          ),
          BrutalSlider(
            value: 3,
            min: 0,
            max: 6,
            divisions: 6,
            semanticLabel: 'Tickets',
            onChanged: (_) {},
          ),
          const BrutalSlider(value: 0.3, onChanged: null, semanticLabel: 'Off'),
        ],
      ),
      const SizedBox(height: BrutalSpacing.extraLarge),
      KitSection(
        title: 'Range',
        note: 'Ink between two thumbs; each is a slider of its own.',
        children: [
          Text(
            '€${_price.start.round()} to €${_price.end.round()}',
            style: context.brutalTheme.textTheme.label,
          ),
          BrutalRangeSlider(
            values: _price,
            min: 0,
            max: 60,
            divisions: 12,
            startLabel: 'Lowest price',
            endLabel: 'Highest price',
            onChanged: (v) => setState(() => _price = v),
          ),
          const BrutalRangeSlider(
            values: BrutalRangeValues(0.2, 0.7),
            onChanged: null,
          ),
        ],
      ),
      const SizedBox(height: BrutalSpacing.extraLarge),
      KitSection(
        title: 'Chips',
        note: 'Flat ruled cells; chosen, they go ink.',
        children: [
          Wrap(
            spacing: BrutalSpacing.small,
            runSpacing: BrutalSpacing.small,
            children: [
              for (final k in const ['Music', 'Film', 'Talks', 'Art'])
                BrutalChip(
                  label: k,
                  selected: _kinds.contains(k),
                  onSelected: (on) =>
                      setState(() => on ? _kinds.add(k) : _kinds.remove(k)),
                ),
              const BrutalChip(
                label: 'Free',
                icon: LucideIcons.tag,
                selected: false,
                onSelected: null,
              ),
            ],
          ),
        ],
      ),
      const SizedBox(height: BrutalSpacing.extraLarge),
      KitSection(
        title: 'Rating',
        note: 'Cells on shared rules; the score inks from the start.',
        children: [
          BrutalRating(
            value: _stars,
            semanticLabel: 'Your rating',
            onChanged: (v) => setState(() => _stars = v),
          ),
          const BrutalRating(value: 4, onChanged: null, semanticLabel: 'Rated'),
        ],
      ),
      const SizedBox(height: BrutalSpacing.extraLarge),
      KitSection(
        title: 'Files',
        note: 'A box in a dashed rule to choose from; a row for each file.',
        children: [
          BrutalFileDrop(
            label: 'Proof of student status',
            hint: 'A photo or a PDF, up to 10 MB',
            files: _files,
            onChoose: () {},
            onRemove: (f) => setState(() => _files.remove(f)),
          ),
        ],
      ),
    ],
  );
}

// Catalog specimens (metadata.yaml): one still per part, drawn the same in
// every preset; the stage chooses the preset.

Widget kitSpecimenCheckbox() => kitState(
  true,
  (context, on, change) => Row(
    children: [
      BrutalCheckbox(
        value: on,
        onChanged: (v) => change(v ?? false),
        semanticLabel: 'Send me the line-up',
      ),
      const SizedBox(width: BrutalSpacing.medium),
      const Expanded(child: Text('Send me the line-up')),
    ],
  ),
);

Widget kitSpecimenRadio() => kitState(
  'standing',
  (context, chosen, change) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final (value, label) in const [
        ('standing', 'Standing'),
        ('seated', 'Seated'),
        ('box', 'A box for four'),
      ])
        Padding(
          padding: const EdgeInsets.only(bottom: BrutalSpacing.small),
          child: Row(
            children: [
              BrutalRadio<String>(
                value: value,
                groupValue: chosen,
                onChanged: (v) => change(v ?? chosen),
                semanticLabel: label,
              ),
              const SizedBox(width: BrutalSpacing.medium),
              Expanded(child: Text(label)),
            ],
          ),
        ),
    ],
  ),
);

Widget kitSpecimenSwitch() => kitState(
  true,
  (context, on, change) => Row(
    children: [
      const Expanded(child: Text('Remind me a day before')),
      BrutalSwitch(
        value: on,
        onChanged: change,
        semanticLabel: 'Remind me a day before',
      ),
    ],
  ),
);

Widget kitSpecimenSegmentedButton() => kitState(
  'week',
  (context, span, change) => BrutalSegmentedButton<String>(
    semanticLabel: 'Span',
    value: span,
    onChanged: change,
    segments: const [
      BrutalSegment(value: 'day', label: 'Day'),
      BrutalSegment(value: 'week', label: 'Week'),
      BrutalSegment(value: 'month', label: 'Month'),
    ],
  ),
);

Widget kitSpecimenStepper() => kitState(
  2,
  (context, count, change) => Row(
    children: [
      const Expanded(child: Text('Tickets')),
      BrutalStepper(
        value: count,
        onChanged: change,
        min: 1,
        max: 8,
        semanticLabel: 'Tickets',
      ),
    ],
  ),
);

Widget kitSpecimenSlider() => kitState(
  0.4,
  (context, level, change) =>
      BrutalSlider(value: level, onChanged: change, semanticLabel: 'Volume'),
);

Widget kitSpecimenRangeSlider() => kitState(
  const BrutalRangeValues(0.2, 0.7),
  (context, span, change) => BrutalRangeSlider(
    values: span,
    onChanged: change,
    startLabel: 'Lowest price',
    endLabel: 'Highest price',
  ),
);

Widget kitSpecimenChip() => kitState<Set<String>>(
  const {'Tonight'},
  (context, chosen, change) => KitRow(
    children: [
      for (final label in const ['Tonight', 'Free', 'Under 18s'])
        BrutalChip(
          label: label,
          selected: chosen.contains(label),
          onSelected: (on) =>
              change(on ? {...chosen, label} : ({...chosen}..remove(label))),
        ),
    ],
  ),
);

Widget kitSpecimenRating() => kitState(
  4,
  (context, stars, change) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: BrutalRating(
      value: stars,
      onChanged: change,
      semanticLabel: 'Your rating',
    ),
  ),
);

Widget kitSpecimenFileDrop() => Builder(
  builder: (context) => BrutalFileDrop(
    label: 'Poster',
    onChoose: () => kitFeedback(context, 'Your files open here.'),
    files: const [BrutalFile(name: 'poster.png', bytes: 482000)],
  ),
);

/// Gloss's value controls: sockets, slots, troughs, steppers, grooves and
/// latching chips.
library;

import 'package:material_ui/material_ui.dart';
import 'package:gloss_ui/gloss_ui.dart';

import '../kit.dart';

/// The choices page.
Widget kitChoicesDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Choices',
  sections: const [
    KitSection(title: 'Every control', children: [_All()]),
    KitSection(title: 'Ranges, stars and files', children: [_More()]),
  ],
);

class _All extends StatefulWidget {
  const _All();

  @override
  State<_All> createState() => _AllState();
}

class _AllState extends State<_All> {
  bool _a = true;
  bool _b = false;
  bool? _c;
  String _radio = 'Week';
  bool _on = true;
  bool _off = false;
  String _segment = 'week';
  int _servings = 4;
  double _spice = 0.4;
  final Set<String> _diets = {'Vegetarian'};

  @override
  Widget build(BuildContext context) {
    final t = GlossTheme.of(context).textTheme;
    // A control that is off has its words clouded with it.
    Widget labelled(String label, Widget control, {bool off = false}) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        control,
        const SizedBox(width: GlossSpacing.small),
        Text(
          label,
          style: off
              ? t.body.copyWith(color: context.glossTheme.colors.inkDisabled)
              : t.body,
        ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KitRow(
          children: [
            labelled(
              'Checked',
              GlossCheckbox(
                value: _a,
                onChanged: (v) => setState(() => _a = v!),
              ),
            ),
            labelled(
              'Not checked',
              GlossCheckbox(
                value: _b,
                onChanged: (v) => setState(() => _b = v!),
              ),
            ),
            labelled(
              'Mixed',
              GlossCheckbox(
                value: _c,
                tristate: true,
                onChanged: (v) => setState(() => _c = v),
              ),
            ),
            labelled(
              'Locked',
              const GlossCheckbox(value: true, onChanged: null),
              off: true,
            ),
            labelled(
              'Wrong',
              GlossCheckbox(value: false, isError: true, onChanged: (_) {}),
            ),
          ],
        ),
        const SizedBox(height: GlossSpacing.large),
        GlossRadioGroup<String>(
          options: const ['Day', 'Week', 'Month', 'Year'],
          value: _radio,
          labelOf: (v) => v,
          isEnabled: (v) => v != 'Year',
          direction: Axis.horizontal,
          semanticLabel: 'Period',
          onChanged: (v) => setState(() => _radio = v),
        ),
        const SizedBox(height: GlossSpacing.large),
        KitRow(
          children: [
            GlossSwitch(value: _on, onChanged: (v) => setState(() => _on = v)),
            GlossSwitch(
              value: _off,
              onChanged: (v) => setState(() => _off = v),
            ),
            const GlossSwitch(value: true, onChanged: null),
            const GlossSwitch(value: false, onChanged: null),
          ],
        ),
        const SizedBox(height: GlossSpacing.large),
        GlossSegmentedButton<String>(
          segments: const [
            GlossSegment(value: 'day', label: 'Day'),
            GlossSegment(value: 'week', label: 'Week'),
            GlossSegment(value: 'month', label: 'Month'),
          ],
          selected: _segment,
          onChanged: (v) => setState(() => _segment = v),
        ),
        const SizedBox(height: GlossSpacing.large),
        KitRow(
          children: [
            GlossStepper(
              value: _servings,
              min: 1,
              max: 12,
              semanticLabel: 'Servings',
              format: (v) => glossPlural(
                context,
                v,
                one: '1 serving',
                other: '$v servings',
              ),
              onChanged: (v) => setState(() => _servings = v),
            ),
            const GlossStepper(value: 2, onChanged: null),
          ],
        ),
        const SizedBox(height: GlossSpacing.large),
        SizedBox(
          width: 320,
          child: GlossSlider(
            value: _spice,
            semanticLabel: 'Heat',
            onChanged: (v) => setState(() => _spice = v),
          ),
        ),
        const SizedBox(height: GlossSpacing.large),
        KitRow(
          children: [
            for (final d in ['Vegetarian', 'Vegan', 'Gluten-free', 'Quick'])
              GlossChip(
                label: d,
                selected: _diets.contains(d),
                onSelected: (on) =>
                    setState(() => on ? _diets.add(d) : _diets.remove(d)),
              ),
            const GlossChip(
              label: 'Sold out',
              selected: false,
              onSelected: null,
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
  GlossRangeValues _minutes = const GlossRangeValues(15, 45);
  int _stars = 4;
  List<GlossFile> _files = const [
    GlossFile(name: 'risotto.jpg', bytes: 240000),
    GlossFile(name: 'method.pdf', bytes: 1820000, progress: 0.6),
  ];

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 360),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlossFieldLabel(
          'Takes ${_minutes.start.round()} to ${_minutes.end.round()} min',
        ),
        GlossRangeSlider(
          values: _minutes,
          max: 90,
          divisions: 18,
          startLabel: 'Shortest',
          endLabel: 'Longest',
          onChanged: (v) => setState(() => _minutes = v),
        ),
        const SizedBox(height: GlossSpacing.regular),
        GlossRating(
          value: _stars,
          semanticLabel: 'Your rating',
          onChanged: (s) => setState(() => _stars = s),
        ),
        const SizedBox(height: GlossSpacing.regular),
        GlossFileDrop(
          label: 'Photos and notes',
          hint: 'A photo of the dish, or the method',
          onChoose: () {},
          files: _files,
          onRemove: (f) => setState(() => _files = [..._files]..remove(f)),
        ),
      ],
    ),
  );
}

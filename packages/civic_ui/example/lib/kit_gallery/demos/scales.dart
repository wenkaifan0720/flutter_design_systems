// Sliders, ratings and colour: a value on a scale with its reading in
// words, a range between two amounts, a score out of five said in words,
// and a colour chosen by name first.
import 'package:material_ui/material_ui.dart';
import 'package:civic_ui/civic_ui.dart';

import '../kit.dart';

Widget kitScalesDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Sliders, ratings & colour',
  intro:
      'A value is always written out in words, so no one has to judge it '
      'by eye. A slider suits a rough answer; type an exact one.',
  sections: const [_Sliders(), _Ratings(), _Colours()],
);

class _Sliders extends StatefulWidget {
  const _Sliders();

  @override
  State<_Sliders> createState() => _SlidersState();
}

class _SlidersState extends State<_Sliders> {
  double _size = 150;
  RawRangeValues _cost = const RawRangeValues(20, 60);

  @override
  Widget build(BuildContext context) => KitSection(
    title: 'Slider & range slider',
    caption: 'The reading above the track, the ends under it.',
    spacing: CivicSpacing.s32,
    children: [
      CivicSlider(
        labelText: 'Text size',
        value: _size,
        min: 100,
        max: 200,
        divisions: 4,
        valueLabel: (v) => '${v.round()}%',
        onChanged: (v) => setState(() => _size = v),
      ),
      CivicRangeSlider(
        labelText: 'Monthly cost',
        helperText: 'Permits between these amounts are shown.',
        values: _cost,
        max: 100,
        divisions: 20,
        valueLabel: (v) => '£${v.round()}',
        onChanged: (v) => setState(() => _cost = v),
      ),
      const CivicSlider(
        labelText: 'Text size (set by your device)',
        value: 100,
        min: 100,
        max: 200,
        divisions: 4,
        onChanged: null,
      ),
    ],
  );
}

class _Ratings extends StatefulWidget {
  const _Ratings();

  @override
  State<_Ratings> createState() => _RatingsState();
}

class _RatingsState extends State<_Ratings> {
  double _ease = 0;

  @override
  Widget build(BuildContext context) => KitSection(
    title: 'Rating',
    caption:
        'Numbered marks, not stars: a mark that says its number reads the '
        'same to everyone.',
    spacing: CivicSpacing.s32,
    children: [
      CivicRating(
        labelText: 'How easy was it to apply?',
        value: _ease,
        labels: const ['Very hard', 'Hard', 'Neither', 'Easy', 'Very easy'],
        onChanged: (v) => setState(() => _ease = v),
      ),
      const CivicRating(
        labelText: 'Average from 1,284 people',
        value: 3.6,
        allowHalf: true,
        readOnly: true,
        onChanged: null,
      ),
    ],
  );
}

class _Colours extends StatefulWidget {
  const _Colours();

  @override
  State<_Colours> createState() => _ColoursState();
}

class _ColoursState extends State<_Colours> {
  final _badge = RawColorController(const Color(0xFF0F4C81));

  @override
  void dispose() {
    _badge.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => KitSection(
    title: 'Colour picker',
    caption:
        'Named swatches first, because a colour alone says nothing to many '
        'people; then the area, the hue and the hex code.',
    children: [
      CivicColorPicker(
        labelText: 'Badge colour',
        helperText: 'Shown on your permit in the window.',
        controller: _badge,
        swatches: const [
          CivicColorSwatch(Color(0xFF0F4C81), 'Harbour blue'),
          CivicColorSwatch(Color(0xFF0B6136), 'Park green'),
          CivicColorSwatch(Color(0xFF8A1C1C), 'Brick red'),
          CivicColorSwatch(Color(0xFF4B4F54), 'Slate'),
        ],
      ),
    ],
  );
}

import 'package:material_ui/material_ui.dart';
import 'package:appliance_ui/appliance_ui.dart';

import '../kit.dart';

/// Switches and selectors: latching keys, preset keys, slide switches, the
/// slide selector and the stepper.
Widget kitChoicesDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Selection',
  sections: const [_Choices(), _Faders()],
);

class _Choices extends StatefulWidget {
  const _Choices();

  @override
  State<_Choices> createState() => _ChoicesState();
}

class _ChoicesState extends State<_Choices> {
  bool _gift = true;
  bool _note = false;
  String _delivery = 'standard';
  bool _updates = true;
  bool _letter = false;
  String _view = 'grid';
  String _tab = 'open';
  int _count = 2;

  @override
  Widget build(BuildContext context) {
    final t = context.applianceTheme.textTheme;
    Widget line(Widget control, String words) => Row(
      children: [
        control,
        const SizedBox(width: ApplianceSpacing.medium),
        Expanded(child: Text(words, style: t.body)),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KitSection(
          title: 'Latching keys',
          note: 'Checked, the key stays down with a tick.',
          gap: ApplianceSpacing.medium,
          children: [
            line(
              ApplianceCheckbox(
                value: _gift,
                semanticLabel: 'Wrap as a gift',
                onChanged: (v) => setState(() => _gift = v!),
              ),
              'Wrap as a gift',
            ),
            line(
              ApplianceCheckbox(
                value: _note,
                semanticLabel: 'Add a note',
                onChanged: (v) => setState(() => _note = v!),
              ),
              'Add a note',
            ),
            line(
              const ApplianceCheckbox(
                value: true,
                semanticLabel: 'Locked',
                onChanged: null,
              ),
              'Locked on',
            ),
          ],
        ),
        const SizedBox(height: ApplianceSpacing.extraLarge),
        KitSection(
          title: 'Preset keys',
          note: 'The chosen key stays down with its lamp lit. A bank is one Tab stop; the arrows choose.',
          gap: ApplianceSpacing.medium,
          children: [
            ApplianceRadioGroup<String>(
              options: const ['standard', 'next', 'collect'],
              value: _delivery,
              labelOf: (v) => switch (v) {
                'standard' => 'Standard delivery',
                'next' => 'Next day',
                _ => 'Collect from the shop',
              },
              semanticLabel: 'Delivery',
              onChanged: (x) => setState(() => _delivery = x),
            ),
          ],
        ),
        const SizedBox(height: ApplianceSpacing.extraLarge),
        KitSection(
          title: 'Slide switches',
          note: 'On: the cap at the end, its lamp lit, the on bar showing.',
          gap: ApplianceSpacing.medium,
          children: [
            line(
              ApplianceSwitch(
                value: _updates,
                semanticLabel: 'Order updates',
                onChanged: (v) => setState(() => _updates = v),
              ),
              'Order updates',
            ),
            line(
              ApplianceSwitch(
                value: _letter,
                semanticLabel: 'New season letter',
                onChanged: (v) => setState(() => _letter = v),
              ),
              'New season letter',
            ),
            line(
              const ApplianceSwitch(
                value: true,
                semanticLabel: 'Locked',
                onChanged: null,
              ),
              'Locked on',
            ),
          ],
        ),
        const SizedBox(height: ApplianceSpacing.extraLarge),
        KitSection(
          title: 'Slide selector and stepper',
          gap: ApplianceSpacing.large,
          children: [
            ApplianceSegmentedButton<String>(
              semanticLabel: 'View',
              segments: const [
                ApplianceSegment(value: 'grid', label: 'Grid'),
                ApplianceSegment(value: 'list', label: 'List'),
              ],
              value: _view,
              onChanged: (v) => setState(() => _view = v),
            ),
            ApplianceTabBar<String>(
              semanticLabel: 'Orders',
              tabs: const [
                ApplianceSegment(value: 'open', label: 'Open'),
                ApplianceSegment(value: 'past', label: 'Past'),
                ApplianceSegment(value: 'returns', label: 'Returns'),
              ],
              value: _tab,
              onChanged: (v) => setState(() => _tab = v),
            ),
            ApplianceStepper(
              value: _count,
              min: 1,
              max: 9,
              semanticLabel: 'How many',
              onChanged: (v) => setState(() => _count = v),
            ),
          ],
        ),
      ],
    );
  }
}

/// Faders, a knob and stars.
class _Faders extends StatefulWidget {
  const _Faders();

  @override
  State<_Faders> createState() => _FadersState();
}

class _FadersState extends State<_Faders> {
  double _volume = 0.4;
  double _steps = 3;
  RawRangeValues _price = const RawRangeValues(20, 60);
  String _browning = 'medium';
  double _stars = 4;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      KitSection(
        title: 'Faders',
        note: 'A cap in a slot, the travelled part lit; ticks for steps.',
        children: [
          ApplianceSlider(
            value: _volume,
            onChanged: (v) => setState(() => _volume = v),
            semanticLabel: 'Volume',
            semanticFormatterCallback: (v) => '${(v * 100).round()}%',
          ),
          ApplianceSlider(
            value: _steps,
            min: 1,
            max: 5,
            divisions: 4,
            onChanged: (v) => setState(() => _steps = v),
            semanticLabel: 'Strength',
          ),
          ApplianceRangeSlider(
            values: _price,
            max: 100,
            onChanged: (v) => setState(() => _price = v),
            startLabel: 'Lowest price',
            endLabel: 'Highest price',
            semanticFormatterCallback: (v) => '\$${v.round()}',
          ),
          const ApplianceSlider(
            value: 0.6,
            onChanged: null,
            semanticLabel: 'Locked',
          ),
        ],
      ),
      const SizedBox(height: ApplianceSpacing.extraLarge),
      KitSection(
        title: 'Knob and stars',
        note: 'A knurled knob turns to its detents; stars take a rating.',
        children: [
          KitRow(
            children: [
              ApplianceKnob<String>(
                semanticLabel: 'Browning',
                value: _browning,
                onChanged: (v) => setState(() => _browning = v),
                options: const [
                  ApplianceKnobOption(value: 'light', label: 'Light'),
                  ApplianceKnobOption(value: 'medium', label: 'Medium'),
                  ApplianceKnobOption(value: 'dark', label: 'Dark'),
                  ApplianceKnobOption(value: 'crisp', label: 'Crisp'),
                ],
              ),
            ],
          ),
          KitRow(
            children: [
              ApplianceRating(
                value: _stars,
                onChanged: (v) => setState(() => _stars = v.toDouble()),
              ),
              const ApplianceRating(value: 3.5, semanticLabel: 'Rated'),
            ],
          ),
        ],
      ),
    ],
  );
}

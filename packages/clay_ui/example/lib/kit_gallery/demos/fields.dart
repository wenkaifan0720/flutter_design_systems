/// Clay's fields: wells pressed into the ground, selects, steppers, codes,
/// suggestions and tags.
library;

import 'package:material_ui/material_ui.dart';
import 'package:clay_ui/clay_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

/// A label and help put round a part that has none of its own: a slider.
class _LabelledPart extends StatelessWidget {
  const _LabelledPart();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const ClayFieldLabel('Glasses a day'),
      KitLive<double>(
        8,
        (context, n, set) => ClaySlider(
          value: n,
          min: 1,
          max: 12,
          divisions: 11,
          onChanged: set,
          semanticLabel: 'Glasses a day',
        ),
      ),
      const ClayFieldMessage(
        helperText: 'A label and help round a part with none of its own',
      ),
    ],
  );
}

/// The fields page.
Widget kitFieldsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Fields',
  sections: [
    KitSection(
      title: 'Text fields',
      maxWidth: 420,
      children: [
        ClayTextField(
          labelText: 'Habit name',
          hintText: 'Drink water',
          helperText: 'Shown on Today',
          onChanged: (_) {},
        ),
        ClayTextField(
          labelText: 'Search',
          hintText: 'Habits, notes',
          prefixIcon: const Icon(LucideIcons.search),
          onChanged: (_) {},
        ),
        ClayTextField(
          labelText: 'Daily goal',
          hintText: '8',
          suffix: const Text('glasses'),
          errorText: 'Enter a number from 1 to 20',
          onChanged: (_) {},
        ),
        ClayTextField(
          labelText: 'Note',
          hintText: 'Why this habit matters',
          maxLines: 4,
          minLines: 3,
          maxLength: 140,
          onChanged: (_) {},
        ),
        const ClayTextField(
          labelText: 'Account',
          hintText: 'mara@example.com',
          enabled: false,
        ),
        const _LabelledPart(),
      ],
    ),
    const KitSection(title: 'Selects', maxWidth: 420, children: [_Selects()]),
    const KitSection(
      title: 'Notes, search and secrets',
      note:
          'A deeper well for a note; search in a rounded well with its '
          'glass; a password behind an eye that shows it.',
      maxWidth: 420,
      children: [_Entry()],
    ),
    const KitSection(
      title: 'Numbers and codes',
      note:
          'Words beside a well; a count between two clay balls; a code in '
          'one well per figure.',
      maxWidth: 420,
      children: [_Numbers()],
    ),
    const KitSection(
      title: 'Picking from many',
      note:
          'A well that suggests as you type; tags pressed in as pills, each '
          'with its own way out.',
      maxWidth: 420,
      children: [_Many()],
    ),
    const KitSection(
      title: 'A label and help round any control',
      maxWidth: 420,
      children: [_FormField()],
    ),
  ],
);

class _Selects extends StatefulWidget {
  const _Selects();

  @override
  State<_Selects> createState() => _SelectsState();
}

class _SelectsState extends State<_Selects> {
  String _repeat = 'daily';
  String? _time;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ClaySelect<String>(
        labelText: 'Repeat',
        value: _repeat,
        items: const [
          ClaySelectItem(value: 'daily', label: 'Every day'),
          ClaySelectItem(value: 'weekdays', label: 'Weekdays'),
          ClaySelectItem(value: 'weekends', label: 'Weekends'),
          ClaySelectItem(value: 'three', label: '3 times a week'),
          ClaySelectItem(value: 'custom', label: 'Custom', enabled: false),
        ],
        onChanged: (v) => setState(() => _repeat = v),
      ),
      const SizedBox(height: ClaySpacing.regular),
      ClaySelect<String>(
        labelText: 'Time of day',
        hintText: 'Choose a time',
        value: _time,
        items: const [
          ClaySelectItem(
            value: 'morning',
            label: 'Morning',
            leading: Icon(LucideIcons.sunrise),
          ),
          ClaySelectItem(
            value: 'afternoon',
            label: 'Afternoon',
            leading: Icon(LucideIcons.sun),
          ),
          ClaySelectItem(
            value: 'evening',
            label: 'Evening',
            leading: Icon(LucideIcons.moon),
          ),
        ],
        onChanged: (v) => setState(() => _time = v),
      ),
      const SizedBox(height: ClaySpacing.regular),
      const ClaySelect<String>(
        labelText: 'Week starts on',
        value: 'mon',
        items: [ClaySelectItem(value: 'mon', label: 'Monday')],
        onChanged: null,
      ),
    ],
  );
}

class _Entry extends StatelessWidget {
  const _Entry();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const ClayTextArea(
        labelText: 'Note',
        hintText: 'What helped today, or what got in the way',
      ),
      const SizedBox(height: ClaySpacing.regular),
      ClaySearchField(hintText: 'Search habits', onChanged: (_) {}),
      const SizedBox(height: ClaySpacing.regular),
      ClayPasswordField(
        labelText: 'Password',
        helperText: 'Eight letters or more',
        onChanged: (_) {},
      ),
    ],
  );
}

class _Numbers extends StatelessWidget {
  const _Numbers();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const ClayInputGroup(
        labelText: 'Goal',
        hintText: '8',
        suffixText: 'glasses a day',
        keyboardType: TextInputType.number,
      ),
      const SizedBox(height: ClaySpacing.regular),
      const ClayFieldLabel('Glasses a day'),
      KitLive<double>(
        8,
        (context, n, set) => ClayNumberField(
          value: n,
          min: 1,
          max: 20,
          onChanged: (v) => set(v ?? n),
          semanticLabel: 'Glasses a day',
        ),
      ),
      const SizedBox(height: ClaySpacing.regular),
      const ClayFieldLabel('The code we sent you'),
      ClayOtpField(semanticLabel: 'Code', onCompleted: (_) {}),
    ],
  );
}

class _Many extends StatelessWidget {
  const _Many();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ClayCombobox<String>(
        labelText: 'Category',
        hintText: 'Health, mind, home',
        options: const ['Health', 'Mind', 'Home', 'Work', 'Friends'],
        onSelected: (_) {},
      ),
      const SizedBox(height: ClaySpacing.regular),
      KitLive<List<String>>(
        const ['Morning', 'Outdoors'],
        (context, tags, set) => ClayTagInput<String>(
          labelText: 'Tags',
          values: tags,
          options: const ['Morning', 'Outdoors', 'Quick', 'With friends'],
          onCreate: (text) => text,
          onChanged: set,
        ),
      ),
    ],
  );
}

class _FormField extends StatelessWidget {
  const _FormField();

  @override
  Widget build(BuildContext context) => KitLive<bool>(
    true,
    (context, on, set) => ClayFormField(
      labelText: 'Reminders',
      helperText: 'A nudge at each habit\'s time',
      child: ClaySwitch(value: on, onChanged: set, semanticLabel: 'Reminders'),
    ),
  );
}

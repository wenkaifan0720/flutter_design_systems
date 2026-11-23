/// Gloss's fields and selects.
library;

import 'package:material_ui/material_ui.dart';
import 'package:gloss_ui/gloss_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

/// The fields page.
Widget kitFieldsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Fields',
  sections: const [
    KitSection(
      title: 'Text fields',
      maxWidth: 480,
      children: [
        _Filled(label: 'Recipe name', text: 'Miso aubergine'),
        GlossTextField(
          hintText: 'Search recipes',
          prefixIcon: Icon(LucideIcons.search),
        ),
        _Filled(
          label: 'Serves',
          text: '4',
          suffix: Text('people'),
          helper: 'Quantities scale to it',
        ),
        _Filled(
          label: 'Cooking time',
          text: 'about half an hour',
          error: 'Use minutes, as a number',
        ),
        _Filled(
          label: 'Notes',
          text: 'Kept by the shared plan',
          enabled: false,
        ),
        GlossTextField(
          labelText: 'Method',
          hintText: 'One step a line',
          maxLines: 4,
        ),
      ],
    ),
    KitSection(title: 'Selects', maxWidth: 480, children: [_Selects()]),
    KitSection(title: 'More ways to enter', children: [_Entry()]),
  ],
);

/// A field showing [text] typed in (not a hint), as a filled form shows it.
class _Filled extends StatefulWidget {
  const _Filled({
    required this.label,
    required this.text,
    this.suffix,
    this.helper,
    this.error,
    this.enabled = true,
  });

  final String label;
  final String text;
  final Widget? suffix;
  final String? helper;
  final String? error;
  final bool enabled;

  @override
  State<_Filled> createState() => _FilledState();
}

class _FilledState extends State<_Filled> {
  late final _controller = TextEditingController(text: widget.text);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GlossTextField(
    controller: _controller,
    labelText: widget.label,
    suffix: widget.suffix,
    helperText: widget.helper,
    errorText: widget.error,
    enabled: widget.enabled,
  );
}

class _Selects extends StatefulWidget {
  const _Selects();

  @override
  State<_Selects> createState() => _SelectsState();
}

class _SelectsState extends State<_Selects> {
  String _units = 'metric';
  String? _week;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      GlossSelect<String>(
        labelText: 'Units',
        value: _units,
        items: const [
          GlossSelectItem(value: 'metric', label: 'Metric (g, ml)'),
          GlossSelectItem(value: 'us', label: 'US cups and ounces'),
          GlossSelectItem(value: 'uk', label: 'Imperial'),
        ],
        onChanged: (v) => setState(() => _units = v),
      ),
      const SizedBox(height: GlossSpacing.regular),
      GlossSelect<String>(
        labelText: 'Week starts on',
        hintText: 'Choose a day',
        value: _week,
        items: const [
          GlossSelectItem(value: 'mon', label: 'Monday'),
          GlossSelectItem(value: 'sat', label: 'Saturday'),
          GlossSelectItem(value: 'sun', label: 'Sunday'),
        ],
        onChanged: (v) => setState(() => _week = v),
      ),
      const SizedBox(height: GlossSpacing.regular),
      const GlossSelect<String>(
        labelText: 'Household',
        value: 'a',
        items: [GlossSelectItem(value: 'a', label: 'Set by the owner')],
        onChanged: null,
      ),
    ],
  );
}

class _Entry extends StatefulWidget {
  const _Entry();

  @override
  State<_Entry> createState() => _EntryState();
}

class _EntryState extends State<_Entry> {
  List<String> _tags = ['Quick'];
  String? _herb;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 360),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const GlossSearchField(hintText: 'Search recipes'),
        const SizedBox(height: GlossSpacing.regular),
        const GlossTextArea(
          labelText: 'Notes',
          hintText: 'What to change next time',
        ),
        const SizedBox(height: GlossSpacing.regular),
        const GlossPasswordField(labelText: 'Password'),
        const SizedBox(height: GlossSpacing.regular),
        const GlossInputGroup(
          labelText: 'Weight',
          prefixText: '≈',
          suffixText: 'g',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: GlossSpacing.regular),
        const GlossFieldLabel('One-time code'),
        const GlossOtpField(semanticLabel: 'One-time code'),
        const SizedBox(height: GlossSpacing.regular),
        GlossCombobox<String>(
          labelText: 'Herb',
          hintText: 'Type to find one',
          options: const ['Basil', 'Bay leaf', 'Chives', 'Coriander', 'Dill'],
          value: _herb,
          onSelected: (h) => setState(() => _herb = h),
        ),
        const SizedBox(height: GlossSpacing.regular),
        GlossTagInput<String>(
          labelText: 'Tags',
          values: _tags,
          options: const ['Quick', 'Batch', 'Freezer', 'Vegan', 'Weeknight'],
          onChanged: (next) => setState(() => _tags = next),
        ),
        const SizedBox(height: GlossSpacing.regular),
        GlossFormField(
          labelText: 'Reminders',
          helperText: 'An hour before dinner',
          child: GlossSwitch(value: true, onChanged: (_) {}),
        ),
      ],
    ),
  );
}

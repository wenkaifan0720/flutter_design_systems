/// Fluent 2's selection controls by its spec: the checkbox (checked,
/// mixed, circular, large, label placements, disabled) and the completion
/// check, the radio group (vertical, horizontal, stacked labels, a
/// disabled choice), the switch (both sizes, label placements, disabled),
/// and the segmented control (a joined filled-circular TabList), each live.
library;

import 'package:flutter/material.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';

import '../kit.dart';

class _Live<T> extends StatefulWidget {
  const _Live(this.initial, this.builder);

  final T initial;
  final Widget Function(T value, ValueChanged<T> set) builder;

  @override
  State<_Live<T>> createState() => _LiveState<T>();
}

class _LiveState<T> extends State<_Live<T>> {
  late T _value = widget.initial;

  @override
  Widget build(BuildContext context) =>
      widget.builder(_value, (v) => setState(() => _value = v));
}

const _views = [
  Fluent2ButtonSegment('day', 'Day'),
  Fluent2ButtonSegment('week', 'Week'),
  Fluent2ButtonSegment('month', 'Month'),
];

const _filters = [
  Fluent2ButtonSegment('all', 'All files', icon: Fluent2Icons.document),
  Fluent2ButtonSegment('shared', 'Shared', icon: Fluent2Icons.people),
  Fluent2ButtonSegment('starred', 'Starred', icon: Fluent2Icons.star),
];

Widget kitSelectionDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Selection',
  sections: [
    kitSection('Checkbox', children: [kitSpecimenCheckboxStates()]),
    kitSection(
      'Checkbox, live',
      children: [
        _Live<Set<String>>(const {'Design'}, (picked, setPicked) {
          const teams = ['Design', 'Engineering', 'Marketing'];
          final bool? all = picked.isEmpty
              ? false
              : picked.length == teams.length
              ? true
              : null;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Fluent2Checkbox(
                value: all,
                label: 'Share with every team',
                onChanged: (v) => setPicked(v ? teams.toSet() : <String>{}),
              ),
              for (final team in teams)
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: Fluent2Spacing.xxl,
                  ),
                  child: Fluent2Checkbox(
                    value: picked.contains(team),
                    label: team,
                    onChanged: (v) => setPicked(
                      v ? {...picked, team} : picked.difference({team}),
                    ),
                  ),
                ),
            ],
          );
        }),
      ],
    ),
    kitSection('Circular and large', children: [kitSpecimenCheckboxShapes()]),
    kitSection(
      'Label placement',
      children: [
        kitRow([
          for (final at in const [
            Fluent2LabelPosition.before,
            Fluent2LabelPosition.after,
          ])
            _Live<bool?>(
              at == Fluent2LabelPosition.after,
              (v, set) => Fluent2Checkbox(
                value: v,
                label: kitSay(at),
                labelPosition: at,
                onChanged: set,
              ),
            ),
        ]),
      ],
    ),
    kitSection('Completion check', children: [kitSpecimenCompletionCheck()]),
    kitSection('Radio group', children: [kitSpecimenRadioGroup()]),
    kitSection('Radio group, horizontal', children: [kitSpecimenRadioRow()]),
    kitSection(
      'Radio group, stacked labels',
      children: [
        _Live<String>(
          'm',
          (v, set) => Fluent2RadioGroup<String>(
            label: 'Thumbnail size',
            value: v,
            onChanged: set,
            layout: Fluent2RadioLayout.horizontalStacked,
            options: const [
              Fluent2Radio('s', 'Small'),
              Fluent2Radio('m', 'Medium'),
              Fluent2Radio('l', 'Large'),
            ],
          ),
        ),
      ],
    ),
    kitSection('Switch', children: [kitSpecimenSwitchStates()]),
    kitSection(
      'Switch, live',
      children: [
        _Live<bool>(
          true,
          (v, set) => Fluent2Switch(
            value: v,
            label: v ? 'Notifications on' : 'Notifications off',
            onChanged: set,
          ),
        ),
        _Live<bool>(
          false,
          (v, set) => Fluent2Switch(
            value: v,
            label: 'Show me as away',
            labelPosition: Fluent2LabelPosition.before,
            size: Fluent2SwitchSize.small,
            onChanged: set,
          ),
        ),
        _Live<bool>(
          false,
          (v, set) => Fluent2Switch(
            value: v,
            label: 'Mute the Design channel for an hour',
            labelPosition: Fluent2LabelPosition.above,
            onChanged: set,
          ),
        ),
      ],
    ),
    kitSection('Segmented control', children: [kitSpecimenSegmented()]),
    kitSection(
      'Segmented control, with glyphs, filling the row',
      children: [
        _Live<String>(
          'all',
          (v, set) => Fluent2SegmentedButton<String>(
            label: 'Files',
            segments: _filters,
            value: v,
            expand: true,
            onChanged: set,
          ),
        ),
      ],
    ),
    kitSection(
      'Segmented control, sizes and disabled',
      children: [kitSpecimenSegmentedSizes()],
    ),
  ],
);

Widget kitSpecimenCheckboxStates() => kitRow([
  Fluent2Checkbox(value: false, label: 'Unchecked', onChanged: (_) {}),
  Fluent2Checkbox(value: true, label: 'Checked', onChanged: (_) {}),
  Fluent2Checkbox(value: null, label: 'Mixed', onChanged: (_) {}),
  const Fluent2Checkbox(value: true, label: 'Disabled', onChanged: null),
  const Fluent2Checkbox(value: false, label: 'Disabled', onChanged: null),
]);

Widget kitSpecimenCheckboxShapes() => kitRow([
  Fluent2Checkbox(
    value: true,
    label: 'Circular',
    shape: Fluent2CheckboxShape.circular,
    onChanged: (_) {},
  ),
  Fluent2Checkbox(
    value: true,
    label: 'Large',
    size: Fluent2CheckboxSize.large,
    onChanged: (_) {},
  ),
  Fluent2Checkbox(
    value: null,
    label: 'Large mixed',
    size: Fluent2CheckboxSize.large,
    onChanged: (_) {},
  ),
]);

Widget kitSpecimenCompletionCheck() => Builder(
  builder: (context) {
    final t = context.fluent2Theme;
    // A task's words run on to more lines at a large text size; a task
    // out of use reads in the disabled ink, as its mark does. The mark says
    // the task as its own name, so a screen reader hears it once, with the
    // mark's state ("Archived task, checkbox, disabled").
    Widget task(
      Widget check,
      String title, {
      bool quiet = false,
      bool inert = false,
    }) => Row(
      spacing: Fluent2Spacing.s,
      children: [
        check,
        Expanded(
          child: ExcludeSemantics(
            child: Text(
              title,
              style: t.body1.c(
                inert
                    ? t.textDisabled
                    : quiet
                    ? t.textSecondary
                    : t.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: Fluent2Spacing.xs,
      children: [
        _Live<bool>(
          true,
          (v, set) => task(
            Fluent2CompletionCheck(
              value: v,
              label: 'Send the launch deck to Kai',
              onChanged: set,
            ),
            'Send the launch deck to Kai',
            quiet: v,
          ),
        ),
        _Live<bool>(
          false,
          (v, set) => task(
            Fluent2CompletionCheck(
              value: v,
              label: 'Book the design review room',
              onChanged: set,
            ),
            'Book the design review room',
            quiet: v,
          ),
        ),
        task(
          const Fluent2CompletionCheck(
            value: true,
            label: 'Press notes, done',
            readOnly: true,
          ),
          'Press notes (Mara marked it done)',
          quiet: true,
        ),
        task(
          const Fluent2CompletionCheck(value: false, label: 'Archived task'),
          'Archived task',
          inert: true,
        ),
      ],
    );
  },
);

Widget kitSpecimenRadioGroup() => _Live<String>(
  'weekly',
  (v, set) => Fluent2RadioGroup<String>(
    label: 'Digest',
    value: v,
    onChanged: set,
    options: const [
      Fluent2Radio('daily', 'Daily digest'),
      Fluent2Radio('weekly', 'Weekly digest'),
      Fluent2Radio('never', 'Never'),
      Fluent2Radio('live', 'As it happens', enabled: false),
    ],
  ),
);

Widget kitSpecimenRadioRow() => _Live<String>(
  'team',
  (v, set) => Fluent2RadioGroup<String>(
    label: 'Who can see this file',
    value: v,
    onChanged: set,
    layout: Fluent2RadioLayout.horizontal,
    options: const [
      Fluent2Radio('me', 'Only me'),
      Fluent2Radio('team', 'Northwind'),
      Fluent2Radio('link', 'Anyone with the link'),
    ],
  ),
);

Widget kitSpecimenSwitchStates() => kitRow([
  Fluent2Switch(value: false, label: 'Off', onChanged: (_) {}),
  Fluent2Switch(value: true, label: 'On', onChanged: (_) {}),
  const Fluent2Switch(value: true, label: 'Disabled', onChanged: null),
  const Fluent2Switch(value: false, label: 'Disabled', onChanged: null),
]);

Widget kitSpecimenSegmented() => _Live<String>(
  'week',
  (v, set) => Fluent2SegmentedButton<String>(
    label: 'Calendar view',
    segments: _views,
    value: v,
    onChanged: set,
  ),
);

Widget kitSpecimenSegmentedSizes() => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    for (final size in Fluent2SegmentedButtonSize.values) ...[
      _Live<String>(
        'day',
        (v, set) => Fluent2SegmentedButton<String>(
          label: 'Calendar view, ${kitSay(size)}',
          segments: _views,
          value: v,
          size: size,
          onChanged: set,
        ),
      ),
      const SizedBox(height: Fluent2Spacing.m),
    ],
    const Fluent2SegmentedButton<String>(
      label: 'Calendar view, disabled',
      segments: _views,
      value: 'month',
      onChanged: null,
    ),
  ],
);

/// Fluent 2's Field by its spec: a label (required, with an info
/// button), a hint, the validation messages (error, warning, success),
/// the horizontal orientation, the sizes, and a form section holding a
/// Northwind workspace's settings, each live.
library;

import 'package:flutter/material.dart';
import 'package:fluent2_ui/fluent2_ui.dart';

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

Widget kitFormsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Forms',
  sections: [
    kitSection('Field', children: [kitSpecimenField()]),
    kitSection('Validation', children: [kitSpecimenFieldValidation()]),
    kitSection(
      'Horizontal (vertical under 400 wide)',
      children: [
        _Live<String>(
          'Northwind',
          (v, set) => Fluent2FormField(
            label: 'Workspace name',
            orientation: Fluent2FieldOrientation.horizontal,
            helper: 'Shown on invites and the sign-in page.',
            child: Fluent2TextField(value: v, onChanged: set),
          ),
        ),
        _Live<String?>(
          'eu',
          (v, set) => Fluent2FormField(
            label: 'Data region',
            orientation: Fluent2FieldOrientation.horizontal,
            child: Fluent2Select<String>(
              options: const [
                Fluent2Option('eu', 'Europe'),
                Fluent2Option('us', 'United States'),
                Fluent2Option('apac', 'Asia Pacific'),
              ],
              value: v,
              onChanged: set,
            ),
          ),
        ),
      ],
    ),
    kitSection(
      'Sizes',
      children: [
        for (final size in Fluent2InputSize.values)
          _Live<String>(
            '',
            (v, set) => Fluent2FormField(
              label: 'Display name, ${kitSay(size)}',
              size: size,
              child: Fluent2TextField(value: v, size: size, onChanged: set),
            ),
          ),
      ],
    ),
    kitSection(
      'Labels',
      children: [
        kitRow([
          const Fluent2Label('Display name'),
          const Fluent2Label('Email', required: true),
          const Fluent2Label('Owner', weight: Fluent2LabelWeight.semibold),
          const Fluent2Label('Archived', enabled: false),
          const Fluent2InfoLabel(
            'Retention',
            info: 'Files in the bin are deleted after 30 days.',
          ),
        ]),
      ],
    ),
    kitSection('Form section', children: [kitSpecimenFormSection()]),
  ],
);

Widget kitSpecimenField() => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.stretch,
  spacing: Fluent2Spacing.l,
  children: [
    _Live<String>(
      '',
      (v, set) => Fluent2FormField(
        label: 'Email',
        required: true,
        helper: 'We send the invite here.',
        child: Fluent2TextField(
          value: v,
          hint: 'name@northwind.example',
          onChanged: set,
        ),
      ),
    ),
    _Live<String>(
      '30',
      (v, set) => Fluent2FormField(
        label: 'Keep deleted files',
        info: 'After this many days, files in the bin are gone for good.',
        child: Fluent2TextField(value: v, onChanged: set),
      ),
    ),
  ],
);

Widget kitSpecimenFieldValidation() => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.stretch,
  spacing: Fluent2Spacing.l,
  children: [
    _Live<String>(
      'northwind launch',
      (v, set) => Fluent2FormField(
        label: 'Channel name',
        validationMessage: 'Use letters, numbers and dashes only.',
        child: Fluent2TextField(value: v, onChanged: set),
      ),
    ),
    _Live<String>(
      'design',
      (v, set) => Fluent2FormField(
        label: 'Channel name',
        validationMessage: 'A channel named design already exists.',
        validationState: Fluent2ValidationState.warning,
        child: Fluent2TextField(value: v, onChanged: set),
      ),
    ),
    _Live<String>(
      'launch-2026',
      (v, set) => Fluent2FormField(
        label: 'Channel name',
        validationMessage: 'The name is free.',
        validationState: Fluent2ValidationState.success,
        child: Fluent2TextField(value: v, onChanged: set),
      ),
    ),
  ],
);

Widget kitSpecimenFormSection() =>
    _Live<(String, bool, String)>(('Ines Duarte', true, 'weekly'), (v, set) {
      final (name, push, digest) = v;
      return Fluent2FormSection(
        title: 'Notifications',
        description: 'How Northwind reaches you about files and chats.',
        footnote: 'Admins can turn off email for the whole workspace.',
        children: [
          Fluent2FormField(
            label: 'Display name',
            required: true,
            child: Fluent2TextField(
              value: name,
              onChanged: (n) => set((n, push, digest)),
            ),
          ),
          Fluent2Switch(
            value: push,
            label: 'Push notifications',
            onChanged: (p) => set((name, p, digest)),
          ),
          Fluent2FormField(
            label: 'Email digest',
            child: Fluent2RadioGroup<String>(
              value: digest,
              onChanged: (d) => set((name, push, d)),
              options: const [
                Fluent2Radio('daily', 'Daily'),
                Fluent2Radio('weekly', 'Weekly'),
                Fluent2Radio('never', 'Never'),
              ],
            ),
          ),
        ],
      );
    });

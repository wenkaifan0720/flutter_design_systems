/// Fluent 2's list section: a team's files under their head with the tabs
/// that pick which set shows, and the day's meetings on the ground with
/// See all at the head's end.
library;

import 'package:flutter/material.dart';
import 'package:fluent2_ui/fluent2_ui.dart';

import '../kit.dart';

/// Holds a live value for a specimen: [builder] draws the control with the
/// value and the setter it hands the control.
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

Widget kitPatternListSectionDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'List section',
  sections: [
    kitSection('Files in sets', children: [kitSpecimenListSectionFiles()]),
    kitSection('Meetings', children: [kitSpecimenListSectionMeetings()]),
  ],
);

// --- Specimens --------------------------------------------------------------

Widget kitSpecimenListSectionFiles() => _Live<int>(
  0,
  (chosen, set) => Fluent2ListSection(
    title: 'Files',
    aside: '${_sets[_keys[chosen]]!.length}',
    action: Fluent2SectionHeader.link('See all', onPressed: () {}),
    selector: Fluent2TabList(
      size: Fluent2TabSize.small,
      appearance: Fluent2TabAppearance.subtleCircular,
      label: 'Which files',
      selectedIndex: chosen,
      onChanged: set,
      tabs: const ['Recent', 'Shared'],
    ),
    rows: [
      for (final (name, meta) in _sets[_keys[chosen]]!)
        Fluent2ListItem(
          icon: Fluent2Icons.document,
          title: name,
          subtitle: meta,
          onTap: () {},
        ),
    ],
  ),
);

const _keys = ['recent', 'shared'];

const Map<String, List<(String, String)>> _sets = {
  'recent': [
    ('Q3 plan.docx', 'Kai Tanaka · 2h ago'),
    ('Brand guidelines.pdf', 'Mara Okafor · Yesterday'),
    ('Roadmap.pptx', 'Ines Duarte · Oct 20'),
  ],
  'shared': [
    ('Offsite budget.xlsx', 'Shared by Tomas Lindqvist'),
    ('Standup notes', 'Shared by Priya Raman'),
  ],
};

Widget kitSpecimenListSectionMeetings() => Fluent2ListSection(
  title: 'Today',
  aside: '3 meetings',
  action: Fluent2SectionHeader.link('See all', onPressed: () {}),
  asCard: false,
  rows: [
    Fluent2ListItem(
      icon: Fluent2Icons.video,
      title: 'Standup',
      subtitle: '09:30 · 15 min',
      onTap: () {},
    ),
    Fluent2ListItem(
      icon: Fluent2Icons.calendarLtr,
      title: 'Roadmap review',
      subtitle: '14:00 · Video call',
      onTap: () {},
    ),
    Fluent2ListItem(
      icon: Fluent2Icons.people,
      title: 'Design crit',
      subtitle: '16:00 · Room 2',
      onTap: () {},
    ),
  ],
);

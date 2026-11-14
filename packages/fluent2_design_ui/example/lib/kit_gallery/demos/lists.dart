/// Fluent 2's list: rows with a glyph, an avatar or a check before their
/// words and a value, a control or a chevron after them, grouped on a
/// card under a section header or laid on the ground, a selected row and
/// a disabled one.
library;

import 'package:flutter/material.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';

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

Widget kitListsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Lists',
  sections: [
    kitSection('Files on a card', children: [kitSpecimenListFiles()]),
    kitSection('People, chevrons', children: [kitSpecimenListPeople()]),
    kitSection('Checks', children: [kitSpecimenListChecks()]),
    kitSection(
      'On the ground, selected and disabled',
      children: [kitSpecimenListGroupGround()],
    ),
    kitSection('Section header', children: [kitSpecimenSectionHeader()]),
  ],
);

// --- Specimens --------------------------------------------------------------

Widget kitSpecimenListFiles() => Fluent2ListGroup(
  title: 'Recent files',
  aside: '12',
  action: Fluent2SectionHeader.link('See all', onPressed: () {}),
  children: [
    Fluent2ListItem(
      icon: Fluent2Icons.document,
      title: 'Q3 plan.docx',
      subtitle: 'Kai Tanaka edited 2h ago',
      value: '2.4 MB',
      onTap: () {},
    ),
    Fluent2ListItem(
      icon: Fluent2Icons.documentText,
      title: 'Brand guidelines.pdf',
      subtitle: 'Mara Okafor · Design',
      value: '8.1 MB',
      onTap: () {},
    ),
    Fluent2ListItem(
      icon: Fluent2Icons.folder,
      title: 'Offsite photos',
      subtitle: '24 items',
      chevron: true,
      onTap: () {},
    ),
  ],
);

Widget kitSpecimenListPeople() => Fluent2ListGroup(
  children: [
    for (final person in kitPeople.take(3))
      Fluent2ListItem(
        leading: Fluent2Avatar(
          name: person.name,
          color: Fluent2AvatarColor.colorful,
        ),
        title: person.name,
        subtitle: 'Northwind · Product',
        chevron: true,
        onTap: () {},
      ),
  ],
);

Widget kitSpecimenListChecks() => _Live<Set<String>>(
  const {'Book the room'},
  (done, set) => Fluent2ListGroup(
    title: 'Offsite checklist',
    children: [
      for (final task in _tasks)
        Fluent2ListItem(
          title: task,
          checked: done.contains(task),
          onChanged: (v) =>
              set(v ? {...done, task} : {...done.where((d) => d != task)}),
        ),
    ],
  ),
);

const List<String> _tasks = ['Book the room', 'Send the agenda', 'Share notes'];

Widget kitSpecimenListGroupGround() => Fluent2ListGroup(
  asCard: false,
  footer: 'Shared with the Northwind team',
  children: [
    Fluent2ListItem(
      icon: Fluent2Icons.chat,
      title: 'Design crit',
      subtitle: 'Kai: the new cards look great',
      selected: true,
      onTap: () {},
    ),
    Fluent2ListItem(
      icon: Fluent2Icons.chat,
      title: 'Launch channel',
      subtitle: 'Archived',
      enabled: false,
      onTap: () {},
    ),
  ],
);

Widget kitSpecimenSectionHeader() => Fluent2SectionHeader(
  'Meetings today',
  aside: '3',
  action: Fluent2SectionHeader.link('Open calendar', onPressed: () {}),
);
